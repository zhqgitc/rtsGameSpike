class_name TerrainMaterial
extends RefCounted
## Builds the ground material: the terrain shader plus its generated noise
## textures. Everything is procedural, so there are no image assets to license.

const SHADER := preload("res://assets/shaders/terrain.gdshader")
const TEXTURE_SIZE := 512


static func create(grid_size: float) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter("macro_noise", _noise(0.006, 4, 11, false))
	material.set_shader_parameter("detail_noise", _noise(0.05, 3, 23, false))
	material.set_shader_parameter("detail_normal", _noise(0.08, 3, 37, true))
	material.set_shader_parameter("grid_size", grid_size)
	return material


static func _noise(frequency: float, octaves: int, noise_seed: int, as_normal_map: bool) -> NoiseTexture2D:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = frequency
	noise.fractal_octaves = octaves
	noise.seed = noise_seed
	var texture := NoiseTexture2D.new()
	texture.noise = noise
	texture.width = TEXTURE_SIZE
	texture.height = TEXTURE_SIZE
	texture.seamless = true
	texture.normalize = true
	if as_normal_map:
		texture.as_normal_map = true
		texture.bump_strength = 5.0
	return texture
