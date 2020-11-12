extends CanvasLayer


signal torque_changed(value)
signal tension_changed(value)

export(NodePath) var _frame:NodePath
onready var frame:Control = get_node(_frame)


func _ready():
	update_size()
	get_viewport().connect("size_changed", self, "update_size")

func update_size():
	frame.rect_size = frame.get_viewport_rect().size

func _set_torque(value):
	emit_signal("torque_changed", value)

func _set_tension(value):
	emit_signal("tension_changed", value)
