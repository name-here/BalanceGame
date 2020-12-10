class_name LevelController extends Node2D


# warning-ignore:unused_signal
#(it actually *is* used, but emitted with call_deferred)
signal state_changed(changed_to, changed_from)
signal on_restart(time)

enum states{#This and the rewind history shouldn't both get called "state"
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

var scene_loader:SceneLoader = null
var next_level_loaded := false

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
onready var rewind_overlay:RewindOverlay = get_node(_rewind_overlay)

# TODO: made things more error tolerant.  For example, things will very much break if tween is null <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
export(NodePath) var _tween:NodePath
onready var tween:Tween = get_node(_tween)

export(Array, float) var completion_anim_times := [1.5, 1.0]
export(float) var next_level_anim_time:float = 1

var rewind_time:float = 1#Number of seconds it takes to rewind
var rewind_time_left:float = 1#Number of seconds left for rewind

const history_max_length:int = 	1024#Is even for simpler code/math
var history_length:int = 0
var history_wait_frames:int = 1
var history_frames_waited = 0

# history_buffers stores 2 buffers, each containing Pool[Type]Arrays
# that track elements of the level state (object positions, etc.) over time
var history_buffers := [[], []]
var history_active_buffer:int = 0#Should be 0 or 1 for first or second buffer
var history_is_first_write := true
#var level_state_init:Array#Stores starting state of the level

var transition_state_buffer := Array()

#var frame_num:int = 0


# "virtual" functions that can be overridden by classes that extend LevelState
# to track more properties of the level state (additional objects' positions, etc.)
func _initialize_history_buffer(length:int) -> Array:
	# These lines work around the commented-out code below not working
	var body_positions := PoolVector2Array()#Replace Body_positions with distance from wheel to body to avoid things not lining up during interpolation <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
	body_positions.resize(length)
	var body_rotations := PoolRealArray()
	body_rotations.resize(length)
	var wheel_distances := PoolRealArray()
	wheel_distances.resize(length)
	var wheel_rotations := PoolRealArray()
	wheel_rotations.resize(length)
	return [body_positions, body_rotations, wheel_distances, wheel_rotations]
	#buffer = [body_positions, body_rotations, wheel_distances, wheel_rotations].duplicate(true)
	#var buffer_init := [body_positions, body_rotations, wheel_distancess, wheel_rotations]
	
	#buffer.resize(buffer_init.size())
	#for i in buffer_init.size():
	#	buffer[i] = buffer_init[i]
	
	#for buffer_index in buffer_array.size():
	#	buffer_array[buffer_index] = buffer_init.duplicate(true)
		#for tracker_index in buffer_array[buffer_index].size(): This doesn't work in 3.2.3, so workaround used instead.
		# Doesn't set length because buffer_array[a][b] gets value, not reference
		#	buffer_array[buffer_index][tracker_index].resize(length)
		#	print(buffer_array[buffer_index][tracker_index].size(), " should be ", length)

# TODO: had one random instance of character disappearing after tweening to the end position, and staying gone after I hit restart.  Did not happen on re-run with same code.  Investigate this <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
func _write_state(buffer:Array, index:int) -> void:
	buffer[0][index] = character.body.global_position
	buffer[1][index] = character.body.global_rotation
	buffer[2][index] = \
		character.body.global_position.distance_to(character.wheel.global_position)
	buffer[3][index] = character.wheel.global_rotation

func _read_state(buffer:Array, index:int) -> void:
	character.body.global_position = buffer[0][index]
	character.body.global_rotation = buffer[1][index]
	character.wheel.global_position = character.body.global_position + \
		Vector2(0, buffer[2][index]).rotated(character.body.global_rotation)
	character.wheel.global_rotation = buffer[3][index]

func _interpolate_state(buffer_1:Array, index_1:int, buffer_2:Array, index_2:int, weight:float) -> void:
	character.body.global_position = buffer_1[0][index_1] + \
		(buffer_2[0][index_2] - buffer_1[0][index_1]) * weight
	character.body.global_rotation = buffer_1[1][index_1] + \
		(buffer_2[1][index_2] - buffer_1[1][index_1]) * weight
	character.wheel.global_position = character.body.global_position + \
		Vector2(0, buffer_1[2][index_1] + (buffer_2[2][index_2] - buffer_1[2][index_1]) * weight)\
		.rotated(character.body.global_rotation)
	character.wheel.global_rotation = buffer_1[3][index_1] + \
		(buffer_2[3][index_2] - buffer_1[3][index_1]) * weight
	

func _copy_state(from_buffer:Array, from_index:int, to_buffer:Array, to_index:int) -> void:
	for i in to_buffer.size():
		to_buffer[i][to_index] = from_buffer[i][from_index]


func _ready() -> void:
	for time in completion_anim_times:
		assert(time > 0)
	
