extends Node3D

@export var near : float = 10.0
@export var far : float = 20.0
@onready var mid : float = (near + far) / 2.0

var is_reachable : bool = false :
	set(val):
		if is_reachable != val:
			is_reachable = val
			print(">>>>>>>> set ", is_reachable)

var state : String

func _ready():
	var camera = get_viewport().get_camera_3d()
	var camera_position = camera.global_transform.origin
	var self_position = self.global_transform.origin
	var distance = camera_position.distance_to(self_position)
	is_reachable = distance <= far
	if is_reachable:
		state = 'in'
	else:
		state = 'out'
	pass

func _process(delta):
	_update()
	pass

func _update():
	var camera = get_viewport().get_camera_3d()
	var camera_position = camera.global_transform.origin
	var self_position = self.global_transform.origin
	var distance = camera_position.distance_to(self_position)
	$"../Label".text = "%s%.3f %s" % ['' if distance >= 10 else '0', distance, state]
	var distance_state = 0
	if distance < near:
		distance_state = 0
	elif distance <= mid:
		distance_state = 1
	elif distance <= far:
		distance_state = 2
	else:
		distance_state = 3
	var next_state : String
	match state:
		'in':
			match distance_state:
				0: next_state = 'in'
				1: next_state = 'in'
				2: next_state = 'fade_out'
				3: next_state = 'out'
		'out':
			match distance_state:
				0: next_state = 'in'
				1: next_state = 'fade_in'
				2: next_state = 'out'
				3: next_state = 'out'
		'fade_out':
			match distance_state:
				0: next_state = 'in'
				1: next_state = 'in'
				2: next_state = 'fade_out'
				3: next_state = 'out'
		'fade_in':
			match distance_state:
				0: next_state = 'in'
				1: next_state = 'fade_in'
				2: next_state = 'out_margin'
				3: next_state = 'out'
		'out_margin':
			match distance_state:
				0: next_state = 'in'
				1: next_state = 'fade_in'
				2: next_state = 'out_margin'
				3: next_state = 'out'
#	print(state, " -> ", next_state)
	if state != next_state:
		if state == 'out':
			is_reachable = true
		elif next_state == 'out':
			is_reachable = false
	state = next_state
	if state == 'fade_in':
		print("percent ", 1.0-(distance-near)/(mid-near))
	elif state == 'fade_out':
		print("percent ", 1.0-(distance-mid)/(far-mid))
	elif state == 'in':
		print("percent ", 1.0)
	elif state == 'out':
		print("percent ", 0.0)
	elif state == 'out_margin':
		print("percent ", 0.0)
