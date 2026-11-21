class_name ProductionControls
extends Node
## Temporary production panel (until the HUD): with a finished building
## selected, press 1, 2, ... to queue a unit it trains, Shift+number to queue
## a Plan batch (where offered). Shows the queue and what each key costs.

const MESSAGE_SECONDS := 3.0

var last_message: String = ""

var _label: Label
var _message_left: float = 0.0

@onready var _selection: SelectionController = get_node("../SelectionController")
@onready var _economy: Economy = get_node("../Economy")


func _ready() -> void:
	var layer := CanvasLayer.new()
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 18)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 6)
	layer.add_child(_label)
	add_child(layer)


func _process(delta: float) -> void:
	_message_left = maxf(0.0, _message_left - delta)
	var building := _selection.selected_building
	if not is_instance_valid(building):
		_label.visible = false
		return
	_label.visible = true
	_label.text = _describe(building)
	var viewport_height := get_viewport().get_visible_rect().size.y
	_label.position = Vector2(16, viewport_height - _label.size.y - 16)


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var building := _selection.selected_building
	if not is_instance_valid(building):
		return
	var index: int = event.keycode - KEY_1
	if index < 0 or index >= building.def.trains.size():
		return
	var error := building.try_enqueue(building.def.trains[index] as UnitDef, event.shift_pressed)
	_say(error if not error.is_empty() else "Queued")
	get_viewport().set_input_as_handled()


func _say(message: String) -> void:
	last_message = message
	_message_left = MESSAGE_SECONDS


func _describe(building: Building) -> String:
	var lines: Array[String] = [building.def.display_name]
	if not building.complete:
		lines.append("Under construction: %d%%" % roundi(building.progress_fraction() * 100.0))
	elif building.def.trains.is_empty():
		lines.append("Nothing to train here")
	else:
		lines.append("Queue %d/%d" % [building.queue.size(), building.def.queue_slots])
		for entry in building.queue:
			var title := "%s x%d (Plan)" % [entry.unit_def.display_name, entry.count] if entry.is_plan else entry.unit_def.display_name
			lines.append("  %s  %d%%" % [title, roundi(entry.progress() * 100.0)])
		for i in building.def.trains.size():
			lines.append(_key_line(building, i))
	if _message_left > 0.0:
		lines.append(last_message)
	return "\n".join(lines)


func _key_line(building: Building, index: int) -> String:
	var unit_def := building.def.trains[index] as UnitDef
	var text := "[%d] %s: %s, %ds" % [index + 1, unit_def.display_name, _costs_text(building.entry_costs(unit_def, false)), roundi(building.entry_time(unit_def, false))]
	if building.def.plan_batch_size > 0:
		text += "   [Shift+%d] Plan x%d: %s, %ds" % [index + 1, building.def.plan_batch_size, _costs_text(building.entry_costs(unit_def, true)), roundi(building.entry_time(unit_def, true))]
	if unit_def.requires != null:
		text += "   (needs %s)" % unit_def.requires.display_name
	return text


func _costs_text(costs: Dictionary) -> String:
	var parts: Array[String] = []
	for resource in costs:
		parts.append("%d %s" % [costs[resource], String(resource).capitalize()])
	return ", ".join(parts) if not parts.is_empty() else "free"
