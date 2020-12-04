shader_type canvas_item;

uniform bool isActive = true;
uniform vec4 fadeColor : hint_color = vec4(1.0);
uniform vec4 baseColor : hint_color = vec4(1.0);

void fragment(){
	// Creates fade in top 2/3 of texture, or leaves top 2/3  blank if is_active is false
	COLOR = texture(TEXTURE, UV) * (
		(UV.y > 2.0/3.0)? baseColor :
			( isActive? vec4(fadeColor.rgb, UV.y * fadeColor.a * 3.0 / 2.0) : vec4(0.0) )
	);
}
