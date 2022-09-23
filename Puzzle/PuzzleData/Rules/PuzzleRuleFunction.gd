class_name PuzzleRuleFunction
extends RefCounted

enum {
	BASE = -1,
	LINE_PASS_THROUGH = 0,
	AREA_SROUND_SEGMENT_COUNT = 1,
	COLOR_ISOLATE = 2,
	COLOR_MATCH = 3,
	AREA_LINK_FILL = 4,
}

static func get_empty_grouped_rules_map() -> Dictionary:
	return {
		LINE_PASS_THROUGH: [],
		AREA_SROUND_SEGMENT_COUNT: [],
		COLOR_ISOLATE: [],
		COLOR_MATCH: [],
		AREA_LINK_FILL: [],
	}

static func check_grouped_rules(rule : int, puzzle_data : PuzzleData, lines_data : Array, grouped_rules : Array[PuzzleRule], isolated_area : Array[Area]) -> Array:
	match rule:
		COLOR_ISOLATE: return ColorIsolate.check_grouped_rule(puzzle_data, lines_data, grouped_rules, isolated_area)
		COLOR_MATCH: return ColorMatch.check_grouped_rule(puzzle_data, lines_data, grouped_rules, isolated_area)
		AREA_LINK_FILL: return AreaLinkFill.check_grouped_rule(puzzle_data, lines_data, grouped_rules, isolated_area)
#		AREA_SROUND_SEGMENT_COUNT: return AreaSroundSegmentCountRule.check_grouped_rule(puzzle_data, line_data, grouped_decorators, isolated_areas)
		_: return []

static func get_rule_class_enum(rule : PuzzleRule) -> int:
	if rule is LinePassThroughRule:
		return LINE_PASS_THROUGH
	elif rule is AreaSroundSegmentCountRule:
		return AREA_SROUND_SEGMENT_COUNT
	elif rule is ColorIsolate:
		return COLOR_ISOLATE
	elif rule is ColorMatch:
		return COLOR_MATCH
	elif rule is AreaLinkFill:
		return AREA_LINK_FILL
	else:
		return -1
