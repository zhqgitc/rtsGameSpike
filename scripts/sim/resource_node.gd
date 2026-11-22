class_name ResourceNode
extends Node3D
## A deposit harvesters can gather from. Shrinks as it is mined and vanishes
## when empty. Acts as an obstacle on the navigation mesh.

signal depleted

const GROUP := &"resource_nodes"

@export var resource_type: StringName = &"materials"
@export var amount: int = 400
## Footprint half-width; units gather from within radius + a little reach.
@export var radius: float = 1.5

var _initial_amount: int = 0
var _model: Node3D


func _ready() -> void:
	_initial_amount = amount
	add_to_group(GROUP)
	_build()


## Take up to `wanted` from the deposit; returns what was actually taken.
func extract(wanted: int) -> int:
	var taken := mini(wanted, amount)
	amount -= taken
	_update_visual()
	if amount <= 0:
		remove_from_group(GROUP)
		queue_free()
		depleted.emit()
	return taken


func _build() -> void:
	_model = DepositArt.build(radius, get_instance_id())
	add_child(_model)

	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var collider := BoxShape3D.new()
	collider.size = Vector3(radius * 2.0, 1.6, radius * 2.0)
	shape.shape = collider
	body.add_child(shape)
	body.add_to_group(Terrain.NAV_SOURCE_GROUP)
	add_child(body)
	body.position.y = 0.8
	_update_visual()


## The heap shrinks as it is mined: lower first, then narrower.
func _update_visual() -> void:
	if _model == null:
		return
	var fraction := clampf(float(amount) / float(maxi(_initial_amount, 1)), 0.0, 1.0)
	_model.scale = Vector3(lerpf(0.6, 1.0, fraction), lerpf(0.3, 1.0, fraction), lerpf(0.6, 1.0, fraction))
