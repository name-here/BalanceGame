class_name LevelController extends Node2D


signal state_changed(changed_to, changed_from)
signal on_restart(time)
#signal start_next_level

enum states{
	INACTIVE,
	PAUSED,
	PLAYING,
	RESTARTING,
	COMPLETE_1,
	COMPLETE_2,
	COMPLETE_3,
	TO_NEXT_LEVEL
}
var state:int = states.INACTIVE setget set_state

export(NodePath) var _character:NodePath
onready var character:Character = get_node(_character)
export(NodePath) var _camera:NodePath
onready var camera:Camera2D = get_node(_camera)

export(Vector2) var end_position:Vector2

export(NodePath) var _end_screen:NodePath
onready var end_screen:EndScreen = get_node(_end_screen)

export(NodePath) var _rewind_overlay:NodePath
onready var rewind_overlay:ColorRect = get_node(_rewind_overlay)

export(NodePath) var _tween:NodePath
onready var tween:Tween = get_node(_tween)

export(Array, float) var completion_anim_times := [1.5, 1.0]
export(float) var next_level_anim_time:float = 1.0

var rewind_time:float = 1#Number of seconds it takes to rewind
var rewind_time_left:float = 1#Number of seconds left for rewind

const history_max_size:int = 16#Is a power of 2 for simpler code/math
var history_length:int = 0
var skip_size:int = 1
var frames_since_last_write = 0
onready var body_positions:PoolVector2Array# = [character.body.global_position]
#var body_positions_init:PoolVector2Array
onready var body_rotations:PoolRealArray# = [character.body.global_rotation]
#var body_rotations_init:PoolRealArray
onready var wheel_positions:PoolVector2Array# = [character.wheel.global_position]
#var wheel_positions_init:PoolVector2Array
onready var wheel_rotations:PoolRealArray# = [character.wheel.global_rotation]
#var wheel_rotations_init:PoolRealArray
var test_data:PoolIntArray
var frame_num:int = 0


func _ready():
	for time in completion_anim_times:
		assert(time > 0)
	
	#body_positions_init = body_positions
	#body_rotations_init = body_rotations
	#wheel_positions_init = wheel_positions
	#wheel_rotations_init = wheel_rotations
	body_positions.resize(history_max_size)
	body_rotations.resize(history_max_size)
	wheel_positions.resize(history_max_size)
	wheel_rotations.resize(history_max_size)
	test_data.resize(history_max_size)
	for i in test_data.size():
		test_data[i] = -1


func _process(delta):
	match state:
		states.PLAYING:
			# The following code does (should do) the following:  (needed for rewind effect)
			# Start by writing character data to the history arrays.
			# When the whole array has been written, go back and overwrite every
			# other value (starting with the second), but twice as slowly
			# (every other frame).  This cuts time resolution in half,
			# and lets the program keep writing data without having to stop and
			# reorder this history arrays.  Playback happens in constant time,
			# so halved time resolution is (probably) not so noticable.
			# Next time it reaches history_max_size, cut time resolution in half
			# again, this time starting with the third value and writing
			# every 4 frames, skipping 4 frames forward in the arrays each time.
			# This is repeted until recording is done.
			frames_since_last_write += 1
			if frames_since_last_write >= skip_size:
				frames_since_last_write = 0
				var index:int = (history_length * skip_size + skip_size / 2) % history_max_size
				body_positions[index] = character.body.global_position
				body_rotations[index] = character.body.global_rotation
				wheel_positions[index] = character.wheel.global_position
				wheel_rotations[index] = character.wheel.global_rotation
				print(frame_num, " over ", test_data[index], " on ", history_length, "*", skip_size)
				test_data[index] = frame_num
				if history_length + 1 < history_max_size:
					history_length += 1
				else:#This probably doesn't work after skip_size gets near/over history_max_size, but that would take quite a while
					history_length = history_max_size / 2
					skip_size *= 2
				frame_num += 1
					
		
		states.RESTARTING:
			if history_length > 0 and rewind_time_left >= 0:
				var rewind_frame := int( (history_length - 1) * rewind_time_left / rewind_time )
				if rewind_frame < 0:
					push_error( str("positions: ", history_length-1, ", time: ", rewind_time_left, ", length: ", rewind_time, ", frame: ", rewind_frame) )
					assert(rewind_frame >= 0)
				else:
					# This unravels the somwhat complicated interwoven values
					# created by the system (described) above.
					var index:int = (rewind_frame * skip_size + skip_size / 2) % history_max_size#NOT FINISHED! <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
					character.body.global_position = body_positions[index]
					character.body.global_rotation = body_rotations[index]
					character.wheel.global_position = wheel_positions[index]
					character.wheel.global_rotation = wheel_rotations[index]
					print("got ", test_data[index], " for ", rewind_frame)
					rewind_time_left -= delta
			else:
				rewind_time_left = 0
				history_length = 0
				skip_size = 1
				frames_since_last_write = 0
				for i in test_data.size():
					test_data[i] = -1
				frame_num = 0
				#body_positions = body_positions_init
				#body_rotations = body_rotations_init
				#wheel_positions = wheel_positions_init
				#wheel_rotations = wheel_rotations_init
				if body_positions.size() > 0:
					character.body.global_position = body_positions[0]
					character.body.global_rotation = body_rotations[0]
					character.wheel.global_position = wheel_positions[0]
					character.wheel.global_rotation = wheel_rotations[0]
					print("got ", test_data[0], " for 0")
				set_state(states.PAUSED)
				tween.interpolate_property(rewind_overlay, "color:a", rewind_overlay.color.a, 0, 0.5)
				tween.interpolate_deferred_callback(self, 0.5, "play")
				tween.start()
		#states.COMPLETE_2:
		#	print("stage 2, ", character.body.global_position, ", ", character.wheel.global_position)


