class_name AIController
extends Node
## Plays the faction the human is not playing: keeps workers harvesting, builds
## its structures in plan order, and trains its army. It uses the same rules as
## the player (pays costs, trains through queues, builds with workers) and
## thinks twice a second. Attacks come later (M7c).

const THINK_INTERVAL := 0.5
## Building spots are searched on a grid around the HQ.
const SPOT_STEP := 3.0
const SPOT_RADIUS := 34.0
## Workers only harvest deposits this close to the HQ (not across the map).
const HARVEST_RADIUS := 55.0
## A site nobody makes progress on for this long is abandoned.
const STALL_LIMIT_SECONDS := 40.0
## Spots near an abandoned site are not tried again within this distance.
const BAD_SPOT_RADIUS := 5.0

var faction: StringName = &""
var plan: AIPlan

var _since_think: float = 0.0
## True while the AI is waiting to afford its next building, so it does not
## spend the money on army units instead.
var _saving: bool = false
## Per construction site: last seen progress and how long it has not changed.
var _site_watch: Dictionary = {}
var _bad_spots: Array[Vector3] = []

@onready var _session: Session = get_node("../Session")
@onready var _economy: Economy = get_node("../Economy")
@onready var _terrain: Terrain = get_node("../Terrain")
@onready var _buildings: Node3D = get_node("../Buildings")
@onready var _rules: MatchRules = get_node("../MatchRules")


func _ready() -> void:
	_session.faction_chosen.connect(_on_player_chose)


func _on_player_chose(player_faction: StringName) -> void:
	faction = &"libertarians" if player_faction == &"collectivists" else &"collectivists"
	plan = load("res://data/ai/%s_plan.tres" % faction) as AIPlan


func _physics_process(delta: float) -> void:
	if plan == null or _rules.ended:
		return
	_since_think += delta
	if _since_think < THINK_INTERVAL:
		return
	_since_think = 0.0
	_manage_workers()
	_manage_construction()
	_manage_production()


## One line describing what the AI has, for tests and debugging.
func status() -> String:
	return "workers=%d army=%d buildings=%s saving=%s" % [_workers().size(), _army_count(), _building_summary(), _saving]


# --- Workers ----------------------------------------------------------------

func _manage_workers() -> void:
	var hq := _hq()
	if hq == null:
		return
	var workers := _workers()
	var queued := 0
	for entry in hq.queue:
		if entry.unit_def == plan.worker:
			queued += entry.count
	if workers.size() + queued < plan.target_workers and hq.queue.size() < plan.max_queued_per_building:
		hq.try_enqueue(plan.worker, false)
	for worker in workers:
		if worker.is_free():
			_send_to_harvest(worker)


func _send_to_harvest(worker: Unit) -> void:
	var hq := _hq()
	var best: ResourceNode = null
	var best_dist := INF
	for node in get_tree().get_nodes_in_group(ResourceNode.GROUP):
		var deposit := node as ResourceNode
		if deposit == null or deposit.amount <= 0:
			continue
		if hq != null and deposit.global_position.distance_to(hq.global_position) > HARVEST_RADIUS:
			continue
		var d := worker.global_position.distance_squared_to(deposit.global_position)
		if d < best_dist:
			best_dist = d
			best = deposit
	if best != null:
		worker.issue_harvest(best)


# --- Construction -----------------------------------------------------------

func _manage_construction() -> void:
	var hq := _hq()
	if hq == null:
		return
	var open_sites := 0
	for building in _own_buildings():
		if building.complete:
			_site_watch.erase(building.get_instance_id())
			continue
		if _site_is_stalled(building):
			# Nobody can make progress here (probably walled in): give up on it.
			_bad_spots.append(building.global_position)
			_site_watch.erase(building.get_instance_id())
			building.take_damage(building.health, null)
			continue
		open_sites += 1
		if not _has_builder_for(building):
			var worker := _pick_builder(building.global_position, building.def)
			if worker != null:
				worker.issue_build(building)
	# One new building at a time.
	if open_sites > 0:
		_saving = false
		return
	var next := _next_building()
	_saving = false
	if next == null:
		return
	if not _economy.shortfall(faction, next.costs).is_empty():
		_saving = _workers().size() >= plan.target_workers
		return
	var spot: Variant = _find_spot(next, hq)
	if spot == null:
		return
	var site := Construction.begin(_buildings, next, spot, _economy, _terrain)
	if site == null:
		return
	var builder := _pick_builder(site.global_position, next)
	if builder != null:
		builder.issue_build(site)


## The next building to start: housing when Manpower is short, otherwise the
## first entry of the build order we do not have enough of yet.
func _next_building() -> BuildingDef:
	if plan.housing != null and _economy.pop_cap(faction) - _economy.pop_used(faction) < plan.housing_margin:
		return plan.housing
	for i in plan.build_order.size():
		var wanted := plan.build_order[i]
		var needed := 0
		for j in i + 1:
			if plan.build_order[j] == wanted:
				needed += 1
		if _count_buildings(wanted) < needed:
			return wanted
	return null


