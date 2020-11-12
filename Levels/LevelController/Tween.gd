extends Tween

export(bool) var ignore_engine_timescale := false


# This code makes tweening Engine.time_scale work.
# I wish there was an easier and less convoluted way,
# but this code comes after hours of trial and error and brute-force testing,
# making sure it doesn't randomly fail.
# It seems like this code has to be here,
# though it would make more sense in LevelController.
func _physics_process(_delta):
	if ignore_engine_timescale:
		if Engine.time_scale > 0:
			playback_speed = 1 / Engine.time_scale
		else:
			remove(Engine, "time_scale")
			ignore_engine_timescale = false
			playback_speed = 1
			Engine.time_scale = 1
