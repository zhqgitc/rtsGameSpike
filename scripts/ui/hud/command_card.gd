class_name CommandCard
extends PanelContainer
## The command card: buttons for what the current selection can do.
## A selected worker shows its buildings; a selected production building shows
## what it trains (and Plan batches where offered). Number keys press the
## buttons (Shift+number for Plan batches). Buttons that cannot be used right
## now are dimmed and explain why in their tooltip; pressing one shows the
## reason in the message line.

const BUTTON_SIZE := Vector2(84, 84)
const MESSAGE_SECONDS := 3.0

## One button's worth of meaning.
class Entry extends RefCounted:
	var kind: StringName ## &"train", &"plan" or &"build"
	var key_index: int = 0
	var unit_def: UnitDef
	var building_def: BuildingDef
	var building: Building ## The producing building (for train/plan).
	var button: Button
	var cost_label: Label

var faction: StringName = &""
var entries: Array[Entry] = []
var last_message: String = ""

var _signature: String = ""
var _row: HBoxContainer
var _message: Label
var _message_left: float = 0.0

var _selection: SelectionController
var _placer: BuildPlacer
var _economy: Economy


func setup(player_faction: StringName, selection: SelectionController, placer: BuildPlacer, economy: Economy) -> void:
	faction = player_faction
	_selection = selection
	_placer = placer
	_economy = economy
	add_theme_stylebox_override("panel", HudStyle.panel_box(faction))
	# Pin to the bottom-right corner and grow up and left to fit the buttons.
	# All four offsets are set so the panel starts empty at the corner; setting
	# only some of them left it stretched across the whole screen.
	set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	offset_left = -12.0
	offset_top = -12.0
	offset_right = -12.0
	offset_bottom = -12.0
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	add_child(column)
	_message = Label.new()
	HudStyle.style_label(_message, faction, 15)
	_message.custom_minimum_size = Vector2(260, 0)
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_message)
	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", 8)
	column.add_child(_row)
	visible = false


func _process(delta: float) -> void:
	_message_left = maxf(0.0, _message_left - delta)
	_message.text = last_message if _message_left > 0.0 else ""
	_message.visible = not _message.text.is_empty()


## Rebuild the buttons if the selection changed, then refresh availability.
func refresh() -> void:
	var wanted := _wanted_entries()
	var signature := _signature_of(wanted)
	if signature != _signature:
		_signature = signature
		_rebuild(wanted)
	for entry in entries:
		_update_entry(entry)
	visible = not entries.is_empty()


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var index: int = event.keycode - KEY_1
	if index < 0 or index > 8:
		return
	for entry in entries:
		if entry.key_index == index and (entry.kind == &"build" or (entry.kind == &"plan") == event.shift_pressed):
			_activate(entry)
			get_viewport().set_input_as_handled()
			return


# --- What to show -----------------------------------------------------------

func _wanted_entries() -> Array[Entry]:
	var wanted: Array[Entry] = []
	var building := _selection.selected_building
	if is_instance_valid(building):
		if building.complete:
			for i in building.def.trains.size():
				var unit_def := building.def.trains[i] as UnitDef
				wanted.append(_train_entry(building, unit_def, i, false))
				if building.def.plan_batch_size > 0:
					wanted.append(_train_entry(building, unit_def, i, true))
		return wanted
	for unit in _selection.selected:
		if is_instance_valid(unit) and unit.def.can_build():
			for i in unit.def.builds.size():
				var entry := Entry.new()
				entry.kind = &"build"
				entry.key_index = i
				entry.building_def = unit.def.builds[i]
				wanted.append(entry)
			break
	return wanted


func _train_entry(building: Building, unit_def: UnitDef, index: int, as_plan: bool) -> Entry:
	var entry := Entry.new()
	entry.kind = &"plan" if as_plan else &"train"
	entry.key_index = index
	entry.unit_def = unit_def
	entry.building = building
	return entry


func _signature_of(wanted: Array[Entry]) -> String:
	var parts: Array[String] = []
	for entry in wanted:
		var id := entry.unit_def.id if entry.unit_def != null else entry.building_def.id
		var source := str(entry.building.get_instance_id()) if entry.building != null else ""
		parts.append("%s:%s:%s" % [entry.kind, id, source])
	return "|".join(parts)


func _rebuild(wanted: Array[Entry]) -> void:
	for child in _row.get_children():
		child.queue_free()
	entries = wanted
	for entry in entries:
		_make_button(entry)


