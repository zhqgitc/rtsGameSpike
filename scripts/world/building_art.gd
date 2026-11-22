class_name BuildingArt
extends RefCounted
## Procedural models for the buildings, assembled from primitives and
## procedural materials.
## Collectivists: brutalism taken as far as it goes. Monolithic raw concrete,
## narrow slits instead of windows, heavy piers, top-heavy cantilevers,
## loudspeaker horns, searchlights, barbed wire, giant red banners and stars.
## Libertarians: very free market. Brick and timber put up by whoever needed
## it, rusty gabled roofs, awnings, crates, price tags, ledgers, scales, a
## chalkboard of supply and demand, and signs that say what they believe.
## Each model fits its building's footprint (def.size.x by def.size.z) and
## stands on the ground at the origin. Chosen by BuildingDef.visual.

const FACADE := preload("res://assets/shaders/facade.gdshader")
const CRAFT := preload("res://assets/shaders/craft.gdshader")

const KIND_PLANKS := 0
const KIND_BRICK := 1
const KIND_METAL := 2
const KIND_CANVAS := 3

const CONCRETE := Color(0.37, 0.36, 0.34)
const CONCRETE_DARK := Color(0.24, 0.24, 0.24)
const RED := Color(0.62, 0.08, 0.08)
const GOLD := Color(0.85, 0.65, 0.12)
const DARK_METAL := Color(0.13, 0.13, 0.14)

static var _banner_material: StandardMaterial3D
static var _chalkboard_material: StandardMaterial3D
static var _coin_flag_material: StandardMaterial3D


## The finished model for a building definition.
static func build(def: BuildingDef) -> Node3D:
	var root := Node3D.new()
	root.name = "Model"
	match def.visual:
		&"committee_block":
			_committee_block(root, def)
		&"dormitory":
			_dormitory(root, def)
		&"conscription_office":
			_conscription_office(root, def)
		&"trading_post":
			_trading_post(root, def)
		&"market":
			_market(root, def)
		&"militia_hall":
			_militia_hall(root, def)
		&"workshop":
			_workshop(root, def)
		_:
			_add_box(root, def.size, Vector3(0, def.size.y * 0.5, 0), _plain(def.color))
	return root


# --- Collectivists ----------------------------------------------------------

## Central Committee Block: a windowless-looking monolith of raw concrete with a
## top-heavy cantilevered upper mass looming over the plinth, a tower, loudspeaker
## horns, giant banners and a red star.
static func _committee_block(root: Node3D, def: BuildingDef) -> void:
	var w := def.size.x
	# Plinth and the steps up to the portal.
	_add_box(root, Vector3(w, 0.9, w), Vector3(0, 0.45, 0), _facade(CONCRETE_DARK, 1.0, 1.0, Vector2.ZERO, 0.45, 0.0, false))
	_add_box(root, Vector3(5.0, 0.3, 1.4), Vector3(0, 0.15, w * 0.5 + 0.6), _facade(CONCRETE_DARK, 1.0, 1.0, Vector2.ZERO, 0.15, 0.0, false))
	_add_box(root, Vector3(3.6, 0.3, 0.8), Vector3(0, 0.45, w * 0.5 + 0.25), _facade(CONCRETE_DARK, 1.0, 1.0, Vector2.ZERO, 0.15, 0.0, false))
	var y := 0.9
	# Lower monolith: narrow slits, a dark portal, heavy piers.
	var lower := w - 1.0
	var lower_h := 7.0
	_add_box(root, Vector3(lower, lower_h, lower), Vector3(0, y + lower_h * 0.5, 0), _facade(CONCRETE, 1.75, 0.85, Vector2(0.1, 0.6), lower_h * 0.5, 0.05))
	_add_box(root, Vector3(2.0, 2.4, 0.3), Vector3(0, y + 1.2, lower * 0.5 + 0.02), _plain(Color(0.02, 0.02, 0.03)))
	for x in [-3.3, -2.2, 2.2, 3.3]:
		for side in [-1.0, 1.0]:
			_add_box(root, Vector3(0.55, lower_h, 0.5), Vector3(x, y + lower_h * 0.5, side * (lower * 0.5 + 0.22)), _facade(CONCRETE, 1.0, 1.0, Vector2.ZERO, lower_h * 0.5, 0.0, false))
	# The banners hang over the piers.
	_add_banner(root, Vector3(-2.75, y + 4.2, lower * 0.5 + 0.55), Vector2(1.6, 5.6))
	_add_banner(root, Vector3(2.75, y + 4.2, lower * 0.5 + 0.55), Vector2(1.6, 5.6))
	y += lower_h
	# Cantilevered upper mass: wider than the base, a dark shadow underneath.
	var upper := lower + 1.6
	var upper_h := 3.2
	_add_box(root, Vector3(upper, 0.35, upper), Vector3(0, y + 0.175, 0), _plain(Color(0.05, 0.05, 0.05), 1.0))
	y += 0.35
	_add_box(root, Vector3(upper, upper_h, upper), Vector3(0, y + upper_h * 0.5, 0), _facade(CONCRETE, 1.6, 0.85, Vector2(0.1, 0.55), upper_h * 0.5, 0.05))
	y += upper_h
	_add_box(root, Vector3(upper + 0.5, 0.45, upper + 0.5), Vector3(0, y + 0.225, 0), _facade(CONCRETE_DARK, 1.0, 1.0, Vector2.ZERO, 0.225, 0.0, false))
	y += 0.45
	# Loudspeaker horns and searchlights on the corners.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var corner := Vector3(sx * (upper * 0.5 - 0.5), y, sz * (upper * 0.5 - 0.5))
			_add_loudspeaker(root, corner + Vector3(0, 0.5, 0), atan2(sx, sz))
			_add_searchlight(root, corner + Vector3(-sx * 0.8, 0.0, 0.0))
	# Tower and crown.
	var tower := 4.6
	var tower_h := 3.0
	_add_box(root, Vector3(tower, tower_h, tower), Vector3(0, y + tower_h * 0.5, 0), _facade(CONCRETE, 1.5, 0.85, Vector2(0.1, 0.55), tower_h * 0.5, 0.06))
	y += tower_h
	_add_box(root, Vector3(tower + 0.6, 0.45, tower + 0.6), Vector3(0, y + 0.225, 0), _plain(def.accent_color, 0.8))
	y += 0.45
	_add_star_sculpture(root, Vector3(0, y + 1.6, 0), 1.7, 0.45)


