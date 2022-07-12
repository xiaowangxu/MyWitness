class_name InteractableNotifier
extends Node3D

signal state_change(reachable : bool)
signal exit()
signal enter()

@export var far : float = 150.0
@export var near : float = 130.0

@export var is_reachable : bool = false

func _ready() -> void:
	_update()

func _process(delta: float) -> void:
	_update()

func _update() -> void:
	var camera := get_viewport().get_camera_3d()
	var camera_position := camera.global_transform.origin
	var distance := global_transform.origin.distance_to(camera_position)
	if is_reachable:
		if distance > far:
			is_reachable = false
			state_change.emit(is_reachable)
			exit.emit()
	else:
		if distance < near:
			is_reachable = true
			state_change.emit(is_reachable)
			enter.emit()
	pass
