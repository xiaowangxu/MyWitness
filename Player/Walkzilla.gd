extends Node3D

enum RayDirection {
	TopLeft = 8,
	TopRight = 4,
	BottomRight = 2,
	BottomLeft = 1,
}

enum CellDirection {
	Up = 0,
	Right = 1,
	Down = 2,
	Left = 3,
}

@export var grid_count : int = 5
@export var grid_gap : float = 0.2
@export var body_height : float = 4.0
@export var leg_height : float = 1.5
@export var target_position : Vector3 = Vector3(0, -2, 0)
@onready var ray_count : int = grid_count ** 2
@onready var cell_count : int = (grid_count - 1) ** 2
@onready var edge_count : int = cell_count * 4
var rays : Array[RayCast3D] = []
var indicators : Array[MeshInstance3D] = []
var collision_positions : Array = []
var cells : PackedInt32Array = []
var edges : PackedVector3Array = []

func _ready() -> void:
	%EdgeMesh.position = Vector3.ZERO
	%Collisions.position = Vector3.ZERO
	var grid_start := - (grid_count - 1) * grid_gap / 2
	collision_positions.resize(ray_count)
	cells.resize(cell_count)
	edges.resize(cell_count * 4)
	for y in grid_count:
		for x in grid_count:
			var ray : RayCast3D = RayCast3D.new()
			ray.target_position = target_position
			ray.collision_mask = GlobalData.PhysicsLayerWalkzilla | GlobalData.PhysicsLayerWalkzillaDisabled
			%Rays.add_child(ray)
			ray.position = Vector3(grid_start + x * grid_gap, 0, grid_start + y * grid_gap)
			rays.append(ray)
			ray.enabled = false
			ray.debug_shape_thickness = 1
			var indicator : MeshInstance3D = preload("res://Player/WalkzillaIndicator.tscn").instantiate()
			%Indicators.add_child(indicator)
			indicator.position = ray.position
			indicators.append(indicator)

func decompose_ray_id(ray_id : int) -> PackedInt32Array:
	return PackedInt32Array([ray_id % grid_count, int(ray_id / grid_count)])

func compose_ray_id(x : int, y : int) -> int:
	return y * grid_count + x

func is_ray_index_valid(x : int, y : int) -> bool:
	return 0 <= x and x < grid_count and 0 <= y and y < grid_count

func decompose_cell_id(cell_id : int) -> PackedInt32Array:
	return PackedInt32Array([cell_id % (grid_count-1), int(cell_id / (grid_count-1))])

func compose_cell_id(x : int, y : int) -> int:
	return y * (grid_count-1) + x

func is_cell_index_vaild(x : int, y : int) -> bool:
	return 0 <= x and x < (grid_count-1) and 0 <= y and y < (grid_count-1)

func is_cell_id_valid(cell_id : int) -> bool:
	return 0 <= cell_id and cell_id < cell_count

func is_ray_id_valid(ray_id : int) -> bool:
	return 0 <= ray_id and ray_id < ray_count

func is_edge_id_valid(edge_id : int) -> bool:
	return 0 <= edge_id and edge_id < edge_count

func compose_edge_id(cell_id : int, direction : CellDirection) -> int:
	return cell_id * 4 + direction

const SubDivide : int = 10
const Delta : float = 0.01
@onready var physics : PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
func get_farest_point(from : int, to : int, last : Vector3) -> Vector3:
	var from_pos := rays[from].global_transform.origin
	var to_pos := rays[to].global_transform.origin
	var last_pos = last
	var mid := (from_pos + to_pos) / 2
	while to_pos.distance_to(mid) > Delta:
		var query := PhysicsRayQueryParameters3D.new()
		query.collide_with_bodies = true
		query.collision_mask = GlobalData.PhysicsLayerWalkzilla | GlobalData.PhysicsLayerWalkzillaDisabled
		query.from = mid
		query.to = mid + target_position
		query.hit_from_inside = false 
		var ans : Dictionary = physics.intersect_ray(query)
		if ans.is_empty() or not is_leg_valid(mid, ans.position) or (ans.collider as StaticBody3D).collision_layer & GlobalData.PhysicsLayerWalkzillaDisabled:
			to_pos = mid
		else:
			last_pos = ans.position
			from_pos = mid
		mid = (from_pos + to_pos) / 2
	return last_pos
