extends Node3D

# Puzzle Data
const PuzzleGroupName : StringName = &"PuzzleGroup"
const InteractableLinkerGroupName : StringName = &"InteractableLinkerGroup"
const PlayerGroupName : StringName = &"PlayerGroup"
const PuzzleSoundEffectsBus : StringName = &"PuzzleSoundEffect"
const PuzzleViewportSizes : Dictionary = {
	"regular": Vector2(600, 600),
	"large": Vector2(2048, 2048),
}
const AllPuzzleJsons : Dictionary = {
	"first_try": preload("res://PuzzleDataJson/Json.json"),
	"second": preload("res://PuzzleDataJson/Json2.json"),
	"second2": preload("res://PuzzleDataJson/Json2-1.json"),
	"hello_world": preload("res://PuzzleDataJson/Json3.json"),
	"generator": preload("res://PuzzleDataJson/PuzzleTest.json"),
	"crt": preload("res://PuzzleDataJson/CRTTest.json"),
}
var AllPuzzleData : Dictionary = {
	"first_try": PuzzleData.new(AllPuzzleJsons.first_try),
	"second": PuzzleData.new(AllPuzzleJsons.second),
	"second2": PuzzleData.new(AllPuzzleJsons.second2),
	"hello_world": PuzzleData.new(AllPuzzleJsons.hello_world),
	"generator": PuzzleData.new(AllPuzzleJsons.generator),
	"crt": PuzzleData.new(AllPuzzleJsons.crt),
}
# Layers: Puzzles | CurrentPuzzle | ... | InvisibleObstacles | Player | Interactable | Visual | Normal
const PhysicsLayerNormal 				: int = 0b10000000000000000000000000000001
const PhysicsLayerVisual 				: int = 0b00000000000000000000000000000010
const PhysicsLayerInteractables 		: int = 0b00000000000000000000000000000100
const PhysicsLayerPlayer 				: int = 0b00000000000000000000000000001000
const PhysicsLayerInvisibleObstacles	: int = 0b00000000000000000000000000010000
const PhysicsLayerPuzzles 				: int = 0b10000000000000000000000000000000
const PhysicsLayerCurrentPuzzle			: int = 0b01000000000000000000000000000000
const PhysicsLayerInteractObstacles 	: int = PhysicsLayerPuzzles | PhysicsLayerNormal | PhysicsLayerVisual | PhysicsLayerInteractables

# Cursor Movement
enum CursorState {
	DISABLED,
	PICKING,
	DRAWING,
}

signal mouse_moved(normalized_position : Vector2, border_percent : float)
signal cursor_state_changed(state : CursorState, old_state : CursorState)
signal rotate_camera_interact(event : InputEvent)
signal rotate_camera_on_edge(axis : Vector3, angle : float, from : Vector3, to : Vector3)

func _init() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE

func get_player() -> Player:
	return get_tree().get_first_node_in_group(PlayerGroupName)

var cursor_state : CursorState = CursorState.DISABLED
const Mouse2DSensitivity : float = 3.0
const Mouse3DSensitivity : float = 0.1
const CameraEdgeMovementSensitivity : float = 0.5
var mouse_position : Vector2 = Vector2.ZERO
var border_percent : float = 0.0
const BorderFadeStep : float = 0.1
const BorderPowerFactor : float = 8.0
const BorderPercent : float = 0.0

func set_cursor_state(state : CursorState) -> void:
	var old_state := cursor_state
	if cursor_state != state:
		cursor_state = state
		if old_state == CursorState.DISABLED:
			set_mouse_position()
		if cursor_state == CursorState.DISABLED:
			set_active_puzzle_panel(null)
			set_preferred_puzzle_panel(null)
		cursor_state_changed.emit(cursor_state, old_state)
	pass

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

