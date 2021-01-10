extends LevelController


export(NodePath) var _wall:NodePath
onready var wall:StaticBody2D = get_node(_wall)
export(NodePath) var _floor_left:NodePath
onready var floor_left:PolygonBlock = get_node(_floor_left)
export(NodePath) var _floor_right:NodePath
onready var floor_right:StaticBody2D = get_node(_floor_right)
export(NodePath) var _death_pit:NodePath
onready var death_pit:DeathPit = get_node(_death_pit)



func set_active(value := true) -> void:
	.set_active(value)
	if value:
		_on_window_resize()
		#pause()
		
		get_viewport().connect("size_changed", self, "_on_window_resize")


func _on_window_resize() -> void:
	var new_size:Vector2 = get_viewport_rect().size
	wall.scale.y = new_size.y
	floor_left.set_height(new_size.y / 2)
	floor_right.scale = Vector2(new_size.x + 448, new_size.y / 2)
	death_pit.scale.y = (new_size.y / 2 - 255) / 64
	camera.limit_bottom = int(new_size.y / 2 - 256)
