extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

@onready var Body : CharacterBody3D = self
@onready var Neck : Node3D = %Neck
@onready var Rotator : Node3D = %Rotator
@onready var Camera : Camera3D = %Camera

# Get the gravity from the project settings to be synced with RigidDynamicBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	GlobalData.rotate_camera_on_edge.connect(rotate_camera_on_edge)
	GlobalData.rotate_camera_interact.connect(rotate_camera_on_interact)

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	if GlobalData.cursor_state == GlobalData.CursorState.DISABLED:
		var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)
	else:
		velocity.x = 0
		velocity.z = 0

	move_and_slide()

func rotate_camera_on_edge(_rotation : Quaternion, from : Vector3, to : Vector3)-> void:
	Rotator.rotation.x = Neck.rotation.x
	Rotator.rotation.y = Body.rotation.y
	Rotator.rotate(_rotation.get_axis().normalized(), _rotation.get_angle())
	Rotator.rotation.z = 0.0
	Neck.rotation.x = Rotator.rotation.x
	Body.rotation.y = Rotator.rotation.y
	pass

var mouse_sensitivity = 0.1
func rotate_camera_on_interact(event : InputEvent) -> void:
	if event is InputEventMouseMotion:
		Body.rotate_y(deg2rad(-event.relative.x * GlobalData.Mouse3DSensitivity))
		Neck.rotate_x(deg2rad(-event.relative.y * GlobalData.Mouse3DSensitivity))
		Neck.rotation.x = clamp(Neck.rotation.x, deg2rad(-89), deg2rad(89))
	pass
