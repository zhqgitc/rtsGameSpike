class_name DepositArt
extends RefCounted
## A deposit of Materials: a heap of rubble and rusting scrap, with steel
## girders sticking out and a few glinting lumps of copper ore on top.


static func build(radius: float, art_seed: int) -> Node3D:
	var root := Node3D.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = art_seed
	var rubble := _material(Color(0.27, 0.2, 0.15), 0.95, 0.0)
	var rust := _material(Color(0.4, 0.21, 0.12), 0.85, 0.3)
	var steel := _material(Color(0.2, 0.2, 0.22), 0.5, 0.6)
	var ore := StandardMaterial3D.new()
	ore.albedo_color = Color(0.8, 0.42, 0.16)
	ore.metallic = 0.7
	ore.roughness = 0.35
	ore.emission_enabled = true
	ore.emission = Color(0.55, 0.24, 0.06)
	ore.emission_energy_multiplier = 0.5

	# The mound and the lumps around its foot.
	_rock(root, Vector3(0, 0.3, 0), Vector3(radius * 0.95, 0.75, radius * 0.95), rng.randf() * TAU, rubble)
	for i in 8:
		var angle := i * TAU / 8.0 + rng.randf_range(-0.2, 0.2)
		var distance := radius * rng.randf_range(0.62, 0.9)
		var size := rng.randf_range(0.28, 0.5)
		_rock(root, Vector3(cos(angle) * distance, size * 0.3, sin(angle) * distance), Vector3(size, size * 0.8, size), rng.randf() * TAU, rust if i % 3 == 0 else rubble)
	# Girders and plates poking out.
	for i in 5:
		var girder := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.14, 0.14, rng.randf_range(1.4, 2.2))
		girder.mesh = box
		girder.material_override = rust if i % 2 == 0 else steel
		girder.position = Vector3(rng.randf_range(-0.5, 0.5), rng.randf_range(0.5, 0.9), rng.randf_range(-0.5, 0.5))
		girder.rotation = Vector3(rng.randf_range(-0.7, 0.7), rng.randf() * TAU, rng.randf_range(-0.5, 0.5))
		root.add_child(girder)
	for i in 3:
		var plate := MeshInstance3D.new()
		var slab := BoxMesh.new()
		slab.size = Vector3(rng.randf_range(0.6, 1.0), 0.06, rng.randf_range(0.5, 0.8))
		plate.mesh = slab
		plate.material_override = steel
		plate.position = Vector3(rng.randf_range(-0.8, 0.8), rng.randf_range(0.2, 0.7), rng.randf_range(-0.8, 0.8))
		plate.rotation = Vector3(rng.randf_range(-0.5, 0.5), rng.randf() * TAU, rng.randf_range(-0.5, 0.5))
		root.add_child(plate)
	# The ore itself.
	for i in 6:
		var angle := rng.randf() * TAU
		var distance := rng.randf_range(0.0, radius * 0.55)
		var size := rng.randf_range(0.18, 0.32)
		_rock(root, Vector3(cos(angle) * distance, 0.62 + rng.randf() * 0.25, sin(angle) * distance), Vector3(size, size, size), rng.randf() * TAU, ore)
	return root


static func _rock(parent: Node3D, center: Vector3, scale: Vector3, yaw: float, material: Material) -> void:
	var instance := MeshInstance3D.new()
	instance.mesh = RockMesh.create(99)
	instance.material_override = material
	instance.position = center
	instance.scale = scale
	instance.rotation.y = yaw
	parent.add_child(instance)


static func _material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material