func _find_spot(def: BuildingDef, hq: Building) -> Variant:
	var limit := SPOT_RADIUS
	if def.max_distance_from_hq > 0.0:
		limit = minf(limit, def.max_distance_from_hq - 1.0)
	var candidates: Array[Vector3] = []
	var steps := int(limit / SPOT_STEP)
	for ix in range(-steps, steps + 1):
		for iz in range(-steps, steps + 1):
			var pos := hq.global_position + Vector3(ix * SPOT_STEP, 0.0, iz * SPOT_STEP)
			if pos.distance_to(hq.global_position) <= limit:
				candidates.append(pos)
	candidates.sort_custom(func(a: Vector3, b: Vector3) -> bool:
		return a.distance_squared_to(hq.global_position) < b.distance_squared_to(hq.global_position))
	for pos in candidates:
		if _near_bad_spot(pos):
			continue
		if Placement.check(get_tree(), def, pos).is_empty():
			return pos
	return null


func _near_bad_spot(pos: Vector3) -> bool:
	for bad in _bad_spots:
		if pos.distance_to(bad) < BAD_SPOT_RADIUS:
			return true
	return false


## Tracks a site's progress between thoughts; true once it has not moved for
## STALL_LIMIT_SECONDS.
func _site_is_stalled(site: Building) -> bool:
	var key := site.get_instance_id()
	var watch: Array = _site_watch.get(key, [site.build_progress, 0.0])
	if not is_equal_approx(watch[0], site.build_progress):
		watch = [site.build_progress, 0.0]
	else:
		watch[1] += THINK_INTERVAL
	_site_watch[key] = watch
	return watch[1] >= STALL_LIMIT_SECONDS


func _has_builder_for(site: Building) -> bool:
	for worker in _workers():
		if worker.build_site() == site:
			return true
	return false


## The nearest worker that can build the type and is not already building:
## idle workers first, otherwise one pulled off harvesting.
func _pick_builder(pos: Vector3, def: BuildingDef) -> Unit:
	var best: Unit = null
	var best_score := INF
	for worker in _workers():
		if not worker.def.builds.has(def) or worker.job_kind() == &"build":
			continue
		var score := worker.global_position.distance_to(pos) + (0.0 if worker.is_free() else 40.0)
		if score < best_score:
			best_score = score
			best = worker
	return best


# --- Production -------------------------------------------------------------

func _manage_production() -> void:
	# Workers first, and no army spending while saving for a building.
	if _saving or _workers().size() < plan.target_workers:
		return
	for building in _own_buildings():
		if building.complete and not building.def.is_hq and not building.def.trains.is_empty() \
				and building.queue.size() < plan.max_queued_per_building:
			_train_army_at(building)


func _train_army_at(building: Building) -> void:
	for unit_def in plan.army:
		if not building.def.trains.has(unit_def) or not building.prerequisite_met(unit_def):
			continue
		if plan.use_plan_batches and building.def.plan_batch_size > 0 and building.block_reason(unit_def, true).is_empty():
			building.try_enqueue(unit_def, true)
			return
		if building.try_enqueue(unit_def, false).is_empty():
			return
		return ## The best available unit is not affordable yet: wait for it.


# --- Queries ----------------------------------------------------------------

func _hq() -> Building:
	for building in _own_buildings():
		if building.def.is_hq and building.complete:
			return building
	return null


func _own_buildings() -> Array[Building]:
	var result: Array[Building] = []
	for node in get_tree().get_nodes_in_group(Building.GROUP):
		var building := node as Building
		if building != null and building.def.faction == faction and not building.is_dead():
			result.append(building)
	return result


func _own_units() -> Array[Unit]:
	var result: Array[Unit] = []
	for node in get_tree().get_nodes_in_group(Unit.GROUP):
		var unit := node as Unit
		if unit != null and unit.def.faction == faction:
			result.append(unit)
	return result


func _workers() -> Array[Unit]:
	var result: Array[Unit] = []
	for unit in _own_units():
		if unit.def == plan.worker:
			result.append(unit)
	return result


func _army_count() -> int:
	var count := 0
	for unit in _own_units():
		if unit.def.can_attack():
			count += 1
	return count


func _count_buildings(def: BuildingDef) -> int:
	var count := 0
	for building in _own_buildings():
		if building.def == def:
			count += 1
	return count


func _building_summary() -> String:
	var parts: Array[String] = []
	for building in _own_buildings():
		parts.append("%s%s" % [building.def.display_name, "" if building.complete else "(%d%%)" % roundi(building.progress_fraction() * 100.0)])
	return ", ".join(parts)
