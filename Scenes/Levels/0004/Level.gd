extends LevelController


export(NodePath) var _start:NodePath
onready var start:Goal = get_node(_start)
export(NodePath) var _goal:NodePath
onready var goal:Goal = get_node(_goal)
export(NodePath) var _wall:NodePath
onready var wall:StaticBody2D = get_node(_wall)
export(NodePath) var _floor_left:NodePath
onready var floor_left:PolygonBlock = get_node(_floor_left)
export(NodePath) var _floor_right:NodePath
onready var floor_right:StaticBody2D = get_node(_floor_right)
export(NodePath) var _death_pit:NodePath
onready var death_pit:DeathPit = get_node(_death_pit)

export(NodePath) var _pit_text:NodePath
onready var pit_text:Label = get_node(_pit_text)

export(float) var intro_anim_time:float = 2



func set_active(value := true) -> void:
	.set_active(value)
	if value:
		var window_size:Vector2 = _on_window_resize()
		pause()
		
		var target_width:float = floor_left.get_width()
		floor_left.set_width(floor_right.position.x)
		var target_height:float = floor_left.get_height()
		floor_left.set_height(0)
		pit_text.modulate.a = 0
		
		var time:float = intro_anim_time / 3
		tween.interpolate_property(wall, "global_position:x",
			0, wall.global_position.x,
			time, Tween.TRANS_CUBIC, Tween.EASE_OUT)
		wall.global_position.x = 0
		tween.interpolate_property(start, "position:x",
			window_size.x / 2, start.position.x, time, Tween.TRANS_CUBIC)
		start.position.x = window_size.x / 2
		tween.interpolate_property(character, "global_position:x",
			start.global_position.x, character.global_position.x,
			time, Tween.TRANS_CUBIC)
		tween.interpolate_property(goal, "position:x",
			window_size.x + 128, goal.position.x, time, Tween.TRANS_CUBIC)
		tween.interpolate_callback(self, time, "_intro_anim_stage_2",
			intro_anim_time - time, target_width, target_height)
		tween.start()

func _intro_anim_stage_2(time_left:float, target_width:float, target_height:float) -> void:
	var time:float = time_left / 2
	tween.interpolate_method(floor_left, "set_width",
		floor_left.get_width(), target_width, time,
		Tween.TRANS_CUBIC)
	tween.interpolate_callback(self, time, "_intro_anim_stage_3",
		time_left - time, target_height)
	tween.start()

func _intro_anim_stage_3(time:float, target_height:float) -> void:
	tween.interpolate_method(floor_left, "set_height",
		floor_left.get_height(), target_height, time,
		Tween.TRANS_CUBIC)
	tween.interpolate_property(pit_text, "modulate:a", 0, 1,
		time, Tween.TRANS_CUBIC, Tween.EASE_IN)
	tween.interpolate_callback(self, time, "_on_intro_anim_done")
	tween.start()
	

func _on_intro_anim_done() -> void:
	get_viewport().connect("size_changed", self, "_on_window_resize")
	play()


func _on_level_state_changed(new_state:int, last_state:int) -> void:
	match new_state:
		States.PLAYING:
			pass
		States.COMPLETE_1:
			pass
		States.NEXT_LEVEL_TRANSITION:
			if scene_loader:
				scene_loader.load_scene(scene_loader.get_next_valid_index(0))
			return
			
			goal.emit_particles = false
			tween.interpolate_property(goal, "particle_color:a",
				goal.particle_color.a, 0, next_level_anim_time)
			tween.interpolate_property(goal, "fade_color:a",
				goal.fade_color.a, 0, next_level_anim_time)
			tween.interpolate_property(goal, "base_color",
				goal.base_color, Color(127), next_level_anim_time)
			tween.interpolate_method(floor_left, "set_width",
				floor_left.get_width(), floor_right.position.x,
				next_level_anim_time, Tween.TRANS_CUBIC)
			tween.interpolate_method(floor_left, "set_height",
				floor_left.get_height(), 0,
				next_level_anim_time, Tween.TRANS_CUBIC)
			tween.interpolate_property(start, "global_position:x",
				start.global_position.x, camera.global_position.x - get_viewport_rect().size.x / 2 - 128,
				next_level_anim_time, Tween.TRANS_CUBIC)
			tween.start()


func _on_window_resize() -> Vector2:
	var new_size:Vector2 = get_viewport_rect().size
	wall.scale.y = new_size.y
	floor_left.set_depth(new_size.y / 2)
	floor_right.scale = Vector2(new_size.x + 448, new_size.y / 2)
	death_pit.scale.y = (new_size.y / 2 - 255) / 64
	camera.limit_bottom = int(new_size.y / 2 - 256)
	return new_size
