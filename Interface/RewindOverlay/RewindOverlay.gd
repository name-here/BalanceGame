tool

class_name RewindOverlay extends Control


export(Color) var color:Color setget _set_color
#var buffer_names := ["buffer0", "buffer1", "buffer2", "buffer3"]
#var buffer:Array
var next_buffer:int = 0
var frame_count:int = 0


func _ready() -> void:
	material = material.duplicate()
	#material.set_shader_param("testTexture", get_viewport().get_texture())#.duplicate())
	#for i in buffer_names.size():
	#	var image := Image.new()
	#	image.copy_from( get_viewport().get_texture().get_data() )
	#	image.crop(100, 1000)
	#	image.crop(1000, 1000)
	#	buffer.append(image)
	#	material.set_shader_param(buffer_names[i], buffer[i])

func _draw() -> void:
	draw_rect(Rect2(rect_position, rect_size), Color())

func _set_color(new_color:Color) -> void:
	color = new_color
	visible = color.a > 0
	if visible:
		material.set_shader_param("color", color)#TODO: This should be done only when color is changed, not every frame.
	#if frame_count >= 2:
	#	frame_count = 0
	#	#Potential leak here?  If so, should get old texturee and free() before overwriting
	#	material.set_shader_param(buffer_names[0], buffer[next_buffer])
	#	next_buffer = (next_buffer + 1) % buffer_names.size()
	update()
