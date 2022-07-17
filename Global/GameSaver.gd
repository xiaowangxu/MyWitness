extends Node

const ConfigPath := "user://GameSaveDataConfig.tres"

var game_save_data : GameSaveDataResource
var game_save_data_config : GameSaveDataConfigResource

func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if ResourceLoader.exists(ConfigPath):
		game_save_data_config = ResourceLoader.load(ConfigPath)
	else:
		game_save_data_config = GameSaveDataConfigResource.new()
		ResourceSaver.save(ConfigPath, game_save_data_config)
	print(">>>> load ", game_save_data_config)
	game_save_data_config.load_all_summarys()
	load_game_save()

func get_all_summarys() -> Array:
	return game_save_data_config.summary_map.values()

func load_game_save(key : String = "", force : bool = false) -> void:
	if force and key == game_save_data_config.current_key:
		restart_current_game_save()
	else:
		var current_game_save_data := game_save_data
		var new_game_save_data := game_save_data_config.load_game_save_data(key, true)
		if current_game_save_data != null:
			await save_game_save_data_resource(current_game_save_data)
		game_save_data = new_game_save_data
		if game_save_data == null:
			game_save_data = GameSaveDataResource.new()
		if key != "":
			get_tree().reload_current_scene()

func start_new_game_save() -> void:
	var current_game_save_data := game_save_data
	var new_game_save_data := game_save_data_config.load_game_save_data("", true)
	if current_game_save_data != null:
		await save_game_save_data_resource(current_game_save_data)
	game_save_data = new_game_save_data
	game_save_data_config.restart_game_save_data()
	get_tree().reload_current_scene()

func restart_current_game_save() -> void:
	var current_game_save_data := game_save_data
	var new_game_save_data := game_save_data_config.load_game_save_data("", true)
	if current_game_save_data != null:
		await save_game_save_data_resource(current_game_save_data)
	game_save_data = new_game_save_data
	game_save_data_config.restart_game_save_data()
	get_tree().reload_current_scene()

var viewport : SubViewport
var camera : Camera3D
func _ready() -> void:
	viewport = SubViewport.new()
	viewport.msaa = Viewport.MSAA_4X
	viewport.size = Vector2(1024, 576)
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(viewport)
	camera = Camera3D.new()
	viewport.add_child(camera)
	camera.make_current()
	camera.cull_mask = 0b11111111111111110111

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

func save_game_save_data_resource(new_save_data: GameSaveDataResource = null) -> void:
#	if not dirty: return
	var _game_save_data := new_save_data
	if new_save_data == null:
		_game_save_data = game_save_data
	var start_time := Time.get_ticks_msec()
	var player : Player = GlobalData.get_player()
	player.save()
	var _camera := get_viewport().get_camera_3d()
	camera.fov = _camera.fov
	camera.global_transform = _camera.global_transform
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	await RenderingServer.frame_post_draw
	var texture := viewport.get_texture()
	var image := texture.get_image()
#	game_save_data.set_cover_image(image)
	game_save_data_config.save_game_data(_game_save_data, image, ConfigPath)
#	var ans := ResourceSaver.save(game_save_data_config.get_file_path("GameSave"), game_save_data)
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	Debugger.print_tag('Save Game', 'in %d ms' % [ Time.get_ticks_msec() - start_time])

func clear_game_save_data_resource() -> void:
	var dir := Directory.new()
	dir.open("user://")
	var err := dir.remove("user://GameSave.res")
	print(err)
	get_tree().quit()
