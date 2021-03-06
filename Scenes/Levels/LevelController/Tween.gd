class_name BetterTween extends Tween

export(bool) var ignore_engine_time_scale := false


func _init():
	playback_process_mode = Tween.TWEEN_PROCESS_PHYSICS


# This code makes tweening Engine.time_scale work.
# I wish there was an easier and less convoluted way,
# but this code comes after hours of trial and error and brute-force testing,
# making sure it doesn't randomly fail.
# It seems like this code has to be here,
# though it would make more sense in LevelController.
func _physics_process(_delta) -> void:
	if ignore_engine_time_scale:
		if Engine.time_scale > 0:
			playback_speed = 1 / Engine.time_scale
		else:
			remove(Engine, "time_scale")
			ignore_engine_time_scale = false
			playback_speed = 1
			Engine.time_scale = 1
