extends Control

var puzzle_renderer : PuzzleRenderer
var puzzle_data : PuzzleData

var puzzle_line : LineData
var relative : Vector2 = Vector2.ZERO
var is_waiting_for_comfirm : bool = false
var game_save_data_select_path : LineData
var game_save_data_summarys : Array[GameSaveDataSummary]

const hboxscene = preload("res://GameUI/HBoxContainer.tscn")

func _ready() -> void:
	pass

enum EndFunction {
	SWITCH_MOUSE_CURSOR = -10,
	SAVE_AND_EXIT = -9,
	FORCE_EXIT = -8
}

func create_menu_puzzle() -> void:
	%CoverA.material.set_shader_param("opacity", 0.0)
	%CoverB.material.set_shader_param("opacity", 0.0)
	for child in %CenterContainer.get_children():
		%CenterContainer.remove_child(child)
		child.queue_free()
	for child in %GameSaveDataList.get_children():
		%GameSaveDataList.remove_child(child)
		child.queue_free()
#	summarys
	const level_start_position_y : int = 100
	const level_end_position_y : int = 780
	var puzzle_json := JsonResource.new({
		"areas": [ ],
		"board": {
			"background_color": [ 1.0, 0.0, 0.0, 0.0 ],
			"background_line_color": [ 0.35, 0.35, 0.35, 1 ],
			"base_size": [400, 850],
			"lines":[
				{
					"correct": [ 1.0, 0.2, 0.0, 1 ],
					"drawing": [ 1, 0.75, 0.00, 1 ],
				}
			],
			"normal_radius": 18,
			"start_radius": 60
		},
		"decorators": [],
		"edges": [
			{
				"from": 4,
				"to": 0
			},
			{
				"from": 4,
				"to": 1
			},
			{
				"from": 2,
				"to": 3
			}
		],
		"points": [
			{
#				0 LEFT CLOSE
				"position": [90,level_start_position_y],
				"type": 1,
				"tag": EndFunction.SWITCH_MOUSE_CURSOR
			},
			{
#				1 RIGHT EXIT
				"position": [310,level_start_position_y],
				"type": 1,
				"tag": EndFunction.FORCE_EXIT
			},
			{
#				2 BOTTOM EXIT - 1
				"position": [200,level_end_position_y],
				"type": 1,
			},
			{
#				3 BOTTOM EXIT - 2
				"position": [310,level_end_position_y],
				"type": 1,
				"tag": EndFunction.SAVE_AND_EXIT
			},
			{
#				4 START
				"position": [200,level_start_position_y],
				"type": 0
			},
		]
	})
#	add_level_point
	game_save_data_summarys = GameSaver.get_all_summarys()
	var summarys := game_save_data_summarys
	var start_position : float = level_start_position_y + puzzle_json.data.board.start_radius / 2.0
	var length : float = level_end_position_y - start_position
	var count := summarys.size() + 1
	var current_idx : int = 0
	var link_level_point_idx : PackedInt32Array = []
	var level_end_idx : int = puzzle_json.data.points.size() - 1
	puzzle_json.data.points.append_array([{
		"position": [200, start_position],
		"type": 3
	}])
	puzzle_json.data.edges.append_array([{
		"from": level_end_idx,
		"to": level_end_idx + 1
	}])
	level_end_idx += 1
	var level_start_point_idx : int = level_end_idx
	for summary in summarys:
#		var hbox := hboxscene.instantiate()
#		hbox.texture = summary.cover_texture
#		hbox.title = "{time} {answered}/6".format(summary.info)
#		%GameSaveDataList.add_child(hbox)
		puzzle_json.data.points.append_array([
			{
				"position": [200,start_position + (current_idx + 1)*(length/count)],
				"type": 3,
			},
			{
				"position": [260,start_position + (current_idx + 1)*(length/count)],
				"type": 1,
				"tag": current_idx + 1
			}
		])
		puzzle_json.data.edges.append_array([
			{
				"from": level_end_idx - 1 if current_idx != 0 else level_end_idx,
				"to": level_end_idx + 1
			},
			{
				"from": level_end_idx + 1,
				"to": level_end_idx + 2
			}
		])
		link_level_point_idx.append(level_end_idx + 1)
		level_end_idx += 2
		current_idx += 1
	if count == 1:
		puzzle_json.data.edges.append_array([{
			"from": level_end_idx,
			"to": 2
		}])
	else:
		puzzle_json.data.edges.append_array([{
			"from": level_end_idx - 1,
			"to": 2
		}])
	puzzle_data = PuzzleData.new(puzzle_json)
	puzzle_renderer = PuzzleRenderer.new(puzzle_data, Vector2i(puzzle_data.base_size))
	%CenterContainer.add_child(puzzle_renderer)
	game_save_data_select_path = LineData.new(puzzle_data.vertices[level_start_point_idx])
	for idx in link_level_point_idx:
		game_save_data_select_path.add_line_segemnt(puzzle_data.vertices[idx])
