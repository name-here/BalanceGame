extends Sprite


signal goal_entered

export(NodePath) var _character:NodePath
onready var character:Character = get_node(_character)

func _process(_delta):
	var goal_position:float = global_position.x - global_scale.y / 2
	if character.global_position.x > goal_position:
		emit_signal("goal_entered")
