class_name EndScreen extends Control


signal restart_pressed
signal continue_pressed

export(bool) var active := false setget set_active
export(float) var alpha:float setget set_alpha

export(Array, NodePath) var _text_fields:Array
var text_fields:Array

export(Array, NodePath) var _buttons:Array
var buttons:Array

export(NodePath) var _background:NodePath
onready var background:ColorRect = get_node(_background)

func _ready() -> void:
	for i in _text_fields.size():
		assert(_text_fields[i] is NodePath)
		text_fields.append( get_node(_text_fields[i]) )
		assert(text_fields[i] is Label)
	for i in _buttons.size():
		assert(_buttons[i] is NodePath)
		buttons.append( get_node(_buttons[i]) )
		assert(buttons[i] is Button)
	
	set_alpha(alpha)
	set_active(active)


func set_alpha(new_alpha:float) -> void:
	if new_alpha > 0:
		set_visible(true)
	else:
		set_visible(false)
	for field in text_fields:
		var target_color:Color = field.get_color("font_color", "Label")
		target_color.a = alpha
		field.add_color_override("font_color", target_color)
	for button in buttons:
		for color_field in ["font_color", "font_color_disabled", "font_color_hover", "font_color_pressed"]:
			var target_color:Color = button.get_color(color_field, "Button")
			target_color.a = alpha
			button.add_color_override(color_field, target_color)
	if background:
		background.color.a = new_alpha / 4
	alpha = new_alpha

func set_active(value) -> void:
	for button in buttons:
			button.disabled = not value
	active = value


func _restart_pressed():
	emit_signal("restart_pressed")

func _continue_pressed():
	emit_signal("continue_pressed")
