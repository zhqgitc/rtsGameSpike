class_name SelectionBoxOverlay
extends Control
## Draws the rubber-band rectangle while the player drags a selection box.

var _rect := Rect2()
var _active := false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_rect(rect: Rect2) -> void:
	_rect = rect
	_active = true
	queue_redraw()


func hide_rect() -> void:
	_active = false
	queue_redraw()


func _draw() -> void:
	if not _active:
		return
	draw_rect(_rect, Color(0.3, 1.0, 0.3, 0.15), true)
	draw_rect(_rect, Color(0.3, 1.0, 0.3, 0.9), false, 1.5)
