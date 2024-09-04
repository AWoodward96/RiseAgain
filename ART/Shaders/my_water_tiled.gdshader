shader_type canvas_item;

uniform bool do_pixelization = true;
uniform float pixelization_amount = 8.0;
uniform vec2 world_texture_size = vec2(64.0, 64.0);

uniform vec2 velocity = vec2(1.0, 0);
uniform sampler2D alpha_noise_multiplier : repeat_enable;

uniform vec4 base_color: source_color = vec4(0.0, 1.0, 1.0, 1.0);
uniform vec4 voronoi_highlights_color : source_color = vec4(0.75, 1.0, 1.0, 1.0);

uniform bool apply_red_mask = false;
uniform bool limit_pallete = false;
uniform int num_colors = 41;
uniform sampler2D palette;

uniform vec2 rows_and_columns = vec2(3.0, 5.0);
uniform float voronoi_warp_speed = 1;
varying vec2 WorldSpace;

void vertex() {
	WorldSpace = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

vec2 random(vec2 uv) {
	return vec2(fract(sin(dot(uv.xy,
		vec2(12.9898,78.233))) * 43758.5453123));
}

vec4 lighten(vec4 base, vec4 blend){
	return max(base, blend);
}

vec4 overlay(vec4 base, vec4 blend){
	vec4 limit = step(0.5, base);
	return mix(2.0 * base * blend, 1.0 - 2.0 * (1.0 - base) * (1.0 - blend), limit);
}

// random and worley methos from: https://godotshaders.com/snippet/voronoi/
float worley(vec2 uv, float columns, float rows, float time) {

	vec2 index_uv = floor(vec2(uv.x * columns, uv.y * rows));
	vec2 fract_uv = fract(vec2(uv.x * columns, uv.y * rows));

	float minimum_dist = 1.0;

	for (int y= -1; y <= 1; y++) {
		for (int x= -1; x <= 1; x++) {
			vec2 neighbor = vec2(float(x),float(y));
			vec2 point = random(index_uv + neighbor);

			// warps the voronoi texture over time
			point = vec2( cos(time * point.x * voronoi_warp_speed), sin(time * point.y * voronoi_warp_speed) ) * 0.5 + 0.5;

			vec2 diff = neighbor + point - fract_uv;
			float dist = length(diff);
			minimum_dist = min(minimum_dist, dist);
		}
	}

	return minimum_dist;
}

// FROM: https://godotshaders.com/shader/palette-limiter-shader/
vec3 palette_limiter (in vec3 albedo){
	float estimation_cutoff = 0.001;
	vec3 closest_color;
	float min_dist = 2.0;
	float n = float(num_colors);

	for (int i=0; i<num_colors; i++ ){
		float index = 1.000/(2.000*n)+float(i)/n;
		vec3 index_color = texture(palette, vec2(index,0.5)).rgb;
		float dist = length(index_color - albedo);
		if (dist < min_dist) {
			min_dist = dist;
			closest_color = index_color;
			if (min_dist < estimation_cutoff){
				return closest_color;
			}
		}
	}
	return closest_color;
}

void fragment() {
	vec2 current_uv = WorldSpace / world_texture_size;
	if (do_pixelization) {
        current_uv = round(current_uv * float(pixelization_amount)) / float(pixelization_amount);
    }

	float alpha_mask = texture(TEXTURE, UV).a;
	float red_mask = texture(TEXTURE, UV).r;

	float worley = worley(current_uv + TIME * velocity, rows_and_columns.x, rows_and_columns.y, TIME);
	if (apply_red_mask)
		worley = clamp(worley - red_mask, 0.0, 1.0);
	vec4 voronoi_color = vec4(vec3(worley), 1.0);


	vec2 motion = vec2(current_uv + TIME * velocity * 2.0);
	vec4 noise_alpha_multiplier = texture(alpha_noise_multiplier, motion);

	if (apply_red_mask)
	{
		voronoi_color = mix(voronoi_color, noise_alpha_multiplier, red_mask);
	}

	if (limit_pallete)
		voronoi_color = vec4(palette_limiter(vec3(voronoi_color.r, voronoi_color.g, voronoi_color.b)), voronoi_color.a);

	COLOR = mix(base_color, voronoi_color, alpha_mask);
}


