extends PuzzlePanel

func set_puzzle_line(line_data : LineData) -> void:
	super(line_data)
	var mirror_vertices_id := PuzzleFunction.map_line_data(puzzle_data, line_data, "mirror")
	print(mirror_vertices_id)
	var mirror_line := PuzzleFunction.generate_line_from_idxs(puzzle_data, mirror_vertices_id, line_data.get_current_percentage())
#	print(mirror_line)
	get_base_viewport_instance().puzzle_renderer.set_puzzle_line(0, line_data)
	get_base_viewport_instance().puzzle_renderer.set_puzzle_line(1, mirror_line)
