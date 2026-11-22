class_name FactionPicker
extends CanvasLayer
## Start screen: choose which faction to play. The game is paused until a
## choice is made.

const CHOICES := [
	{
		"id": &"collectivists",
		"title": "The Collective",
		"blurb": "One will, many hands.\nCheap, plentiful troops, planned production,\nstrict central control. Build only within the Plan's reach.",
	},
	{
		"id": &"libertarians",
		"title": "The Free Holdings",
		"blurb": "Free individuals, free contracts.\nEducated, capable units, trade and private initiative.\nBuild wherever you choose.",
	},
]


const DIFFICULTIES := [
	{"id": &"easy", "title": "Easy"},
	{"id": &"normal", "title": "Normal"},
	{"id": &"hard", "title": "Hard"},
]

var _difficulty: StringName = &"normal"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	get_tree().paused = true
	_build()


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 28)
	center.add_child(column)

	var heading := Label.new()
	heading.text = "Choose your side"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 40)
	column.add_child(heading)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 32)
	column.add_child(row)
	for choice in CHOICES:
		row.add_child(_make_button(choice))
	column.add_child(_make_difficulty_row())


func _make_button(choice: Dictionary) -> Button:
	var faction: StringName = choice["id"]
	var colors := HudStyle.palette(faction)
	var button := Button.new()
	button.custom_minimum_size = Vector2(420, 200)
	button.text = "%s\n\n%s" % [choice["title"], choice["blurb"]]
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", colors["text"])
	button.add_theme_color_override("font_hover_color", colors["text"])
	button.add_theme_color_override("font_pressed_color", colors["text"])
	for state in ["normal", "hover", "pressed"]:
		var box := HudStyle.panel_box(faction)
		if state == "hover":
			box.bg_color = box.bg_color.lightened(0.12)
		elif state == "pressed":
			box.bg_color = box.bg_color.darkened(0.1)
		button.add_theme_stylebox_override(state, box)
	button.pressed.connect(_on_chosen.bind(faction))
	return button


## "Opponent: Easy / Normal / Hard". Hard gives the computer extra income.
func _make_difficulty_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	var label := Label.new()
	label.text = "Opponent:"
	label.add_theme_font_size_override("font_size", 22)
	row.add_child(label)
	var group := ButtonGroup.new()
	for level in DIFFICULTIES:
		var button := Button.new()
		button.text = level["title"]
		button.toggle_mode = true
		button.button_group = group
		button.button_pressed = level["id"] == _difficulty
		button.custom_minimum_size = Vector2(110, 40)
		button.add_theme_font_size_override("font_size", 20)
		button.toggled.connect(func(pressed: bool) -> void:
			if pressed:
				_difficulty = level["id"])
		row.add_child(button)
	return row


func _on_chosen(faction: StringName) -> void:
	var session := Session.find(get_tree())
	if session != null:
		session.difficulty = _difficulty
		session.choose(faction)
	get_tree().paused = false
	queue_free()
