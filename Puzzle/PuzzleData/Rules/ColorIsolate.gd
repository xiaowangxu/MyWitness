class_name ColorIsolate
extends PuzzleRule

var color_id : int = 0

func _init(data) -> void:
	self.color_id = data
	self.rule_type = 2
	self.handle_type = 1
	pass

static func check_grouped_rule(puzzle_data : PuzzleData, line_data, grouped_rules : Array[PuzzleRule], isolated_area : Array) -> Array:
	var ans : Array[PuzzleRule] = []
	var counts : Dictionary = {}
	for rule in grouped_rules:
		if counts.has(rule.color_id):
			counts[rule.color_id].append(rule)
		else:
			counts[rule.color_id] = [rule]
#	print(counts)
	if counts.size() > 1:
		var keys : Array[int] = counts.keys()
		keys.sort_custom(func (a : int, b : int) -> bool:
			var _ans : bool = counts[a].size() < counts[b].size()
			if counts[a].size() == counts[b].size():
				return a > b
			return _ans
		)
#		print(keys)
		for key in keys.slice(0, -1):
			ans.append_array(counts[key])
	return ans
