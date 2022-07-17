class_name ColorMatch
extends PuzzleRule

var color_id : int = 0
var count : int = 2
var is_host : bool = false

func _init(data) -> void:
	self.color_id = data.color_id
	self.is_host = data.host if data.has("host") else false
	if self.is_host:
		self.count = data.count
	self.rule_type = 3
	self.handle_type = 1
	pass

static func check_grouped_rule(puzzle_data : PuzzleData, line_data, grouped_rules : Array[PuzzleRule], isolated_area : Array) -> Array:
	var ans : Array[PuzzleRule] = []
	var counts : Dictionary = {}
	for rule in grouped_rules:
		if counts.has(rule.color_id):
			counts[rule.color_id] += 1
		else:
			counts[rule.color_id] = 1
#	print(counts)
	for rule in grouped_rules:
		if not rule.is_host: continue
		if not (counts[rule.color_id] == rule.count):
			ans.append(rule)
#	if counts.size() > 1:
#		var keys : Array[int] = counts.keys()
#		keys.sort_custom(func (a : int, b : int) -> bool:
#			var _ans : bool = counts[a].size() < counts[b].size()
#			if counts[a].size() == counts[b].size():
#				return a > b
#			return _ans
#		)
#		print(keys)
#		for key in keys.slice(0, -1):
#			ans.append_array(counts[key])
	return ans
