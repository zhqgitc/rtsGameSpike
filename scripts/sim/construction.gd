class_name Construction
extends RefCounted
## Starting a building: pay its cost and put a construction site on the map.
## Shared by the player's placement UI and the AI.


## Returns the new site, or null if the faction cannot afford it.
static func begin(parent: Node, def: BuildingDef, pos: Vector3, economy: Economy, terrain: Terrain) -> Building:
	if not economy.spend(def.faction, def.costs):
		return null
	var site := Building.new()
	parent.add_child(site)
	site.setup(def)
	site.position = pos
	site.begin_construction()
	terrain.rebake()
	return site
