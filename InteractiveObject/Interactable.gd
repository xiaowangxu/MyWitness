class_name Interactable
extends Node3D

signal interact_result_changed(toggle : bool, tag : int)

@export var next_interactables_node_path : Array[NodePath] = []

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

func get_preferred_transform(player_transform: Transform3D) -> Transform3D:
	return player_transform

func get_next_interactable(id : int = 0) -> Interactable:
	if id >= 0 and id < next_interactables_node_path.size():
		return get_node_or_null(next_interactables_node_path[id])
	return null
