class_name Atmosphere
extends Node
## The mood of the world: a low, weak sun, an overcast sky, haze that swallows
## the distance, desaturated grading, ambient occlusion and a soft vignette.
## All the numbers are constants at the top so the look is easy to tune.

# Sky and haze (the horizon colour and the fog colour match, so the far edge of
# the world dissolves instead of showing a seam).
const SKY_TOP := Color(0.24, 0.26, 0.29)
const SKY_HORIZON := Color(0.50, 0.47, 0.43)
const GROUND_HORIZON := Color(0.50, 0.47, 0.43)
const GROUND_BOTTOM := Color(0.24, 0.22, 0.20)
const FOG_COLOR := Color(0.47, 0.44, 0.40)
const FOG_DENSITY := 0.0042

# Light.
const SUN_COLOR := Color(1.0, 0.88, 0.74)
const SUN_ENERGY := 1.25
const SUN_ROTATION := Vector3(-36.0, -32.0, 0.0)
const AMBIENT_ENERGY := 0.7

# Grading.
const SATURATION := 0.68
const CONTRAST := 1.1
const VIGNETTE_STRENGTH := 0.5


func _ready() -> void:
	var world_environment := get_node("../WorldEnvironment") as WorldEnvironment
	world_environment.environment = _make_environment()
	_set_up_sun(get_node("../Sun") as DirectionalLight3D)
	_add_vignette()


func _make_environment() -> Environment:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = SKY_TOP
	sky_material.sky_horizon_color = SKY_HORIZON
	sky_material.sky_curve = 0.18
	sky_material.ground_horizon_color = GROUND_HORIZON
	sky_material.ground_bottom_color = GROUND_BOTTOM
	sky_material.ground_curve = 0.1
	sky_material.sun_angle_max = 1.0
	sky_material.use_debanding = true
	var sky := Sky.new()
	sky.sky_material = sky_material

	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = AMBIENT_ENERGY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.adjustment_enabled = true
	env.adjustment_saturation = SATURATION
	env.adjustment_contrast = CONTRAST
	env.ssao_enabled = true
	env.ssao_radius = 1.6
	env.ssao_intensity = 2.2
	env.fog_enabled = true
	env.fog_light_color = FOG_COLOR
	env.fog_density = FOG_DENSITY
	env.fog_sky_affect = 0.6
	return env


func _set_up_sun(sun: DirectionalLight3D) -> void:
	sun.rotation_degrees = SUN_ROTATION
	sun.light_color = SUN_COLOR
	sun.light_energy = SUN_ENERGY
	sun.shadow_enabled = true
	sun.shadow_blur = 1.4
	sun.directional_shadow_max_distance = 160.0


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
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("strength", VIGNETTE_STRENGTH)
	var rect := ColorRect.new()
	rect.material = material
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(rect)
	add_child(layer)
