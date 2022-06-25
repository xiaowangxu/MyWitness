class_name TextureRoundedShapeResource
extends TextureShapeResource

var round_cornor: float = 0.0

func _init(points: PackedVector2Array, round_cornor: float = 0.0, uv: bool = false) -> void:
	self.round_cornor = round_cornor
	super(calcu_points(points), uv)

func calcu_points(points: PackedVector2Array) -> PackedVector2Array:
	if round_cornor == 0.0:
		return points
	else:
		return Geometry2D.offset_polygon(points, round_cornor, Geometry2D.JOIN_ROUND)[0]
