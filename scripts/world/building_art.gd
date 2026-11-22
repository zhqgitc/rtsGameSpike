class_name BuildingArt
extends RefCounted
## Procedural models for the buildings, assembled from primitives and
## procedural materials. The Collectivists build brutalist concrete: massive
## stepped blocks, slit windows, heavy cornices, red banners. The Libertarians
## build by hand: brick and timber, pitched rusty roofs, awnings and crates.
## Each model fits its building's footprint (def.size.x by def.size.z) and
## stands on the ground at the origin. Chosen by BuildingDef.visual.

const FACADE := preload("res://assets/shaders/facade.gdshader")
const CRAFT := preload("res://assets/shaders/craft.gdshader")

const KIND_PLANKS := 0
const KIND_BRICK := 1
const KIND_METAL := 2
const KIND_CANVAS := 3

const CONCRETE := Color(0.39, 0.38, 0.36)
const CONCRETE_DARK := Color(0.28, 0.28, 0.28)
const RED := Color(0.62, 0.08, 0.08)
const GOLD := Color(0.85, 0.65, 0.12)

static var _banner_material: StandardMaterial3D


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

## Central Committee Block: a stepped ziggurat of raw concrete with a portal,
## a giant banner and flags.
static func _committee_block(root: Node3D, def: BuildingDef) -> void:
	var w := def.size.x
	var y := 0.0
	# Plinth and steps.
	_add_box(root, Vector3(w, 0.8, w), Vector3(0, 0.4, 0), _facade(CONCRETE_DARK, 1.0, 1.0, Vector2.ZERO, 0.4, 0.0, false))
	_add_box(root, Vector3(4.2, 0.3, 1.2), Vector3(0, 0.15, w * 0.5 + 0.5), _facade(CONCRETE, 1.0, 1.0, Vector2.ZERO, 0.15, 0.0, false))
	y = 0.8
	# Tier 1 with the portal.
	var t1 := w - 0.8
	_add_box(root, Vector3(t1, 3.2, t1), Vector3(0, y + 1.6, 0), _facade(CONCRETE, 1.6, 1.2, Vector2(0.3, 0.55), 1.6, 0.1))
	_add_box(root, Vector3(2.4, 2.3, 0.25), Vector3(0, y + 1.15, t1 * 0.5 + 0.02), _plain(Color(0.03, 0.03, 0.04)))
	for side in [-1.0, 1.0]:
		_add_box(root, Vector3(0.7, 3.0, 0.7), Vector3(side * 1.9, y + 1.5, t1 * 0.5 + 0.35), _facade(CONCRETE, 1.0, 1.0, Vector2.ZERO, 1.5, 0.0, false))
	y += 3.2
	_add_box(root, Vector3(t1 + 0.8, 0.35, t1 + 0.8), Vector3(0, y + 0.175, 0), _facade(CONCRETE_DARK, 1.0, 1.0, Vector2.ZERO, 0.175, 0.0, false))
	y += 0.35
	# Tier 2 with the banner and corner flags.
	var t2 := 6.4
	_add_box(root, Vector3(t2, 3.0, t2), Vector3(0, y + 1.5, 0), _facade(CONCRETE, 1.5, 1.1, Vector2(0.28, 0.55), 1.5, 0.12))
	_add_banner(root, Vector3(0, y + 1.6, t2 * 0.5 + 0.05), Vector2(2.4, 4.2))
	var tier2_top := y + 3.0
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_add_flag(root, Vector3(sx * (t2 * 0.5 - 0.3), tier2_top, sz * (t2 * 0.5 - 0.3)), 2.3, RED)
	y = tier2_top
	_add_box(root, Vector3(t2 + 0.6, 0.3, t2 + 0.6), Vector3(0, y + 0.15, 0), _facade(CONCRETE_DARK, 1.0, 1.0, Vector2.ZERO, 0.15, 0.0, false))
	y += 0.3
	# Tier 3 and the red crown.
	_add_box(root, Vector3(4.4, 2.6, 4.4), Vector3(0, y + 1.3, 0), _facade(CONCRETE, 1.3, 1.0, Vector2(0.3, 0.55), 1.3, 0.12))
	y += 2.6
	_add_box(root, Vector3(4.9, 0.45, 4.9), Vector3(0, y + 0.225, 0), _plain(def.accent_color, 0.8))


