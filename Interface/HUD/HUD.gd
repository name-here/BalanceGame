extends Control

signal torque_changed(value)
signal tension_changed(value)


func _ready():
	update_size()
	get_viewport().connect("size_changed", self, "update_size")

func update_size():
	rect_size = get_viewport_rect().size
	rect_position = -get_viewport_rect().size / 2

func _set_torque(value):
	emit_signal("torque_changed", value)

func _set_tension(value):
	emit_signal("tension_changed", value)