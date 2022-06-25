class_name TextureShapeResource
extends Resource

var points : PackedVector2Array = [] :
	get: return points
var uv : PackedVector2Array = [] :
	get: return uv
var bound : Rect2 = Rect2()

func _init(points : PackedVector2Array, uv : bool = false) -> void:
	self.points = points
	if uv:
		calcu_bound()
		calcu_uv()

func calcu_bound() -> void:
	bound = Rect2(points[0], Vector2.ZERO)
	for i in range(1, points.size()):
		bound = bound.expand(points[i])

func calcu_uv() -> void:
	uv.resize(points.size())
	var left := bound.position.x
	var top := bound.position.y
	var width := bound.size.x
	var height := bound.size.y
	for i in range(points.size()):
		var pos := points[i]
		uv[i] = Vector2((pos.x - left)/width, (pos.y - top)/height)
