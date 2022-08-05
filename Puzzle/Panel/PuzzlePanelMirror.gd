extends PuzzlePanel

static func get_mirror_data(data, segment, element : PuzzleElement):
	match typeof(data):
		TYPE_DICTIONARY:
			if segment is Vertice:
				return data[str(segment.id)]
			elif segment is LineDataSegment:
				return data[str(segment.from.id)]
			else:
				return data.values()[0]
		_:
			return data
	return data

func get_is_clamped(line_data : LineData) -> bool:
	var mirror_vertices_id := PuzzleFunction.map_line_data(puzzle_data, line_data, "mirror", get_mirror_data)
	var mirror_line := PuzzleFunction.generate_line_from_idxs(puzzle_data, mirror_vertices_id, line_data.get_current_segment_length(), true)
	mirror_line.validate()
	line_data.clamp_to_length(mirror_line.get_length())
	var first_collision_idx : int = LineData.find_first_collision([line_data, mirror_line])
	return first_collision_idx != -1

func on_move_finished(line_data : LineData, puzzle_position : Vector2 = Vector2.ZERO, mouse_position : Vector3 = Vector3.ZERO, world_position : Vector3 = Vector3.ZERO) -> Vector2:
	var mirror_vertices_id := PuzzleFunction.map_line_data(puzzle_data, line_data, "mirror", get_mirror_data)
	var mirror_line := PuzzleFunction.generate_line_from_idxs(puzzle_data, mirror_vertices_id, line_data.get_current_segment_length(), true)
	mirror_line.validate()
	line_data.clamp_to_length(mirror_line.get_length())
	
	var first_collision_idx : int = LineData.find_first_collision([line_data, mirror_line])
	if first_collision_idx != -1:
		line_data.clamp_to_nth(first_collision_idx)
		mirror_line.clamp_to_nth(first_collision_idx)
		LineDataSegment.collide_segments_pair(line_data.get_current_segment(), mirror_line.get_current_segment(), puzzle_data.normal_radius)
		line_data.normalize()
		mirror_line.normalize()
#	var collision_idx : int = line_data.find_first_collision_with_another_line(mirror_line)
#	if collision_idx != -1:
#		var collision := line_data.get_nth_segment(collision_idx)
#		var mirror_collision := mirror_line.get_nth_segment(collision_idx)
##		printt(collision.edge_id, mirror_collision.edge_id)
#		line_data.clamp_to_segment(collision)
#		mirror_line.clamp_to_segment(mirror_collision)
#		LineDataSegment.collide_segments_pair(collision, mirror_collision, puzzle_data.normal_radius)
#		line_data.normalize()
#		mirror_line.normalize()
#	var meet_idx : int = mirror_line.find_first_collision_with_another_vertice(line_data.get_current_vertice())
#	print(meet_idx)
		
	return line_data.get_current_position()

func set_puzzle_line(line_data : LineData) -> void:
	var mirror_vertices_id := PuzzleFunction.map_line_data(puzzle_data, line_data, "mirror", get_mirror_data)
	var mirror_line := PuzzleFunction.generate_line_from_idxs(puzzle_data, mirror_vertices_id, line_data.get_current_segment_length(), true)
##	print(mirror_line)
	get_base_viewport_instance().puzzle_renderer.set_puzzle_line(0, line_data)
	get_base_viewport_instance().puzzle_renderer.set_puzzle_line(1, mirror_line)
