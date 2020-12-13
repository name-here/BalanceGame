extends LevelController


#export(NodePath) var _level_controller:NodePath
#onready var level_controller:Node = get_node(_level_controller)

#var scene_loader:SceneLoader
#var has_scene_loader := false

export(NodePath) var _goal:NodePath
onready var goal:Goal = get_node(_goal)
export(NodePath) var _left_wall:NodePath
onready var left_wall:StaticBody2D = get_node(_left_wall)
export(NodePath) var _floor_:NodePath
onready var floor_:StaticBody2D = get_node(_floor_)

export(Array, NodePath) var _fade_in:Array
var fade_in:Array
export(NodePath) var _tension_bar:NodePath
onready var tension_bar:Control = get_node(_tension_bar)

export(float) var intro_anim_time:float = 1.5



func _ready() -> void:
	pause()
	
	#has_scene_loader = get_parent() is SceneLoader
	#if has_scene_loader:
	#	scene_loader = get_parent()
	
	for _element in _fade_in:
		var element = get_node(_element)
		assert(element is CanvasItem)
		fade_in.append(element)


func set_active(value := true) -> void:
	.set_active(value)
	if value:
		end_position.x = goal.global_position.x
		_on_window_resize()
		pause()
		
		for element in fade_in:
			element.modulate.a = 0
			tween.interpolate_property(element, "modulate:a", 0, 1, intro_anim_time)
		left_wall.global_position.x -= 64#Change to use wall's transform?<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
		tween.interpolate_property(left_wall, "global_position:x",
			left_wall.global_position.x, left_wall.global_position.x + 64,
			intro_anim_time, Tween.TRANS_CUBIC, Tween.EASE_OUT)
		tween.interpolate_callback(self, intro_anim_time, "_on_intro_anim_done")
		tween.start()

func _on_intro_anim_done() -> void:
	get_viewport().connect("size_changed", self, "_on_window_resize")
	play()


func _on_level_state_changed(new_state:int, last_state:int) -> void:
	match new_state:
		states.NEXT_LEVEL_TRANSITION:
			pass

func restart_game() -> void:
	if scene_loader:
		scene_loader.load_scene(0)

func _on_level_restarting(time:int) -> void:
	pass


func _on_window_resize() -> void:
	var new_size:Vector2 = get_viewport_rect().size
	left_wall.scale.x = new_size.x / 2
	left_wall.scale.y = new_size.y / 2 + 256 + 1024#Character can go 1024 pixels into the air without seeing the wall's top
	left_wall.position = Vector2(64 - left_wall.scale.x / 2 - new_size.x / 2, -left_wall.scale.y / 2)
	floor_.scale = Vector2(2048 + new_size.x * 2, new_size.y / 2)
