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
	var segment := segments[-1]
	segment.set_percentage(segment.percentage + percentage)
	pass

func backward(percentage : float = 0.0) -> void:
	if segments.size() == 0: print_debug("not able to backward on zero length line data")
	var segment := segments[-1]
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

# TODO: Array[Vertice]
func to_vertices() -> Array:
	var ans : Array[Vertice] = []
	ans.append(start)
	for segment in segments:
		ans.append(segment.to)
	return ans

func get_points_with_interval(interval : float = 10.0) -> PackedVector2Array:
	var ans : PackedVector2Array = []
	return ans

func is_complete() -> bool:
	var size := segments.size()
	return size == 0 or is_equal_approx(segments[-1].percentage, 1.0) or is_zero_approx(segments[-1].percentage)

func is_empty() -> bool:
	return segments.size() == 0

func get_length(from : int = 0, to : int = segments.size()) -> float:
	var length := 0.0
	for i in range(from, to + 1):
		length += get_nth_segment(i).get_length()
	return length

func get_segments_count() -> int:
	return segments.size()+1

func get_nth_segment(idx : int = 0) -> LineDataSegment:
	if idx > segments.size(): return null
	if idx == 0: return LineDataSegment.new(start, start)
	return segments[idx - 1]

func get_nth_segment_duplicated(idx : int = 0) -> LineDataSegment:
	if idx > segments.size(): return null
	if idx == 0: return LineDataSegment.new(start, start)
	return segments[idx - 1].duplicate()

func get_current_segment() -> LineDataSegment:
	if segments.size() == 0: return LineDataSegment.new(start, start)
	return segments[-1].duplicate()

func get_current_vertice() -> Vertice:
	if segments.size() == 0: return start
	return segments[-1].to

func get_current_segment_length() -> float:
	if segments.size() == 0: return 0.0
	return segments[-1].length

func get_current_position() -> Vector2:
	if segments.size() == 0: return start.position
	return segments[-1].get_position()

func get_current_percentage() -> float:
	if segments.size() == 0: return -1.0
	return segments[-1].percentage

func get_from_vertice() -> Vertice:
	if segments.size() == 0: return null
	return segments[-1].from

func get_current_normal() -> Vector2:
	if segments.size() == 0: return Vector2.ZERO
	return segments[-1].normal

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
	var end_segment := segments[-1]
	var to_vertice := end_segment.to
	if pass_through(to_vertice):
		end_segment.percentage = clampf(end_segment.percentage, 0.0, 
			1.0-(line_radius + (line_radius if to_vertice != start else start_radius))/end_segment.length)
		if is_zero_approx(end_segment.percentage):
			segments.pop_back()
	pass

func clamp_to_segment(segment : LineDataSegment, forward : bool = true) -> void:
	if segment.from == segment.to:
		if segment.to == start:
			segments.clear()
			return
	for i in (range(segments.size()) if forward else range(segments.size() - 1, -1, -1)):
		var cnt_segment := segments[i]
		if cnt_segment.from == segment.from and cnt_segment.to == segment.to:
			cnt_segment.set_percentage(segment.percentage)
			segments.resize(i+1)
			return
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

func calcu_forward_or_backward_line(base_line : LineData) -> Dictionary:
	var vertices_base : Array[Vertice] = base_line.to_vertices()
	var vertices_line : Array[Vertice] = self.to_vertices()
	var vertices_base_size := vertices_base.size()
	var vertices_line_size := vertices_line.size()
	var start_idx : int = 0
	while true:
		if start_idx >= vertices_base_size or start_idx >= vertices_line_size: return {}
		if vertices_line[start_idx] != vertices_base[start_idx]:
			break
		elif start_idx >= vertices_base_size - 1 or start_idx >= vertices_line_size - 1:
			break
		else: start_idx += 1
#	print(">>> split : ", start_idx, " old: ", vertices_base_size-1, " new: ", vertices_line_size - 1)

	var has_forward  : bool = false 
	var has_backward : bool = false 
#	check if is forward
#	        | start_idx		      | start_idx
#	        |				      | |
#	o---a---b				o---a-b |
#	o---a---b---c			o---a---b
#
	if start_idx >= vertices_base_size - 1:
		if vertices_base_size == vertices_line_size:
#			may be in a same segment, so needs to compare their percentage
			var base_end_percentage := base_line.get_current_percentage()
			var line_end_percentage := self.get_current_percentage()
			if base_end_percentage < line_end_percentage:
				has_backward = false
				has_forward = true
			elif base_end_percentage == line_end_percentage:
				has_backward = false
				has_forward = false
			else:
				has_backward = true
				has_forward = false
		else:
			has_backward = false
			has_forward = true
#	
#	    | start_idx		    | start_idx
#	    |				    |
#	o---a---b			o---a---b
#	    |
#	    c---d			o---a
#
	else:
		has_backward = true
		if start_idx >= vertices_line_size - 1:
			has_forward = false
		else:
			has_forward = true
	
#	if has_backward and has_forward:
#		print("<-- backward --> forward")
#	elif has_backward:
#		print("<-- backward")
#	elif has_forward:
#		print("--> forward")
	
	var forward_segments  : Array[LineDataSegment] = []
	var backward_segments : Array[LineDataSegment] = []
	if has_forward:
#		if start_idx != 0:
		var last_segment := base_line.get_nth_segment_duplicated(start_idx)
		forward_segments.append(last_segment)
		for i in range(start_idx, vertices_line_size):
			var cnt_segment := self.get_nth_segment_duplicated(i)
			if last_segment.is_same_segment(cnt_segment) and i < vertices_line_size - 1: continue
			forward_segments.append(cnt_segment)
			last_segment = cnt_segment
	if has_backward:
		for i in range(vertices_base_size - 1, start_idx - 1, -1):
			if i == 0: continue
			backward_segments.append(base_line.get_nth_segment_duplicated(i))
		backward_segments.append(self.get_nth_segment_duplicated(start_idx))
	
	return {
		"forward" : forward_segments,
		"backward": backward_segments
	}
