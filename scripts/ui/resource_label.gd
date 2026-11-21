class_name ResourceLabel
extends Label
## Temporary readout of each faction's stockpile, until the real HUD (M5).

const FACTIONS: Array[StringName] = [&"collectivists", &"libertarians"]
const RESOURCES: Array[StringName] = [&"materials"]

var _economy: Economy


func _ready() -> void:
	add_theme_font_size_override("font_size", 20)
	add_theme_color_override("font_outline_color", Color.BLACK)
	add_theme_constant_override("outline_size", 6)
	_economy = get_tree().get_first_node_in_group(Economy.GROUP) as Economy
	if _economy:
		_economy.changed.connect(func(_f: StringName, _r: StringName, _a: int) -> void: _refresh())
	_refresh()


func _refresh() -> void:
	var lines: Array[String] = []
	for faction in FACTIONS:
		var parts: Array[String] = []
		for resource in RESOURCES:
			var value := _economy.amount(faction, resource) if _economy else 0
			parts.append("%s %d" % [String(resource).capitalize(), value])
		lines.append("%s: %s" % [String(faction).capitalize(), ", ".join(parts)])
	text = "\n".join(lines)