#	for weight in range(1, SubDivide + 1, 1):
#		var pos := from_pos.lerp(to_pos, weight/float(SubDivide))
#		var _to := pos + target_position
#		var query := PhysicsRayQueryParameters3D.new()
#		query.collide_with_bodies = true
#		query.collision_mask = GlobalData.PhysicsLayerPlayerCollision
#		query.from = pos
#		query.to = _to
#		query.hit_from_inside = false 
#		var ans : Dictionary = physics.intersect_ray(query)
#		if ans.is_empty() or not is_leg_valid(pos, ans.position):
#			return last_pos
#		else:
#			last_pos = ans.position
#	return last_pos

func get_farest_position(from : Vector3, to : Vector3) -> Vector3:
	var from_pos := from
	var to_pos := to
	var last_pos = Vector3(INF, INF, INF)
	var mid := from_pos
	while to_pos.distance_to(mid) > Delta:
		var query := PhysicsRayQueryParameters3D.new()
		query.collide_with_bodies = true
		query.collision_mask = GlobalData.PhysicsLayerWalkzilla | GlobalData.PhysicsLayerWalkzillaDisabled
		query.from = mid
		query.to = mid + target_position
		query.hit_from_inside = false 
		var ans : Dictionary = physics.intersect_ray(query)
		if ans.is_empty() or not is_leg_valid(mid, ans.position) or (ans.collider as StaticBody3D).collision_layer & GlobalData.PhysicsLayerWalkzillaDisabled:
			to_pos = mid
		else:
			last_pos = ans.position
			from_pos = mid
		mid = (from_pos + to_pos) / 2
	return last_pos
	
	
#	for weight in range(0, SubDivide + 1, 1):
#		var pos := from_pos.lerp(to_pos, weight/float(SubDivide))
#		var _to := pos + target_position
#		var query := PhysicsRayQueryParameters3D.new()
#		query.collide_with_bodies = true
#		query.collision_mask = GlobalData.PhysicsLayerPlayerCollision
#		query.from = pos
#		query.to = _to
#		query.hit_from_inside = false 
#		var ans : Dictionary = physics.intersect_ray(query)
#		if ans.is_empty() or not is_leg_valid(pos, ans.position):
#			return last_pos
#		else:
#			last_pos = ans.position
#	return last_pos

func is_leg_valid(start : Vector3, end : Vector3) -> bool:
	var distance := start.y - end.y
	return distance > (body_height - leg_height) and distance < (body_height + leg_height)

@onready var mesh : ImmediateMesh = %EdgeMesh.mesh
func clear_edge_mesh() -> void:
	mesh.clear_surfaces()
#	for child in %Collisions.get_children():
#		%Collisions.remove_child(child)
#		child.queue_free()
	pass

func add_edge_mesh(a : Vector3, b : Vector3) -> void:
#	a = %EdgeMesh.to_local(a)
#	b = %EdgeMesh.to_local(b)
#	var c := preload("res://Player/WalkzillaCollision.tscn").instantiate()
#	c.position = a
#	c.scale.z = Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))
#	c.rotation.y = TAU + PI/2 - (Vector2(b.x, b.z) - Vector2(a.x, a.z)).angle()
#	%Collisions.add_child(c)

	mesh.surface_begin(Mesh.PRIMITIVE_LINES, preload("res://Player/WalkzillaEdgeMaterial.tres"))
	mesh.surface_set_color(Color.RED)
	mesh.surface_add_vertex(a)
	mesh.surface_set_color(Color.RED)
	mesh.surface_add_vertex(b)
	mesh.surface_end()

	mesh.surface_begin(Mesh.PRIMITIVE_LINES, preload("res://Player/WalkzillaEdgeMaterial.tres"))
	mesh.surface_set_color(Color.RED)
	mesh.surface_add_vertex(a)
	mesh.surface_set_color(Color.RED)
	mesh.surface_add_vertex(a - target_position)
	mesh.surface_end()
	
	mesh.surface_begin(Mesh.PRIMITIVE_LINES, preload("res://Player/WalkzillaEdgeMaterial.tres"))
	mesh.surface_set_color(Color.RED)
	mesh.surface_add_vertex(b)
	mesh.surface_set_color(Color.RED)
	mesh.surface_add_vertex(b - target_position)
	mesh.surface_end()
	
	mesh.surface_begin(Mesh.PRIMITIVE_LINES, preload("res://Player/WalkzillaEdgeMaterial.tres"))
	mesh.surface_set_color(Color.RED)
	mesh.surface_add_vertex(a - target_position)
	mesh.surface_set_color(Color.RED)
	mesh.surface_add_vertex(b - target_position)
	mesh.surface_end()
	pass

