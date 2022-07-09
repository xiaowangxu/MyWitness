class_name PuzzleData
extends Resource

var decorators : Array[TextureShapeResource] = []
var vertices : Array[Vertice] = []
var vertices_start : Array[Vertice] = []
var vertices_end : Array[Vertice] = []
var edges : Array[Edge] = []
var areas : Array[Area] = []
#var decorated_elements : Dictionary = {}
# check procedure
#var require_area_isolation : bool = false
var decorated_elements : Array[PuzzleElement] = []

var base_size : Vector2i
var background_color : Color
var background_line_color : Color
var line_drawing_color : Color
var line_highlight_color : Color
var line_error_color : Color
var line_correct_color : Color
var start_radius : float
var normal_radius : float

var edge_map = null
var area_neighbour_map = {}

func _init(res : JsonResource) -> void:
	calcu_puzzle(res.data)
	calcu_egde_map()
	calcu_area_neighbour_map()
	pass

func calcu_line_center(from : Vertice, to : Vertice, radius : float = normal_radius) -> Vector2:
	var normal := (to.position - from.position).normalized()
	var extends_length := normal * radius
	var from_position : Vector2 = from.position + (-extends_length if from.type == Vertice.VerticeType.STOP else Vector2.ZERO) 
	var to_position   : Vector2 = to.position + (extends_length if to.type == Vertice.VerticeType.STOP else Vector2.ZERO) 
	return (from_position + to_position) / 2.0

func calcu_area_center(points : PackedVector2Array) -> Vector2:
	var center : Vector2 = Vector2.ZERO
	var area_sum : float = 0.0
	var triangles : PackedInt32Array = Geometry2D.triangulate_polygon(points)
	for i in range(0, triangles.size(), 3):
		var a := points[triangles[i]]
		var b := points[triangles[i + 1]]
		var c := points[triangles[i + 2]]
		var area := (a-b).cross(c-b) / 2.0
		area_sum += area
		var triangle_center := (a+b+c)/3.0
		center += triangle_center*area
	return center / area_sum

func array_to_color(array : Array) -> Color:
	match array.size():
		3: return Color(array[0],array[1],array[2])
		4: return Color(array[0],array[1],array[2],array[3])
		_: 
			assert("array size is not able to convert to Color")
			return Color.RED

func create_decorator_shared_shape(type : int, data : Dictionary) -> TextureShapeResource:
	match type:
		0:
			return TextureRegularShapeResource.new(data.edge_count, data.radius, data.round_cornor, data.uv)
		1:
			return TextureRoundedShapeResource.new(PackedVector2Array([
				Vector2(-64, -48),
				Vector2(-48, -64),
				Vector2(0, -16),
				Vector2(48, -64),
				Vector2(64, -48),
				Vector2(16, 0),
				Vector2(64, 48),
				Vector2(48, 64),
				Vector2(0, 16),
				Vector2(-48, 64),
				Vector2(-64, 48),
				Vector2(-16, 0),
			]), 5.0, true)
		_:
			return null

func create_decorator(base : TextureShapeResource, color : Array, texture, rotation : float = 0.0, rules : Array = []) -> Decorator:
	var decorator := Decorator.new(base, array_to_color(color), null if texture == null else load(texture), Transform2D(deg2rad(rotation), Vector2.ZERO)) #decorator
	for rule_data in rules:
		var rule : PuzzleRule = PuzzleRule.create_rule(rule_data.name, rule_data.data)
		decorator.add_rule(rule)
		pass
#	var decorator := Decorator.new(base, Color(color[0], color[1], color[2], color[3]), texture)
	return decorator

func append_decorator(element : PuzzleElement) -> void:
	decorated_elements.append(element)
#	for rule in element.decorator.rules:
#		var script : GDScript = rule.get_script()
#		if decorated_elements.has(script):
#			decorated_elements[script].append(element)
#		else:
#			decorated_elements[script] = [element]
	pass

