shader_type canvas_item;

uniform vec4 alternateColor;

void fragment(){
	COLOR = (texture(TEXTURE, UV) == textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0)) ? alternateColor : texture(TEXTURE, UV);
}