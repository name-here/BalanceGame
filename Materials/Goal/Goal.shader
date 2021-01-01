shader_type canvas_item;

uniform bool isActive = true;
uniform vec4 fadeColor : hint_color = vec4(1.0);
uniform vec4 baseColor : hint_color = vec4(1.0);

void fragment(){
	// Creates fade in top 2/3 of texture, or leaves top 2/3  blank if is_active is false
	float modeSwitch = float(UV.y > 0.7499);
	float fadeAlpha = UV.y * 4.0 / 3.0;
	COLOR = texture(TEXTURE, UV)  *  (
		modeSwitch * baseColor  +
		(1.0 - modeSwitch) * float(isActive) *
			vec4(fadeColor.rgb, fadeColor.a * fadeAlpha*fadeAlpha)
		);
}
