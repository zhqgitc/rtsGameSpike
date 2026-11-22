class_name Props
extends Node3D
## Battlefield debris: scattered rocks and broken concrete slabs, in clusters,
## kept away from bases, deposits and walls. Purely decorative (no collision,
## not part of the navigation mesh). Grouped in chunks so the fog of war can
## hide the ones the player has not explored.

const CHUNK_SIZE := 16.0
## Debris density rises from nothing at a cleared area's edge to normal this far out.
const CLEAR_FADE := 14.0
const ROCK_COUNT := 650
const SLAB_COUNT := 140
const ICOSAHEDRON_FACES: Array[Array] = [
	[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11],
	[1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6], [7, 1, 8],
	[3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9],
	[4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1],
]

## One entry per chunk, aligned: its ground rectangle and the node holding its props.
var chunk_rects: Array[Rect2] = []
var chunk_roots: Array[Node3D] = []

var _rng := RandomNumberGenerator.new()


## Scatter props over the map, avoiding the given ground rectangles.
func scatter(map_size: Vector2, exclusions: Array[Rect2]) -> void:
	for root in chunk_roots:
		root.queue_free()
	chunk_rects.clear()
	chunk_roots.clear()
	_rng.seed = 7

	var cols := ceili(map_size.x / CHUNK_SIZE)
	var rows := ceili(map_size.y / CHUNK_SIZE)
	var origin := -map_size * 0.5
	# Per chunk: transforms and colours for rocks and slabs.
	var rocks: Array = []
	var slabs: Array = []
	for i in cols * rows:
		rocks.append([])
		slabs.append([])

	var clusters := FastNoiseLite.new()
	clusters.frequency = 0.035
	clusters.seed = 3
	_collect(ROCK_COUNT, map_size, origin, cols, rows, clusters, exclusions, rocks, false)
	_collect(SLAB_COUNT, map_size, origin, cols, rows, clusters, exclusions, slabs, true)

	var rock_mesh := _make_rock_mesh()
	var slab_mesh := BoxMesh.new()
	slab_mesh.size = Vector3.ONE
	var rock_material := _make_material(Color(0.2, 0.19, 0.175))
	var slab_material := _make_material(Color(0.36, 0.35, 0.33))

	for row in rows:
		for col in cols:
			var index := row * cols + col
			var chunk_origin := origin + Vector2(col, row) * CHUNK_SIZE
			var root := Node3D.new()
			add_child(root)
			chunk_roots.append(root)
			chunk_rects.append(Rect2(chunk_origin, Vector2(CHUNK_SIZE, CHUNK_SIZE)))
			_add_multimesh(root, rock_mesh, rock_material, rocks[index])
			_add_multimesh(root, slab_mesh, slab_material, slabs[index])


func _collect(count: int, map_size: Vector2, origin: Vector2, cols: int, rows: int, clusters: FastNoiseLite, exclusions: Array[Rect2], into: Array, slab: bool) -> void:
	var placed := 0
	var attempts := 0
	while placed < count and attempts < count * 12:
		attempts += 1
		var x := _rng.randf_range(origin.x + 1.0, origin.x + map_size.x - 1.0)
		var z := _rng.randf_range(origin.y + 1.0, origin.y + map_size.y - 1.0)
		# Props thin out gradually towards cleared areas instead of stopping at a line.
		var clearance := _clearance_weight(Vector2(x, z), exclusions)
		# Props gather in clusters rather than spreading evenly.
		var density := clampf(clusters.get_noise_2d(x, z) + 0.65, 0.08, 1.0) * clearance
		if _rng.randf() > density:
			continue
		var col := clampi(floori((x - origin.x) / CHUNK_SIZE), 0, cols - 1)
		var row := clampi(floori((z - origin.y) / CHUNK_SIZE), 0, rows - 1)
		into[row * cols + col].append(_slab_transform(x, z) if slab else _rock_transform(x, z))
		placed += 1


func _rock_transform(x: float, z: float) -> Transform3D:
	var size := _rng.randf_range(0.22, 1.05)
	var basis := Basis.from_euler(Vector3(_rng.randf_range(-0.25, 0.25), _rng.randf_range(0.0, TAU), _rng.randf_range(-0.25, 0.25)))
	basis = basis.scaled(Vector3(size, size * _rng.randf_range(0.5, 0.95), size * _rng.randf_range(0.8, 1.2)))
	return Transform3D(basis, Vector3(x, size * 0.12, z))


func _slab_transform(x: float, z: float) -> Transform3D:
	var basis := Basis.from_euler(Vector3(_rng.randf_range(-0.22, 0.22), _rng.randf_range(0.0, TAU), _rng.randf_range(-0.22, 0.22)))
	basis = basis.scaled(Vector3(_rng.randf_range(1.2, 3.2), _rng.randf_range(0.16, 0.3), _rng.randf_range(0.9, 2.2)))
	return Transform3D(basis, Vector3(x, 0.08, z))


## 0 inside a cleared rectangle, rising to 1 at CLEAR_FADE metres away from all of them.
func _clearance_weight(point: Vector2, exclusions: Array[Rect2]) -> float:
	var nearest := INF
	for rect in exclusions:
		var dx := maxf(maxf(rect.position.x - point.x, 0.0), point.x - rect.end.x)
		var dy := maxf(maxf(rect.position.y - point.y, 0.0), point.y - rect.end.y)
		nearest = minf(nearest, sqrt(dx * dx + dy * dy))
	return clampf(nearest / CLEAR_FADE, 0.0, 1.0)


func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.95
	return material


func _add_multimesh(root: Node3D, mesh: Mesh, material: Material, items: Array) -> void:
	if items.is_empty():
		return
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = items.size()
	for i in items.size():
		multimesh.set_instance_transform(i, items[i])
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	instance.material_override = material
	root.add_child(instance)


## A rough, low-poly rock: a squashed icosahedron with jittered corners and
## flat-shaded faces.
func _make_rock_mesh() -> ArrayMesh:
	var t := (1.0 + sqrt(5.0)) * 0.5
	var corners: Array[Vector3] = [
		Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0),
		Vector3(0, -1, t), Vector3(0, 1, t), Vector3(0, -1, -t), Vector3(0, 1, -t),
		Vector3(t, 0, -1), Vector3(t, 0, 1), Vector3(-t, 0, -1), Vector3(-t, 0, 1),
	]
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
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
	return surface.commit()
