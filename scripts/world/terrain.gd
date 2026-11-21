class_name Terrain
extends Node3D
## Flat placeholder map: a gridded ground plane plus a collider for mouse picking.

@export var map_size: Vector2 = Vector2(128, 128)
@export var tile_size: float = 4.0


func _ready() -> void:
	var plane := PlaneMesh.new()
	plane.size = map_size
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = plane
	mesh_instance.material_override = _make_grid_material()
	add_child(mesh_instance)

	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(map_size.x, 1.0, map_size.y)
	shape.shape = box
	shape.position.y = -0.5
	body.add_child(shape)
	add_child(body)


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
