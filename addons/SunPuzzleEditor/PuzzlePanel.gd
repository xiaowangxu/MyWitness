@tool
extends Node2D

signal mouse_move(position : Vector2)

var file : PuzzleData = PuzzleData.new()
var snap : bool = true

var vertice_helper := preload("res://addons/SunPuzzleEditor/VerticeHelper.tscn")

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		input(event)
	if event is InputEventMouseButton and ((event as InputEventMouse).button_mask & MOUSE_BUTTON_LEFT):
		var hovered_helper := is_hover_helper()
		if hovered_helper:
			pass
		else:
			add_vertice()
	pass

func input(event: InputEvent) -> void:
	%Cursor.global_position = event.position
	if %Cursor.position.x < 0: %Cursor.position.x = 0
	if %Cursor.position.x > $ColorRect.minimum_size.x: %Cursor.position.x = $ColorRect.minimum_size.x
	if %Cursor.position.y < 0: %Cursor.position.y = 0
	if %Cursor.position.y > $ColorRect.minimum_size.y: %Cursor.position.y = $ColorRect.minimum_size.y
	if snap:
		%Cursor.position = $Grid.snap_grid(%Cursor.position)
	mouse_move.emit(%Cursor.position)
	

func is_hover_helper() -> Area2D:
	print($Helpers.get_children())
	for c in $Helpers.get_children():
		print(c.is_hovered)
		if c.is_hovered: return c
	return null

func add_vertice(pos : Vector2 = $Cursor.position) -> void:
	var point := vertice_helper.instantiate()
	point.position = pos
	$Helpers.add_child(point)
