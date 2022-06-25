extends Node3D

# Puzzle Data
const PuzzleGroupName : StringName = &"PuzzleGroup"
const PuzzleSoundEffectsBus : StringName = &"PuzzleSoundEffect"
const PuzzleViewportSizes : Dictionary = {
	"regular": Vector2(1024, 1024),
}
const AllPuzzleJsons : Dictionary = {
	"first_try": preload("res://Puzzle/Json/Json.json"),
	"second": preload("res://Puzzle/Json/Json2.json"),
	"hello_world": preload("res://Puzzle/Json/Json3.json"),
}
var AllPuzzleData : Dictionary = {
	"first_try": PuzzleData.new(AllPuzzleJsons.first_try),
	"second": PuzzleData.new(AllPuzzleJsons.second),
	"hello_world": PuzzleData.new(AllPuzzleJsons.hello_world),
}
const PhysicsLayerCurrentPuzzle : int = 0b00000000000000000000000000000010

# Cursor Movement
enum CursorState {
	DISABLED,
	PICKING,
	DRAWING
}

signal mouse_moved(normalized_position : Vector2, border_percent : float)
signal cursor_state_changed(state : CursorState, old_state : CursorState)

var cursor_state : CursorState = CursorState.PICKING
const Mouse2DSensitivity : float = 2.5
const CameraEdgeMovementSensitivity : float = 0.85
var mouse_position : Vector2 = Vector2.ZERO
var border_percent : float = 0.0
const BorderFadeStep : float = 0.1
const BorderPowerFactor : float = 8.0
const BorderPercent : float = 0.0005

func set_cursor_state(state : CursorState) -> void:
	var old_state := cursor_state
	if cursor_state != state:
		cursor_state = state
		if old_state == CursorState.DISABLED:
			set_mouse_position()
		if cursor_state == CursorState.DISABLED:
			set_active_puzzle_panel(null)
		cursor_state_changed.emit(cursor_state, old_state)

func get_mouse_position_from_world(_position : Vector3) -> Vector2:
	var vp := get_viewport()
	var camera := vp.get_camera_3d()
	var size := get_viewport().get_visible_rect().size
	var pos := camera.unproject_position(_position)
	pos /= size
	pos *= 2
	pos -= Vector2.ONE
	return pos

func get_viewport_position_from_mouse(mouse_position : Vector2) -> Vector2:
	var viewport_size := get_viewport().get_visible_rect().size
	return (mouse_position + Vector2.ONE) / 2 * viewport_size

func set_mouse_position_from_world(_position : Vector3) -> void:
	set_mouse_position(get_mouse_position_from_world(_position))

func set_mouse_position(_position : Vector2 = Vector2.ZERO) -> void:
	_position.x = clampf(_position.x, -1.0, 1.0)
	_position.y = clampf(_position.y, -1.0, 1.0)
	mouse_position = _position
	border_percent = calcu_border_value(mouse_position)
	mouse_moved.emit(mouse_position, border_percent)
	pass

func calcu_border_value(pos : Vector2) -> float:
	var viewport_size := get_viewport().get_visible_rect().size
	var w := viewport_size.x / 2.0;
	var h := viewport_size.y / 2.0;
	var _a : float = minf(BorderPercent * w, BorderPercent * h);
	var _p : float = (h - _a) / h;
	var p := (w - _a) / w;
	var _pos = pos;
	_pos.x /= p;
	_pos.y /= _p;
	var distance : float = pow(abs(_pos.x), BorderPowerFactor) + pow(abs(_pos.y), BorderPowerFactor)
	return smoothstep(BorderFadeStep, 1.0, distance)

func _unhandled_input(event: InputEvent) -> void:
	if cursor_state == CursorState.DISABLED: return
	var viewport_size := get_viewport().get_visible_rect().size
	if event as InputEventMouseMotion and (event as InputEventMouseMotion).relative != Vector2.ZERO:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED: 
			mouse_position += (event as InputEventMouseMotion).relative / (viewport_size) * Mouse2DSensitivity
			set_mouse_position(mouse_position)
	elif cursor_state == CursorState.PICKING:
		var ans := pick_interactable(mouse_position)
		if not ans.is_empty():
			var obj = ans.collider
			var normal : Vector3 = ans.normal
			var _position : Vector3 = ans.position
			var parent = obj.get_parent()
			if parent != null:
				if parent is Interactable:
					(parent as Interactable).input_event(event,
						(parent as Interactable).mouse_to_local(_position), _position)
	elif cursor_state == CursorState.DRAWING and last_puzzle_panel != null:
		(last_puzzle_panel as Interactable).input_event(event, Vector3.ZERO, Vector3.ZERO)
	pass