## Dormitory Block: a long, repetitive housing slab, rows of identical windows.
static func _dormitory(root: Node3D, def: BuildingDef) -> void:
	var w := def.size.x
	var d := def.size.z
	var h := 4.4
	_add_box(root, Vector3(w, h, d), Vector3(0, h * 0.5, 0), _facade(Color(0.5, 0.49, 0.46), 1.1, 0.95, Vector2(0.5, 0.45), h * 0.5, 0.14))
	_add_box(root, Vector3(w + 0.05, 0.3, d + 0.05), Vector3(0, h - 0.4, 0), _plain(def.accent_color, 0.85))
	_add_box(root, Vector3(w + 0.3, 0.3, d + 0.3), Vector3(0, h + 0.15, 0), _facade(CONCRETE_DARK, 1.0, 1.0, Vector2.ZERO, 0.15, 0.0, false))
	_add_box(root, Vector3(1.6, 1.3, 1.6), Vector3(w * 0.22, h + 0.3 + 0.65, -d * 0.22), _facade(CONCRETE, 1.0, 1.0, Vector2.ZERO, 0.65, 0.0, false))
	for x in [-1.0, 0.0]:
		_add_cylinder(root, 0.22, 0.7, Vector3(-w * 0.2 + x * 0.9, h + 0.3 + 0.35, d * 0.2), _plain(Color(0.2, 0.2, 0.2), 0.6, 0.3))
	_add_flag(root, Vector3(-w * 0.4, h + 0.3, -d * 0.4), 1.8, RED)


## Conscription Office: a heavy low block with a gate, a banner and a watch tower.
static func _conscription_office(root: Node3D, def: BuildingDef) -> void:
	var w := def.size.x
	var d := def.size.z
	var h := 3.4
	_add_box(root, Vector3(w, h, d), Vector3(0, h * 0.5, 0), _facade(CONCRETE, 1.7, 1.0, Vector2(0.28, 0.55), h * 0.5, 0.1))
	_add_box(root, Vector3(w + 0.3, 0.35, d + 0.3), Vector3(0, h + 0.175, 0), _facade(CONCRETE_DARK, 1.0, 1.0, Vector2.ZERO, 0.175, 0.0, false))
	_add_box(root, Vector3(w + 0.05, 0.3, d + 0.05), Vector3(0, h - 0.5, 0), _plain(def.accent_color, 0.85))
	# Gate with a massive lintel.
	_add_box(root, Vector3(2.4, 2.4, 0.3), Vector3(0.9, 1.2, d * 0.5 + 0.02), _plain(Color(0.03, 0.03, 0.04)))
	_add_box(root, Vector3(3.4, 0.35, 1.4), Vector3(0.9, 2.65, d * 0.5 + 0.5), _facade(CONCRETE_DARK, 1.0, 1.0, Vector2.ZERO, 0.175, 0.0, false))
	_add_banner(root, Vector3(-1.9, 2.2, d * 0.5 + 0.05), Vector2(1.6, 2.6))
	# Watch tower in the back corner.
	var tx := -w * 0.5 + 1.0
	var tz := -d * 0.5 + 1.0
	_add_box(root, Vector3(2.0, 6.4, 2.0), Vector3(tx, 3.2, tz), _facade(CONCRETE, 1.6, 0.9, Vector2(0.28, 0.55), 3.2, 0.1))
	_add_box(root, Vector3(2.7, 0.45, 2.7), Vector3(tx, 6.6, tz), _plain(def.accent_color, 0.85))
	for i in 2:
		_add_cylinder(root, 0.14, 0.5, Vector3(tx + (i * 2 - 1) * 0.8, 7.05, tz + 0.7), _plain(Color(0.9, 0.85, 0.6), 0.4, 0.2))
	_add_flag(root, Vector3(tx, 6.85, tz), 2.0, RED)


