class_name BuildingDef
extends Resource
## Static definition of a building type. Pure data; see data/buildings/*.tres.

@export var id: StringName
@export var display_name: String
@export var faction: StringName
@export var max_health: int = 500
## The faction's main base: drop-off point and anchor for the planned zone.
@export var is_hq: bool = false
## Resource ids this building accepts deliveries of (empty = not a drop-off).
@export var drop_off_resources: Array[StringName] = []

@export_group("Construction")
## Resource id -> amount, paid when the building is placed.
@export var costs: Dictionary = {}
## Seconds of work by one worker (build speed 1.0) to finish it.
@export var build_time: float = 20.0
## If above 0, may only be placed within this distance of a finished friendly
## HQ (the Collectivist "planned zone"). 0 = build anywhere.
@export var max_distance_from_hq: float = 0.0

@export_group("Effects")
## Population cap added once finished (Manpower).
@export var pop_provided: int = 0
## Resource id -> amount per second produced once finished.
@export var income: Dictionary = {}

@export_group("Placeholder visuals")
@export var size: Vector3 = Vector3(6, 4, 6)
@export var color: Color = Color(0.5, 0.5, 0.52)
## Roof band in the faction colour so buildings read at a glance.
@export var accent_color: Color = Color.WHITE
