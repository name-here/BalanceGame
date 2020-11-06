extends Node2D

export(NodePath) var _character:NodePath
onready var character:Node2D = get_node(_character)
export(NodePath) var _camera:NodePath
onready var camera:Camera2D = get_node(_camera)
export(NodePath) var _goal:NodePath
onready var goal:Sprite = get_node(_goal)

export(NodePath) var _character_label:NodePath
onready var character_label:Label = get_node(_character_label)
export(NodePath) var _completed_text:NodePath
onready var completed_text:Label = get_node(_completed_text)

export(NodePath) var _tween:NodePath
onready var tween:Tween = get_node(_tween)

const completion_anim_times := [1.5, 1]

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
var body_positions:PoolVector2Array
var body_rotations:PoolRealArray
var wheel_positions:PoolVector2Array
var wheel_rotations:PoolRealArray

func _ready():
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
				if body_positions.size() > 0:
					character.body.global_position = body_positions[0]
					character.body.global_rotation = body_rotations[0]
					character.wheel.global_position = wheel_positions[0]
					character.wheel.global_rotation = wheel_rotations[0]
				body_positions = PoolVector2Array()
				body_rotations = PoolRealArray()
				wheel_positions = PoolVector2Array()
				wheel_rotations = PoolRealArray()
				set_physics(true)
				level_state = states.PLAYING


func restart(time:float = 1, override:bool = false):
	if override or level_state == states.PLAYING:
		set_physics(false)
		character.body.angular_velocity = 0
		character.body.linear_velocity = Vector2(0, 0)
		character.wheel.angular_velocity = 0
		character.wheel.linear_velocity = Vector2(0, 0)
		rewind_length = time
		rewind_time = rewind_length
		level_state = states.RESTARTING
	else:
		match level_state:
			states.COMPLETE_3:
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

func next_complete_anim():
	if level_state >= states.COMPLETE_1:
		if level_state < states.size() - 1:
			level_state += 1
	else:
		level_state = states.COMPLETE_1
	
	match level_state:
		states.COMPLETE_1:
			tween.interpolate_property(camera, "global_position:x",
				camera.global_position.x, goal.global_position.x, completion_anim_times[0], Tween.TRANS_CUBIC)
			tween.interpolate_method(self, "set_character_label_color",
				Color(1, 1, 1, 1), Color(1, 1, 1, 0), completion_anim_times[0])
			tween.interpolate_property(Engine, "time_scale", Engine.time_scale, 0, completion_anim_times[0], Tween.TRANS_EXPO, Tween.EASE_OUT)
			tween.interpolate_callback(self, completion_anim_times[0], "reset_timescales")
			tween.interpolate_deferred_callback(self, completion_anim_times[0], "next_complete_anim")
			tween.ignore_engine_timescale = true
			tween.start()
		
		states.COMPLETE_2:
			set_physics(false)
			tween.remove_all()
			character.update_origin()
			tween.interpolate_method(self, "set_character_state",
				Vector3(character.global_position.x, character.global_position.y, character.body.global_rotation),
				Vector3(goal.global_position.x, -192, 0),
				completion_anim_times[1], Tween.TRANS_CUBIC)
			tween.interpolate_method(self, "set_completed_text_color",
				Color(1, 1, 1, 0), Color(1, 1, 1, 1), completion_anim_times[1])
			tween.interpolate_deferred_callback(self, completion_anim_times[1], "next_complete_anim")
			tween.start()


func set_physics(value:bool):
	Physics2DServer.set_active(value)
	character.do_torque_input = value

func set_active(value := true):
	if value:
		_on_window_resize()
		camera.make_current()
		level_state = states.PLAYING
		#get_viewport().connect("size_changed", self, "_on_window_resize")
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

func set_completed_text_color(color:Color):
	completed_text.set("custom_colors/font_color", color)

func reset_timescales():
	tween.ignore_engine_timescale = false
	tween.playback_speed = 1
	Engine.time_scale = 1


func _input(event):
	if event.is_action_pressed("reset_level"):
		match level_state:
			states.PLAYING:
				restart(0.5)
			states.COMPLETE_3:
				restart(2)

func _on_window_resize():
	camera.position.x = get_viewport_rect().size.x / 2
	goal.position.x = get_viewport_rect().size.x - 160
