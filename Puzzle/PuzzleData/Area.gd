class_name Area
extends PuzzleElement

var srounds : Array[Edge] = []

func _init(srounds : Array[Edge], center : Vector2, decorator : Decorator = null) -> void:
	self.srounds = srounds
	self.position = center
	self.decorator = decorator
