class_name UnitArt
extends RefCounted
## Procedural figures for the units, built from primitives and animated by
## UnitModel. The Collectivists are one identical, stocky figure in a red
## greatcoat and fur hat: a mass in uniform. The Libertarians are individuals:
## each one gets its own coat, hat, skin, gear and build (seeded by the unit),
## with a gold scarf to read as one side from far away.
## Figures stand on the ground at the origin and face -Z.

const RED_COAT := Color(0.5, 0.1, 0.09)
const GOLD := Color(0.9, 0.7, 0.15)
const SKINS: Array[Color] = [Color(0.88, 0.7, 0.56), Color(0.72, 0.54, 0.42), Color(0.52, 0.37, 0.28), Color(0.93, 0.8, 0.68)]
const HAIRS: Array[Color] = [Color(0.12, 0.09, 0.07), Color(0.3, 0.2, 0.12), Color(0.55, 0.4, 0.2), Color(0.46, 0.46, 0.46)]
const COATS: Array[Color] = [Color(0.27, 0.31, 0.22), Color(0.33, 0.26, 0.19), Color(0.22, 0.26, 0.32), Color(0.38, 0.33, 0.26), Color(0.2, 0.2, 0.21), Color(0.36, 0.22, 0.16)]
const CIVILIAN_COATS: Array[Color] = [Color(0.45, 0.4, 0.33), Color(0.4, 0.45, 0.5), Color(0.5, 0.35, 0.25), Color(0.35, 0.42, 0.3), Color(0.55, 0.5, 0.4)]
const TROUSERS: Array[Color] = [Color(0.2, 0.2, 0.22), Color(0.28, 0.23, 0.17), Color(0.18, 0.22, 0.27), Color(0.3, 0.27, 0.22)]
const BOOTS := Color(0.1, 0.08, 0.07)
const METAL := Color(0.14, 0.14, 0.15)
const WOOD := Color(0.32, 0.22, 0.14)


static func build(def: UnitDef, seed_value: int) -> UnitModel:
	var model := UnitModel.new()
	model.name = "Model"
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var variation := 1.0
	match def.id:
		&"collectivist_conscript":
			_conscript(model)
		&"collectivist_laborer":
			_laborer(model)
		&"libertarian_freeholder":
			_freeholder(model, rng)
			variation = rng.randf_range(0.94, 1.07)
		&"libertarian_volunteer":
			_volunteer(model, rng)
			variation = rng.randf_range(0.92, 1.06)
		&"libertarian_prospector":
			_prospector(model, rng)
			variation = rng.randf_range(0.94, 1.05)
		_:
			_generic(model, def)
	model.scale = Vector3.ONE * (def.size.y / 1.8) * variation
	return model


# --- Collectivists: identical, stocky, in uniform ---------------------------

static func _conscript(m: UnitModel) -> void:
	_figure(m, {
		"stock": 1.28, "coat": RED_COAT, "trousers": Color(0.17, 0.11, 0.1), "skin": Color(0.8, 0.62, 0.5),
		"long_coat": true, "hat": &"ushanka", "hat_color": Color(0.33, 0.33, 0.34),
	})
	m.stride = 0.8
	m.melee = true
	_rifle(m, 1.1, true)


static func _laborer(m: UnitModel) -> void:
	_figure(m, {
		"stock": 1.2, "coat": Color(0.88, 0.45, 0.1), "trousers": Color(0.2, 0.15, 0.13), "skin": Color(0.8, 0.62, 0.5),
		"hat": &"hardhat", "hat_color": Color(0.92, 0.6, 0.08),
	})
	m.stride = 0.85
	_tool(m, &"shovel")


# --- Libertarians: individuals ----------------------------------------------

static func _freeholder(m: UnitModel, rng: RandomNumberGenerator) -> void:
	var hats: Array[StringName] = [&"cowboy", &"cowboy", &"cap", &"wide", &"none"]
	_figure(m, {
		"stock": rng.randf_range(0.92, 1.05), "coat": COATS[rng.randi() % COATS.size()], "trousers": TROUSERS[rng.randi() % TROUSERS.size()],
		"skin": SKINS[rng.randi() % SKINS.size()], "hair": HAIRS[rng.randi() % HAIRS.size()],
		"long_coat": rng.randf() < 0.7, "hat": hats[rng.randi() % hats.size()],
		"hat_color": COATS[rng.randi() % COATS.size()].darkened(0.1), "scarf": GOLD,
		"gear": [&"backpack", &"bandolier", &"none"][rng.randi() % 3],
	})
	_rifle(m, 1.35, false)


static func _volunteer(m: UnitModel, rng: RandomNumberGenerator) -> void:
	var hats: Array[StringName] = [&"cap", &"cap", &"none", &"wide"]
	_figure(m, {
		"stock": rng.randf_range(0.9, 1.05), "coat": CIVILIAN_COATS[rng.randi() % CIVILIAN_COATS.size()], "trousers": TROUSERS[rng.randi() % TROUSERS.size()],
		"skin": SKINS[rng.randi() % SKINS.size()], "hair": HAIRS[rng.randi() % HAIRS.size()],
		"hat": hats[rng.randi() % hats.size()], "hat_color": CIVILIAN_COATS[rng.randi() % CIVILIAN_COATS.size()].darkened(0.2),
		"scarf": GOLD, "gear": [&"backpack", &"none"][rng.randi() % 2],
	})
	_rifle(m, 0.95, false)


