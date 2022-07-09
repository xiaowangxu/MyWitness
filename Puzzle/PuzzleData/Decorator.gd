class_name Decorator
extends RefCounted

var base : TextureShapeResource
var color : Color
var texture : Texture
var transform : Transform2D
var rules : Array[PuzzleRule] = []

func _init(base : TextureShapeResource, color : Color, texture : Texture, transform : Transform2D) -> void:
	self.base = base
	self.color = color
	self.texture = texture
	self.transform = transform

func _to_string() -> String:
	return "[Decorator base:%s color:%s texture:%s]" % [base, color, texture]

func add_rule(rule : PuzzleRule) -> void:
	rules.append(rule)
	pass
