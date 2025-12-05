shader_type spatial;
stencil_mode write, compare_always, 1;

uniform sampler2D main_texture:source_color;

void fragment() {
	vec4 sample = texture(main_texture, UV);
	ALBEDO.rgb = sample.rgb;
}
