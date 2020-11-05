extends Control

signal torque_changed(value)
signal tension_changed(value)


func _process(_delta):#this seems inefficient, but I don't think there's an _on_resized signal/function/etc.
	update_size()

func update_size():
	rect_size = get_viewport_rect().size
	rect_position = -get_viewport_rect().size / 2

func _set_torque(value):
	emit_signal("torque_changed", value)

func _set_tension(value):
	emit_signal("tension_changed", value)
