extends Control

var puzzle_renderer : PuzzleRenderer
var puzzle_data : PuzzleData

var puzzle_line : LineData
var relative : Vector2 = Vector2.ZERO
var is_waiting_for_comfirm : bool = false
var exit_base_path : LineData
var new_base_path : LineData

func _ready() -> void:
	var puzzle_json := JsonResource.new({
		"areas": [ ],
		"board": {
			"background_color": [ 1.0, 0.0, 0.0, 0 ],
			"background_line_color": [ 0.35, 0.35, 0.35, 1 ],
			"base_size": [450, 900],
			"line_correct_color": [ 1.0, 0.2, 0.0, 1 ],
			"line_drawing_color": [ 1, 0.75, 0.00, 1 ],
			"normal_radius": 18,
			"start_radius": 60
		},
		"decorators": [],
		"edges": [
			{
				"from": 0,
				"to": 1
			},
			{
				"from": 0,
				"to": 2
			},
			{
				"from": 2,
				"to": 3
			},
			{
				"from": 2,
				"to": 4
			},
			{
				"from": 4,
				"to": 5
			},
			{
				"from": 5,
				"to": 6
			},
			{
				"from": 6,
				"to": 7
			},
			{
				"from": 7,
				"to": 8
			},
			{
				"from": 0,
				"to": 9
			}
		],
		"points": [
			{
				"position": [200,100],
				"type": 0
			},
			{
				"position": [310,100],
				"type": 1,
				"tag": 1024
			},
			{
				"position": [200,700],
				"type": 3
			},
			{
				"position": [275,700],
				"type": 1
			},
			{
				"position": [200,780],
				"type": 1
			},
			{
				"position": [275,780],
				"type": 3
			},
			{
				"position": [325,830],
				"type": 3
			},
			{
				"position": [400,830],
				"type": 3
			},
			{
				"position": [350,780],
				"type": 1,
				"tag": 666
			},
			{
				"position": [90,100],
				"type": 1,
				"tag": 233
			}
		]
	})
	puzzle_data = PuzzleData.new(puzzle_json)
	puzzle_renderer = PuzzleRenderer.new(puzzle_data, Vector2i(450, 900))
	%CenterContainer.add_child(puzzle_renderer)
	exit_base_path = LineData.new(puzzle_data.vertices[0])
	exit_base_path.add_line_segemnt(puzzle_data.vertices[2])
	exit_base_path.add_line_segemnt(puzzle_data.vertices[3])
	new_base_path = LineData.new(puzzle_data.vertices[0])
	new_base_path.add_line_segemnt(puzzle_data.vertices[1])
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		get_tree().paused = false
		visible = false
		return
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		on_confirm()
	if event is InputEventMouseMotion:
		relative += event.relative

func _process(delta: float) -> void:
	var mouse_delta := relative * GlobalData.Mouse2DSensitivity
	relative = Vector2.ZERO
	var new_line := PuzzleFunction.move_line(puzzle_data, puzzle_line, mouse_delta)
	puzzle_line = new_line
	puzzle_renderer.set_puzzle_line(0, puzzle_line)
	var exit_percentage : float = PuzzleFunction.get_base_path_percentage(puzzle_line, exit_base_path, false)
	var new_percentage : float = PuzzleFunction.get_base_path_percentage(puzzle_line, new_base_path)
	var count : Vector2 = %GameSaveDataList.size
	if exit_percentage >= 0.0:
		%GameSaveDataList.offset_left = 0
		%GameSaveDataList.offset_top = exit_percentage * count.y * -2 + count.y
	elif new_percentage >= 0.0:
		%GameSaveDataList.offset_top = count.y
		%GameSaveDataList.offset_left = new_percentage * 500
	update_confirm_state(puzzle_line)

func _notification(what: int) -> void:
	if what == NOTIFICATION_UNPAUSED:
		on_menu_open()

func on_menu_open() -> void:
	visible = true
	puzzle_line = LineData.new(puzzle_data.vertices[0])
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
		666:
			await GameSaver.save_game_save_data_resource()
			get_tree().quit()
		233:
			match Input.get_mouse_mode():
				Input.MOUSE_MODE_CAPTURED:
					Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				Input.MOUSE_MODE_VISIBLE:
					Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
