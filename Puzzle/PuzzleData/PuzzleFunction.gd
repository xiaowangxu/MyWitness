class_name PuzzleFunction
extends RefCounted

static func line_to_directioned_edges(puzzle_data : PuzzleData, line : LineData) -> Array:
	var ans : Array[DirectionedEdge] = []
	var edge_map : Dictionary = puzzle_data.edge_map
	for line_segment in line.segments:
		if not is_equal_approx(line_segment.percentage, 1.0): continue
		var from := line_segment.from
		var to := line_segment.to
		if edge_map.has(from):
			if edge_map[from].has(to):
				ans.append(DirectionedEdge.new(edge_map[from][to], false))
		elif edge_map.has(to):
			if edge_map[to].has(from):
				ans.append(DirectionedEdge.new(edge_map[to][from], true))
	return ans

# Move Line
static func _calcu_remain_movement(movement_length : float, current_percentage : float, total_length : float, forward : bool = true) -> float:
	var percentage : float = movement_length / total_length
	if forward:
		if percentage + current_percentage <= 1.0: return 0.0
		else:
			var used : float = 1.0 - current_percentage
			var used_length : float = total_length * used
			return movement_length - used_length
	else:
		if current_percentage - percentage >= 0.0: return 0.0
		else:
			var used : float = current_percentage
			var used_length : float = total_length * used
			return movement_length - used_length
	return 0.0

static func _get_directioned_edge(edge : Edge, from : Vertice) -> DirectionedEdge:
	var inverted := edge.from != from
	return DirectionedEdge.new(edge, inverted)

class _MoveLineInfo extends RefCounted:
	var directioned_edge : DirectionedEdge
	var forward : bool = true
	
	func _init(directioned_edge : DirectionedEdge, forward : bool = true) -> void:
		self.directioned_edge = directioned_edge
		self.forward = forward
		pass
	pass

const DotSmoothSensitivity : float = 0.6

static func _move_line(puzzle_data : PuzzleData, line_data : LineData, remain_movement : Vector2, dot_smooth : bool = false) -> Vector2:
	var movement_normal := remain_movement.normalized()
	var current_edge : Edge = puzzle_data.get_edge_by_id(line_data.get_current_edge_id())
	var current_vertice : Vertice = line_data.get_current_vertice()
#	print(">>>>> ", movement_normal, current_vertice)
#	print(">>>>> ", current_edge)
	var from_vertice : Vertice = null
	var current_percentage : float = line_data.get_current_percentage()
	var current_normal : Vector2 = line_data.get_current_normal()
	var movement_length : float = remain_movement.length()
	var is_empty : bool = line_data.is_empty()
	var is_complete : bool = line_data.is_complete()
	if not is_empty: from_vertice = line_data.get_current_from_vertice()
	
	var from_normals : Array[_MoveLineInfo] = []
	var to_normals : Array[_MoveLineInfo] = []
	var start_normals : Array[_MoveLineInfo] = []
	
#	to_normals
	if line_data.pass_through(current_vertice):
		if current_edge != null:
			var dir_edge := _get_directioned_edge(current_edge, current_vertice)
			to_normals.append(_MoveLineInfo.new(dir_edge, false))
	else:
		for neighbour_idx in current_vertice.neighbours:
			var neighbour : Edge = puzzle_data.get_edge_by_id(neighbour_idx)
			var dir_edge := _get_directioned_edge(neighbour, current_vertice)
			to_normals.append(_MoveLineInfo.new(dir_edge, current_edge != neighbour))
#	from_normals
	if not is_empty:
		for neighbour_idx in from_vertice.neighbours:
			var neighbour : Edge = puzzle_data.get_edge_by_id(neighbour_idx)
			var dir_edge := _get_directioned_edge(neighbour, from_vertice)
			from_normals.append(_MoveLineInfo.new(dir_edge, current_edge == neighbour))
	
#	printt("from", from_normals.keys())
#	printt("to", to_normals.keys())
	
#	if in to normal only one chose include and it is back
	var is_end_segment : bool = to_normals.size() == 1 and to_normals[0].directioned_edge.to == from_vertice
	
#	print("=====================================================")
	var filtered_normals : Array
	if is_empty:
		filtered_normals.append_array(to_normals)
	else:
		if current_percentage < 0.5:
			filtered_normals.append_array(from_normals)
			filtered_normals.append(
				_MoveLineInfo.new(_get_directioned_edge(current_edge, current_vertice), false)
			)
		else:
			filtered_normals.append_array(to_normals)
			
			if not is_complete or is_end_segment:
				filtered_normals.append(
					_MoveLineInfo.new(_get_directioned_edge(current_edge, from_vertice), true)
				)
	
	if filtered_normals.size() == 0: return Vector2.ZERO
	var nearest_move_line : _MoveLineInfo = filtered_normals[0]
	var nearest_dot : float = movement_normal.dot(nearest_move_line.directioned_edge.normal)
	for i in range(1, filtered_normals.size()):
		var _nearest_move_line : _MoveLineInfo = filtered_normals[i]
		var dot : float = movement_normal.dot(_nearest_move_line.directioned_edge.normal)
		if dot > nearest_dot:
			nearest_move_line = _nearest_move_line
			nearest_dot = dot
	
	if nearest_dot <= 0: return Vector2.ZERO

	#	check if end
	if is_end_segment and current_edge == nearest_move_line.directioned_edge.edge and nearest_move_line.directioned_edge.to == current_vertice and is_equal_approx(current_percentage, 1.0):
		return Vector2.ZERO
	
	if dot_smooth:
		var dot := lerp(1.0, nearest_dot, DotSmoothSensitivity)
		movement_length = movement_length * abs(dot)
	
	var remained : Vector2 = Vector2.ZERO
	
	if is_complete and current_edge != nearest_move_line.directioned_edge.edge:
