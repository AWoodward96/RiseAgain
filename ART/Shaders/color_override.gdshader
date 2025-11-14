shader_type canvas_item;


uniform bool use_color_override = false;
uniform vec4 color_override : source_color = vec4(1.0, 0.0, 0.0, 1.0);

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	if (use_color_override)
	{
		vec4 overridden_color = color_override;
		overridden_color.a = color.a * color_override.a;
		COLOR = overridden_color;
	}
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
