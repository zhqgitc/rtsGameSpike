class_name FogOfWar
extends Node
## What the player can see. The map is split into square cells, each either
## unexplored, explored (seen before, not in sight now) or visible (inside the
## sight range of one of the player's units or buildings). Recomputed ten times
## a second from the player's units and buildings. Pure data: the look of the
## fog lives in FogPresenter and the minimap, which read this.

signal updated

enum State { UNEXPLORED, EXPLORED, VISIBLE }

const GROUP := &"fog"
const CELL_SIZE := 2.0
## Simulation ticks between recomputations (60 ticks per second).
const UPDATE_EVERY_TICKS := 6
## Sight of a building that is still a construction site.
const SITE_SIGHT := 6.0
const ALPHA_UNEXPLORED := 255
const ALPHA_EXPLORED := 140
const ALPHA_VISIBLE := 0

## Black overlay whose alpha encodes the fog (one pixel per cell). Used for the
## terrain overlay and the minimap.
var overlay_texture: ImageTexture
var cols: int = 0
var rows: int = 0

var _map_size: Vector2 = Vector2(128, 128)
var _faction: StringName = &""
var _states: PackedByteArray = PackedByteArray()
var _ticks: int = 0


func _ready() -> void:
	add_to_group(GROUP)
	var terrain := get_node("../Terrain") as Terrain
	_map_size = terrain.map_size
	cols = ceili(_map_size.x / CELL_SIZE)
	rows = ceili(_map_size.y / CELL_SIZE)
	_states.resize(cols * rows)
	_states.fill(State.UNEXPLORED)
	var image := Image.create(cols, rows, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 1))
	overlay_texture = ImageTexture.create_from_image(image)
	(get_node("../Session") as Session).faction_chosen.connect(_on_faction_chosen)


func _physics_process(_delta: float) -> void:
	if _faction == &"":
		return
	_ticks += 1
	if _ticks >= UPDATE_EVERY_TICKS:
		_ticks = 0
		recompute()


func state_at(world: Vector3) -> int:
	return _states[_index_of(world)]


func is_visible_at(world: Vector3) -> bool:
	return state_at(world) == State.VISIBLE


func is_explored_at(world: Vector3) -> bool:
	return state_at(world) != State.UNEXPLORED


## The best state among the cells a ground rectangle (x, z) touches.
func best_state_in(rect: Rect2) -> int:
	var best: int = State.UNEXPLORED
	var first := _cell_of(rect.position)
	var last := _cell_of(rect.end)
	for row in range(first.y, last.y + 1):
		for col in range(first.x, last.x + 1):
			best = maxi(best, _states[row * cols + col])
	return best


## Recompute the visible area from the player's units and buildings.
func recompute() -> void:
	for i in _states.size():
		if _states[i] == State.VISIBLE:
			_states[i] = State.EXPLORED
	for node in get_tree().get_nodes_in_group(Unit.GROUP):
		var unit := node as Unit
		if unit != null and unit.def.faction == _faction:
			_reveal(unit.global_position, unit.def.sight_range)
	for node in get_tree().get_nodes_in_group(Building.GROUP):
		var building := node as Building
		if building != null and building.def.faction == _faction:
			_reveal(building.global_position, building.def.sight_range if building.complete else SITE_SIGHT)
	_refresh_texture()
	updated.emit()


func _on_faction_chosen(faction: StringName) -> void:
	_faction = faction
	recompute()


func _reveal(center: Vector3, sight: float) -> void:
	var middle := _cell_of(Vector2(center.x, center.z))
	var reach := ceili(sight / CELL_SIZE)
	var limit := sight * sight
	for dz in range(-reach, reach + 1):
		var row := middle.y + dz
		if row < 0 or row >= rows:
			continue
		for dx in range(-reach, reach + 1):
			var col := middle.x + dx
			if col < 0 or col >= cols:
				continue
			if float(dx * dx + dz * dz) * CELL_SIZE * CELL_SIZE <= limit:
				_states[row * cols + col] = State.VISIBLE


func _refresh_texture() -> void:
	var bytes := PackedByteArray()
	bytes.resize(cols * rows * 4)
	for i in _states.size():
		var alpha := ALPHA_UNEXPLORED
		if _states[i] == State.VISIBLE:
			alpha = ALPHA_VISIBLE
		elif _states[i] == State.EXPLORED:
			alpha = ALPHA_EXPLORED
		bytes[i * 4 + 3] = alpha
	overlay_texture.update(Image.create_from_data(cols, rows, false, Image.FORMAT_RGBA8, bytes))


func _cell_of(ground: Vector2) -> Vector2i:
	var col := clampi(floori((ground.x + _map_size.x * 0.5) / CELL_SIZE), 0, cols - 1)
	var row := clampi(floori((ground.y + _map_size.y * 0.5) / CELL_SIZE), 0, rows - 1)
	return Vector2i(col, row)


func _index_of(world: Vector3) -> int:
	var cell := _cell_of(Vector2(world.x, world.z))
	return cell.y * cols + cell.x
