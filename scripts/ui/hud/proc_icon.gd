class_name ProcIcon
extends Control
## Procedurally drawn icon for a unit or building type. Placeholder art that
## reads at a glance (faction colour, figure shape, role marker) and can be
## replaced by real icons later without touching the callers.

var _unit: UnitDef
var _building: BuildingDef


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func clear() -> void:
	_unit = null
	_building = null
	queue_redraw()


func show_unit(def: UnitDef) -> void:
	_unit = def
	_building = null
	queue_redraw()


func show_building(def: BuildingDef) -> void:
	_building = def
	_unit = null
	queue_redraw()


func _draw() -> void:
	var faction: StringName = &""
	if _unit != null:
		faction = _unit.faction
	elif _building != null:
		faction = _building.faction
	else:
		return
	var palette := HudStyle.palette(faction)
	var plate: Color = (palette["border"] as Color).darkened(0.55)
	draw_rect(Rect2(Vector2.ZERO, size), plate, true)
	draw_rect(Rect2(Vector2.ONE, size - Vector2.ONE * 2.0), (palette["border"] as Color).darkened(0.2), false, 2.0)
	if _unit != null:
		_draw_unit(_unit)
	else:
		_draw_building(_building, palette["border"])


# --- Units ------------------------------------------------------------------

func _draw_unit(def: UnitDef) -> void:
	var u := minf(size.x, size.y)
	var c := Vector2(size.x * 0.5, size.y * 0.52)
	var body_color := def.color
	var dark := body_color.darkened(0.35)
	if def.shape == UnitDef.Shape.CAPSULE:
		draw_circle(c + Vector2(0, -u * 0.22), u * 0.14, body_color.lightened(0.15))
		draw_rect(Rect2(c + Vector2(-u * 0.14, -u * 0.1), Vector2(u * 0.28, u * 0.38)), body_color, true)
		draw_circle(c + Vector2(0, u * 0.28), u * 0.14, body_color)
	else:
		draw_rect(Rect2(c + Vector2(-u * 0.11, -u * 0.34), Vector2(u * 0.22, u * 0.2)), body_color.lightened(0.1), true)
		draw_rect(Rect2(c + Vector2(-u * 0.22, -u * 0.12), Vector2(u * 0.44, u * 0.46)), body_color, true)
		draw_rect(Rect2(c + Vector2(-u * 0.22, u * 0.22), Vector2(u * 0.44, u * 0.12)), dark, true)
	_draw_unit_role_marker(def, u)


## Corner marker: ranged weapon, melee weapon or worker gear.
func _draw_unit_role_marker(def: UnitDef, u: float) -> void:
	var m := Vector2(size.x - u * 0.2, size.y - u * 0.2)
	var light := Color(1, 1, 1, 0.9)
	if def.can_build() or def.can_harvest():
		draw_arc(m, u * 0.09, 0.0, TAU, 12, light, 2.0)
		for i in 4:
			var dir := Vector2.RIGHT.rotated(i * PI * 0.5)
			draw_line(m + dir * u * 0.09, m + dir * u * 0.15, light, 2.0)
	elif def.projectile_speed > 0.0:
		draw_circle(m + Vector2(u * 0.07, 0), u * 0.05, light)
		draw_line(m + Vector2(-u * 0.14, 0), m + Vector2(u * 0.02, 0), light, 2.0)
	elif def.can_attack():
		draw_line(m + Vector2(-u * 0.1, -u * 0.1), m + Vector2(u * 0.1, u * 0.1), light, 2.5)
		draw_line(m + Vector2(-u * 0.1, u * 0.1), m + Vector2(u * 0.1, -u * 0.1), light, 2.5)


# --- Buildings --------------------------------------------------------------

func _draw_building(def: BuildingDef, glyph_color: Color) -> void:
	var u := minf(size.x, size.y)
	var width := u * lerpf(0.5, 0.8, clampf(def.size.x / 9.0, 0.0, 1.0))
	var height := u * lerpf(0.32, 0.55, clampf(def.size.y / 5.0, 0.0, 1.0))
	var base := Vector2(size.x * 0.5, size.y * 0.8)
	var body := Rect2(base + Vector2(-width * 0.5, -height), Vector2(width, height))
	draw_rect(body, def.color, true)
	draw_rect(Rect2(body.position + Vector2(-2, -4), Vector2(width + 4, 6)), def.accent_color, true)
	draw_rect(Rect2(base + Vector2(-u * 0.05, -height * 0.45), Vector2(u * 0.1, height * 0.45)), def.color.darkened(0.5), true)
	_draw_building_glyph(def, body, glyph_color)


func _draw_building_glyph(def: BuildingDef, body: Rect2, color: Color) -> void:
	var light := Color(1, 1, 1, 0.9)
	var center := body.get_center() + Vector2(0, -body.size.y * 0.12)
	var r := minf(body.size.x, body.size.y) * 0.2
	if def.is_hq:
		_draw_star(center, r * 1.5, light)
	elif def.pop_provided > 0:
		for row in 2:
			for col in 2:
				var origin := body.position + Vector2(body.size.x * (0.2 + col * 0.35), body.size.y * (0.12 + row * 0.3))
				draw_rect(Rect2(origin, Vector2(body.size.x * 0.18, body.size.y * 0.16)), light.darkened(0.15), true)
	elif not def.income.is_empty():
		draw_circle(center, r * 1.2, Color(0.97, 0.8, 0.2))
		draw_arc(center, r * 1.2, 0.0, TAU, 14, Color(0.6, 0.4, 0.0), 1.5)
	elif not def.trains.is_empty():
		for i in 2:
			var x := center.x - r + i * r * 1.1
			draw_line(Vector2(x, center.y - r), Vector2(x + r * 0.8, center.y), light, 2.5)
			draw_line(Vector2(x + r * 0.8, center.y), Vector2(x, center.y + r), light, 2.5)
	else:
		# Book: the education building.
		draw_rect(Rect2(center - Vector2(r * 1.2, r), Vector2(r * 2.4, r * 2.0)), light, true)
		draw_line(center + Vector2(0, -r), center + Vector2(0, r), color.darkened(0.3), 2.0)


func _draw_star(center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 10:
		var angle := -PI * 0.5 + i * PI / 5.0
		var rad := radius if i % 2 == 0 else radius * 0.45
		points.append(center + Vector2(cos(angle), sin(angle)) * rad)
	draw_colored_polygon(points, color)
