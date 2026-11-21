class_name Hud
extends CanvasLayer
## The player's heads-up display, styled for their faction: resource bar along
## the top and a selection panel at the bottom centre. Hidden until a faction
## is chosen.

const REFRESH_INTERVAL := 0.2

var _faction: StringName = &""
var _materials: Label
var _second: Label
var _selection_panel: PanelContainer
var _title: Label
var _hp_bar: ProgressBar
var _detail: Label
var _since_refresh: float = 0.0

@onready var _session: Session = get_node("../Session")
@onready var _selection: SelectionController = get_node("../SelectionController")
@onready var _economy: Economy = get_node("../Economy")


func _ready() -> void:
	layer = 1
	visible = false
	_session.faction_chosen.connect(_on_faction_chosen)


func _process(delta: float) -> void:
	if not visible:
		return
	_since_refresh += delta
	if _since_refresh >= REFRESH_INTERVAL:
		_since_refresh = 0.0
		_refresh_resources()
		_refresh_selection()


func _on_faction_chosen(faction: StringName) -> void:
	_faction = faction
	_build_resource_bar()
	_build_selection_panel()
	visible = true
	_refresh_resources()
	_refresh_selection()


# --- Construction -----------------------------------------------------------

func _build_resource_bar() -> void:
	var bar := PanelContainer.new()
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.add_theme_stylebox_override("panel", HudStyle.panel_box(_faction))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 48)
	bar.add_child(row)
	_materials = Label.new()
	_second = Label.new()
	for label in [_materials, _second]:
		HudStyle.style_label(label, _faction, 20)
		row.add_child(label)
	add_child(bar)


func _build_selection_panel() -> void:
	_selection_panel = PanelContainer.new()
	_selection_panel.add_theme_stylebox_override("panel", HudStyle.panel_box(_faction))
	_selection_panel.custom_minimum_size = Vector2(440, 0)
	_selection_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_selection_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_selection_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_selection_panel.offset_bottom = -12.0

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	_selection_panel.add_child(column)

	_title = Label.new()
	HudStyle.style_label(_title, _faction, 22)
	column.add_child(_title)

	_hp_bar = ProgressBar.new()
	_hp_bar.show_percentage = false
	_hp_bar.custom_minimum_size = Vector2(0, 14)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.25, 0.85, 0.25)
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.0, 0.0, 0.0, 0.45)
	_hp_bar.add_theme_stylebox_override("fill", fill)
	_hp_bar.add_theme_stylebox_override("background", back)
	column.add_child(_hp_bar)

	_detail = Label.new()
	HudStyle.style_label(_detail, _faction, 16)
	column.add_child(_detail)

	_selection_panel.visible = false
	add_child(_selection_panel)


# --- Refresh ----------------------------------------------------------------

func _refresh_resources() -> void:
	_materials.text = "Materials  %d" % _economy.amount(_faction, &"materials")
	if _faction == &"collectivists":
		_second.text = "Manpower  %d / %d" % [_economy.pop_used(_faction), _economy.pop_cap(_faction)]
	else:
		_second.text = "Capital  %d" % _economy.amount(_faction, &"capital")


func _refresh_selection() -> void:
	var building := _selection.selected_building
	if is_instance_valid(building):
		_show_building(building)
		return
	var units: Array[Unit] = []
	for unit in _selection.selected:
		if is_instance_valid(unit) and not unit.is_dead():
			units.append(unit)
	if units.size() == 1:
		_show_unit(units[0])
	elif units.size() > 1:
		_show_group(units)
	else:
		_selection_panel.visible = false


func _show_building(building: Building) -> void:
	_selection_panel.visible = true
	_title.text = building.def.display_name
	_hp_bar.visible = false
	if not building.complete:
		_detail.text = "Under construction: %d%%" % roundi(building.progress_fraction() * 100.0)
	elif building.def.trains.is_empty():
		_detail.text = ""
	else:
		_detail.text = "Queue %d / %d" % [building.queue.size(), building.def.queue_slots]


func _show_unit(unit: Unit) -> void:
	_selection_panel.visible = true
	_title.text = unit.def.display_name
	_hp_bar.visible = true
	_hp_bar.max_value = unit.def.max_health
	_hp_bar.value = unit.health
	var detail := "HP %d / %d   %s" % [unit.health, unit.def.max_health, _state_name(unit.state)]
	if unit.def.can_harvest():
		detail += "   Carrying %d / %d" % [unit.carried(), unit.def.carry_capacity]
	_detail.text = detail


func _show_group(units: Array[Unit]) -> void:
	_selection_panel.visible = true
	_title.text = "%d units selected" % units.size()
	_hp_bar.visible = false
	var counts := {}
	for unit in units:
		counts[unit.def.display_name] = counts.get(unit.def.display_name, 0) + 1
	var parts: Array[String] = []
	for unit_name in counts:
		parts.append("%s x%d" % [unit_name, counts[unit_name]])
	_detail.text = "   ".join(parts)


func _state_name(state: Unit.State) -> String:
	match state:
		Unit.State.MOVING:
			return "Moving"
		Unit.State.ATTACKING:
			return "Attacking"
		Unit.State.RETREATING:
			return "Retreating"
		_:
			return "Idle"
