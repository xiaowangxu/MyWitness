class_name InteractableNotifier
extends Node3D

signal fade_step(percentage : float)
signal reachable_change(reachable : bool)

@export var near : float = 100.0
@export var far : float = 120.0
@onready var mid : float = (near + far) / 2.0

var is_reachable : bool = false :
	set(val):
		if is_reachable != val:
			is_reachable = val
			reachable_change.emit(is_reachable)
var percentage : float = -1.0 :
	set(val):
		if percentage != val:
			percentage = val
			fade_step.emit(percentage)

enum FadeState {
	IN, OUT, FADE_IN, FADE_OUT, OUT_MARGIN
}

var state : FadeState

func _ready():
	assert(near < far, 'near >= far')
	var camera = get_viewport().get_camera_3d()
	var camera_position = camera.global_transform.origin
	
	var self_position = self.global_transform.origin
	var distance = camera_position.distance_to(self_position)
	is_reachable = distance <= far
	if is_reachable:
		state = FadeState.IN
		percentage = 1.0
	else:
		state = FadeState.OUT
		percentage = 0.0
	_update()
	pass

func _process(delta):
	_update()
	pass

func _update():
	var camera = get_viewport().get_camera_3d()
	var camera_position = camera.global_transform.origin
	var self_position = self.global_transform.origin
	var distance = camera_position.distance_to(self_position)
	var distance_state = 0
	if distance < near:
		distance_state = 0
	elif distance <= mid:
		distance_state = 1
	elif distance <= far:
		distance_state = 2
	else:
		distance_state = 3
	var next_state : FadeState
	match state:
		FadeState.IN:
			match distance_state:
				0: next_state = FadeState.IN
				1: next_state = FadeState.IN
				2: next_state = FadeState.FADE_OUT
				3: next_state = FadeState.OUT
		FadeState.OUT:
			match distance_state:
				0: next_state = FadeState.IN
				1: next_state = FadeState.FADE_IN
				2: next_state = FadeState.OUT
				3: next_state = FadeState.OUT
		FadeState.FADE_OUT:
			match distance_state:
				0: next_state = FadeState.IN
				1: next_state = FadeState.IN
				2: next_state = FadeState.FADE_OUT
				3: next_state = FadeState.OUT
		FadeState.FADE_IN:
			match distance_state:
				0: next_state = FadeState.IN
				1: next_state = FadeState.FADE_IN
				2: next_state = FadeState.OUT_MARGIN
				3: next_state = FadeState.OUT
		FadeState.OUT_MARGIN:
			match distance_state:
				0: next_state = FadeState.IN
				1: next_state = FadeState.FADE_IN
				2: next_state = FadeState.OUT_MARGIN
				3: next_state = FadeState.OUT
#	print(state, " -> ", next_state)
	if next_state == FadeState.FADE_IN:
		percentage = 1.0-(distance-near)/(mid-near)
	elif next_state == FadeState.FADE_OUT:
		percentage = 1.0-(distance-mid)/(far-mid)
	elif next_state == FadeState.IN:
		percentage = 1.0
	elif next_state == FadeState.OUT:
		percentage = 0.0
	elif next_state == FadeState.OUT_MARGIN:
		percentage = 0.0
	if state != next_state:
		if state == FadeState.OUT:
			is_reachable = true
		elif next_state == FadeState.OUT:
			is_reachable = false
	state = next_state
	
