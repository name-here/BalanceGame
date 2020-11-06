extends Tween

export(bool) var ignore_engine_timescale := false


func _physics_process(delta):
	#print("process")
	if ignore_engine_timescale:
		if Engine.time_scale > 0:
			playback_speed = 1 / Engine.time_scale
		else:
			seek(get_runtime())
