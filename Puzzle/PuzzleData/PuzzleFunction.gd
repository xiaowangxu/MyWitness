class_name PuzzleFunction
extends RefCounted

static func line_to_edges(puzzle_data : PuzzleData, line : LineData) -> Array:
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
				ans.append(DirectionedEdge.new(edge_map[to][from], false))
	return ans

static func around_area_edges_count(directioned_edges : Array[DirectionedEdge], area : Area) -> int:
	var edges : Array[Edge] = directioned_edges.map(func(i : DirectionedEdge):return i.edge)
	var count : int = 0
	for edge in area.srounds:
		if edges.has(edge): count += 1
	return count

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

static func _move_line(puzzle_data : PuzzleData, line_data : LineData, remain_movement : Vector2) -> Vector2:
	var movement_normal := remain_movement.normalized()
	var current_vertice : Vertice = line_data.get_current_vertice()
	var from_vertice : Vertice = null
	var current_percentage : float = line_data.get_current_percentage()
	var current_normal : Vector2 = line_data.get_current_normal()
	var movement_length : float = remain_movement.length()
	var is_empty : bool = line_data.is_empty()
	var is_complete : bool = line_data.is_complete()
	if not is_empty: from_vertice = line_data.get_from_vertice()
	
	var from_normals : Dictionary = {}
	var to_normals : Dictionary = {}
	
#	to_normals
	if line_data.pass_through(current_vertice):
		to_normals[from_vertice] = {
			"normal": -line_data.get_current_normal(),
			"length": line_data.get_current_segment_length()
		}
	else:
		for neighbour_idx in current_vertice.neighbours:
			var neighbour : Edge = puzzle_data.edges[neighbour_idx]
#			if not is_empty and from_vertice != neighbour.get_forward_vertice(current_vertice):
			to_normals[neighbour.get_forward_vertice(current_vertice)] = {
				"normal": neighbour.get_normal(current_vertice),
				"length": neighbour.length
			}
	
#	from_normals
	if not is_empty:
		for neighbour_idx in from_vertice.neighbours:
			var neighbour : Edge = puzzle_data.edges[neighbour_idx]
#			if line_data.get_current_vertice() != neighbour.get_forward_vertice(from_vertice):
			from_normals[neighbour.get_forward_vertice(from_vertice)] = {
				"normal": neighbour.get_normal(from_vertice),
				"length": neighbour.length
			}
	
#	printt("from", from_normals.keys())
#	printt("to", to_normals.keys())
	var is_end_segment : bool = to_normals.size() == 1 and to_normals.keys()[0] == from_vertice
	
	var vertices : Array[Vertice]
	var normals : Dictionary
	if is_empty:
		normals = to_normals
		vertices = normals.keys()
	else:
		if current_percentage < 0.5:
			normals = from_normals
			vertices = normals.keys()
#			if vertices.size() == 1 and vertices[0] == current_vertice:
#			if not is_complete:
			normals[from_vertice] = to_normals[from_vertice]
			vertices.append(from_vertice)
		else:
			normals = to_normals
			vertices = normals.keys()
			if not is_complete or is_end_segment:
				normals[current_vertice] = from_normals[current_vertice]
				vertices.append(current_vertice)
	
	if vertices.size() == 0: return Vector2.ZERO
	var nearest_vertice : Vertice = vertices[0]
	var nearest_dot : float = movement_normal.dot(normals[nearest_vertice].normal)
	var nearest_length : float = normals[nearest_vertice].length
	for i in range(1, vertices.size()):
		var vertice : Vertice = vertices[i]
		var dot : float = movement_normal.dot(normals[vertice].normal)
		if dot > nearest_dot:
			nearest_vertice = vertice
			nearest_dot = dot
			nearest_length = normals[vertice].length
	
#	print(nearest_vertice)
	if nearest_dot <= 0: return Vector2.ZERO
	#	check if end
	if is_end_segment and nearest_vertice == current_vertice and is_equal_approx(current_percentage, 1.0):
		return Vector2.ZERO
	
#	var dot := current_normal.dot(movement_normal)
#	if is_empty:
#		dot = nearest_dot
#	movement_length = movement_length * abs(dot)

	var remained : Vector2 = Vector2.ZERO
	if is_empty or (is_complete and nearest_vertice != from_vertice and nearest_vertice != current_vertice):
		line_data.add_line_segemnt(nearest_vertice, movement_length/nearest_length)
		remained = _calcu_remain_movement(movement_length, 0.0, nearest_length, true) * movement_normal
	else:
		var segment_length : float = line_data.get_current_segment_length()
		var forward : bool = true
		if nearest_vertice in from_normals:
			if nearest_vertice == current_vertice:
#				print(">>>>>1")
				line_data.forward(movement_length/segment_length)
			else:
#				print(">>>>>2")
				forward = false
				line_data.backward(movement_length/segment_length)
		else:
			if nearest_vertice == from_vertice:
#				print(">>>>>3")
				forward = false
				line_data.backward(movement_length/segment_length)
			else:
#				print(">>>>>4")
				line_data.forward(movement_length/segment_length)
		remained = _calcu_remain_movement(movement_length, current_percentage, segment_length, forward) * movement_normal
	
	line_data.clamp_line_end(puzzle_data.normal_radius, puzzle_data.start_radius)
	return remained

static func move_line(puzzle_data : PuzzleData, line_data : LineData, movement : Vector2) -> LineData:
	if is_zero_approx(movement.length_squared()): return line_data
	var new_line : LineData = line_data.duplicate()
#	var count := 0
	while not is_zero_approx(movement.length_squared()):
		movement = _move_line(puzzle_data, new_line, movement)
#		count += 1
#		movement = Vector2.ZERO
#	print(count)
	return new_line

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

static func generate_line_from_idxs(puzzle_data : PuzzleData, idxs : PackedInt32Array) -> LineData:
	var start_idx := idxs[0]
	var line := LineData.new(puzzle_data.vertices[start_idx])
	for i in range(1, idxs.size()):
		line.add_line_segemnt(puzzle_data.vertices[idxs[i]])
	return line

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
