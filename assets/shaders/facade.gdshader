// Brutalist concrete wall: grainy, weathered, with a regular grid of dark
// window slits (a few lit), floor seams and rain stains under the windows.
// Patterns are laid out in the mesh's own coordinates so each tier of a
// building is symmetric about its centre.
shader_type spatial;
render_mode diffuse_burley;

uniform vec3 concrete_color : source_color = vec3(0.45, 0.44, 0.42);
uniform vec3 window_color : source_color = vec3(0.04, 0.05, 0.06);
uniform vec3 lit_color : source_color = vec3(1.0, 0.72, 0.35);
uniform float floor_height = 1.6;
uniform float column_spacing = 1.2;
uniform vec2 window_size = vec2(0.3, 0.55); // fraction of one grid cell
uniform float bottom = 0.0;                 // distance from the mesh centre down to its base
uniform float lit_chance = 0.08;
uniform float windows_on = 1.0;
uniform float stain_strength = 0.4;

varying vec3 world_pos;
varying vec3 world_normal;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 n = normalize(world_normal);
	vec3 local = world_pos - NODE_POSITION_WORLD;
	bool wall = abs(n.y) < 0.5;
	vec2 uv = wall ? vec2(abs(n.x) > abs(n.z) ? local.z : local.x, local.y + bottom) : local.xz;

	float grain = vnoise(uv * 6.0) * 0.5 + vnoise(uv * 21.0) * 0.5;
	vec3 base = concrete_color * (0.78 + grain * 0.44);
	vec3 emission = vec3(0.0);
	float rough = 0.95;
	float spec = 0.15;

	if (wall && windows_on > 0.5) {
		vec2 cell = vec2(uv.x / column_spacing, uv.y / floor_height);
		vec2 f = fract(cell);
		vec2 id = floor(cell);
		vec2 margin = (vec2(1.0) - window_size) * 0.5;
		float x_in = step(margin.x, f.x) * step(f.x, 1.0 - margin.x);
		float y_in = step(0.2, f.y) * step(f.y, 0.2 + window_size.y);
		float in_window = x_in * y_in;
		float lit = step(hash(id + vec2(3.0, 7.0)), lit_chance);
		vec3 glass = mix(window_color, lit_color * 0.55, lit);
		base = mix(base, glass, in_window);
		emission = lit_color * lit * in_window * 0.9;
		rough = mix(rough, 0.25, in_window);
		spec = mix(spec, 0.7, in_window);
		// Rain stains running down from the window sills.
		float below = smoothstep(0.2, 0.0, f.y) * x_in;
		base *= 1.0 - below * stain_strength * (0.4 + 0.6 * vnoise(vec2(uv.x * 11.0, id.y)));
		// Seam between floors.
		base *= 1.0 - smoothstep(0.03, 0.0, f.y) * 0.3;
	} else if (!wall) {
		base *= 0.85;
	}

	// Grime and soot collect toward the ground.
	base *= mix(0.45, 1.0, smoothstep(0.0, 2.2, world_pos.y));

	ALBEDO = base;
	EMISSION = emission;
	ROUGHNESS = rough;
	SPECULAR = spec;
}
