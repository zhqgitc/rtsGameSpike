class_name Unit
extends Node3D
## A unit in the world: health, move/attack orders, automatic engagement and
## retreat, pathing over the navigation mesh (with avoidance), plus placeholder
## visuals. All behaviour runs in _physics_process (the fixed simulation tick).

signal health_changed(current: int, maximum: int)
signal died(unit: Unit)

enum State { IDLE, MOVING, ATTACKING, RETREATING }

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

static var _spawn_counter: int = 0

var def: UnitDef
var health: int = 0
var state: State = State.IDLE
var selected: bool = false:
	set(value):
		selected = value
		if _selection_ring:
			_selection_ring.visible = value

var _agent: NavigationAgent3D
var _selection_ring: MeshInstance3D
var _target: Unit
var _target_ordered: bool = false ## Player-ordered targets are never dropped automatically.
var _path_active: bool = false
var _dead: bool = false
var _cooldown: float = 0.0
var _scan_timer: float = 0.0
var _repath_timer: float = 0.0
var _stall_time: float = 0.0
var _job: HarvestJob


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
	_begin_travel(target, State.MOVING)


## Attack a specific unit, chasing it as needed. Stays on it until it dies.
func issue_attack(enemy: Unit) -> void:
	if not def.can_attack() or enemy == null or enemy == self or enemy._dead:
		return
	_job = null
	_begin_attack(enemy, true)


## Gather from a deposit and deliver to the nearest drop-off, repeatedly.
func issue_harvest(node: ResourceNode) -> void:
	if not def.can_harvest() or node == null:
		return
	_target = null
	_go_idle()
	_job = HarvestJob.new(self, node)


func stop() -> void:
	_job = null
	_go_idle()


## Resources currently carried by a harvesting unit.
func carried() -> int:
	return _job.carried if _job != null else 0


# --- Helpers for HarvestJob (move without cancelling the job) ---------------

func job_move_to(destination: Vector3) -> void:
	_begin_travel(destination, State.MOVING)


func job_stop() -> void:
	_go_idle()


func end_job() -> void:
	_job = null


func is_moving() -> bool:
	return state == State.MOVING


func is_dead() -> bool:
	return _dead


## True once health has fallen below the retreat threshold (never for units
## that don't retreat).
func is_demoralized() -> bool:
	return def.retreat_health_fraction > 0.0 and health < def.max_health * def.retreat_health_fraction


func take_damage(amount: int, attacker: Unit) -> void:
	if _dead:
		return
	health = maxi(0, health - amount)
	health_changed.emit(health, def.max_health)
	if health <= 0:
		_die()
		return
	# Hit while idle: hit back, or flee if too hurt to fight.
	if def.can_attack() and state == State.IDLE and attacker != null and not attacker.is_dead():
		if is_demoralized():
			_begin_retreat(attacker)
		else:
			_begin_attack(attacker, false)


# --- Simulation tick --------------------------------------------------------

func _physics_process(delta: float) -> void:
	if _dead:
		return
	_cooldown = maxf(0.0, _cooldown - delta)
	match state:
		State.IDLE:
			_tick_idle(delta)
		State.MOVING, State.RETREATING:
			_tick_travel()
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


func _tick_travel() -> void:
	if _agent.is_navigation_finished():
		_halt()
		state = State.IDLE
		_scan_timer = 0.0
		return
	_drive_path()


func _tick_attack(delta: float) -> void:
	if _target == null or not is_instance_valid(_target) or _target.is_dead():
		_go_idle()
		return
	var to_target := _target.global_position - global_position
	to_target.y = 0.0
	var dist := to_target.length()
	if not _target_ordered:
		if is_demoralized():
			_begin_retreat(_target)
			return
		if dist > def.acquire_range * LEASH_FACTOR:
			_go_idle()
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


func _begin_attack(enemy: Unit, ordered: bool) -> void:
	_target = enemy
	_target_ordered = ordered
	_repath_timer = 0.0
	_cooldown = maxf(_cooldown, 0.0)
	state = State.ATTACKING


func _begin_retreat(from: Unit) -> void:
	var away := global_position - from.global_position
	away.y = 0.0
	away = away.normalized() if away.length() > 0.01 else Vector3.BACK
	_target = null
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
	if not _path_active or _dead:
		return
	var delta := get_physics_process_delta_time()
	var flat := Vector3(safe_velocity.x, 0.0, safe_velocity.z)
	# Avoidance knows nothing about walls, so clamp the step back onto the navmesh.
	var next := NavigationServer3D.map_get_closest_point(_agent.get_navigation_map(), global_position + flat * delta)
	global_position = Vector3(next.x, 0.0, next.z)
	if flat.length() > 0.1:
		_face(flat, delta)
	if state == State.MOVING or state == State.RETREATING:
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


func _nearest_enemy(max_range: float) -> Unit:
	var best: Unit = null
	var best_dist := max_range * max_range
	for node in get_tree().get_nodes_in_group(GROUP):
		var other := node as Unit
		if other == null or other == self or other._dead or other.def.faction == def.faction:
			continue
		var d := global_position.distance_squared_to(other.global_position)
		if d < best_dist:
			best_dist = d
			best = other
	return best


func _die() -> void:
	_dead = true
	_path_active = false
	remove_from_group(GROUP)
	selected = false
	died.emit(self)
	queue_free()


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