# --- Libertarians -----------------------------------------------------------

## Trading Post: brick ground floor, timber upper storey, gabled roof, awning, sign.
static func _trading_post(root: Node3D, def: BuildingDef) -> void:
	var brick := _craft(KIND_BRICK, Color(0.46, 0.21, 0.15), Color(0.36, 0.16, 0.13))
	var timber := _craft(KIND_PLANKS, Color(0.4, 0.32, 0.22), Color(0.3, 0.24, 0.17))
	var rust := _craft(KIND_METAL, Color(0.42, 0.21, 0.11), Color(0.28, 0.14, 0.09))
	_add_box(root, Vector3(4.6, 2.0, 4.4), Vector3(0, 1.0, 0), brick)
	_add_box(root, Vector3(4.2, 1.5, 4.0), Vector3(0, 2.75, 0), timber)
	_gable_roof(root, 4.2, 4.0, 1.0, 0.4, 3.5, rust)
	_add_box(root, Vector3(0.5, 1.6, 0.5), Vector3(1.4, 3.9, -0.8), brick)
	# Door, awning, sign.
	_add_box(root, Vector3(0.95, 1.5, 0.12), Vector3(0, 0.75, 2.22), _plain(Color(0.08, 0.06, 0.05)))
	_add_box(root, Vector3(3.8, 0.1, 1.5), Vector3(0, 2.05, 2.95), _craft(KIND_CANVAS, GOLD, Color(0.85, 0.8, 0.65)), Vector3(0.28, 0, 0))
	for x in [-1.75, 1.75]:
		_add_box(root, Vector3(0.14, 1.95, 0.14), Vector3(x, 0.975, 3.45), timber)
	_add_box(root, Vector3(1.2, 0.5, 0.08), Vector3(2.0, 1.75, 2.3), _plain(GOLD, 0.7))
	for crate in [[Vector3(-1.8, 0.3, 2.7), 0.6], [Vector3(-1.2, 0.25, 3.0), 0.5], [Vector3(1.9, 0.3, 3.0), 0.6]]:
		_add_box(root, Vector3.ONE * crate[1], crate[0], timber)


## Market: an open stall under a striped canvas roof, counter, crates, barrels.
static func _market(root: Node3D, def: BuildingDef) -> void:
	var timber := _craft(KIND_PLANKS, Color(0.42, 0.33, 0.22), Color(0.31, 0.24, 0.17))
	for sx in [-1.5, 1.5]:
		for sz in [-1.3, 1.3]:
			_add_cylinder(root, 0.08, 2.2, Vector3(sx, 1.1, sz), timber)
	_add_box(root, Vector3(3.9, 0.08, 3.5), Vector3(0, 2.3, 0), _craft(KIND_CANVAS, GOLD, Color(0.8, 0.76, 0.62)), Vector3(0.12, 0, 0))
	_add_box(root, Vector3(2.8, 0.9, 0.8), Vector3(0, 0.45, 0.9), timber)
	_add_box(root, Vector3(2.4, 0.06, 0.6), Vector3(0, 0.93, 0.9), _plain(Color(0.55, 0.5, 0.4)))
	for crate in [[Vector3(-1.4, 0.3, -0.9), 0.6], [Vector3(-0.8, 0.25, -1.1), 0.5], [Vector3(1.3, 0.3, -1.0), 0.6]]:
		_add_box(root, Vector3.ONE * crate[1], crate[0], timber)
	for x in [1.0, 1.55]:
		_add_cylinder(root, 0.28, 0.75, Vector3(x, 0.375, -0.2), _plain(Color(0.3, 0.22, 0.15), 0.9))


