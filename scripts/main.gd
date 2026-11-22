extends Node3D
## Spike entry point: lays out both bases, deposits and starting units.

const COLLECTIVIST_UNIT := preload("res://data/units/collectivist_conscript.tres")
const LIBERTARIAN_UNIT := preload("res://data/units/libertarian_freeholder.tres")
const COLLECTIVIST_WORKER := preload("res://data/units/collectivist_laborer.tres")
const LIBERTARIAN_WORKER := preload("res://data/units/libertarian_prospector.tres")
const COLLECTIVIST_HQ := preload("res://data/buildings/collectivist_hq.tres")
const LIBERTARIAN_HQ := preload("res://data/buildings/libertarian_hq.tres")

const DEPOSIT_AMOUNT := 600
const STARTING_MATERIALS := 200
const LIBERTARIAN_STARTING_CAPITAL := 50

@onready var _terrain: Terrain = $Terrain
@onready var _units: Node3D = $Units
@onready var _buildings: Node3D = $Buildings
@onready var _deposits: Node3D = $Deposits


func _ready() -> void:
	var economy: Economy = $Economy
	economy.add(&"collectivists", &"materials", STARTING_MATERIALS)
	economy.add(&"libertarians", &"materials", STARTING_MATERIALS)
	economy.add(&"libertarians", &"capital", LIBERTARIAN_STARTING_CAPITAL)
	_buildings.child_entered_tree.connect(_on_building_added)
	($Session as Session).faction_chosen.connect(_on_faction_chosen)
	_setup_collectivists()
	_setup_libertarians()
	# Buildings and deposits are new obstacles: bake them into the navmesh.
	_terrain.rebake()


func _setup_collectivists() -> void:
	_spawn_building(COLLECTIVIST_HQ, Vector3(-42, 0, 0))
	_spawn_deposit(Vector3(-34, 0, -14))
	_spawn_deposit(Vector3(-34, 0, 14))
	for i in 3:
		_spawn_unit(COLLECTIVIST_WORKER, Vector3(-34.0, 0.0, -3.0 + i * 3.0))
	# Dense formation: the mass.
	for row in 3:
		for col in 6:
			_spawn_unit(COLLECTIVIST_UNIT, Vector3(-30.0 + col * 1.6, 0.0, -6.0 + row * 1.6))


func _setup_libertarians() -> void:
	_spawn_building(LIBERTARIAN_HQ, Vector3(44, 0, 0))
	_spawn_deposit(Vector3(36, 0, -13))
	_spawn_deposit(Vector3(36, 0, 13))
	for i in 3:
		_spawn_unit(LIBERTARIAN_WORKER, Vector3(37.0, 0.0, -4.0 + i * 4.0))
	# Loose spread: the individuals.
	for i in 5:
		_spawn_unit(LIBERTARIAN_UNIT, Vector3(24.0 + (i % 3) * 4.2, 0.0, -5.0 + i * 3.3))


func _spawn_unit(def: UnitDef, pos: Vector3) -> void:
	var unit := Unit.new()
	_units.add_child(unit)
	unit.setup(def)
	unit.position = pos
	var bar := HealthBar.new()
	unit.add_child(bar)
	bar.attach(unit, unit.def.size.y + 0.6)
	($FogPresenter as FogPresenter).apply_to_unit(unit)


## Start the view on the chosen faction's HQ.
func _on_faction_chosen(faction: StringName) -> void:
	for node in _buildings.get_children():
		var building := node as Building
		if building != null and building.def.is_hq and building.def.faction == faction:
			($RTSCamera as RTSCamera).focus_on(building.global_position)
			return


func _on_building_added(node: Node) -> void:
	var building := node as Building
	if building == null:
		return
	building.unit_produced.connect(_spawn_unit)
	building.configured.connect(_attach_building_bar)
	building.died.connect(_on_building_died)


func _attach_building_bar(building: Building) -> void:
	var bar := HealthBar.new()
	building.add_child(bar)
	bar.attach(building, building.def.size.y + 1.0, maxf(building.def.size.x, 2.5))


func _on_building_died(target: Damageable) -> void:
	($MatchRules as MatchRules).building_destroyed(target as Building)
	# The wreck is freed at the end of the frame; bake once it is gone.
	await get_tree().process_frame
	_terrain.rebake()


func _spawn_building(def: BuildingDef, pos: Vector3) -> void:
	var building := Building.new()
	_buildings.add_child(building)
	building.setup(def)
	building.position = pos


func _spawn_deposit(pos: Vector3) -> void:
	var deposit := ResourceNode.new()
	deposit.amount = DEPOSIT_AMOUNT
	_deposits.add_child(deposit)
	deposit.position = pos
	deposit.depleted.connect(_on_deposit_depleted)


func _on_deposit_depleted() -> void:
	# The deposit is freed at the end of the frame; bake once it is gone.
	await get_tree().process_frame
	_terrain.rebake()
