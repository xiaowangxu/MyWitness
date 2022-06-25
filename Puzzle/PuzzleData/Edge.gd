class_name Edge
extends PuzzleElement

var from : Vertice
var to : Vertice
var length : float
var normal : Vector2

func _init(from : Vertice, to : Vertice, center : Vector2, decorator : Decorator = null) -> void:
	self.from = from
	self.to = to
	self.position = center
	self.decorator = decorator
	self.length = from.position.distance_to(to.position)
	self.normal = from.position.direction_to(to.position)

func get_normal(from : Vertice) -> Vector2:
	return normal if self.from == from else -normal

func get_forward_vertice(from : Vertice) -> Vertice:
	return to if from == self.from else self.from

func _to_string() -> String:
	return "[Edge \n\tfrom:%s\n\tto:%s\n\tdecorator:%s\n]" % [from, to, decorator]
