class_name GroupShapeResource
extends ShapeBaseResource

var shapes : Array[ShapeResource]
var transforms : Array[Transform2D]

func _init(shapes : Array, transforms : Array) -> void:
	self.shapes = shapes
	self.transforms = transforms
	pass

func draw(rid : RID) -> void:
	var transform_size := transforms.size()
	for i in range(shapes.size()):
		var shape := shapes[i]
		var transform := transforms[i] if i < transform_size else Transform2D()
		var sub_rid := RenderingServer.canvas_item_create()
		RenderingServer.canvas_item_set_transform(sub_rid, transform)
		RenderingServer.canvas_item_set_parent(sub_rid, rid)
		shape.draw(sub_rid)
	pass
