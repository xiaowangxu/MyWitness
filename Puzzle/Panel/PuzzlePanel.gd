#@tool
class_name PuzzlePanel
extends Interactable

const AudioSoundEffects = {
#	"start": preload("res://SoundEffects/Puzzle/PuzzleStart.wav"),
	"start": preload("res://SoundEffects/Puzzle/PuzzleError.wav"),
	"error": preload("res://SoundEffects/Puzzle/PuzzleError2.wav"),
}
enum PuzzleInteractState {
	PREFERRED,
	PICKING,
	DRAWING,
	ANSWERED
}

signal move_finished(line_data : LineData, puzzle_position : Vector2, mouse_position : Vector3, world_position : Vector3)
signal puzzle_answered(correct : bool, tag : int)
signal puzzle_started(start_vertice : Vertice, puzzle_position : Vector2, mouse_position : Vector3, world_position : Vector3)
signal puzzle_exited()
signal puzzle_checked()
signal puzzle_interact_state_changed(state : PuzzleInteractState)

@export var puzzle_name : String = ""
@export var add_config : bool = false:
	set(val):
		add_config = false
		viewport_configs.append({
			"name": "base",
			"visual": 0b1111,
			"targets": PackedStringArray(["surface_material_override/0:albedo_texture", "surface_material_override/0:emission_texture"]),
			"transparent": false,
			"update": true
		})
@export var viewport_configs : Array[Dictionary] = [{
	"name": "base",
	"visual": 0b1111,
	"targets": PackedStringArray(["surface_material_override/0:albedo_texture", "surface_material_override/0:emission_texture"]),
	"transparent": false,
	"update": true
}]
@export var min_delta_length : float = 1.0
var puzzle_renderer_viewport_map : Dictionary = {}
var update_viewport_list : Array[SubViewport] = []

@onready var mesh : MeshInstance3D = $Mesh
@onready var area : CollisionObject3D = $Area
@onready var audio : AudioStreamPlayer = $Audio

var viewport_size : Vector2 = GlobalData.PuzzleViewportSizes.regular
var base_viewport : SubViewport = null
@onready var puzzle_data : PuzzleData = GlobalData.AllPuzzleData[puzzle_name]
var base_puzzle_renderer : PuzzleRenderer = null
var puzzle_line : LineData = null
var is_answered : bool = false

#var test_cursor := preload("res://Puzzle/TestCursor.tscn").instantiate()
@onready var test_info := preload("res://Puzzle/Panel/PuzzzlePanelInfo.tscn").instantiate()
func _ready() -> void:
	move_finished.connect(_on_move_finished)
	puzzle_answered.connect(on_puzzle_answered)
	puzzle_started.connect(on_puzzle_started)
	puzzle_exited.connect(on_puzzle_exited)
	puzzle_interact_state_changed.connect(on_puzzle_interact_state_changed)
	area.add_to_group(GlobalData.PuzzleGroupName)
	area.collision_layer |= GlobalData.PhysicsLayerInteractables | GlobalData.PhysicsLayerPuzzles
	audio.bus = GlobalData.PuzzleSoundEffectsBus
	
	for config in viewport_configs:
		set_viewports(config)
	
	base_viewport.add_child(test_info)
	base_puzzle_renderer.state_changed.connect(on_puzzle_render_state_changed)
	test_info.puzzle_name = puzzle_name
	
	load_save()
	pass

func set_viewports(config : Dictionary) -> void:
	var viewport : SubViewport = SubViewport.new()
	var puzzle_renderer : PuzzleRenderer = PuzzleRenderer.new(puzzle_data, viewport_size, config.visual)
	viewport.size = viewport_size
	viewport.transparent_bg = config.transparent
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(viewport)
	viewport.add_child(puzzle_renderer)
	puzzle_renderer_viewport_map[config.name] = {
		"puzzle_renderer": puzzle_renderer,
		"viewport": viewport
	}
	if config.update:
		update_viewport_list.append(viewport)
	if config.name == "base":
		base_viewport = viewport
		base_puzzle_renderer = puzzle_renderer
	if config.targets.size() != 0:
		var texture : ViewportTexture = viewport.get_texture()
		for target in config.targets:
			mesh.set_indexed(target, texture)
	pass

