extends LevelController


export(NodePath) var _goal:NodePath
onready var goal:Sprite = get_node(_goal)
export(NodePath) var _floor_:NodePath
onready var floor_:StaticBody2D = get_node(_floor_)
export(NodePath) var _wall:NodePath
onready var wall:StaticBody2D = get_node(_wall)
export(float) var wall_width:float



func set_active(value := true) -> void:
	.set_active(value)
	_on_window_resize()
	get_viewport().connect("size_changed", self, "_on_window_resize")


func _on_level_state_changed(new_state:int, last_state:int) -> void:#TODO: Change how this connects to LevelController?
	match new_state:
		states.COMPLETE_1:
			tween.interpolate_property(camera, "global_position:x",
				camera.global_position.x, goal.global_position.x, completion_anim_times[0], Tween.TRANS_CUBIC)
		
		states.NEXT_LEVEL_TRANSITION:
			tween.interpolate_property(goal, "fade_color:a",
				goal.fade_color.a, 0, next_level_anim_time)
			tween.interpolate_property(goal, "base_color",
				goal.base_color, Color(127), next_level_anim_time)
			#if get_viewport_rect().size.x / 2 > camera.global_position.x - 16:
			#	level_controller.tween.interpolate_property(wall, "global_position:x",
			#		wall.global_position.x, camera.global_position.x - get_viewport_rect().size.x / 2 - wall.scale.x / 2,
			#		level_controller.next_level_anim_time, Tween.TRANS_CUBIC, Tween.EASE_IN)
			#tween.start()Don't need to start the tween, since it gets started later (it shouldn't matter, though)

func _on_level_restart(time:float) -> void:
	tween.interpolate_property(camera, "global_position:x",
		camera.global_position.x, 512, time/2, Tween.TRANS_CUBIC)


func _on_window_resize() -> void:#TODO: Change some of this to not use global properties!<<<<<<<<<<<<<<<<<<<<<<<<<
	var new_size:Vector2 = get_viewport_rect().size
	floor_.scale = Vector2(new_size.x * 2, new_size.y / 2 - 256)
	floor_.global_position.x = floor_.scale.x / 2 - new_size.x / 2 + 512
	#wall.scale = Vector2(new_size.x / 2 - 512 + wall_width, new_size.y / 2 + 256)
	wall.scale.y = new_size.y / 2 + 256
	#wall.global_position = Vector2(wall_width - wall.scale.x / 2, -wall.scale.y / 2)
	wall.global_position = Vector2(512 - (new_size.x - wall_width) / 2, -wall.scale.y / 2)
	#goal.global_position.x = 1024 - 128 - 32
	
	#level_controller.end_position.x = goal.global_position.x
	#if level_controller.state < level_controller.states.COMPLETE_1:
	#	camera.global_position.x = 512#new_size.x / 2
	if state > states.COMPLETE_1:
		camera.global_position.x = goal.global_position.x
		character.global_position.x = goal.global_position.x