var last_puzzle_panel : PuzzlePanel = null
func set_active_puzzle_panel(panel : PuzzlePanel) -> void:
	if last_puzzle_panel != panel:
		if last_puzzle_panel != null:
			last_puzzle_panel.area.collision_layer &= ~PhysicsLayerCurrentPuzzle
		last_puzzle_panel = panel
		if last_puzzle_panel != null:
			last_puzzle_panel.area.collision_layer |= PhysicsLayerCurrentPuzzle

func _physics_process(delta: float) -> void:
	if cursor_state == CursorState.DISABLED: return
	if cursor_state == CursorState.DRAWING and last_puzzle_panel != null:
		var ans := pick_interactable(mouse_position, PhysicsLayerCurrentPuzzle)
		var new_mouse_position = null
		if not ans.is_empty():
			var obj : Area3D = ans.collider
			var normal : Vector3 = ans.normal
			var _position : Vector3 = ans.position
			new_mouse_position = last_puzzle_panel.on_mouse_moved(_position)
		else:
			var camera : Camera3D = get_viewport().get_camera_3d()
			var current := (last_puzzle_panel as Interactable).get_current_mouse_position()
			var from = get_mouse_position_from_world(current)
			var pos = get_viewport_position_from_mouse(from)
			get_node("/root/World/GameUI/TestCursor").position = pos
			var farest := get_farrest_reachable(from, mouse_position, PhysicsLayerCurrentPuzzle)
			if not farest.is_empty():
				var obj : Area3D = farest.collider
				var normal : Vector3 = farest.normal
				var _position : Vector3 = farest.position
				if not camera.is_position_in_frustum(_position):
					(last_puzzle_panel as Interactable).input_event(InputPuzzleForceExitEvent.new(), Vector3.ZERO, Vector3.ZERO)
				else:
					new_mouse_position = last_puzzle_panel.on_mouse_moved(_position)
					var _pos = get_viewport_position_from_mouse(get_mouse_position_from_world(_position))
					get_node("/root/World/GameUI/TestCursor2").position = _pos
			else:
				if camera.is_position_in_frustum(current):
					new_mouse_position = last_puzzle_panel.on_mouse_moved(current)
					get_node("/root/World/GameUI/TestCursor2").position = pos
				else:
					(last_puzzle_panel as Interactable).input_event(InputPuzzleForceExitEvent.new(), Vector3.ZERO, Vector3.ZERO)
		if new_mouse_position != null:
			set_mouse_position_from_world(new_mouse_position)
		move_camera_on_edge(delta)
		if new_mouse_position != null:
			set_mouse_position_from_world(new_mouse_position)
	pass

@onready var physics : PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
func pick_interactable(mouse_pos : Vector2, collision_layer : int = 0xFFFFFFFF) -> Dictionary:
	var vp := get_viewport()
	var camera := vp.get_camera_3d()
	var length := camera.far
	var size := vp.get_visible_rect().size
	mouse_pos = (mouse_pos + Vector2.ONE) / 2.0 * size
	var query : PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_mask = collision_layer
	var from := camera.project_ray_origin(mouse_pos)
	var project_normal := camera.project_ray_normal(mouse_pos)
	query.from = from
	query.to = from + project_normal * length
	return physics.intersect_ray(query)

func pick_first_obstacle(from : Vector3, target : Area3D, self_distance : float = 0.001, collision_layer : int = 0xFFFFFFFF) -> Dictionary:
	var query : PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.collision_mask = collision_layer
	query.exclude = [target]
	var _from := get_viewport().get_camera_3d().global_transform.origin
	var _normal := (_from - from).normalized()
	query.to = from - _normal * self_distance
	query.from = _from
	return physics.intersect_ray(query)

func check_reachable(from : Vector3, target : Area3D, self_distance : float = 0.001, collision_layer : int = 0xFFFFFFFF) -> bool:
	return pick_first_obstacle(from, target, self_distance, collision_layer).is_empty()

func get_farrest_reachable(from : Vector2, to : Vector2, collision_layer : int = 0xFFFFFFFF, interval : float = 0.005) -> Dictionary:
	var ans : Dictionary = {}
#	if from.x < -1 or from.x > 1 or from.y < -1 or from.y > 1: return ans
	var length = from.distance_to(to)
	var count = mini(floor(length / interval), 300)
	if count <= 1: return ans
	for i in range(1, count):
		var pos := from.lerp(to, float(i)/float(count))
		var _ans = pick_interactable(pos, collision_layer)
		if _ans.is_empty():
#			print(i, " / ", count)
			return ans
		else:
			ans = _ans
	return ans

func move_camera_on_edge(delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	var viewport_size := get_viewport().get_visible_rect().size
	var _position = (mouse_position + Vector2.ONE) / 2 * viewport_size
	if border_percent > 0.0:
		var to : Vector3 = camera.project_ray_normal(_position)
		var from : Vector3 = camera.project_ray_normal(viewport_size/2)
		var quat := Quaternion(-from, -to)
		camera.rotate(quat.get_axis(), quat.get_angle() * delta * CameraEdgeMovementSensitivity * border_percent)
		camera.rotation.z = 0.0
