class_name GameSaveDataResource
extends Resource

@export var saved_time : String = ""
@export var player_position : Vector3 = Vector3(10,0,10)
@export var player_lookat : Vector2
@export var puzzles_ans : Dictionary
@export var interactable : Dictionary

func save_player(position : Vector3, lookat_x : float, lookat_y : float) -> void:
	player_position = position
	player_lookat = Vector2(lookat_x, lookat_y)
	update_saved_time()
	pass

func save_puzzle(tag : String, data : Dictionary) -> void:
	puzzles_ans[tag] = data
	update_saved_time()
	pass

func clear_puzzle(tag : String) -> void:
	if puzzles_ans.has(tag):
		puzzles_ans.erase(tag)
		update_saved_time()
	pass

func get_puzzle(tag : String):
	return puzzles_ans[tag] if puzzles_ans.has(tag) else null

func save_interactable(tag : String, data : Dictionary) -> void:
	interactable[tag] = data
	update_saved_time()
	pass

func clear_interactable(tag : String) -> void:
	if interactable.has(tag):
		interactable.erase(tag)
		update_saved_time()
	pass

func get_interactable(tag : String):
	return interactable[tag] if interactable.has(tag) else null

func update_saved_time() -> void:
	saved_time = Time.get_datetime_string_from_system(false, true)

func get_saved_time(unknown_ans : String = "unknown_datetime") -> String:
	return unknown_ans if saved_time == "" else saved_time

func get_summary() -> Dictionary:
	return {
		"time":saved_time,
		"answered": puzzles_ans.size()
	}
