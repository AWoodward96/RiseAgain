shader_type canvas_item;


uniform sampler2D palette;
uniform float palette_count = 1.0;
uniform float palette_index = 0.0;

uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);

uniform bool grey_scale = false;
uniform float grey_scale_offset = 0.5;
uniform bool use_color_override = false;
uniform vec4 color_override : source_color = vec4(1.0, 0.0, 0.0, 1.0);

const float STEP_UNIT = 0.00392;

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
