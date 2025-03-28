shader_type canvas_item;

// 0: default
// 1: allied
// 2: enemy
// 3: neutral
uniform int palette_choice;

/**
 * The [code]input_palette_texture[/code] property should store a texture with a color palette.
 * This palette should be organized as a grid of pixels (transparent colors count), each one storing a color.
 * If found in the original texture, the color of each pixel of this palette is replaced by the color of same position in the [code]output_palette_texture[/code].
 * If this palette texture is set, but the [code]output_palette_texture[/code] is not, the shader will try to replace the target colors with that empty texture, which should be avoided.
 * If you wish to let this property set to a palette without affecting the end result, just set the [code]output_palette_texture[/code] to the same palette.
 */
uniform sampler2D input_palette_texture: filter_nearest;

/**
 * The [code]output_palette_texture[/code] property should store a texture with a color palette.
 * This palette should be organized as a grid of pixels (transparent colors count), each one storing a color.
 * For proper functioning, this texture should have the same size as the [code]input_palette_texture[/code].
 * The color of each pixel of this palette is used to replace the color of same position in the [code]input_palette_texture[/code], if found in the original texture.
 */
uniform sampler2D allied_palette_texture: filter_nearest;
uniform sampler2D enemy_palette_texture: filter_nearest;
uniform sampler2D neutral_palette_texture: filter_nearest;

uniform float precision = 0.1;


/**
 * The [code]compare_floats[/code] function receives two [code]float[/code]
 * numbers [param a] and [param b] and returns an [code]int[/code] indicating
 * if those values are equal, less than or greater than one another.
 * If they are approximately equal, this function returns [code]0[/code],
 * if [param a] is greater than [param b], this function returns [code]1[/code],
 * and if [param a] is less than [param b], this function returns
 * [code]-1[/code].
 */
int compare_floats(float a, float b) {
	float difference = a - b;

	if(abs(difference) < 0.0001) {
		return 0;
	} else if(difference > 0.0) {
		return 1;
	} else {
		return -1;
	}
}

/**
 * The [code]color_is_transparent[/code] function is a utility function that
 * returns a [code]bool[/code] indicating if the received [param color] is
 * fully transparent.
 */
bool color_is_transparent(vec4 color) {
	return compare_floats(color.a, 0.0) == 0;
}

/**
 * The [code]find_color_in_palette_texture[/code] function tries to find a
 * [param color] in a [param palette] texture.
 * To do so, this function iterates over the palette trying to find a
 * color that matches the desired one (fully transparent colors are considered
 * equal, and when comparing other colors the opacity is taken into account).
 * If such color is not found, this function returns a [code]vec2(-1.0)[/code]
 * as its result. If the color is found, the coordinate of this color in the
 * texture (from [code]vec2(0.0)[/code] to [code]vec2(1.0)[/code]) is returned.
 */
vec2 find_color_in_palette_texture(vec4 color, sampler2D palette) {
	ivec2 palette_size = textureSize(palette, 0);

	for(uint y = uint(0); y < uint(palette_size.y); y++) {
		for(uint x = uint(0); x < uint(palette_size.x); x++) {
			vec2 palette_coord = vec2(
				float(x) / float(palette_size.x),
				float(y) / float(palette_size.y)
			);

			vec4 palette_color = texture(palette, palette_coord);

			if(distance(color, palette_color) <= precision) {
				return palette_coord;
			}
			if(
				color_is_transparent(color) &&
				color_is_transparent(palette_color)
			) {
				return palette_coord;
			}
		}
	}

	return vec2(-1.0);
}

/**
 * The [code]get_color_from_palette_texture[/code] function returns what color
 * is in the given [param coord] in the given [param palette].
 * The [param coord] should be between [code]vec2(0.0)[/code] to
 * [code]vec2(1.0)[/code] so that the [code]texture[/code]
 * function can be used with it as the coordinates to look for.
 */
vec4 get_color_from_palette_texture(vec2 coord, sampler2D palette) {
	return texture(palette, coord);
}

/**
 * The [code]swap_colors_from_palette_textures[/code] function takes a
 * [param input_color] and an [param output_color].
 * This function then modifies the [param output_color],
 * if the [param input_color] is mapped in the
 * [code]input_palette_texture[/code], so that it matches the corresponding
 * [code]output_palette_texture[/code] color.
 */
void swap_colors_from_palette_textures(
	vec4 input_color,
	inout vec4 output_color
) {
	vec2 palette_coord = find_color_in_palette_texture(
		input_color, input_palette_texture
	);

	if(palette_coord == vec2(-1.0)) {
		return;
	}

	// This ain fuckin pretty but I don't care. It's a pixel art game
	if(palette_choice == 0)
	{
		output_color = get_color_from_palette_texture(
			palette_coord,
			input_palette_texture
		);
	}else if(palette_choice == 1)
	{
		output_color = get_color_from_palette_texture(
			palette_coord,
			allied_palette_texture
		);
	}else if(palette_choice == 2)
	{
		output_color = get_color_from_palette_texture(
			palette_coord,
			enemy_palette_texture
		);
	}else if(palette_choice == 3)
	{
		output_color = get_color_from_palette_texture(
			palette_coord,
			neutral_palette_texture
		);
	}else{
		output_color = input_color;
	}
}


/*
 * This function is executed for every pixel of the base texture on which
 * this shader is being applied. For every one of those pixels, this function
 * tries to figure out if its color is mapped in an input palette and
 * tries to replace such color with its corresponding one in an output palette.
 * Such operations are done with the palette textures first and then with
 * the palette arrays so that the arrays are prioritized over the textures,
 * when applicable.
 */
void fragment() {
	vec4 input_color = texture(TEXTURE, UV);
	vec4 output_color = texture(TEXTURE, UV);

	if (palette_choice != 0)
	{
		swap_colors_from_palette_textures(input_color, output_color);
	}

	COLOR = output_color;
}