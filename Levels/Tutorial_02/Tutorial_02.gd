extends Node2D


export(NodePath) var _level_controller:NodePath
onready var level_controller:Node = get_node(_level_controller)

export(NodePath) var _goal:NodePath
onready var goal:Sprite = get_node(_goal)
export(NodePath) var _left_wall:NodePath
onready var left_wall:StaticBody2D = get_node(_left_wall)
export(NodePath) var _floor_:NodePath
onready var floor_:StaticBody2D = get_node(_floor_)

export(float) var intro_anim_time:float = 2


func _ready():
	set_active()


func set_active(value := true) -> void:
	#ZZPhysics2DServer.set_active(false)
	level_controller.end_position.x = goal.global_position.x
	level_controller.set_active(value)
	_on_window_resize()
	#set_wall_y(0)
	get_viewport().connect("size_changed", self, "_on_window_resize")
	
	#level_controller.tween.interpolate_method(self, "set_wall_y",
	#	0, 1, intro_anim_time, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	#level_controller.tween.interpolate_deferred_callback(
	#		Physics2DServer, intro_anim_time, "set_active", true)
	#level_controller.tween.start()

#func set_wall_y(proportion:float):
#	assert(proportion >= 0.0 and proportion <= 1.0)
#	left_wall.position.y = (0.5 - proportion) * left_wall.scale.y


func _on_level_state_changed(new_state:int, last_state:int):
	pass

func _on_level_on_restart(time:int):
	pass


func _on_window_resize():
	var new_size:Vector2 = get_viewport_rect().size
	left_wall.scale.x = new_size.x / 2
	left_wall.scale.y = new_size.y / 2 + 256 + 1024#Character can go 1024 pixels into the air without seeing the wall's top
	left_wall.position = Vector2(64 - left_wall.scale.x / 2 - new_size.x / 2, -left_wall.scale.y / 2)
	#left_wall.position.x = 64 - left_wall.scale.x / 2 - new_size.x / 2
	#set_wall_y(1)
	floor_.scale = Vector2(2048 + new_size.x * 2, new_size.y / 2)