	if get_parent() is SceneLoader:
		scene_loader = get_parent()
	
	for _element in _fade_out:
		var element = get_node(_element)
		assert(element is CanvasItem)
		fade_out.append(element)
	
	for i in history_buffers.size():
		history_buffers[i] = _initialize_history_buffer(history_max_length)
	call_deferred("init_level_state")#Calling deferred to make sure stuff is initialized
	transition_state_buffer = _initialize_history_buffer(2)
	
	if not scene_loader:
		call_deferred("set_active")

func init_level_state() -> void:
	for i in history_buffers.size():
		_write_state(history_buffers[i], 0)

func _process(delta) -> void:
	match state:
		states.PLAYING:
			# The following code does (should do) the following:  (needed for rewind effect)
			# Start by writing character data to the history arrays.
			# When the whole array has been written, 
			# 
			history_frames_waited += 1
			if history_frames_waited >= history_wait_frames:
				history_frames_waited = 0
				
				# Write data to current buffer
				_write_state(history_buffers[history_active_buffer], history_length)
				# Copy earlier data into first half of active buffer (if not on first write)
				if !history_is_first_write:
					var write_index:int = history_length - history_max_length / 2
					_copy_state(history_buffers[int(!history_active_buffer)], write_index * 2,
						history_buffers[history_active_buffer], write_index)
				
				history_length += 1
				if history_length >= history_max_length:
					history_is_first_write = false
					history_length = history_max_length / 2
					# We're about to throw out the last data point we wrote,
					# so wait half as long to keep the delay even
					history_frames_waited = history_wait_frames
					history_wait_frames *= 2
					history_active_buffer = int(!history_active_buffer)
			
			#frame_num += 1
		
		
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
					else:
						_read_state(history_buffers[int(!history_active_buffer)], rewind_frame * 2)
						
					rewind_time_left -= delta
			else:
				rewind_time_left = 0
				history_length = 0
				history_wait_frames = 1
				history_frames_waited = 0
				history_is_first_write = true
				#frame_num = 0
				# Loads starting state (should already be done by code above)
				#_read_state(history_buffers[0], 0)
				
				set_state(states.PAUSED)
				tween.interpolate_property(rewind_overlay, "color:a", rewind_overlay.color.a, 0, 0.5)
				tween.interpolate_deferred_callback(self, 0.5, "play")
				tween.start()
		#states.COMPLETE_2:
		#	print("stage 2, ", character.body.global_position, ", ", character.wheel.global_position)


func next_complete_anim() -> int:
	if state < states.COMPLETE_1:
		set_state(states.COMPLETE_1)
	elif state < states.size() - 1:
		set_state(state + 1)
	#print("asked for stage ", states.keys()[state])
	
	match state:
		states.COMPLETE_1:
			tween.interpolate_property(Engine, "time_scale",
				Engine.time_scale, 0, completion_anim_times[0], Tween.TRANS_EXPO, Tween.EASE_OUT)
			#tween.interpolate_callback(self, completion_anim_times[0], "reset_time_scales")
			#tween.interpolate_callback(self, completion_anim_times[0], "set_physics", false)
			
			tween.interpolate_method(self, "set_fade_out_alpha",
				1, 0, completion_anim_times[0], Tween.TRANS_EXPO, Tween.EASE_OUT)
			tween.interpolate_callback(self, completion_anim_times[0], "next_complete_anim")
			tween.ignore_engine_time_scale = true
			tween.start()
		
		states.COMPLETE_2:
			#reset_time_scales()
			set_physics(false)
			tween.remove_all()
			character.update_origin()
			
			# Assumes last and 3rd-to-last elements of inactive buffer are never read
			_write_state(transition_state_buffer, 0)
			var distance = character.body.global_position.distance_to(character.wheel.global_position)
			character.wheel.global_position = end_position + Vector2(0, -96)
			character.body.global_position = character.wheel.global_position - \
			Vector2(0, distance)
			character.body.global_rotation = 0
			_write_state(transition_state_buffer, 1)
			_read_state(transition_state_buffer, 0)
			tween.interpolate_method(self, "interpolate_level_states",
				0.0, 1.0, completion_anim_times[1], Tween.TRANS_CUBIC)
			
