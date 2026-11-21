class_name Projectile
extends Node3D
## A shot in flight. Homes in on its target and applies damage on arrival.
## Fizzles out if the target dies first or after a maximum lifetime.

const MAX_LIFETIME := 4.0
const HIT_DISTANCE := 0.6
const AIM_HEIGHT := 0.9

var _target: Unit
var _attacker: Unit
var _damage: int = 0
var _speed: float = 20.0
var _age: float = 0.0


func launch(from: Vector3, target: Unit, damage: int, speed: float, attacker: Unit) -> void:
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
	var aim := _target.global_position + Vector3.UP * AIM_HEIGHT
	var to_target := aim - global_position
	var step := _speed * delta
	if to_target.length() <= maxf(step, HIT_DISTANCE):
		_target.take_damage(_damage, _attacker if is_instance_valid(_attacker) else null)
		queue_free()
		return
	global_position += to_target.normalized() * step


func _build_visual() -> void:
	var sphere := SphereMesh.new()
	sphere.radius = 0.15
	sphere.height = 0.3
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.95, 0.4)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = sphere
	mesh_instance.material_override = mat
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh_instance)
