class_name PuzzleRule
extends RefCounted

enum RuleHandleType {
	SELF,
	GROUPED
}

func get_handle_type() -> int:
	return 0

func _init(rule : String) -> void:
	pass 

func check_rule(puzzle_data : PuzzleData, line_data, puzzle_element : PuzzleElement) -> bool:
	return true

static func create_rule(name : String, data) -> PuzzleRule:
	match name:
		"line_pass_through": return LinePassThroughRule.new(data)
		"area_sround_segment_count": return AreaSroundSegmentCountRule.new(data)
	return null
