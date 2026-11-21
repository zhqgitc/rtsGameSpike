class_name Unit
extends Node3D
## A unit in the world. Holds its definition, follows move orders over the
## navigation mesh (with avoidance) and builds placeholder visuals.
## Movement runs in _physics_process (the fixed simulation tick).

const GROUP := &"units"
## A unit that barely moves for this long while ordered to move gives up.
const STALL_SECONDS := 1.0
const STALL_SPEED_FRACTION := 0.2

var def: UnitDef
var selected: bool = false:
	set(value):
		selected = value
		if _selection_ring:
			_selection_ring.visible = value

var _agent: NavigationAgent3D
var _selection_ring: MeshInstance3D
var _moving: bool = false
var _stall_time: float = 0.0


func setup(unit_def: UnitDef) -> void:
	def = unit_def
	name = "%s_%d" % [def.id, get_instance_id()]
	add_to_group(GROUP)
	_build_placeholder_mesh()
	_build_selection_ring()
	_build_agent()


## Order the unit to walk to a point on the ground.
func issue_move(target: Vector3) -> void:
	_agent.target_position = target
	_moving = true
	_stall_time = 0.0


func stop() -> void:
	_moving = false
	_agent.velocity = Vector3.ZERO


func is_moving() -> bool:
	return _moving


func _physics_process(_delta: float) -> void:
	if not _moving:
		return
	if _agent.is_navigation_finished():
		stop()
		return
	var to_next := _agent.get_next_path_position() - global_position
	to_next.y = 0.0
	# Feeding the desired velocity runs avoidance; the result arrives in _on_velocity_computed.
	_agent.velocity = to_next.normalized() * def.move_speed


func _on_velocity_computed(safe_velocity: Vector3) -> void:
	if not _moving:
		return
	var delta := get_physics_process_delta_time()
	var flat := Vector3(safe_velocity.x, 0.0, safe_velocity.z)
	# Avoidance knows nothing about walls, so clamp the step back onto the navmesh.
	var next := NavigationServer3D.map_get_closest_point(_agent.get_navigation_map(), global_position + flat * delta)
	global_position = Vector3(next.x, 0.0, next.z)
	if flat.length() > 0.1:
		rotation.y = lerp_angle(rotation.y, atan2(-flat.x, -flat.z), minf(1.0, delta * 10.0))
	if flat.length() < def.move_speed * STALL_SPEED_FRACTION:
		_stall_time += delta
		if _stall_time > STALL_SECONDS:
			stop()
	else:
		_stall_time = 0.0


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
