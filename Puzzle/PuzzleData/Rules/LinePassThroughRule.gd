class_name LinePassThroughRule
extends PuzzleRule

var line_id : int = 0

func _init(data) -> void:
	self.line_id = data
	self.rule_type = 0
	self.handle_type = 0
	pass

func check_rule(puzzle_data : PuzzleData, line_data : LineData, puzzle_element : PuzzleElement) -> bool:
	if puzzle_element is Edge and line_data.has_edge(puzzle_element):
		return true
	if puzzle_element is Vertice and line_data.has_vertice(puzzle_element):
		return true
	return false