func _calcu_edge_recover_point(start : Vector3, end : Vector3) -> float:
	return (Vector2(start.x, start.z).distance_to(Vector2(end.x, end.z))) / grid_gap

const EdgeRecoverIgnorePercentage : float = 0.02
func update_collision(player_position : Vector3) -> void:
	self.global_transform.origin = player_position.snapped(Vector3.ONE * grid_gap)
	self.global_transform.origin.y = player_position.y
	
	for ray_id in ray_count:
		if ray_id < cell_count:
			cells[ray_id] = 0
		var ray := rays[ray_id]
		ray.force_raycast_update()
		var indicator := indicators[ray_id]
		if ray.is_colliding() and not ((ray.get_collider() as StaticBody3D).collision_layer & GlobalData.PhysicsLayerWalkzillaDisabled):
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
		var index_x := indexs[0]
		var index_y := indexs[1]
		var indicator := indicators[ray_id]
		var is_right_edge := false
		var right_far_pos := Vector3.ZERO
		var is_bottom_edge := false
		var bottom_far_pos := Vector3.ZERO
		if is_ray_index_valid(index_x+1, index_y):
			var right_id := compose_ray_id(index_x+1, index_y)
			var right_pos = collision_positions[right_id]
			var right_indicator = indicators[right_id]
			if pos == null and right_pos != null:
				right_far_pos = get_farest_point(right_id, ray_id, right_pos)
				is_right_edge = true
				
				var i := preload("res://Player/WalkzillaIndicator.tscn").instantiate()
				%FarIndicators.add_child(i)
				i.global_transform.origin = right_far_pos
				i.set_shader_instance_uniform("color", Color.DODGER_BLUE)
				
				right_indicator.set_shader_instance_uniform("color", Color.ORANGE_RED)
			if pos != null and right_pos == null:
				right_far_pos = get_farest_point(ray_id, right_id, pos)
				is_right_edge = true
				
				var i := preload("res://Player/WalkzillaIndicator.tscn").instantiate()
				%FarIndicators.add_child(i)
				i.global_transform.origin = right_far_pos
				i.set_shader_instance_uniform("color", Color.DODGER_BLUE)
				
				indicator.set_shader_instance_uniform("color", Color.ORANGE_RED)
		if is_ray_index_valid(index_x, index_y+1):
			var bottom_id := compose_ray_id(index_x, index_y+1)
			var bottom_pos = collision_positions[bottom_id]
			var bottom_indicator = indicators[bottom_id]
			if pos == null and bottom_pos != null:
				bottom_far_pos = get_farest_point(bottom_id, ray_id, bottom_pos)
				is_bottom_edge = true
				
				var i := preload("res://Player/WalkzillaIndicator.tscn").instantiate()
				%FarIndicators.add_child(i)
				i.global_transform.origin = bottom_far_pos
				i.set_shader_instance_uniform("color", Color.DODGER_BLUE)
				
				bottom_indicator.set_shader_instance_uniform("color", Color.ORANGE_RED)
			if pos != null and bottom_pos == null:
				bottom_far_pos = get_farest_point(ray_id, bottom_id, pos)
				is_bottom_edge = true
				
				var i := preload("res://Player/WalkzillaIndicator.tscn").instantiate()
				%FarIndicators.add_child(i)
				i.global_transform.origin = bottom_far_pos
				i.set_shader_instance_uniform("color", Color.DODGER_BLUE)
				
				indicator.set_shader_instance_uniform("color", Color.ORANGE_RED)
	
		if is_cell_index_vaild(index_x, index_y):
