class_name Decorator
extends RefCounted

var base : ShapeBaseResource
var color : Color
var transform : Transform2D
var rules : Array[PuzzleRule] = []

func _init(base : ShapeBaseResource, color : Color, transform : Transform2D) -> void:
	self.base = base
	self.color = color
	self.transform = transform

func _to_string() -> String:
	return "[Decorator base:%s color:%s]" % [base, color]

func add_rule(rule : PuzzleRule) -> void:
	rules.append(rule)
	pass
