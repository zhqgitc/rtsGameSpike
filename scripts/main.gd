extends Node3D
## Spike entry point: spawns a few placeholder units for each faction.

const COLLECTIVIST_UNIT := preload("res://data/units/collectivist_conscript.tres")
const LIBERTARIAN_UNIT := preload("res://data/units/libertarian_freeholder.tres")

@onready var _units: Node3D = $Units


func _ready() -> void:
	# Collectivists: dense formation. Libertarians: loose, spread out.
	for row in 3:
		for col in 6:
			_spawn(COLLECTIVIST_UNIT, Vector3(-30.0 + col * 1.6, 0.0, -6.0 + row * 1.6))
	for i in 5:
		_spawn(LIBERTARIAN_UNIT, Vector3(24.0 + (i % 3) * 4.2, 0.0, -5.0 + i * 3.3))


func _spawn(def: UnitDef, pos: Vector3) -> void:
	var unit := Unit.new()
	_units.add_child(unit)
	unit.setup(def)
	unit.position = pos
	var bar := HealthBar.new()
	unit.add_child(bar)
	bar.attach(unit)