## Dormitory Block: a grim housing slab. Tiny barred windows in a dense grid,
## concrete fins, no comfort, wire and a loudspeaker on the roof.
static func _dormitory(root: Node3D, def: BuildingDef) -> void:
	var w := def.size.x
	var d := def.size.z
	var h := 5.0
	_add_box(root, Vector3(w, h, d), Vector3(0, h * 0.5, 0), _facade(CONCRETE, 1.0, 0.8, Vector2(0.4, 0.3), h * 0.5, 0.06))
	for x in [-2.1, -0.7, 0.7, 2.1]:
		_add_box(root, Vector3(0.3, h, 0.3), Vector3(x, h * 0.5, d * 0.5 + 0.12), _facade(CONCRETE, 1.0, 1.0, Vector2.ZERO, h * 0.5, 0.0, false))
	_add_box(root, Vector3(1.2, 1.7, 0.3), Vector3(0, 0.85, d * 0.5 + 0.02), _plain(Color(0.02, 0.02, 0.03)))
	_add_box(root, Vector3(2.4, 0.3, 1.0), Vector3(0, 1.9, d * 0.5 + 0.4), _facade(CONCRETE_DARK, 1.0, 1.0, Vector2.ZERO, 0.15, 0.0, false))
	_add_box(root, Vector3(w + 0.05, 0.45, d + 0.05), Vector3(0, h - 0.5, 0), _plain(def.accent_color, 0.85))
	_add_box(root, Vector3(w + 0.4, 0.4, d + 0.4), Vector3(0, h + 0.2, 0), _facade(CONCRETE_DARK, 1.0, 1.0, Vector2.ZERO, 0.2, 0.0, false))
	_add_box(root, Vector3(1.6, 1.3, 1.6), Vector3(w * 0.2, h + 0.4 + 0.65, -d * 0.2), _facade(CONCRETE, 1.0, 1.0, Vector2.ZERO, 0.65, 0.0, false))
	_add_loudspeaker(root, Vector3(-w * 0.3, h + 0.4, d * 0.3), 0.0)
	_add_barbed_wire(root, Vector3(-w * 0.5, h + 0.4, d * 0.5), Vector3(w * 0.5, h + 0.4, d * 0.5), 0.5)
	_add_banner(root, Vector3(-1.5, 3.0, d * 0.5 + 0.55), Vector2(1.1, 3.0))


