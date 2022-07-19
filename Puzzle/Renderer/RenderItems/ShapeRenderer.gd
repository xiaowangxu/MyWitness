class_name ShapeRenderer
extends RenderItem

var shape : ShapeBaseResource :
	set(val):
		shape = val
		update()

func _init(shape : ShapeBaseResource) -> void:
	self.shape = shape
	pass

func _draw() -> void:
	if shape != null:
		shape.draw(_rid)
	pass
