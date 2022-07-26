class_name AreaSroundSegmentCountRule
extends PuzzleRule

var count : int = 0

func _init(data) -> void:
	self.count = data
	self.rule_type = 1
	self.handle_type = 0
	pass

func check_rule(puzzle_data : PuzzleData, lines_data : Array, puzzle_element : PuzzleElement) -> bool:
	var has_count : int = 0
	for edge_idx in (puzzle_element as Area).srounds: 
		for line_data in lines_data: 
			if line_data.has_edge(puzzle_data.get_edge_by_id(edge_idx)):
				has_count += 1
	return has_count == count
