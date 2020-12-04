class_name SceneLoader extends Node


signal progress_changed(percent)
signal scene_loaded

export(String) var scenes_folder:String
export(Array, String) var scenes:Array
export(int) var starting_scene:int = 0#scene loaded on ready, set to -1 to not load anything
var current_scene_index:int = -1
var loading_scene_index:int#index of the scene to be loaded
var current_scene:Node
var loading_scene:Node
var is_loading := false

var progress:float


func _ready():
	if not scenes_folder.ends_with("/"):
		scenes_folder += "/"
	load_scene(starting_scene)

func load_scene(index:int):
	loading_scene_index = index
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
	is_loading = true
	loading_scene_index = index
	var request := AsyncLoader.LoadRequest.new(
			scenes_folder+"/"+scenes[index]+"/"+scenes[index]+".tscn", "PackedScene",
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
		current_scene_index = loading_scene_index
		loading_scene = null

func _update_progress(new_progress:float):
	progress = new_progress
	emit_signal("progress_changed", new_progress)

# This function gets called in the loader thread instead of the main thread,
# allowing the scene to be instanced without potentially freezing the main thread.
func _scene_loaded(scene):
	if scene != null:
		call_deferred("_update_scene", scene.instance())
	else:
		push_error("Error: Could not load scene from specified path \"%s\"."%scenes[loading_scene_index])

func _update_loading_scene(scene_instance):#should only ever be called deferred
	loading_scene = scene_instance
	#switch_scene()
	#emit_signal("progress_changed", 100.0)#_update_progress is already called with 100% on completion
	emit_signal("scene_loaded")
