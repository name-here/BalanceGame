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
	NEXT_LEVEL_TRANSITION
}
var state:int = states.INACTIVE setget set_state

export(NodePath) var _character:NodePath
onready var character:Character = get_node(_character)
export(NodePath) var _camera:NodePath
onready var camera:Camera2D = get_node(_camera)

export(Array, NodePath) var _fade_out:Array
var fade_out:Array

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

const history_max_length:int = 	1024#Is even for simpler code/math
var history_length:int = 0
var history_wait_frames:int = 1
var history_frames_waited = 0

# history_buffers stores 2 buffers, each containing Pool[Type]Arrays
# that track elements of the level state (object positions, etc.) over time
var history_buffers := [null, null]
var history_active_buffer:int = 0#Should be 0 or 1 for first or second buffer
var history_is_first_write := true
#var level_state_init:Array#Stores starting state of the level

var test_data := [null, null]
var frame_num:int = 0


# "virtual" functions that can be overridden by classes that extend LevelState
# to track more properties of the level state (additional objects' positions, etc.)
func _initialize_history_buffers(buffer_array:Array, length:int):
	var body_positions:PoolVector2Array#These lines work around the commented-out code below not working
	body_positions.resize(length)
	var body_rotations:PoolRealArray
	body_rotations.resize(length)
	var wheel_positions:PoolVector2Array
	wheel_positions.resize(length)
	var wheel_rotations:PoolRealArray
	wheel_rotations.resize(length)
	var buffer_init := [body_positions, body_rotations, wheel_positions, wheel_rotations]
	var test_data_init:PoolIntArray
	test_data_init.resize(length)
	for i in test_data_init.size():
		test_data_init[i] = i
	for buffer_index in buffer_array.size():
		test_data[buffer_index] = test_data_init
		buffer_array[buffer_index] = buffer_init.duplicate(true)
		#for tracker_index in buffer_array[buffer_index].size(): This doesn't work in 3.2.3, so workaround used instead.
		# Doesn't set length because buffer_array[a][b] gets value, not reference
		#	buffer_array[buffer_index][tracker_index].resize(length)
		#	print(buffer_array[buffer_index][tracker_index].size(), " should be ", length)

#func _set_initial_state(state_array:Array):
#	state_array = [
#		character.body.global_position,
#		character.body.global_rotation,
#		character.wheel.global_position,
#		character.wheel.global_rotation,
#	]

func _write_state(buffer:Array, index:int):
	buffer[0][index] = character.body.global_position
	buffer[1][index] = character.body.global_rotation
	buffer[2][index] = character.wheel.global_position
	buffer[3][index] = character.wheel.global_rotation

func _read_state(buffer:Array, index:int):
	character.body.global_position = buffer[0][index]
	character.body.global_rotation = buffer[1][index]
	character.wheel.global_position = buffer[2][index]
	character.wheel.global_rotation = buffer[3][index]

func _copy_state(from_buffer:Array, from_index:int, to_buffer:Array, to_index:int):
	for i in to_buffer.size():
		to_buffer[i][to_index] = from_buffer[i][from_index]


func _ready():
	for time in completion_anim_times:
		assert(time > 0)
	
	for _element in _fade_out:
		var element = get_node(_element)
		assert(element is CanvasItem)
		fade_out.append(element)
	
	_initialize_history_buffers(history_buffers, history_max_length)
	#_set_initial_state(level_state_init)
	for buffer in history_buffers:
		_write_state(buffer, 0)
	#level_state_init.resize(history_buffers[0].size())
	#This is hugely inefficient (copies whole array, then immediately resizes it)
	#for i in history_buffers[0].size():
	#	level_state_init[i] = history_buffers[0][i]
	#	level_state_init[i].resize(1)
	#_write_state(level_state_init, 0)
	
	#for array in test_data:
	#	for elem in array:
	#		elem = -1


