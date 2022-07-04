class_name StartEndHintRing
extends RenderItem

const DelayDuration := 1.0
const Duration := 1.5
const EaseType := Tween.TRANS_QUINT

var ring_width : float = 2.0 :
	set(val):
		val = clampf(val, 1.0, INF)
		if val != ring_width:
			ring_width = val
			update()
var start_positions : PackedVector2Array = [] :
	set(val):
		start_positions = val
		update()
var end_positions : PackedVector2Array = [] :
	set(val):
		end_positions = val
		update()
var normal_radius : float = 25.0 :
	set(val):
		val = clampf(val, 0.0, INF)
		if val != normal_radius:
			normal_radius = val
			update()
var start_radius : float = 60.0 :
	set(val):
		val = clampf(val, 0.0, INF)
		if val != normal_radius:
			start_radius = val
			update()
var start_percentage : float = 0.0 :
	set(val):
		val = clampf(val, 0.0, 1.0)
		if val != start_percentage:
			start_percentage = val
			update()
var end_percentage : float = 0.0 :
	set(val):
		val = clampf(val, 0.0, 1.0)
		if val != end_percentage:
			end_percentage = val
			update()

func _init(puzzle_board : PuzzleData, viewport_size : Vector2i, ring_width : float = 1.5) -> void:
	var _scale := Vector2(viewport_size) / Vector2(puzzle_board.base_size)
	self.start_positions = puzzle_board.vertices_start.map(func (v : Vertice) -> Vector2: return v.position * _scale)
	self.end_positions = puzzle_board.vertices_end.map(func (v : Vertice) -> Vector2: return v.position * _scale)
	self.normal_radius = puzzle_board.normal_radius * 1.2
	self.start_radius = puzzle_board.start_radius * 1.2
	self.ring_width = ring_width

func _draw() -> void:
	if not is_zero_approx(start_percentage):
		for center in start_positions:
			draw_ring(center, start_radius, ring_width, start_percentage)
	if not is_zero_approx(end_percentage):
		for center in end_positions:
			draw_ring(center, normal_radius, ring_width, end_percentage)
	pass

func draw_ring(center : Vector2, max_radius : float = 50.0, max_width : float = 3.0, percentage : float = 0.0)-> void:
	var width := max_width * (1 - percentage)
	draw_arc(center, max_radius * percentage, 0, TAU, 24, Color(1.0,1.0,1.0, minf(1.0, width) ), width, true)
	pass

var start_hint_tween : Tween
func set_start_hint_enabled(enabled : bool = false) -> void:
	if start_hint_tween != null:
		if not enabled:
			start_hint_tween.kill()
			start_hint_tween = null
			start_percentage = 0.0
	else:
		if enabled:
			start_hint_tween = create_tween().set_loops()
			start_hint_tween.tween_property(self, "start_percentage", 1.0, Duration).from(0.0).set_delay(DelayDuration).set_ease(Tween.EASE_OUT).set_trans(EaseType)
	pass

var end_hint_tween : Tween
func set_end_hint_enabled(enabled : bool = false) -> void:
	if end_hint_tween != null:
		if not enabled:
			end_hint_tween.kill()
			end_hint_tween = null
			end_percentage = 0.0
	else:
		if enabled:
			end_hint_tween = create_tween().set_loops()
			end_hint_tween.tween_property(self, "end_percentage", 1.0, Duration).from(0.0).set_delay(DelayDuration).set_ease(Tween.EASE_OUT).set_trans(EaseType)
	pass
