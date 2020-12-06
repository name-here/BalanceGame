extends ColorRect


export(NodePath) var _moving_rect:NodePath
onready var moving_rect:Node2D = get_node(_moving_rect)
var time_elapsed:float = 0


func _ready() -> void:
	material.set_shader_param("testTexture", get_viewport().get_texture())

func _process(delta) -> void:
	time_elapsed += delta
	moving_rect.global_position.x = int(time_elapsed * 100)%int(get_viewport_rect().size.x - 100)
