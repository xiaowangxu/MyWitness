class_name PuzzleElement
extends RefCounted

var decorator : Decorator
var position : Vector2
var tag : int = 0
var id : int = -1
var custom_data : Dictionary = {}

func has_custom_data(key : StringName) -> bool:
	return custom_data.has(key)

func get_custom_data(key : StringName) -> bool:
	return custom_data.get(key)

func set_custom_data(data : Dictionary) -> void:
	for key in data:
		if data[key] == null: continue
		custom_data[StringName(key)] = data[key]
	pass

func add_custom_data(key : StringName, val) -> void:
	if val == null and has_custom_data(key):
		custom_data.erase(key)
	else:
		custom_data[key] = val
	pass

func remove_custom_data(key : StringName) -> void:
	if has_custom_data(key):
		custom_data.erase(key)
	pass