var current_position : Vector2 = Vector2.ZERO
func input_event(event : InputEvent, mouse_position : Vector3, world_position : Vector3) -> void:
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
		current_position = base_puzzle_renderer.panel_to_puzzle(Vector2(mouse_position.x, mouse_position.y))
#		can start ?
		var start_vertice : Vertice = PuzzleFunction.pick_start_vertice(puzzle_data, current_position)
		if start_vertice != null:
			var pos := start_vertice.position
			var _mouse_pos : Vector2 = base_puzzle_renderer.puzzle_to_panel(pos)
			var mouse_pos : Vector3 = Vector3(_mouse_pos.x, _mouse_pos.y, 0)
			var world_pos : Vector3 = mouse_to_global(Vector3(mouse_pos.x, mouse_pos.y, 0))
			if GlobalData.is_position_in_view(world_pos) and GlobalData.check_reachable(world_pos, area):
				is_answered = false
				puzzle_started.emit(start_vertice, pos, mouse_pos, world_pos)
				puzzle_interact_state_changed.emit(PuzzleInteractState.DRAWING)
	pass

func get_current_mouse_position() -> Vector3:
	var panel_position : Vector2 = base_puzzle_renderer.puzzle_to_panel(current_position)
	return Vector3(panel_position.x, panel_position.y, 0.0)

func get_current_world_position() -> Vector3:
	return mouse_to_global(get_current_mouse_position())

func get_preferred_transform(player_transform : Transform3D) -> Transform3D:
	var pos := global_transform.origin
	var quat := global_transform.basis.get_rotation_quaternion()
	pos -= Vector3.FORWARD.rotated(quat.get_axis().normalized(), quat.get_angle()) * 2
	pos.y = global_transform.origin.y - 4.0
	return Transform3D(Basis(Quaternion(Vector3(0,global_transform.basis.get_euler().y,0))), pos)

func on_mouse_moved(pos : Vector3) -> Vector3:
	if not GlobalData.check_reachable(get_current_world_position(), area):
		if puzzle_line.is_empty():
			on_confirm(true)
			return get_current_world_position()
		var back_line : LineData = LineData.new(puzzle_line.start)
		puzzle_line = clamp_puzzle_line(back_line, puzzle_line, true)
		if puzzle_line.is_empty():
			on_confirm(true)
			return get_current_world_position()
	var local = mouse_to_local(pos)
	var new_pos : Vector2 = base_puzzle_renderer.panel_to_puzzle(Vector2(local.x, local.y))
	var delta := new_pos - current_position
#	if is_zero_approx(delta.length_squared()): return get_current_world_position()
	test_info.puzzle_movement = delta
	current_position = new_pos
#	test_cursor.position = puzzlerenderer.puzzle_to_panel(current_position)
	
	var new_line : LineData = PuzzleFunction.move_line(puzzle_data, puzzle_line, delta)
	var ans_line : LineData = clamp_puzzle_line(new_line, puzzle_line)
	puzzle_line = ans_line 
	var end_position : Vector2 = puzzle_line.get_current_position()
	var mouse_pos : Vector2 = base_puzzle_renderer.puzzle_to_panel(end_position)
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

