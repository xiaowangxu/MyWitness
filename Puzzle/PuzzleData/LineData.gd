class_name LineData
extends RefCounted

var line_id : int = 0
var start : Vertice

var segments : Array[LineDataSegment] = []

func _init(start : Vertice, line_id : int = 0) -> void:
	self.start = start
	self.line_id = line_id
	pass

# TODO : remove this
func add_vertice_segment(to : Vertice, percentage : float = 1.0) -> LineData:
	if is_zero_approx(percentage): return self
	if segments.size() == 0:
		if start != to:
			segments.append(LineDataSegment.new(start, to, percentage, 0.0))
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
			segments.append(LineDataSegment.new(last.to, to, percentage, 0.0))
		else:
			last.set_percentage(percentage)
	return self

func add_edge_segment(edge : Edge, percentage : float = 1.0) -> LineData:
	if is_zero_approx(percentage): return self
	if segments.size() == 0:
		var to := edge.get_forward_vertice(start)
		segments.append(LineDataSegment.new(start, to, percentage, 0.0, edge.wrap, edge.wrap_from, edge.wrap_to, edge.wrap_extend, edge.id))
	else:
		var last : LineDataSegment
		var size : int = segments.size() - 1
		for i in range(size + 1):
			if i < size:
				segments[i].set_percentage(1.0)
			else:
				last = segments[i]
		if last != null:
			last.set_percentage(1.0)
			var to := edge.get_forward_vertice(last.to)
			if not edge.wrap:
				segments.append(LineDataSegment.new(last.to, to, percentage, 0.0, edge.wrap, edge.wrap_from, edge.wrap_to, edge.wrap_extend, edge.id))
			else:
				if to == edge.to:
					segments.append(LineDataSegment.new(last.to, to, percentage, 0.0, edge.wrap, edge.wrap_from, edge.wrap_to, edge.wrap_extend, edge.id))
				else:
					segments.append(LineDataSegment.new(last.to, to, percentage, 0.0, edge.wrap, edge.wrap_to, edge.wrap_from, edge.wrap_extend, edge.id))
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

# TODO: Array[Vertice]
func to_vertices() -> Array:
	var ans : Array[Vertice] = []
	ans.append(start)
	for segment in segments:
		ans.append(segment.to)
	return ans

func to_line_elements() -> Array:
	var ans : Array = [start]
	ans.append_array(segments)
	return ans

func to_puzzle_element_ids(puzzle_data : PuzzleData) -> PackedInt32Array:
	var ans : PackedInt32Array = []
	for elem in to_puzzle_elements(puzzle_data):
		ans.append(elem.id)
	return ans

func to_puzzle_elements(puzzle_data : PuzzleData) -> Array:
	var ans : Array[PuzzleElement] = []
	for i in range(size()):
		ans.append(get_nth_puzzle_element(puzzle_data, i))
	return ans

# TODO: finish this
#func get_points_with_interval(interval : float = 10.0) -> PackedVector2Array:
#	var ans : PackedVector2Array = []
#	return ans

func is_complete() -> bool:
	var size := segments.size()
	return size == 0 or is_equal_approx(segments[-1].percentage, 1.0) or is_zero_approx(segments[-1].percentage)

func is_empty() -> bool:
	return segments.size() == 0

func size() -> int:
	return segments.size() + 1

func get_length(from : int = 0,  to : int = segments.size()) -> float:
	var length := 0.0
	for i in range(from, to + 1):
		length += get_nth_segment(i).get_length()
	return length

func get_edge_ids() -> PackedInt32Array:
	var ans : PackedInt32Array = []
	for segment in segments:
		ans.append(segment.edge_id)
	return ans

func validate() -> void:
	for i in range(segments.size()):
		var segment : LineDataSegment = segments[i]
		if not segment.from.neighbours.has(segment.edge_id):
			segments = segments.slice(0, i)
			return
		if i == 0:
			if segment.from.type != Vertice.VerticeType.START:
				segments = []
				return
		else:
			if segment.from.type != Vertice.VerticeType.NORMAL:
				segments = segments.slice(0, i)
				return
		if segment.to.type == Vertice.VerticeType.STOP or segment.to.type == Vertice.VerticeType.END:
			segments = segments.slice(0, i + 1)
			return

func normalize() -> void:
	for i in range(segments.size()):
		var segment : LineDataSegment = segments[i]
		if segment.is_empty():
			segments = segments.slice(0, i)
			return
	return

func get_nth_puzzle_element(puzzle_data : PuzzleData, idx : int = 0) -> PuzzleElement:
	if idx > segments.size(): return null
	if idx == 0: return start
	return puzzle_data.get_edge_by_id(segments[idx - 1].edge_id)

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
	return segments[-1]

func get_current_vertice() -> Vertice:
	if segments.size() == 0: return start
	return segments[-1].to

func get_current_edge_id() -> int:
	if segments.size() == 0: return -1
	return segments[-1].edge_id

func get_current_segment_length() -> float:
	if segments.size() == 0: return 0.0
	return segments[-1].get_length()

func get_current_position() -> Vector2:
	if segments.size() == 0: return start.position
	return segments[-1].get_position()

func get_current_percentage() -> float:
	if segments.size() == 0: return -1.0
	return segments[-1].percentage

