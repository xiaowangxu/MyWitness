class_name LineData
extends RefCounted

var start : Vertice

var segments : Array[LineDataSegment] = []

func _init(start : Vertice) -> void:
	self.start = start
	pass

func add_line_segemnt(to : Vertice, percentage : float = 1.0) -> LineData:
	if is_zero_approx(percentage): return self
	if segments.size() == 0:
		if start != to:
			segments.append(LineDataSegment.new(start, to, percentage))
	else:
		var last : LineDataSegment
		var size : int = segments.size() - 1
		for i in range(size + 1):
			if i < size:
				segments[i].set_percentage(1.0)
			else:
				last = segments[i]
		if last.to != to:
			last.set_percentage(1.0)
			segments.append(LineDataSegment.new(last.to, to, percentage))
		else:
			last.set_percentage(percentage)
	return self

func forward(percentage : float = 0.0) -> void:
	if segments.size() == 0: print_debug("not able to forward on zero length line data")
	var segment := segments[segments.size() - 1]
	segment.set_percentage(segment.percentage + percentage)
	pass

func backward(percentage : float = 0.0) -> void:
	if segments.size() == 0: print_debug("not able to backward on zero length line data")
	var segment := segments[segments.size() - 1]
	segment.set_percentage(segment.percentage - percentage)
	if is_zero_approx(segment.percentage):
		segments.pop_back()
	pass

func to_points() -> PackedVector2Array:
	var ans : PackedVector2Array = []
	ans.append(start.position)
	for segment in segments:
		var point := segment.get_position()
		ans.append(point)
	return ans

func get_points_with_interval(interval : float = 10.0) -> PackedVector2Array:
	var ans : PackedVector2Array = []
	return ans

func is_complete() -> bool:
	var size := segments.size()
	return size == 0 or is_equal_approx(segments[size - 1].percentage, 1.0) or is_zero_approx(segments[size - 1].percentage)

func is_empty() -> bool:
	return segments.size() == 0

func get_segments_count() -> int:
	return segments.size()+1

func get_nth_segment_duplicated(idx : int = 0) -> LineDataSegment:
	if idx > segments.size(): return null
	if idx == 0: return LineDataSegment.new(start, start)
	return segments[idx - 1].duplicate()

func get_current_segment() -> LineDataSegment:
	if segments.size() == 0: return LineDataSegment.new(start, start)
	return segments[segments.size() - 1].duplicate()

func get_current_vertice() -> Vertice:
	if segments.size() == 0: return start
	return segments[segments.size() - 1].to

func get_current_segment_length() -> float:
	if segments.size() == 0: return 0.0
	return segments[segments.size() - 1].length

func get_current_position() -> Vector2:
	if segments.size() == 0: return start.position
	return segments[segments.size() - 1].get_position()

func get_current_percentage() -> float:
	if segments.size() == 0: return -1.0
	return segments[segments.size() - 1].percentage

func get_from_vertice() -> Vertice:
	if segments.size() == 0: return null
	return segments[segments.size() - 1].from

func get_current_normal() -> Vector2:
	if segments.size() == 0: return Vector2.ZERO
	return segments[segments.size() - 1].normal

func pass_through(vertice : Vertice, include_end : bool = false) -> bool:
	if start == vertice:
		if is_empty():
			if include_end: return true
			return false
		else: return true
	for i in range(segments.size() - (0 if include_end else 1)):
		if segments[i].to == vertice: return true
	return false

func clamp_line_end(line_radius : float, start_radius : float) -> void:
	if segments.size() == 0: return
	var end_segment := segments[segments.size() - 1]
	var to_vertice := end_segment.to
	if pass_through(to_vertice):
		end_segment.percentage = clampf(end_segment.percentage, 0.0, 
			1.0-(line_radius + (line_radius if to_vertice != start else start_radius))/end_segment.length)
		if is_zero_approx(end_segment.percentage):
			segments.pop_back()
	pass

func duplicate() -> LineData:
	var line : LineData = LineData.new(self.start)
	for segment in self.segments:
		line.segments.append(segment.duplicate())
	return line

func _to_string() -> String:
	var ans : String = "" if start == null else "(%.1f,%.1f)" % [start.position.x, start.position.y]
	for i in segments:
		var segment := i
		ans += ' -> (%.1f,%.1f,%.2f)' % [segment.to.position.x, segment.to.position.y, segment.percentage]
	return ans

func difference(old_line : LineData) -> Dictionary:
	print("======== diffing ==========================================================")
	var diff : LineData = LineData.new(null)
	var a_line := self
	var b_line := old_line
	var a_count := a_line.get_segments_count()
	var b_count := b_line.get_segments_count()
	if a_count < b_count:
		var tmp := a_count
		a_count = b_count
		b_count = tmp
		a_line = old_line
		b_line = self
	
	var same_end := b_count
	
	for i in range(b_count):
		var a_segment := a_line.get_nth_segment_duplicated(i)
		var b_segment := b_line.get_nth_segment_duplicated(i)
		printt(a_segment, ",", b_segment)
		if a_segment.is_equal_approx(b_segment):
			continue
		else:
			same_end = i
			break
		pass
	
	print(same_end, " ", b_count)
	if same_end == b_count:
		diff.segments.append(b_line.get_nth_segment_duplicated(same_end - 1))
	
	for i in range(same_end, a_count):
		var a_segment := a_line.get_nth_segment_duplicated(i)
		diff.segments.append(a_segment)
	
	return {
		"forward": true,
		"difference": diff
	}