func clamp_puzzle_line(new_line : LineData, old_line : LineData, reachable_stop : bool = false) -> LineData:
	var diff : Dictionary = new_line.calcu_forward_or_backward_line(old_line)
	var forward : Array[LineDataSegment] = diff.forward
	var backward : Array[LineDataSegment] = diff.backward
	backward.reverse()
	if not backward.is_empty():
		for segment in backward:
			var start_pos : Vector2 = segment.get_position()
			var end_pos : Vector2 = segment.get_from_position()
			var length := (end_pos - start_pos).length()
			var count : int = ceil(length / min_delta_length)
			var last_pos := start_pos
			for i in range(count):
				var weight : float = float(i)/float(count - 1)
				var point := start_pos.lerp(end_pos, weight)
				var puzzle_position := base_puzzle_renderer.puzzle_to_panel(point)
				var world_position := mouse_to_global(Vector3(puzzle_position.x, puzzle_position.y, 0.0))
				var reachable := GlobalData.check_reachable(world_position, area)
				if (not reachable_stop and reachable) or (reachable_stop and not reachable):
					last_pos = point
					pass
				else:
					var percentage : float = segment.get_percentage(point if reachable_stop else last_pos)
					segment.percentage = percentage
					old_line.clamp_to_segment(segment)
					return old_line
	if not forward.is_empty():
		for segment in forward:
			var start_pos : Vector2 = segment.get_from_position()
			var end_pos : Vector2 = segment.get_position()
			var length := (end_pos - start_pos).length()
			var count : int = ceil(length / min_delta_length)
			var last_pos := start_pos
			for i in range(count):
				var weight : float = float(i)/float(count - 1)
				var point := start_pos.lerp(end_pos, weight)
				var puzzle_position := base_puzzle_renderer.puzzle_to_panel(point)
				var world_position := mouse_to_global(Vector3(puzzle_position.x, puzzle_position.y, 0.0))
				var reachable := GlobalData.check_reachable(world_position, area)
				if (not reachable_stop and reachable) or (reachable_stop and not reachable):
					last_pos = point
					pass
				else:
					var percentage : float = segment.get_percentage(point if reachable_stop else last_pos)
					segment.percentage = percentage
					new_line.clamp_to_segment(segment)
					return new_line
	return new_line

func on_preferred() -> void:
	_is_preferred = true
	puzzle_interact_state_changed.emit(PuzzleInteractState.PREFERRED)
	Debugger.print_tag(puzzle_name, "preferred", puzzle_data.background_color)
	pass

func on_unpreferred() -> void:
	_is_preferred = false
	Debugger.print_tag(puzzle_name, "unpreferred", puzzle_data.background_color)
	pass

func on_puzzle_interact_state_changed(state : PuzzleInteractState) -> void:
	Debugger.print_tag(puzzle_name + " interact state", str(state) + (" Answered" if is_answered else ""))

var _puzzle_state : int = PuzzleRenderer.State.STOPPED :
	set(val):
		_puzzle_state = val
		match _puzzle_state:
			PuzzleRenderer.State.DRAWING:
				request_viewport_mode(true)
			PuzzleRenderer.State.STOPPED:
				request_viewport_mode(false)
var _is_preferred : bool = false :
	set(val):
		_is_preferred = val
		request_viewport_mode(_is_preferred)
func request_viewport_mode(should_render : bool) -> void:
	if should_render:
		Debugger.print_tag(puzzle_name, "rendering", Color.GREEN)
		for viewport in update_viewport_list:
			viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	elif _puzzle_state == PuzzleRenderer.State.STOPPED and not _is_preferred:
		Debugger.print_tag(puzzle_name, "render disabled", Color.RED)
		for viewport in update_viewport_list:
			viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if should_render else SubViewport.UPDATE_DISABLED

func on_puzzle_render_state_changed(state : PuzzleRenderer.State) -> void:
	_puzzle_state = state
	pass

var is_waiting_for_comfirm : bool = false
func on_confirm(force_cancel : bool = false) -> void:
	if force_cancel or not is_waiting_for_comfirm:
		exit_puzzle()
	else:
		var correct_tag := check_puzzle_ans()
		is_answered = correct_tag >= 0
		puzzle_answered.emit(is_answered, correct_tag)
		puzzle_interact_state_changed.emit(PuzzleInteractState.ANSWERED)

