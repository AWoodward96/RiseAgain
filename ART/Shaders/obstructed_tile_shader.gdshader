shader_type canvas_item;


uniform bool obscure = true;
uniform sampler2D alpha_texture : source_color ,repeat_enable;
uniform float y_cutoff;
uniform float blend_strength = 1;


const vec2 local_uv[] = {vec2(0,0),vec2(0,1),vec2(1,1),vec2(1,0)};
varying vec2 LOCAL_UV;

void vertex() {
	LOCAL_UV = local_uv[VERTEX_ID];
}
 
void fragment() {
	if(obscure){
		if(LOCAL_UV.y < y_cutoff){
			vec4 c = texture(TEXTURE, UV);
			vec4 lookup = texture(alpha_texture, LOCAL_UV);
			c.a = mix(c.a, c.a * lookup.a, blend_strength);
			//if(lookup.a < 1.0)
			//{
				//c.a = c.a * (lookup.a * (1.0 - blend_strength));
			//}
			COLOR = c;
		}
	}
	
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
