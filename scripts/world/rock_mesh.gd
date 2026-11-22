class_name RockMesh
extends RefCounted
## A rough, low-poly rock: a squashed icosahedron with jittered corners and
## flat-shaded faces. Shared by the scattered debris, deposits and wreckage.

const ICOSAHEDRON_FACES: Array[Array] = [
	[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11],
	[1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6], [7, 1, 8],
	[3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9],
	[4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1],
]

static var _cache: Dictionary = {}


## The rock for a given seed (cached; unit radius).
static func create(rock_seed: int = 99) -> ArrayMesh:
	if _cache.has(rock_seed):
		return _cache[rock_seed]
	var t := (1.0 + sqrt(5.0)) * 0.5
	var corners: Array[Vector3] = [
		Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0),
		Vector3(0, -1, t), Vector3(0, 1, t), Vector3(0, -1, -t), Vector3(0, 1, -t),
		Vector3(t, 0, -1), Vector3(t, 0, 1), Vector3(-t, 0, -1), Vector3(-t, 0, 1),
	]
	var rng := RandomNumberGenerator.new()
	rng.seed = rock_seed
	for i in corners.size():
		corners[i] = corners[i].normalized() * rng.randf_range(0.72, 1.12)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	for face in ICOSAHEDRON_FACES:
		# Reversed so the faces point outwards in Godot's winding order.
		surface.add_vertex(corners[face[0]])
		surface.add_vertex(corners[face[2]])
		surface.add_vertex(corners[face[1]])
	surface.generate_normals()
	var mesh := surface.commit()
	_cache[rock_seed] = mesh
	return mesh
