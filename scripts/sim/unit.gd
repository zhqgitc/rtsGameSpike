class_name Unit
extends Damageable
## A unit in the world: health, move/attack orders, automatic engagement and
## retreat, pathing over the navigation mesh (with avoidance), plus placeholder
## visuals. All behaviour runs in _physics_process (the fixed simulation tick).

enum State { IDLE, MOVING, ATTACKING, RETREATING, ATTACK_MOVING }

const GROUP := &"units"
## A unit that barely moves for this long while travelling gives up.
const STALL_SECONDS := 1.0
const STALL_SPEED_FRACTION := 0.2
const SCAN_INTERVAL := 0.25
const REPATH_INTERVAL := 0.3
## An automatically acquired target is dropped beyond acquire_range * this.
const LEASH_FACTOR := 1.6
const RETREAT_DISTANCE := 24.0
const FACE_TURN_RATE := 10.0
## Avoidance priority of standing units (moving units use 1.0): lower priority
## means stepping aside for others.
const STANDING_PRIORITY := 0.5
## Ignore pushes weaker than this so idle units don't jitter.
const NUDGE_MIN_SPEED := 0.15

static var _spawn_counter: int = 0

var def: UnitDef
var state: State = State.IDLE
var selected: bool = false:
	set(value):
		selected = value
		if _selection_ring:
			_selection_ring.visible = value

var _agent: NavigationAgent3D
var _selection_ring: MeshInstance3D
var _target: Damageable
var _target_ordered: bool = false ## Player-ordered targets are never dropped automatically.
var _attack_moving: bool = false ## On an attack-move: resume travelling after each fight.
var _attack_move_dest: Vector3 = Vector3.ZERO
var _path_active: bool = false
var _cooldown: float = 0.0
var _scan_timer: float = 0.0
var _repath_timer: float = 0.0
var _stall_time: float = 0.0
var _job: Job


func setup(unit_def: UnitDef) -> void:
	def = unit_def
	health = def.max_health
	name = "%s_%d" % [def.id, get_instance_id()]
	# Deterministic stagger so units don't all scan in the same tick.
	_scan_timer = (_spawn_counter % 5) * (SCAN_INTERVAL / 5.0)
	_spawn_counter += 1
	add_to_group(GROUP)
	_build_placeholder_mesh()
	_build_selection_ring()
	_build_agent()


# --- Orders -----------------------------------------------------------------

## Walk to a point on the ground, ignoring enemies on the way.
func issue_move(target: Vector3) -> void:
	_job = null
	_target = null
	_attack_moving = false
	_begin_travel(target, State.MOVING)


## Walk to a point but fight anything met on the way (units first, then
## buildings), then carry on. Units that cannot attack just move.
func issue_attack_move(target: Vector3) -> void:
	if not def.can_attack():
		issue_move(target)
		return
	_job = null
	_target = null
	_attack_moving = true
	_attack_move_dest = target
	_scan_timer = 0.0
	_begin_travel(target, State.ATTACK_MOVING)


## Attack a specific unit or building, chasing it as needed. Stays on it until
## it is destroyed.
func issue_attack(enemy: Damageable) -> void:
	if not def.can_attack() or enemy == null or enemy == self or enemy._dead:
		return
	_job = null
	_attack_moving = false
	_begin_attack(enemy, true)


## Gather from a deposit and deliver to the nearest drop-off, repeatedly.
func issue_harvest(node: ResourceNode) -> void:
	if not def.can_harvest() or node == null:
		return
	_target = null
	_go_idle()
	_job = HarvestJob.new(self, node)


## Construct (or keep constructing) a building site.
func issue_build(site: Building) -> void:
	if site == null or site.complete or not def.builds.has(site.def):
		return
	_target = null
	_go_idle()
	_job = BuildJob.new(self, site)


func stop() -> void:
	_job = null
	_attack_moving = false
	_go_idle()


## Resources currently carried by a harvesting unit.
func carried() -> int:
	var harvest := _job as HarvestJob
	return harvest.carried if harvest != null else 0


# --- Helpers for HarvestJob (move without cancelling the job) ---------------

func job_move_to(destination: Vector3) -> void:
	_begin_travel(destination, State.MOVING)


func job_stop() -> void:
	_go_idle()


func end_job() -> void:
	_job = null


func is_moving() -> bool:
	return state == State.MOVING


func get_faction() -> StringName:
	return def.faction


func max_health() -> int:
	return def.max_health


func hit_radius() -> float:
	return def.size.x * 0.5


func aim_point() -> Vector3:
	return global_position + Vector3.UP * 0.9


