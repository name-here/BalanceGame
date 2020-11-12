extends Node


signal progress_changed(percent)
signal scene_loaded

export(String) var scenes_folder:String
export(Array, String) var scenes:Array
export(int) var starting_scene:int = 0#scene loaded on ready, set to -1 to not load anything
var load_index:int#index of the scene to be loaded
var current_scene:Node
var loading_scene:Node

var progress:float


func _ready():
	if not scenes_folder.ends_with("/"):
		scenes_folder += "/"
	load_scene(starting_scene)

func load_scene(index:int):
	if index >= 0 and index < scenes.size():
		var packed_scene:PackedScene = ResourceLoader.load(scenes_folder+"/"+scenes[index]+"/"+scenes[index]+".tscn")
		if packed_scene != null:
			loading_scene = packed_scene.instance()
			switch_scene()
		else:
			push_error("Error: Could not load scene from specified path \"%s\"."%scenes[starting_scene])
	else:
		push_error("Error: Invalid index %i given for loading scene.  There are only %i scenes."%index%scenes.size())

func load_scene_async(index:int):
	var request := AsyncLoader.LoadRequest.new(
			scenes[index], "PackedScene",
			funcref(self, "_scene_loaded"), funcref(self, "_update_progress") )
	AsyncLoader.load(request)

#Switches to loading_scene 
func switch_scene():
	assert(loading_scene != null)
	if loading_scene != null:
		add_child(loading_scene)
		if loading_scene.has_method("set_active"):
			loading_scene.set_active(true)
		if current_scene != null:
			current_scene.free()
		current_scene = loading_scene
		loading_scene = null

func _update_progress(new_progress:float):
	progress = new_progress
	emit_signal("progress_changed", new_progress)

func _scene_loaded(scene):
	loading_scene = scene.instance()
	emit_signal("scene_loaded")
	emit_signal("progress_changed", 100.0)
	call_deferred("switch_scene")
