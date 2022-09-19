extends Node3D

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
#	print_orphan_nodes()
	pass

func _process(delta: float) -> void:
#	print(get_tree().get_processed_tweens().size())
	pass
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_home"):
		%AutoTester.solve()
#		var player := GlobalData.get_player()
#		var trans : Transform3D = player.get_look_at_transform(%Position3D.global_transform.origin)
#		trans = Transform3D(trans.basis, player.position)
#		player.create_move_and_rotate_tween(trans)
