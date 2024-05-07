shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

void fragment()
{
	// This grabs the pixels on the screen
    vec4 currentScreenPixel = textureLod(screen_texture, SCREEN_UV, 0.0).rgba;

	// This grabs the texture we're lookinga at. C becomes the individual pixel we're rendering
	vec4 currentTexturePixel = texture(TEXTURE,UV);

	// Only invert the colors of the screen when our current pixel has an alpha value. Meaning it's opaque, not transparent
	if(currentTexturePixel.a == 1.0)
	{
    	COLOR = vec4(1.0 - currentScreenPixel.rgb, currentScreenPixel.a);
	}
}