#		print(">>>> new line")
		line_data.add_edge_segment(nearest_move_line.directioned_edge.edge, movement_length/nearest_move_line.directioned_edge.length)
		remained = _calcu_remain_movement(movement_length, 0.0, nearest_move_line.directioned_edge.length, true) * movement_normal
	else:
		var forward : bool = true
		if nearest_move_line.forward:
#			print(">>>>> 1")
			line_data.forward(movement_length/ current_edge.length)
		else:
#			print(">>>>> 2")
			forward = false
			line_data.backward(movement_length/ current_edge.length)
		remained = _calcu_remain_movement(movement_length, current_percentage, current_edge.length, forward) * movement_normal

	line_data.clamp_line_end(puzzle_data.normal_radius, puzzle_data.start_radius)
	return remained

static func move_line(puzzle_data : PuzzleData, line_data : LineData, movement : Vector2, dot_smooth : bool = true) -> LineData:
	if is_zero_approx(movement.length_squared()): return line_data
	var new_line : LineData = line_data.duplicate()
	var count := 0
	while not is_zero_approx(movement.length_squared()) and count < 100:
		movement = _move_line(puzzle_data, new_line, movement, dot_smooth)
		count += 1
#	print(count)
	return new_line

# ====================================================================================================
static func pick_start_vertice(puzzle_data : PuzzleData, mouse_position : Vector2) -> Vertice:
	var last_vertice : Vertice = null
	var last_distance : float = INF
	for vertice in puzzle_data.vertices_start:
		var distance : float = vertice.position.distance_to(mouse_position)
		if distance <= puzzle_data.start_radius:
			if last_vertice == null:
				last_vertice = vertice
				last_distance = distance
			elif last_distance > distance:
				last_vertice = vertice
				last_distance = distance
	return last_vertice

static func generate_line_from_idxs(puzzle_data : PuzzleData, idxs : PackedInt32Array, end_percentage : float = 1.0) -> LineData:
	var start_idx := idxs[0]
	var start_vertice : Vertice = puzzle_data.get_vertice_by_id(start_idx)
	if start_vertice == null: return null
	var line := LineData.new(start_vertice)
	for i in range(1, idxs.size()):
		var edge : Edge = puzzle_data.get_edge_by_id(idxs[i])
		if edge == null: return line
		line.add_edge_segment(edge)
	if not line.is_empty():
		line.get_current_segment().set_percentage(end_percentage)
	return line

static func map_line_data(puzzle_data : PuzzleData, line_data : LineData, custom_data_key : StringName) -> Array:
	var ans : Array = []
	for elem in line_data.to_puzzle_elements(puzzle_data):
		if elem.has_custom_data(custom_data_key):
			ans.append(elem.get_custom_data(custom_data_key))
		else:
			return []
	return ans

# TODO refactor
static func get_valid_line(puzzle_data : PuzzleData, line_data : LineData) -> LineData:
	var new_line : LineData
	var vertices_count := puzzle_data.vertices.size()
	var last_vertice : Vertice = puzzle_data.get_vertice_by_id(line_data.start.id)
	if last_vertice == null: return null
	new_line = LineData.new(last_vertice)
	for segment in line_data.segments:
		if last_vertice.has_neighbour(segment.to.id):
			new_line.add_vertice_segment(segment.to, segment.percentage)
		else:
			return new_line
	return new_line

# get the percentage of a portion of the path
static func get_base_path_percentage(line_data : LineData, base_path : LineData, strict : bool = true, ) -> float:
	var vertices_base : Array[Vertice] = base_path.to_vertices()
	var vertices_line : Array[Vertice] = line_data.to_vertices()
	var vertices_base_size := vertices_base.size()
	var vertices_line_size := vertices_line.size()
	var start_vertice := vertices_base[0]
	var start_idx : int = 0
	while true:
		if start_idx >= vertices_line_size: return -1.0
		if vertices_line[start_idx] == start_vertice:
			break
		else: start_idx += 1
	var end_idx : int = 1
	if start_idx >= vertices_line_size - 1: return -1.0
	while true:
		if start_idx + end_idx >= vertices_line_size or end_idx >= vertices_base_size: break
		if vertices_line[start_idx + end_idx] != vertices_base[end_idx]:
			if strict: return -1.0
			else: break
		else: end_idx += 1
