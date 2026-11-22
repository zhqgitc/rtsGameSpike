class_name Effects
extends Node3D
## Visual effects: hit sparks, dust, falling bodies, building collapses, smoke,
## and order markers. Purely presentation: the simulation never waits for or
## reads any of this. Effects the player cannot currently see (fog of war) are
## not spawned.

const GROUP := &"effects"
const MAX_CORPSES := 36
const CORPSE_SECONDS := 14.0
const RUBBLE_SECONDS := 70.0

static var _soft_texture: GradientTexture2D

var _corpses: Array[Node3D] = []


static func find(tree: SceneTree) -> Effects:
	return tree.get_first_node_in_group(GROUP) as Effects


func _ready() -> void:
	add_to_group(GROUP)


# --- Combat -----------------------------------------------------------------

## A small burst of sparks where something was hit.
func hit_spark(pos: Vector3) -> void:
	if not _can_see(pos):
		return
	var sparks := spark_emitter()
	sparks.position = pos
	_add_and_free(sparks, 0.5)


## A puff of dust (settling rubble, a body hitting the ground, ...).
func dust_puff(pos: Vector3, radius: float = 1.0, amount: int = 12) -> void:
	if not _can_see(pos):
		return
	var puff := dust_emitter(amount, radius)
	puff.position = pos
	_add_and_free(puff, 2.0)