#	print(game_save_data_select_path)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		exit_ui()
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		on_confirm()
	if event is InputEventMouseMotion:
		relative += event.relative

func exit_ui() -> void:
	get_tree().paused = false
	visible = false
	return

func _process(delta: float) -> void:
	var mouse_delta := relative * GlobalData.Mouse2DSensitivity
	relative = Vector2.ZERO
	var new_line := PuzzleFunction.move_line(puzzle_data, puzzle_line, mouse_delta)
	puzzle_line = new_line
	puzzle_renderer.set_puzzle_line(0, puzzle_line)
	var game_save_data_select_path_percentage : float = PuzzleFunction.get_base_path_percentage(puzzle_line, game_save_data_select_path, false)
	var count : Vector2 = %GameSaveDataList.size
	if game_save_data_select_path_percentage >= 0.0:
		var max_count : int = game_save_data_summarys.size()
		var target_idx : int = floor(game_save_data_select_path_percentage * (max_count))
		var segment_percentage : float = 1.0 / float(max_count)
		var step_percentage : float = fmod(game_save_data_select_path_percentage, segment_percentage)/segment_percentage
#		printt(target_idx, step_percentage)
		if is_zero_approx(step_percentage) or is_equal_approx(step_percentage, 1.0):
			if target_idx - 1 >= 0:
				step_percentage = 1.0
			target_idx = clampi(target_idx - 1, 0, max_count - 1)
		var a_texture : ImageTexture = null if target_idx == 0 else game_save_data_summarys[target_idx - 1].cover_texture
		var b_texture : ImageTexture = game_save_data_summarys[target_idx].cover_texture
#		printt(target_idx, step_percentage)
		%CoverA.texture = a_texture
		%CoverB.texture = b_texture
		%CoverA.material.set_shader_param("opacity", clampf((1.0 - step_percentage) * 2.0, 0.0, 1.0))
		%CoverB.material.set_shader_param("opacity", clampf((step_percentage - 0.5) * 2.0, 0.0, 1.0))
#		%GameSaveDataList.offset_left = 0
#		%GameSaveDataList.offset_top = game_save_data_select_path_percentage * count.y * -2 + count.y
	else:
		%CoverA.material.set_shader_param("opacity", 0.0)
		%CoverB.material.set_shader_param("opacity", 0.0)
	update_confirm_state(puzzle_line)

func _notification(what: int) -> void:
	if what == NOTIFICATION_UNPAUSED:
		on_menu_open()

func on_menu_open() -> void:
	create_menu_puzzle()
	visible = true
	puzzle_line = LineData.new(puzzle_data.vertices[4])
	puzzle_renderer.set_puzzle_line(0, puzzle_line)
	puzzle_renderer.create_start_tween()
	%GameSaveDataList.offset_top = %GameSaveDataList.size.y

func on_confirm(force_cancel : bool = false) -> void:
	if force_cancel or not is_waiting_for_comfirm:
		return
	else:
		var correct_tag := check_puzzle_ans()
		on_puzzle_answered(correct_tag)

# -1 is wrong >= 0 means different correct ans's tags
func check_puzzle_ans() -> int:
	var last_vertice := puzzle_line.get_current_vertice()
	return last_vertice.tag

func update_confirm_state(line_data : LineData) -> void:
	var current_vertice : Vertice = line_data.get_current_vertice()
	var current_percentage : float = line_data.get_current_percentage()
	if current_vertice.type == Vertice.VerticeType.END and current_percentage > 0.9:
		if not is_waiting_for_comfirm:
			is_waiting_for_comfirm = true
			on_waiting_to_confirm_changed(true)
	else:
		if is_waiting_for_comfirm:
			is_waiting_for_comfirm = false
			on_waiting_to_confirm_changed(false)

func on_waiting_to_confirm_changed(is_waiting : bool) -> void:
	if is_waiting_for_comfirm:
		puzzle_renderer.create_highlight_tween()
	else:
		puzzle_renderer.create_exit_highlight_tween()

func on_puzzle_answered(tag : int) -> void:
	match tag:
		EndFunction.SAVE_AND_EXIT:
			await GameSaver.save_game_save_data_resource()
			get_tree().quit()
		EndFunction.FORCE_EXIT:
#			GameSaver.restart_current_game_save()
#			exit_ui()
			get_tree().quit()
		EndFunction.SWITCH_MOUSE_CURSOR:
			match Input.get_mouse_mode():
				Input.MOUSE_MODE_CAPTURED:
					Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				Input.MOUSE_MODE_VISIBLE:
					Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		_:
			var level_key : String = game_save_data_summarys[tag-1].key
			Debugger.print_tag("Select Save", level_key, Color.DEEP_SKY_BLUE)
			exit_ui()
			GameSaver.load_game_save(level_key, true)
