class_name LinePassThroughRule
extends PuzzleRule

var line_id : int = 0

func get_handle_type() -> int:
	return 0

func _init(data) -> void:
	self.line_id = data
	pass

func check_rule(puzzle_data : PuzzleData, line_data : LineData, puzzle_element : PuzzleElement) -> bool:
	if line_data.has_edge(puzzle_element):
		return true
	return false
