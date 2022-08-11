extends Node3D

@export var grid_count : int = 5
@export var grid_gap : float = 0.2
@export var leg_height : float = 2.5
@export var target_position : Vector3 = Vector3(0, -2, 0)
@onready var ray_count : int = grid_count ** 2
var rays : Array[RayCast3D] = []
var indicators : Array[MeshInstance3D] = []
var collision_positions : Array = []

func _ready() -> void:
	var grid_start := - (grid_count - 1) * grid_gap / 2
	collision_positions.resize(ray_count)
	for y in grid_count:
		for x in grid_count:
			var ray : RayCast3D = RayCast3D.new()
			ray.target_position = target_position
			ray.collision_mask = GlobalData.PhysicsLayerPlayerCollision
			%Rays.add_child(ray)
			ray.position = Vector3(grid_start + x * grid_gap, 0, grid_start + y * grid_gap)
			rays.append(ray)
			ray.debug_shape_thickness = 1
			var indicator : MeshInstance3D = preload("res://Player/WalkzillaIndicator.tscn").instantiate()
			%Indicators.add_child(indicator)
			indicator.position = ray.position
			indicators.append(indicator)

func decompose_ray_id(ray_id : int) -> PackedInt32Array:
	return PackedInt32Array([ray_id % grid_count, int(ray_id / grid_count)])

func compose_ray_id(x : int, y : int) -> int:
	return y * grid_count + x

func is_index_valid(x : int, y : int) -> bool:
	return 0 <= x and x < grid_count and 0 <= y and y < grid_count

func is_ray_id_valid(ray_id : int) -> bool:
	return 0 <= ray_id and ray_id < ray_count

const SubDivide : int = 20
@onready var physics : PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
func get_farest_point(from : int, to : int, last : Vector3) -> Vector3:
	var from_pos := rays[from].global_transform.origin
	var to_pos := rays[to].global_transform.origin
	var last_pos = last
	for weight in range(1, SubDivide + 1, 1):
		var pos := from_pos.lerp(to_pos, weight/float(SubDivide))
		var _to := pos + target_position
		var query := PhysicsRayQueryParameters3D.new()
		query.collide_with_areas = true
		query.collide_with_bodies = true
		query.collision_mask = GlobalData.PhysicsLayerPlayerCollision
		query.from = pos
		query.to = _to
		query.hit_from_inside = true 
		var ans : Dictionary = physics.intersect_ray(query)
		if ans.is_empty() or not is_leg_valid(pos, ans.position):
			return last_pos
		else:
			last_pos = ans.position
	return last_pos

func is_leg_valid(start : Vector3, end : Vector3) -> bool:
	var to_head := start.y - end.y
	return to_head > leg_height

func update_collision(player_position : Vector3) -> void:
	self.global_transform.origin = player_position.snapped(Vector3.ONE * (grid_count - 1) * grid_gap / 4)
	self.global_transform.origin.y = player_position.y
	
	for ray_id in ray_count:
		var ray := rays[ray_id]
		var indicator := indicators[ray_id]
		if ray.is_colliding():
			var pos := ray.get_collision_point()
			if is_leg_valid(ray.global_transform.origin, pos):
				collision_positions[ray_id] = pos
				indicator.visible = true
				indicator.global_transform.origin = pos
				indicator.set_shader_instance_uniform("color", Color.GREEN)
			else:
				collision_positions[ray_id] = null
				indicator.visible = false
		else:
			collision_positions[ray_id] = null
			indicator.visible = false
	
	for child in %FarIndicators.get_children():
		%FarIndicators.remove_child(child)
		child.queue_free()
	
	for ray_id in ray_count:
		var pos = collision_positions[ray_id]
		var indexs := decompose_ray_id(ray_id)
		var indicator := indicators[ray_id]
		if is_index_valid(indexs[0]+1, indexs[1]):
			var right_id := compose_ray_id(indexs[0]+1, indexs[1])
			var right_pos = collision_positions[right_id]
			var right_indicator = indicators[right_id]
			if pos == null and right_pos != null:
				var far := get_farest_point(right_id, ray_id, right_pos)
				
				var i := preload("res://Player/WalkzillaIndicator.tscn").instantiate()
				%FarIndicators.add_child(i)
				i.global_transform.origin = far
				i.set_shader_instance_uniform("color", Color.DODGER_BLUE)
				
				right_indicator.set_shader_instance_uniform("color", Color.ORANGE_RED)
			if pos != null and right_pos == null:
				var far := get_farest_point(ray_id, right_id, pos)
				
				var i := preload("res://Player/WalkzillaIndicator.tscn").instantiate()
				%FarIndicators.add_child(i)
				i.global_transform.origin = far
				i.set_shader_instance_uniform("color", Color.DODGER_BLUE)
				
				indicator.set_shader_instance_uniform("color", Color.ORANGE_RED)
		if is_index_valid(indexs[0], indexs[1]+1):
			var bottom_id := compose_ray_id(indexs[0], indexs[1]+1)
			var bottom_pos = collision_positions[bottom_id]
			var bottom_indicator = indicators[bottom_id]
			if pos == null and bottom_pos != null:
				var far := get_farest_point(bottom_id, ray_id, bottom_pos)
				
				var i := preload("res://Player/WalkzillaIndicator.tscn").instantiate()
				%FarIndicators.add_child(i)
				i.global_transform.origin = far
				i.set_shader_instance_uniform("color", Color.DODGER_BLUE)
				
				bottom_indicator.set_shader_instance_uniform("color", Color.ORANGE_RED)
			if pos != null and bottom_pos == null:
				var far := get_farest_point(ray_id, bottom_id, pos)
				
				var i := preload("res://Player/WalkzillaIndicator.tscn").instantiate()
				%FarIndicators.add_child(i)
				i.global_transform.origin = far
				i.set_shader_instance_uniform("color", Color.DODGER_BLUE)
				
				indicator.set_shader_instance_uniform("color", Color.ORANGE_RED)
	pass
