extends HBoxContainer


export(NodePath) var _left_bar:NodePath
onready var left_bar:ProgressBar = get_node(_left_bar)
export(NodePath) var _right_bar:NodePath
onready var right_bar:ProgressBar = get_node(_right_bar)

export(float, -1, 1) var value:float = 0 setget _set_value

func _ready():
	_set_value(value)

func _set_value(new_value:float):
	value = new_value
	if right_bar:
		left_bar.value = new_value
	if left_bar:
		right_bar.value = new_value
