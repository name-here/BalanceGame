tool

class_name DeathPit extends Sprite


signal pit_entered

# Character must be within bounds (texture width plus padding) of pit horizontally,
# and bottom_death_distance below bottom of pit's texture to "enter" pit
export(int) var left_padding:int
export(int) var right_padding:int
export(int) var bottom_death_distance:int = 192

export(Color) var color1:Color = Color(0, 0, 0, 1) setget _set_color1
export(Color) var color2:Color = Color(1, 0, 0, 1) setget _set_color2

export(NodePath) var _character:NodePath
var character:Character

var is_in_pit := false#True if character is currently in this pit


func _ready() -> void:
	if Engine.editor_hint:
		material = material.duplicate()
	
	if _character:
		character = get_node(_character)
	
	_set_color1(color1)
	_set_color2(color2)

func _physics_process(delta) -> void:
	if not Engine.editor_hint and character:
		var pit_size:Vector2 = region_rect.size * global_scale
		if character.global_position.y >= global_position.y + pit_size.y + bottom_death_distance and \
				character.global_position.x >= global_position.x - left_padding and \
				character.global_position.x <= global_position.x + pit_size.x + right_padding:
			if not is_in_pit:
				emit_signal("pit_entered")
				is_in_pit = true
		else:
			is_in_pit = false


func _set_color1(new_color:Color) -> void:
	material.set_shader_param("color1", new_color)
	color1 = new_color

func _set_color2(new_color:Color) -> void:
	material.set_shader_param("color2", new_color)
	color2 = new_color
