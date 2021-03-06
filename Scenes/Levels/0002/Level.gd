extends LevelController


export(NodePath) var _start:NodePath
onready var start:Goal = get_node(_start)
export(NodePath) var _goal:NodePath
onready var goal:Goal = get_node(_goal)
export(NodePath) var _wall:NodePath
onready var wall:StaticBody2D = get_node(_wall)
export(NodePath) var _floor_:NodePath
onready var floor_:StaticBody2D = get_node(_floor_)

export(NodePath) var _ramp_text:NodePath
onready var ramp_text:Node2D = get_node(_ramp_text)

export(float) var intro_anim_time:float = 3



func set_active(value := true) -> void:
	self.end_position.x = goal.global_position.x
	.set_active(value)
	var window_size:Vector2 = _on_window_resize()
	pause()
	
	ramp_text.modulate.a = 0
	var ramp_height = floor_.get_ramp_end_height()
	floor_.set_ramp_end_height(0)
	goal.global_position.y = 0
	
	tween.interpolate_property(wall, "global_position:x",
		wall.global_position.x - wall.global_scale.x, wall.global_position.x,
		intro_anim_time / 2, Tween.TRANS_CUBIC)
	wall.global_position.x -= wall.global_scale.x
	tween.interpolate_property(start, "global_position:x",
		0, start.global_position.x, intro_anim_time / 3, Tween.TRANS_CUBIC)
	start.global_position.x = 0
	tween.interpolate_property(character, "global_position:x",
		0, character.global_position.x, intro_anim_time / 3, Tween.TRANS_CUBIC)
	character.global_position.x = 0
	tween.interpolate_property(goal, "global_position:x",
		window_size.x / 2 + 128, goal.global_position.x,
		intro_anim_time / 2, Tween.TRANS_CUBIC)
	goal.global_position.x = window_size.x / 2 + goal.global_position.x / 2#Global_position seems like the wrong thing to use here<<<<<<<<<<<<
	tween.interpolate_callback(self, intro_anim_time / 2, "_intro_anim_part_2",
		intro_anim_time / 2, ramp_height)
	tween.start()

func _intro_anim_part_2(time:float, final_height:float) -> void:
	tween.interpolate_property(goal, "global_position:y",
		goal.global_position.y, final_height, time, Tween.TRANS_CUBIC)
	tween.interpolate_method(floor_, "set_ramp_end_height", 0, final_height,
		time, Tween.TRANS_CUBIC)
	tween.interpolate_property(ramp_text, "modulate:a", 0, 1,
		time, Tween.TRANS_CUBIC, Tween.EASE_IN)#These fade-ins should really be happening in LevelController <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
	tween.interpolate_callback(self, time, "_on_intro_anim_done")
	tween.start()

func _on_intro_anim_done() -> void:
	get_viewport().connect("size_changed", self, "_on_window_resize")
	play()


func _on_level_state_changed(new_state:int, last_state:int) -> void:
	match new_state:
		States.COMPLETE_1:
			tween.interpolate_property(camera, "global_position",
				camera.global_position, end_position + Vector2(0, -256),
				completion_anim_times[0], Tween.TRANS_CUBIC)
		
		States.NEXT_LEVEL_TRANSITION:
			goal.emit_particles = false
			tween.interpolate_property(goal, "particle_color:a",
				goal.particle_color.a, 0, next_level_anim_time)
			tween.interpolate_property(goal, "fade_color:a",
				goal.fade_color.a, 0, next_level_anim_time)
			tween.interpolate_property(goal, "base_color",
				goal.base_color, Color(127), next_level_anim_time)
			tween.interpolate_method(floor_, "set_ramp_start_height",
				floor_.get_ramp_start_height(), floor_.get_ramp_end_height(),
				next_level_anim_time, Tween.TRANS_CUBIC)
			tween.interpolate_property(start, "global_position:y",
				start.global_position.y, floor_.get_ramp_end_height(),
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
	wall.scale.y = new_size.y / 2 + 256
	wall.global_position.x = -new_size.x / 2
	floor_.set_size(new_size.x * 2, new_size.y / 2 - 256)
	return new_size
