class_name Economy
extends Node
## Resource stockpiles per faction. Resource types are plain ids (e.g.
## &"materials"), so faction-specific resources need no code changes here.

signal changed(faction: StringName, resource: StringName, amount: int)

const GROUP := &"economy"

var _stock: Dictionary = {} ## faction -> { resource -> int }
var _income_factors: Dictionary = {} ## faction -> multiplier on everything it earns (Hard AI cheat)


func _ready() -> void:
	add_to_group(GROUP)


## Multiplier on what a faction harvests and earns (1.0 unless a difficulty says otherwise).
func income_factor(faction: StringName) -> float:
	return _income_factors.get(faction, 1.0)


func set_income_factor(faction: StringName, factor: float) -> void:
	_income_factors[faction] = factor


func amount(faction: StringName, resource: StringName) -> int:
	return _stock.get(faction, {}).get(resource, 0)


func add(faction: StringName, resource: StringName, value: int) -> void:
	if value == 0:
		return
	if not _stock.has(faction):
		_stock[faction] = {}
	_stock[faction][resource] = amount(faction, resource) + value
	changed.emit(faction, resource, _stock[faction][resource])


## Population cap from finished buildings (Manpower).
func pop_cap(faction: StringName) -> int:
	var total := 0
	for node in get_tree().get_nodes_in_group(Building.GROUP):
		var building := node as Building
		if building != null and building.complete and building.def.faction == faction:
			total += building.def.pop_provided
	return total


## Population occupied by living units plus units queued for training.
func pop_used(faction: StringName) -> int:
	var total := 0
	for node in get_tree().get_nodes_in_group(Unit.GROUP):
		var unit := node as Unit
		if unit != null and unit.def.faction == faction:
			total += unit.def.pop_cost
	for node in get_tree().get_nodes_in_group(Building.GROUP):
		var building := node as Building
		if building != null and building.def.faction == faction:
			total += building.queued_pop()
	return total


## Empty if the costs are affordable, otherwise e.g. "Not enough Materials (need 150, have 80)".
func shortfall(faction: StringName, costs: Dictionary) -> String:
	for resource in costs:
		var have := amount(faction, resource)
		if have < costs[resource]:
			return "Not enough %s (need %d, have %d)" % [String(resource).capitalize(), costs[resource], have]
	return ""


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
