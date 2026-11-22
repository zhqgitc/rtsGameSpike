// Handmade surfaces for the Libertarian buildings: timber planks, brick,
// rusty corrugated metal and striped canvas. Procedural, laid out in the
// mesh's own coordinates.
shader_type spatial;
render_mode diffuse_burley;

uniform int kind = 0; // 0 planks, 1 brick, 2 corrugated metal, 3 canvas stripes
uniform vec3 color_a : source_color = vec3(0.40, 0.31, 0.21);
uniform vec3 color_b : source_color = vec3(0.30, 0.23, 0.16);
uniform float scale = 1.0;

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
	vec2 uv = wall ? vec2(abs(n.x) > abs(n.z) ? local.z : local.x, local.y) : local.xz;

	vec3 col = color_a;
	float rough = 0.9;
	float metal = 0.0;

	if (kind == 0) {
		float width = 0.26 * scale;
		float board = floor(uv.x / width);
		float within = fract(uv.x / width);
		col = mix(color_a, color_b, hash(vec2(board, 1.0)));
		col *= 0.82 + 0.34 * vnoise(vec2(uv.x * 9.0 / scale, uv.y * 1.6 / scale));
		col *= 1.0 - smoothstep(0.07, 0.0, within) * 0.5;
	} else if (kind == 1) {
		float row = floor(uv.y / (0.2 * scale));
		float shift = mod(row, 2.0) * 0.5;
		float bx = uv.x / (0.5 * scale) + shift;
		vec2 b = vec2(fract(bx), fract(uv.y / (0.2 * scale)));
		float mortar = clamp(step(b.x, 0.06) + step(b.y, 0.1), 0.0, 1.0);
		col = mix(mix(color_a, color_b, hash(vec2(floor(bx), row))), vec3(0.28, 0.27, 0.26), mortar);
		col *= 0.85 + 0.25 * vnoise(uv * 8.0 / scale);
	} else if (kind == 2) {
		float ridge = sin(uv.x * 15.0 / scale) * 0.5 + 0.5;
		col = mix(color_a, color_b, vnoise(uv * 2.5 / scale));
		col *= 0.7 + ridge * 0.4;
		col = mix(col, color_b * 0.6, smoothstep(0.55, 0.9, vnoise(uv * 5.0 / scale + 9.0)) * 0.6); // rust patches
		rough = 0.6;
		metal = 0.35;
	} else {
		float stripe = step(0.5, fract(uv.x / (0.5 * scale)));
		col = mix(color_a, color_b, stripe) * (0.85 + 0.2 * vnoise(uv * 12.0));
		rough = 0.95;
	}

	ALBEDO = col;
	ROUGHNESS = rough;
	METALLIC = metal;
}
