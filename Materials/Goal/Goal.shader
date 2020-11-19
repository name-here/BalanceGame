shader_type canvas_item;

uniform bool isActive = true;
uniform float fadeOpacity = 1.0;
uniform vec4 color = vec4(1.0);

void fragment(){
	float opacity = (UV.y > 2.0/3.0)? 1.0 : ( isActive? (UV.y * fadeOpacity * 2.0 / 3.0) : 0.0 );//Creates fade in top 2/3 of texture, or leaves top 2/3  blank if is_active is false
	vec4 textureColor = texture(TEXTURE, UV) * color;
	COLOR = vec4(textureColor.rgb, textureColor.a * opacity);
}
