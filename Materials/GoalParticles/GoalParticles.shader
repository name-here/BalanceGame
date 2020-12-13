shader_type canvas_item;

uniform vec4 glowColor : hint_color = vec4(1.0);

void fragment(){
	float x = abs(UV.x - 0.5) * 3.0 - 0.5;
	x = x * float(x >= 0.0) + 0.0 * float(x < 0.0);
	float y = abs(UV.y - 0.5) * 3.0 - 0.5;
	y = y * float(y >= 0.0) + 0.0 * float(y < 0.0);
	
	float alpha = (1.0 - (x*x + y*y));
	COLOR = vec4(COLOR.rgb * alpha + glowColor.rgb * (1.0-alpha), COLOR.a * glowColor.a * alpha);
}