# -1 is wrong >= 0 means different correct ans's tags
func check_puzzle_ans() -> int:
	var last_vertice := puzzle_line.get_current_vertice()
	return last_vertice.tag

func exit_puzzle() -> void:
	puzzle_line = null
	save()
	GlobalData.set_cursor_state(GlobalData.CursorState.PICKING)
	base_puzzle_renderer.create_exit_tween()
	puzzle_interact_state_changed.emit(PuzzleInteractState.PICKING)
	puzzle_exited.emit()
	interact_result_changed.emit(false, -1)
	pass

func on_puzzle_answered(correct : bool, tag : int) -> void:
	if not correct:
		play_sound("error")
		puzzle_line.forward(1.0)
		set_puzzle_line(puzzle_line)
		base_puzzle_renderer.create_error_tween()
		GlobalData.set_cursor_state(GlobalData.CursorState.PICKING)
	else:
		play_sound("start")
		puzzle_line.forward(1.0)
		set_puzzle_line(puzzle_line)
		base_puzzle_renderer.create_correct_tween()
		GlobalData.set_cursor_state(GlobalData.CursorState.PICKING)
	save()
	puzzle_line = null
	interact_result_changed.emit(correct, tag)
	pass

func on_puzzle_started(start_vertice : Vertice, puzzle_position : Vector2, mouse_position : Vector3, world_position : Vector3) -> void:
	is_waiting_for_comfirm = false
	current_position = puzzle_position
	puzzle_line = LineData.new(start_vertice)
#	puzzle_line.add_line_segemnt(puzzle_data.vertices[1])
#	puzzle_line.add_line_segemnt(puzzle_data.vertices[2])
#	puzzle_line.add_line_segemnt(puzzle_data.vertices[5])
#	puzzle_line.add_line_segemnt(puzzle_data.vertices[8])
#	puzzle_line.add_line_segemnt(puzzle_data.vertices[9])
	GlobalData.set_mouse_position_from_world(world_position)
	GlobalData.set_active_puzzle_panel(self)
	GlobalData.set_cursor_state(GlobalData.CursorState.DRAWING)
	set_puzzle_line(puzzle_line)
	base_puzzle_renderer.create_start_tween()
	play_sound("start")
	pass

func on_puzzle_exited() -> void:
	play_sound("error")
	pass

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

func _on_move_finished(line_data : LineData, puzzle_position : Vector2, mouse_position : Vector3, world_position : Vector3) -> void:
	update_confirm_state(line_data)
	on_move_finished(line_data, puzzle_position, mouse_position, world_position)
	pass

func on_move_finished(line_data : LineData, puzzle_position : Vector2, mouse_position : Vector3, world_position : Vector3) -> void:
	set_puzzle_line(line_data)
	pass

func on_waiting_to_confirm_changed(is_waiting : bool) -> void:
	if is_waiting_for_comfirm:
		base_puzzle_renderer.create_highlight_tween()
	else:
		base_puzzle_renderer.create_exit_highlight_tween()

func play_sound(stream_name : String = "") -> void:
	if stream_name.is_empty():
		audio.stop()
	else:
		audio.stream = AudioSoundEffects[stream_name]
		audio.play()

func set_puzzle_line(line_data : LineData, idx : int = 0) -> void:
	base_puzzle_renderer.set_puzzle_line(idx, line_data)

# save load
func save() -> void:
	if puzzle_line == null:
		GameSaver.clear_puzzle(puzzle_name)
	else:
		var line_vertice_id : Array = PackedInt32Array([puzzle_line.start.id])
		for i in puzzle_line.segments:
			line_vertice_id.append(i.to.id)
		var save_data : Dictionary = {
			"line": line_vertice_id
		}
		GameSaver.save_puzzle(puzzle_name, save_data)

func load_save() -> void:
	var data = GameSaver.get_puzzle(puzzle_name)
	if data == null: return
	is_answered = true
	var line : LineData = PuzzleFunction.generate_line_from_idxs(puzzle_data, data.line)
	set_puzzle_line(line)
