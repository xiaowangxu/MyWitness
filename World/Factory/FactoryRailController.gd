extends InteractableLinker

var path_line_renderer : LineSegment = null

func _ready() -> void:
	var panel : PuzzlePanel = interactable as PuzzlePanel
	var puzzle_data := panel.puzzle_data
	path_line_renderer = LineSegment.new(null, puzzle_data.normal_radius, puzzle_data.start_radius, puzzle_data.base_size)
	path_line_renderer.self_modulate = Color(0.4, 0.5, 0.8)
	path_line_renderer.name = "path_render_item"
	panel.get_base_viewport_instance().puzzle_renderer.add_render_item(path_line_renderer)
#	panel.set_always_on(true)
	panel.puzzle_answered.connect(on_puzzle_answered)
	panel.puzzle_exited.connect(on_puzzle_exited)
	panel.puzzle_line_updated.connect(on_puzzle_line_updated)
	pass

func on_puzzle_answered(correct : bool, tag : int, errors : Array, puzzle_line : LineData) -> void:
	print(puzzle_line)
	path_line_renderer.line_data = puzzle_line
	pass

func on_puzzle_exited() -> void:
	print("exited")
	pass

func on_puzzle_line_updated(line : LineData) -> void:
	var length := line.get_length()
	$"../Path3D/PathFollow3D".unit_offset = clampf(length / 1000, 0, 1)
