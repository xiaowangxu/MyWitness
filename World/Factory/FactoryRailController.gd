extends InteractableLinker

var path_line_renderer : LineSegment = null
@onready var positions : PackedVector3Array = [
	$"../Factory/Position3D1".position, 
	$"../Factory/Position3D2".position, 
	$"../Factory/Position3D3".position, 
	$"../Factory/Position3D4".position, 
	$"../Factory/Position3D5".position, 
	$"../Factory/Position3D6".position, 
	$"../Factory/Position3D7".position, 
	$"../Factory/Position3D8".position, 
	$"../Factory/Position3D9".position,
]

func _ready() -> void:
	var panel : PuzzlePanel = interactable as PuzzlePanel
	var puzzle_data := panel.puzzle_data
	path_line_renderer = LineSegment.new(null, 9, 38, puzzle_data.base_size)
	path_line_renderer.self_modulate = Color(0.15, 0.15, 0.15)
	path_line_renderer.name = "path_render_item"
	panel.get_base_viewport_instance().puzzle_renderer.add_render_item(path_line_renderer)
#	panel.set_always_on(true)
	panel.puzzle_started.connect(on_puzzle_started)
	panel.puzzle_answered.connect(on_puzzle_answered)
	panel.puzzle_exited.connect(on_puzzle_exited)
	pass
	
func on_puzzle_started(line_data : LineData, puzzle_position : Vector2, mouse_position : Vector3, world_position : Vector3) -> void:
#	var panel : PuzzlePanel = interactable as PuzzlePanel
#	panel.get_base_viewport_instance().puzzle_renderer.move_render_item(path_line_renderer, 2)
	pass


func on_puzzle_answered(correct : bool, tag : int, errors : Array, puzzle_line : LineData) -> void:
	var ans_line = puzzle_line.duplicate()
	queue_path(ans_line)
	pass

var current_line : LineData = null
var current_length : float = 0.0
var speed : float = 0.5
var queued_line : LineData = null
var is_animating : bool = false
func queue_path(puzzle_line : LineData) -> void:
	queued_line = puzzle_line
	if not is_animating and queued_line != null:
		if current_line == null:
			create_forward_animation()
		else:
			create_backward_animation()

func create_forward_animation() -> void:
	if queued_line == null: return
	current_line = queued_line
	queued_line = null
	var panel : PuzzlePanel = interactable as PuzzlePanel
	var points : Array[Vector3] = current_line.to_vertices_ids().filter(func (i : int): return i >= 0 and i <= 8).map(func (i : int): return positions[i])
	var curve := Curve3D.new()
	curve.up_vector_enabled = false
	for point in points:
		curve.add_point(point)
	var length := curve.get_baked_length()
	current_length = length
	var duration := length / speed
	var start := current_line.duplicate()
	start.clamp_to_length(0.0)
	var tween = create_tween()
	is_animating = true
	tween.tween_callback(func ():
		path_line_renderer.line_data = start
		$"../Path3D".curve = curve
		$"../Path3D/PathFollow3D".progress_ratio = 0.0
		panel.get_base_viewport_instance().puzzle_renderer.move_render_item(path_line_renderer)
		panel.set_always_on(true)
		pass
	)
	tween.tween_property(path_line_renderer, "percentage", 1.0, 2.0).from(0.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_method(func (val : float):
		var line : LineData = current_line.duplicate()
		line.clamp_to_length(current_line.get_length() * val)
		path_line_renderer.line_data = line
		$"../Path3D/PathFollow3D".progress_ratio = val
		pass,
		0.0,
		1.0,
		duration
	).set_trans(Tween.TRANS_LINEAR)
	tween.tween_callback(func ():
		panel.set_always_on(false)
		is_animating = false
		on_forward_animation_finsihed()
	)
	pass

func on_forward_animation_finsihed() -> void:
	if queued_line != null:
		create_backward_animation()

func create_backward_animation() -> void:
	is_animating = true
	var panel : PuzzlePanel = interactable as PuzzlePanel
	var duration := current_length / speed / 2
	var tween = create_tween()
	tween.tween_callback(func ():
		panel.set_always_on(true)
		pass
	)
	tween.tween_method(func (val : float):
		var line : LineData = current_line.duplicate()
		line.clamp_to_length(line.get_length() * val)
		path_line_renderer.line_data = line
		$"../Path3D/PathFollow3D".progress_ratio = val
		pass,
		1.0,
		0.0,
		duration
	).set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(path_line_renderer, "percentage", 0.0, 1.0).from(1.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(func ():
		panel.set_always_on(false)
		current_length = 0.0
		current_line = null
		is_animating = false
		on_backward_animation_finsihed()
	)
	pass

func on_backward_animation_finsihed() -> void:
	if queued_line != null:
		create_forward_animation()

#func create_animation() -> void:
#	if tween != null or ans_line == null: return
#	var panel : PuzzlePanel = interactable as PuzzlePanel
#
#	tween = create_tween()
#	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
#	panel.set_always_on(true)
#
##	go back
#	if current_line != null:
#		var duration := current_length / speed / 2
#		var _current_line = current_line.duplicate()
#		tween.tween_method(func (val : float):
#			var line : LineData = _current_line.duplicate()
#			line.clamp_to_length(line.get_length() * val)
#			path_line_renderer.line_data = line
#			$"../Path3D/PathFollow3D".progress_ratio = val
#			pass,
#			1.0,
#			0.0,
#			duration
#		).set_trans(Tween.TRANS_LINEAR)
#		tween.tween_property(path_line_renderer, "percentage", 0.0, 1.0).from(1.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)		
#
#	if ans_line != null:
#		current_line = ans_line.duplicate()
#		ans_line = null
#		var points : Array[Vector3] = current_line.to_vertices_ids().filter(func (i : int): return i >= 0 and i <= 8).map(func (i : int): return positions[i])
#		var curve := Curve3D.new()
#		curve.up_vector_enabled = false
#		for point in points:
#			curve.add_point(point)
#		var length := curve.get_baked_length()
#		current_length = length
#		var duration := length / speed
#
#		var start := current_line.duplicate()
#		start.clamp_to_length(0.0)
#		tween.tween_callback(func ():
#			path_line_renderer.line_data = start
#			$"../Path3D".curve = curve
#			panel.get_base_viewport_instance().puzzle_renderer.move_render_item(path_line_renderer)
#			pass
#		)
#		tween.tween_property(path_line_renderer, "percentage", 1.0, 2.0).from(0.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
#		tween.tween_method(func (val : float):
#			var line : LineData = current_line.duplicate()
#			line.clamp_to_length(current_line.get_length() * val)
#			path_line_renderer.line_data = line
#			$"../Path3D/PathFollow3D".progress_ratio = val
#			pass,
#			0.0,
#			1.0,
#			duration
#		).set_trans(Tween.TRANS_LINEAR)
#		tween.tween_callback(func ():
#			tween = null
#			panel.set_always_on(false)
#			create_animation.call_deferred()
#		)
#

func on_puzzle_exited() -> void:
	queue_path(null)
	pass
