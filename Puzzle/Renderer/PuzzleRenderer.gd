class_name PuzzleRenderer
extends ColorRect

var puzzle_data : PuzzleData = null
var background_line : PuzzleBoardLine
var line_renders : Array[LineSegment] = []
var decorator_renderitems_map : Dictionary = {}
var show_element : int = 0b1111
var override_size : Vector2i = Vector2i.ZERO

# children
var line_canvas_group : CanvasGroup = null

enum State { DRAWING, STOPPED}
signal state_changed(state : State)

func _init(puzzle_data : PuzzleData, viewport_size : Vector2i = Vector2i.ZERO, show_element : int = 0b1111) -> void:
	self.puzzle_data = puzzle_data
	self.show_element = show_element
	self.override_size = viewport_size
#func _ready() -> void:
	# scale
	var _viewport_size : Vector2
	if override_size == Vector2i.ZERO:
		_viewport_size = get_viewport_rect().size
	else:
		_viewport_size = override_size
	custom_minimum_size = puzzle_data.base_size
#	minimum_size = puzzle_data.base_size
	size = puzzle_data.base_size
	scale = _viewport_size / size
	
	if show_element & 0b1:
		self.color = puzzle_data.background_color
	else:
		self.color = Color.TRANSPARENT
	if show_element & 0b10:
		# background
		background_line = PuzzleBoardLine.new(puzzle_data)
		background_line.self_modulate = puzzle_data.background_line_color
		add_child(background_line)
	if show_element & 0b100:
		# decorators
		var elements : Array = []
		elements.append_array(puzzle_data.vertices)
		elements.append_array(puzzle_data.edges)
		elements.append_array(puzzle_data.areas)
		for elem in elements:
			if elem.decorator != null:
				var decorator_item : RenderItem = ShapeRenderer.new(elem.decorator.base)
				decorator_renderitems_map[elem.decorator] = decorator_item
				decorator_item.modulate = elem.decorator.color
				decorator_item.position = elem.position
				decorator_item.rotation = elem.decorator.transform.get_rotation()
				add_child(decorator_item)
	# line
	if show_element & 0b1000:
		line_canvas_group = CanvasGroup.new()
		line_canvas_group.z_index = 1
		for i in puzzle_data.lines_count:
			var line_render := LineSegment.new([], puzzle_data.normal_radius, puzzle_data.start_radius)
			line_renders.append(line_render)
			line_render.self_modulate = puzzle_data.lines_color[i * 4 + 3]
			line_canvas_group.add_child(line_render)
		add_child(line_canvas_group)
	pass

func puzzle_to_panel(pos : Vector2) -> Vector2:
	return pos * scale

func panel_to_puzzle(pos : Vector2) -> Vector2:
	return pos / scale

func set_puzzle_line(index : int, line : LineData) -> void:
	line_renders[index].points = line.to_points()

var tween_scheduled : Tween = null

func schedule_tween(tween : Tween = null) -> void:
	if tween_scheduled != null:
		tween_scheduled.kill()
	if tween != null:
		tween.finished.connect(func ():
#			print("tween end")
			tween_scheduled = null
			pass
		)
	tween_scheduled = tween

func create_start_tween() ->void:
	if not show_element & 0b1100: return
	var tween : Tween = create_tween()
	if show_element & 0b1000:
		line_canvas_group.self_modulate = Color.WHITE
		for i in range(line_renders.size()):
			var line_render := line_renders[i]
			line_render.self_modulate = puzzle_data.lines_color[i * 4]
	if show_element & 0b100:
		for decorator in decorator_renderitems_map:
			var decorator_item : RenderItem = decorator_renderitems_map[decorator]
			decorator_item.stop_scheduled_tween()
			decorator_item.modulate = decorator.color
	if show_element & 0b1000:
		tween.set_parallel(true)
		for line_render in line_renders:
			tween.tween_property(line_render, "percentage", 1.0, 0.2).from(0.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.set_parallel(false)
	state_changed.emit(State.DRAWING)
	schedule_tween(tween)
#	print(get_tree().get_processed_tweens())
	pass

func create_exit_tween() ->void:
	if not (show_element & 0b1000): return
	var tween : Tween = create_tween()
	tween.tween_property(line_canvas_group, "self_modulate", Color.TRANSPARENT, 1.0).from_current().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_interval(0.1)
	tween.tween_callback(func ():
		self.state_changed.emit(State.STOPPED)
		pass
	)
	schedule_tween(tween)
	pass

func create_error_tween(errors : Array) ->void:
	if show_element & 0b100:
		for decorator in errors:
			if decorator_renderitems_map.has(decorator):
				var decorator_item : RenderItem = decorator_renderitems_map[decorator]
				var decorator_tween : Tween = decorator_item.create_scheduled_tween().set_loops(4)
				decorator_tween.tween_property(decorator_item, "modulate", decorator.color, 0.75).from(Color.RED).set_trans(Tween.TRANS_LINEAR)
				decorator_tween.tween_property(decorator_item, "modulate", Color.RED, 0.0)
		pass
	if show_element & 0b1000:
		for i in range(line_renders.size()):
			var line_render := line_renders[i]
			line_render.self_modulate = puzzle_data.lines_color[i * 4 + 2]
		line_canvas_group.self_modulate = Color.WHITE
		var tween : Tween = create_tween()
		tween.tween_interval(1.0)
		tween.tween_property(line_canvas_group, "self_modulate", Color.TRANSPARENT, 4.0).from_current().set_trans(Tween.TRANS_LINEAR)
		tween.tween_interval(0.1)
		tween.tween_callback(func ():
			self.state_changed.emit(State.STOPPED)
			pass
		)
		schedule_tween(tween)
	pass

func create_correct_tween() ->void:
	if not (show_element & 0b1000): return
	var tween : Tween = create_tween()
	tween.set_parallel(true)
	for i in range(line_renders.size()):
		var line_render := line_renders[i]
		tween.tween_property(line_render, "self_modulate", puzzle_data.lines_color[i * 4 + 3], 0.15).from_current().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.set_parallel(false)
	tween.tween_interval(0.1)
	tween.tween_callback(func ():
		self.state_changed.emit(State.STOPPED)
		pass
	)
	schedule_tween(tween)
	pass

func _set_all_line_highlight_tween_step(val : float) -> void:
	for i in range(line_renders.size()):
		var line_render := line_renders[i]
		line_render.self_modulate = puzzle_data.lines_color[i * 4].lerp(puzzle_data.lines_color[i * 4 + 1], val)
	pass

func create_highlight_tween() ->void:
	if not (show_element & 0b1000): return
	for line_render in line_renders:
		line_render.percentage = 1.0
	var tween : Tween = create_tween().set_loops()
	tween.tween_method(_set_all_line_highlight_tween_step, 0.0, 1.0, 0.3).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CIRC)
	tween.tween_method(_set_all_line_highlight_tween_step, 1.0, 0.0, 0.3).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CIRC)
	schedule_tween(tween)
	pass

func create_exit_highlight_tween() ->void:
	if not (show_element & 0b1000): return
	if tween_scheduled != null:
		tween_scheduled.loop_finished.connect(func (idx : int):
			tween_scheduled.kill()
			pass
		)
	pass
