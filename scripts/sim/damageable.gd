class_name Damageable
extends Node3D
## Anything combat can hit: units and buildings. Holds health and the common
## damage/death flow; subclasses say who they belong to, how big they are and
## what happens when they are hurt or destroyed.

signal health_changed(current: int, maximum: int)
signal died(target: Damageable)

var health: int = 0
var _dead: bool = false


func is_dead() -> bool:
	return _dead


## Which faction this belongs to.
func get_faction() -> StringName:
	return &""


func max_health() -> int:
	return 1


## Radius used for range checks: attackers reach a target when the distance to
## its centre minus this is within their weapon range.
func hit_radius() -> float:
	return 0.5


## Where projectiles aim.
func aim_point() -> Vector3:
	return global_position + Vector3.UP


func take_damage(amount: int, attacker: Damageable) -> void:
	if _dead:
		return
	health = maxi(0, health - amount)
	health_changed.emit(health, max_health())
	if health <= 0:
		_dead = true
		_on_death()
		died.emit(self)
		queue_free()
	else:
		_on_damaged(attacker)


func _on_damaged(_attacker: Damageable) -> void:
	pass


func _on_death() -> void:
	pass
