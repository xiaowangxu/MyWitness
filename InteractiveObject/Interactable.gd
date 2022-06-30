class_name Interactable
extends Node3D

signal interact_result_changed(toggle : bool, tag : int)

func _init() -> void:
	add_to_group("GameSave")

func input_event(event : InputEvent, mouse_position : Vector3, world_position : Vector3) -> void:
	pass

func mouse_to_local(pos : Vector3) -> Vector3:
	return Vector3.ZERO

func mouse_to_global(pos : Vector3) -> Vector3:
	return Vector3.ZERO

func get_current_mouse_position() -> Vector3:
	return Vector3.ZERO

func get_current_world_position() -> Vector3:
	return Vector3.ZERO
