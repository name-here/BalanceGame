tool
extends CanvasLayer


export(Color) var color:Color setget _set_color
export(NodePath) var _color_rect:NodePath
var color_rect:ColorRect

var viewport:Viewport

func _ready():
	if not Engine.editor_hint:
		viewport = get_viewport()
		color_rect = get_node(_color_rect)
		update_size()
		viewport.connect("size_changed", self, "update_size")
	#print("run from ready with ", color)
	_set_color(color)

func _set_color(new_color:Color):
	#print("setting ", color)
	if Engine.editor_hint:
		get_node(_color_rect).color = new_color
		ProjectSettings.set_setting("rendering/environment/default_clear_color", new_color)
	elif color_rect != null:
		color_rect.color = new_color
	color = new_color

func update_size():
	color_rect.rect_size = viewport.get_visible_rect().size
