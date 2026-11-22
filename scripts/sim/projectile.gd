class_name Projectile
extends Node3D
## A shot in flight. Homes in on its target and applies damage on arrival.
## Fizzles out if the target dies first or after a maximum lifetime.

const MAX_LIFETIME := 4.0
const HIT_DISTANCE := 0.6

var _target: Damageable
var _attacker: Damageable
var _damage: int = 0
var _speed: float = 20.0
var _age: float = 0.0


func launch(from: Vector3, target: Damageable, damage: int, speed: float, attacker: Damageable) -> void:
	position = from
	_target = target
	_damage = damage
	_speed = speed
	_attacker = attacker
	_build_visual()


func _physics_process(delta: float) -> void:
	_age += delta
	if _age > MAX_LIFETIME or not is_instance_valid(_target) or _target.is_dead():
		queue_free()
		return
	var to_target := _target.aim_point() - global_position
	var step := _speed * delta
	# Big targets (buildings) are hit at their surface, not at their centre.
	if to_target.length() <= maxf(step, HIT_DISTANCE + _target.hit_radius() * 0.5):
		_target.take_damage(_damage, _attacker if is_instance_valid(_attacker) else null)
		queue_free()
		return
	var direction := to_target.normalized()
	if absf(direction.y) < 0.98:
		look_at(global_position + direction, Vector3.UP)
	global_position += direction * step


## A glowing tracer streak that points along its flight.
func _build_visual() -> void:
	var streak := CapsuleMesh.new()
	streak.radius = 0.045
	streak.height = 1.1
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.9, 0.5)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.75, 0.25)
	mat.emission_energy_multiplier = 3.0
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = streak
	mesh_instance.material_override = mat
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh_instance.rotation.x = PI * 0.5 # the capsule's axis lies along the flight direction (-Z)
	add_child(mesh_instance)
