shader_type canvas_item;

uniform bool do_pixelization = true;
uniform float pixelization_amount = 8.0;
uniform vec2 world_texture_size = vec2(64.0, 64.0);

uniform int OCTAVE = 6;
uniform float mulscale = 5.0;
uniform float height = 0.6;
uniform float tide = 0.1;
uniform float foamthickness = 0.1;
uniform float timescale = 1.0;
uniform float waterdeep = 0.3;
uniform vec4 color_1 : source_color;
uniform vec4 color_2 : source_color;
uniform vec4 foam_color : source_color;

varying vec2 WorldSpace;

void vertex() {
	WorldSpace = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

float rand(vec2 input){
	return fract(sin(dot(input,vec2(23.53,44.0)))*42350.45);
}

float perlin(vec2 input){
	vec2 i = floor(input);
	vec2 j = fract(input);
	vec2 coord = smoothstep(0.,1.,j);

	float a = rand(i);
	float b = rand(i+vec2(1.0,0.0));
	float c = rand(i+vec2(0.0,1.0));
	float d = rand(i+vec2(1.0,1.0));

	return mix(mix(a,b,coord.x),mix(c,d,coord.x),coord.y);
}

float fbm(vec2 input){
	float value = 0.0;
	float scale = 0.5;

	for(int i = 0; i < OCTAVE; i++){
		value += perlin(input)*scale;
		input*=2.0;
		scale*=0.5;
	}
	return value;
}

void fragment(){
	vec2 current_uv = SCREEN_UV;
	if (do_pixelization) {
        current_uv = round(current_uv * float(pixelization_amount)) / float(pixelization_amount);
    }

	float newtime = TIME*timescale;
	float fbmval = fbm(vec2(current_uv.x*mulscale+0.2*sin(0.3*newtime)+0.15*newtime,-0.05*newtime+current_uv.y*mulscale+0.1*cos(0.68*newtime)));
	float fbmvalshadow = fbm(vec2(current_uv.x*mulscale+0.2*sin(-0.6*newtime + 25.0 * current_uv.y)+0.15*newtime+3.0,-0.05*newtime+current_uv.y*mulscale+0.13*cos(-0.68*newtime))-7.0+0.1*sin(0.43*newtime));
	float myheight = height+tide*sin(newtime+5.0*current_uv.x-8.0*current_uv.y);
	float shadowheight = height+tide*1.3*cos(newtime+2.0*current_uv.x-2.0*current_uv.y);
	float withinFoam = step(myheight, fbmval)*step(fbmval, myheight + foamthickness);
	float shadow = (1.0-withinFoam)*step(shadowheight, fbmvalshadow)*step(fbmvalshadow, shadowheight + foamthickness * 0.7);
	COLOR = withinFoam*foam_color + shadow*color_2 + ((1.0-withinFoam)*(1.0-shadow))*color_1;
	//COLOR = vec4(1.0,1.0,1.0,fbmval);
}