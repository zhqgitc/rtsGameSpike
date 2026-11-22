class_name Terrain
extends NavigationRegion3D
## Placeholder map: gridded ground plane, a few obstacles, and the navigation
## mesh baked from them at startup.

## Static bodies in this group (anywhere in the tree) are baked into the navmesh.
const NAV_SOURCE_GROUP := &"nav_source"
const GROUP := &"terrain"

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

## The visible block for each entry of `obstacles` (same order), so the fog of
## war can hide walls the player has not explored yet.
var obstacle_meshes: Array[MeshInstance3D] = []

var _rebake_pending: bool = false


func _ready() -> void:
	add_to_group(GROUP)
	var plane := PlaneMesh.new()
	plane.size = map_size
	var ground := MeshInstance3D.new()
	ground.mesh = plane
	ground.material_override = TerrainMaterial.create(tile_size)
	add_child(ground)

	var concrete := BuildingArt.ruin_material(obstacle_height)
	for rect in obstacles:
		var box := BoxMesh.new()
		box.size = Vector3(rect.size.x, obstacle_height, rect.size.y)
		var block := MeshInstance3D.new()
		block.mesh = box
		block.material_override = concrete
		block.position = Vector3(rect.position.x + rect.size.x * 0.5, obstacle_height * 0.5, rect.position.y + rect.size.y * 0.5)
		add_child(block)
		obstacle_meshes.append(block)
		var block_body := StaticBody3D.new()
		var block_shape := CollisionShape3D.new()
		var block_box := BoxShape3D.new()
		block_box.size = box.size
		block_shape.shape = block_box
		block_body.add_child(block_shape)
		block_body.add_to_group(NAV_SOURCE_GROUP)
		block_body.position = block.position
		add_child(block_body)

	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var floor_box := BoxShape3D.new()
	floor_box.size = Vector3(map_size.x, 1.0, map_size.y)
	shape.shape = floor_box
	shape.position.y = -0.5
	body.add_child(shape)
	body.add_to_group(NAV_SOURCE_GROUP)
	add_child(body)

	_setup_navigation()
	bake_finished.connect(_on_bake_finished)
	bake_navigation_mesh(false)


## Re-bake after obstacles were added or removed (buildings, depleted deposits).
## Runs on a thread; a request during a running bake is queued.
func rebake() -> void:
	if is_baking():
		_rebake_pending = true
		return
	bake_navigation_mesh(true)


func _on_bake_finished() -> void:
	if _rebake_pending:
		_rebake_pending = false
		bake_navigation_mesh(true)


func _setup_navigation() -> void:
	var nav := NavigationMesh.new()
	# Bake from collision shapes: parsing visual meshes at runtime stalls the GPU.
	nav.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nav.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	nav.geometry_source_group_name = NAV_SOURCE_GROUP
	nav.agent_radius = 0.5
	navigation_mesh = nav

