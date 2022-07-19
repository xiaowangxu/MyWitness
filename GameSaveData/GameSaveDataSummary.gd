class_name GameSaveDataSummary
extends Resource

@export var info : Dictionary
@export var cover : Image :
	set(val):
		cover = val
		cover_texture = ImageTexture.new()
		cover_texture.create_from_image(cover)
@export var key : String

var cover_texture : ImageTexture

func init(key : String, info : Dictionary, cover : Image) -> void:
	self.key = key
	self.info = info
	self.cover = cover