## Conscription Office: a squat fortress. Slit windows, a heavy gate, wire, and
## two guard towers with searchlights and loudspeakers.
static func _conscription_office(root: Node3D, def: BuildingDef) -> void:
	var w := def.size.x
	var d := def.size.z
	var h := 3.6
	_add_box(root, Vector3(w, h, d), Vector3(0, h * 0.5, 0), _facade(CONCRETE, 1.8, 0.85, Vector2(0.1, 0.55), h * 0.5, 0.05))
	_add_box(root, Vector3(w + 0.4, 0.45, d + 0.4), Vector3(0, h + 0.225, 0), _facade(CONCRETE_DARK, 1.0, 1.0, Vector2.ZERO, 0.225, 0.0, false))
	_add_box(root, Vector3(w + 0.05, 0.4, d + 0.05), Vector3(0, h - 0.6, 0), _plain(def.accent_color, 0.85))
	# Heavy gate under a massive lintel.
	_add_box(root, Vector3(2.6, 2.6, 0.3), Vector3(0.0, 1.3, d * 0.5 + 0.02), _plain(Color(0.02, 0.02, 0.03)))
	_add_box(root, Vector3(3.8, 0.5, 1.6), Vector3(0.0, 2.95, d * 0.5 + 0.6), _facade(CONCRETE_DARK, 1.0, 1.0, Vector2.ZERO, 0.25, 0.0, false))
	_add_banner(root, Vector3(-2.2, 2.0, d * 0.5 + 0.05), Vector2(1.3, 2.8))
	# Guard towers in both front corners.
	for side in [-1.0, 1.0]:
		var tx: float = side * (w * 0.5 - 0.9)
		var tz: float = d * 0.5 - 0.9
		_add_box(root, Vector3(1.8, 6.6, 1.8), Vector3(tx, 3.3, tz), _facade(CONCRETE, 1.65, 0.8, Vector2(0.1, 0.55), 3.3, 0.05))
		_add_box(root, Vector3(2.5, 0.5, 2.5), Vector3(tx, 6.85, tz), _plain(def.accent_color, 0.85))
		_add_searchlight(root, Vector3(tx, 7.1, tz))
		_add_loudspeaker(root, Vector3(tx, 7.2, tz), atan2(side, 1.0))
	_add_barbed_wire(root, Vector3(-w * 0.5 + 1.8, 1.0, d * 0.5 + 0.7), Vector3(-1.5, 1.0, d * 0.5 + 0.7), 0.9)
	_add_barbed_wire(root, Vector3(1.5, 1.0, d * 0.5 + 0.7), Vector3(w * 0.5 - 1.8, 1.0, d * 0.5 + 0.7), 0.9)


# --- Libertarians -----------------------------------------------------------

## Trading Post: brick ground floor, timber upper storey with a chalkboard of
## supply and demand, a gabled roof, awning, and signs that say what they think.
static func _trading_post(root: Node3D, def: BuildingDef) -> void:
	var brick := _craft(KIND_BRICK, Color(0.46, 0.21, 0.15), Color(0.36, 0.16, 0.13))
	var timber := _craft(KIND_PLANKS, Color(0.4, 0.32, 0.22), Color(0.3, 0.24, 0.17))
	var rust := _craft(KIND_METAL, Color(0.42, 0.21, 0.11), Color(0.28, 0.14, 0.09))
	_add_box(root, Vector3(4.6, 2.0, 4.4), Vector3(0, 1.0, 0), brick)
	_add_box(root, Vector3(4.2, 1.5, 4.0), Vector3(0, 2.75, 0), timber)
	_gable_roof(root, 4.2, 4.0, 1.0, 0.4, 3.5, rust)
	_add_box(root, Vector3(0.5, 1.6, 0.5), Vector3(1.4, 3.9, -0.8), brick)
	# Door, awning, posts.
	_add_box(root, Vector3(0.95, 1.5, 0.12), Vector3(0, 0.75, 2.22), _plain(Color(0.08, 0.06, 0.05)))
	_add_box(root, Vector3(3.8, 0.1, 1.5), Vector3(0, 2.05, 2.95), _craft(KIND_CANVAS, GOLD, Color(0.85, 0.8, 0.65)), Vector3(0.28, 0, 0))
	for x in [-1.75, 1.75]:
		_add_box(root, Vector3(0.14, 1.95, 0.14), Vector3(x, 0.975, 3.45), timber)
	# The chalkboard: supply meets demand.
	_add_chalkboard(root, Vector3(-0.9, 2.85, 2.02), Vector2(1.7, 1.15))
	_add_sign(root, "FREE TRADE", Vector3(1.4, 1.65, 2.28), Vector2(1.7, 0.42), 30, GOLD)
	_add_sign(root, "NO PERMITS REQUIRED", Vector3(-2.32, 1.5, 0.5), Vector2(1.9, 0.36), 21, Color(0.9, 0.86, 0.7), PI * 0.5 * -1.0)
	for crate in [[Vector3(-1.8, 0.3, 2.7), 0.6], [Vector3(-1.2, 0.25, 3.0), 0.5], [Vector3(1.9, 0.3, 3.0), 0.6]]:
		_add_box(root, Vector3.ONE * crate[1], crate[0], timber)
		_add_price_tag(root, crate[0] + Vector3(0, crate[1] * 0.5 + 0.02, crate[1] * 0.5))
	_add_scales(root, Vector3(1.0, 0.0, 3.1))


