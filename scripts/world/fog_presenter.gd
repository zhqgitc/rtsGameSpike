class_name FogPresenter
extends Node3D
## Draws the fog of war in the 3D world: a dark overlay on the terrain, enemy
## units hidden outside sight, and enemy buildings, deposits and walls hidden
## until explored (explored-but-unseen buildings stay, dimmed). The player's
## own things are always shown.

const OVERLAY_HEIGHT := 0.06

var _fog: FogOfWar
var _terrain: Terrain
var _session: Session


func _ready() -> void:
	_fog = get_node("../Fog")
	_terrain = get_node("../Terrain")
	_session = get_node("../Session")
	_build_overlay()
	_fog.updated.connect(apply)


## Apply the current fog to every unit, building, deposit and wall.
func apply() -> void:
	for node in get_tree().get_nodes_in_group(Unit.GROUP):
		apply_to_unit(node as Unit)
	for node in get_tree().get_nodes_in_group(Building.GROUP):
		_apply_to_building(node as Building)
	for node in get_tree().get_nodes_in_group(ResourceNode.GROUP):
		var deposit := node as ResourceNode
		if deposit != null:
			deposit.visible = _fog.is_explored_at(deposit.global_position)
	for i in _terrain.obstacle_meshes.size():
		_terrain.obstacle_meshes[i].visible = _fog.best_state_in(_terrain.obstacles[i]) != FogOfWar.State.UNEXPLORED


## Used for units that have just been created, so an enemy unit does not
## flash into view before the next update.
func apply_to_unit(unit: Unit) -> void:
	if unit == null:
		return
	unit.visible = unit.def.faction == _session.player_faction or _fog.is_visible_at(unit.global_position)


func _apply_to_building(building: Building) -> void:
	if building == null:
		return
	if building.def.faction == _session.player_faction:
		building.visible = true
		building.set_remembered(false)
		return
	var state := _fog.best_state_in(building.footprint())
	building.visible = state != FogOfWar.State.UNEXPLORED
	building.set_remembered(state == FogOfWar.State.EXPLORED)


func _build_overlay() -> void:
	var plane := PlaneMesh.new()
	plane.size = _terrain.map_size
	var material := StandardMaterial3D.new()
	material.albedo_texture = _fog.overlay_texture
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	material.texture_repeat = false
	var overlay := MeshInstance3D.new()
	overlay.mesh = plane
	overlay.material_override = material
	overlay.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	overlay.position.y = OVERLAY_HEIGHT
	add_child(overlay)