#	print(start_idx, end_idx)
	if start_idx + 1 > start_idx + end_idx - 1 : return -1.0
	var base_length : float = base_path.get_length()
	var line_length : float = line_data.get_length(start_idx + 1, start_idx + end_idx - 1)
#	printt(base_length, line_length, start_idx + 1, start_idx + end_idx - 1)
	if is_zero_approx(base_length):
		return 1.0
	return line_length / base_length

# Area Util
static func _get_area_neighbour_by_sround_edge_id(puzzle_data : PuzzleData, area : Area, edge_id : int) -> Array:
	if not area.srounds.has(edge_id): return []
	if not puzzle_data.area_neighbour_map.has(edge_id): return []
	var sround_areas : Array[Area] = puzzle_data.area_neighbour_map[edge_id].duplicate()
	sround_areas.erase(area)
	return sround_areas

static func _is_areas_neighbour(puzzle_data : PuzzleData, area1 : Area, area2 : Area) -> bool:
	for area_sround in puzzle_data.area_neighbour_map:
		if area_sround.has(area1) and area_sround.has(area2): return true
	return false

static func _reduce_linked_areas(puzzle_data : PuzzleData, edge_ids : PackedInt32Array, area : Area, ans : Array[Area]) -> void:
	for edge_id in area.srounds:
		if edge_ids.has(edge_id): continue
		var sround_areas : Array[Area] = _get_area_neighbour_by_sround_edge_id(puzzle_data, area, edge_id)
		for sub_area in sround_areas:
			if ans.has(sub_area): continue
			else:
				ans.append(sub_area)
				_reduce_linked_areas(puzzle_data, edge_ids, sub_area, ans)
	pass

static func get_isolated_areas(puzzle_data : PuzzleData, edge_ids : PackedInt32Array) -> Array:
	var areas : Array[Area] = puzzle_data.areas.duplicate()
	var ans = []
	while areas.size() > 0:
		var area : Area = areas.pop_back()
		var _ans : Array[Area] = [area]
		_reduce_linked_areas(puzzle_data, edge_ids, area, _ans)
		for sub_area in _ans:
			areas.erase(sub_area)
		ans.append(_ans)
	return ans

static func get_directional_sround_area(puzzle_data : PuzzleData, area : Area, sround_direction : int = 0) -> Area:
	if sround_direction < 0 or sround_direction >= area.srounds.size(): return null
	return puzzle_data.get_area_by_id(area.srounds[sround_direction])

# check puzzle answer main function
static func check_puzzle_answer(puzzle_data : PuzzleData, line_data : LineData) -> Array:
	var ans : Array[Decorator] = []
	var grouped_rule_element_map = {}
	for elem in puzzle_data.decorated_elements:
		for rule in elem.decorator.rules:
			if rule.handle_type == PuzzleRule.RuleHandleType.SELF:
				if not rule.check_rule(puzzle_data, line_data, elem):
					if not ans.has(elem.decorator):
						ans.append(elem.decorator)
			else:
				grouped_rule_element_map[rule] = elem
	if !grouped_rule_element_map.is_empty():
		var all_grouped_rules : Array[PuzzleRule] = grouped_rule_element_map.keys()
		var edge_ids : PackedInt32Array = line_data.get_edge_ids()
		var isolated_areas := get_isolated_areas(puzzle_data, edge_ids)
		for isolated_area in isolated_areas:
			var _all_grouped_rules := all_grouped_rules.duplicate()
			var rule_element_map = {}
			for rule in _all_grouped_rules:
				if isolated_area.has(grouped_rule_element_map[rule]):
					rule_element_map[rule] = grouped_rule_element_map[rule]
					all_grouped_rules.erase(rule)
			var wrong_decorators : Array[Decorator] = _check_puzzle_area_rules(puzzle_data, line_data, rule_element_map, isolated_area)
			for decorator in wrong_decorators:
				if not ans.has(decorator):
					ans.append(decorator)
		pass
	return ans

static func _check_puzzle_area_rules(puzzle_data : PuzzleData, line_data : LineData, rule_element_map : Dictionary, isolated_area : Array[Area]) -> Array:
	var rules := rule_element_map.keys()
	var rules_map : Dictionary = PuzzleRuleFunction.get_empty_grouped_rules_map()
	var wrong_decorator : Array[Decorator] = []
	for rule in rules:
		rules_map[rule.rule_type].append(rule)
	for key in rules_map:
		var _rules : Array[PuzzleRule] = rules_map[key]
		if _rules.is_empty(): continue
		var _wrong_rule : Array[PuzzleRule] = PuzzleRuleFunction.check_grouped_rules(key, puzzle_data, line_data, _rules, isolated_area)
		wrong_decorator.append_array(_wrong_rule.map(func (rule : PuzzleRule) -> Decorator: return rule_element_map[rule].decorator))
	return wrong_decorator