## Market: an open stall under a striped canvas roof; goods hang from the
## awning, every item carries a price tag, the ledger lies open on the counter.
static func _market(root: Node3D, def: BuildingDef) -> void:
	var timber := _craft(KIND_PLANKS, Color(0.42, 0.33, 0.22), Color(0.31, 0.24, 0.17))
	for sx in [-1.5, 1.5]:
		for sz in [-1.3, 1.3]:
			_add_cylinder(root, 0.08, 2.2, Vector3(sx, 1.1, sz), timber)
	_add_box(root, Vector3(3.9, 0.08, 3.5), Vector3(0, 2.3, 0), _craft(KIND_CANVAS, GOLD, Color(0.8, 0.76, 0.62)), Vector3(0.12, 0, 0))
	_add_box(root, Vector3(2.8, 0.9, 0.8), Vector3(0, 0.45, 0.9), timber)
	_add_box(root, Vector3(2.4, 0.06, 0.6), Vector3(0, 0.93, 0.9), _plain(Color(0.55, 0.5, 0.4)))
	_add_sign(root, "PRICES BY AGREEMENT", Vector3(0, 0.55, 1.32), Vector2(2.4, 0.3), 19, Color(0.95, 0.9, 0.7))
	_add_ledger(root, Vector3(-0.7, 0.99, 0.9))
	_add_scales(root, Vector3(0.7, 0.96, 0.9), 0.55)
	# Goods hanging from the front edge of the awning.
	var goods := [Color(0.55, 0.15, 0.1), Color(0.6, 0.45, 0.2), Color(0.25, 0.4, 0.2), Color(0.6, 0.15, 0.1), Color(0.5, 0.38, 0.22)]
	for i in goods.size():
		var x := -1.5 + i * 0.75
		_add_cylinder(root, 0.02, 0.5, Vector3(x, 2.0, 1.45), _plain(Color(0.2, 0.2, 0.2)))
		_add_cylinder(root, 0.12, 0.38, Vector3(x, 1.65, 1.45), _plain(goods[i], 0.85))
		_add_price_tag(root, Vector3(x + 0.1, 1.82, 1.58))
	for crate in [[Vector3(-1.4, 0.3, -0.9), 0.6], [Vector3(-0.8, 0.25, -1.1), 0.5], [Vector3(1.3, 0.3, -1.0), 0.6]]:
		_add_box(root, Vector3.ONE * crate[1], crate[0], timber)
		_add_price_tag(root, crate[0] + Vector3(0, crate[1] * 0.5 + 0.02, crate[1] * 0.5))
	for x in [1.0, 1.55]:
		_add_cylinder(root, 0.28, 0.75, Vector3(x, 0.375, -0.2), _plain(Color(0.3, 0.22, 0.15), 0.9))


## Militia Hall: a timber longhouse. Volunteers only.
static func _militia_hall(root: Node3D, def: BuildingDef) -> void:
	var timber := _craft(KIND_PLANKS, Color(0.36, 0.3, 0.22), Color(0.27, 0.22, 0.16))
	var rust := _craft(KIND_METAL, Color(0.38, 0.2, 0.12), Color(0.26, 0.14, 0.09))
	_add_box(root, Vector3(4.3, 2.0, 3.2), Vector3(0, 1.0, -0.3), timber)
	var roof := _gable_roof(root, 4.3, 3.2, 1.0, 0.35, 2.0, rust)
	roof.position.z = -0.3 # the walls are shifted back a little to leave room for the sandbags
	_add_box(root, Vector3(1.0, 1.6, 0.12), Vector3(0, 0.8, 1.32), _plain(Color(0.07, 0.06, 0.05)))
	_add_sign(root, "VOLUNTEERS ONLY", Vector3(0, 1.95, 1.33), Vector2(2.3, 0.38), 25, GOLD)
	_add_coin_flag(root, Vector3(1.8, 0.0, 1.7), 4.6)
	var sandbag := _plain(Color(0.45, 0.4, 0.28), 1.0)
	for i in 7:
		var x := -1.8 + i * 0.6
		_add_box(root, Vector3(0.6, 0.28, 0.36), Vector3(x, 0.14, 2.0), sandbag, Vector3(0, 0.05 * (i % 3 - 1), 0))
		if i % 2 == 0 and i < 6:
			_add_box(root, Vector3(0.6, 0.28, 0.36), Vector3(x + 0.3, 0.42, 2.0), sandbag)


