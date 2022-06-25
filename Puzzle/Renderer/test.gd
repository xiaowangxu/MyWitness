extends Node2D

var texture : CompressedTexture2D = preload("res://icon.png")
var shape := TextureShape.new(PackedVector2Array([
	Vector2(-64, -48),
	Vector2(-48, -64),
	Vector2(0, -16),
	Vector2(48, -64),
	Vector2(64, -48),
	Vector2(16, 0),
	Vector2(64, 48),
	Vector2(48, 64),
	Vector2(0, 16),
	Vector2(-48, 64),
	Vector2(-64, 48),
	Vector2(-16, 0),
]))

func _ready() -> void:
	update()
	pass # Replace with function body.

func _draw() -> void:
	RenderingServer.canvas_item_add_polygon(get_canvas_item(), shape.points, PackedColorArray([Color.WHITE]), shape.uv, texture.get_rid())
