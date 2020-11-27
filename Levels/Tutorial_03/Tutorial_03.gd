extends LevelController


export(NodePath) var _goal:NodePath
onready var goal:Sprite = get_node(_goal)
export(NodePath) var _left_wall:NodePath
onready var left_wall:StaticBody2D = get_node(_left_wall)
export(NodePath) var _floor_:NodePath
onready var floor_:StaticBody2D = get_node(_floor_)


func _ready():
	_on_window_resize()


func set_active(value := true) -> void:
	self.end_position.x = goal.global_position.x
	.set_active(value)
	_on_window_resize()
	pause()
	_on_intro_anim_done()

func _on_intro_anim_done() -> void:
	get_viewport().connect("size_changed", self, "_on_window_resize")
	play()


func _on_level_state_changed(new_state:int, last_state:int):
	match new_state:
		states.COMPLETE_1:
			tween.interpolate_property(camera, "global_position",
				camera.global_position, Vector2(goal.global_position.x, goal.global_position.y - 256), completion_anim_times[0], Tween.TRANS_CUBIC)

func _on_level_restart(time:float):
	tween.interpolate_property(camera, "global_position",
		camera.global_position, Vector2(0, -256), completion_anim_times[0], Tween.TRANS_CUBIC)


func _on_window_resize():
	var new_size = get_viewport_rect().size
	left_wall.global_scale.y = new_size.y / 2 + 256
	left_wall.global_position = Vector2((left_wall.global_scale.x - new_size.x) / 2, -left_wall.global_scale.y / 2)
	floor_.set_size(new_size.x * 2, new_size.y / 2 - 256)
