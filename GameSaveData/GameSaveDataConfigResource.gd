class_name GameSaveDataConfigResource
extends Resource

const FileFolderPath := "user://gamesavedata/file"
const SummaryFolderPath := "user://gamesavedata/summary"
	
@export var current_key : String = ""
@export var all_file_keys : PackedStringArray = []

var save_to_new_file : bool = false
var summary_map : Dictionary = {}

func _add_summary_pair(key : String, summary) -> void:
	summary_map[key] = summary

func load_all_summarys() -> void:
	for key in all_file_keys:
		var summary_path := get_summary_path(key)
		if ResourceLoader.exists(summary_path):
			var summary = ResourceLoader.load(summary_path)
			_add_summary_pair(key, summary)

func get_file_path(key : String) -> String:
	return FileFolderPath+"/"+key+".res"

func get_summary_path(key : String) -> String:
	return SummaryFolderPath+"/"+key+".res"

func _to_string() -> String:
	return '[GameSaveDataConfig current:%s]' % [self.current_key]

func restart_game_save_data() -> void:
	save_to_new_file = true

func load_game_save_data(target : String = "", no_save_as_new : bool = false) -> GameSaveDataResource:
	if target == "": target = current_key
	if not all_file_keys.has(target):
		var game_save_data = GameSaveDataResource.new()
		save_to_new_file = true
		return game_save_data
	if target == current_key:
		var file_path := get_file_path(current_key)
		if ResourceLoader.exists(file_path):
			Debugger.print_tag("Load Current", current_key)
			return ResourceLoader.load(file_path, "", 0)
	else:
		current_key = target
		save_to_new_file = not no_save_as_new
		var file_path := get_file_path(current_key)
		if ResourceLoader.exists(file_path):
			Debugger.print_tag("Load Target", current_key)
			return ResourceLoader.load(file_path, "", 0).duplicate()
#	fail to load
	var game_save_data = GameSaveDataResource.new()
	save_to_new_file = true
	return game_save_data

func save_game_data(game_save_data : GameSaveDataResource, image : Image, config_path : String) -> void:
	if current_key == "": save_to_new_file = true
#	year、month、day、weekday、hour、minute、second
	var current_time := Time.get_datetime_dict_from_system()
	current_time.idx = 0
	var new_key := "{year}_{month}_{day}_{hour}_{minute}_{second}_{idx}".format(current_time)
	while all_file_keys.has(new_key):
		current_time.idx += 1
		new_key = "{year}_{month}_{day}_{hour}_{minute}_{second}_{idx}".format(current_time)
#	Debugger.print_tag("New Tag", new_key)
	if save_to_new_file:
		all_file_keys.append(new_key)
		current_key = new_key
		var file_path := get_file_path(new_key)
		var summary_path := get_summary_path(new_key)
		var summary := GameSaveDataSummary.new()
		summary.init(current_key, game_save_data.get_summary(), image)
		_add_summary_pair(new_key, summary)
		ResourceSaver.save(game_save_data, file_path)
		ResourceSaver.save(summary, summary_path)
		ResourceSaver.save(self, config_path)
		Debugger.print_tag("Save New", file_path)
	else:
		var file_path := get_file_path(current_key)
		var summary_path := get_summary_path(current_key)
		var summary := GameSaveDataSummary.new()
		summary.init(current_key, game_save_data.get_summary(), image)
		_add_summary_pair(current_key, summary)
		ResourceSaver.save(game_save_data, file_path)
		ResourceSaver.save(summary, summary_path)
		ResourceSaver.save(self, config_path)
		Debugger.print_tag("Save Current", file_path)
