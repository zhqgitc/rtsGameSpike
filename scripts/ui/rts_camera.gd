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

## A right click that did not move; orders and cancels hang off this.
signal right_clicked(screen_position: Vector2, ctrl_held: bool)

const GROUP := &"rts_camera"
const DRAG_THRESHOLD := 6.0
const MAX_SHAKE := 1.2
const SHAKE_DECAY := 1.6

var _zoom: float = 40.0
var _shake: float = 0.0
var _rmb_down: bool = false
var _rmb_dragging: bool = false
var _rmb_start: Vector2 = Vector2.ZERO
var _rmb_last: Vector2 = Vector2.ZERO

@onready var _camera: Camera3D = $Camera3D


func _ready() -> void:
	add_to_group(GROUP)
	_apply_zoom()


## Rattle the view (explosions, collapsing buildings). Strength is in metres of
## camera offset; it fades out by itself.
func shake(strength: float) -> void:
	_shake = maxf(_shake, minf(strength, MAX_SHAKE))


func _process(delta: float) -> void:
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta * SHAKE_DECAY)
		_camera.h_offset = randf_range(-1.0, 1.0) * _shake
		_camera.v_offset = randf_range(-1.0, 1.0) * _shake
	elif _camera.h_offset != 0.0 or _camera.v_offset != 0.0:
		_camera.h_offset = 0.0
		_camera.v_offset = 0.0
	var dir := _read_pan_direction()
	if dir != Vector2.ZERO:
		var step := pan_speed * _zoom * delta
		position.x = clampf(position.x + dir.x * step, -bounds.x, bounds.x)
		position.z = clampf(position.z + dir.y * step, -bounds.y, bounds.y)


## Where the four screen corners land on the ground (for the minimap's view
## outline). Corners whose ray misses the ground are left out.
func view_corners_on_ground() -> PackedVector3Array:
	var corners := PackedVector3Array()
	var size := get_viewport().get_visible_rect().size
	for point in [Vector2(0, 0), Vector2(size.x, 0), size, Vector2(0, size.y)]:
		var hit: Variant = _ground_point(point)
		if hit != null:
			corners.append(hit)
	return corners


## Jump the view to centre on a ground point.
func focus_on(point: Vector3) -> void:
	position.x = clampf(point.x, -bounds.x, bounds.x)
	position.z = clampf(point.z, -bounds.y, bounds.y)


## This node sits last in the scene tree so it sees input first. It owns the
## right mouse button: a drag pans the map ("grab" the ground), a click without
## movement is reported through right_clicked for orders and cancelling.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				_rmb_down = true
				_rmb_dragging = false
				_rmb_start = event.position
				_rmb_last = event.position
			elif _rmb_down:
				_rmb_down = false
				if not _rmb_dragging:
					right_clicked.emit(event.position, event.ctrl_pressed)
				_rmb_dragging = false
			get_viewport().set_input_as_handled()
		elif event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				_set_zoom(_zoom - zoom_step)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_set_zoom(_zoom + zoom_step)
	elif event is InputEventMouseMotion and _rmb_down:
		if not _rmb_dragging and event.position.distance_to(_rmb_start) > DRAG_THRESHOLD:
			_rmb_dragging = true
		if _rmb_dragging:
			_drag_pan(event.position)
			get_viewport().set_input_as_handled()


## Move the camera so the ground point that was under the cursor stays under it.
func _drag_pan(current: Vector2) -> void:
	var before: Variant = _ground_point(_rmb_last)
	var after: Variant = _ground_point(current)
	_rmb_last = current
	if before == null or after == null:
		return
	focus_on(position + (before - after))


func _ground_point(screen_pos: Vector2) -> Variant:
	return Plane(Vector3.UP, 0.0).intersects_ray(
			_camera.project_ray_origin(screen_pos), _camera.project_ray_normal(screen_pos))


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
	if edge_scroll_enabled and not _rmb_dragging and DisplayServer.window_is_focused():
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
