extends CPUParticles2D

func _process(delta):
	if Engine.time_scale > 0:
		anim_speed = 1 / Engine.time_scale
