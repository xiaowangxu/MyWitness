class_name PuzzlePanel
extends Interactable

const AudioSoundEffects = {
	"answered": preload("res://SoundEffects/Puzzle/PuzzleStart.wav"),
	"start": preload("res://SoundEffects/Puzzle/PuzzleError.wav"),
	"error": preload("res://SoundEffects/Puzzle/PuzzleError2.wav"),
}
enum PuzzleInteractState {
	PREFERRED,
	PICKING,
	DRAWING,
	ANSWERED
}

signal puzzle_answered(correct : bool, tag : int, errors : Array[Decorator], puzzle_line : LineData)
signal puzzle_line_updated(puzzle_line : LineData)
signal puzzle_started(line_data : LineData, puzzle_position : Vector2, mouse_position : Vector3, world_position : Vector3)
signal puzzle_exited()
signal puzzle_checked()
signal puzzle_interact_state_changed(state : PuzzleInteractState)

@export var puzzle_name : String = ""
@export var save_name : String = ""
@onready var puzzle_save_name := save_name if save_name != "" else puzzle_name
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
	"idle": 1,
	"update": true
}]
@export var min_delta_length : float = 1.0
@export var puzzle_surface_material_id : int = 0
var viewport_instance_map : Dictionary = {}
var viewport_instance_list : Array[ViewportInstance] = []
var hint_ring_render_item : StartEndHintRing

@onready var mesh : MeshInstance3D = $Mesh
@onready var area : CollisionObject3D = $Area
@onready var audio : AudioStreamPlayer = $Audio
@onready var interactable_notifier : InteractableNotifier = get_node_or_null("InteractableNotifier")
@onready var material : Material = mesh.get_surface_override_material(puzzle_surface_material_id)

@onready var puzzle_data : PuzzleData = GlobalData.AllPuzzleData[puzzle_name]
var viewport_size : Vector2 = GlobalData.PuzzleViewportSizes.regular
@onready var puzzle_panel_scale : Vector2 = Vector2(viewport_size) / Vector2(puzzle_data.base_size)
var base_viewport_instance : ViewportInstance = null
var puzzle_line : LineData = null
@export var initial_active : bool = false
@onready var is_active : bool = initial_active
var is_answered : bool = false

@onready var test_info := preload("res://Puzzle/Panel/PuzzzlePanelInfo.tscn").instantiate()
func _ready() -> void:
	if interactable_notifier != null:
		interactable_notifier.reachable_change.connect(on_visible_changed)
		interactable_notifier.fade_step.connect(on_visible_percentage_changed)
	
	set_panel_active_percentage(1.0 if is_active else 0.0)
	self.add_to_group(GlobalData.PuzzleGroupName)
	puzzle_answered.connect(on_puzzle_answered)
	puzzle_started.connect(on_puzzle_started)
	puzzle_exited.connect(on_puzzle_exited)
	puzzle_interact_state_changed.connect(on_puzzle_interact_state_changed)
	area.collision_layer |= GlobalData.PhysicsLayerInteractables | GlobalData.PhysicsLayerPuzzles
	audio.bus = GlobalData.PuzzleSoundEffectsBus
	hint_ring_render_item = StartEndHintRing.new(puzzle_data, viewport_size)
	
	for config_idx in range(viewport_configs.size()):
		var viewport_instance := set_visual_instance(config_idx)
		if viewport_instance.config_name == "base":
			base_viewport_instance = viewport_instance
	
	viewport_configs.clear()
	
	if interactable_notifier != null:
		_set_material_fade_percentage_param(interactable_notifier.percentage)
		if interactable_notifier.is_reachable:
			set_viewports(true)
		else:
			free_viewports(true)
	else:
		set_viewports(true)
		_set_material_fade_percentage_param(1.0)
	mesh.set_instance_shader_parameter(&"default_color", puzzle_data.background_color)
	
