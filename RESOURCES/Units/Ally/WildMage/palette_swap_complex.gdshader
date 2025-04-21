shader_type canvas_item;

uniform sampler2D palette;
uniform float palette_count = 1.0;
uniform float palette_index = 0.0;
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
		//new_color.a *= step(STEP_UNIT, color.a);
		COLOR = new_color;
	}
	else
	{
		vec4 overridden_color = color_override;
		overridden_color.a = color.a * color_override.a;
		COLOR = overridden_color;
	}
}