## Apprentice Workshop: learning by doing. A shed with a chalkboard, a shelf of
## books, a bench, a chimney and a log pile.
static func _workshop(root: Node3D, def: BuildingDef) -> void:
	var timber := _craft(KIND_PLANKS, Color(0.42, 0.34, 0.23), Color(0.32, 0.26, 0.18))
	var rust := _craft(KIND_METAL, Color(0.36, 0.2, 0.12), Color(0.25, 0.14, 0.1))
	_add_box(root, Vector3(3.6, 1.8, 3.4), Vector3(0, 0.9, 0), timber)
	_add_box(root, Vector3(3.9, 0.12, 3.7), Vector3(0, 2.0, 0), rust, Vector3(0.2, 0, 0))
	for x in [-0.9, 0.9]:
		_add_box(root, Vector3(0.9, 0.08, 0.8), Vector3(x, 2.28, -0.2), _plain(Color(0.2, 0.32, 0.34), 0.2, 0.0), Vector3(0.2, 0, 0))
	_add_cylinder(root, 0.22, 2.4, Vector3(1.3, 2.3, -1.0), _plain(Color(0.18, 0.17, 0.17), 0.6, 0.4))
	_add_chalkboard(root, Vector3(0.6, 1.1, 1.72), Vector2(1.5, 1.0))
	_add_sign(root, "LEARN BY DOING", Vector3(0.0, 1.65, 1.73), Vector2(1.9, 0.3), 20, Color(0.95, 0.9, 0.7))
	_add_bookshelf(root, Vector3(-1.4, 0.0, 1.5))
	_add_box(root, Vector3(1.4, 0.8, 0.6), Vector3(-0.8, 0.4, 2.2), timber)
	_add_box(root, Vector3(0.4, 0.35, 0.3), Vector3(-0.7, 0.97, 2.2), _plain(Color(0.12, 0.12, 0.13), 0.5, 0.5))
	for i in 3:
		var log_node := _add_cylinder(root, 0.17, 1.3, Vector3(1.5, 0.17 + (i / 2) * 0.3, 1.9 - (i % 2) * 0.34 + (i / 2) * 0.17), timber)
		log_node.rotation = Vector3(0, 0, PI * 0.5)


# --- Collectivist props -----------------------------------------------------

## A horn loudspeaker on a post, aimed outwards (yaw in radians).
static func _add_loudspeaker(parent: Node3D, base: Vector3, yaw: float) -> void:
	var mount := Node3D.new()
	mount.position = base
	mount.rotation.y = yaw
	parent.add_child(mount)
	_add_cylinder(mount, 0.06, 0.5, Vector3(0, 0.25, 0), _plain(DARK_METAL, 0.5, 0.5))
	var horn := CylinderMesh.new()
	horn.top_radius = 0.42
	horn.bottom_radius = 0.07
	horn.height = 0.85
	horn.radial_segments = 10
	var instance := MeshInstance3D.new()
	instance.mesh = horn
	instance.material_override = _plain(DARK_METAL, 0.45, 0.6)
	instance.position = Vector3(0, 0.62, 0.38)
	instance.rotation = Vector3(PI * 0.5, 0, 0)
	mount.add_child(instance)


static func _add_searchlight(parent: Node3D, base: Vector3) -> void:
	_add_box(parent, Vector3(0.3, 0.4, 0.3), base + Vector3(0, 0.2, 0), _plain(DARK_METAL, 0.5, 0.5))
	var lamp := _add_cylinder(parent, 0.22, 0.45, base + Vector3(0, 0.62, 0), _plain(Color(0.95, 0.9, 0.7), 0.3, 0.2))
	lamp.rotation = Vector3(0.5, 0, 0)


## Two strands of barbed wire between posts (decoration, no collision).
static func _add_barbed_wire(parent: Node3D, from: Vector3, to: Vector3, height: float) -> void:
	var length := from.distance_to(to)
	var posts := maxi(int(length / 0.9), 2)
	var wire := _plain(Color(0.12, 0.12, 0.12), 0.5, 0.6)
	var direction := (to - from).normalized()
	for i in posts + 1:
		var p := from + direction * (length * i / posts)
		_add_cylinder(parent, 0.03, height, p + Vector3(0, height * 0.5, 0), wire)
	var yaw := atan2(-direction.z, direction.x)
	for level in [0.45, 0.85]:
		var strand := _add_box(parent, Vector3(length, 0.02, 0.02), (from + to) * 0.5 + Vector3(0, height * level, 0), wire)
		strand.rotation.y = yaw


