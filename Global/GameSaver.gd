extends Node

var game_save_data : GameSaveDataResource
var cover_texture : ImageTexture
#var dirty : bool = false

func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if ResourceLoader.exists("user://GameSave.res"):
		game_save_data = ResourceLoader.load("user://GameSave.res")
		print(">>>> load")
		print(game_save_data.get_saved_time())
		cover_texture = ImageTexture.new()
		cover_texture.create_from_image(game_save_data.cover_image)
	else:
		game_save_data = GameSaveDataResource.new()
		print(">>>> init")

var viewport : SubViewport
var camera : Camera3D
func _ready() -> void:
	viewport = SubViewport.new()
	viewport.msaa = Viewport.MSAA_4X
	viewport.size = Vector2(960, 540)
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(viewport)
	camera = Camera3D.new()
	viewport.add_child(camera)
	camera.make_current()
	camera.cull_mask = 0b11111111111111110111

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		save_game_save_data_resource()

func save_player(position : Vector3, lookat_x : float, lookat_y : float) -> void:
	game_save_data.save_player(position, lookat_x, lookat_y)
	pass

func get_player_position() -> Vector3:
	return game_save_data.player_position

func get_player_lookat() -> Vector2:
	return game_save_data.player_lookat

func save_puzzle(tag : String, data : Dictionary) -> void:
	game_save_data.save_puzzle(tag, data)
	pass

func clear_puzzle(tag : String) -> void:
	game_save_data.clear_puzzle(tag)
	pass

func get_puzzle(tag : String):
	return game_save_data.get_puzzle(tag)

func save_interactable(tag : String, data : Dictionary) -> void:
	game_save_data.save_interactable(tag, data)
	pass

func clear_interactable(tag : String) -> void:
	game_save_data.clear_interactable(tag)
	pass

func get_interactable(tag : String):
	return game_save_data.get_interactable(tag)

func get_cover_image() -> Image:
	return game_save_data.get_cover_image()

func save_game_save_data_resource() -> void:
#	if not dirty: return
	print(">>>> save")
	var start_time := Time.get_ticks_msec()
	var player : Player = GlobalData.get_player()
	player.save()
	var _camera := get_viewport().get_camera_3d()
	camera.global_transform = _camera.global_transform
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	await RenderingServer.frame_post_draw
	var texture := viewport.get_texture()
	var image := texture.get_image()
	game_save_data.set_cover_image(image)
	var ans := ResourceSaver.save("user://GameSave.res", game_save_data)
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	print("Game Saved ! in : ", Time.get_ticks_msec() - start_time, "ms")
#	dirty = false