## True once health has fallen below the retreat threshold (never for units
## that don't retreat).
func is_demoralized() -> bool:
	return def.retreat_health_fraction > 0.0 and health < def.max_health * def.retreat_health_fraction


## Hit while idle or on an attack-move: hit back, or flee if too hurt to fight.
func _on_damaged(attacker: Damageable) -> void:
	var can_respond := state == State.IDLE or state == State.ATTACK_MOVING
	if def.can_attack() and can_respond and attacker != null and not attacker.is_dead():
		if is_demoralized():
			_begin_retreat(attacker)
		else:
			_begin_attack(attacker, false)


# --- Simulation tick --------------------------------------------------------

func _physics_process(delta: float) -> void:
	if _dead:
		return
	_cooldown = maxf(0.0, _cooldown - delta)
	# Units on the move take right of way; standing units step aside for them.
	_agent.avoidance_priority = 1.0 if _path_active else STANDING_PRIORITY
	if not _path_active:
		_agent.velocity = Vector3.ZERO ## Keeps avoidance running so we can be nudged.
	match state:
		State.IDLE:
			_tick_idle(delta)
		State.MOVING, State.RETREATING, State.ATTACK_MOVING:
			_tick_travel(delta)
		State.ATTACKING:
			_tick_attack(delta)
	if _job != null and not _dead:
		_job.tick(delta)


func _tick_idle(delta: float) -> void:
	if not def.can_attack():
		return
	_scan_timer -= delta
	if _scan_timer > 0.0:
		return
	_scan_timer = SCAN_INTERVAL
	var enemy := _nearest_enemy(def.acquire_range)
	if enemy == null:
		return
	if is_demoralized():
		_begin_retreat(enemy)
	else:
		_begin_attack(enemy, false)


func _tick_travel(delta: float) -> void:
	if state == State.ATTACK_MOVING:
		_scan_timer -= delta
		if _scan_timer <= 0.0:
			_scan_timer = SCAN_INTERVAL
			var enemy := _nearest_enemy(def.acquire_range, true)
			if enemy != null:
				if is_demoralized():
					_begin_retreat(enemy)
				else:
					_begin_attack(enemy, false)
				return
	if _agent.is_navigation_finished():
		_halt()
		state = State.IDLE
		_attack_moving = false
		_scan_timer = 0.0
		return
	_drive_path()


## A fight is over (target gone or dropped): carry on with the attack-move if
## there is one, otherwise stand still.
func _end_engagement() -> void:
	if _attack_moving:
		_target = null
		_begin_travel(_attack_move_dest, State.ATTACK_MOVING)
	else:
		_go_idle()


func _tick_attack(delta: float) -> void:
	if _target == null or not is_instance_valid(_target) or _target.is_dead():
		_end_engagement()
		return
	var to_target := _target.global_position - global_position
	to_target.y = 0.0
	# Distance to the target's surface, so big buildings can be reached.
	var dist := to_target.length() - _target.hit_radius()
	if not _target_ordered:
		if is_demoralized():
			_begin_retreat(_target)
			return
		if dist > def.acquire_range * LEASH_FACTOR:
			_end_engagement()
			return
	if dist > def.attack_range:
		_repath_timer -= delta
		if _repath_timer <= 0.0:
			_repath_timer = REPATH_INTERVAL
			_agent.target_position = _target.global_position
		_path_active = true
		_drive_path()
		return
	_halt()
	_face(to_target, delta)
	if _cooldown <= 0.0:
		_fire()


func _fire() -> void:
	_cooldown = def.attack_cooldown
	if def.projectile_speed > 0.0:
		var shot := Projectile.new()
		get_parent().add_child(shot)
		shot.launch(global_position + Vector3.UP * 1.2, _target, def.attack_damage, def.projectile_speed, self)
	else:
		_target.take_damage(def.attack_damage, self)


func _begin_attack(enemy: Damageable, ordered: bool) -> void:
	_target = enemy
	_target_ordered = ordered
	_repath_timer = 0.0
	_cooldown = maxf(_cooldown, 0.0)
	state = State.ATTACKING


func _begin_retreat(from: Damageable) -> void:
	var away := global_position - from.global_position
	away.y = 0.0
	away = away.normalized() if away.length() > 0.01 else Vector3.BACK
	_target = null
	_attack_moving = false
	_begin_travel(global_position + away * RETREAT_DISTANCE, State.RETREATING)


func _begin_travel(destination: Vector3, travel_state: State) -> void:
	_agent.target_position = destination
	_path_active = true
	_stall_time = 0.0
	state = travel_state


func _halt() -> void:
	_path_active = false
	_agent.velocity = Vector3.ZERO


