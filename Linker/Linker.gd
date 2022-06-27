class_name InteractableLinker
extends Node

@export var InteractableNodePath : NodePath
@export var acceptable_tags : PackedInt32Array = []
@onready var interactable : Interactable = get_node(InteractableNodePath)

func _ready() -> void:
	add_to_group(GlobalData.InteractableLinkerName)
	if interactable != null:
		interactable.interact_result_changed.connect(_on_interact_result_changed)

func _on_interact_result_changed(correct : bool, tag : int) -> void:
	if acceptable_tags.has(tag):
		on_interact_result_changed(correct, tag)
	pass

func on_interact_result_changed(correct : bool, tag : int) -> void:
	print(correct, ", ", tag)

func save() -> Dictionary:
	return {}

func load_save(save : Dictionary) -> void:
	pass
