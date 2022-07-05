class_name PanelInteractableLinker
extends InteractableLinker

@export var NextPanelNodePath : NodePath
@onready var next_panel : PuzzlePanel = get_node(NextPanelNodePath)

func on_interact_result_changed(correct : bool, tag : int) -> void:
	next_panel.set_active_with_tween(true)