## A giant extruded red star on a post.
static func _add_star_sculpture(parent: Node3D, center: Vector3, radius: float, depth: float) -> void:
	var points := PackedVector2Array()
	for i in 10:
		var angle := -PI * 0.5 + i * PI / 5.0
		points.append(Vector2(cos(angle), -sin(angle)) * (radius if i % 2 == 0 else radius * 0.42))
	var triangles := Geometry2D.triangulate_polygon(points)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	var inside := Vector3.ZERO
	var half := depth * 0.5
	for i in range(0, triangles.size(), 3):
		var a := points[triangles[i]]
		var b := points[triangles[i + 1]]
		var c := points[triangles[i + 2]]
		_triangle(surface, Vector3(a.x, a.y, half), Vector3(b.x, b.y, half), Vector3(c.x, c.y, half), inside)
		_triangle(surface, Vector3(a.x, a.y, -half), Vector3(b.x, b.y, -half), Vector3(c.x, c.y, -half), inside)
	for i in points.size():
		var p := points[i]
		var q := points[(i + 1) % points.size()]
		_triangle(surface, Vector3(p.x, p.y, half), Vector3(q.x, q.y, half), Vector3(q.x, q.y, -half), inside)
		_triangle(surface, Vector3(p.x, p.y, half), Vector3(q.x, q.y, -half), Vector3(p.x, p.y, -half), inside)
	surface.generate_normals()
	var instance := MeshInstance3D.new()
	instance.mesh = surface.commit()
	instance.material_override = _plain(RED, 0.6)
	instance.position = center
	parent.add_child(instance)
	_add_cylinder(parent, 0.12, 1.2, center + Vector3(0, -radius * 0.9, 0), _plain(DARK_METAL, 0.5, 0.5))


# --- Libertarian props ------------------------------------------------------

## A wooden sign with lettering (yaw rotates it to face another wall).
static func _add_sign(parent: Node3D, text: String, center: Vector3, board: Vector2, font_size: int, color: Color, yaw: float = 0.0) -> void:
	var mount := Node3D.new()
	mount.position = center
	mount.rotation.y = yaw
	parent.add_child(mount)
	_add_box(mount, Vector3(board.x, board.y, 0.06), Vector3.ZERO, _plain(Color(0.14, 0.1, 0.07), 0.9))
	var label := Label3D.new()
	label.text = text
	label.font_size = font_size
	label.pixel_size = 0.0105
	label.modulate = color
	label.outline_size = 3
	label.outline_modulate = Color(0.05, 0.03, 0.02)
	label.position = Vector3(0, 0, 0.04)
	label.shaded = false
	mount.add_child(label)


static func _add_price_tag(parent: Node3D, position: Vector3) -> void:
	_add_box(parent, Vector3(0.16, 0.1, 0.012), position, _plain(Color(0.9, 0.88, 0.8), 0.9), Vector3(0.0, 0.2, 0.15))


## A balance scale: the market sets the price.
static func _add_scales(parent: Node3D, base: Vector3, scale_factor: float = 1.0) -> void:
	var metal := _plain(Color(0.55, 0.45, 0.2), 0.4, 0.7)
	_add_cylinder(parent, 0.03 * scale_factor, 0.55 * scale_factor, base + Vector3(0, 0.275 * scale_factor, 0), metal)
	_add_box(parent, Vector3(0.7, 0.03, 0.03) * scale_factor, base + Vector3(0, 0.56 * scale_factor, 0), metal)
	for side in [-1.0, 1.0]:
		_add_cylinder(parent, 0.12 * scale_factor, 0.02 * scale_factor, base + Vector3(side * 0.32 * scale_factor, 0.36 * scale_factor, 0), metal)
		_add_box(parent, Vector3(0.01, 0.2, 0.01) * scale_factor, base + Vector3(side * 0.32 * scale_factor, 0.46 * scale_factor, 0), metal)


## An open ledger on the counter.
static func _add_ledger(parent: Node3D, center: Vector3) -> void:
	_add_box(parent, Vector3(0.5, 0.05, 0.36), center + Vector3(0, 0.025, 0), _plain(Color(0.35, 0.06, 0.05), 0.8))
	_add_box(parent, Vector3(0.44, 0.03, 0.3), center + Vector3(0, 0.065, 0), _plain(Color(0.9, 0.87, 0.75), 0.9))


## A shelf of books (somebody has to read Mises).
static func _add_bookshelf(parent: Node3D, base: Vector3) -> void:
	var wood := _plain(Color(0.25, 0.18, 0.12), 0.9)
	_add_box(parent, Vector3(0.9, 1.5, 0.35), base + Vector3(0, 0.75, 0), wood)
	var colors := [Color(0.55, 0.12, 0.1), Color(0.15, 0.25, 0.4), Color(0.6, 0.5, 0.2), Color(0.2, 0.3, 0.2), Color(0.35, 0.2, 0.3)]
	for shelf in 3:
		for i in 7:
			var height := 0.28 + 0.06 * ((i * 5 + shelf * 3) % 4)
			_add_box(parent, Vector3(0.09, height, 0.24), base + Vector3(-0.36 + i * 0.12, 0.3 + shelf * 0.42 + height * 0.5 - 0.1, 0.06), _plain(colors[(i + shelf) % colors.size()], 0.85))