## Militia Hall: a timber longhouse with a gabled metal roof, flag and sandbags.
static func _militia_hall(root: Node3D, def: BuildingDef) -> void:
	var timber := _craft(KIND_PLANKS, Color(0.36, 0.3, 0.22), Color(0.27, 0.22, 0.16))
	var rust := _craft(KIND_METAL, Color(0.38, 0.2, 0.12), Color(0.26, 0.14, 0.09))
	_add_box(root, Vector3(4.3, 2.0, 3.2), Vector3(0, 1.0, -0.3), timber)
	var roof := _gable_roof(root, 4.3, 3.2, 1.0, 0.35, 2.0, rust)
	roof.position.z = -0.3 # the walls are shifted back a little to leave room for the sandbags
	_add_box(root, Vector3(1.0, 1.6, 0.12), Vector3(0, 0.8, 1.32), _plain(Color(0.07, 0.06, 0.05)))
	_add_flag(root, Vector3(1.8, 0.0, 1.7), 4.6, GOLD)
	var sandbag := _plain(Color(0.45, 0.4, 0.28), 1.0)
	for i in 7:
		var x := -1.8 + i * 0.6
		_add_box(root, Vector3(0.6, 0.28, 0.36), Vector3(x, 0.14, 2.0), sandbag, Vector3(0, 0.05 * (i % 3 - 1), 0))
		if i % 2 == 0 and i < 6:
			_add_box(root, Vector3(0.6, 0.28, 0.36), Vector3(x + 0.3, 0.42, 2.0), sandbag)


## Apprentice Workshop: a shed with a skylit roof, chimney, bench and log pile.
static func _workshop(root: Node3D, def: BuildingDef) -> void:
	var timber := _craft(KIND_PLANKS, Color(0.42, 0.34, 0.23), Color(0.32, 0.26, 0.18))
	var rust := _craft(KIND_METAL, Color(0.36, 0.2, 0.12), Color(0.25, 0.14, 0.1))
	_add_box(root, Vector3(3.6, 1.8, 3.4), Vector3(0, 0.9, 0), timber)
	_add_box(root, Vector3(3.9, 0.12, 3.7), Vector3(0, 2.0, 0), rust, Vector3(0.2, 0, 0))
	for x in [-0.9, 0.9]:
		_add_box(root, Vector3(0.9, 0.08, 0.8), Vector3(x, 2.28, -0.2), _plain(Color(0.2, 0.32, 0.34), 0.2, 0.0), Vector3(0.2, 0, 0))
	_add_cylinder(root, 0.22, 2.4, Vector3(1.3, 2.3, -1.0), _plain(Color(0.18, 0.17, 0.17), 0.6, 0.4))
	_add_box(root, Vector3(1.4, 0.8, 0.6), Vector3(-0.8, 0.4, 1.95), timber)
	_add_box(root, Vector3(0.4, 0.35, 0.3), Vector3(-0.7, 0.97, 1.95), _plain(Color(0.12, 0.12, 0.13), 0.5, 0.5))
	for i in 3:
		var log_node := _add_cylinder(root, 0.17, 1.3, Vector3(1.5, 0.17 + (i / 2) * 0.3, 1.75 - (i % 2) * 0.34 + (i / 2) * 0.17), timber)
		log_node.rotation = Vector3(0, 0, PI * 0.5)


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


static func _add_flag(parent: Node3D, base: Vector3, pole_height: float, color: Color) -> void:
	_add_cylinder(parent, 0.05, pole_height, base + Vector3(0, pole_height * 0.5, 0), _plain(Color(0.15, 0.15, 0.15), 0.5, 0.5))
	_add_box(parent, Vector3(1.0, 0.6, 0.03), base + Vector3(0.55, pole_height - 0.4, 0), _plain(color, 0.9), Vector3(0, 0.12, 0.05))


static func _add_banner(parent: Node3D, center: Vector3, size: Vector2) -> void:
	var mesh := QuadMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = _get_banner_material()
	instance.position = center
	parent.add_child(instance)


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