#	test info
	get_base_viewport_instance().puzzle_renderer.state_changed.connect(on_puzzle_render_state_changed)
	test_info.puzzle_name = puzzle_name
	
	load_save()
	
	Debugger.print_tag("Puzzle Inited", "{0} as {1}".format([puzzle_name, puzzle_save_name]), Color.CRIMSON)
	
	pass

class ViewportInstance extends RefCounted:
	var config_name : String
	var config_idx : int
	var puzzle_renderer : PuzzleRenderer
	var viewport : SubViewport = SubViewport.new()
	var viewport_size : Vector2
	var viewport_transparent : bool = false
	var need_update : bool = false
	var targets : PackedStringArray
	
	func _init(config_idx : int, config : Dictionary, viewport_size : Vector2, puzzle_renderer : PuzzleRenderer, parent : PuzzlePanel) -> void:
		self.config_idx = config_idx
		self.puzzle_renderer = puzzle_renderer
		self.viewport_size = viewport_size
		self.viewport_transparent = config.transparent
		self.need_update = config.update
		self.targets = config.targets
		self.config_name = config.name
		self.viewport.transparent_bg = viewport_transparent
		self.viewport.size = Vector2i.ONE
		self.viewport.msaa_2d = Viewport.MSAA_4X
		parent.add_child(self.viewport)
		self.viewport.add_child(self.puzzle_renderer)
		if self.config_name == 'base':
			self.viewport.add_child(parent.hint_ring_render_item)
			self.viewport.add_child(parent.test_info)
		var texture : ViewportTexture = viewport.get_texture()
		set_texture(parent, texture)
		update_render()
		pass
	
	func set_texture(parent : PuzzlePanel, texture : Texture2D) -> void:
		if self.targets.size() != 0:
			for target in targets:
				parent.mesh.set_indexed(target, texture)
		pass
	
	func set_viewport(parent : Node) -> void:
		if viewport.size == Vector2i(viewport_size): return
		else:
			viewport.size = Vector2i(viewport_size)
			if viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED or viewport.render_target_update_mode == SubViewport.UPDATE_ONCE:
				update_render()
			var texture : ViewportTexture = viewport.get_texture()
			set_texture(parent, texture)
			return
#		if viewport != null: return
#		else:
#			viewport = SubViewport.new()
#			viewport.size = viewport_size
#			viewport.transparent_bg = viewport_transparent
#			viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
#			parent.add_child(viewport)
#			viewport.add_child(puzzle_renderer)
#			
	
	func set_rendering(render : bool) -> void:
		if viewport != null and need_update:
#			await RenderingServer.frame_post_draw
			viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if render else SubViewport.UPDATE_ONCE
	
	func update_render() -> void:
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	
	func free_viewport(parent : Node) -> void:
#		if viewport.size == Vector2i.ONE: return
		viewport.size = Vector2i.ONE
		set_texture(parent, null)
		return
#		if viewport != null:
#			for target in targets:
#				mesh.set_indexed(target, null)
#			viewport.remove_child(puzzle_renderer)
#			parent.remove_child(viewport)
#			viewport.queue_free()
#			viewport = null
	
	pass

func set_visual_instance(idx : int) -> ViewportInstance:
	var config : Dictionary = viewport_configs[idx]
	var puzzle_renderer : PuzzleRenderer = PuzzleRenderer.new(puzzle_data, viewport_size, config.visual)
	var viewport_instance : ViewportInstance = ViewportInstance.new(idx, config, viewport_size, puzzle_renderer, self)
	viewport_instance_map[config.name] = viewport_instance
	viewport_instance_list.append(viewport_instance)
	return viewport_instance

var _is_viewports_instanced : bool = false
func set_viewports(force : bool = false) -> void:
	if not force and _is_viewports_instanced: return
	for viewport_instance in viewport_instance_list:
		viewport_instance.set_viewport(self)
	_is_viewports_instanced = true
