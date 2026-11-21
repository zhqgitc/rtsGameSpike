class_name BuildPlacer
extends Node
## Temporary building placement (until the HUD): with a worker selected, press
## 1, 2, ... to pick one of its buildings, move the ghost over the map, left
## click to place it, right click or Esc to cancel. Placing pays the cost and
## sends the selected workers to construct it.
##
## Must come after the SelectionController in the scene tree so it sees
## input first and can swallow clicks while placing.

const GRID := 1.0
const VALID_COLOR := Color(0.3, 1.0, 0.3, 0.45)
const INVALID_COLOR := Color(1.0, 0.25, 0.25, 0.45)

var _def: BuildingDef
var _ghost: MeshInstance3D
var _ghost_material: StandardMaterial3D
var _label: Label
var _position: Vector3 = Vector3.ZERO
var _problem: String = ""

@onready var _selection: SelectionController = get_node("../SelectionController")
@onready var _terrain: Terrain = get_node("../Terrain")
@onready var _buildings: Node3D = get_node("../Buildings")
@onready var _economy: Economy = get_node("../Economy")


func _ready() -> void:
	var layer := CanvasLayer.new()
	_label = Label.new()
	_label.position = Vector2(16, 90)
	_label.add_theme_font_size_override("font_size", 18)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 6)
	_label.visible = false
	layer.add_child(_label)
	add_child(layer)


func _process(_delta: float) -> void:
	if _def == null:
		return
	var ground: Variant = _ground_point(get_viewport().get_mouse_position())
	if ground != null:
		_position = Vector3(snappedf(ground.x, GRID), 0.0, snappedf(ground.z, GRID))
	_ghost.position = _position + Vector3.UP * _def.size.y * 0.5
	_problem = _validate()
	_ghost_material.albedo_color = VALID_COLOR if _problem.is_empty() else INVALID_COLOR
	_label.text = "%s  (%s)\n%s" % [_def.display_name, _cost_text(), _problem if not _problem.is_empty() else "Left click: place   Right click / Esc: cancel"]


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var index: int = event.keycode - KEY_1
		if index >= 0 and index < 9:
			if _start(index):
				get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE and _def != null:
			_cancel()
			get_viewport().set_input_as_handled()
		return
	if _def == null or not event is InputEventMouseButton or not event.pressed:
		return
	if event.button_index == MOUSE_BUTTON_LEFT:
		_try_place()
		get_viewport().set_input_as_handled()
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		_cancel()
		get_viewport().set_input_as_handled()


func _start(index: int) -> bool:
	var builder := _first_builder()
	if builder == null or index >= builder.def.builds.size():
		return false
	_cancel()
	_def = builder.def.builds[index]
	var box := BoxMesh.new()
	box.size = _def.size
	_ghost_material = StandardMaterial3D.new()
	_ghost_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ghost_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ghost = MeshInstance3D.new()
	_ghost.mesh = box
	_ghost.material_override = _ghost_material
	_ghost.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ghost)
	_label.visible = true
	return true


func _cancel() -> void:
	_def = null
	if _ghost != null:
		_ghost.queue_free()
		_ghost = null
	_label.visible = false


func _try_place() -> void:
	_problem = _validate()
	if not _problem.is_empty():
		return
	var builder := _first_builder()
	if builder == null or not _economy.spend(_def.faction, _def.costs):
		return
	var site := Building.new()
	_buildings.add_child(site)
	site.setup(_def)
	site.position = _position
	site.begin_construction()
	_terrain.rebake()
	Orders.build_group(_selection.selected, site)
	_cancel()


func _validate() -> String:
	var shortfall := _economy.shortfall(_def.faction, _def.costs)
	if not shortfall.is_empty():
		return shortfall
	return Placement.check(get_tree(), _def, _position)


func _first_builder() -> Unit:
	for unit in _selection.selected:
		if is_instance_valid(unit) and unit.def.can_build():
			return unit
	return null


func _ground_point(screen_pos: Vector2) -> Variant:
	var cam := get_viewport().get_camera_3d()
	return Plane(Vector3.UP, 0.0).intersects_ray(
			cam.project_ray_origin(screen_pos), cam.project_ray_normal(screen_pos))


func _cost_text() -> String:
	var parts: Array[String] = []
	for resource in _def.costs:
		parts.append("%d %s" % [_def.costs[resource], String(resource).capitalize()])
	return ", ".join(parts) if not parts.is_empty() else "free"
