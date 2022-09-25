class_name Area
extends PuzzleElement

var srounds : Array[Edge] = []
var edge_types : PackedInt32Array = []
var edge_sub_types : PackedInt32Array = []

func _init(srounds : Array[Edge], edge_types : PackedInt32Array, edge_sub_types : PackedInt32Array, center : Vector2, decorator : Decorator = null) -> void:
	self.tag = 1
	self.srounds = srounds
	self.position = center
	self.decorator = decorator
	self.edge_types = edge_types
	self.edge_sub_types = edge_sub_types

func get_sround_edge_by_type_and_subtype(type : int, subtype : int = -1) -> Edge:
	for i in range(edge_types.size()):
		if edge_types[i] == type and (subtype < 0 or edge_sub_types[i] == subtype):
			return srounds[i]
	return null

func _to_string() -> String:
		return "[Area id: %d]" % [id]
