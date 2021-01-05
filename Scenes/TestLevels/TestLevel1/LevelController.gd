extends Node2D

export(NodePath) var _character:NodePath
onready var character:Node2D = get_node(_character)
export(NodePath) var _camera:NodePath
onready var camera:Camera2D = get_node(_camera)


func set_active(value:bool = true) -> void:
	if value:
		character.update_origin()
		camera.make_current()

func _input(event) -> void:
	if event.is_action_pressed("reset_level"):
		get_tree().reload_current_scene()
