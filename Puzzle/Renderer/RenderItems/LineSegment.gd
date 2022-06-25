class_name LineSegment
extends RenderItem

var total_length : float = 0.0
var segments_length : PackedFloat32Array = []
var points : PackedVector2Array :
	set(val):
		points = val
		if points.size() > 1:
			total_length = 0.0
			segments_length.resize(0)
			for i in range(1, points.size()):
				var length := points[i-1].distance_to(points[i])
				segments_length.append(length)
				total_length += length
		update()
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
var length_percentage : float = 1.0 :
	set(val):
		val = clampf(val, 0.0, 1.0)
		if val != length_percentage:
			length_percentage = val
			update()

var last_point : Vector2 = Vector2.ZERO

func _init(points : PackedVector2Array, normal_radius : float = 10.0, start_radius : float = 20.0) -> void:
	self.points = points
	self.start_radius = start_radius
	self.normal_radius = normal_radius

func _draw() -> void:
	if percentage == 0.0:
		return
	match points.size():
		0:
			pass
		1:
			RenderingServer.canvas_item_add_circle(_rid, points[0], start_radius * percentage, WHITE)
		var size:
			var remain_length := total_length * length_percentage
			var circle_radius := normal_radius * percentage
			var line_width := circle_radius * 2.0
			RenderingServer.canvas_item_add_circle(_rid, points[0], start_radius * percentage, WHITE)
			for i in range(1, size):
				var start := points[i - 1]
				var end := points[i]
				var length := segments_length[i-1]
				if remain_length < length:
					var weight := remain_length/length
					end = start.lerp(end, weight)
					RenderingServer.canvas_item_add_circle(_rid, end, circle_radius, WHITE)
					RenderingServer.canvas_item_add_line(_rid, start, end, WHITE, line_width)
					last_point = end
					break
				else:
					remain_length -= length
					RenderingServer.canvas_item_add_circle(_rid, end, circle_radius, WHITE)
					RenderingServer.canvas_item_add_line(_rid, start, end, WHITE, line_width)
	pass
