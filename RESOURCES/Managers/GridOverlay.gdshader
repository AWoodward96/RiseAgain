shader_type canvas_item;

uniform int grid_cell_size = 64;
uniform int thickness = 1;
uniform vec4 grid_color : source_color = vec4(0.2, 0.3, 0.5, 1.0);
varying vec2 global_position;


void vertex(){
	global_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec4 currentColor = COLOR;
	if ((int(global_position.x) % grid_cell_size <= thickness) || (int(global_position.y) % grid_cell_size <= thickness))
		currentColor = grid_color;
	else
		currentColor.a = 0.0;
	COLOR = currentColor;
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
