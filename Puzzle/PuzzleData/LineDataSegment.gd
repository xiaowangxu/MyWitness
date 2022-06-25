class_name LineDataSegment
extends RefCounted

var from : Vertice
var to : Vertice
var percentage : float = 0.0
var length : float = 0.0
var normal : Vector2 = Vector2.ZERO
	
func _init(from : Vertice, to : Vertice, percentage : float = 1.0) -> void:
	self.from = from
	self.to = to
	self.length = from.position.distance_to(to.position)
	self.normal = from.position.direction_to(to.position)
	set_percentage(percentage)
	
func set_percentage(percentage : float) -> void:
	self.percentage = clampf(percentage, 0.0, 1.0)
	
func get_position() -> Vector2:
	return from.position.lerp(to.position, percentage)
	
func duplicate() -> LineDataSegment:
	return LineDataSegment.new(self.from, self.to, self.percentage)

func _to_string() -> String:
	return "(%s) - %.4f -> (%s)" % [from.position, percentage, to.position]

func is_equal_approx(b : LineDataSegment) -> bool:
	if self.from == b.from and self.to == b.to:
		return is_equal_approx(self.percentage, b.percentage)
	else:
		return false
