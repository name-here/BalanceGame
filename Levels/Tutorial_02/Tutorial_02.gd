extends Node2D


export(NodePath) var _level_controller:NodePath
onready var level_controller:Node = get_node(_level_controller)

export(NodePath) var _goal:NodePath
onready var goal:Sprite = get_node(_goal)
export(NodePath) var _left_wall:NodePath
onready var left_wall:StaticBody2D = get_node(_left_wall)
export(NodePath) var _floor_:NodePath
onready var floor_:StaticBody2D = get_node(_floor_)


func _ready():
	set_active()


func set_active(value := true) -> void:
	level_controller.end_position = Vector2(goal.global_position.x, -192)
	level_controller.set_active(value)
	_on_window_resize()
	get_viewport().connect("size_changed", self, "_on_window_resize")


func _on_level_state_changed(new_state:int, last_state:int):
	pass

func _on_level_on_restart(time:int):
	pass


func _on_window_resize():
	var new_size:Vector2 = get_viewport_rect().size
	left_wall.scale.x = new_size.x / 2
	left_wall.scale.y = new_size.y / 2 + 256 + 1024#Character can go 1024 pixels into the air without seeing the wall's top
	left_wall.position = Vector2(64 - left_wall.scale.x / 2 - new_size.x / 2, -left_wall.scale.y / 2)
	floor_.scale = Vector2(2048 + new_size.x * 2, new_size.y / 2)
