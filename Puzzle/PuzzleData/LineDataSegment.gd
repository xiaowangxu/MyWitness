class_name LineDataSegment
extends RefCounted

var from : Vertice
var to : Vertice
var from_percentage : float = 0.0
var percentage : float = 0.0
var length : float = 0.0
var normal : Vector2 = Vector2.ZERO
var wrap : bool = false
var wrap_from : Vector2
var wrap_from_length : float
var wrap_to : Vector2
var wrap_extend : float = 0.0
var edge_id : int = -1

func _init(from : Vertice, to : Vertice, percentage : float = 1.0, from_percentage : float = 0.0, wrap : bool = false, wrap_from : Vector2 = Vector2.ZERO, wrap_to : Vector2 = Vector2.ZERO, wrap_extend : float = 0.0, edge_id : int = -1) -> void:
	self.from = from
	self.to = to
	self.wrap = wrap
	self.edge_id = edge_id
	if self.wrap:
		self.wrap_from = wrap_from
		self.wrap_to = wrap_to
		self.wrap_from_length = from.position.distance_to(self.wrap_from)
		self.length = self.wrap_from_length + to.position.distance_to(self.wrap_to)
		self.normal = from.position.direction_to(self.wrap_from)
		self.wrap_extend = wrap_extend
	else:
		self.length = from.position.distance_to(to.position)
		self.normal = from.position.direction_to(to.position)
	set_from_percentage(from_percentage)
	set_percentage(percentage)
	
func set_percentage(percentage : float) -> void:
	self.percentage = clampf(percentage, 0.0, 1.0)

func set_from_percentage(percentage : float) -> void:
	self.from_percentage = clampf(percentage, 0.0, self.percentage)

func get_position() -> Vector2:
	if not wrap:
		return from.position.lerp(to.position, percentage)
	else:
		var _length := length * percentage
		if _length <= wrap_from_length:
			return from.position.lerp(wrap_from, _length / wrap_from_length)
		else:
			return wrap_to.lerp(to.position, (_length - wrap_from_length) / (length - wrap_from_length))

func get_from_position() -> Vector2:
	if not wrap:
		return from.position.lerp(to.position, from_percentage)
	else:
		var _length := length * from_percentage
		if _length <= wrap_from_length:
			return from.position.lerp(wrap_from, _length / wrap_from_length)
		else:
			return wrap_to.lerp(to.position, from_percentage - wrap_from_length / length)

func get_positions() -> PackedVector2Array:
	if not wrap:
		return PackedVector2Array([get_from_position(), get_position()])
	var from_part_percentage := wrap_from_length / length
	var from_part : int
	var to_part : int
	if from_percentage < from_part_percentage:
		from_part = 0
	else:
		from_part = 1
	if percentage < from_part_percentage:
		to_part = 0
	else:
		to_part = 1
	match [from_part, to_part]:
		[0,0], [1,1]: return PackedVector2Array([get_from_position(), get_position()])
		_:
			var wrap_extends_length := normal * wrap_extend
			return PackedVector2Array([get_from_position(), wrap_from + wrap_extends_length, wrap_to - wrap_extends_length, get_position()]) 

func get_length() -> float:
	return length * (percentage - from_percentage)

func duplicate() -> LineDataSegment:
	return LineDataSegment.new(self.from, self.to, self.percentage, self.from_percentage, self.wrap, self.wrap_from, self.wrap_to, self.wrap_extend, self.edge_id)

func _to_string() -> String:
	return "{%s}-(%.4f <=> %.4f)-{%s}" % [from.id, from_percentage, percentage, to.id]

func is_same_segment(b : LineDataSegment) -> bool:
	return self.from == b.from and self.to == b.to and self.wrap == b.wrap

func is_segment_equal_approx(b : LineDataSegment) -> bool:
	if self.from == b.from and self.to == b.to and self.wrap == b.wrap:
		return is_equal_approx(self.percentage, b.percentage) and is_equal_approx(self.from_percentage, b.from_percentage)
	else:
		return false

func is_edge(edge : Edge) -> bool:
	return (self.from == edge.from and self.to == edge.to) or (self.from == edge.to and self.to == edge.from) and (self.wrap == edge.wrap)

func get_percentage(position : Vector2) -> float:
	var sub_length := (position - from.position).length()
	return sub_length / length

func is_complete() -> bool:
	return is_zero_approx(from_percentage) and is_equal_approx(percentage, 1.0)
