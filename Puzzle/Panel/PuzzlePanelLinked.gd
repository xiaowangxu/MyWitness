extends PuzzlePanel

@export var others_node_path : Array[NodePath] = []
var is_main_panel : bool = true
var others : Array[PuzzlePanel] = []

func _ready() -> void:
	super()
	for node_path in others_node_path:
		var node = get_node_or_null(node_path)
		if node != null and node is PuzzlePanel:
			others.append(node)

func on_puzzle_started(line_data : LineData, puzzle_position : Vector2, mouse_position : Vector3, world_position : Vector3) -> void:
	if is_main_panel:
		for panel in others:
			if panel != self:
				panel.is_main_panel = false
				var new_line := PuzzleFunction.generate_line_from_idxs((panel as PuzzlePanel).puzzle_data, line_data.to_puzzle_element_ids(puzzle_data), line_data.get_current_percentage())
				panel.start_puzzle(new_line)
			else:
				panel.is_main_panel = true
	super(line_data, puzzle_position, mouse_position, world_position)

func on_move_finished(line_data : LineData, puzzle_position : Vector2 = Vector2.ZERO, mouse_position : Vector3 = Vector3.ZERO, world_position : Vector3 = Vector3.ZERO) -> Vector2:
	if is_main_panel:
		for panel in others:
			if panel != self:
				var new_line := PuzzleFunction.generate_line_from_idxs(panel.puzzle_data, line_data.to_puzzle_element_ids(puzzle_data), line_data.get_current_percentage())
				panel.commit_move_line(new_line)
	return super(line_data, puzzle_position, mouse_position, world_position)

func on_puzzle_answered(correct : bool, tag : int, errors : Array) -> void:
	if is_main_panel:
		for panel in others:
			if panel != self:
				panel.check_puzzle()
			panel.is_main_panel = true
	super(correct, tag, errors)

func on_puzzle_exited() -> void:
	if is_main_panel:
		for panel in others:
			if panel != self:
				panel.exit_puzzle()
			panel.is_main_panel = true
	super()
