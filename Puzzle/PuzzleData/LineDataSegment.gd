class_name LineDataSegment
extends RefCounted

var from : Vertice
var to : Vertice
var from_percentage : float = 0.0
var percentage : float = 0.0
var length : float = 0.0
var normal : Vector2 = Vector2.ZERO
	
func _init(from : Vertice, to : Vertice, percentage : float = 1.0, from_percentage : float = 0.0) -> void:
	self.from = from
	self.to = to
	self.length = from.position.distance_to(to.position)
	self.normal = from.position.direction_to(to.position)
	set_from_percentage(from_percentage)
	set_percentage(percentage)
	
func set_percentage(percentage : float) -> void:
	self.percentage = clampf(percentage, 0.0, 1.0)

func set_from_percentage(percentage : float) -> void:
	self.from_percentage = clampf(percentage, 0.0, self.percentage)

func get_position() -> Vector2:
	return from.position.lerp(to.position, percentage)

func get_from_position() -> Vector2:
	return from.position.lerp(to.position, from_percentage)

func get_length() -> float:
	return length * (percentage - from_percentage)

func duplicate() -> LineDataSegment:
	return LineDataSegment.new(self.from, self.to, self.percentage, self.from_percentage)

func _to_string() -> String:
	return "{%s}-(%.4f <=> %.4f)-{%s}" % [from.id, from_percentage, percentage, to.id]

func is_same_segment(b : LineDataSegment) -> bool:
	return self.from == b.from and self.to == b.to

func is_equal_approx(b : LineDataSegment) -> bool:
	if self.from == b.from and self.to == b.to:
		return is_equal_approx(self.percentage, b.percentage) and is_equal_approx(self.from_percentage, b.from_percentage)
	else:
		return false

func is_edge(edge : Edge) -> bool:
	return (self.from == edge.from and self.to == edge.to) or (self.from == edge.to and self.to == edge.from)

func get_percentage(position : Vector2) -> float:
	var sub_length := (position - from.position).length()
	return sub_length / length
