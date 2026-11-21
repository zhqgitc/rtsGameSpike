class_name HudStyle
extends RefCounted
## Faction look for HUD panels: red-and-concrete for the Collectivists,
## warm cream and gold for the Libertarians.

const PALETTES := {
	&"collectivists": {
		"background": Color(0.16, 0.16, 0.18, 0.94),
		"border": Color(0.72, 0.1, 0.1),
		"text": Color(0.93, 0.91, 0.88),
		"accent": Color(0.85, 0.2, 0.15),
	},
	&"libertarians": {
		"background": Color(0.93, 0.89, 0.78, 0.95),
		"border": Color(0.85, 0.65, 0.1),
		"text": Color(0.16, 0.12, 0.07),
		"accent": Color(0.75, 0.5, 0.05),
	},
}


static func palette(faction: StringName) -> Dictionary:
	return PALETTES.get(faction, PALETTES[&"collectivists"])


static func panel_box(faction: StringName) -> StyleBoxFlat:
	var colors := palette(faction)
	var box := StyleBoxFlat.new()
	box.bg_color = colors["background"]
	box.border_color = colors["border"]
	box.set_border_width_all(3)
	box.set_corner_radius_all(4)
	box.content_margin_left = 14
	box.content_margin_right = 14
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	return box


static func style_label(label: Label, faction: StringName, font_size: int = 18) -> void:
	label.add_theme_color_override("font_color", palette(faction)["text"])
	label.add_theme_font_size_override("font_size", font_size)
