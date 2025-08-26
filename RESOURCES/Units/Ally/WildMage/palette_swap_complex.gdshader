shader_type canvas_item;


uniform sampler2D palette;
uniform float palette_count = 1.0;
uniform float palette_index = 0.0;

uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);

uniform bool grey_scale = false;
uniform float grey_scale_offset = -0.1f;

uniform float hue = 1;
uniform float saturation = 1;
uniform float value = 1;


uniform bool use_color_override = false;
uniform vec4 color_override : source_color = vec4(1.0, 0.0, 0.0, 1.0);

const float STEP_UNIT = 0.00392;

vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}


void fragment() {

	vec4 color = texture(TEXTURE, UV);
	if (!use_color_override)
	{
		float increment = 1.0 / palette_count;
		float y = increment * palette_index + increment * 0.5;
		vec4 new_color = texture(palette, vec2(color.r, y));

		new_color.a *= color.a;
		// I don't know why we'd use this step method, so I've commented it out, but the OG shader did use it over the above line
		//new_color.a *= step(STEP_UNIT, color.a);

		if (grey_scale)
		{
			new_color.rgb = mix(vec3(((COLOR.r + COLOR.g + COLOR.b) / 3.0) - grey_scale_offset),  vec3(0.299 * COLOR.r + 0.587 * COLOR.g + 0.114 * COLOR.b), float(false));
		} else
		{
			new_color.rgb = hsv2rgb(rgb2hsv(new_color.rgb) * vec3(hue, saturation, value));

		}

		COLOR = new_color * tint;

	}
	else
	{
		vec4 overridden_color = color_override;
		overridden_color.a = color.a * color_override.a;
		COLOR = overridden_color;
	}
}
