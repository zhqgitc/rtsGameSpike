class_name SelectionController
extends Node
## Mouse input for units: left click / drag-box to select (shift adds),
## right click on the ground to order a move. Selection is UI state; the
## simulation only ever receives orders through the Orders class.

const DRAG_THRESHOLD := 6.0
const CLICK_MIN_WIDTH := 24.0

var selected: Array[Unit] = []
## A selected building (mutually exclusive with selected units).
var selected_building: Building

var _press_pos := Vector2.ZERO
var _pressing := false
var _dragging := false
var _overlay: SelectionBoxOverlay
var _session: Session


func _ready() -> void:
	_session = Session.find(get_tree())
	# Right clicks come from the camera, which also uses right-drag to pan.
	(get_node("../RTSCamera") as RTSCamera).right_clicked.connect(_order_move)
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
	elif event is InputEventMouseMotion and _pressing:
		if not _dragging and event.position.distance_to(_press_pos) > DRAG_THRESHOLD:
			_dragging = true
		if _dragging:
			_overlay.show_rect(_drag_rect(event.position))


func _drag_rect(current: Vector2) -> Rect2:
	return Rect2(_press_pos, Vector2.ZERO).expand(current)


## Only the player's own units and buildings can be selected.
func _is_mine(faction: StringName) -> bool:
	return _session == null or _session.player_faction == &"" or _session.is_player(faction)


## The unit under a screen point (nearest to the camera if several overlap).
## Enemy units are only considered when `include_enemies` is set (attack targets).
func _unit_at_point(point: Vector2, include_enemies: bool = false) -> Unit:
	var cam := get_viewport().get_camera_3d()
	var best: Unit = null
	var best_dist := INF
	for node in get_tree().get_nodes_in_group(Unit.GROUP):
		var unit := node as Unit
		if unit == null or cam.is_position_behind(unit.global_position):
			continue
		if not include_enemies and not _is_mine(unit.def.faction):
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
	elif not additive:
		var building := _building_at_point(point)
		if building != null:
			_apply_selection(picked, false)
			_set_building(building)
			return
	_apply_selection(picked, additive)


## The building under a screen point, found by casting the camera ray into
## each building's box (so clicking a roof works as well as a wall).
func _building_at_point(point: Vector2) -> Building:
	var cam := get_viewport().get_camera_3d()
	var origin := cam.project_ray_origin(point)
	var direction := cam.project_ray_normal(point)
	var best: Building = null
	var best_dist := INF
	for node in get_tree().get_nodes_in_group(Building.GROUP):
		var building := node as Building
		if building == null or not _is_mine(building.def.faction):
			continue
		var dist := building.ray_distance(origin, direction)
		if dist >= 0.0 and dist < best_dist:
			best_dist = dist
			best = building
	return best


func _set_building(building: Building) -> void:
	if is_instance_valid(selected_building):
		selected_building.selected = false
	selected_building = building
	if building != null:
		building.selected = true


func _select_in_rect(rect: Rect2, additive: bool) -> void:
	var cam := get_viewport().get_camera_3d()
	var picked: Array[Unit] = []
	for node in get_tree().get_nodes_in_group(Unit.GROUP):
		var unit := node as Unit
		if unit == null or not _is_mine(unit.def.faction) or cam.is_position_behind(unit.global_position):
			continue
		if rect.intersects(_screen_rect(cam, unit)):
			picked.append(unit)
	_apply_selection(picked, additive)


func _apply_selection(picked: Array[Unit], additive: bool) -> void:
	if not additive or not picked.is_empty():
		_set_building(null)
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
	# While placing a building, right click only cancels the placement.
	var placer := get_node_or_null("../BuildPlacer") as BuildPlacer
	if placer != null and placer.is_placing():
		return
	_prune_selection()
	if selected.is_empty():
		return
	# Right-click on an enemy attacks it; anywhere else moves.
	var clicked := _unit_at_point(screen_pos, true)
	if clicked != null and _selection_has_enemy_of(clicked):
		Orders.attack_group(selected, clicked)
		return
	var cam := get_viewport().get_camera_3d()
	var hit: Variant = Plane(Vector3.UP, 0.0).intersects_ray(
			cam.project_ray_origin(screen_pos), cam.project_ray_normal(screen_pos))
	if hit == null:
		return
	command_point(hit)


## Order the selected units to a ground point: gather from a deposit there,
## help build a site there, or simply move. Used by right clicks on the world
## and on the minimap.
func command_point(ground_point: Vector3) -> void:
	_prune_selection()
	if selected.is_empty():
		return
	var deposit := _resource_node_at(ground_point)
	if deposit != null:
		Orders.harvest_group(selected, deposit)
		return
	var site := _unfinished_building_at(ground_point)
	if site != null and Orders.build_group(selected, site) > 0:
		return
	Orders.move_group(selected, ground_point)


## An unfinished building whose footprint contains a ground point, if any.
func _unfinished_building_at(ground_point: Vector3) -> Building:
	var point := Vector2(ground_point.x, ground_point.z)
	for candidate in get_tree().get_nodes_in_group(Building.GROUP):
		var building := candidate as Building
		if building != null and not building.complete and building.footprint().has_point(point):
			return building
	return null


## The resource deposit whose footprint contains a ground point, if any.
func _resource_node_at(ground_point: Vector3) -> ResourceNode:
	for candidate in get_tree().get_nodes_in_group(ResourceNode.GROUP):
		var node := candidate as ResourceNode
		if node == null:
			continue
		var offset := ground_point - node.global_position
		offset.y = 0.0
		if offset.length() <= node.radius * 1.45 + 0.5:
			return node
	return null


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
