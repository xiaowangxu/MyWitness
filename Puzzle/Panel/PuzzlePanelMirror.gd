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

func on_move_finished(line_data : LineData, puzzle_position : Vector2 = Vector2.ZERO, mouse_position : Vector3 = Vector3.ZERO, world_position : Vector3 = Vector3.ZERO) -> Vector2:
	var mirror_vertices_id := PuzzleFunction.map_line_data(puzzle_data, line_data, "mirror", get_mirror_data)
	var mirror_line := PuzzleFunction.generate_line_from_idxs(puzzle_data, mirror_vertices_id, line_data.get_current_segment_length(), true)
	mirror_line.validate()
	line_data.clamp_to_length(mirror_line.get_length())
	return line_data.get_current_position()

func set_puzzle_line(line_data : LineData) -> void:
	super(line_data)
	var mirror_vertices_id := PuzzleFunction.map_line_data(puzzle_data, line_data, "mirror", get_mirror_data)
	var mirror_line := PuzzleFunction.generate_line_from_idxs(puzzle_data, mirror_vertices_id, line_data.get_current_segment_length(), true)
##	print(mirror_line)
	get_base_viewport_instance().puzzle_renderer.set_puzzle_line(0, line_data)
	get_base_viewport_instance().puzzle_renderer.set_puzzle_line(1, mirror_line)
