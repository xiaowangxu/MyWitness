extends Node3D

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
#	print_orphan_nodes()
	pass

var freed := false
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		for panel in get_tree().get_nodes_in_group(GlobalData.PuzzleGroupName):
			if freed:
				panel.set_viewports()
			else:
				panel.free_viewports()
		freed = not freed

func _process(delta: float) -> void:
#	print(get_tree().get_processed_tweens().size())
	pass