func _go_idle() -> void:
	_target = null
	_halt()
	state = State.IDLE
	_scan_timer = 0.0


func _drive_path() -> void:
	if _agent.is_navigation_finished():
		_agent.velocity = Vector3.ZERO
		return
	var to_next := _agent.get_next_path_position() - global_position
	to_next.y = 0.0
	# Feeding the desired velocity runs avoidance; the result arrives in _on_velocity_computed.
	_agent.velocity = to_next.normalized() * def.move_speed


func _on_velocity_computed(safe_velocity: Vector3) -> void:
	if _dead:
		return
	var delta := get_physics_process_delta_time()
	if not _path_active:
		# Standing still: only move if avoidance pushes us out of someone's way.
		var push := Vector3(safe_velocity.x, 0.0, safe_velocity.z)
		if push.length() > NUDGE_MIN_SPEED:
			var nudged := NavigationServer3D.map_get_closest_point(_agent.get_navigation_map(), global_position + push * delta)
			global_position = Vector3(nudged.x, 0.0, nudged.z)
		return
	var flat := Vector3(safe_velocity.x, 0.0, safe_velocity.z)
	# Avoidance knows nothing about walls, so clamp the step back onto the navmesh.
	var next := NavigationServer3D.map_get_closest_point(_agent.get_navigation_map(), global_position + flat * delta)
	global_position = Vector3(next.x, 0.0, next.z)
	if flat.length() > 0.1:
		_face(flat, delta)
	if state == State.MOVING or state == State.RETREATING or state == State.ATTACK_MOVING:
		if flat.length() < def.move_speed * STALL_SPEED_FRACTION:
			_stall_time += delta
			if _stall_time > STALL_SECONDS:
				_halt()
				state = State.IDLE
		else:
			_stall_time = 0.0


func _face(direction: Vector3, delta: float) -> void:
	if direction.length() < 0.01:
		return
	rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), minf(1.0, delta * FACE_TURN_RATE))


## The closest enemy within range. Units are preferred; enemy buildings are
## only considered when `include_buildings` is set (attack-moves).
func _nearest_enemy(max_range: float, include_buildings: bool = false) -> Damageable:
	var best: Damageable = null
	var best_dist := max_range * max_range
	for node in get_tree().get_nodes_in_group(GROUP):
		var other := node as Unit
		if other == null or other == self or other._dead or other.def.faction == def.faction:
			continue
		var d := global_position.distance_squared_to(other.global_position)
		if d < best_dist:
			best_dist = d
			best = other
	if best != null or not include_buildings:
		return best
	for node in get_tree().get_nodes_in_group(Building.GROUP):
		var building := node as Building
		if building == null or building._dead or building.def.faction == def.faction:
			continue
		var gap := maxf(0.0, global_position.distance_to(building.global_position) - building.hit_radius())
		if gap * gap < best_dist:
			best_dist = gap * gap
			best = building
	return best


func _on_death() -> void:
	_path_active = false
	remove_from_group(GROUP)
	selected = false


# --- Placeholder visuals ----------------------------------------------------

func _build_agent() -> void:
	_agent = NavigationAgent3D.new()
	add_child(_agent)
	_agent.radius = def.size.x * 0.5 + 0.1
	_agent.max_speed = def.move_speed
	_agent.path_desired_distance = 0.6
	_agent.target_desired_distance = 0.6
	_agent.avoidance_enabled = true
	_agent.neighbor_distance = 8.0
	_agent.max_neighbors = 10
	_agent.time_horizon_agents = 1.5
	_agent.velocity_computed.connect(_on_velocity_computed)


func _build_placeholder_mesh() -> void:
	var mesh_instance := MeshInstance3D.new()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = def.color
	match def.shape:
		UnitDef.Shape.CAPSULE:
			var capsule := CapsuleMesh.new()
			capsule.radius = def.size.x * 0.5
			capsule.height = def.size.y
			mesh_instance.mesh = capsule
		_:
			var box := BoxMesh.new()
			box.size = def.size
			mesh_instance.mesh = box
	mesh_instance.material_override = mat
	mesh_instance.position.y = def.size.y * 0.5
	add_child(mesh_instance)


func _build_selection_ring() -> void:
	var radius := maxf(def.size.x, def.size.z) * 0.5 + 0.2
	var torus := TorusMesh.new()
	torus.inner_radius = radius
	torus.outer_radius = radius + 0.15
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 1.0, 0.3)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_selection_ring = MeshInstance3D.new()
	_selection_ring.mesh = torus
	_selection_ring.material_override = mat
	_selection_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_selection_ring.position.y = 0.05
	_selection_ring.visible = selected
	add_child(_selection_ring)