func calcu_puzzle(data : Dictionary) -> void:
	decorators = []
	vertices = []
	edges = []
	areas = []
	var board : Dictionary = data.board
	var bs : Array = board.base_size
	base_size = Vector2i(bs[0], bs[1])
	background_color = array_to_color(board.background_color)
	background_line_color = array_to_color(board.background_line_color)
	start_radius = board.start_radius
	normal_radius = board.normal_radius

#	line color
	if board.has("line_drawing_color"):
		line_drawing_color = array_to_color(board.line_drawing_color)
	else:
		line_drawing_color = Color.DEEP_SKY_BLUE
	if board.has("line_highlight_color"):
		var c : Array = board.line_highlight_color
		line_highlight_color = array_to_color(board.line_highlight_color)
	else:
		line_highlight_color = Color.WHITE
	if board.has("line_error_color"):
		line_error_color = array_to_color(board.line_error_color)
	else:
		line_error_color = Color.RED
	if board.has("line_correct_color"):
		line_correct_color = array_to_color(board.line_correct_color)
	else:
		line_correct_color = line_drawing_color
	
	for i in range(data.decorators.size()):
		var decorator : Dictionary = data.decorators[i]
		decorators.append(create_decorator_shared_shape(decorator.type, decorator.data))
	for i in range(data.points.size()):
		var point : Dictionary = data.points[i]
		var decorator : Decorator = null if not point.has("decorator") else create_decorator(decorators[int(point.decorator.id)], point.decorator.color, point.decorator.texture, point.decorator.rotation, point.decorator.rules)
		var vertice := Vertice.new(Vector2(point.position[0], point.position[1]), point.type, decorator)
		if decorator != null:
			append_decorator(vertice)
		vertice.id = i
		if point.has("tag"):
			vertice.tag = point.tag
		vertices.append(vertice)
		if point.type == Vertice.VerticeType.START:
			vertices_start.append(vertice)
		elif point.type == Vertice.VerticeType.END:
			vertices_end.append(vertice)
	for i in range(data.edges.size()):
		var edge : Dictionary = data.edges[i]
		var start := vertices[edge.from]
		var end := vertices[edge.to]
		var decorator : Decorator = null if not edge.has("decorator") else create_decorator(decorators[int(edge.decorator.id)], edge.decorator.color, edge.decorator.texture, edge.decorator.rotation, edge.decorator.rules)
		var _edge := Edge.new(start, end, calcu_line_center(start, end), decorator)
		if decorator != null:
			append_decorator(_edge)
		_edge.id = i
		if edge.has("tag"):
			_edge.tag = edge.tag
		edges.append(_edge)
		start.add_neighbour(i)
		end.add_neighbour(i)
	for i in range(data.areas.size()):
		var area : Dictionary = data.areas[i]
		var srounds : PackedInt32Array = []
		for edge_idx in area.srounds:
			srounds.append(edge_idx)
		var decorator : Decorator = null if not area.has("decorator") else create_decorator(decorators[int(area.decorator.id)], area.decorator.color, area.decorator.texture, area.decorator.rotation, area.decorator.rules)
		var center : Vector2
		if area.has("position"):
			center = Vector2(area.position[0], area.position[1])
		elif area.has("vertices"):
			var points : PackedVector2Array = []
			for p in area.vertices:
				points.append(vertices[p].position)
			center = calcu_area_center(points)
		else:
			var points : PackedVector2Array = []
			for edge_idx in srounds:
				var edge : Edge = edges[edge_idx]
				points.append(edge.position)
			center = calcu_area_center(points)
		var _area := Area.new(srounds, center, decorator)
		if decorator != null:
			append_decorator(_area)
		_area.id = i
		areas.append(_area)
		if area.has("tag"):
			_area.tag = area.tag
	pass

func calcu_area_neighbour_map() -> void:
	for area in areas:
		for i in area.srounds:
			if area_neighbour_map.has(i):
				area_neighbour_map[i].append(area)
			else:
				area_neighbour_map[i] = [area]
	pass

func calcu_egde_map() -> void:
	if edge_map != null: return
	edge_map = {}
	for edge in edges:
		if edge_map.has(edge.from):
			edge_map[edge.from][edge.to] = edge
		else:
			edge_map[edge.from] = {
				edge.to: edge
			}
	pass
