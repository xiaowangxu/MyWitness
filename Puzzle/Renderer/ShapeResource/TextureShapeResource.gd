class_name TextureShapeResource
extends ShapeBaseResource

var shape : ShapeResource
var texture : Texture

func _init(shape : ShapeResource, texture : Texture) -> void:
	self.shape = shape
	self.texture = texture
	pass

func draw(rid : RID) -> void:
	if (not shape.uv.is_empty()) and texture != null:
		RenderingServer.canvas_item_add_polygon(
			rid,
			shape.points,
			PackedColorArray([Color.WHITE]),
			shape.uv,
			texture.get_rid()
		)
	else:
		RenderingServer.canvas_item_add_polygon(
			rid,
			shape.points,
			PackedColorArray([Color.WHITE])
		)
	pass
