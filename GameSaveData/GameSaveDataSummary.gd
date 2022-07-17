class_name GameSaveDataSummary
extends Resource

@export var info : Dictionary
@export var cover : Image
@export var key : String

func init(key : String, info : Dictionary, cover : Image) -> void:
	self.key = key
	self.info = info
	self.cover = cover
