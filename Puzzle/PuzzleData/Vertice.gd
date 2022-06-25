class_name Vertice
extends PuzzleElement

enum VerticeType {
	START,
	END,
	STOP,
	NORMAL
}

var type : VerticeType = VerticeType.NORMAL
var neighbours : PackedInt32Array = []
	
func _init(position: Vector2, type : VerticeType, decorator : Decorator = null) -> void:
	self.position = position
	self.type = type
	self.decorator = decorator
	
func add_neighbour(neighbour_id : int) -> void:
	if not neighbours.has(neighbour_id):
		neighbours.append(neighbour_id)
	
func _to_string() -> String:
	return "[Vertice position:%s type:%d decorator:%s]" % [position, type, decorator]
