class_name MatchRules
extends Node
## Decides when the game is over. A faction loses when its HQ is destroyed.

signal match_ended(winner: StringName, loser: StringName)

const FACTIONS: Array[StringName] = [&"collectivists", &"libertarians"]

var ended: bool = false


## Call when any building has been destroyed.
func building_destroyed(building: Building) -> void:
	if ended or building == null or not building.def.is_hq:
		return
	ended = true
	var loser := building.def.faction
	var winner := FACTIONS[1] if loser == FACTIONS[0] else FACTIONS[0]
	match_ended.emit(winner, loser)
