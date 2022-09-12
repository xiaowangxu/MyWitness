class_name PuzzleBoardLine
extends RenderItem

var puzzle_board : PuzzleData :
	set(val):
		puzzle_board = val
		queue_redraw()
var normal_radius : float = 25.0 :
	set(val):
		val = clampf(val, 0.0, INF)
		if val != normal_radius:
			normal_radius = val
			queue_redraw()
var start_radius : float = 60.0 :
	set(val):
		val = clampf(val, 0.0, INF)
		if val != normal_radius:
			start_radius = val
			queue_redraw()

func _init(puzzle_board : PuzzleData) -> void:
	self.puzzle_board = puzzle_board
	self.normal_radius = puzzle_board.normal_radius
	self.start_radius = puzzle_board.start_radius

func _draw() -> void:
	for vertice in puzzle_board.vertices:
		match vertice.type:
			Vertice.VerticeType.STOP:
				pass
			Vertice.VerticeType.START:
				RenderingServer.canvas_item_add_circle(_rid, vertice.position, start_radius, WHITE)
			_:
				RenderingServer.canvas_item_add_circle(_rid, vertice.position, normal_radius, WHITE)
	for edge in puzzle_board.edges:
		var extends_length := edge.normal * normal_radius
		var from_position : Vector2 = edge.from.position + (-extends_length if edge.from.type == Vertice.VerticeType.STOP else Vector2.ZERO) 
		var to_position   : Vector2 = edge.to.position + (extends_length if edge.to.type == Vertice.VerticeType.STOP else Vector2.ZERO)
		if edge.wrap:
			var wrap_extends_length := edge.normal * edge.wrap_extend
			RenderingServer.canvas_item_add_line(_rid, from_position, edge.wrap_from + wrap_extends_length, WHITE, normal_radius*2)
			RenderingServer.canvas_item_add_line(_rid, edge.wrap_to - wrap_extends_length, to_position, WHITE, normal_radius*2)
		else:
			RenderingServer.canvas_item_add_line(_rid, from_position, to_position, WHITE, normal_radius*2)
	pass
