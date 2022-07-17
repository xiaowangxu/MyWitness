class_name PuzzleRule
extends RefCounted

enum RuleHandleType {
	SELF,
	GROUPED
}

var rule_type : int = -1
var handle_type : int = 0 

func _init(rule : String) -> void:
	pass 

func check_rule(puzzle_data : PuzzleData, line_data, puzzle_element : PuzzleElement) -> bool:
	return true

static func check_grouped_rule(puzzle_data : PuzzleData, line_data, grouped_rules : Array[PuzzleRule], isolated_area : Array) -> Array:
	return []
