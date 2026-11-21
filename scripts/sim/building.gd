class_name Building
extends Node3D
## A structure. For now: a solid obstacle on the navigation mesh and, if its
## definition says so, a delivery point for harvested resources.

const GROUP := &"buildings"
## Extra distance (beyond the footprint) from which units count as "at" it.
const REACH_MARGIN := 2.0

var def: BuildingDef


func setup(building_def: BuildingDef) -> void:
	def = building_def
	name = "%s_%d" % [def.id, get_instance_id()]
	add_to_group(GROUP)
	_build_visuals()
	_build_collider()


func accepts(resource: StringName) -> bool:
	return def.drop_off_resources.has(resource)


## Centre distance within which a unit standing next to the building counts as
## having reached it (footprint corner plus navmesh margin plus a little slack).
func reach() -> float:
	return maxf(def.size.x, def.size.z) * 0.5 * 1.45 + REACH_MARGIN


func _build_visuals() -> void:
	var box := BoxMesh.new()
	box.size = def.size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = def.color
	mat.roughness = 0.95
	var body := MeshInstance3D.new()
	body.mesh = box
	body.material_override = mat
	body.position.y = def.size.y * 0.5
	add_child(body)

	var band := BoxMesh.new()
	band.size = Vector3(def.size.x + 0.2, 0.5, def.size.z + 0.2)
	var band_mat := StandardMaterial3D.new()
	band_mat.albedo_color = def.accent_color
	var roof := MeshInstance3D.new()
	roof.mesh = band
	roof.material_override = band_mat
	# Raised a hair so the band's top doesn't z-fight with the body's top face.
	roof.position.y = def.size.y - 0.25 + 0.03
	add_child(roof)


func _build_collider() -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = def.size
	shape.shape = box
	body.add_child(shape)
	body.add_to_group(Terrain.NAV_SOURCE_GROUP)
	add_child(body)
	body.position.y = def.size.y * 0.5
