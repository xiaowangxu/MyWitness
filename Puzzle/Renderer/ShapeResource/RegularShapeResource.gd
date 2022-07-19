class_name RegularShapeResource
extends ShapeResource

var radius : float = 10.0 :
	get: return radius
var edge_count : int = 3 :
	get: return edge_count
var round_cornor : float = 0.0 :
	get: return round_cornor

func _init(edge_count : int = 3, radius : float = 10.0, round_cornor : float = 0.0, uv : bool = false) -> void:
	self.edge_count = edge_count
	self.radius = radius
	self.round_cornor = round_cornor
	super(calcu_points(), uv)

func calcu_points() -> PackedVector2Array:
	var p : PackedVector2Array = []
	for i in range(edge_count):
		var rad : float = TAU * (i / float(edge_count))
		p.append(Vector2.from_angle(rad) * radius)
	if round_cornor == 0.0:
		return p
	else:
		return Geometry2D.offset_polygon(p, round_cornor, Geometry2D.JOIN_ROUND)[0]
