class_name UnitDef
extends Resource
## Static definition of a unit type. Pure data; see data/units/*.tres.

enum Shape { BOX, CAPSULE }

@export var id: StringName
@export var display_name: String
@export var faction: StringName
@export var max_health: int = 100
@export var move_speed: float = 4.0
## Distance between units when this unit type is ordered to move as a group.
## Collectivists pack tightly, Libertarians spread out.
@export var formation_spacing: float = 2.0

@export_group("Combat")
## Centre-to-centre distance at which the unit can hit its target.
@export var attack_range: float = 2.0
@export var attack_damage: int = 5
@export var attack_cooldown: float = 1.0
## 0 = instant (melee-ish) hit. Above 0 = visible projectile with this speed.
@export var projectile_speed: float = 0.0
## Idle units attack enemies that come within this distance.
@export var acquire_range: float = 10.0
## Below this share of max health the unit stops fighting and flees.
## 0 = never retreats (Collectivist obedience).
@export_range(0.0, 1.0) var retreat_health_fraction: float = 0.0

@export_group("Senses")
## How far this unit sees (reveals fog of war). Combat units should see at
## least as far as they acquire targets.
@export var sight_range: float = 14.0

@export_group("Harvesting")
## 0 = cannot harvest.
@export var carry_capacity: int = 0
## Resource units gathered per second while at a deposit.
@export var gather_rate: float = 5.0

@export_group("Building")
## Buildings this unit can construct, in hotkey order (1, 2, ...). Empty = cannot build.
@export var builds: Array[BuildingDef] = []
## Build-seconds of progress contributed per second.
@export var build_speed: float = 1.0

@export_group("Population")
## Manpower slots this unit occupies (Collectivists only; 0 = none).
@export var pop_cost: int = 0

@export_group("Training")
## Resource id -> amount, paid when queued at a production building.
@export var train_costs: Dictionary = {}
## Seconds to train one unit.
@export var train_time: float = 10.0
## A finished friendly building of this type is needed before training
## (Libertarian "education": the Apprentice Workshop). Null = none.
@export var requires: BuildingDef

@export_group("Placeholder visuals")
## Until real models are assigned.
@export var shape: Shape = Shape.BOX
@export var size: Vector3 = Vector3(1, 1, 1)
@export var color: Color = Color.WHITE


func can_attack() -> bool:
	return attack_damage > 0


func can_harvest() -> bool:
	return carry_capacity > 0


func can_build() -> bool:
	return not builds.is_empty()
