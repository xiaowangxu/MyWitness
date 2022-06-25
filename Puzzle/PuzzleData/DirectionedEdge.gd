class_name DirectionedEdge
extends RefCounted

var edge : Edge
var inverted : bool = false

func _init(edge : Edge, inverted : bool = false) -> void:
	self.edge = edge
	self.inverted = inverted
