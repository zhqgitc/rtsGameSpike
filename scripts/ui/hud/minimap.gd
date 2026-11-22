class_name Minimap
extends Control
## Top-down overview of the whole map: terrain, obstacles, deposits, buildings
## and units as coloured marks, plus an outline of what the camera sees.
## Left click or drag moves the camera; right click orders the selected units.
## Redrawn a few times a second.

const REFRESH_INTERVAL := 0.1
const GROUND_COLOR := Color(0.22, 0.28, 0.2)
const OBSTACLE_COLOR := Color(0.5, 0.5, 0.55)
const DEPOSIT_COLOR := Color(0.7, 0.48, 0.22)

var _terrain: Terrain
var _fog: FogOfWar
var _rig: RTSCamera
var _selection: SelectionController
var _player_faction: StringName = &""
var _dragging: bool = false
var _since_refresh: float = 0.0


func setup(terrain: Terrain, rig: RTSCamera, selection: SelectionController, fog: FogOfWar, player_faction: StringName) -> void:
	_terrain = terrain
	_fog = fog
	_rig = rig
	_selection = selection
	_player_faction = player_faction
	custom_minimum_size = Vector2(210, 210)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _process(delta: float) -> void:
	_since_refresh += delta
	if _since_refresh >= REFRESH_INTERVAL:
		_since_refresh = 0.0
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if _terrain == null:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_dragging = event.pressed
			if event.pressed:
				_rig.focus_on(_to_world(event.position))
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_selection.command_point(_to_world(event.position))
		accept_event()
	elif event is InputEventMouseMotion and _dragging:
		_rig.focus_on(_to_world(event.position))
		accept_event()


# --- Coordinate mapping -----------------------------------------------------

func _to_map(world: Vector3) -> Vector2:
	var half := _terrain.map_size * 0.5
	return Vector2((world.x + half.x) / _terrain.map_size.x * size.x, (world.z + half.y) / _terrain.map_size.y * size.y)


func _to_world(map_point: Vector2) -> Vector3:
	var half := _terrain.map_size * 0.5
	var clamped := map_point.clamp(Vector2.ZERO, size)
	return Vector3(clamped.x / size.x * _terrain.map_size.x - half.x, 0.0, clamped.y / size.y * _terrain.map_size.y - half.y)


func _rect_to_map(rect: Rect2) -> Rect2:
	var top_left := _to_map(Vector3(rect.position.x, 0.0, rect.position.y))
	var bottom_right := _to_map(Vector3(rect.end.x, 0.0, rect.end.y))
	return Rect2(top_left, bottom_right - top_left)


func _faction_color(faction: StringName) -> Color:
	return HudStyle.palette(faction)["border"]


# --- Drawing ----------------------------------------------------------------

func _draw() -> void:
	if _terrain == null:
		return
	draw_rect(Rect2(Vector2.ZERO, size), GROUND_COLOR, true)
	for obstacle in _terrain.obstacles:
		if _fog.best_state_in(obstacle) != FogOfWar.State.UNEXPLORED:
			draw_rect(_rect_to_map(obstacle), OBSTACLE_COLOR, true)
	for node in get_tree().get_nodes_in_group(ResourceNode.GROUP):
		var deposit := node as ResourceNode
		if deposit != null and _fog.is_explored_at(deposit.global_position):
			draw_rect(Rect2(_to_map(deposit.global_position) - Vector2(2, 2), Vector2(4, 4)), DEPOSIT_COLOR, true)
	for node in get_tree().get_nodes_in_group(Building.GROUP):
		var building := node as Building
		if building != null and building.visible:
			_draw_building(building)
	for node in get_tree().get_nodes_in_group(Unit.GROUP):
		var unit := node as Unit
		if unit != null and unit.visible:
			_draw_unit(unit)
	# Fog of war on top of the marks, then the view outline.
	draw_texture_rect(_fog.overlay_texture, Rect2(Vector2.ZERO, size), false)
	_draw_view_outline()
	draw_rect(Rect2(Vector2.ZERO, size), HudStyle.palette(_player_faction)["border"], false, 2.0)


func _draw_building(building: Building) -> void:
	var rect := _rect_to_map(building.footprint())
	var color := _faction_color(building.def.faction)
	if not building.complete:
		color.a = 0.55
	draw_rect(rect, color, true)
	if building.def.faction == _player_faction:
		draw_rect(rect, Color.WHITE, false, 1.0)


func _draw_unit(unit: Unit) -> void:
	var own := unit.def.faction == _player_faction
	draw_circle(_to_map(unit.global_position), 2.6 if own else 2.0, _faction_color(unit.def.faction))


func _draw_view_outline() -> void:
	var corners := _rig.view_corners_on_ground()
	if corners.size() < 3:
		return
	var points := PackedVector2Array()
	for corner in corners:
		points.append(_to_map(corner).clamp(Vector2.ZERO, size))
	points.append(points[0])
	draw_polyline(points, Color(1, 1, 1, 0.9), 1.5)
