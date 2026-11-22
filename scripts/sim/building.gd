class_name Building
extends Node3D
## A structure. Starts finished unless begin_construction() is called, after
## which workers add progress until it completes. Solid obstacle on the
## navmesh; may be a drop-off, grant population cap, produce income or train
## units through a queue.

signal completed(building: Building)
## A unit finished training and should appear at `spawn_position`.
signal unit_produced(unit_def: UnitDef, spawn_position: Vector3)

## One slot in the production queue: a single unit or a Plan batch.
class QueueEntry extends RefCounted:
	var unit_def: UnitDef
	var count: int = 1
	var is_plan: bool = false
	var time_total: float = 1.0
	var elapsed: float = 0.0

	func progress() -> float:
		return clampf(elapsed / time_total, 0.0, 1.0)

const GROUP := &"buildings"
## Extra distance (beyond the footprint) from which units count as "at" it.
const REACH_MARGIN := 2.0
const SCAFFOLD_ALPHA := 0.55
const MIN_SCAFFOLD_HEIGHT := 0.08
## Gap between the building's front edge and freshly trained units.
const SPAWN_OFFSET := 2.0

var def: BuildingDef
var complete: bool = true
var build_progress: float = 0.0
var queue: Array[QueueEntry] = []
var selected: bool = false:
	set(value):
		selected = value
		if _selection_marker:
			_selection_marker.visible = value

var _body: MeshInstance3D
var _roof: MeshInstance3D
var _body_material: StandardMaterial3D
var _selection_marker: MeshInstance3D
var _income_accumulator: Dictionary = {}


func setup(building_def: BuildingDef) -> void:
	def = building_def
	name = "%s_%d" % [def.id, get_instance_id()]
	add_to_group(GROUP)
	_build_visuals()
	_build_collider()
	_build_selection_marker()


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


## Whether a camera ray hits this building's box (used for click selection).
## Returns the hit distance, or -1.0 if it misses.
func ray_distance(origin: Vector3, direction: Vector3) -> float:
	var fp := footprint()
	var box := AABB(Vector3(fp.position.x, 0.0, fp.position.y), def.size)
	var hit: Variant = box.intersects_ray(origin, direction)
	return origin.distance_to(hit) if hit != null else -1.0


## Centre distance within which a unit standing next to the building counts as
## having reached it (footprint corner plus navmesh margin plus a little slack).
func reach() -> float:
	return maxf(def.size.x, def.size.z) * 0.5 * 1.45 + REACH_MARGIN


# --- Production -------------------------------------------------------------

## Cost of one queue entry (a single unit, or a whole Plan batch).
func entry_costs(unit_def: UnitDef, as_plan: bool) -> Dictionary:
	var count := def.plan_batch_size if as_plan else 1
	var factor := def.plan_cost_factor if as_plan else 1.0
	var costs := {}
	for resource in unit_def.train_costs:
		costs[resource] = ceili(unit_def.train_costs[resource] * count * factor)
	return costs


func entry_time(unit_def: UnitDef, as_plan: bool) -> float:
	if as_plan:
		return unit_def.train_time * def.plan_batch_size * def.plan_time_factor
	return unit_def.train_time


## Manpower reserved by units waiting in or being trained from the queue.
func queued_pop() -> int:
	var total := 0
	for entry in queue:
		total += entry.unit_def.pop_cost * entry.count
	return total


## Why a unit (or Plan batch) cannot be queued right now, or an empty string
## if it can. Used for the command card's greyed-out state and tooltips.
func block_reason(unit_def: UnitDef, as_plan: bool) -> String:
	if not complete:
		return "Still under construction"
	if not def.trains.has(unit_def):
		return "%s cannot train %s" % [def.display_name, unit_def.display_name]
	if as_plan and def.plan_batch_size <= 0:
		return "No Plan batches at %s" % def.display_name
	if queue.size() >= def.queue_slots:
		return "Queue is full (%d slots)" % def.queue_slots
	if unit_def.requires != null and not _has_finished_building(unit_def.requires):
		return "%s requires a finished %s" % [unit_def.display_name, unit_def.requires.display_name]
	var economy := get_tree().get_first_node_in_group(Economy.GROUP) as Economy
	if economy == null:
		return "No economy"
	var count := def.plan_batch_size if as_plan else 1
	if unit_def.pop_cost > 0 and economy.pop_used(def.faction) + unit_def.pop_cost * count > economy.pop_cap(def.faction):
		return "Not enough Manpower: build more housing"
	return economy.shortfall(def.faction, entry_costs(unit_def, as_plan))


## Queue a unit (or a Plan batch). Pays up front. Returns an empty string on
## success, otherwise a short reason why it was refused.
func try_enqueue(unit_def: UnitDef, as_plan: bool) -> String:
	var reason := block_reason(unit_def, as_plan)
	if not reason.is_empty():
		return reason
	var economy := get_tree().get_first_node_in_group(Economy.GROUP) as Economy
	var count := def.plan_batch_size if as_plan else 1
	economy.spend(def.faction, entry_costs(unit_def, as_plan))
	var entry := QueueEntry.new()
	entry.unit_def = unit_def
	entry.count = count
	entry.is_plan = as_plan
	entry.time_total = entry_time(unit_def, as_plan)
	queue.append(entry)
	return ""


func _physics_process(delta: float) -> void:
	if not complete:
		return
	_tick_income(delta)
	_tick_production(delta)


func _tick_income(delta: float) -> void:
	if def.income.is_empty():
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


func _tick_production(delta: float) -> void:
	if queue.is_empty():
		return
	var head := queue[0]
	head.elapsed += delta
	if head.elapsed < head.time_total:
		return
	queue.pop_front()
	_deliver(head)


## Units step out of the front of the building, side by side.
func _deliver(entry: QueueEntry) -> void:
	var spacing := maxf(entry.unit_def.formation_spacing, 1.5)
	var front := global_position + Vector3(0.0, 0.0, def.size.z * 0.5 + SPAWN_OFFSET)
	for i in entry.count:
		var offset := (i - (entry.count - 1) * 0.5) * spacing
		unit_produced.emit(entry.unit_def, front + Vector3(offset, 0.0, 0.0))


func _has_finished_building(building_def: BuildingDef) -> bool:
	for node in get_tree().get_nodes_in_group(GROUP):
		var other := node as Building
		if other != null and other.complete and other.def == building_def and other.def.faction == def.faction:
			return true
	return false


# --- Visuals ----------------------------------------------------------------

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


## Flat green pad under the building while it is selected.
func _build_selection_marker() -> void:
	var pad := BoxMesh.new()
	pad.size = Vector3(def.size.x + 1.2, 0.06, def.size.z + 1.2)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 1.0, 0.3, 0.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_selection_marker = MeshInstance3D.new()
	_selection_marker.mesh = pad
	_selection_marker.material_override = mat
	_selection_marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_selection_marker.position.y = 0.04
	_selection_marker.visible = selected
	add_child(_selection_marker)


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
