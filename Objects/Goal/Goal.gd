tool

extends Sprite


signal goal_entered

export(bool) var is_active := true setget _set_active
export(Color) var fade_color := Color(1, 1, 1, 1) setget _set_fade_color
export(Color) var base_color := Color(1, 1, 1, 1) setget _set_base_color

export(NodePath) var _character:NodePath
onready var character:Character = get_node(_character)

func _ready() -> void:
	material = material.duplicate()
	_set_active(is_active)
	_set_fade_color(fade_color)
	_set_base_color(base_color)

func _process(_delta) -> void:
	if not Engine.editor_hint and character != null:
		var goal_position:float = global_position.x - 128
		if character.global_position.x > goal_position:
			emit_signal("goal_entered")


func _set_active(value:bool) -> void:
	material.set_shader_param("isActive", value)
	is_active = value

func _set_fade_color(new_color:Color) -> void:
	material.set_shader_param("fadeColor", new_color)
	fade_color = new_color

func _set_base_color(new_color:Color) -> void:
	material.set_shader_param("baseColor", new_color)
	base_color = new_color
