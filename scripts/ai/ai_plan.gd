class_name AIPlan
extends Resource
## How a computer-controlled faction builds up. Pure data; see data/ai/*.tres.
## The controller (AIController) plays the plan using the same rules as the
## player: it pays costs, trains units, builds with workers.

@export var faction: StringName
## The worker unit trained at the HQ, and how many the AI keeps.
@export var worker: UnitDef
@export var target_workers: int = 6
## Buildings to construct, in order. Listing a type twice means two of them.
@export var build_order: Array[BuildingDef] = []
## If set, another one is built whenever free Manpower runs low (Collectivists).
@export var housing: BuildingDef
## Free Manpower below which more housing is built.
@export var housing_margin: int = 5
## Combat units to train, best first; each production building trains the
## first one it can afford and is allowed to make.
@export var army: Array[UnitDef] = []
## Prefer Plan batches (where the building offers them) over single units.
@export var use_plan_batches: bool = false
## Units waiting in one building's queue before the AI stops adding more.
@export var max_queued_per_building: int = 2

@export_group("Attacks")
## Seconds into the game before the first attack wave (before difficulty scaling).
@export var first_wave_time: float = 200.0
## Minimum seconds between waves.
@export var wave_interval: float = 100.0
## Combat units needed to launch a wave (before difficulty scaling).
@export var wave_size: int = 20
## True: a wave takes every available unit (the Collectivist mass). False: a
## wave is exactly wave_size units and the rest wait for the next one (raids).
@export var send_all: bool = true
## Combat units that stay at home and are never sent out.
@export var home_guard: int = 0
## What a wave goes for: &"hq" (the player's headquarters) or &"workers" (raid
## the player's workers and economy).
@export var raid_target: StringName = &"hq"
## A wave with fewer than this share of its units left is recalled. 0 = never
## (the Collectivists fight to the last man).
@export_range(0.0, 1.0) var recall_below: float = 0.0
