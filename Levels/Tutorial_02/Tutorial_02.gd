extends LevelController


export(NodePath) var _goal:NodePath
onready var goal:Sprite = get_node(_goal)
export(NodePath) var _start:NodePath
onready var start:Sprite = get_node(_start)
export(NodePath) var _left_wall:NodePath
onready var left_wall:StaticBody2D = get_node(_left_wall)
export(NodePath) var _floor_:NodePath
onready var floor_:StaticBody2D = get_node(_floor_)

export(float) var intro_anim_time:float = 3



func set_active(value := true) -> void:
	self.end_position.x = goal.global_position.x
	.set_active(value)
	var window_size:Vector2 = _on_window_resize()
	pause()
	
	floor_.ramp_center.modulate.a = 0
	var ramp_height = floor_.get_ramp_end_height()
	floor_.set_ramp_end_height(0)
	goal.global_position.y = -32
	
	left_wall.global_position.x = -window_size.x / 2 - 16
	tween.interpolate_property(left_wall, "global_position:x",
		left_wall.global_position.x, -window_size.x / 2 + 16,
		intro_anim_time / 2, Tween.TRANS_CIRC, Tween.EASE_OUT)
	tween.interpolate_property(start, "global_position:x",
		0, start.global_position.x, intro_anim_time / 3, Tween.TRANS_CUBIC)
	start.global_position.x = 0
	tween.interpolate_property(character, "global_position:x",
		0, character.global_position.x, intro_anim_time / 3, Tween.TRANS_CUBIC)
	character.global_position.x = 0
	tween.interpolate_property(goal, "global_position:x",
		get_viewport_rect().size.x / 2 + goal.global_position.x / 2, goal.global_position.x,
		intro_anim_time / 2, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	goal.global_position.x = window_size.x / 2 + goal.global_position.x / 2#global_position seems wrong here<<<<<<<<<<<<
	tween.interpolate_callback(self, intro_anim_time / 2, "intro_anim_2",
		intro_anim_time / 2, ramp_height)
	tween.start()

func intro_anim_2(time:float, final_height:float) -> void:
	tween.interpolate_property(goal, "global_position:y",
		-32, final_height - 32, time, Tween.TRANS_CUBIC)
	tween.interpolate_method(floor_, "set_ramp_end_height", 0, final_height,
		time, Tween.TRANS_CUBIC)
	tween.interpolate_property(floor_.ramp_center, "modulate:a", 0, 1,
		time, Tween.TRANS_CUBIC, Tween.EASE_IN)
	tween.interpolate_callback(self, time, "_on_intro_anim_done")
	tween.start()

func _on_intro_anim_done() -> void:
	get_viewport().connect("size_changed", self, "_on_window_resize")
	play()


func _on_level_state_changed(new_state:int, last_state:int) -> void:
	match new_state:
		states.COMPLETE_1:
			tween.interpolate_property(camera, "global_position",
				camera.global_position, end_position + Vector2(0, -256),
				completion_anim_times[0], Tween.TRANS_CUBIC)
		
		states.NEXT_LEVEL_TRANSITION:
			tween.interpolate_property(goal, "fade_color:a",
				goal.fade_color.a, 0, next_level_anim_time)
			tween.interpolate_property(goal, "base_color",
				goal.base_color, Color(127), next_level_anim_time)
			tween.interpolate_method(floor_, "set_ramp_start_height",
				floor_.get_ramp_start_height(), floor_.get_ramp_end_height(),
				next_level_anim_time, Tween.TRANS_CUBIC)
			tween.interpolate_property(start, "global_position:y",
				start.global_position.y, floor_.get_ramp_end_height() - 32,
				next_level_anim_time, Tween.TRANS_CUBIC)
			tween.interpolate_property(start, "global_position:x",
				start.global_position.x, camera.global_position.x - get_viewport_rect().size.x / 2 - 128,
				next_level_anim_time, Tween.TRANS_CUBIC)

func _on_level_restarting(time:float) -> void:
	tween.interpolate_property(camera, "global_position",
		camera.global_position, Vector2(0, -256),
		completion_anim_times[0], Tween.TRANS_CUBIC, Tween.EASE_OUT)


func _on_window_resize() -> Vector2:
	var new_size:Vector2 = get_viewport_rect().size
	left_wall.global_scale.y = new_size.y / 2 + 256
	left_wall.global_position = Vector2((left_wall.global_scale.x - new_size.x) / 2, -left_wall.global_scale.y / 2)
	floor_.set_size(new_size.x * 2, new_size.y / 2 - 256)
	return new_size
