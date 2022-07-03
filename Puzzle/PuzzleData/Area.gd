class_name Area
extends PuzzleElement

var srounds : PackedInt32Array = []
var neighbours : PackedInt32Array = []

func _init(srounds : PackedInt32Array, center : Vector2, decorator : Decorator = null) -> void:
	self.srounds = srounds
	self.position = center
	self.decorator = decorator

func add_neighbour(neighbour_id : int) -> void:
	if not neighbours.has(neighbour_id):
		neighbours.append(neighbour_id)

func _to_string() -> String:
		return "[Area \n\tsrounds:%s\n\tdecorator:%s\n]" % [srounds, decorator]