## A flag with a gold field and a black coin.
static func _add_coin_flag(parent: Node3D, base: Vector3, pole_height: float) -> void:
	_add_cylinder(parent, 0.05, pole_height, base + Vector3(0, pole_height * 0.5, 0), _plain(Color(0.15, 0.15, 0.15), 0.5, 0.5))
	var quad := QuadMesh.new()
	quad.size = Vector2(1.3, 0.85)
	var instance := MeshInstance3D.new()
	instance.mesh = quad
	instance.material_override = _get_coin_flag_material()
	instance.position = base + Vector3(0.72, pole_height - 0.5, 0)
	instance.rotation = Vector3(0, 0.1, 0.04)
	parent.add_child(instance)


## Chalk drawing of supply and demand on a dark green board.
static func _add_chalkboard(parent: Node3D, center: Vector3, size: Vector2) -> void:
	var frame := _plain(Color(0.28, 0.2, 0.12), 0.9)
	_add_box(parent, Vector3(size.x + 0.12, size.y + 0.12, 0.05), center, frame)
	var quad := QuadMesh.new()
	quad.size = size
	var instance := MeshInstance3D.new()
	instance.mesh = quad
	instance.material_override = _get_chalkboard_material()
	instance.position = center + Vector3(0, 0, 0.03)
	parent.add_child(instance)


# --- Textures painted once --------------------------------------------------

static func _get_chalkboard_material() -> StandardMaterial3D:
	if _chalkboard_material != null:
		return _chalkboard_material
	var width := 160
	var height := 108
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.1, 0.2, 0.16))
	var chalk := Color(0.92, 0.92, 0.85)
	# Axes.
	for y in range(10, height - 14):
		image.set_pixel(22, y, chalk)
		image.set_pixel(23, y, chalk)
	for x in range(22, width - 12):
		image.set_pixel(x, height - 16, chalk)
		image.set_pixel(x, height - 15, chalk)
	# Supply (rising) and demand (falling) curves, crossing at the price.
	for i in 100:
		var t := i / 99.0
		var sx := 28 + int(t * 100.0)
		var sy := (height - 22) - int(pow(t, 1.35) * 70.0)
		var dy := 18 + int(pow(t, 0.8) * 62.0)
		for dy2 in 2:
			image.set_pixel(sx, clampi(sy + dy2, 0, height - 1), Color(0.95, 0.8, 0.35))
			image.set_pixel(sx, clampi(dy + dy2, 0, height - 1), Color(0.6, 0.85, 0.95))
	# The equilibrium: dotted guide lines.
	for k in range(0, 60, 4):
		image.set_pixel(76, height - 20 - k, chalk)
		image.set_pixel(30 + k, 52, chalk)
	_chalkboard_material = StandardMaterial3D.new()
	_chalkboard_material.albedo_texture = ImageTexture.create_from_image(image)
	_chalkboard_material.roughness = 1.0
	return _chalkboard_material


static func _get_coin_flag_material() -> StandardMaterial3D:
	if _coin_flag_material != null:
		return _coin_flag_material
	var width := 104
	var height := 68
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.85, 0.65, 0.12))
	var center := Vector2(width * 0.5, height * 0.5)
	for x in width:
		for y in height:
			var d := Vector2(x, y).distance_to(center)
			if d < 22.0 and d > 18.0:
				image.set_pixel(x, y, Color(0.08, 0.06, 0.04))
			elif d <= 18.0 and (absi(x - int(center.x)) < 2 and absi(y - int(center.y)) < 15):
				image.set_pixel(x, y, Color(0.08, 0.06, 0.04))
	_coin_flag_material = StandardMaterial3D.new()
	_coin_flag_material.albedo_texture = ImageTexture.create_from_image(image)
	_coin_flag_material.roughness = 0.9
	_coin_flag_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return _coin_flag_material


