class_name Economy
extends Node
## Resource stockpiles per faction. Resource types are plain ids (e.g.
## &"materials"), so faction-specific resources need no code changes here.

signal changed(faction: StringName, resource: StringName, amount: int)

const GROUP := &"economy"

var _stock: Dictionary = {} ## faction -> { resource -> int }


func _ready() -> void:
	add_to_group(GROUP)


func amount(faction: StringName, resource: StringName) -> int:
	return _stock.get(faction, {}).get(resource, 0)


func add(faction: StringName, resource: StringName, value: int) -> void:
	if value == 0:
		return
	if not _stock.has(faction):
		_stock[faction] = {}
	_stock[faction][resource] = amount(faction, resource) + value
	changed.emit(faction, resource, _stock[faction][resource])


func can_afford(faction: StringName, costs: Dictionary) -> bool:
	for resource in costs:
		if amount(faction, resource) < costs[resource]:
			return false
	return true


## Deduct the costs if affordable. Returns whether it was paid.
func spend(faction: StringName, costs: Dictionary) -> bool:
	if not can_afford(faction, costs):
		return false
	for resource in costs:
		add(faction, resource, -costs[resource])
	return true