## A unit dies: it falls over, kicks up a little dust and lies there a while.
func unit_death(unit: Unit) -> void:
	var pos := unit.global_position
	if not _can_see(pos):
		return
	dust_puff(pos + Vector3.UP * 0.2, 0.6, 8)
	var corpse := UnitArt.build(unit.def, unit.get_instance_id())
	corpse.position = pos
	corpse.rotation = unit.rotation
	add_child(corpse)
	_corpses.append(corpse)
	while _corpses.size() > MAX_CORPSES:
		var oldest: Node3D = _corpses.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()
	# Fall backwards, rest, then sink into the ground.
	var tween := create_tween()
	tween.tween_property(corpse, "rotation:x", corpse.rotation.x + deg_to_rad(-88.0), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_interval(CORPSE_SECONDS)
	tween.tween_property(corpse, "position:y", pos.y - 0.9, 3.0)
	tween.tween_callback(corpse.queue_free)


# --- Buildings --------------------------------------------------------------

## A building comes down: dust, flying debris, a rubble pile, a column of smoke
## and a shake of the camera.
func building_collapse(pos: Vector3, footprint: Vector2, height: float) -> void:
	if not _can_see(pos):
		return
	var radius := maxf(footprint.x, footprint.y) * 0.5
	# Dust: one big cloud and a ring.
	var cloud := dust_emitter(40, radius * 0.9)
	cloud.position = pos + Vector3.UP * 0.6
	_add_and_free(cloud, 2.2)
	var ring := dust_emitter(26, radius * 1.3)
	ring.position = pos + Vector3.UP * height * 0.4
	_add_and_free(ring, 2.2)
	# Debris thrown out, then lying around as rubble.
	var rubble := Node3D.new()
	rubble.position = pos
	add_child(rubble)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var chunk_count := clampi(int(radius * 4.0), 14, 40)
	for i in chunk_count:
		var chunk := DebrisChunk.new()
		var size := rng.randf_range(0.25, 0.9)
		var mesh := BoxMesh.new()
		mesh.size = Vector3(size, size * rng.randf_range(0.4, 1.0), size * rng.randf_range(0.6, 1.2))
		chunk.mesh = mesh
		var shade := rng.randf_range(0.2, 0.4)
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(shade, shade * 0.97, shade * 0.93)
		material.roughness = 0.95
		chunk.material_override = material
		rubble.add_child(chunk)
		var start := Vector3(rng.randf_range(-1.0, 1.0) * footprint.x * 0.4, rng.randf_range(0.3, 1.0) * height * 0.6, rng.randf_range(-1.0, 1.0) * footprint.y * 0.4)
		chunk.position = start
		var outward := Vector3(start.x, 0.0, start.z).normalized()
		chunk.velocity = outward * rng.randf_range(1.5, 5.5) + Vector3(0.0, rng.randf_range(2.0, 7.0), 0.0)
		chunk.spin = Vector3(rng.randf_range(-6.0, 6.0), rng.randf_range(-6.0, 6.0), rng.randf_range(-6.0, 6.0))
	# A heap of larger pieces stays where the building stood.
	for i in 7:
		var piece := MeshInstance3D.new()
		piece.mesh = RockMesh.create(99)
		var heap_material := StandardMaterial3D.new()
		heap_material.albedo_color = Color(0.25, 0.25, 0.24)
		heap_material.roughness = 0.95
		piece.material_override = heap_material
		var scale_xz := rng.randf_range(0.9, 1.6) * radius * 0.35
		piece.scale = Vector3(scale_xz, scale_xz * rng.randf_range(0.4, 0.7), scale_xz)
		piece.position = Vector3(rng.randf_range(-1.0, 1.0) * footprint.x * 0.3, scale_xz * 0.2, rng.randf_range(-1.0, 1.0) * footprint.y * 0.3)
		piece.rotation.y = rng.randf() * TAU
		rubble.add_child(piece)
	var tween := create_tween()
	tween.tween_interval(RUBBLE_SECONDS)
	tween.tween_property(rubble, "scale", Vector3(1.0, 0.02, 1.0), 4.0)
	tween.tween_callback(rubble.queue_free)
	# Smoke rising from the ruin.
	var smoke := smoke_emitter(26, 4.0, 1.6)
	smoke.position = pos + Vector3.UP * 1.0
	add_child(smoke)
	get_tree().create_timer(22.0).timeout.connect(func() -> void:
		if is_instance_valid(smoke):
			smoke.emitting = false
			get_tree().create_timer(5.0).timeout.connect(smoke.queue_free))
	_shake_camera(pos, 0.7 + radius * 0.06)


# --- Orders -----------------------------------------------------------------

## A ring on the ground where an order was given; grows and fades.
func order_marker(pos: Vector3, color: Color) -> void:
	var torus := TorusMesh.new()
	torus.inner_radius = 0.55
	torus.outer_radius = 0.72
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var ring := MeshInstance3D.new()
	ring.mesh = torus
	ring.material_override = material
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.position = Vector3(pos.x, 0.12, pos.z)
	ring.scale = Vector3.ONE * 0.5
	add_child(ring)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(ring, "scale", Vector3.ONE * 1.5, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(material, "albedo_color:a", 0.0, 0.55)
	tween.chain().tween_callback(ring.queue_free)


# --- Emitter builders (also used by BuildingFX) ------------------------------

static func spark_emitter() -> CPUParticles3D:
	var p := _particles(10, 0.3, true)
	p.direction = Vector3.UP
	p.spread = 70.0
	p.initial_velocity_min = 2.5
	p.initial_velocity_max = 6.0
	p.gravity = Vector3(0, -14, 0)
	p.scale_amount_min = 0.05
	p.scale_amount_max = 0.11
	p.color_ramp = _ramp([Color(1.0, 0.95, 0.6, 1.0), Color(1.0, 0.55, 0.15, 0.9), Color(0.6, 0.2, 0.05, 0.0)])
	p.mesh = _soft_quad(true)
	return p


static func dust_emitter(amount: int, radius: float) -> CPUParticles3D:
	var p := _particles(amount, 1.4, true)
	p.direction = Vector3.UP
	p.spread = 80.0
	p.initial_velocity_min = 0.4 * radius
	p.initial_velocity_max = 1.8 * radius
	p.gravity = Vector3(0, 0.4, 0)
	p.damping_min = 1.0
	p.damping_max = 2.0
	p.scale_amount_min = 0.5 * radius
	p.scale_amount_max = 1.1 * radius
	p.scale_amount_curve = _growth_curve(0.5, 1.7)
	p.color_ramp = _ramp([Color(0.5, 0.44, 0.36, 0.55), Color(0.42, 0.38, 0.32, 0.35), Color(0.35, 0.32, 0.28, 0.0)])
	p.mesh = _soft_quad(false)
	return p


static func smoke_emitter(amount: int, lifetime: float, size: float) -> CPUParticles3D:
	var p := _particles(amount, lifetime, false)
	p.direction = Vector3.UP
	p.spread = 14.0
	p.initial_velocity_min = 1.0
	p.initial_velocity_max = 2.2
	p.gravity = Vector3(0.4, 0.5, 0)
	p.scale_amount_min = 0.6 * size
	p.scale_amount_max = 1.1 * size
	p.scale_amount_curve = _growth_curve(0.5, 2.2)
	p.color_ramp = _ramp([Color(0.2, 0.19, 0.18, 0.0), Color(0.2, 0.19, 0.18, 0.55), Color(0.3, 0.29, 0.28, 0.0)])
	p.mesh = _soft_quad(false)
	return p


static func fire_emitter() -> CPUParticles3D:
	var p := _particles(18, 0.7, false)
	p.direction = Vector3.UP
	p.spread = 18.0
	p.initial_velocity_min = 1.2
	p.initial_velocity_max = 2.6
	p.gravity = Vector3(0, 1.5, 0)
	p.scale_amount_min = 0.7
	p.scale_amount_max = 1.2
	p.scale_amount_curve = _growth_curve(1.0, 0.3)
	p.color_ramp = _ramp([Color(1.0, 0.65, 0.18, 0.5), Color(1.0, 0.32, 0.05, 0.4), Color(0.3, 0.1, 0.05, 0.0)])
	p.mesh = _soft_quad(true)
	return p


# --- Internals ---------------------------------------------------------------

static func _particles(amount: int, lifetime: float, one_shot: bool) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = amount
	p.lifetime = lifetime
	p.one_shot = one_shot
	p.explosiveness = 1.0 if one_shot else 0.0
	p.emitting = true
	p.local_coords = false
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return p


static func _ramp(colors: Array[Color]) -> Gradient:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray(colors)
	var offsets := PackedFloat32Array()
	for i in colors.size():
		offsets.append(float(i) / float(colors.size() - 1))
	gradient.offsets = offsets
	return gradient


static func _growth_curve(from: float, to: float) -> Curve:
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, from))
	curve.add_point(Vector2(1.0, to))
	return curve


