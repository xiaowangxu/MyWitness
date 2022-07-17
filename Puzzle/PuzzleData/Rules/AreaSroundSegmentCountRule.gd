class_name AreaSroundSegmentCountRule
extends PuzzleRule

var count : int = 0

func _init(data) -> void:
	self.count = data
	self.rule_type = 1
	self.handle_type = 0
	pass

func check_rule(puzzle_data : PuzzleData, line_data : LineData, puzzle_element : PuzzleElement) -> bool:
	var has_count : int = 0
	for edge_idx in (puzzle_element as Area).srounds: 
		if line_data.has_edge(puzzle_data.edges[edge_idx]):
			has_count += 1
	return has_count == count
