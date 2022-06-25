class_name PuzzlePanel
extends Interactable

const AudioSoundEffects = {
#	"start": preload("res://SoundEffects/Puzzle/PuzzleStart.wav"),
	"start": preload("res://SoundEffects/Puzzle/PuzzleError.wav"),
	"error": preload("res://SoundEffects/Puzzle/PuzzleError2.wav"),
}

signal move_finished(line_data : LineData, puzzle_position : Vector2, mouse_position : Vector3, world_position : Vector3)
signal puzzle_answered(correct : bool)
signal puzzle_started()
signal puzzle_exited()

@export var puzzle_name : String = ""

@export var ViewportConfig : Array[Dictionary] = [{
	"name": "base",
	"visual": 0b1111,
	"target": PackedStringArray(["albedo_texture", "emission_texture"]),
	"transparent": false
}]

@export_flags("Albedo", "Emssion") var material_textures_target : int = 3

@onready var mesh : MeshInstance3D = $Mesh
@onready var area : Area3D = $Area
@onready var audio : AudioStreamPlayer = $Audio

var viewport : SubViewport = SubViewport.new()
var viewport_size : Vector2
var puzzle_texture : ViewportTexture
@onready var puzzle_data : PuzzleData = GlobalData.AllPuzzleData[puzzle_name]
@export_flags("Background", "Board", "Decorators", "Line") var _base_puzzle_config : int = 0b1111
@onready var puzzlerenderer : PuzzleRenderer = PuzzleRenderer.new(puzzle_data, GlobalData.PuzzleViewportSizes.regular, _base_puzzle_config)
var puzzle_line : LineData = null

#var test_cursor := preload("res://Puzzle/TestCursor.tscn").instantiate()
var test_info := preload("res://Puzzle/Panel/PuzzzlePanelInfo.tscn").instantiate()
func _ready() -> void:
	viewport.transparent_bg = true
	move_finished.connect(on_move_finished)
	puzzle_answered.connect(on_puzzle_answered)
	puzzle_started.connect(on_puzzle_started)
	puzzle_exited.connect(on_puzzle_exited)
	area.add_to_group(GlobalData.PuzzleGroupName)
	(area as Area3D).collision_layer = 0b00000000000000000000000000000001
	(area as Area3D).monitorable = false
	(area as Area3D).monitoring = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	viewport_size = GlobalData.PuzzleViewportSizes.regular
	viewport.size = viewport_size
	audio.bus = GlobalData.PuzzleSoundEffectsBus
	add_child(viewport)
#	viewport.add_child(test_cursor)
	viewport.add_child(puzzlerenderer)
	if has_node("PostEffect"):
		var post_effect : ColorRect = get_node("PostEffect")
		remove_child(post_effect)
		puzzlerenderer.add_child(post_effect)
	if has_node("Background"):
		var background :  = get_node("Background")
		remove_child(background)
		puzzlerenderer.add_child(background)
		puzzlerenderer.move_child(background, 0)
	puzzlerenderer.state_changed.connect(on_puzzle_state_changed)
	viewport.add_child(test_info)
	test_info.puzzle_name = puzzle_name
	set_texture()
	pass

func set_texture() -> void:
	var mat = mesh.get_active_material(0)
	puzzle_texture = viewport.get_texture()
	if material_textures_target & 1:
		mat.albedo_texture = puzzle_texture
	if material_textures_target & 2:
		mat.emission_texture = puzzle_texture