## A long hanging banner: red field, gold star, dark border (painted once).
static func _get_banner_material() -> StandardMaterial3D:
	if _banner_material != null:
		return _banner_material
	var width := 64
	var height := 112
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(RED)
	for x in width:
		for y in height:
			if x < 3 or x >= width - 3 or y < 3 or y >= height - 3:
				image.set_pixel(x, y, Color(0.12, 0.02, 0.02))
	var star := PackedVector2Array()
	var center := Vector2(width * 0.5, height * 0.4)
	for i in 10:
		var angle := -PI * 0.5 + i * PI / 5.0
		star.append(center + Vector2(cos(angle), sin(angle)) * (22.0 if i % 2 == 0 else 9.0))
	for x in width:
		for y in height:
			if Geometry2D.is_point_in_polygon(Vector2(x, y), star):
				image.set_pixel(x, y, Color(0.93, 0.76, 0.2))
	_banner_material = StandardMaterial3D.new()
	_banner_material.albedo_texture = ImageTexture.create_from_image(image)
	_banner_material.roughness = 0.9
	_banner_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return _banner_material


## A ruined concrete shell (for the walls on the map): dark, windowed, no roof detail.
static func ruin_material(height: float) -> ShaderMaterial:
	return _facade(Color(0.3, 0.3, 0.29), 2.0, 1.6, Vector2(0.5, 0.5), height * 0.5, 0.0)


# --- Building blocks --------------------------------------------------------

static func _add_box(parent: Node3D, size: Vector3, center: Vector3, material: Material, rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = center
	instance.rotation = rotation
	parent.add_child(instance)
	return instance


static func _add_cylinder(parent: Node3D, radius: float, height: float, center: Vector3, material: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = center
	parent.add_child(instance)
	return instance


static func _add_banner(parent: Node3D, center: Vector3, size: Vector2) -> void:
	var mesh := QuadMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = _get_banner_material()
	instance.position = center
	parent.add_child(instance)


## A two-sided pitched roof (ridge along x) with an overhang.
static func _gable_roof(parent: Node3D, width_x: float, depth_z: float, rise: float, overhang: float, base_y: float, material: Material) -> MeshInstance3D:
	var a := width_x * 0.5 + overhang
	var b := depth_z * 0.5 + overhang
	var corner_a := Vector3(-a, 0, -b)
	var corner_b := Vector3(a, 0, -b)
	var corner_c := Vector3(a, 0, b)
	var corner_d := Vector3(-a, 0, b)
	var ridge_1 := Vector3(-a, rise, 0)
	var ridge_2 := Vector3(a, rise, 0)
	var inside := Vector3(0, rise * 0.3, 0)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	_triangle(surface, corner_a, corner_b, ridge_2, inside)
	_triangle(surface, corner_a, ridge_2, ridge_1, inside)
	_triangle(surface, corner_c, corner_d, ridge_1, inside)
	_triangle(surface, corner_c, ridge_1, ridge_2, inside)
	_triangle(surface, corner_a, ridge_1, corner_d, inside)
	_triangle(surface, corner_b, corner_c, ridge_2, inside)
	_triangle(surface, corner_a, corner_d, corner_c, inside)
	_triangle(surface, corner_a, corner_c, corner_b, inside)
	surface.generate_normals()
	var instance := MeshInstance3D.new()
	instance.mesh = surface.commit()
	instance.material_override = material
	instance.position = Vector3(0, base_y, 0)
	parent.add_child(instance)
	return instance


## Adds a triangle wound so it faces away from `inside` (Godot's front faces are clockwise).
static func _triangle(surface: SurfaceTool, p0: Vector3, p1: Vector3, p2: Vector3, inside: Vector3) -> void:
	var normal := (p1 - p0).cross(p2 - p0)
	var centroid := (p0 + p1 + p2) / 3.0
	if normal.dot(centroid - inside) > 0.0:
		var swap := p1
		p1 = p2
		p2 = swap
	surface.add_vertex(p0)
	surface.add_vertex(p1)
	surface.add_vertex(p2)


# --- Materials --------------------------------------------------------------

## Concrete wall with a grid of window slits (or plain if `windows` is false).
static func _facade(color: Color, floor_height: float, column_spacing: float, window_size: Vector2, bottom: float, lit_chance: float = 0.08, windows: bool = true) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = FACADE
	material.set_shader_parameter("concrete_color", color)
	material.set_shader_parameter("floor_height", floor_height)
	material.set_shader_parameter("column_spacing", column_spacing)
	material.set_shader_parameter("window_size", window_size)
	material.set_shader_parameter("bottom", bottom)
	material.set_shader_parameter("lit_chance", lit_chance)
	material.set_shader_parameter("windows_on", 1.0 if windows else 0.0)
	return material


static func _craft(kind: int, color_a: Color, color_b: Color, texture_scale: float = 1.0) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = CRAFT
	material.set_shader_parameter("kind", kind)
	material.set_shader_parameter("color_a", color_a)
	material.set_shader_parameter("color_b", color_b)
	material.set_shader_parameter("scale", texture_scale)
	return material


static func _plain(color: Color, roughness: float = 0.9, metallic: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material
