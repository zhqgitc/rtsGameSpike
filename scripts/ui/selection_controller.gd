class_name SelectionController
extends Node
## Mouse input for units: left click / drag-box to select (shift adds),
## right click on the ground to order a move. Selection is UI state; the
## simulation only ever receives orders through the Orders class.

const DRAG_THRESHOLD := 6.0
const CLICK_MIN_WIDTH := 24.0

var selected: Array[Unit] = []

var _press_pos := Vector2.ZERO
var _pressing := false
var _dragging := false
var _overlay: SelectionBoxOverlay


func _ready() -> void:
	var layer := CanvasLayer.new()
	_overlay = SelectionBoxOverlay.new()
	layer.add_child(_overlay)
	add_child(layer)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_pressing = true
				_dragging = false
				_press_pos = event.position
			elif _pressing:
				_pressing = false
				_overlay.hide_rect()
				if _dragging:
					_select_in_rect(_drag_rect(event.position), event.shift_pressed)
				else:
					_select_at_point(event.position, event.shift_pressed)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_order_move(event.position)
	elif event is InputEventMouseMotion and _pressing:
		if not _dragging and event.position.distance_to(_press_pos) > DRAG_THRESHOLD:
			_dragging = true
		if _dragging:
			_overlay.show_rect(_drag_rect(event.position))


func _drag_rect(current: Vector2) -> Rect2:
	return Rect2(_press_pos, Vector2.ZERO).expand(current)


## The unit under a screen point (nearest to the camera if several overlap).
func _unit_at_point(point: Vector2) -> Unit:
	var cam := get_viewport().get_camera_3d()
	var best: Unit = null
	var best_dist := INF
	for node in get_tree().get_nodes_in_group(Unit.GROUP):
		var unit := node as Unit
		if unit == null or cam.is_position_behind(unit.global_position):
			continue
		if _screen_rect(cam, unit).has_point(point):
			var dist := cam.global_position.distance_squared_to(unit.global_position)
			if dist < best_dist:
				best_dist = dist
				best = unit
	return best


func _select_at_point(point: Vector2, additive: bool) -> void:
	var best := _unit_at_point(point)
	var picked: Array[Unit] = []
	if best:
		picked.append(best)
	_apply_selection(picked, additive)


func _select_in_rect(rect: Rect2, additive: bool) -> void:
	var cam := get_viewport().get_camera_3d()
	var picked: Array[Unit] = []
	for node in get_tree().get_nodes_in_group(Unit.GROUP):
		var unit := node as Unit
		if unit == null or cam.is_position_behind(unit.global_position):
			continue
		if rect.intersects(_screen_rect(cam, unit)):
			picked.append(unit)
	_apply_selection(picked, additive)


func _apply_selection(picked: Array[Unit], additive: bool) -> void:
	if not additive:
		for unit in selected:
			if is_instance_valid(unit):
				unit.selected = false
		selected.clear()
	for unit in picked:
		if not selected.has(unit):
			selected.append(unit)
			unit.selected = true


func _order_move(screen_pos: Vector2) -> void:
	_prune_selection()
	if selected.is_empty():
		return
	# Right-click on an enemy attacks it; anywhere else moves.
	var clicked := _unit_at_point(screen_pos)
	if clicked != null and _selection_has_enemy_of(clicked):
		Orders.attack_group(selected, clicked)
		return
	var cam := get_viewport().get_camera_3d()
	var hit: Variant = Plane(Vector3.UP, 0.0).intersects_ray(
			cam.project_ray_origin(screen_pos), cam.project_ray_normal(screen_pos))
	if hit == null:
		return
	Orders.move_group(selected, hit)


func _selection_has_enemy_of(target: Unit) -> bool:
	for unit in selected:
		if unit.def.faction != target.def.faction:
			return true
	return false


func _prune_selection() -> void:
	var alive: Array[Unit] = []
	for unit in selected:
		if is_instance_valid(unit):
			alive.append(unit)
	selected = alive


## Approximate on-screen bounds of a unit, from projecting its feet and head.
func _screen_rect(cam: Camera3D, unit: Unit) -> Rect2:
	var feet := cam.unproject_position(unit.global_position)
	var head := cam.unproject_position(unit.global_position + Vector3.UP * unit.def.size.y)
	var height := absf(feet.y - head.y)
	var width := maxf(height * 0.7, CLICK_MIN_WIDTH)
	return Rect2(Vector2(feet.x - width * 0.5, minf(feet.y, head.y)), Vector2(width, maxf(height, CLICK_MIN_WIDTH)))
