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
## Placeholder visuals until real models are assigned.
@export var shape: Shape = Shape.BOX
@export var size: Vector3 = Vector3(1, 1, 1)
@export var color: Color = Color.WHITE
