tool

extends Sprite


signal goal_entered

export(bool) var is_active := true setget _set_active
export(float) var fade_opacity:float = 0 setget _set_fade_opacity
export(Color) var color := Color(1, 1, 1, 1) setget _set_color

export(NodePath) var _character:NodePath
onready var character:Character = get_node(_character)

func _ready():
	_set_active(is_active)
	_set_color(color)

func _process(_delta):
	if not Engine.editor_hint and character != null:
		var goal_position:float = global_position.x - 128
		if character.global_position.x > goal_position:
			emit_signal("goal_entered")


func _set_active(value:bool):
	material.set_shader_param("isActive", value)
	is_active = value

func _set_fade_opacity(new_opacity):
	material.set_shader_param("fadeOpacity", new_opacity)
	fade_opacity = new_opacity

func _set_color(new_color:Color):
	material.set_shader_param("color", new_color)
	color = new_color
