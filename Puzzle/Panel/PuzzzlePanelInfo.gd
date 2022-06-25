extends Control

var puzzle_name : String = "unknown" :
	set(val):
		puzzle_name = val
		%Name.text = "PN: %s" % val

var puzzle_movement : Vector2 = Vector2.ZERO :
	set(val):
		puzzle_movement = val
		%Movement.text = "MO: (%f,%f)" % [val.x, val.y]
#		%Arrow.rotation = val.angle()

func _process(delta: float) -> void:
	%Painting.rotate(0.05)