#	Debugger.print_tag("Viewport Inited", puzzle_name, Color.MEDIUM_SPRING_GREEN)
	pass

func free_viewports(force : bool = false) -> void:
	if not force and not _is_viewports_instanced: return
	for viewport_instance in viewport_instance_list:
		viewport_instance.free_viewport(self)
	_is_viewports_instanced = false
#	Debugger.print_tag("Viewport Freed", puzzle_name, Color.MEDIUM_SPRING_GREEN)
	pass

func set_panel_active_percentage(percentage : float) -> void:
	mesh.set_instance_shader_parameter(&"enable_percentage", percentage)
	pass

const ActiveDuration : float = 0.3
func set_active_with_tween(active : bool) -> void:
	if is_active != active:
		is_active = active
		save()
		var tween := create_tween()
		if is_active:
			for viewport_instance in viewport_instance_list:
				viewport_instance.puzzle_renderer.reset_render()
			for viewport in viewport_instance_list:
				viewport.update_render()
			tween.tween_method(set_panel_active_percentage, 0.0, 1.0, ActiveDuration).set_trans(Tween.TRANS_LINEAR)
		else:
			tween.tween_method(set_panel_active_percentage, 1.0, 0.0, ActiveDuration).set_trans(Tween.TRANS_LINEAR)

func on_visible_changed(on_screen : bool) -> void:
#	print(">>>>> ", puzzle_name, " ", on_screen)
	if on_screen:
		set_viewports()
	else:
		free_viewports()
	pass

func on_visible_percentage_changed(percentage : float) -> void:
	_set_material_fade_percentage_param(percentage)

func _set_material_fade_percentage_param(percentage : float) -> void:
	mesh.set_instance_shader_parameter(&"fade_percentage", percentage)
	pass

var current_position : Vector2 = Vector2.ZERO :
	set(val):
		current_position = val
		if (current_position.x < 0 or current_position.x > puzzle_data.base_size.x or current_position.y < 0 or current_position.y > puzzle_data.base_size.y):
			print(current_position)
			print_stack()
			current_position.x = clampf(current_position.x, 0.0, puzzle_data.base_size.x)
			current_position.y = clampf(current_position.y, 0.0, puzzle_data.base_size.y)
			assert(false, "Current Mouse Puzzle Position is out side of panel")

