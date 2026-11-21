class_name BuildingDef
extends Resource
## Static definition of a building type. Pure data; see data/buildings/*.tres.

@export var id: StringName
@export var display_name: String
@export var faction: StringName
@export var max_health: int = 500
## Resource ids this building accepts deliveries of (empty = not a drop-off).
@export var drop_off_resources: Array[StringName] = []

@export_group("Placeholder visuals")
@export var size: Vector3 = Vector3(6, 4, 6)
@export var color: Color = Color(0.5, 0.5, 0.52)
## Roof band in the faction colour so buildings read at a glance.
@export var accent_color: Color = Color.WHITE
