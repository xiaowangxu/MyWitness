@tool
extends ColorRect

@export_dir var file_path : String
@export var file_name : String = "Puzzle"

@export var Generate : bool = false :
	set(val):
		generate()

func get_point(position : Vector2, type : int = 3) -> Dictionary:
	return {
		"position": [position.x,position.y],
		"type": type
	}

func get_edge(from : int, to : int) -> Dictionary:
	return {
		"from": from,
		"to": to
	}

func generate() -> void:
	var line : Line2D = get_node("Line2D")
	if line == null: return
	var json_obj : Dictionary = {
		"board": {
			"base_size": [size.x, size.y],
			"background_color": [color.r, color.g, color.b, color.a],
			"background_line_color": [0.1,0.1,0.1,1.0],
			"start_radius": 60.0,
			"normal_radius": 22.0,
			"line_drawing_color": [0.8,0.1,0.8,1.0],
			"line_correct_color": [0.9,0.0,0.8,1.0],
		},
		"decorators": [],
		"points": [],
		"edges": [],
		"areas": [],
	}
	var idx : int = 0
	var length := line.points.size()
	for point in line.points:
		var point_type : int = 0
		if idx == 0: point_type = 0
		elif idx == length-1: point_type = 1
		else: point_type = 3
		var point_item := get_point(point, point_type)
		json_obj.points.append(point_item)
		if idx > 0:
			var edge_item := get_edge(idx-1, idx)
			json_obj.edges.append(edge_item)
		idx += 1
	var file := File.new()
	var path := file_path + "/" + file_name + ".json"
	if file.file_exists(path):
		return
	var json_str := JSON.new().stringify(json_obj, "\t")
	if file.open(path, File.WRITE) == OK:
		file.store_string(json_str)
		file.close()
		print("!!! generation finished")
	pass
