extends Area2D

var is_hovered : bool = false

func _on_area_2d_mouse_entered() -> void:
	print(">>> ", is_hovered)
	is_hovered = true
	pass # Replace with function body.

func _on_area_2d_mouse_exited() -> void:
	is_hovered = false
	pass # Replace with function body.
