class_name TextureShape
extends RenderItem

var shape : TextureShapeResource :
	set(val):
		shape = val
		update()
var texture : Texture = null :
	set(val):
		texture = val
		update()

func _init(shape : TextureShapeResource, texture : Texture = null) -> void:
	self.shape = shape
	self.texture = texture

func _draw() -> void:
	if (not shape.uv.is_empty()) and texture != null:
		RenderingServer.canvas_item_add_polygon(
			_rid,
			shape.points,
			PackedColorArray([Color.WHITE]),
			shape.uv,
			texture.get_rid()
		)
	else:
		RenderingServer.canvas_item_add_polygon(
			_rid,
			shape.points,
			PackedColorArray([Color.WHITE])
		)
	pass