func is_position_in_view(_position : Vector3) -> bool:
	var camera : Camera3D = get_viewport().get_camera_3d()	
	return camera.is_position_in_frustum(_position)

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
	if event.is_action_pressed("ui_cancel"):
		if last_puzzle_panel != null:
			(last_puzzle_panel as Interactable).input_event(InputPuzzleForceExitEvent.new(), Vector3.ZERO, Vector3.ZERO)
		set_cursor_state(CursorState.DISABLED)
		get_viewport().set_input_as_handled()
		get_tree().paused = true
		pass
	var viewport_size := get_viewport().get_visible_rect().size
	if event as InputEventMouseMotion and (event as InputEventMouseMotion).relative != Vector2.ZERO:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED: 
			if cursor_state == CursorState.DISABLED:
				rotate_camera_interact.emit(event)
			else:
				mouse_position += (event as InputEventMouseMotion).relative / (viewport_size) * Mouse2DSensitivity
				set_mouse_position(mouse_position)
	elif cursor_state == CursorState.DISABLED:
		if event is InputEventMouseButton and event.is_pressed() and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			set_mouse_position()
			set_cursor_state(CursorState.PICKING)
			return
	elif cursor_state == CursorState.PICKING:
		if event is InputEventMouseButton and event.is_pressed() and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_RIGHT:
			set_cursor_state(CursorState.DISABLED)
			return
		elif has_preferred_puzzle_panel():
			var target_direction : int = -1
			if event.is_action_pressed("ui_up"):
				target_direction = 0
			elif event.is_action_pressed("ui_right"):
				target_direction = 1
			elif event.is_action_pressed("ui_down"):
				target_direction = 2
			elif event.is_action_pressed("ui_left"):
				target_direction = 3
			if target_direction != -1:
				var next : Interactable = preferred_puzzle_panel.get_next_interactable(target_direction)
				if next is PuzzlePanel:
					var player := get_player()
					player.move_and_rotate_to_panel(next)
				return
		var ans := pick_interactable(mouse_position)
		if not ans.is_empty():
			var obj = ans.collider
			var normal : Vector3 = ans.normal
			var _position : Vector3 = ans.position
			var parent = obj.get_parent()
			if parent != null:
				if parent is Interactable:
					if preferred_puzzle_panel != null and parent is PuzzlePanel and parent != preferred_puzzle_panel:
						if event is InputEventMouseButton and event.is_pressed() and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
							var player := get_player()
							player.move_and_rotate_to_panel(parent)
					else:
						(parent as Interactable).input_event(event, (parent as Interactable).mouse_to_local(_position), _position)
	elif cursor_state == CursorState.DRAWING and last_puzzle_panel != null:
		(last_puzzle_panel as Interactable).input_event(event, Vector3.ZERO, Vector3.ZERO)
	pass

var preferred_puzzle_panel : PuzzlePanel = null
func set_preferred_puzzle_panel(panel : PuzzlePanel) -> void:
	if panel != preferred_puzzle_panel:
		if preferred_puzzle_panel != null:
			preferred_puzzle_panel.on_unpreferred()
	preferred_puzzle_panel = panel
	if preferred_puzzle_panel != null:
		preferred_puzzle_panel.on_preferred()
	pass

func has_preferred_puzzle_panel() -> bool:
	return preferred_puzzle_panel != null

var last_puzzle_panel : PuzzlePanel = null
func set_active_puzzle_panel(panel : PuzzlePanel = null) -> void:
	if last_puzzle_panel != panel:
		if last_puzzle_panel != null:
			last_puzzle_panel.area.collision_layer &= ~PhysicsLayerCurrentPuzzle
		last_puzzle_panel = panel
		if last_puzzle_panel != null:
			last_puzzle_panel.area.collision_layer |= PhysicsLayerCurrentPuzzle

