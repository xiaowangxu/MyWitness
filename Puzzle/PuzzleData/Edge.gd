class_name Edge
extends PuzzleElement

var from : Vertice
var to : Vertice
var length : float
var normal : Vector2
var wrap : bool = false
var wrap_from : Vector2
var wrap_to : Vector2
var wrap_extend : float = 0.0

func _init(from : Vertice, to : Vertice, center : Vector2, decorator : Decorator = null) -> void:
	self.from = from
	self.to = to
	self.position = center
	self.decorator = decorator
	self.length = from.position.distance_to(to.position)
	self.normal = from.position.direction_to(to.position)

func calcu_wrap() -> void:
	if has_custom_data(&"wrap"):
		var wrap_from_arr : Array[float] = get_custom_data(&"wrap").from
		var wrap_to_arr : Array[float] = get_custom_data(&"wrap").to
		self.wrap_from = Vector2(wrap_from_arr[0], wrap_from_arr[1])
		self.wrap_to = Vector2(wrap_to_arr[0], wrap_to_arr[1])
		self.length = self.from.position.distance_to(self.wrap_from) + self.to.position.distance_to(self.wrap_to)
		self.normal = self.from.position.direction_to(self.wrap_from)
		self.wrap = true
		self.wrap_extend = get_custom_data(&"wrap").extend

func get_normal(from : Vertice) -> Vector2:
	return normal if self.from == from else -normal

func get_forward_vertice(from : Vertice) -> Vertice:
	return to if from == self.from else self.from

func _to_string() -> String:
	return "[Edge \n\tfrom:%s\n\tto:%s\n\tdecorator:%s\n]" % [from, to, decorator]
