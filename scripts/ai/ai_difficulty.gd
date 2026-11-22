class_name AIDifficulty
extends Resource
## How hard the computer opponent plays. Pure data; see data/ai/difficulty_*.tres.
## Easy and Normal play fair. Hard cheats lightly: more income, nothing else.

@export var id: StringName
@export var display_name: String
## Multiplies the plan's time before the first attack wave (smaller = sooner).
@export var first_wave_factor: float = 1.0
## Multiplies the plan's wave size (bigger = stronger waves).
@export var wave_size_factor: float = 1.0
## Multiplies the plan's time between waves (smaller = more often).
@export var interval_factor: float = 1.0
## Multiplies everything the AI gathers and earns.
@export var income_factor: float = 1.0