func _process(delta: float) -> void:
	if cursor_state == CursorState.DISABLED: return
	if cursor_state == CursorState.DRAWING and last_puzzle_panel != null:
		var ans := pick_interactable(mouse_position, PhysicsLayerCurrentPuzzle)
		var new_mouse_position = null
		if not ans.is_empty():
			var obj : CollisionObject3D = ans.collider
			var normal : Vector3 = ans.normal
			var _position : Vector3 = ans.position
			new_mouse_position = last_puzzle_panel.on_mouse_moved(_position)
		else:
			var current := (last_puzzle_panel as Interactable).get_current_world_position()
			var from = get_mouse_position_from_world(current)
			var pos = get_viewport_position_from_mouse(from)
			get_node("/root/World/GameUI/TestCursor").position = pos
			var farest := get_farrest_reachable(from, mouse_position, PhysicsLayerCurrentPuzzle)
			if not farest.is_empty():
				var obj : CollisionObject3D = farest.collider
				var normal : Vector3 = farest.normal
				var _position : Vector3 = farest.position
				if not is_position_in_view(_position):
					(last_puzzle_panel as Interactable).input_event(InputPuzzleForceExitEvent.new(), Vector3.ZERO, Vector3.ZERO)
				else:
					new_mouse_position = last_puzzle_panel.on_mouse_moved(_position)
					var _pos = get_viewport_position_from_mouse(get_mouse_position_from_world(_position))
					get_node("/root/World/GameUI/TestCursor2").position = _pos
			else:
				if not is_position_in_view(current):
					(last_puzzle_panel as Interactable).input_event(InputPuzzleForceExitEvent.new(), Vector3.ZERO, Vector3.ZERO)
				else:
					new_mouse_position = last_puzzle_panel.on_mouse_moved(current)
					get_node("/root/World/GameUI/TestCursor2").position = pos
		if new_mouse_position != null:
			set_mouse_position_from_world(new_mouse_position)
		move_camera_on_edge(delta)
		if new_mouse_position != null:
			set_mouse_position_from_world.call_deferred(new_mouse_position)
#			set_mouse_position_from_world(new_mouse_position)
	pass

@onready var physics : PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
func pick_interactable(mouse_pos : Vector2, collision_layer : int = PhysicsLayerInteractObstacles, ray_length : float = -1.0) -> Dictionary:
	var vp := get_viewport()
	var camera := vp.get_camera_3d()
	var length := camera.far if ray_length <= 0 else ray_length
	var size := vp.get_visible_rect().size
	mouse_pos = (mouse_pos + Vector2.ONE) / 2.0 * size
	var query : PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.collision_mask = collision_layer
	query.hit_from_inside = true
	var from := camera.project_ray_origin(mouse_pos)
	var project_normal := camera.project_ray_normal(mouse_pos)
	query.from = from
	query.to = from + project_normal * length
	return physics.intersect_ray(query)

func pick_first_obstacle(from : Vector3, target : CollisionObject3D, self_distance : float = 0.001, collision_layer : int = PhysicsLayerInteractObstacles) -> Dictionary:
	var query : PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.collision_mask = collision_layer
#	query.exclude = [target]
	query.hit_from_inside = true
	var _from := get_viewport().get_camera_3d().global_transform.origin
	var _normal := (_from - from).normalized()
	query.to = from + _normal * self_distance
	query.from = _from
	return physics.intersect_ray(query)

func check_reachable(from : Vector3, target : CollisionObject3D, self_distance : float = 0.001, collision_layer : int = PhysicsLayerInteractObstacles) -> bool:
#	var ans = pick_first_obstacle(from, target, self_distance, collision_layer)
	return pick_first_obstacle(from, target, self_distance, collision_layer).is_empty()

func get_farrest_reachable(from : Vector2, to : Vector2, collision_layer : int = PhysicsLayerInteractObstacles, interval : float = 0.005) -> Dictionary:
	var ans : Dictionary = {}
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
		var quat := Quaternion(from, to)
		var axis := quat.get_axis()
		var angle := quat.get_angle() * delta * CameraEdgeMovementSensitivity * border_percent
		rotate_camera_on_edge.emit(axis, angle, from, to)

# ready
# develop only
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_end"):
		get_tree().quit()

func _ready() -> void:
#	process_priority = INF
#	cursor_state_changed.connect(try_save_game)
	pass

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		await GameSaver.save_game_save_data_resource()
		get_tree().quit()
