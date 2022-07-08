extends Node

static func print_tag(title : String, info : String, color : Color = Color.WHITE) -> void:
	print_rich('[b][color=#%s] %s [/color][/b] [color=white][bgcolor=#333333] %s [/bgcolor][/color]' % [color.to_html(false),title, info])
	pass
