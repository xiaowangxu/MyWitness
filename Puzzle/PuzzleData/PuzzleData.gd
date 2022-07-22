class_name PuzzleData
extends Resource

var decorators : Array[ShapeBaseResource] = []
var vertices : Array[Vertice] = []
var vertices_start : Array[Vertice] = []
var vertices_end : Array[Vertice] = []
var edges : Array[Edge] = []
var areas : Array[Area] = []
var decorated_elements : Array[PuzzleElement] = []

var base_size : Vector2i
var background_color : Color
var background_line_color : Color
var lines_count : int
var lines_color : PackedColorArray = []
var line_drawing_color : Color
var line_highlight_color : Color
var line_error_color : Color
var line_correct_color : Color
var start_radius : float
var normal_radius : float

var edge_map : Dictionary = {}
var area_neighbour_map : Dictionary = {}

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

func create_decorator_shared_shape(type : int, data : Dictionary) -> ShapeBaseResource:
	match type:
		0:
			return RegularShapeResource.new(data.edge_count, data.radius, data.round_cornor, data.uv)
		1:
			return RoundedShapeResource.new(PackedVector2Array([
				Vector2(0, -44),
				Vector2(14, -30),
				Vector2(30, -30),
				Vector2(30, -14),
				Vector2(44, 0),
				Vector2(30, 14),
				Vector2(30, 30),
				Vector2(14, 30),
				Vector2(0, 44),
				Vector2(-14, 30),
				Vector2(-30, 30),
				Vector2(-30, 14),
				Vector2(-44, 0),
				Vector2(-30, -14),
				Vector2(-30, -30),
				Vector2(-14, -30)
			]), data.round_cornor, data.uv)
		2:
			return RoundedShapeResource.new(PackedVector2Array([
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
		233:
			return TextureShapeResource.new(RoundedShapeResource.new(PackedVector2Array([
				Vector2(0, -44),
				Vector2(14, -30),
				Vector2(30, -30),
				Vector2(30, -14),
				Vector2(44, 0),
				Vector2(30, 14),
				Vector2(30, 30),
				Vector2(14, 30),
				Vector2(0, 44),
				Vector2(-14, 30),
				Vector2(-30, 30),
				Vector2(-30, 14),
				Vector2(-44, 0),
				Vector2(-30, -14),
				Vector2(-30, -30),
				Vector2(-14, -30)
			]), 4.0, true), preload("res://Puzzle/Panel/TestPainting.png"))
		234:
			return GroupShapeResource.new([
				RegularShapeResource.new(3, 22, 0, false),
				RegularShapeResource.new(3, 22, 0, false),
				RegularShapeResource.new(3, 22, 0, false),
			], [
				Transform2D(deg2rad(30), Vector2(-40, 0)),
				Transform2D(deg2rad(30), Vector2(0, 0)),
				Transform2D(deg2rad(30), Vector2(40, 0)),
			])
		_:
			return null

func create_rule(name : int, data) -> PuzzleRule:
	match name:
		PuzzleRuleFunction.LINE_PASS_THROUGH: return LinePassThroughRule.new(data)
		PuzzleRuleFunction.AREA_SROUND_SEGMENT_COUNT: return AreaSroundSegmentCountRule.new(data)
		PuzzleRuleFunction.COLOR_ISOLATE: return ColorIsolate.new(data)
		PuzzleRuleFunction.COLOR_MATCH: return ColorMatch.new(data)
	return null

func create_decorator(base : ShapeBaseResource, color : Array, rotation : float = 0.0, rules : Array = []) -> Decorator:
	var decorator := Decorator.new(base, array_to_color(color), Transform2D(deg2rad(rotation), Vector2.ZERO)) #decorator
	for rule_data in rules:
		var rule : PuzzleRule = create_rule(rule_data.name, rule_data.data)
		decorator.add_rule(rule)
		pass
	return decorator

func append_decorator(element : PuzzleElement) -> void:
	decorated_elements.append(element)
	pass

func create_lines(lines : Array) -> void:
	lines_count = lines.size()
	for i in range(lines_count):
		var line : Dictionary = lines[i]
		var color_start := i * 4
		#	line color
		if line.has("drawing"):
			lines_color.append(array_to_color(line.drawing))
		else:
			lines_color.append(Color.DEEP_SKY_BLUE)
		if line.has("highlight"):
			lines_color.append(array_to_color(line.highlight))
		else:
			lines_color.append(Color.WHITE)
		if line.has("error"):
			lines_color.append(array_to_color(line.error))
		else:
			lines_color.append(Color.RED)
		if line.has("correct"):
			lines_color.append(array_to_color(line.correct))
		else:
			lines_color.append(lines_color[color_start])
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
	
	create_lines(board.lines)
	
	for i in range(data.decorators.size()):
		var decorator : Dictionary = data.decorators[i]
		decorators.append(create_decorator_shared_shape(decorator.type, decorator.data))
	for i in range(data.points.size()):
		var point : Dictionary = data.points[i]
		var decorator : Decorator = null if not point.has("decorator") else create_decorator(decorators[int(point.decorator.id)], point.decorator.color, point.decorator.rotation, point.decorator.rules)
		var vertice := Vertice.new(Vector2(point.position[0], point.position[1]), point.type, decorator)
		if decorator != null:
			append_decorator(vertice)
		vertice.id = i
		if point.has("tag"):
			vertice.tag = point.tag
		if point.has("custom"):
			vertice.set_custom_data(point.custom)
		vertices.append(vertice)
		if point.type == Vertice.VerticeType.START:
			vertices_start.append(vertice)
		elif point.type == Vertice.VerticeType.END:
			vertices_end.append(vertice)
	for i in range(data.edges.size()):
		var edge : Dictionary = data.edges[i]
		var start := vertices[edge.from]
		var end := vertices[edge.to]
		var decorator : Decorator = null if not edge.has("decorator") else create_decorator(decorators[int(edge.decorator.id)], edge.decorator.color, edge.decorator.rotation, edge.decorator.rules)
		var _edge := Edge.new(start, end, calcu_line_center(start, end), decorator)
		if decorator != null:
			append_decorator(_edge)
		_edge.id = i
		if edge.has("tag"):
			_edge.tag = edge.tag
		if edge.has("custom"):
			_edge.set_custom_data(edge.custom)
			_edge.calcu_wrap()
		edges.append(_edge)
		start.add_neighbour(i)
		end.add_neighbour(i)
	for i in range(data.areas.size()):
		var area : Dictionary = data.areas[i]
		var srounds : PackedInt32Array = []
		for edge_idx in area.srounds:
			srounds.append(edge_idx)
		var decorator : Decorator = null if not area.has("decorator") else create_decorator(decorators[int(area.decorator.id)], area.decorator.color, area.decorator.rotation, area.decorator.rules)
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
		if area.has("custom"):
			_area.set_custom_data(area.custom)
	pass

func calcu_area_neighbour_map() -> void:
	if not area_neighbour_map.is_empty(): return
	for area in areas:
		for i in area.srounds:
			if area_neighbour_map.has(i):
				area_neighbour_map[i].append(area)
			else:
				area_neighbour_map[i] = [area]
	pass

func calcu_egde_map() -> void:
	if not edge_map.is_empty(): return
	for edge in edges:
		if edge_map.has(edge.from):
			edge_map[edge.from][edge.to] = edge
		else:
			edge_map[edge.from] = {
				edge.to: edge
			}
	pass

# utils
func get_vertice_by_id(id : int) -> Vertice:
	if has_vertice_id(id):
		return vertices[id]
	else:
		return null
	pass

func has_vertice_id(id : int) -> bool:
	return 0 <= id and id < vertices.size()

func get_area_by_id(id : int) -> Area:
	if has_area_id(id):
		return areas[id]
	else:
		return null
	pass

func has_area_id(id : int) -> bool:
	return 0 <= id and id < areas.size()

func get_edge_by_id(id : int) -> Edge:
	if has_edge_id(id):
		return edges[id]
	else:
		return null
	pass

func has_edge_id(id : int) -> bool:
	return 0 <= id and id < edges.size()

func find_edge(a : Vertice, b : Vertice) -> Edge:
	if edge_map.has(a):
		if edge_map[a].has(b):
			return edge_map[a][b]
	if edge_map.has(b):
		if edge_map[b].has(a):
			return edge_map[b][a]
	return null
