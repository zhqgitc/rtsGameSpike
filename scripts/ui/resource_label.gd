class_name ResourceLabel
extends Label
## Temporary readout of each faction's stockpile, until the real HUD (M5).

const REFRESH_INTERVAL := 0.4

var _economy: Economy
var _since_refresh: float = 0.0


func _ready() -> void:
	add_theme_font_size_override("font_size", 20)
	add_theme_color_override("font_outline_color", Color.BLACK)
	add_theme_constant_override("outline_size", 6)
	_economy = get_tree().get_first_node_in_group(Economy.GROUP) as Economy
	_refresh()


func _process(delta: float) -> void:
	_since_refresh += delta
	if _since_refresh >= REFRESH_INTERVAL:
		_since_refresh = 0.0
		_refresh()


func _refresh() -> void:
	if _economy == null:
		return
	var c := &"collectivists"
	var l := &"libertarians"
	text = "Collectivists: Materials %d  |  Manpower %d/%d\nLibertarians: Materials %d  |  Capital %d" % [
		_economy.amount(c, &"materials"), _economy.pop_used(c), _economy.pop_cap(c),
		_economy.amount(l, &"materials"), _economy.amount(l, &"capital"),
	]