## A camera-facing quad with a soft round texture; `glow` makes it unshaded
## and bright (sparks, fire) instead of dull (dust, smoke).
static func _soft_quad(glow: bool) -> QuadMesh:
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	var material := StandardMaterial3D.new()
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.billboard_keep_scale = true
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = _get_soft_texture()
	if glow:
		material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	quad.material = material
	return quad


static func _get_soft_texture() -> GradientTexture2D:
	if _soft_texture != null:
		return _soft_texture
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	gradient.offsets = PackedFloat32Array([0.0, 1.0])
	_soft_texture = GradientTexture2D.new()
	_soft_texture.gradient = gradient
	_soft_texture.fill = GradientTexture2D.FILL_RADIAL
	_soft_texture.fill_from = Vector2(0.5, 0.5)
	_soft_texture.fill_to = Vector2(1.0, 0.5)
	_soft_texture.width = 64
	_soft_texture.height = 64
	return _soft_texture


func _add_and_free(emitter: CPUParticles3D, seconds: float) -> void:
	add_child(emitter)
	get_tree().create_timer(seconds).timeout.connect(emitter.queue_free)


## Effects the player cannot see (fogged ground) are not shown at all.
func _can_see(pos: Vector3) -> bool:
	var fog := get_tree().get_first_node_in_group(FogOfWar.GROUP) as FogOfWar
	return fog == null or fog.is_visible_at(pos)


func _shake_camera(pos: Vector3, strength: float) -> void:
	var camera := get_tree().get_first_node_in_group(RTSCamera.GROUP) as RTSCamera
	if camera != null:
		camera.shake(strength / (1.0 + camera.global_position.distance_to(pos) / 35.0))


## A piece of wreckage thrown out of a collapsing building: flies, tumbles,
## lands and stays put.
class DebrisChunk extends MeshInstance3D:
	var velocity: Vector3 = Vector3.ZERO
	var spin: Vector3 = Vector3.ZERO
	var _landed: bool = false

	func _process(delta: float) -> void:
		if _landed:
			return
		velocity.y -= 18.0 * delta
		position += velocity * delta
		rotation += spin * delta
		# `position` is relative to the rubble node, which sits on the ground.
		if position.y <= 0.12 and velocity.y < 0.0:
			position.y = 0.12
			_landed = true
			set_process(false)
