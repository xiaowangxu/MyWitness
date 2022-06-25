extends Polygon2D

var mouse_position : Vector2

func _ready() -> void:
	GlobalData.mouse_moved.connect(on_mouse_moved)

func on_mouse_moved(normalized_position : Vector2, border_percent : float) -> void:
	mouse_position = normalized_position

func _process(delta: float) -> void:
	var viewport_size := get_viewport_rect().size
	position = (mouse_position + Vector2.ONE) / 2 * viewport_size