			tween.interpolate_method(end_screen, "set_alpha",
				0, 1, completion_anim_times[1], Tween.TRANS_CUBIC)
			tween.interpolate_callback(self, completion_anim_times[1], "next_complete_anim")
			tween.start()
		states.COMPLETE_3:
			end_screen.active = true
	
	return state


func play() -> void:
	set_physics(true)
	set_state(states.PLAYING)

func pause() -> void:
	set_physics(false)
	set_state(states.PAUSED)

func stop() -> void:
	set_physics(false)
	set_state(states.INACTIVE)

func restart(time:float = 1, override:bool = false) -> void:
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
				end_screen.active = false
				tween.interpolate_method(end_screen, "set_alpha",
					1, 0, time/2, Tween.TRANS_EXPO, Tween.EASE_OUT)
				tween.interpolate_method(self, "set_fade_out_alpha",
					0, 1, time/2, Tween.TRANS_QUAD, Tween.EASE_OUT)
				
				#Assumes the last element of the inactive buffer is never read
				_write_state(transition_state_buffer, 0)
				_copy_state(history_buffers[history_active_buffer], history_length - 1,
					transition_state_buffer, 1)
				tween.interpolate_method(self, "interpolate_level_states",
					0.0, 1.0, time/2, Tween.TRANS_EXPO, Tween.EASE_IN)
				
				tween.interpolate_deferred_callback(self, time/2, "restart", time/2, true)
				tween.start()


func transition_to_next_level() -> void:
	if scene_loader == null:
		return
	
	end_screen.active = false
	set_state(states.NEXT_LEVEL_TRANSITION)
	
	_write_state(transition_state_buffer, 0)
	character.body.global_position = end_position + Vector2(0, -192)
	character.body.global_rotation = 0
	character.wheel.global_position = end_position + Vector2(0, -48)
	character.wheel.rotation = 0
	_write_state(transition_state_buffer, 1)
	_read_state(transition_state_buffer, 0)
	tween.interpolate_method(self, "interpolate_level_states",
		0.0, 1.0, next_level_anim_time, Tween.TRANS_CUBIC)
	#tween.interpolate_property(character.wheel, "rotation",
	#	character.wheel.rotation, 0, next_level_anim_time,  Tween.TRANS_CUBIC)
	
	tween.interpolate_method(end_screen, "set_alpha",
		1, 0, next_level_anim_time, Tween.TRANS_EXPO, Tween.EASE_OUT)
	
	scene_loader.connect("scene_loaded", self, "_on_next_level_loaded")
	scene_loader.load_scene_async(scene_loader.current_scene_index + 1)
	tween.interpolate_deferred_callback(self, next_level_anim_time, "_on_level_transition_complete")
	tween.start()

func _on_level_transition_complete() -> void:
	if next_level_loaded:
		#Physics2DServer.set_active(true)
		scene_loader.call_deferred("_switch_scene")

func _on_next_level_loaded() -> void:
	if tween.is_active():#if transition animations are still running
		next_level_loaded = true
	else:
		#Physics2DServer.set_active(true)
		scene_loader.call_deferred("_switch_scene")


func set_state(new_state:int) -> void:
	call_deferred("emit_signal", "state_changed", new_state, state)
	state = new_state

func set_physics(value:bool) -> void:
	Physics2DServer.set_active(value)
	character.do_torque_input = value

func set_active(value := true) -> void:
	if value:
		camera.make_current()
		character.update_mouse(get_viewport().get_mouse_position())
		play()
	else:
		stop()


func interpolate_level_states(weight:float) -> void:
	_interpolate_state(transition_state_buffer, 0,
		transition_state_buffer, 1, weight)

func set_fade_out_alpha(alpha:float) -> void:
	for element in fade_out:
		element.modulate.a = alpha

#func reset_time_scales():
#	tween.ignore_engine_time_scale = false
#	tween.playback_speed = 1
#	Engine.time_scale = 1


func _on_goal_entered() -> void:
	if state == states.PLAYING:
		call_deferred("next_complete_anim")

func _on_character_hit_floor(collision_position:Vector2, collision_normal:Vector2) -> void:
	#TODO: emit particles and play sound, or whatever<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
	restart(1)


func _input(event) -> void:
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
