extends Node2D


export(NodePath) var _level_controller:NodePath
onready var level_controller:LevelController = get_node(_level_controller)

var scene_loader:SceneLoader
var has_scene_loader := false
var next_level_ready := false
var switch_when_ready := false

export(NodePath) var _character:NodePath
onready var character:Character = get_node(_character)

export(NodePath) var _camera:NodePath
onready var camera:Camera2D = get_node(_camera)

export(NodePath) var _goal:NodePath
onready var goal:Sprite = get_node(_goal)
export(NodePath) var _floor_:NodePath
onready var floor_:StaticBody2D = get_node(_floor_)
export(NodePath) var _wall:NodePath
onready var wall:StaticBody2D = get_node(_wall)
export(float) var wall_width:float


func _ready():
	has_scene_loader = get_parent() is SceneLoader
	if has_scene_loader:
		scene_loader = get_parent()


func set_active(value := true) -> void:
	level_controller.set_active(value)
	_on_window_resize()
	get_viewport().connect("size_changed", self, "_on_window_resize")

func start_next_level():
	if next_level_ready:
		level_controller.tween.remove_all()
		Physics2DServer.set_active(true)
		scene_loader.call_deferred("switch_scene")
	else:
		switch_when_ready = true

func _on_next_level_loaded():
	next_level_ready = true
	if switch_when_ready:
		call_deferred("start_next_level")


func _on_level_state_changed(new_state:int, last_state:int):
	match new_state:
		level_controller.states.COMPLETE_1:
			level_controller.tween.interpolate_property(camera, "global_position:x",
				camera.global_position.x, goal.global_position.x, level_controller.completion_anim_times[0], Tween.TRANS_CUBIC)
		
		level_controller.states.NEXT_LEVEL_TRANSITION:
			if has_scene_loader:
				scene_loader.connect("scene_loaded", self, "_on_next_level_loaded")
				scene_loader.load_scene_async(scene_loader.current_scene_index + 1)
				
				level_controller.tween.interpolate_property(goal, "fade_opacity",
					goal.fade_opacity, 0, level_controller.next_level_anim_time)
				level_controller.tween.interpolate_property(goal, "color",
					goal.color, Color(127), level_controller.next_level_anim_time)
				#if get_viewport_rect().size.x / 2 > camera.global_position.x - 16:
				#	level_controller.tween.interpolate_property(wall, "global_position:x",
				#		wall.global_position.x, camera.global_position.x - get_viewport_rect().size.x / 2 - wall.scale.x / 2,
				#		level_controller.next_level_anim_time, Tween.TRANS_CUBIC, Tween.EASE_IN)
				level_controller.tween.interpolate_deferred_callback(self, level_controller.next_level_anim_time, "start_next_level")
				level_controller.tween.start()

func _on_level_restart(time:float):
	level_controller.tween.interpolate_property(camera, "global_position:x",
		camera.global_position.x, 512, time/2, Tween.TRANS_CUBIC)


func _on_window_resize():#TODO: Change some of this to not use global properties!<<<<<<<<<<<<<<<<<<<<<<<<<
	var new_size:Vector2 = get_viewport_rect().size
	floor_.scale = Vector2(new_size.x * 2, new_size.y / 2 - 256)
	floor_.global_position.x = floor_.scale.x / 2 - new_size.x / 2 + 512
	#wall.scale = Vector2(new_size.x / 2 - 512 + wall_width, new_size.y / 2 + 256)
	wall.scale.y = new_size.y / 2 + 256
	#wall.global_position = Vector2(wall_width - wall.scale.x / 2, -wall.scale.y / 2)
	wall.global_position = Vector2(512 - (new_size.x - wall_width) / 2, -wall.scale.y / 2)
	#goal.global_position.x = 1024 - 128 - 32
	
	level_controller.end_position.x = goal.global_position.x
	#if level_controller.state < level_controller.states.COMPLETE_1:
	#	camera.global_position.x = 512#new_size.x / 2
	if level_controller.state > level_controller.states.COMPLETE_1:
		camera.global_position.x = goal.global_position.x
		character.global_position.x = goal.global_position.x