func _process(delta):
	match state:
		states.PLAYING:
			# The following code does (should do) the following:  (needed for rewind effect)
			# Start by writing character data to the history arrays.
			# When the whole array has been written, 
			# 
			history_frames_waited += 1
			if history_frames_waited >= history_wait_frames:#TODO: MATH BELOW HERE NOT FINISHED! <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
				history_frames_waited = 0
				var index:int
				
				# Write data to current buffer
				_write_state(history_buffers[history_active_buffer], history_length)
				test_data[history_active_buffer][history_length] = frame_num
				print("wrote ", frame_num, " to ", history_length, " in buffer ", history_active_buffer)
				# Copy past data into first half of active buffer (if not on first write)
				if !history_is_first_write:
					var write_index:int = history_length - history_max_length / 2
					_copy_state(history_buffers[int(!history_active_buffer)], write_index * 2,
						history_buffers[history_active_buffer], write_index)
					test_data[history_active_buffer][write_index] = test_data[int(!history_active_buffer)][write_index*2]
					print("copied ",test_data[history_active_buffer][write_index]," from index ",write_index*2," in buffer ",history_active_buffer," to index ",write_index," in buffer ",int(!history_active_buffer))
				#print(frame_num, " over ", test_data[index], " on ", history_length, "*", history_wait_frames)
				#test_data[index] = frame_num
				
				history_length += 1
				if history_length >= history_max_length:
					history_is_first_write = false
					history_length = history_max_length / 2
					# We're about to throw out the last data point we wrote,
					# so wait half as long to keep the delay even
					history_frames_waited = history_wait_frames
					history_wait_frames *= 2
					history_active_buffer = int(!history_active_buffer)
					#print(test_data)
			
			frame_num += 1
		
		
		states.RESTARTING:
			if history_length > 0 and rewind_time_left >= 0:
				var rewind_frame := int( (history_length - 1) * rewind_time_left / rewind_time )
				if rewind_frame < 0:
					push_error( str("positions: ", history_length-1, ", time: ", rewind_time_left, ", length: ", rewind_time, ", frame: ", rewind_frame) )
					assert(rewind_frame >= 0)
				else:
					# This plays back the data created above (split between
					# 2 buffers) in the correct reverse order
					if history_is_first_write or rewind_frame >= history_max_length / 2:
						_read_state(history_buffers[history_active_buffer], rewind_frame)
						print("got ", test_data[history_active_buffer][rewind_frame], " for ", rewind_frame, " in buffer ", history_active_buffer)
					else:
						_read_state(history_buffers[int(!history_active_buffer)], rewind_frame * 2)
						print("got ", test_data[int(!history_active_buffer)][rewind_frame*2], " for ", rewind_frame, " in buffer ", int(!history_active_buffer))
						
					#print("got ", test_data[index], " for ", rewind_frame)
					rewind_time_left -= delta
			else:
				rewind_time_left = 0
				history_length = 0
				history_wait_frames = 1#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
				history_frames_waited = 0
				history_is_first_write = true
				#for i in test_data.size():
				#	test_data[i] = -1
				frame_num = 0
				#body_positions = body_positions_init<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
				#body_rotations = body_rotations_init
				#wheel_positions = wheel_positions_init
				#wheel_rotations = wheel_rotations_init
				#if body_positions.size() > 0:
				#	character.body.global_position = body_positions[0]
				#	character.body.global_rotation = body_rotations[0]
				#	character.wheel.global_position = wheel_positions[0]
				#	character.wheel.global_rotation = wheel_rotations[0]
				#	print("got ", test_data[0], " for 0")
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
			tween.interpolate_property(Engine, "time_scale",
				Engine.time_scale, 0, completion_anim_times[0], Tween.TRANS_EXPO, Tween.EASE_OUT)
			#tween.interpolate_callback(self, completion_anim_times[0], "reset_timescales")
			#tween.interpolate_callback(self, completion_anim_times[0], "set_physics", false)
			
			tween.interpolate_method(self, "set_fade_out_alpha",
				1, 0, completion_anim_times[0], Tween.TRANS_EXPO, Tween.EASE_OUT)
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
				0, 1, completion_anim_times[1], Tween.TRANS_CUBIC)
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
		print(test_data[0], "\n", test_data[1])
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
				tween.interpolate_method(self, "set_fade_out_alpha",
					0, 1, time/2, Tween.TRANS_QUAD, Tween.EASE_OUT)
				#tween.interpolate_method(self, "set_character_state",<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
				#	Color( character.wheel.global_position.x, character.wheel.global_position.y,
				#		character.body.global_rotation, character.body.global_position.distance_to(character.wheel.global_position) ),
				#	Color( body_positions[last].x, body_positions[last].y,
				#		body_rotations[last], body_positions[last].distance_to(wheel_positions[last]) ),
				#	time/2, Tween.TRANS_EXPO, Tween.EASE_IN)
				tween.interpolate_deferred_callback(self, time/2, "restart", time/2, true)
				tween.start()

func go_to_next_level():
	end_screen.active = false
	set_state(states.NEXT_LEVEL_TRANSITION)
	tween.interpolate_method(self, "set_character_state",
		Color( character.wheel.global_position.x, character.wheel.global_position.y,
			character.body.global_rotation, character.body.global_position.distance_to(character.wheel.global_position) ),
		Color(end_position.x, -48, 0, 144),
		next_level_anim_time, Tween.TRANS_CUBIC)
	tween.interpolate_property(character.wheel, "rotation",
		character.wheel.rotation, 0, next_level_anim_time,  Tween.TRANS_CUBIC)
	tween.interpolate_method(end_screen, "set_alpha",
		1, 0, next_level_anim_time, Tween.TRANS_EXPO, Tween.EASE_OUT)
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

func set_fade_out_alpha(alpha:float):
	for element in fade_out:
		element.modulate.a = alpha

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
