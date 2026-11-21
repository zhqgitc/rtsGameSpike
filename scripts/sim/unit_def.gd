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

@export_group("Harvesting")
## 0 = cannot harvest.
@export var carry_capacity: int = 0
## Resource units gathered per second while at a deposit.
@export var gather_rate: float = 5.0

@export_group("Placeholder visuals")
## Until real models are assigned.
@export var shape: Shape = Shape.BOX
@export var size: Vector3 = Vector3(1, 1, 1)
@export var color: Color = Color.WHITE


func can_attack() -> bool:
	return attack_damage > 0


func can_harvest() -> bool:
	return carry_capacity > 0
