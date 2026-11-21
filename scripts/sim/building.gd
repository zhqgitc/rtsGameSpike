class_name Building
extends Node3D
## A structure. Starts finished unless begin_construction() is called, after
## which workers add progress until it completes. Solid obstacle on the
## navmesh; may be a drop-off, grant population cap or produce income.

signal completed(building: Building)

const GROUP := &"buildings"
## Extra distance (beyond the footprint) from which units count as "at" it.
const REACH_MARGIN := 2.0
const SCAFFOLD_ALPHA := 0.55
const MIN_SCAFFOLD_HEIGHT := 0.08

var def: BuildingDef
var complete: bool = true
var build_progress: float = 0.0

var _body: MeshInstance3D
var _roof: MeshInstance3D
var _body_material: StandardMaterial3D
var _income_accumulator: Dictionary = {}


func setup(building_def: BuildingDef) -> void:
	def = building_def
	name = "%s_%d" % [def.id, get_instance_id()]
	add_to_group(GROUP)
	_build_visuals()
	_build_collider()


## Turn this building into a construction site (call right after setup).
func begin_construction() -> void:
	complete = false
	build_progress = 0.0
	_update_construction_visual()


## Work done by builders, in build-seconds. Finishes the building when enough.
func add_progress(amount: float) -> void:
	if complete:
		return
	build_progress += amount
	if build_progress >= def.build_time:
		complete = true
		_update_construction_visual()
		completed.emit(self)
	else:
		_update_construction_visual()


func progress_fraction() -> float:
	return 1.0 if complete else clampf(build_progress / def.build_time, 0.0, 1.0)


func accepts(resource: StringName) -> bool:
	return complete and def.drop_off_resources.has(resource)


func footprint() -> Rect2:
	var half := Vector2(def.size.x, def.size.z) * 0.5
	return Rect2(Vector2(global_position.x, global_position.z) - half, half * 2.0)


## Centre distance within which a unit standing next to the building counts as
## having reached it (footprint corner plus navmesh margin plus a little slack).
func reach() -> float:
	return maxf(def.size.x, def.size.z) * 0.5 * 1.45 + REACH_MARGIN


func _physics_process(delta: float) -> void:
	if not complete or def.income.is_empty():
		return
	var economy := get_tree().get_first_node_in_group(Economy.GROUP) as Economy
	if economy == null:
		return
	for resource in def.income:
		var acc: float = _income_accumulator.get(resource, 0.0) + def.income[resource] * delta
		var whole := int(acc)
		if whole > 0:
			economy.add(def.faction, resource, whole)
			acc -= whole
		_income_accumulator[resource] = acc


func _build_visuals() -> void:
	var box := BoxMesh.new()
	box.size = def.size
	_body_material = StandardMaterial3D.new()
	_body_material.albedo_color = def.color
	_body_material.roughness = 0.95
	_body = MeshInstance3D.new()
	_body.mesh = box
	_body.material_override = _body_material
	_body.position.y = def.size.y * 0.5
	add_child(_body)

	var band := BoxMesh.new()
	band.size = Vector3(def.size.x + 0.2, 0.5, def.size.z + 0.2)
	var band_mat := StandardMaterial3D.new()
	band_mat.albedo_color = def.accent_color
	_roof = MeshInstance3D.new()
	_roof.mesh = band
	_roof.material_override = band_mat
	# Raised a hair so the band's top doesn't z-fight with the body's top face.
	_roof.position.y = def.size.y - 0.25 + 0.03
	add_child(_roof)


func _build_collider() -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = def.size
	shape.shape = box
	body.add_child(shape)
	body.add_to_group(Terrain.NAV_SOURCE_GROUP)
	add_child(body)
	body.position.y = def.size.y * 0.5


## Scaffold look: translucent and rising with progress; solid once finished.
func _update_construction_visual() -> void:
	if _body == null:
		return
	var fraction := progress_fraction()
	var height_scale := 1.0 if complete else maxf(fraction, MIN_SCAFFOLD_HEIGHT)
	_body.scale.y = height_scale
	_body.position.y = def.size.y * height_scale * 0.5
	_roof.visible = complete
	if complete:
		_body_material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
		_body_material.albedo_color = def.color
	else:
		_body_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_body_material.albedo_color = Color(def.color, SCAFFOLD_ALPHA)
