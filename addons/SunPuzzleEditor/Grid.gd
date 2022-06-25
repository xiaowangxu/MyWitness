@tool
extends Node2D

var sizew : int = 800 :
	set(val):
		sizew = val
		update()
var sizeh : int = 800 :
	set(val):
		sizeh = val
		update()
var hcount : int = 10 :
	set(val):
		val = clampf(val, 1, 400)
		hcount = val
		update()
var vcount : int = 10 :
	set(val):
		val = clampf(val, 1, 400)
		vcount = val
		update()
var tbmargin : float = 40 :
	set(val):
		val = clampf(val, 0, 400)
		tbmargin = val
		update()
var lrmargin : float = 40 :
	set(val):
		val = clampf(val, 0, 400)
		lrmargin = val
		update()

func _draw() -> void:
	var w := sizew - lrmargin*2.0
	var h := sizeh - tbmargin*2.0
	var hspace := w / float(hcount)
	var vspace := h / float(vcount)
	for i in range(0, vcount + 1):
		draw_dashed_line(Vector2(lrmargin, tbmargin+i*vspace), Vector2(sizew-lrmargin, tbmargin+i*vspace), Color.BLACK, 1.0, 4.0)
	for i in range(0, hcount + 1):
		draw_dashed_line(Vector2(lrmargin+i*hspace, tbmargin), Vector2(lrmargin+i*hspace, sizeh-tbmargin), Color.BLACK, 1.0, 4.0)
	if tbmargin != 0.0:
		draw_line(Vector2(lrmargin, tbmargin), Vector2(sizew-lrmargin, tbmargin), Color.BLACK, 1.0)
		draw_line(Vector2(lrmargin, sizeh-tbmargin), Vector2(sizeh-lrmargin, sizew - tbmargin), Color.BLACK, 1.0)
	if lrmargin != 0.0:
		draw_line(Vector2(lrmargin, tbmargin), Vector2(lrmargin, sizeh-tbmargin), Color.BLACK, 1.0)
		draw_line(Vector2(sizew-lrmargin, tbmargin), Vector2(sizew-lrmargin, sizeh-tbmargin), Color.BLACK, 1.0)

func snap_grid(pos : Vector2) -> Vector2:
	if pos.x < lrmargin: pos.x = lrmargin
	if pos.x > sizew-lrmargin: pos.x = sizew-lrmargin
	if pos.y < tbmargin: pos.y = tbmargin
	if pos.y > sizeh-tbmargin: pos.y = sizeh-tbmargin
	var w := sizew - lrmargin*2.0
	var h := sizeh - tbmargin*2.0
	var hspace := w / float(hcount)
	var vspace := h / float(vcount)
	pos = (pos - Vector2(lrmargin, tbmargin)).snapped(Vector2(hspace, vspace)) + Vector2(lrmargin, tbmargin)
	return pos
