class_name Placement
extends RefCounted
## Rules for where a building may be placed.

## Free space kept around buildings so units can walk between them.
const MARGIN := 1.0


## Returns an empty string if the building may be placed centred at `pos`,
## otherwise a short human-readable reason why not.
static func check(tree: SceneTree, def: BuildingDef, pos: Vector3) -> String:
	var half := Vector2(def.size.x, def.size.z) * 0.5
	var rect := Rect2(Vector2(pos.x, pos.z) - half, half * 2.0).grow(MARGIN)

	var fog := tree.get_first_node_in_group(FogOfWar.GROUP) as FogOfWar
	if fog != null and not fog.is_explored_at(pos):
		return "Unexplored area"

	var terrain := tree.get_first_node_in_group(Terrain.GROUP) as Terrain
	if terrain != null:
		var limit := terrain.map_size * 0.5
		if absf(pos.x) + half.x > limit.x or absf(pos.z) + half.y > limit.y:
			return "Outside the map"
		for obstacle in terrain.obstacles:
			if rect.intersects(obstacle):
				return "Blocked by terrain"

	for node in tree.get_nodes_in_group(Building.GROUP):
		var other := node as Building
		if other != null and rect.intersects(other.footprint()):
			return "Too close to another building"

	for node in tree.get_nodes_in_group(ResourceNode.GROUP):
		var deposit := node as ResourceNode
		if deposit == null:
			continue
		var d := Vector2(deposit.global_position.x, deposit.global_position.z)
		if rect.intersects(Rect2(d - Vector2.ONE * deposit.radius, Vector2.ONE * deposit.radius * 2.0)):
			return "Blocked by a deposit"

	if def.max_distance_from_hq > 0.0 and not _near_friendly_hq(tree, def, pos):
		return "Outside the planned zone (too far from HQ)"
	return ""


static func _near_friendly_hq(tree: SceneTree, def: BuildingDef, pos: Vector3) -> bool:
	for node in tree.get_nodes_in_group(Building.GROUP):
		var hq := node as Building
		if hq == null or not hq.def.is_hq or not hq.complete or hq.def.faction != def.faction:
			continue
		var offset := hq.global_position - pos
		offset.y = 0.0
		if offset.length() <= def.max_distance_from_hq:
			return true
	return false
