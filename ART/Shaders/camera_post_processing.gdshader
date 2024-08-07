shader_type canvas_item;

uniform vec4 effectColor : source_color;
uniform sampler2D screen_texture :hint_screen_texture, repeat_disable,filter_nearest;

vec4 multiply(vec4 base, vec4 blend){
	return base * blend;
}

vec4 screen(vec4 base, vec4 blend){
	return 1.0 - (1.0 - base) * (1.0 - blend);
}

void fragment(){
	vec4 screenColor = texture(screen_texture, SCREEN_UV);

	COLOR.rgb = multiply(screenColor, effectColor).rgb;
}

