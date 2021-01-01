shader_type canvas_item;

uniform vec4 alternateColor : hint_color;

void fragment(){
	/*vec4 textureColor = texture(TEXTURE, UV);
	vec4 colorBehind = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0);
	float difference = (textureColor.r + textureColor.g + textureColor.b - colorBehind.r - colorBehind.g - colorBehind.b) / 3.0;
	float changeAmount = 1.0 - difference*difference;
	COLOR = ( alternateColor * changeAmount + textureColor * (1.0 - changeAmount) ) * textureColor.a;*/
	COLOR = (texture(TEXTURE, UV) == textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0)) ? alternateColor : texture(TEXTURE, UV);
}