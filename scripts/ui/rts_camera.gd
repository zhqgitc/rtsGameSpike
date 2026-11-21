class_name RTSCamera
extends Node3D
## Fixed-angle RTS camera: pan with WASD/arrows or screen edges, zoom with mouse wheel.

@export var pan_speed: float = 1.0 ## Pan speed per second, scaled by zoom distance.
@export var edge_scroll_margin: int = 12
@export var edge_scroll_enabled: bool = true
@export var pitch_degrees: float = 55.0
@export var zoom_min: float = 12.0
@export var zoom_max: float = 70.0
@export var zoom_step: float = 4.0
@export var bounds: Vector2 = Vector2(60, 60) ## Max |x| and |z| of the focus point.

var _zoom: float = 40.0

@onready var _camera: Camera3D = $Camera3D


func _ready() -> void:
	_apply_zoom()


func _process(delta: float) -> void:
	var dir := _read_pan_direction()
	if dir != Vector2.ZERO:
		var step := pan_speed * _zoom * delta
		position.x = clampf(position.x + dir.x * step, -bounds.x, bounds.x)
		position.z = clampf(position.z + dir.y * step, -bounds.y, bounds.y)


## Jump the view to centre on a ground point.
func focus_on(point: Vector3) -> void:
	position.x = clampf(point.x, -bounds.x, bounds.x)
	position.z = clampf(point.z, -bounds.y, bounds.y)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_set_zoom(_zoom - zoom_step)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_set_zoom(_zoom + zoom_step)


func _read_pan_direction() -> Vector2:
	var dir := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		dir.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		dir.x += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		dir.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		dir.y += 1.0
	if edge_scroll_enabled and DisplayServer.window_is_focused():
		var vp := get_viewport()
		var mouse := vp.get_mouse_position()
		var size := vp.get_visible_rect().size
		if Rect2(Vector2.ZERO, size).has_point(mouse):
			if mouse.x < edge_scroll_margin:
				dir.x -= 1.0
			elif mouse.x > size.x - edge_scroll_margin:
				dir.x += 1.0
			if mouse.y < edge_scroll_margin:
				dir.y -= 1.0
			elif mouse.y > size.y - edge_scroll_margin:
				dir.y += 1.0
	return dir.normalized() if dir.length() > 1.0 else dir


func _set_zoom(value: float) -> void:
	_zoom = clampf(value, zoom_min, zoom_max)
	_apply_zoom()


func _apply_zoom() -> void:
	var rot := Basis(Vector3.RIGHT, deg_to_rad(-pitch_degrees))
	_camera.basis = rot
	_camera.position = rot * Vector3(0.0, 0.0, _zoom)
