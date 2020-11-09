extends Node2D

export(NodePath) var _character:NodePath
onready var character:Node2D = get_node(_character)
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
export(Array, NodePath) var _end_texts:Array
var end_texts:Array

export(NodePath) var _rewind_overlay:NodePath
onready var rewind_overlay:ColorRect = get_node(_rewind_overlay)

export(NodePath) var _tween:NodePath
onready var tween:Tween = get_node(_tween)

export(Array, float) var completion_anim_times := [1.5, 1.0]

enum states{
	INACTIVE,
	PAUSED,
	PLAYING,
	RESTARTING,
	COMPLETE_1,
	COMPLETE_2,
	COMPLETE_3,
}
var level_state:int = states.INACTIVE

var rewind_length:float = 1#number of seconds it takes to rewind
var rewind_time:float = 1#number of seconds left for rewind
onready var body_positions:PoolVector2Array = [character.body.global_position]
var body_positions_init:PoolVector2Array
onready var body_rotations:PoolRealArray = [character.body.global_rotation]
var body_rotations_init:PoolRealArray
onready var wheel_positions:PoolVector2Array = [character.wheel.global_position]
var wheel_positions_init:PoolVector2Array
onready var wheel_rotations:PoolRealArray = [character.wheel.global_rotation]
var wheel_rotations_init:PoolRealArray

func _ready():
	for time in completion_anim_times:
		assert(time > 0)
	
	for i in _end_texts.size():
		assert(_end_texts[i] is NodePath)
		end_texts.append( get_node(_end_texts[i]) )
		assert(end_texts[i] is Label)
		
	
	body_positions_init = body_positions
	body_rotations_init = body_rotations
	wheel_positions_init = wheel_positions
	wheel_rotations_init = wheel_rotations
	set_active()


func _process(delta):
	match level_state:
		states.PLAYING:
			var goal_position := goal.global_position.x - goal.scale.x / 2
			if character.wheel.global_position.x > goal_position and character.body.global_position.x > goal_position:
				next_complete_anim()
			body_positions.append(character.body.global_position)
			body_rotations.append(character.body.global_rotation)
			wheel_positions.append(character.wheel.global_position)
			wheel_rotations.append(character.wheel.global_rotation)
		states.RESTARTING:
			if body_positions.size() > 0 and rewind_time >= 0:
				var rewind_frame := int( (body_positions.size() - 1) * rewind_time / rewind_length )
				if rewind_frame < 0:
					push_error( str("positions: ", body_positions.size()-1, ", time: ", rewind_time, ", length: ", rewind_length, ", frame: ", rewind_frame) )
					assert(rewind_frame >= 0)
				else:
					character.body.global_position = body_positions[rewind_frame]
					character.body.global_rotation = body_rotations[rewind_frame]
					character.wheel.global_position = wheel_positions[rewind_frame]
					character.wheel.global_rotation = wheel_rotations[rewind_frame]
					rewind_time -= delta
			else:
				rewind_time = 0
				body_positions = body_positions_init
				body_rotations = body_rotations_init
				wheel_positions = wheel_positions_init
				wheel_rotations = wheel_rotations_init
				if body_positions.size() > 0:
					character.body.global_position = body_positions[0]
					character.body.global_rotation = body_rotations[0]
					character.wheel.global_position = wheel_positions[0]
					character.wheel.global_rotation = wheel_rotations[0]
				level_state = states.PAUSED
				tween.interpolate_property(rewind_overlay, "color:a", rewind_overlay.color.a, 0, 0.5)
				tween.interpolate_deferred_callback(self, 0.5, "play")
				tween.start()
		#states.COMPLETE_2:
		#	print("stage 2, ", character.body.global_position, ", ", character.wheel.global_position)


func next_complete_anim() -> void:
	if level_state < states.COMPLETE_1:
		level_state = states.COMPLETE_1
	elif level_state < states.size() - 1:
		level_state += 1
	
	#print("asked for stage ", states.keys()[level_state])
	
	match level_state:
		states.COMPLETE_1:
			tween.interpolate_property(camera, "global_position:x",
				camera.global_position.x, goal.global_position.x, completion_anim_times[0], Tween.TRANS_CUBIC)
			tween.interpolate_method(self, "set_character_label_color",
				Color(1, 1, 1, 1), Color(1, 1, 1, 0), completion_anim_times[0])
			tween.interpolate_property(Engine, "time_scale", Engine.time_scale, 0, completion_anim_times[0], Tween.TRANS_EXPO, Tween.EASE_OUT)
			#tween.interpolate_callback(self, completion_anim_times[0], "reset_timescales")
			#tween.interpolate_callback(self, completion_anim_times[0], "set_physics", false)
			tween.interpolate_callback(self, completion_anim_times[0], "next_complete_anim")
			tween.ignore_engine_timescale = true
			tween.start()
		
		states.COMPLETE_2:
			#reset_timescales()
			set_physics(false)
			tween.remove_all()
			character.update_origin()
			tween.interpolate_method(self, "set_character_state",
				Vector3(character.global_position.x, character.global_position.y, character.body.global_rotation),
				Vector3(goal.global_position.x, -192, 0),
				completion_anim_times[1], Tween.TRANS_CUBIC)
			tween.interpolate_method(self, "set_completed_text_alpha",
				0, 1, completion_anim_times[1])
			tween.interpolate_callback(self, completion_anim_times[1], "next_complete_anim")
			tween.start()


