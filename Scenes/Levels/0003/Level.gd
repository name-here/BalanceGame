extends LevelController


#export(NodePath) var _level_controller:NodePath
#onready var level_controller:Node = get_node(_level_controller)

#var scene_loader:SceneLoader
#var has_scene_loader := false

export(NodePath) var _start:NodePath
onready var start:Goal = get_node(_start)
export(NodePath) var _goal:NodePath
onready var goal:Goal = get_node(_goal)
export(NodePath) var _wall:NodePath
onready var wall:StaticBody2D = get_node(_wall)
export(NodePath) var _floor_:NodePath
onready var floor_:StaticBody2D = get_node(_floor_)

export(Array, NodePath) var _fade_in:Array
var fade_in:Array
#export(NodePath) var _tension_bar:NodePath
#onready var tension_bar:Control = get_node(_tension_bar)

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
		var window_size:Vector2 = _on_window_resize()
		#end_position.x = goal.global_position.x
		pause()
		
		var time:float = intro_anim_time * 2/3
		for element in fade_in:
			element.modulate.a = 0
		tween.interpolate_property(wall, "global_position:x",
			0, wall.global_position.x,
			time, Tween.TRANS_CUBIC, Tween.EASE_OUT)
		wall.global_position.x = 0
		tween.interpolate_property(start, "global_position:x",
			window_size.x/2, start.global_position.x, time, Tween.TRANS_CUBIC)
		start.global_position.x = window_size.x/2
		tween.interpolate_property(character, "global_position:x",
			start.global_position.x, character.global_position.x, time, Tween.TRANS_CUBIC)
		character.global_position.x = start.global_position.x
		tween.interpolate_property(goal, "global_position:x",
			window_size.x + 128, goal.global_position.x,
			time, Tween.TRANS_CUBIC)
		goal.global_position.x = window_size.x / 2 + goal.global_position.x / 2#Global_position seems like the wrong thing to use here<<<<<<<<<<<<
		tween.interpolate_callback(self, intro_anim_time - time, "_intro_anim_part_2", intro_anim_time/2)
		tween.start()

func _intro_anim_part_2(time:float) -> void:
	for element in fade_in:
		tween.interpolate_property(element, "modulate:a", 0, 1, time)
	tween.interpolate_callback(self, time, "_on_intro_anim_done")
	tween.start()

func _on_intro_anim_done() -> void:
	get_viewport().connect("size_changed", self, "_on_window_resize")
	play()


func _on_level_state_changed(new_state:int, last_state:int) -> void:
	match new_state:
		States.PLAYING:
			pass#camera.drag_margin_v_enabled = true
		States.COMPLETE_1:
			pass#camera.drag_margin_v_enabled = false
		States.NEXT_LEVEL_TRANSITION:
			pass

func _on_level_restarting(time:int) -> void:
	pass#camera.drag_margin_v_enabled = false


func _on_window_resize() -> Vector2:
	var new_size:Vector2 = get_viewport_rect().size
	#wall.scale.x = -new_size.x / 2
	wall.scale.y = new_size.y / 2 + 256 + 1024#Character can go 1024 pixels into the air without seeing the wall's top
	#wall.position.x = 64 - new_size.x / 2
	#floor_.scale.x = 2048 + new_size.x
	floor_.scale = Vector2(2048 + new_size.x, new_size.y / 2)
	#floor_.global_position.x = -new_size.x
	camera.limit_bottom = int(new_size.y / 2 - 256)
	return new_size