var current_position : Vector2 = Vector2.ZERO
func input_event(event : InputEvent, mouse_position : Vector3, world_position : Vector3) -> void:
#	print(">>>>> ", event)
#	print("| pos ", mouse_position)
	if event is InputPuzzleForceExitEvent:
		if puzzle_line != null:
			on_confirm(true)
			return
	if event is InputEventMouseButton and event.is_pressed():
		if (event as InputEventMouseButton).button_index == MOUSE_BUTTON_RIGHT or (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			if puzzle_line != null:
				on_confirm((event as InputEventMouseButton).button_index == MOUSE_BUTTON_RIGHT)
				return
	if event is InputEventMouseButton and event.is_pressed() and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		if puzzle_line != null: return
		current_position = puzzlerenderer.panel_to_puzzle(Vector2(mouse_position.x, mouse_position.y))
#		can start ?
		var start_vertice : Vertice = PuzzleFunction.pick_start_vertice(puzzle_data, current_position)
		if start_vertice != null:
			puzzle_line = LineData.new(start_vertice)
			puzzlerenderer.set_puzzle_line(0, puzzle_line)
			puzzlerenderer.create_start_tween()
			current_position = start_vertice.position
			var mouse_pos : Vector2 = puzzlerenderer.puzzle_to_panel(current_position)
			GlobalData.set_mouse_position_from_world(mouse_to_global(Vector3(mouse_pos.x, mouse_pos.y, 0)))
			GlobalData.set_active_puzzle_panel(self)
			GlobalData.set_cursor_state(GlobalData.CursorState.DRAWING)
			puzzle_started.emit()
	pass

func get_current_mouse_position() -> Vector3:
	var panel_position : Vector2 = puzzlerenderer.puzzle_to_panel(current_position)
	return mouse_to_global(Vector3(panel_position.x, panel_position.y, 0.0))

func on_mouse_moved(pos : Vector3) -> Vector3:
	var local = mouse_to_local(pos)
	var new_pos : Vector2 = puzzlerenderer.panel_to_puzzle(Vector2(local.x, local.y))
	var delta := new_pos - current_position
	test_info.puzzle_movement = delta
	current_position = new_pos
#	test_cursor.position = puzzlerenderer.puzzle_to_panel(current_position)

	var new_line : LineData = PuzzleFunction.move_line(puzzle_data, puzzle_line, delta)
#	var diff := puzzle_line.difference(new_line)
#	print("============================================")
#	print("old  ", puzzle_line)
#	print("new  ", new_line)
#	print("diff ", diff.difference)
	puzzle_line = new_line
	var end_position : Vector2 = new_line.get_current_position()
	var mouse_pos : Vector2 = puzzlerenderer.puzzle_to_panel(end_position)
	current_position = end_position
	var mouse_position : Vector3 = Vector3(mouse_pos.x, mouse_pos.y, 0)
	var world_position : Vector3 = mouse_to_global(mouse_position)
	move_finished.emit(puzzle_line, end_position, mouse_position, world_position)
	return world_position

func mouse_to_local(pos : Vector3) -> Vector3:
	var trans := global_transform.affine_inverse()
	var ans := trans * pos
	ans.y *= -1
	var scaled := (ans + Vector3(0.5,0.5,0))
	scaled.x *= viewport_size.x
	scaled.y *= viewport_size.y
	return scaled

func mouse_to_global(pos : Vector3) -> Vector3:
	var trans := global_transform
	var scaled := pos
	scaled.x /= viewport_size.x
	scaled.y /= viewport_size.y
	scaled -= Vector3(0.5, 0.5, 0)
	scaled.y *= -1
	var ans := trans * scaled
	return ans

# puzzle logic
func on_puzzle_state_changed(state : PuzzleRenderer.State) -> void:
#	print(state)
	match state:
		0: # PuzzleRenderer.State.DRAWING
			viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		2: # PuzzleRenderer.State.STOPPED
			viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	pass

var is_waiting_for_comfirm : bool = false
func on_confirm(force_cancel : bool = false) -> void:
	if force_cancel or not is_waiting_for_comfirm:
		exit_puzzle()
	else:
		puzzle_answered.emit(true)

func exit_puzzle() -> void:
	puzzle_line = null
	GlobalData.set_cursor_state(GlobalData.CursorState.PICKING)
	puzzlerenderer.create_exit_tween()
	puzzle_exited.emit()
	pass

func on_puzzle_answered(correct : bool) -> void:
	if correct:
		play_sound("error")
		puzzle_line.forward(1.0)
		puzzlerenderer.set_puzzle_line(0, puzzle_line)
		puzzle_line = null
		puzzlerenderer.create_error_tween()
		GlobalData.set_cursor_state(GlobalData.CursorState.PICKING)
	else:
		play_sound("start")
		puzzle_line.forward(1.0)
		puzzlerenderer.set_puzzle_line(0, puzzle_line)
		puzzle_line = null
		puzzlerenderer.create_correct_tween()
		GlobalData.set_cursor_state(GlobalData.CursorState.PICKING)
	pass

func on_puzzle_started() -> void:
	is_waiting_for_comfirm = false
	play_sound("start")
	pass

func on_puzzle_exited() -> void:
	play_sound("error")
	pass

func on_move_finished(line_data : LineData, puzzle_position : Vector2, mouse_position : Vector3, world_position : Vector3) -> void:
	puzzlerenderer.set_puzzle_line(0, puzzle_line)
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
	pass

func on_waiting_to_confirm_changed(is_waiting : bool) -> void:
	if is_waiting_for_comfirm:
		puzzlerenderer.create_highlight_tween()
	else:
		puzzlerenderer.create_exit_highlight_tween()

func play_sound(stream_name : String = "") -> void:
	if stream_name.is_empty():
		audio.stop()
	else:
		audio.stream = AudioSoundEffects[stream_name]
		audio.play()
