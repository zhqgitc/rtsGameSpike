class_name HarvestJob
extends Job
## A harvester's standing orders: walk to a deposit, gather until full, carry
## the load to the nearest friendly drop-off, repeat. Cancelled by any other
## order given to the unit.

enum Phase { TO_NODE, GATHERING, TO_DROPOFF }

## Margin beyond a deposit's footprint within which a unit counts as at it.
const NODE_REACH_MARGIN := 2.0
## Deposits within this distance of the last one are considered replacements.
const REPLACEMENT_SEARCH_RADIUS := 60.0

var phase: Phase = Phase.TO_NODE
var carried: int = 0

var _unit: Unit
var _node: ResourceNode
var _resource: StringName
var _last_node_position: Vector3
var _gather_progress: float = 0.0
var _dropoff: Building


func _init(unit: Unit, node: ResourceNode) -> void:
	_unit = unit
	_node = node
	_resource = node.resource_type
	_last_node_position = node.global_position


func tick(delta: float) -> void:
	match phase:
		Phase.TO_NODE:
			_tick_to_node()
		Phase.GATHERING:
			_tick_gathering(delta)
		Phase.TO_DROPOFF:
			_tick_to_dropoff()


func _tick_to_node() -> void:
	if not _node_usable(_node):
		_node = _find_node()
		if _node == null:
			# Nothing left to mine: deliver what we have, then stop.
			if carried > 0:
				phase = Phase.TO_DROPOFF
			else:
				_unit.end_job()
			return
	_last_node_position = _node.global_position
	if _flat_distance(_node.global_position) <= _node.radius * 1.45 + NODE_REACH_MARGIN:
		_unit.job_stop()
		_gather_progress = 0.0
		phase = Phase.GATHERING
		return
	if not _unit.is_moving():
		_unit.job_move_to(_node.global_position)


func _tick_gathering(delta: float) -> void:
	if not _node_usable(_node):
		phase = Phase.TO_DROPOFF if carried > 0 else Phase.TO_NODE
		return
	_gather_progress += _unit.def.gather_rate * delta
	var whole := int(_gather_progress)
	if whole <= 0:
		return
	_gather_progress -= whole
	var room := _unit.def.carry_capacity - carried
	carried += _node.extract(mini(whole, room))
	if carried >= _unit.def.carry_capacity or not _node_usable(_node):
		phase = Phase.TO_DROPOFF if carried > 0 else Phase.TO_NODE


func _tick_to_dropoff() -> void:
	if carried <= 0:
		phase = Phase.TO_NODE
		return
	if _dropoff == null or not is_instance_valid(_dropoff):
		_dropoff = _find_dropoff()
		if _dropoff == null:
			_unit.end_job()
			return
	if _flat_distance(_dropoff.global_position) <= _dropoff.reach():
		var economy := _unit.get_tree().get_first_node_in_group(Economy.GROUP) as Economy
		if economy != null:
			economy.add(_unit.def.faction, _resource, roundi(carried * economy.income_factor(_unit.def.faction)))
		carried = 0
		_unit.job_stop()
		phase = Phase.TO_NODE
		return
	if not _unit.is_moving():
		_unit.job_move_to(_dropoff.global_position)


## The deposit may have been used up and freed since we last looked, so the
## parameter is untyped: a freed object cannot be passed as a ResourceNode.
func _node_usable(node: Variant) -> bool:
	return is_instance_valid(node) and (node as ResourceNode).amount > 0


func _find_node() -> ResourceNode:
	var best: ResourceNode = null
	var best_dist := REPLACEMENT_SEARCH_RADIUS * REPLACEMENT_SEARCH_RADIUS
	for candidate in _unit.get_tree().get_nodes_in_group(ResourceNode.GROUP):
		var other := candidate as ResourceNode
		if other == null or other.resource_type != _resource or other.amount <= 0:
			continue
		var d := _last_node_position.distance_squared_to(other.global_position)
		if d < best_dist:
			best_dist = d
			best = other
	return best


func _find_dropoff() -> Building:
	var best: Building = null
	var best_dist := INF
	for candidate in _unit.get_tree().get_nodes_in_group(Building.GROUP):
		var building := candidate as Building
		if building == null or building.def.faction != _unit.def.faction or not building.accepts(_resource):
			continue
		var d := _unit.global_position.distance_squared_to(building.global_position)
		if d < best_dist:
			best_dist = d
			best = building
	return best


func _flat_distance(point: Vector3) -> float:
	var d := point - _unit.global_position
	d.y = 0.0
	return d.length()
