class_name UnitModel
extends Node3D
## A unit's body and its animation. UnitArt builds the parts; this node animates
## them from what the unit is doing: walking, aiming, firing (recoil and muzzle
## flash) or thrusting, and working with a tool. It only reads the unit; the
## simulation does not know it exists. The model faces -Z, like the unit.

const FLASH_SECONDS := 0.07
const WALK_SPEED_THRESHOLD := 0.4

# Parts, filled in by UnitArt.
var leg_left: Node3D
var leg_right: Node3D
var arm_left: Node3D
var arm_right: Node3D
var body: Node3D ## Torso, head and gear: bobs, sways and takes the recoil.
var weapon: Node3D ## Held weapon (rifle, ...), or null for tool users.
var tool_node: Node3D ## Held tool (shovel, pickaxe), parented to the right arm.
var flash: MeshInstance3D ## Muzzle flash, hidden except just after a shot.
var melee: bool = false ## Thrusts instead of shooting.
var stride: float = 1.0 ## How big the walking motion is (heavier units swing less).

var _unit: Unit
var _last_position: Vector3
var _speed: float = 0.0
var _phase: float = 0.0
var _clock: float = 0.0
var _kick: float = 0.0
var _flash_left: float = 0.0
var _clock_offset: float = 0.0


func setup(unit: Unit) -> void:
	_unit = unit
	_last_position = unit.global_position
	# Spread idle motion so a crowd does not breathe in step.
	_clock_offset = float(unit.get_instance_id() % 97)
	unit.fired.connect(_on_fired)
	if flash != null:
		flash.visible = false


func _process(delta: float) -> void:
	if _unit == null or not is_instance_valid(_unit):
		return
	_clock += delta
	var position_now := _unit.global_position
	var moved := Vector2(position_now.x - _last_position.x, position_now.z - _last_position.z).length()
	_last_position = position_now
	_speed = lerpf(_speed, moved / maxf(delta, 0.0001), minf(1.0, delta * 10.0))

	var walking := _speed > WALK_SPEED_THRESHOLD
	var firing := _unit.state == Unit.State.ATTACKING and not walking
	var working := _unit.job_kind() != &"" and not walking

	_animate_legs(delta, walking)
	_animate_arms(delta, walking, firing, working)
	_animate_body(delta, walking)
	_animate_effects(delta)


func _animate_legs(delta: float, walking: bool) -> void:
	if walking:
		_phase += delta * (5.0 + _speed * 1.4)
	var swing := sin(_phase) * 0.7 * stride * clampf(_speed / 3.0, 0.0, 1.3) if walking else 0.0
	_ease_rotation(leg_left, swing, delta)
	_ease_rotation(leg_right, -swing, delta)


func _animate_arms(delta: float, walking: bool, firing: bool, working: bool) -> void:
	var right := 0.9
	var left := 1.1
	if tool_node != null:
		# Carry the tool at rest, swing it while working.
		right = 0.3
		left = 0.1
		if working:
			right = 1.0 + sin((_clock + _clock_offset) * 7.0) * 0.75
			left = 0.5
		elif walking:
			left = -sin(_phase) * 0.5 * stride
	elif weapon != null:
		if firing:
			right = 1.45
			left = 1.5
		elif walking:
			right = 0.95
			left = 1.15
	_ease_rotation(arm_right, right, delta)
	_ease_rotation(arm_left, left, delta)


func _animate_body(delta: float, walking: bool) -> void:
	var t := _clock + _clock_offset
	var bob := absf(sin(_phase)) * 0.045 * stride if walking else sin(t * 1.8) * 0.008
	body.position.y = lerpf(body.position.y, 0.78 + bob, minf(1.0, delta * 14.0))
	# Recoil kicks the body back; a melee lunge thrusts the whole figure forward.
	_kick = maxf(0.0, _kick - delta * 7.0)
	if melee:
		position.z = -_kick * 0.45
		body.rotation.x = _kick * 0.2
	else:
		body.position.z = _kick * 0.1
		if weapon != null:
			weapon.rotation.x = -_kick * 0.18


func _animate_effects(delta: float) -> void:
	if flash == null:
		return
	_flash_left = maxf(0.0, _flash_left - delta)
	flash.visible = _flash_left > 0.0


func _on_fired() -> void:
	_kick = 1.0
	if flash != null and not melee:
		_flash_left = FLASH_SECONDS


func _ease_rotation(part: Node3D, target_x: float, delta: float) -> void:
	if part != null:
		part.rotation.x = lerpf(part.rotation.x, target_x, minf(1.0, delta * 12.0))
