class_name WeatherPreset
extends Resource
## One kind of day: sky, haze, sun and grading. Pure data; see data/weather/*.tres.
## Even the brightest day is muted: the darkness comes from the setting.

@export var id: StringName
@export var display_name: String

@export_group("Sky and haze")
@export var sky_top: Color = Color(0.24, 0.26, 0.29)
@export var sky_horizon: Color = Color(0.50, 0.47, 0.43)
@export var ground_bottom: Color = Color(0.24, 0.22, 0.20)
## Matches the horizon so the far edge of the world dissolves.
@export var fog_color: Color = Color(0.47, 0.44, 0.40)
@export var fog_density: float = 0.0042

@export_group("Sun")
@export var sun_color: Color = Color(1.0, 0.88, 0.74)
@export var sun_energy: float = 1.25
## Pitch, yaw in degrees (negative pitch points the sun down at the ground).
@export var sun_rotation: Vector3 = Vector3(-36.0, -32.0, 0.0)
## Larger = softer shadows (heavy cloud or fog).
@export var shadow_blur: float = 1.4
@export var ambient_energy: float = 0.7

@export_group("Grading")
@export var saturation: float = 0.68
@export var contrast: float = 1.1
@export var vignette: float = 0.5
