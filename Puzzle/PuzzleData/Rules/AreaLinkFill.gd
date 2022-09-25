class_name AreaLinkFill
extends PuzzleRule

var fill_rule : PackedInt32Array = []
var hollow : bool = false

func _init(data) -> void:
	match typeof(data):
		TYPE_ARRAY:
			self.fill_rule = data
		TYPE_DICTIONARY:
			self.fill_rule = data.blocks
			self.hollow = data.hollow
	self.rule_type = 4
	self.handle_type = 1
	pass

static func fit_block(puzzle_data : PuzzleData, start_area : Area, areas: Array, used_areas : Array, rule: AreaLinkFill, line_data : PackedInt32Array = [] as PackedInt32Array) -> bool:
	var check_area : Array[Area] = [start_area]
	if not areas.has(start_area): return false
	if rule.fill_rule[0] != start_area.tag: return false
	areas.erase(start_area)
	used_areas.append(start_area)
	var this_time_used : Array[Area] = []
	for i in range(1, rule.fill_rule.size(), 5):
		var cnt_area : Area = check_area[rule.fill_rule[i]]
		var type : int = rule.fill_rule[i + 1]
		var subtype : int = rule.fill_rule[i + 2]
		var area_tag : int = rule.fill_rule[i + 3]
		var area_required : int = rule.fill_rule[i + 4]
		var jump_edge : Edge = cnt_area.get_sround_edge_by_type_and_subtype(type, subtype)
		if jump_edge == null or line_data.has(jump_edge.id): return false
		var jump_areas = puzzle_data.get_area_neighbours_by_sround_edge(cnt_area, jump_edge)
		if jump_areas.size() != 1: return false
		var jump_area : Area = jump_areas[0]
		check_area.append(jump_area)
		if absi(area_tag) != jump_area.tag: return false
		if area_required == 0: continue
		if not areas.has(jump_area):
			if area_tag < 0:
				if used_areas.has(jump_area): continue
				else: return false
			else:
				if this_time_used.has(jump_area): continue
				else: return false
		else:
			if area_tag > 0:
				areas.erase(jump_area) 
				used_areas.append(jump_area)
				this_time_used.append(jump_area)
	return true

static func has_intersection(a : Array, b : Array) -> bool:
	for _a in a:
		if b.has(_a): return true
	return false

static func solve_tetris(puzzle_data : PuzzleData, areas: Array, used_areas : Array, rules: Array, line_data : PackedInt32Array = [] as PackedInt32Array) -> bool:
	if rules.size() == 0: return areas.size() == 0
	var rule : AreaLinkFill = rules.pop_front()
	for area in areas:
		var _areas : Array[Area] = areas.duplicate()
		var _used_areas : Array[Area] = used_areas.duplicate()
		var fitted : bool = AreaLinkFill.fit_block(puzzle_data, area, _areas, _used_areas, rule, line_data)
		if not fitted: continue
		var remain_result : bool = AreaLinkFill.solve_tetris(puzzle_data, _areas, _used_areas, rules.duplicate())
		if remain_result: return true
	return false

static func check_grouped_rule(puzzle_data : PuzzleData, lines_data : Array, grouped_rules : Array[PuzzleRule], isolated_area : Array) -> Array:
	var _areas : Array[Area] = isolated_area.duplicate()
	var _rules : Array = grouped_rules.duplicate()
	var edge_ids : PackedInt32Array = []
	for line in lines_data:
		edge_ids.append_array((line as LineData).get_edge_ids())
	var ans = AreaLinkFill.solve_tetris(puzzle_data, _areas, [], _rules, edge_ids)
#	var ans = AreaLinkFill.solve_hollow_tetris(puzzle_data, _areas, [], [], _rules, edge_ids)
	return [] if ans else grouped_rules
#	var ans : Array[PuzzleRule] = []
#	var counts : Dictionary = {}
#	for rule in grouped_rules:
#		if counts.has(rule.color_id):
#			counts[rule.color_id].append(rule)
#		else:
#			counts[rule.color_id] = [rule]
##	print(counts)
#	if counts.size() > 1:
#		var keys : Array[int] = counts.keys()
#		keys.sort_custom(func (a : int, b : int) -> bool:
#			var _ans : bool = counts[a].size() < counts[b].size()
#			if counts[a].size() == counts[b].size():
#				return a > b
#			return _ans
#		)
##		print(keys)
#		for key in keys.slice(0, -1):
#			ans.append_array(counts[key])
	return []