func _make_button(entry: Entry) -> void:
	var button := Button.new()
	button.custom_minimum_size = BUTTON_SIZE
	button.focus_mode = Control.FOCUS_NONE
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var box := HudStyle.panel_box(faction)
		box.set_border_width_all(2)
		box.content_margin_left = 0
		box.content_margin_right = 0
		box.content_margin_top = 0
		box.content_margin_bottom = 0
		if state == "hover":
			box.bg_color = box.bg_color.lightened(0.15)
		elif state == "pressed":
			box.bg_color = box.bg_color.darkened(0.15)
		button.add_theme_stylebox_override(state, box)

	var icon := ProcIcon.new()
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.offset_bottom = -16.0
	icon.offset_left = 3.0
	icon.offset_top = 3.0
	icon.offset_right = -3.0
	if entry.unit_def != null:
		icon.show_unit(entry.unit_def)
	else:
		icon.show_building(entry.building_def)
	button.add_child(icon)

	var key := Label.new()
	key.text = ("Shift+%d" if entry.kind == &"plan" else "%d") % (entry.key_index + 1)
	key.position = Vector2(5, 2)
	key.add_theme_font_size_override("font_size", 12)
	key.add_theme_color_override("font_color", Color.WHITE)
	key.add_theme_color_override("font_outline_color", Color.BLACK)
	key.add_theme_constant_override("outline_size", 4)
	key.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(key)

	var cost := Label.new()
	cost.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	cost.offset_top = -16.0
	cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost.add_theme_font_size_override("font_size", 12)
	HudStyle.style_label(cost, faction, 12)
	cost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(cost)

	button.pressed.connect(_activate.bind(entry))
	entry.button = button
	entry.cost_label = cost
	_row.add_child(button)


# --- Availability, tooltips, actions ----------------------------------------

func _update_entry(entry: Entry) -> void:
	if entry.button == null or not is_instance_valid(entry.button):
		return
	var reason := _reason(entry)
	entry.button.modulate = Color(1, 1, 1, 1) if reason.is_empty() else Color(0.55, 0.55, 0.55, 1)
	entry.cost_label.text = _cost_text(_costs(entry))
	entry.button.tooltip_text = _tooltip(entry, reason)


func _reason(entry: Entry) -> String:
	if entry.kind == &"build":
		return _economy.shortfall(faction, entry.building_def.costs)
	if not is_instance_valid(entry.building):
		return "Building lost"
	return entry.building.block_reason(entry.unit_def, entry.kind == &"plan")


func _costs(entry: Entry) -> Dictionary:
	if entry.kind == &"build":
		return entry.building_def.costs
	if not is_instance_valid(entry.building):
		return {}
	return entry.building.entry_costs(entry.unit_def, entry.kind == &"plan")


func _tooltip(entry: Entry, reason: String) -> String:
	var lines: Array[String] = []
	if entry.kind == &"build":
		var def := entry.building_def
		lines.append(def.display_name)
		lines.append("%s, %d s of work" % [_cost_text(def.costs, true), roundi(def.build_time)])
		if def.max_distance_from_hq > 0.0:
			lines.append("Only within %d m of a finished HQ" % roundi(def.max_distance_from_hq))
		if def.pop_provided > 0:
			lines.append("+%d Manpower" % def.pop_provided)
		for resource in def.income:
			lines.append("+%s %s per second" % [str(def.income[resource]), String(resource).capitalize()])
	else:
		var unit_def := entry.unit_def
		var plan := entry.kind == &"plan"
		var title := unit_def.display_name
		if plan and is_instance_valid(entry.building):
			title = "Plan: %d x %s" % [entry.building.def.plan_batch_size, unit_def.display_name]
		lines.append(title)
		if is_instance_valid(entry.building):
			lines.append("%s, %d s" % [_cost_text(_costs(entry), true), roundi(entry.building.entry_time(unit_def, plan))])
		if unit_def.pop_cost > 0:
			lines.append("Uses %d Manpower each" % unit_def.pop_cost)
		if unit_def.requires != null:
			lines.append("Needs: %s" % unit_def.requires.display_name)
	if not reason.is_empty():
		lines.append("")
		lines.append(reason)
	return "\n".join(lines)


func _activate(entry: Entry) -> void:
	if entry.kind == &"build":
		# The placement ghost itself explains anything that is missing.
		if not _placer.begin_placement(entry.building_def):
			_say("Select a worker first")
		return
	if not is_instance_valid(entry.building):
		return
	var error := entry.building.try_enqueue(entry.unit_def, entry.kind == &"plan")
	_say(error if not error.is_empty() else "Queued")


func _say(text: String) -> void:
	last_message = text
	_message_left = MESSAGE_SECONDS


func _cost_text(costs: Dictionary, long_names: bool = false) -> String:
	var parts: Array[String] = []
	for resource in costs:
		if long_names:
			parts.append("%d %s" % [costs[resource], String(resource).capitalize()])
		else:
			parts.append("%d%s" % [costs[resource], String(resource).left(1).to_upper()])
	return (", " if long_names else " ").join(parts) if not parts.is_empty() else "free"