static func _prospector(m: UnitModel, rng: RandomNumberGenerator) -> void:
	_figure(m, {
		"stock": rng.randf_range(0.9, 1.0), "coat": Color(0.3, 0.5, 0.36), "trousers": TROUSERS[rng.randi() % TROUSERS.size()],
		"skin": SKINS[rng.randi() % SKINS.size()], "hair": HAIRS[rng.randi() % HAIRS.size()],
		"hat": &"wide", "hat_color": Color(0.55, 0.45, 0.28), "scarf": GOLD, "gear": &"backpack",
	})
	_tool(m, &"pickaxe")


static func _generic(m: UnitModel, def: UnitDef) -> void:
	var instance := MeshInstance3D.new()
	if def.shape == UnitDef.Shape.CAPSULE:
		var capsule := CapsuleMesh.new()
		capsule.radius = def.size.x * 0.5
		capsule.height = def.size.y
		instance.mesh = capsule
	else:
		var box := BoxMesh.new()
		box.size = def.size
		instance.mesh = box
	instance.material_override = _plain(def.color)
	instance.position.y = def.size.y * 0.5
	m.add_child(instance)
	m.body = Node3D.new()
	m.add_child(m.body)


# --- Figure -----------------------------------------------------------------

## A humanoid from boxes and a sphere, with pivots for animation. `p` holds the
## look: stock (build width), coat, trousers, skin, hair, long_coat, hat,
## hat_color, scarf, gear.
static func _figure(m: UnitModel, p: Dictionary) -> void:
	var stock: float = p.get("stock", 1.0)
	var coat: Color = p["coat"]
	var skin: Color = p["skin"]
	var trousers: Color = p["trousers"]
	var hip := 0.78
	var torso_h := 0.62

	m.leg_left = _limb(m, Vector3(-0.12 * stock, hip, 0.0), Vector3(0.17 * stock, 0.78, 0.2 * stock), trousers, true)
	m.leg_right = _limb(m, Vector3(0.12 * stock, hip, 0.0), Vector3(0.17 * stock, 0.78, 0.2 * stock), trousers, true)

	m.body = Node3D.new()
	m.body.position = Vector3(0, hip, 0)
	m.add_child(m.body)
	_box(m.body, Vector3(0.46 * stock, torso_h, 0.28 * stock), Vector3(0, torso_h * 0.5, 0), coat)
	if p.get("long_coat", false):
		_box(m.body, Vector3(0.5 * stock, 0.42, 0.31 * stock), Vector3(0, -0.14, 0), coat.darkened(0.08))
	var head_y := torso_h + 0.17
	_sphere(m.body, 0.14, Vector3(0, head_y, 0), skin)
	_hair(m.body, p, head_y)
	_hat(m.body, p.get("hat", &"none"), p.get("hat_color", Color.GRAY), head_y)
	if p.has("scarf"):
		_box(m.body, Vector3(0.3 * stock, 0.08, 0.22 * stock), Vector3(0, torso_h + 0.01, 0), p["scarf"])
		_box(m.body, Vector3(0.07, 0.24, 0.03), Vector3(0.08, torso_h - 0.13, -0.15 * stock), p["scarf"])
	_gear(m, p.get("gear", &"none"), stock, torso_h)

	m.arm_left = _limb(m.body, Vector3(-0.3 * stock, torso_h - 0.08, 0.0), Vector3(0.12, 0.6, 0.14), coat, false, skin)
	m.arm_right = _limb(m.body, Vector3(0.3 * stock, torso_h - 0.08, 0.0), Vector3(0.12, 0.6, 0.14), coat, false, skin)


## A hinged limb: a pivot at the joint with the limb hanging below it.
static func _limb(parent: Node3D, joint: Vector3, size: Vector3, color: Color, boot: bool, hand: Color = Color.TRANSPARENT) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = joint
	parent.add_child(pivot)
	_box(pivot, size, Vector3(0, -size.y * 0.5, 0), color)
	if boot:
		_box(pivot, Vector3(size.x * 1.05, 0.1, size.z * 1.5), Vector3(0, -size.y + 0.05, -size.z * 0.25), BOOTS)
	if hand.a > 0.0:
		_box(pivot, Vector3(size.x * 0.9, 0.1, size.z * 0.9), Vector3(0, -size.y - 0.02, 0), hand)
	return pivot


static func _hair(body: Node3D, p: Dictionary, head_y: float) -> void:
	if not p.has("hair"):
		return
	_box(body, Vector3(0.27, 0.1, 0.27), Vector3(0, head_y + 0.1, 0.02), p["hair"])


