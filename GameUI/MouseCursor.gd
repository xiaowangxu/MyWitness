extends Polygon2D

var mouse_position : Vector2

@export var IndicatorNodePath : NodePath
@onready var Indicator : Panel = get_node(IndicatorNodePath)

func _ready() -> void:
	GlobalData.mouse_moved.connect(on_mouse_moved)
	GlobalData.cursor_state_changed.connect(on_cursor_state_changed)
	pass

func on_mouse_moved(normalized_position : Vector2, border_percent : float) -> void:
	mouse_position = normalized_position
	pass

func _process(delta: float) -> void:
	var viewport_size := get_viewport_rect().size
	position = (mouse_position + Vector2.ONE) / 2 * viewport_size
	pass

func on_cursor_state_changed(newval : GlobalData.CursorState, oldval : GlobalData.CursorState) -> void:
#	print(oldval , " -> ", newval)
	match newval:
		0: 
			self.visible = false
			Indicator.visible = false
		1: 
			self.visible = true
			Indicator.visible = true
		2: 
			self.visible = true
			Indicator.visible = true
	pass