func get_current_from_vertice() -> Vertice:
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
	var normal : Vector2 = end_segment.get_normal_start_with_vertice(to_vertice)
	if pass_through(to_vertice):
		var min_percentage = end_segment.percentage
		for segment in segments:
			if segment == end_segment: continue
			if segment.from == to_vertice or segment.to == to_vertice:
				var segment_normal : Vector2 = segment.get_normal_start_with_vertice(to_vertice)
				var angle : float = abs(normal.angle_to(segment_normal))
				if to_vertice == start and line_radius < start_radius:
					var percentage := 1.0 - (line_radius + start_radius) / end_segment.length
					min_percentage = minf(min_percentage, percentage)
				elif angle >= PI/2 or is_equal_approx(angle, PI/2):
					var percentage := 1.0-(line_radius + (line_radius if to_vertice != start else start_radius))/end_segment.length
					min_percentage = minf(min_percentage, percentage)
				elif is_zero_approx(angle):
					min_percentage = 0
					break
				else:
					var x : float = ((line_radius if to_vertice != start else start_radius) * 2) / sin(angle)
					var percentage : float = 1.0 - (x / end_segment.length)
					min_percentage = minf(min_percentage, percentage)
		end_segment.percentage = min_percentage
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
		if cnt_segment.is_same_segment(segment):
			cnt_segment.set_percentage(segment.percentage)
			segments.resize(i+1)
			break
	if is_zero_approx(get_current_percentage()):
		segments.pop_back()
	pass

func clamp_to_length(length : float = 0.0) -> void:
	if length <= 0.0: return
	var total_length := get_length()
	if total_length <= length: return
	total_length = length
	for i in range(segments.size()):
		var segment := segments[i]
		var segment_length := segment.get_length()
		if total_length - segment_length <= 0:
			segments = segments.slice(0, i + 1)
			var percentage : float = segment.get_length_percentage(total_length)
			segment.set_percentage(percentage)
			return
		total_length -= segment_length
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

func calcu_forward_or_backward_line(base_line : LineData) -> Dictionary:
	var a := self
	var b := base_line
	var a_size := a.size()
	var b_size := b.size()
	var start_idx : int = 0
	for i in range(mini(a_size, b_size)):
		var a_line_elem : LineDataSegment = a.get_nth_segment(i)
		var b_line_elem : LineDataSegment = b.get_nth_segment(i)
		if a_line_elem.is_same_segment(b_line_elem):
			start_idx = i
		else: break
	
#	var vertices_base : Array[Vertice] = base_line.to_vertices()
#	var vertices_line : Array[Vertice] = self.to_vertices()
#	var vertices_base_size := vertices_base.size()
#	var vertices_line_size := vertices_line.size()
#	var start_idx : int = -1
#	for i in range(mini(vertices_base_size, vertices_line_size)):
#		if vertices_base[i] == vertices_line[i]:
#			start_idx = i
#		else: break
#
#	if start_idx < 0: return {"forward": [], "backward": []}
	
#	print(">> split ", start_idx)
#	print(">>> split : ", start_idx, " old: ", vertices_base_size-1, " new: ", vertices_line_size - 1)
	
	var backward_segments : Array[LineDataSegment] = []
	var forward_segments : Array[LineDataSegment] = []

#	| start_idx
#	|
#	o---a---b
#	o---c---d---e
	if start_idx == 0:
		for segment in b.segments:
			backward_segments.append(segment.duplicate())
		for segment in a.segments:
			forward_segments.append(segment.duplicate())
	else:
#		      | start_idx
#		      | |
#		o---a-b |
#		o---a---b
		if start_idx >= b_size - 1 and a_size == b_size:
			var a_percentage := a.get_current_percentage()
			var b_percentage := b.get_current_percentage()
			if b_percentage < a_percentage:
#				forward
				var segment := a.get_current_segment().duplicate()
				segment.set_from_percentage(b_percentage)
				forward_segments.append(segment)
			elif b_percentage > a_percentage:
#				backward
				var segment := b.get_current_segment().duplicate()
				segment.set_from_percentage(a_percentage)
				backward_segments.append(segment)
		else:
#		      | start_idx		    | start_idx		    | start_idx
#		      | |					|				    |
#		o---a-b=b				o---a---b			o---a---b
#		o---a---b---c			    |				  | start_idx
#								    c---d			o-a=a
#			backward
			if start_idx >= a_size - 1 and not a.is_complete():
				var segment := a.get_current_segment().duplicate()
				segment.set_from_percentage(segment.percentage)
				segment.set_percentage(1.0)
				backward_segments.append(segment)
			for i in range(start_idx + 1, b_size):
				backward_segments.append(b.get_nth_segment_duplicated(i))
#			forward
			if start_idx >= b_size - 1 and not b.is_complete():
				var segment := b.get_current_segment().duplicate()
				segment.set_from_percentage(segment.percentage)
				segment.set_percentage(1.0)
				forward_segments.append(segment)
			for i in range(start_idx + 1, a_size):
				forward_segments.append(a.get_nth_segment_duplicated(i))
	
	return {
		"forward" : forward_segments,
		"backward": backward_segments
	}

func has_edge(edge : Edge) -> bool:
	for segment in segments:
		if segment.is_edge(edge): return true
	return false

func has_vertice(vertice : Vertice) -> bool:
	if start == vertice: return true
	for segment in segments:
		if segment.is_complete() and segment.to == vertice:
			return true
	return false

func find_first_collision_with_another_line(line : LineData) -> int:
	var size := mini(self.segments.size(), line.segments.size())
	for i in range(size):
		var a := self.segments[i]
		var b := line.segments[i]
		if a.edge_id == b.edge_id: return i + 1
		if a.to == b.to: return i + 1
	return -1

func find_first_collision_with_another_vertice(vertice : Vertice) -> int:
	if start == vertice: return 0
	for i in range(segments.size()):
		if segments[i].to == vertice: return i + 1
	return -1