#			self
			var cell_id := compose_cell_id(index_x, index_y)
			var topleft_id := compose_ray_id(index_x, index_y)
			var topright_id := compose_ray_id(index_x + 1, index_y)
			var bottomright_id := compose_ray_id(index_x + 1, index_y + 1)
			var bottomleft_id := compose_ray_id(index_x, index_y + 1)
			
			cells[cell_id] |= RayDirection.TopLeft if collision_positions[topleft_id] != null else 0
			cells[cell_id] |= RayDirection.TopRight if collision_positions[topright_id] != null else 0
			cells[cell_id] |= RayDirection.BottomRight if collision_positions[bottomright_id] != null else 0
			cells[cell_id] |= RayDirection.BottomLeft if collision_positions[bottomleft_id] != null else 0
			
			var up_cell_id := compose_cell_id(index_x, index_y-1)
			var left_cell_id := compose_cell_id(index_x-1, index_y)
			if is_right_edge:
				edges[compose_edge_id(cell_id, CellDirection.Up)] = right_far_pos
				if is_cell_id_valid(up_cell_id):
					edges[compose_edge_id(up_cell_id, CellDirection.Down)] = right_far_pos
			if is_bottom_edge:
				edges[compose_edge_id(cell_id, CellDirection.Left)] = bottom_far_pos
				if is_cell_id_valid(left_cell_id):
					edges[compose_edge_id(left_cell_id, CellDirection.Right)] = bottom_far_pos
		elif is_cell_index_vaild(index_x - 1, index_y):
			if is_bottom_edge:
				edges[compose_edge_id(compose_cell_id(index_x - 1, index_y), CellDirection.Right)] = bottom_far_pos
		elif is_cell_index_vaild(index_x, index_y - 1):
			if is_right_edge:
				edges[compose_edge_id(compose_cell_id(index_x, index_y - 1), CellDirection.Down)] = right_far_pos

	clear_edge_mesh()
	# print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
	for cell_id in cell_count:
		var cell := cells[cell_id]
		# printt(cell_id, cell)
		var cell_index := decompose_cell_id(cell_id)
		var up_pos := edges[compose_edge_id(cell_id, CellDirection.Up)]
		var right_pos := edges[compose_edge_id(cell_id, CellDirection.Right)]
		var down_pos := edges[compose_edge_id(cell_id, CellDirection.Down)]
		var left_pos := edges[compose_edge_id(cell_id, CellDirection.Left)]
		
		var top_left = compose_ray_id(cell_index[0], cell_index[1])
		var top_right = compose_ray_id(cell_index[0] + 1, cell_index[1])
		var bottom_left = compose_ray_id(cell_index[0], cell_index[1] + 1)
		var bottom_right = compose_ray_id(cell_index[0] + 1, cell_index[1] + 1)
		