func input_event(event : InputEvent, mouse_position : Vector3, world_position : Vector3) -> void:
	if not is_active: return
	if event is InputPuzzleForceExitEvent:
		if puzzle_line != null:
			_on_confirm(true)
			return
	if event is InputEventMouseButton and event.is_pressed():
		if (event as InputEventMouseButton).button_index == MOUSE_BUTTON_RIGHT or (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			if puzzle_line != null:
				_on_confirm((event as InputEventMouseButton).button_index == MOUSE_BUTTON_RIGHT)
				return
	if event is InputEventMouseButton and event.is_pressed() and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		if puzzle_line != null: return
		current_position = panel_to_puzzle(Vector2(mouse_position.x, mouse_position.y))
#		can start ?
		var start_vertice : Vertice = PuzzleFunction.pick_start_vertice(puzzle_data, current_position)
		if start_vertice != null:
			var pos := start_vertice.position
			var _mouse_pos : Vector2 = puzzle_to_panel(pos)
			var mouse_pos : Vector3 = Vector3(_mouse_pos.x, _mouse_pos.y, 0)
			var world_pos : Vector3 = mouse_to_global(Vector3(mouse_pos.x, mouse_pos.y, 0))
			if GlobalData.is_position_in_view(world_pos) and GlobalData.check_reachable(world_pos, area):
				var new_line := LineData.new(start_vertice)
				start_puzzle(new_line, pos, mouse_pos, world_pos)
				GlobalData.set_mouse_position_from_world(world_pos)
				GlobalData.set_active_puzzle_panel(self)
				GlobalData.set_cursor_state(GlobalData.CursorState.DRAWING)
	pass

func get_current_mouse_position() -> Vector3:
	var panel_position : Vector2 = puzzle_to_panel(current_position)
	return Vector3(panel_position.x, panel_position.y, 0.0)

func get_current_world_position() -> Vector3:
	return mouse_to_global(get_current_mouse_position())

const PreferredDistance : float = 2.5
func get_preferred_transform(player_transform : Transform3D) -> Transform3D:
	var pos := area.global_transform.origin
	var quat := area.global_transform.basis.get_rotation_quaternion()
	if is_zero_approx(quat.get_axis().length_squared()):
		pos -= Vector3.FORWARD * PreferredDistance
	else:
		pos -= Vector3.FORWARD.rotated(quat.get_axis().normalized(), quat.get_angle()) * PreferredDistance
	pos.y = area.global_transform.origin.y - 4.0
	return Transform3D(Basis(Quaternion(Vector3(0,area.global_transform.basis.get_euler().y,0))), pos)

func get_base_viewport_instance() -> ViewportInstance:
	return base_viewport_instance

const ComputationTolerence : float = 0.5
func on_mouse_moved(pos : Vector3) -> Vector3:
	if not GlobalData.check_reachable(get_current_world_position(), area):
		if puzzle_line.is_empty():
			current_position = puzzle_line.get_current_position()
			_on_confirm(true)
			return get_current_world_position()
		var back_line : LineData = LineData.new(puzzle_line.start)
		puzzle_line = clamp_puzzle_line(back_line, puzzle_line, true)
		if puzzle_line.is_empty():
#			current_position = puzzle_line.get_current_position()
			_on_confirm(true)
			return get_current_world_position()
	var local = mouse_to_local(pos)
	var new_pos : Vector2 = panel_to_puzzle(Vector2(local.x, local.y))
	var delta := new_pos - current_position
	
	if delta.length_squared() < ComputationTolerence:
		delta = Vector2.ZERO
	
	test_info.puzzle_movement = delta
	current_position = new_pos

	var new_line : LineData = PuzzleFunction.move_line(puzzle_data, puzzle_line, delta, get_is_clamped(puzzle_line))
	var ans_line : LineData = clamp_puzzle_line(new_line, puzzle_line)
	var end_position : Vector2 = ans_line.get_current_position()
	var mouse_pos : Vector2 = puzzle_to_panel(end_position)
	var mouse_position : Vector3 = Vector3(mouse_pos.x, mouse_pos.y, 0)
	var world_position : Vector3 = mouse_to_global(mouse_position)
	current_position = commit_move_line(ans_line, end_position, mouse_position, world_position)
	var new_mouse_pos : Vector2 = puzzle_to_panel(current_position)
	var new_world_pos : Vector3 = mouse_to_global(Vector3(new_mouse_pos.x, new_mouse_pos.y, 0))
	
#	print(">>>>>> ", pos == new_world_pos, new_world_pos, pos)
	return new_world_pos

func mouse_to_local(pos : Vector3) -> Vector3:
	var trans := area.global_transform.affine_inverse()
	var ans := trans * pos
	ans.y *= -1
	var scaled := (ans + Vector3(0.5,0.5,0))
	scaled.x *= viewport_size.x
	scaled.y *= viewport_size.y
	return scaled

func mouse_to_global(pos : Vector3) -> Vector3:
	var trans := area.global_transform
	var scaled := pos
	scaled.x /= viewport_size.x
	scaled.y /= viewport_size.y
	scaled -= Vector3(0.5, 0.5, 0)
	scaled.y *= -1
	var ans := trans * scaled
	return ans

func puzzle_to_panel(pos : Vector2) -> Vector2:
	return pos * puzzle_panel_scale

func panel_to_puzzle(pos : Vector2) -> Vector2:
	return pos / puzzle_panel_scale

func clamp_puzzle_line(new_line : LineData, old_line : LineData, reachable_stop : bool = false) -> LineData:
	var diff : Dictionary = new_line.calcu_forward_or_backward_line(old_line)
	var forward : Array[LineDataSegment] = diff.forward
	var backward : Array[LineDataSegment] = diff.backward
#	print(forward)
#	print(backward)
	backward.reverse()
	if not backward.is_empty():
		for segment in backward:
			var segment_length : float = segment.get_length()
			var count : int = maxi(1, ceil(segment_length / min_delta_length))
			var last_percentage := segment.percentage
			for i in range(-1, count):
				var weight : float = float(i + 1)/float(count)
				var percentage := lerpf(segment.percentage, segment.from_percentage, weight)
				var point := segment.get_position(percentage)
				var puzzle_position := puzzle_to_panel(point)
				var world_position := mouse_to_global(Vector3(puzzle_position.x, puzzle_position.y, 0.0))
				var reachable := GlobalData.check_reachable(world_position, area)
				if (not reachable_stop and reachable) or (reachable_stop and not reachable):
					last_percentage = percentage
					pass
				else:
					segment.percentage = percentage if reachable_stop else last_percentage
#					print("clamp backward ", segment.percentage)
					old_line.clamp_to_segment(segment)
					return old_line
	if not forward.is_empty():
		for segment in forward:
			var segment_length : float = segment.get_length()
			var count : int = maxi(1, ceil(segment_length / min_delta_length))
			var last_percentage := segment.from_percentage
			for i in range(-1, count):
				var weight : float = float(i + 1)/float(count)
				var percentage := lerpf(segment.from_percentage, segment.percentage, weight)
				var point := segment.get_position(percentage)
				var puzzle_position := puzzle_to_panel(point)
				var world_position := mouse_to_global(Vector3(puzzle_position.x, puzzle_position.y, 0.0))
				var reachable := GlobalData.check_reachable(world_position, area)
				if (not reachable_stop and reachable) or (reachable_stop and not reachable):
					last_percentage = percentage
					pass
				else:
					segment.percentage = percentage if reachable_stop else last_percentage
#					print("clamp forward  ", segment.percentage)
					new_line.clamp_to_segment(segment)
					return new_line
				pass
	assert(!is_nan(new_line.get_current_percentage()))
	return new_line

func on_preferred() -> void:
	_is_preferred = true
	puzzle_interact_state_changed.emit(PuzzleInteractState.PREFERRED)
#	Debugger.print_tag(puzzle_name, "preferred", Color.CHARTREUSE)
	pass

func on_unpreferred() -> void:
	_is_preferred = false
#	Debugger.print_tag(puzzle_name, "unpreferred", Color.CHARTREUSE)
	pass

func on_puzzle_interact_state_changed(state : PuzzleInteractState) -> void:
#	Debugger.print_tag(puzzle_name + " interact state", str(state) + (" Answered" if is_answered else ""), Color.SEA_GREEN)
	if state == PuzzleInteractState.PREFERRED and not is_answered:
		hint_ring_render_item.set_start_hint_enabled(true)
	elif state == PuzzleInteractState.PICKING or state == PuzzleInteractState.ANSWERED:
		hint_ring_render_item.set_start_hint_enabled(false)
		hint_ring_render_item.set_end_hint_enabled(false)
	elif state == PuzzleInteractState.DRAWING:
		hint_ring_render_item.set_start_hint_enabled(false)
		hint_ring_render_item.set_end_hint_enabled(true)

func set_always_on(enabled : bool = false) -> void:
	_always_on = enabled
	pass

var _always_on : bool = false :
	set(val):
		var changed := _always_on != val
		_always_on = val
		if changed:
			request_viewport_mode(_always_on)
var _puzzle_state : int = PuzzleRenderer.State.STOPPED :
	set(val):
		var changed := _puzzle_state != val
		_puzzle_state = val
		if changed:
			match _puzzle_state:
				PuzzleRenderer.State.DRAWING:
					request_viewport_mode(true)
				PuzzleRenderer.State.STOPPED:
					request_viewport_mode(false)
var _is_preferred : bool = false :
	set(val):
		var changed := _is_preferred != val
		_is_preferred = val
		if changed:
			request_viewport_mode(_is_preferred)
func request_viewport_mode(should_render : bool) -> void:
	if should_render:
#		Debugger.print_tag(puzzle_name, "rendering", Color.DODGER_BLUE)
		for viewport in viewport_instance_list:
			viewport.set_rendering(true)
	elif _puzzle_state == PuzzleRenderer.State.STOPPED and not _is_preferred and not _always_on:
#		Debugger.print_tag(puzzle_name, "render disabled", Color.DODGER_BLUE)
		hint_ring_render_item.set_start_hint_enabled(false)
		hint_ring_render_item.set_end_hint_enabled(false)
		for viewport in viewport_instance_list:
			viewport.set_rendering(should_render)

func on_puzzle_render_state_changed(state : PuzzleRenderer.State) -> void:
	_puzzle_state = state
	pass

func start_puzzle(line_data : LineData, puzzle_pos : Vector2 = Vector2.ZERO, mouse_pos : Vector3 = Vector3.ZERO, world_pos : Vector3 = Vector3.ZERO) -> void:
	set_viewports()
	is_answered = false
	is_waiting_for_comfirm = false
	puzzle_line = line_data
	set_puzzle_line(puzzle_line)
	current_position = puzzle_pos
	puzzle_started.emit(puzzle_line, puzzle_pos, mouse_pos, world_pos)
	puzzle_interact_state_changed.emit(PuzzleInteractState.DRAWING)
	pass

func get_is_clamped(line_data : LineData) -> bool:
	return false

var is_waiting_for_comfirm : bool = false
func _on_confirm(force_cancel : bool = false) -> void:
	if force_cancel or not is_waiting_for_comfirm:
		_exit_puzzle()
	else:
		_check_puzzle()

func _exit_puzzle() -> void:
	exit_puzzle()
	GlobalData.set_cursor_state(GlobalData.CursorState.PICKING)
	pass

func exit_puzzle() -> void:
	puzzle_line = null
	save()
	get_base_viewport_instance().puzzle_renderer.create_exit_tween()
	puzzle_exited.emit()
	puzzle_interact_state_changed.emit(PuzzleInteractState.PICKING)
	interact_result_changed.emit(false, -1)
	pass

func _check_puzzle() -> void:
	check_puzzle()
	GlobalData.set_mouse_position_from_world(get_current_world_position())
	GlobalData.set_cursor_state(GlobalData.CursorState.PICKING)
	pass

func check_puzzle() -> void:
	puzzle_line.forward(1.0)
	set_puzzle_line(puzzle_line)
	current_position = puzzle_line.get_current_position()
	var correct_dict := check_puzzle_answer(puzzle_line)
	is_answered = correct_dict.tag >= 0
	save()
	puzzle_answered.emit(is_answered, correct_dict.tag, correct_dict.errors, puzzle_line)
	puzzle_line = null
	puzzle_interact_state_changed.emit(PuzzleInteractState.ANSWERED)
	interact_result_changed.emit(is_answered, correct_dict.tag)
	pass

# -1 is wrong >= 0 means different correct ans's tags
func check_puzzle_answer(line_data : LineData) -> Dictionary:
	var last_vertice := line_data.get_current_vertice()
	var errors : Array[Decorator] = PuzzleFunction.check_puzzle_answer(puzzle_data, get_check_lines(line_data))
	if errors.size() <= 0: return {"tag":last_vertice.tag, "errors": []}
	return {"tag":-1, "errors": errors}

# Array[LineData]
func get_check_lines(line_data : LineData) -> Array:
	var ans : Array[LineData] = [line_data]
	return ans

func on_puzzle_started(line_data : LineData, puzzle_position : Vector2, mouse_position : Vector3, world_position : Vector3) -> void:
	get_base_viewport_instance().puzzle_renderer.create_start_tween()
	play_sound("start")
	pass

func on_puzzle_answered(correct : bool, tag : int, errors : Array, line_data : LineData) -> void:
	if not correct:
		play_sound("error")
		for viewport_instance in viewport_instance_list:
			viewport_instance.puzzle_renderer.create_error_tween(errors)
		if not initial_active:
			set_active_with_tween(false)
#		get_base_viewport_instance().puzzle_renderer
	else:
		play_sound("answered")
		get_base_viewport_instance().puzzle_renderer.create_correct_tween()
	pass

func on_puzzle_exited() -> void:
	play_sound("error")
	pass

const ConfirmRemainLength : float = 10.0
func _update_confirm_state(line_data : LineData) -> void:
	var current_vertice : Vertice = line_data.get_current_vertice()
	var current_remain_length : float = line_data.get_current_segment().length - line_data.get_current_segment_length()
	if current_vertice.type == Vertice.VerticeType.END and current_remain_length <= ConfirmRemainLength:
		if not is_waiting_for_comfirm:
			is_waiting_for_comfirm = true
			on_waiting_to_confirm_changed(true)
	else:
		if is_waiting_for_comfirm:
			is_waiting_for_comfirm = false
			on_waiting_to_confirm_changed(false)
	hint_ring_render_item.set_end_hint_enabled(not is_waiting_for_comfirm)

func commit_move_line(line_data : LineData, puzzle_position : Vector2 = Vector2.ZERO, mouse_position : Vector3 = Vector3.ZERO, world_position : Vector3 = Vector3.ZERO) -> Vector2:
	puzzle_line = line_data 
	var new_puzzle_pos := on_move_finished(line_data, puzzle_position, mouse_position, world_position)
	set_puzzle_line(line_data)
	_update_confirm_state(line_data)
	puzzle_line_updated.emit(line_data)
	return new_puzzle_pos

func on_move_finished(line_data : LineData, puzzle_position : Vector2 = Vector2.ZERO, mouse_position : Vector3 = Vector3.ZERO, world_position : Vector3 = Vector3.ZERO) -> Vector2:
	return puzzle_position

func on_waiting_to_confirm_changed(is_waiting : bool) -> void:
	if is_waiting_for_comfirm:
		get_base_viewport_instance().puzzle_renderer.create_highlight_tween()
	else:
		get_base_viewport_instance().puzzle_renderer.create_exit_highlight_tween()

func play_sound(stream_name : String = "") -> void:
	if stream_name.is_empty():
		audio.stop()
	else:
		audio.stream = AudioSoundEffects[stream_name]
		audio.play()

func set_puzzle_line(line_data : LineData) -> void:
	get_base_viewport_instance().puzzle_renderer.set_puzzle_line(0, line_data)

# save load
func save() -> void:
	if not is_answered and (not initial_active and not is_active):
		GameSaver.clear_puzzle(puzzle_save_name)
	else:
		if is_answered and puzzle_line != null:
			var line_vertice_id : Array = PackedInt32Array([puzzle_line.start.id])
			for i in puzzle_line.segments:
				line_vertice_id.append(i.edge_id)
			var save_data : Dictionary = {
				"line": line_vertice_id,
				"active": is_active
			}
			GameSaver.save_puzzle(puzzle_save_name, save_data)
		else:
			var save_data : Dictionary = {
				"line": null,
				"active": is_active
			}
			GameSaver.save_puzzle(puzzle_save_name, save_data)

func load_save() -> void:
	var data = GameSaver.get_puzzle(puzzle_save_name)
	if data == null: return
	if data.line != null:
		is_answered = true
		var line : LineData = PuzzleFunction.generate_line_from_idxs(puzzle_data, data.line)
		set_puzzle_line(line)
	is_active = initial_active or data.active
	set_panel_active_percentage(1.0 if is_active else 0.0)
