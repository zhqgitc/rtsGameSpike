class_name Terrain
extends NavigationRegion3D
## Placeholder map: gridded ground plane, a few obstacles, and the navigation
## mesh baked from them at startup.

@export var map_size: Vector2 = Vector2(128, 128)
@export var tile_size: float = 4.0
## Temporary hard-coded obstacles as Rect2(x, z, width, depth) on the ground,
## until maps become data.
@export var obstacles: Array[Rect2] = [
	Rect2(-4, -12, 8, 24),
	Rect2(-20, 10, 10, 6),
	Rect2(12, -20, 6, 10),
]
@export var obstacle_height: float = 4.0


func _ready() -> void:
	var plane := PlaneMesh.new()
	plane.size = map_size
	var ground := MeshInstance3D.new()
	ground.mesh = plane
	ground.material_override = _make_grid_material()
	add_child(ground)

	var concrete := StandardMaterial3D.new()
	concrete.albedo_color = Color(0.45, 0.45, 0.48)
	for rect in obstacles:
		var box := BoxMesh.new()
		box.size = Vector3(rect.size.x, obstacle_height, rect.size.y)
		var block := MeshInstance3D.new()
		block.mesh = box
		block.material_override = concrete
		block.position = Vector3(rect.position.x + rect.size.x * 0.5, obstacle_height * 0.5, rect.position.y + rect.size.y * 0.5)
		add_child(block)
		var block_body := StaticBody3D.new()
		var block_shape := CollisionShape3D.new()
		var block_box := BoxShape3D.new()
		block_box.size = box.size
		block_shape.shape = block_box
		block_body.add_child(block_shape)
		block_body.position = block.position
		add_child(block_body)

	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var floor_box := BoxShape3D.new()
	floor_box.size = Vector3(map_size.x, 1.0, map_size.y)
	shape.shape = floor_box
	shape.position.y = -0.5
	body.add_child(shape)
	add_child(body)

	_bake_navigation()


func _bake_navigation() -> void:
	var nav := NavigationMesh.new()
	# Bake from collision shapes: parsing visual meshes at runtime stalls the GPU.
	nav.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nav.agent_radius = 0.5
	navigation_mesh = nav
	bake_navigation_mesh(false)


func _make_grid_material() -> StandardMaterial3D:
	var img := Image.create(64, 64, true, Image.FORMAT_RGB8)
	img.fill(Color(0.32, 0.38, 0.27))
	var line := Color(0.24, 0.29, 0.2)
	for i in 64:
		for t in 2:
			img.set_pixel(i, t, line)
			img.set_pixel(t, i, line)
	img.generate_mipmaps()
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = ImageTexture.create_from_image(img)
	mat.uv1_scale = Vector3(map_size.x / tile_size, map_size.y / tile_size, 1.0)
	mat.roughness = 1.0
	return mat
