class_name Atmosphere
extends Node
## The mood of the world: overcast sky, haze that swallows the distance, a low
## weak sun, desaturated grading, ambient occlusion and a soft vignette.
## Each game gets its own kind of day (a WeatherPreset from data/weather/):
## overcast, dark, foggy or sunny, all muted by the setting.

signal weather_changed(preset: WeatherPreset)

const PRESET_IDS: Array[StringName] = [&"overcast", &"dark", &"foggy", &"sunny"]

## Which day to use: one of PRESET_IDS, or &"random" for a different day each game.
@export var day: StringName = &"random"

var current: WeatherPreset

var _environment: Environment
var _sky_material: ProceduralSkyMaterial
var _sun: DirectionalLight3D
var _vignette_material: ShaderMaterial


func _ready() -> void:
	_sun = get_node("../Sun") as DirectionalLight3D
	_build_environment()
	_add_vignette()
	(get_node("../WorldEnvironment") as WorldEnvironment).environment = _environment
	apply(_load_preset(_pick_day()))


## Switch to a kind of day immediately.
func apply(preset: WeatherPreset) -> void:
	current = preset
	_sky_material.sky_top_color = preset.sky_top
	_sky_material.sky_horizon_color = preset.sky_horizon
	_sky_material.ground_horizon_color = preset.sky_horizon
	_sky_material.ground_bottom_color = preset.ground_bottom
	_environment.fog_light_color = preset.fog_color
	_environment.fog_density = preset.fog_density
	_environment.ambient_light_energy = preset.ambient_energy
	_environment.adjustment_saturation = preset.saturation
	_environment.adjustment_contrast = preset.contrast
	_sun.rotation_degrees = preset.sun_rotation
	_sun.light_color = preset.sun_color
	_sun.light_energy = preset.sun_energy
	_sun.shadow_blur = preset.shadow_blur
	_vignette_material.set_shader_parameter("strength", preset.vignette)
	weather_changed.emit(preset)


func apply_by_id(preset_id: StringName) -> void:
	apply(_load_preset(preset_id))


func _pick_day() -> StringName:
	if day != &"random":
		return day
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return PRESET_IDS[rng.randi() % PRESET_IDS.size()]


func _load_preset(preset_id: StringName) -> WeatherPreset:
	return load("res://data/weather/%s.tres" % preset_id) as WeatherPreset


func _build_environment() -> void:
	_sky_material = ProceduralSkyMaterial.new()
	_sky_material.sky_curve = 0.18
	_sky_material.ground_curve = 0.1
	_sky_material.sun_angle_max = 1.0
	_sky_material.use_debanding = true
	var sky := Sky.new()
	sky.sky_material = _sky_material

	_environment = Environment.new()
	_environment.background_mode = Environment.BG_SKY
	_environment.sky = sky
	_environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	_environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_environment.adjustment_enabled = true
	_environment.ssao_enabled = true
	_environment.ssao_radius = 1.6
	_environment.ssao_intensity = 2.2
	_environment.fog_enabled = true
	_environment.fog_sky_affect = 0.6
	_sun.shadow_enabled = true
	_sun.directional_shadow_max_distance = 160.0


## A dark rim around the screen. Sits below the HUD and ignores the mouse.
func _add_vignette() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 0
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform float strength = 0.5;
void fragment() {
	vec2 p = UV - vec2(0.5);
	float d = dot(p, p) * 2.2;
	COLOR = vec4(0.0, 0.0, 0.0, clamp(d * d, 0.0, 1.0) * strength);
}
"""
	_vignette_material = ShaderMaterial.new()
	_vignette_material.shader = shader
	var rect := ColorRect.new()
	rect.material = _vignette_material
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(rect)
	add_child(layer)
