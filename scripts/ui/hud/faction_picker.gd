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


func _on_chosen(faction: StringName) -> void:
	var session := Session.find(get_tree())
	if session != null:
		session.choose(faction)
	get_tree().paused = false
	queue_free()
