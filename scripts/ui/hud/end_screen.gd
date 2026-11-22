class_name EndScreen
extends CanvasLayer
## Victory / Defeat overlay shown when the match ends, with a Restart button
## that reloads the game (back to the faction choice). Pauses the game.

@onready var _rules: MatchRules = get_node("../MatchRules")
@onready var _session: Session = get_node("../Session")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 11
	_rules.match_ended.connect(_on_match_ended)


func _on_match_ended(winner: StringName, _loser: StringName) -> void:
	get_tree().paused = true
	var won := winner == _session.player_faction
	var faction := _session.player_faction

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", HudStyle.panel_box(faction))
	center.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 20)
	column.custom_minimum_size = Vector2(420, 0)
	panel.add_child(column)

	var title := Label.new()
	title.text = "VICTORY" if won else "DEFEAT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	HudStyle.style_label(title, faction, 56)
	column.add_child(title)

	var detail := Label.new()
	detail.text = "The enemy headquarters has fallen." if won else "Your headquarters has fallen."
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	HudStyle.style_label(detail, faction, 20)
	column.add_child(detail)

	var restart := Button.new()
	restart.text = "Restart"
	restart.custom_minimum_size = Vector2(0, 48)
	restart.add_theme_font_size_override("font_size", 22)
	restart.pressed.connect(_on_restart)
	column.add_child(restart)


func _on_restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
