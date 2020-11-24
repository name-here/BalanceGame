shader_type canvas_item;


//uniform vec4 color;

//uniform sampler2D buffer0;
//uniform sampler2D buffer1;
//uniform sampler2D buffer2;
//uniform sampler2D buffer3;

uniform sampler2D testTexture;


void fragment(){
	//vec4 average = 
	//	(	texture(buffer0, SCREEN_UV, 0.0) +
	//		texture(buffer1, SCREEN_UV, 0.0) +
	//		texture(buffer2, SCREEN_UV, 0.0) +
	//		texture(buffer3, SCREEN_UV, 0.0) +
	//		textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0) ) / 5.0;
	//COLOR = average * (1.0 - color.a)  +  vec4(color.rgb * color.a, color.a);
	COLOR = vec4(textureLod(testTexture, SCREEN_UV, 0.0).rgb, 1.0);
	//COLOR = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0) * (1.0 - color.a)  +  vec4(color.rgb * color.a, color.a);
}
