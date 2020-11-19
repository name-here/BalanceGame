extends CanvasLayer


signal torque_changed(value)
signal tension_changed(value)


func _set_torque(value):
	emit_signal("torque_changed", value)

func _set_tension(value):
	emit_signal("tension_changed", value)
