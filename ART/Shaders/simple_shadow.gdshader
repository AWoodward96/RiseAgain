shader_type canvas_item;

uniform bool use_screen_uv;
uniform vec2 shadow_offset = vec2(-10.0, -10.0);
uniform vec4 shadow_color : source_color;

varying vec2 global_position;


void fragment() {
	vec2 uv = UV;
	if (use_screen_uv)
	{
		uv = SCREEN_UV;
	}

	vec4 texture_copy = texture(TEXTURE, uv);
	texture_copy.a = (texture(TEXTURE, uv).a) * 1.0;

	vec4 shadow_texture = texture(TEXTURE, uv + shadow_offset * SCREEN_PIXEL_SIZE);
	vec4 shadow = vec4(shadow_color.rgb, shadow_texture.a - (1.0 - shadow_color.a));

	vec4 result = mix(shadow, texture_copy, texture_copy.a);
	COLOR = result;

}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