static func _hat(body: Node3D, kind: StringName, color: Color, head_y: float) -> void:
	var top := head_y + 0.12
	match kind:
		&"ushanka":
			_box(body, Vector3(0.36, 0.17, 0.36), Vector3(0, top + 0.02, 0), color)
			for side in [-1.0, 1.0]:
				_box(body, Vector3(0.07, 0.2, 0.22), Vector3(side * 0.2, head_y - 0.02, 0.02), color.darkened(0.1))
			_box(body, Vector3(0.09, 0.09, 0.03), Vector3(0, top + 0.03, -0.19), Color(0.85, 0.08, 0.08))
		&"hardhat":
			_sphere(body, 0.17, Vector3(0, top - 0.03, 0), color, Vector3(1.0, 0.7, 1.0))
			_box(body, Vector3(0.3, 0.03, 0.12), Vector3(0, top - 0.1, -0.17), color)
		&"cowboy":
			_cylinder(body, 0.3, 0.03, Vector3(0, top - 0.02, 0), color)
			_cylinder(body, 0.14, 0.16, Vector3(0, top + 0.07, 0), color)
		&"wide":
			_cylinder(body, 0.36, 0.025, Vector3(0, top - 0.02, 0), color.lightened(0.1))
			_cylinder(body, 0.14, 0.1, Vector3(0, top + 0.04, 0), color.lightened(0.1))
		&"cap":
			_box(body, Vector3(0.3, 0.07, 0.3), Vector3(0, top, 0), color)
			_box(body, Vector3(0.24, 0.025, 0.12), Vector3(0, top - 0.02, -0.2), color.darkened(0.2))


static func _gear(m: UnitModel, kind: StringName, stock: float, torso_h: float) -> void:
	match kind:
		&"backpack":
			_box(m.body, Vector3(0.34 * stock, 0.42, 0.18), Vector3(0, torso_h * 0.5, 0.22 * stock), Color(0.3, 0.24, 0.16))
			_box(m.body, Vector3(0.3 * stock, 0.12, 0.2), Vector3(0, torso_h + 0.0, 0.22 * stock), Color(0.38, 0.3, 0.2))
		&"bandolier":
			var strap := _box(m.body, Vector3(0.07, 0.75, 0.04), Vector3(0, torso_h * 0.5, -0.15 * stock), Color(0.22, 0.15, 0.1))
			strap.rotation.z = 0.7


## A long gun held across the body (the arms pose around it). The muzzle flash
## sits at its tip.
static func _rifle(m: UnitModel, length: float, bayonet: bool) -> void:
	var gun := Node3D.new()
	gun.position = Vector3(0.1, 0.4, -0.28)
	m.body.add_child(gun)
	m.weapon = gun
	_box(gun, Vector3(0.05, 0.06, length), Vector3(0, 0, -length * 0.3), METAL)
	_box(gun, Vector3(0.06, 0.1, length * 0.35), Vector3(0, -0.02, length * 0.12), WOOD)
	var muzzle := -length * 0.8
	if bayonet:
		_box(gun, Vector3(0.02, 0.02, 0.32), Vector3(0, 0.0, muzzle - 0.14), Color(0.7, 0.7, 0.72))
		muzzle -= 0.3
	var flash_mesh := SphereMesh.new()
	flash_mesh.radius = 0.12
	flash_mesh.height = 0.24
	var flash_material := StandardMaterial3D.new()
	flash_material.albedo_color = Color(1.0, 0.85, 0.4)
	flash_material.emission_enabled = true
	flash_material.emission = Color(1.0, 0.8, 0.3)
	flash_material.emission_energy_multiplier = 4.0
	flash_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var flash := MeshInstance3D.new()
	flash.mesh = flash_mesh
	flash.material_override = flash_material
	flash.position = Vector3(0, 0, muzzle - 0.08)
	flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	gun.add_child(flash)
	m.flash = flash


## A work tool carried in the right hand and swung while working.
static func _tool(m: UnitModel, kind: StringName) -> void:
	var tool := Node3D.new()
	tool.position = Vector3(0, -0.55, 0)
	m.arm_right.add_child(tool)
	m.tool_node = tool
	_box(tool, Vector3(0.045, 0.95, 0.045), Vector3(0, -0.3, 0), WOOD)
	if kind == &"shovel":
		_box(tool, Vector3(0.22, 0.3, 0.025), Vector3(0, -0.85, 0), Color(0.55, 0.55, 0.57))
	else:
		_box(tool, Vector3(0.5, 0.06, 0.06), Vector3(0, -0.78, 0), Color(0.5, 0.5, 0.52))


# --- Primitives -------------------------------------------------------------

static func _box(parent: Node3D, size: Vector3, center: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = _plain(color)
	instance.position = center
	parent.add_child(instance)
	return instance


static func _sphere(parent: Node3D, radius: float, center: Vector3, color: Color, squash: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 10
	mesh.rings = 6
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = _plain(color)
	instance.position = center
	instance.scale = squash
	parent.add_child(instance)
	return instance


static func _cylinder(parent: Node3D, radius: float, height: float, center: Vector3, color: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = _plain(color)
	instance.position = center
	parent.add_child(instance)
	return instance


static func _plain(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	return material
