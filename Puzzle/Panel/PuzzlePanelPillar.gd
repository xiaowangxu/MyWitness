extends PuzzlePanel

func mouse_to_local(pos : Vector3) -> Vector3:
#	print(pos)
	var trans := global_transform.affine_inverse()
	var ans := trans * pos
#	print(ans)
	ans.y *= -1
	var scaled := Vector3(0.5,(ans.y+2.8)/(5.6),0)
	var ang := -Vector2(ans.x, ans.z).rotated(-PI/2).angle()
	scaled.x = ang/TAU + 0.5
	scaled.x *= viewport_size.x
	scaled.y *= viewport_size.y
	return scaled

func mouse_to_global(pos : Vector3) -> Vector3:
#	print(">> ", pos)
	var trans := global_transform
	var scaled := pos
	scaled.x /= viewport_size.x
	scaled.x  = -(scaled.x - 0.5) * TAU
	var ang := Vector2.from_angle(scaled.x).rotated(PI/2)
	scaled.x = ang.x
	scaled.z = ang.y
	scaled.y /= viewport_size.y
	scaled.y = scaled.y*5.6-2.8
	scaled.y *= -1
	var ans := trans * scaled
	return ans

func get_preferred_transform(player_transform: Transform3D) -> Transform3D:
	var player_position := player_transform.origin
	var position_vec3 := (player_position - self.global_transform.origin).normalized()
	var angle := Vector2(position_vec3.x, -position_vec3.z).angle()
	var angle2 := Vector2(position_vec3.x, position_vec3.z).angle()
	var normalized_position := self.global_transform.origin + Vector3.RIGHT.rotated(Vector3.UP, angle) * 3
	normalized_position.y = 0.0
	var preferred_transform := Transform3D(Basis(Quaternion(Vector3(0,PI/2+angle,0))), normalized_position)#Basis(Quaternion(Vector3(0,0,0)))
	return preferred_transform

#var last_angle : float = 0.0
#func on_puzzle_started(line_data : LineData, puzzle_position : Vector2, mouse_position : Vector3, world_position : Vector3) -> void:
#	is_waiting_for_comfirm = false
#	current_position = puzzle_position
#	puzzle_line = LineData.new(start_vertice)
#	GlobalData.set_mouse_position_from_world(world_position)
#	GlobalData.set_active_puzzle_panel(self)
#	GlobalData.set_cursor_state(GlobalData.CursorState.DRAWING)
#	set_puzzle_line(puzzle_line)
#	base_viewport_instance.puzzle_renderer.create_start_tween()
#	play_sound("start")
#	var position_vec3 := (world_position - self.global_transform.origin).normalized()
#	last_angle = Vector2(position_vec3.x, position_vec3.z).angle()
#	pass

func on_move_finished(line_data : LineData, puzzle_position : Vector2 = Vector2.ZERO, mouse_position : Vector3 = Vector3.ZERO, world_position : Vector3 = Vector3.ZERO) -> Vector2:
	var position_vec3 := (world_position - self.global_transform.origin).normalized()
	var angle := Vector2(position_vec3.x, -position_vec3.z).angle()
	var angle2 := Vector2(position_vec3.x, position_vec3.z).angle()
	var normalized_position := self.global_transform.origin + Vector3.RIGHT.rotated(Vector3.UP, angle) * 3
	normalized_position.y = 0.0
	GlobalData.get_player().move_and_rotate_to_transform(Transform3D(Basis(Quaternion(Vector3(0,PI/2+angle,0))), normalized_position))
	return puzzle_position
