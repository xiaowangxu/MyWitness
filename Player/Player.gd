class_name Player
extends CharacterBody3D

const SPEED = 7.0
const RUN_SPEED = 11.0

@onready var body : CharacterBody3D = self
@onready var neck : Node3D = %Neck
@onready var rotator : Node3D = %Rotator
@onready var camera : Camera3D = %Camera

@export var nav : NavigationRegion3D

# Get the gravity from the project settings to be synced with RigidDynamicBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	rotation = Vector3.ZERO
	add_to_group(GlobalData.PlayerGroupName)
	load_save()
	GlobalData.rotate_camera_on_edge.connect(rotate_camera_on_edge)
	GlobalData.rotate_camera_interact.connect(rotate_camera_on_interact)
	GlobalData.cursor_state_changed.connect(on_cursor_state_changed)

func _physics_process(delta: float) -> void:
#	var last_pos := global_transform.origin
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	if GlobalData.cursor_state == GlobalData.CursorState.DISABLED:
		var speed := SPEED
		if Input.is_action_pressed("shift"): speed = RUN_SPEED
		var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		var direction := (neck.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)
	else:
		velocity.x = 0
		velocity.z = 0
	
#	%Walkzilla.update_collision(self.global_transform.origin + Vector3(0, 4, 0))
	move_and_slide()
	
#	var b = global_transform.origin
#
#	if b.distance_to(last_pos) > 0.01:
#		var rid = nav.get_region_rid()
#		var map_rid = NavigationServer3D.region_get_map(rid)
#		var closest_point = NavigationServer3D.map_get_closest_point(map_rid, global_transform.origin)
#		var a = closest_point
#		global_transform.origin.x = a.x
#		global_transform.origin.z = a.z
#	printt(b, global_transform.origin)

func on_cursor_state_changed(new_state : GlobalData.CursorState, old_state : GlobalData.CursorState) -> void:
	if old_state == GlobalData.CursorState.DISABLED and new_state == GlobalData.CursorState.PICKING:
		var panel := pick_nearest_panel()
		if panel != null:
			move_and_rotate_to_panel(panel)
	pass

const NearestReachableLength = 4.0
func pick_nearest_panel() -> PuzzlePanel:
	var detect_position : PackedVector2Array = [Vector2.ZERO, Vector2(0.25, 0), Vector2(0.5, 0), Vector2(-0.25, 0), Vector2(-0.5, 0), Vector2(0, 0.25), Vector2(0, 0.5), Vector2(0, -0.25), Vector2(0, -0.5)]
	var ans : Dictionary = {}
	for pos in detect_position:
		var _ans := GlobalData.pick_interactable(pos, GlobalData.PhysicsLayerInteractObstacles, NearestReachableLength)
		if not _ans.is_empty():
			var parent = _ans.collider.get_parent()
			if parent != null and parent is PuzzlePanel:
				if ans.has(parent):
					ans[parent].append(_ans.position)
				else:
					ans[parent] = [_ans.position]
	if ans.is_empty(): return null
	var panels : Array[PuzzlePanel] = ans.keys()
	var target := panels[0]
	var target_count : int = ans[target].size()
	for i in range(1, panels.size()):
		var _target := panels[i]
		if ans[_target].size() > target_count:
			target = _target
			target_count = ans[_target].size()
	return target

func rotate_camera_on_edge(axis : Vector3, angle : float, from : Vector3, to : Vector3)-> void:
	rotator.rotation.x = camera.rotation.x
	rotator.rotation.y = neck.rotation.y
	rotator.rotation.z = 0.0
	rotator.rotate(axis.normalized(), angle)
	rotator.rotation.z = 0.0
	camera.rotation.x = rotator.rotation.x
	neck.rotation.y = rotator.rotation.y
	clamp_camera_angle()
	pass

func get_current_transform() -> Transform3D:
	return Transform3D(Basis(Quaternion(Vector3(camera.rotation.x, neck.rotation.y, 0))), global_transform.origin)

func get_safe_position() -> Vector3:
	return %Mesh.global_transform.origin

func get_landing_position(safe_pos : Vector3) -> Vector3:
	var raycast : RayCast3D = %RayCast
	raycast.global_transform.origin = safe_pos
	raycast.force_raycast_update()
	raycast.position = Vector3.ZERO
	if raycast.is_colliding():
		return raycast.get_collision_point()
	else:
		return safe_pos

var mouse_sensitivity = 0.1
var up_max_deg = 85
var down_max_deg = 60
func clamp_camera_angle() -> void:
	var up_max_rad := deg_to_rad(up_max_deg)
	var down_max_rad := deg_to_rad(-down_max_deg)
	camera.rotation.x = clamp(camera.rotation.x, down_max_rad, up_max_rad)
	pass

func rotate_camera_on_interact(event : InputEvent) -> void:
	if event is InputEventMouseMotion:
		neck.rotate_y(deg_to_rad(-event.relative.x * GlobalData.Mouse3DSensitivity))
		camera.rotate_x(deg_to_rad(-event.relative.y * GlobalData.Mouse3DSensitivity))
		var up_max_rad := deg_to_rad(up_max_deg)
		var down_max_rad := deg_to_rad(-down_max_deg)
		clamp_camera_angle()
	pass

func move_and_rotate_to_transform(trans : Transform3D) -> void:
	global_transform.origin = trans.origin
	camera.transform.basis = Basis(Quaternion(Vector3(trans.basis.get_euler().x, 0, 0)))
	neck.transform.basis = Basis(Quaternion(Vector3(0, trans.basis.get_euler().y, 0)))
	clamp_camera_angle()

const MoveAndRotateDuration : float = 0.5
func create_move_and_rotate_tween(target_transform : Transform3D) -> void:
	var tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_method(move_and_rotate_to_transform, get_current_transform(), target_transform, MoveAndRotateDuration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)

func move_and_rotate_to_panel(panel : PuzzlePanel) -> void:
	GlobalData.set_preferred_puzzle_panel(panel)
	var current_transform := get_current_transform()
	var preferred_transform : Transform3D = panel.get_preferred_transform(current_transform)
	var pos := preferred_transform.origin
	var safe_pos := get_landing_position(pos + Vector3(0, 4, 0))
	preferred_transform = Transform3D(get_look_at_transform(panel.global_transform.origin, safe_pos + Vector3(0, 4, 0)).basis, safe_pos)
	if not preferred_transform.is_equal_approx(current_transform):
		create_move_and_rotate_tween(preferred_transform)

func save() -> void:
	GameSaver.save_player(get_safe_position(), camera.rotation.x, neck.rotation.y)
	pass

func load_save() -> void:
	var pos : Vector3 = GameSaver.get_player_position()
	var lookat : Vector2= GameSaver.get_player_lookat()
	position = get_landing_position(pos)
	camera.rotation.x = lookat.x
	neck.rotation.y = lookat.y
	pass

func get_look_at_transform(target : Vector3, from : Vector3 = %Camera.global_transform.origin) -> Transform3D:
	var trans := Transform3D()
	trans = trans.looking_at(target - from)
	return trans
