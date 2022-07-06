class_name RenderItem
extends Node2D

const WHITE : Color = Color.WHITE

var _rid : RID = get_canvas_item()
var _tween_scheduled : Tween = null

func stop_scheduled_tween() -> void:
	if _tween_scheduled != null:
		_tween_scheduled.kill()
		_tween_scheduled = null
	pass

func create_scheduled_tween() -> Tween:
	if _tween_scheduled != null:
		_tween_scheduled.kill()
	var new_tween := create_tween()
	_tween_scheduled = new_tween
	_tween_scheduled.finished.connect(_reset_scheduled_tween)
	return _tween_scheduled

func _reset_scheduled_tween() -> void:
	_tween_scheduled = null
