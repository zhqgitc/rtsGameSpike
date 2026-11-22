class_name Session
extends Node
## Who the human player is. Everything that is "yours" (selection, HUD,
## commands) keys off player_faction; the other faction is the opponent.

signal faction_chosen(faction: StringName)

const GROUP := &"session"

var player_faction: StringName = &""
## How hard the opponent plays (see data/ai/difficulty_*.tres); chosen on the start screen.
var difficulty: StringName = &"normal"


func _ready() -> void:
	add_to_group(GROUP)


static func find(tree: SceneTree) -> Session:
	return tree.get_first_node_in_group(GROUP) as Session


func choose(faction: StringName) -> void:
	player_faction = faction
	faction_chosen.emit(faction)


func is_player(faction: StringName) -> bool:
	return faction == player_faction
