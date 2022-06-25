class_name JsonResourceLoader
extends ResourceFormatLoader

func _get_recognized_extensions() -> PackedStringArray:
	return PackedStringArray(["json"])

func _handles_type(type: StringName) -> bool:
	return type == "Resource"

func _get_resource_type(path: String) -> String:
	var el := path.get_extension().to_lower()
	if el == "json":
		return "Resource"
	return ""

func _load(path: String, original_path: String, use_sub_threads: bool, cache_mode: int):
#	printt(path, original_path, use_sub_threads, cache_mode)
	var file_loader := File.new()
	var err := file_loader.open(path, File.READ)
	if err == OK:
		var string := file_loader.get_as_text()
		var json_parser := JSON.new()
		var json_err := json_parser.parse(string)
		if json_err == OK:
			var res = json_parser.get_data()
			return JsonResource.new(res)
		else:
			return json_err
	else:
		return err
