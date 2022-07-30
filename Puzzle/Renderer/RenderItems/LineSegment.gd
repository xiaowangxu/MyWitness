class_name LineSegment
extends RenderItem

var line_data : LineData = null :
	get: return _line_data
	set(val):
		_line_data = val
		update()
var _line_data : LineData = null
var start_radius : float = 20.0:
	set(val):
		val = clampf(val, 0.0, INF)
		if val != start_radius:
			start_radius = val
			update()
var normal_radius : float = 10.0 :
	set(val):
		val = clampf(val, 0.0, INF)
		if val != normal_radius:
			normal_radius = val
			update()
var percentage : float = 1.0 :
	set(val):
		val = clampf(val, 0.0, 1.0)
		if val != percentage:
			percentage = val
			update()
var wrap_rect : Vector2 = Vector2.ZERO :
	set(val):
		if val != wrap_rect:
			wrap_rect = val
			update()

func _init(line_data : LineData, normal_radius : float = 10.0, start_radius : float = 20.0, wrap_rect : Vector2 = Vector2.ZERO) -> void:
	self.line_data = line_data
	self.start_radius = start_radius
	self.normal_radius = normal_radius
	self.wrap_rect = wrap_rect

func clear_line_data() -> void:
	_line_data = null

func _draw() -> void:
	if percentage == 0.0 or _line_data == null:
		return
	var last_position : Vector2 = _line_data.start.position
	RenderingServer.canvas_item_add_circle(_rid, last_position, start_radius * percentage, WHITE)
#	RenderingServer.canvas_item_add_line(_rid, start, end, WHITE, line_width)
	var _normal_radius := normal_radius * percentage
	var _line_width := _normal_radius * 2.0
	for segment in _line_data.segments:
		if not segment.wrap:
			var positions : PackedVector2Array = segment.get_positions()
			RenderingServer.canvas_item_add_circle(_rid, positions[1], _normal_radius, WHITE)
			RenderingServer.canvas_item_add_line(_rid, last_position, positions[1], WHITE, _line_width)
			last_position = positions[1]
		else:
			var positions : PackedVector2Array = segment.get_positions()
			if positions.size() == 2:
				RenderingServer.canvas_item_add_circle(_rid, positions[1], _normal_radius, WHITE)
				RenderingServer.canvas_item_add_line(_rid, last_position, positions[1], WHITE, _line_width)
				last_position = positions[1]
				if last_position.distance_to(segment.wrap_from) < _normal_radius:
					var offset := last_position - segment.wrap_from
					var offset_position := segment.wrap_to + offset
					var wrap_extend_length := segment.normal * (segment.wrap_extend) # - offset.length()
					RenderingServer.canvas_item_add_circle(_rid, offset_position, _normal_radius, WHITE)
					RenderingServer.canvas_item_add_line(_rid, offset_position - wrap_extend_length, offset_position, WHITE, _line_width)
#				if last_position.x + _normal_radius > wrap_rect.x:
#					var wrap_position : Vector2
#					var wrap_x := - wrap_rect.x + last_position.x
#					if last_position.y + _normal_radius > wrap_rect.y:
#						wrap_position = Vector2(wrap_x, - wrap_rect.y + last_position.y)
#					elif last_position.y - _normal_radius < 0:
#						wrap_position = Vector2(wrap_x, wrap_rect.y + last_position.y)
#					else:
#						wrap_position = Vector2(wrap_x, last_position.y)
#					RenderingServer.canvas_item_add_circle(_rid, wrap_position, _normal_radius, WHITE)
#					RenderingServer.canvas_item_add_line(_rid, wrap_position - wrap_extend_length, wrap_position, WHITE, _line_width)
#				elif last_position.x - _normal_radius < 0:
#					var wrap_position : Vector2
#					var wrap_x := wrap_rect.x + last_position.x
#					if last_position.y + _normal_radius > wrap_rect.y:
#						wrap_position = Vector2(wrap_x, - wrap_rect.y + last_position.y)
#					elif last_position.y - _normal_radius < 0:
#						wrap_position = Vector2(wrap_x, wrap_rect.y + last_position.y)
#					else:
#						wrap_position = Vector2(wrap_x, last_position.y)
#					RenderingServer.canvas_item_add_circle(_rid, wrap_position, _normal_radius, WHITE)
#					RenderingServer.canvas_item_add_line(_rid, wrap_position - wrap_extend_length, wrap_position, WHITE, _line_width)
#				else:
#					var wrap_position : Vector2
#					var wrap_x := last_position.x
#					if last_position.y + _normal_radius > wrap_rect.y:
#						wrap_position = Vector2(wrap_x, - wrap_rect.y + last_position.y)
#						RenderingServer.canvas_item_add_circle(_rid, wrap_position, _normal_radius, WHITE)
#						RenderingServer.canvas_item_add_line(_rid, wrap_position - wrap_extend_length, wrap_position, WHITE, _line_width)
#					elif last_position.y - _normal_radius < 0:
#						wrap_position = Vector2(wrap_x, wrap_rect.y + last_position.y)
#						RenderingServer.canvas_item_add_circle(_rid, wrap_position, _normal_radius, WHITE)
#						RenderingServer.canvas_item_add_line(_rid, wrap_position - wrap_extend_length, wrap_position, WHITE, _line_width)
			else:
#				RenderingServer.canvas_item_add_circle(_rid, positions[1], _normal_radius, WHITE)
				RenderingServer.canvas_item_add_line(_rid, last_position, positions[1], WHITE, _line_width)
#				RenderingServer.canvas_item_add_circle(_rid, positions[2], _normal_radius, WHITE)
				RenderingServer.canvas_item_add_line(_rid, positions[2], positions[3], WHITE, _line_width)
				RenderingServer.canvas_item_add_circle(_rid, positions[3], _normal_radius, WHITE)
				last_position = positions[3]
	pass
