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
	pass


func set_active(value := true) -> void:
	level_controller.end_position.x = goal.global_position.x
	level_controller.set_active(value)
	_on_window_resize()
	level_controller.pause()


func _on_window_resize():
	pass