#		match cell:
#			8, 7	: add_edge_mesh(up_pos, left_pos)
#			4, 11	: add_edge_mesh(up_pos, right_pos)
#			2, 13	: add_edge_mesh(down_pos, right_pos)
#			1, 14	: add_edge_mesh(down_pos, left_pos)
#			12, 3	: add_edge_mesh(right_pos, left_pos)
#			6, 9	: add_edge_mesh(up_pos, down_pos)
		
		
		match cell:
			8	:
				var start1_percentage := _calcu_edge_recover_point(collision_positions[top_left], left_pos)
				var start2_percentage := _calcu_edge_recover_point(collision_positions[top_left], up_pos)

				if start1_percentage < EdgeRecoverIgnorePercentage or start2_percentage < EdgeRecoverIgnorePercentage:
					add_edge_mesh(up_pos, left_pos)
				else:
					var start1 := rays[top_left].global_transform.origin.lerp(rays[bottom_left].global_transform.origin, start1_percentage/2)
					var end1 := rays[top_right].global_transform.origin.lerp(rays[bottom_right].global_transform.origin, start1_percentage/2)
					var start2 := rays[top_left].global_transform.origin.lerp(rays[top_right].global_transform.origin, start2_percentage/2)
					var end2 := rays[bottom_left].global_transform.origin.lerp(rays[bottom_right].global_transform.origin, start2_percentage/2)
					
					var far1 := get_farest_position(start1, end1)
					var far2 := get_farest_position(start2, end2)

					if far1.x == INF or far2.x == INF:
						add_edge_mesh(up_pos, left_pos)
					else:
						var collision := Geometry3D.get_closest_points_between_segments(left_pos, left_pos + (far2 - left_pos).normalized(), up_pos, up_pos + (far1 - up_pos).normalized())[0]
						if is_nan(collision.x) or is_nan(collision.y) or is_nan(collision.z):
							add_edge_mesh(up_pos, left_pos)
						else:
							var i := preload("res://Player/WalkzillaIndicator.tscn").instantiate()
							%FarIndicators.add_child(i)
							i.global_transform.origin = collision
							i.set_shader_instance_uniform("color", Color.REBECCA_PURPLE)
							add_edge_mesh(up_pos, collision)
							add_edge_mesh(collision, left_pos)
			7	:
				var start1_percentage := 1 - _calcu_edge_recover_point(collision_positions[bottom_left], left_pos)
				var start2_percentage := 1 - _calcu_edge_recover_point(collision_positions[top_right], up_pos)

				if start1_percentage < EdgeRecoverIgnorePercentage or start2_percentage < EdgeRecoverIgnorePercentage:
					add_edge_mesh(up_pos, left_pos)
				else:
					var start1 := rays[top_left].global_transform.origin.lerp(rays[bottom_left].global_transform.origin, start1_percentage / 2)
					var end1 := rays[top_right].global_transform.origin.lerp(rays[bottom_right].global_transform.origin, start1_percentage / 2)
					var start2 := rays[top_left].global_transform.origin.lerp(rays[top_right].global_transform.origin, start2_percentage / 2)
					var end2 := rays[bottom_left].global_transform.origin.lerp(rays[bottom_right].global_transform.origin, start2_percentage / 2)
					
					var far1 := get_farest_position(end1, start1)
					var far2 := get_farest_position(end2, start2)

					if far1.x == INF or far2.x == INF:
						add_edge_mesh(up_pos, left_pos)
					else:
						var collision := Geometry3D.get_closest_points_between_segments(left_pos, left_pos + (far2 - left_pos).normalized(), up_pos, up_pos + (far1 - up_pos).normalized())[0]
						if is_nan(collision.x) or is_nan(collision.y) or is_nan(collision.z):
							add_edge_mesh(up_pos, left_pos)
						else:
							var i := preload("res://Player/WalkzillaIndicator.tscn").instantiate()
							%FarIndicators.add_child(i)
							i.global_transform.origin = collision
							i.set_shader_instance_uniform("color", Color.REBECCA_PURPLE)
							add_edge_mesh(up_pos, collision)
							add_edge_mesh(collision, left_pos)
			4	:
				var start1_percentage := _calcu_edge_recover_point(collision_positions[top_right], right_pos)
				var start2_percentage := _calcu_edge_recover_point(collision_positions[top_right], up_pos)
				if start1_percentage < EdgeRecoverIgnorePercentage or start2_percentage < EdgeRecoverIgnorePercentage:
					add_edge_mesh(up_pos, right_pos)
				else:
					var start1 := rays[top_right].global_transform.origin.lerp(rays[bottom_right].global_transform.origin, start1_percentage/2)
					var end1 := rays[top_left].global_transform.origin.lerp(rays[bottom_left].global_transform.origin, start1_percentage/2)
					var start2 := rays[top_right].global_transform.origin.lerp(rays[top_left].global_transform.origin, start2_percentage/2)
					var end2 := rays[bottom_right].global_transform.origin.lerp(rays[bottom_left].global_transform.origin, start2_percentage/2)
					
					var far1 := get_farest_position(start1, end1)
					var far2 := get_farest_position(start2, end2)

					if far1.x == INF or far2.x == INF:
						add_edge_mesh(up_pos, right_pos)
						break
					else:
						var collision := Geometry3D.get_closest_points_between_segments(right_pos, right_pos + (far2 - right_pos).normalized(), up_pos, up_pos + (far1 - up_pos).normalized())[0]
						if is_nan(collision.x) or is_nan(collision.y) or is_nan(collision.z):
							add_edge_mesh(up_pos, right_pos)
						else:
							var i := preload("res://Player/WalkzillaIndicator.tscn").instantiate()
							%FarIndicators.add_child(i)
							i.global_transform.origin = collision
							i.set_shader_instance_uniform("color", Color.REBECCA_PURPLE)
							add_edge_mesh(up_pos, collision)
							add_edge_mesh(collision, right_pos)
			11	:
				var start1_percentage := 1 - _calcu_edge_recover_point(collision_positions[bottom_right], right_pos)
				var start2_percentage := 1 - _calcu_edge_recover_point(collision_positions[top_left], up_pos)

				if start1_percentage < EdgeRecoverIgnorePercentage or start2_percentage < EdgeRecoverIgnorePercentage:
					add_edge_mesh(up_pos, right_pos)
				else:
					var start1 := rays[top_right].global_transform.origin.lerp(rays[bottom_right].global_transform.origin, start1_percentage / 2)
					var end1 := rays[top_left].global_transform.origin.lerp(rays[bottom_left].global_transform.origin, start1_percentage / 2)
					var start2 := rays[top_right].global_transform.origin.lerp(rays[top_left].global_transform.origin, start2_percentage / 2)
					var end2 := rays[bottom_right].global_transform.origin.lerp(rays[bottom_left].global_transform.origin, start2_percentage / 2)
					
					var far1 := get_farest_position(end1, start1)
					var far2 := get_farest_position(end2, start2)

					if far1.x == INF or far2.x == INF:
						add_edge_mesh(up_pos, right_pos)
					else:
						var collision := Geometry3D.get_closest_points_between_segments(right_pos, right_pos + (far2 - right_pos).normalized(), up_pos, up_pos + (far1 - up_pos).normalized())[0]
						if is_nan(collision.x) or is_nan(collision.y) or is_nan(collision.z):
							add_edge_mesh(up_pos, right_pos)
						else:
							var i := preload("res://Player/WalkzillaIndicator.tscn").instantiate()
							%FarIndicators.add_child(i)
							i.global_transform.origin = collision
							i.set_shader_instance_uniform("color", Color.REBECCA_PURPLE)
							add_edge_mesh(up_pos, collision)
							add_edge_mesh(collision, right_pos)
			2	: 
				var start1_percentage := _calcu_edge_recover_point(collision_positions[bottom_right], right_pos)
				var start2_percentage := _calcu_edge_recover_point(collision_positions[bottom_right], down_pos)

				if start1_percentage < EdgeRecoverIgnorePercentage or start2_percentage < EdgeRecoverIgnorePercentage:
					add_edge_mesh(down_pos, right_pos)
				else:
					var start1 := rays[bottom_right].global_transform.origin.lerp(rays[top_right].global_transform.origin, start1_percentage / 2.0)
					var end1 := rays[bottom_left].global_transform.origin.lerp(rays[top_left].global_transform.origin, start1_percentage / 2.0)
					var start2 := rays[bottom_right].global_transform.origin.lerp(rays[bottom_left].global_transform.origin, start2_percentage / 2.0)
					var end2 := rays[top_right].global_transform.origin.lerp(rays[top_left].global_transform.origin, start2_percentage / 2.0)
					
					var far1 := get_farest_position(start1, end1)
					var far2 := get_farest_position(start2, end2)

					if far1.x == INF or far2.x == INF:
						add_edge_mesh(down_pos, right_pos)
					else:
						var collision := Geometry3D.get_closest_points_between_segments(right_pos, right_pos + (far2 - right_pos).normalized(), down_pos, down_pos + (far1 - down_pos).normalized())[0]
						if is_nan(collision.x) or is_nan(collision.y) or is_nan(collision.z):
							add_edge_mesh(down_pos, right_pos)
						else:
							var i := preload("res://Player/WalkzillaIndicator.tscn").instantiate()
							%FarIndicators.add_child(i)
							i.global_transform.origin = collision
							i.set_shader_instance_uniform("color", Color.REBECCA_PURPLE)
							add_edge_mesh(down_pos, collision)
							add_edge_mesh(collision, right_pos)
			13	: 
				var start1_percentage := 1 - _calcu_edge_recover_point(collision_positions[top_right], right_pos)
				var start2_percentage := 1 - _calcu_edge_recover_point(collision_positions[bottom_left], down_pos)

				if start1_percentage < EdgeRecoverIgnorePercentage or start2_percentage < EdgeRecoverIgnorePercentage:
					add_edge_mesh(down_pos, right_pos)
				else:
					var start1 := rays[bottom_right].global_transform.origin.lerp(rays[top_right].global_transform.origin, start1_percentage / 2.0)
					var end1 := rays[bottom_left].global_transform.origin.lerp(rays[top_left].global_transform.origin, start1_percentage / 2.0)
					var start2 := rays[bottom_right].global_transform.origin.lerp(rays[bottom_left].global_transform.origin, start2_percentage / 2.0)
					var end2 := rays[top_right].global_transform.origin.lerp(rays[top_left].global_transform.origin, start2_percentage / 2.0)
					
					var far1 := get_farest_position(end1, start1)
					var far2 := get_farest_position(end2, start2)

					if far1.x == INF or far2.x == INF:
						add_edge_mesh(down_pos, right_pos)
					else:
						var collision := Geometry3D.get_closest_points_between_segments(right_pos, right_pos + (far2 - right_pos).normalized(), down_pos, down_pos + (far1 - down_pos).normalized())[0]
						if is_nan(collision.x) or is_nan(collision.y) or is_nan(collision.z):
							add_edge_mesh(down_pos, right_pos)
						else:
							var i := preload("res://Player/WalkzillaIndicator.tscn").instantiate()
							%FarIndicators.add_child(i)
							i.global_transform.origin = collision
							i.set_shader_instance_uniform("color", Color.REBECCA_PURPLE)
							add_edge_mesh(down_pos, collision)
							add_edge_mesh(collision, right_pos)
			1	: 
				var start1_percentage := _calcu_edge_recover_point(collision_positions[bottom_left], left_pos)
				var start2_percentage := _calcu_edge_recover_point(collision_positions[bottom_left], down_pos)

				if start1_percentage < EdgeRecoverIgnorePercentage or start2_percentage < EdgeRecoverIgnorePercentage:
					add_edge_mesh(down_pos, left_pos)
				else:
					var start1 := rays[bottom_left].global_transform.origin.lerp(rays[top_left].global_transform.origin, start1_percentage / 2.0)
					var end1 := rays[bottom_right].global_transform.origin.lerp(rays[top_right].global_transform.origin, start1_percentage / 2.0)
					var start2 := rays[bottom_left].global_transform.origin.lerp(rays[bottom_right].global_transform.origin, start2_percentage / 2.0)
					var end2 := rays[top_left].global_transform.origin.lerp(rays[top_right].global_transform.origin, start2_percentage / 2.0)
					
					var far1 := get_farest_position(start1, end1)
					var far2 := get_farest_position(start2, end2)

					if far1.x == INF or far2.x == INF:
						add_edge_mesh(down_pos, left_pos)
					else:
						var collision := Geometry3D.get_closest_points_between_segments(left_pos, left_pos + (far2 - left_pos).normalized(), down_pos, down_pos + (far1 - down_pos).normalized())[0]
						if is_nan(collision.x) or is_nan(collision.y) or is_nan(collision.z):
							add_edge_mesh(down_pos, left_pos)
						else:
							var i := preload("res://Player/WalkzillaIndicator.tscn").instantiate()
							%FarIndicators.add_child(i)
							i.global_transform.origin = collision
							i.set_shader_instance_uniform("color", Color.REBECCA_PURPLE)
							add_edge_mesh(down_pos, collision)
							add_edge_mesh(collision, left_pos)
			14	: 
				var start1_percentage := 1 - _calcu_edge_recover_point(collision_positions[top_left], left_pos)
				var start2_percentage := 1 - _calcu_edge_recover_point(collision_positions[bottom_right], down_pos)
				if start1_percentage < EdgeRecoverIgnorePercentage or start2_percentage < EdgeRecoverIgnorePercentage:
					add_edge_mesh(down_pos, left_pos)
				else:
					var start1 := rays[bottom_left].global_transform.origin.lerp(rays[top_left].global_transform.origin, start1_percentage / 2)
					var end1 := rays[bottom_right].global_transform.origin.lerp(rays[top_right].global_transform.origin, start1_percentage / 2)
					var start2 := rays[bottom_left].global_transform.origin.lerp(rays[bottom_right].global_transform.origin, start2_percentage / 2)
					var end2 := rays[top_left].global_transform.origin.lerp(rays[top_right].global_transform.origin, start2_percentage / 2)
					
					var far1 := get_farest_position(end1, start1)
					var far2 := get_farest_position(end2, start2)
					
					if far1.x == INF or far2.x == INF:
						add_edge_mesh(down_pos, left_pos)
					else:
						var collision := Geometry3D.get_closest_points_between_segments(left_pos, left_pos + (far2 - left_pos).normalized(), down_pos, down_pos + (far1 - down_pos).normalized())[0]
						if is_nan(collision.x) or is_nan(collision.y) or is_nan(collision.z):
							add_edge_mesh(down_pos, left_pos)
						else:
							var i := preload("res://Player/WalkzillaIndicator.tscn").instantiate()
							%FarIndicators.add_child(i)
							i.global_transform.origin = collision
							i.set_shader_instance_uniform("color", Color.REBECCA_PURPLE)
							add_edge_mesh(down_pos, collision)
							add_edge_mesh(collision, left_pos)

			12, 3	: add_edge_mesh(right_pos, left_pos)
			6, 9	: add_edge_mesh(up_pos, down_pos)
	pass