func pause() -> void:
	set_physics(false)
	level_state = states.PAUSED

func play() -> void:
	set_physics(true)
	level_state = states.PLAYING

func restart(time:float = 1, override:bool = false):
	if time <= 0:
		assert(time > 0)
		time = 1.0
	if override or level_state == states.PLAYING:
		set_physics(false)
		character.body.angular_velocity = 0
		character.body.linear_velocity = Vector2(0, 0)
		character.wheel.angular_velocity = 0
		character.wheel.linear_velocity = Vector2(0, 0)
		rewind_length = time
		rewind_time = rewind_length
		tween.interpolate_property(rewind_overlay, "color:a", 0, 0.15, 0.1)
		tween.start()
		level_state = states.RESTARTING
	else:
		match level_state:
			states.COMPLETE_3:
				level_state = states.PAUSED
				var last = body_positions.size() - 1
				tween.interpolate_method(self, "set_completed_text_color",
					Color(1, 1, 1, 1), Color(1, 1, 1, 0), time/2, Tween.TRANS_EXPO, Tween.EASE_OUT)
				tween.interpolate_method(self, "set_character_state",
					Vector3(character.global_position.x, character.global_position.y, character.body.global_rotation),
					Vector3(body_positions[last].x, body_positions[last].y, body_rotations[last]),
					time/2, Tween.TRANS_EXPO, Tween.EASE_IN)
				tween.interpolate_method(self, "set_character_label_color",
					Color(1, 1, 1, 0), Color(1, 1, 1, 1), time/2)
				tween.interpolate_property(camera, "global_position:x",
					camera.global_position.x, get_viewport_rect().size.x / 2, time/2, Tween.TRANS_CUBIC)
				tween.interpolate_deferred_callback(self, time/2, "restart", time/2, true)
				tween.start()


func set_physics(value:bool):
	Physics2DServer.set_active(value)
	character.do_torque_input = value

func set_active(value := true):
	if value:
		_on_window_resize()
		camera.make_current()
		level_state = states.PLAYING
		get_viewport().connect("size_changed", self, "_on_window_resize")
	else:
		level_state = states.INACTIVE


func set_character_state(new_state:Vector3):#sets position and rotation (pos.x, pos.y, rotation)
	var new_position := Vector2(new_state[0], new_state[1])
	var distance:float = character.body.global_position.distance_to(character.wheel.global_position)
	character.body.global_position = new_position
	character.body.global_rotation = new_state[2]
	character.wheel.global_position = new_position + Vector2( -sin(new_state[2]), cos(new_state[2]) ) * distance
	character.connector.global_position = character.wheel.global_position
	character.connector.global_rotation = character.body.global_rotation

func set_character_label_color(color:Color):
	character_label.set("custom_colors/font_color", color)

func set_completed_text_alpha(alpha:float):
	for text in end_texts:
		var target_color:Color = text.get_color("font_color", "Label")
		target_color.a = alpha
		text.add_color_override("font_color", target_color)

#func reset_timescales():
#	tween.ignore_engine_timescale = false
#	tween.playback_speed = 1
#	Engine.time_scale = 1


func _input(event):
	if event.is_action_pressed("reset_level"):
		#print(states.keys()[level_state])
		match level_state:
			states.PLAYING:
				restart(0.5)
			states.COMPLETE_3:
				restart(2)
	elif event.is_action_pressed("toggle_fullscreen"):
		OS.window_fullscreen = !OS.window_fullscreen
	elif event.is_action_pressed("toggle_fullscreen"):
		OS.window_fullscreen = false

func _on_window_resize():
	var new_size:Vector2 = get_viewport_rect().size
	camera.position.x = new_size.x / 2
	floor_.scale = Vector2(new_size.x * 2, new_size.y / 2 - 256)
	floor_.position = floor_.scale / 2
	wall.scale.y = new_size.y / 2 + 256
	wall.position.y = -wall.scale.y / 2
	goal.position.x = new_size.x - 160
