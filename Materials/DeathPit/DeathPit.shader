shader_type canvas_item;

const float PI = 3.1415926535897932;

uniform vec4 color1 : hint_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 color2 : hint_color = vec4(1.0, 0.0, 0.0, 1.0);

void fragment(){
	float sine = sin( PI / (2.05 - sqrt(UV.y)*2.0) );
	float alpha1 =  UV.y/2.0 + 0.25 - sine / 4.0;
	float alpha2 = UV.y * (0.25 + sine / 4.0);
	COLOR =  texture(TEXTURE, UV)  *  vec4( color1.rgb * alpha1 + color2.rgb * alpha2,  color1.a * alpha1 + color2.a * alpha2 );
}