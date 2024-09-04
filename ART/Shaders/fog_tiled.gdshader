shader_type canvas_item;

uniform sampler2D world_texture : source_color, repeat_enable;
uniform vec2 world_texture_size = vec2(64.0, 64.0);

uniform bool do_pixelization = true;
uniform float pixelization_amount = 8.0;
uniform vec4 fog_color: source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 minimum_color: source_color = vec4(0.0, 0.0, 0.0, 0.0);

// Amount of detail.
uniform int octaves = 4;

// Opacity of the output fog.
uniform float starting_amplitude: hint_range(0.0, 0.5) = 0.5;

// Rate of pattern within the fog.
uniform float starting_frequency = 1.0;

// Shift towards transparency (clamped) for sparser fog.
uniform float shift: hint_range(-1.0, 0.0) = -0.2;

// Direction and speed of travel.
uniform vec2 velocity = vec2(1.0, 1.0);
varying vec2 WorldSpace;

void vertex() {
	WorldSpace = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

float rand(vec2 uv) {
	float amplitude = starting_amplitude;
	float frequency = starting_frequency;
	float output = 0.0;
	for (int i = 0; i < octaves; i++) {
		output += texture(world_texture, uv * frequency).x * amplitude;
		amplitude /= 2.0;
		frequency *= 2.0;
	}
	return clamp(output + shift, 0.0, 1.0);
}

void fragment() {
	 vec2 current_uv = WorldSpace / world_texture_size;
	if (do_pixelization) {
        current_uv = round(current_uv * float(pixelization_amount)) / float(pixelization_amount);
    }

	float mask = texture(TEXTURE, UV).a;
	vec4 color = texture(world_texture, current_uv);

	vec2 motion = vec2(rand(current_uv + TIME * starting_frequency * velocity));
	COLOR = mix(minimum_color, color * fog_color, rand(current_uv + motion) * mask);
	//COLOR.rgba = mix(vec4(0.0), color * fog_color, 0.5 * mask);
}