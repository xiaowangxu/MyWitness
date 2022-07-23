class_name DirectionedEdge
extends RefCounted

var edge : Edge
var inverted : bool = false
var from : Vertice :
	get:
		return self.edge.to if self.inverted else self.edge.from
var to : Vertice :
	get:
		return self.edge.from if self.inverted else self.edge.to
var normal : Vector2 :
	get:
		return self.edge.normal * (-1.0 if self.inverted else 1.0)
var length : float :
	get:
		return self.edge.length

func _init(edge : Edge, inverted : bool = false) -> void:
	self.edge = edge
	self.inverted = inverted
