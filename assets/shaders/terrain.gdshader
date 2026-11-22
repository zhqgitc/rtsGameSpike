// Ground: scorched, dusty earth. Colour comes from large and small noise
// sampled in world space (so the same material continues seamlessly onto the
// skirt around the map), with a faint gameplay grid on top.
shader_type spatial;
render_mode diffuse_burley;

uniform sampler2D macro_noise : repeat_enable, filter_linear_mipmap;
uniform sampler2D detail_noise : repeat_enable, filter_linear_mipmap;
uniform sampler2D detail_normal : hint_normal, repeat_enable, filter_linear_mipmap;

uniform vec3 ash_color : source_color = vec3(0.15, 0.148, 0.14);
uniform vec3 dirt_color : source_color = vec3(0.25, 0.225, 0.19);
uniform vec3 dust_color : source_color = vec3(0.34, 0.32, 0.28);

uniform float macro_scale = 0.011;   // 1 / metres per macro tile
uniform float detail_scale = 0.32;   // 1 / metres per detail tile
uniform float grid_size = 4.0;       // metres per grid cell
uniform float grid_strength = 0.13;  // 0 = no grid

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = world_pos.xz;
	float macro = texture(macro_noise, uv * macro_scale).r;
	float macro_b = texture(macro_noise, uv * macro_scale * 2.7 + vec2(17.0, 31.0)).r;
	float detail = texture(detail_noise, uv * detail_scale).r;

	// Patches of ash, bare dirt and pale dust.
	vec3 base = mix(ash_color, dirt_color, smoothstep(0.25, 0.75, macro));
	base = mix(base, dust_color, smoothstep(0.55, 0.95, macro_b) * 0.45);
	// Fine grain so the ground never looks flat up close.
	base *= 0.64 + detail * 0.72;

	// Faint grid, anti-aliased by the screen-space derivative.
	vec2 cell = uv / grid_size;
	vec2 g = abs(fract(cell - 0.5) - 0.5) / max(fwidth(cell), vec2(0.0001));
	float line = 1.0 - clamp(min(g.x, g.y), 0.0, 1.0);
	base *= 1.0 - line * grid_strength;

	ALBEDO = base;
	ROUGHNESS = 0.96;
	SPECULAR = 0.18;
	NORMAL_MAP = texture(detail_normal, uv * detail_scale).rgb;
	NORMAL_MAP_DEPTH = 0.9;
}
