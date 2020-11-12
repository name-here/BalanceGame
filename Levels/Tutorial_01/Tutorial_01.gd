extends Node2D


export(NodePath) var _level_controller:NodePath
onready var level_controller:LevelController = get_node(_level_controller)

export(NodePath) var _character:NodePath
onready var character:Character = get_node(_character)

export(NodePath) var _camera:NodePath
onready var camera:Camera2D = get_node(_camera)

export(NodePath) var _goal:NodePath
onready var goal:Sprite = get_node(_goal)
export(NodePath) var _floor_:NodePath
onready var floor_:StaticBody2D = get_node(_floor_)
export(NodePath) var _wall:NodePath
onready var wall:StaticBody2D = get_node(_wall)

export(NodePath) var _character_label:NodePath
onready var character_label:Label = get_node(_character_label)

func set_active(value := true) -> void:
	level_controller.set_active(value)
	_on_window_resize()
	get_viewport().connect("size_changed", self, "_on_window_resize")


func _on_level_state_changed(new_state:int, last_state:int):
	match new_state:
		level_controller.states.COMPLETE_1:
			level_controller.tween.interpolate_method(self, "set_character_label_alpha",
				1, 0, level_controller.completion_anim_times[0])
			level_controller.tween.interpolate_property(camera, "global_position:x",
				camera.global_position.x, goal.global_position.x, level_controller.completion_anim_times[0], Tween.TRANS_CUBIC)
		_:
			if new_state < level_controller.states.COMPLETE_1 and last_state >= level_controller.states.COMPLETE_1:
				level_controller.tween.interpolate_method(self, "set_character_label_alpha",
					0, 1, level_controller.completion_anim_times[0])

func _on_restart(time:float):
	level_controller.tween.interpolate_property(camera, "global_position:x",
		camera.global_position.x, get_viewport_rect().size.x / 2, time/2, Tween.TRANS_CUBIC)


func set_character_label_alpha(alpha:float):
	var target_color:Color = character_label.get_color("font_color", "Label")
	target_color.a = alpha
	character_label.set("custom_colors/font_color", target_color)


func _on_window_resize():#TODO: Change some of this to not use global properties!<<<<<<<<<<<<<<<<<<<<<<<<<
	var new_size:Vector2 = get_viewport_rect().size
	floor_.scale = Vector2(new_size.x * 2, new_size.y / 2 - 256)
	floor_.global_position.x = floor_.scale.x / 2
	wall.scale.y = new_size.y / 2 + 256
	wall.global_position.y = -wall.scale.y / 2
	goal.global_position.x = new_size.x - goal.global_scale.y / 2 - 32
	level_controller.end_position = Vector2(goal.global_position.x, -192)
	if level_controller.state < level_controller.states.COMPLETE_1:
		camera.global_position.x = new_size.x / 2
	elif level_controller.state > level_controller.states.COMPLETE_1:
		camera.global_position.x = goal.global_position.x
		character.global_position.x = goal.global_position.x