func next_complete_anim() -> void:
	if state < states.COMPLETE_1:
		set_state(states.COMPLETE_1)
	elif state < states.size() - 1:
		set_state(state + 1)
	
	#print("asked for stage ", states.keys()[state])
	
	match state:
		states.COMPLETE_1:
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
				Color( character.wheel.global_position.x, character.wheel.global_position.y,
					character.body.global_rotation, character.body.global_position.distance_to(character.wheel.global_position) ),
				Color( end_position.x, end_position.y,
					0, character.body.global_position.distance_to(character.wheel.global_position) ),
				completion_anim_times[1], Tween.TRANS_CUBIC)
			tween.interpolate_method(end_screen, "set_alpha",
				0, 1, completion_anim_times[1])
			tween.interpolate_callback(self, completion_anim_times[1], "next_complete_anim")
			tween.start()
		states.COMPLETE_3:
			end_screen.active = true


func pause() -> void:
	set_physics(false)
	set_state(states.PAUSED)

func play() -> void:
	set_physics(true)
	set_state(states.PLAYING)

func restart(time:float = 1, override:bool = false):
	if time <= 0:
		assert(time > 0)
		time = 1.0
	if override or state == states.PLAYING:
		set_physics(false)
		emit_signal("on_restart", time)
		character.body.angular_velocity = 0
		character.body.linear_velocity = Vector2(0, 0)
		character.wheel.angular_velocity = 0
		character.wheel.linear_velocity = Vector2(0, 0)
		rewind_time = time
		rewind_time_left = rewind_time
		tween.interpolate_property(rewind_overlay, "color:a", 0, 0.15, 0.1)
		tween.start()
		set_state(states.RESTARTING)
	else:
		match state:
			states.COMPLETE_3:
				set_state(states.PAUSED)
				var last = history_length - 1
				end_screen.active = false
				tween.interpolate_method(end_screen, "set_alpha",
					1, 0, time/2, Tween.TRANS_EXPO, Tween.EASE_OUT)
				tween.interpolate_method(self, "set_character_state",
					Color( character.global_position.x, character.global_position.y,
						character.body.global_rotation, character.body.global_position.distance_to(character.wheel.global_position) ),
					Color( body_positions[last].x, body_positions[last].y,
						body_rotations[last], character.body.global_position.distance_to(character.wheel.global_position) ),
					time/2, Tween.TRANS_EXPO, Tween.EASE_IN)
				tween.interpolate_deferred_callback(self, time/2, "restart", time/2, true)
				tween.start()

func go_to_next_level():
	end_screen.active = false
	set_state(states.TO_NEXT_LEVEL)
	tween.interpolate_method(self, "set_character_state",
		Color( character.wheel.global_position.x, character.wheel.global_position.y,
			character.body.global_rotation, character.body.global_position.distance_to(character.wheel.global_position) ),
		Color(end_position.x, -48, 0, 144),
		next_level_anim_time, Tween.TRANS_CUBIC)
	tween.interpolate_property(character.wheel, "rotation",
		character.wheel.rotation, 0, next_level_anim_time,  Tween.TRANS_CUBIC)
	tween.interpolate_method(end_screen, "set_alpha",
		1, 0, next_level_anim_time)
	#tween.interpolate_deferred_callback(self, next_level_anim_time, "emit_signal", "start_next_level")
	tween.start()


func set_state(new_state:int):
	call_deferred("emit_signal", "state_changed", new_state, state)
	state = new_state

func set_physics(value:bool):
	Physics2DServer.set_active(value)
	character.do_torque_input = value

func set_active(value := true):
	if value:
		camera.make_current()
		set_state(states.PLAYING)
		
	else:
		set_state(states.INACTIVE)


func set_character_state(new_state:Color):#sets position, rotation, and distance (pos.x, pos.y, rotation, distance)  (Color is just Vector4 in disguise)
	var new_position := Vector2(new_state[0], new_state[1])
	#var distance:float = character.body.global_position.distance_to(character.wheel.global_position)
	character.wheel.global_position = new_position
	character.body.global_position = new_position + Vector2( sin(new_state[2]), -cos(new_state[2]) ) * new_state[3]#distance
	character.body.global_rotation = new_state[2]
	character.connector.global_position = character.wheel.global_position
	character.connector.global_rotation = character.body.global_rotation

#func reset_timescales():
#	tween.ignore_engine_timescale = false
#	tween.playback_speed = 1
#	Engine.time_scale = 1


func _on_goal_entered():
	if state == states.PLAYING:
		next_complete_anim()

func _on_character_hit_floor(collision_position:Vector2, collision_normal:Vector2):
	#emit particles or whatever
	restart(1)


func _input(event):
	if event.is_action_pressed("reset_level"):
		#print(states.keys()[state])
		match state:
			states.PLAYING:
				restart(0.5)
			states.COMPLETE_3:
				restart(2)
	elif event.is_action_pressed("toggle_fullscreen"):
		OS.window_fullscreen = !OS.window_fullscreen
	elif event.is_action_pressed("toggle_fullscreen"):
		OS.window_fullscreen = false
