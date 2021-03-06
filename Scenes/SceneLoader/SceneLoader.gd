class_name SceneLoader extends Node


signal progress_changed(percent)
signal scene_loaded

export(String) var level_list_path:String
onready var level_list:LevelList = load(level_list_path)
export(int) var starting_scene:int = 0#scene loaded on ready, set to -1 to not load anything
var current_scene_index:int = -1
var loading_scene_index:int#index of the scene to be loaded
var current_scene:Node
var loading_scene:Node
var is_loading := false

var progress:float


func _ready() -> void:
	var load_index:int = get_next_valid_index(0)
	if load_index >= 0:
		load_scene(load_index)
	else:
		push_error("Error: No enabled levels found.")

func get_next_valid_index(current_index:int) -> int:
	if current_index < level_list.levels_ordered.size():
		while not level_list.levels_ordered[current_index].is_active:
			current_index += 1
			if current_index >= level_list.levels_ordered.size():
				return -1
		return current_index
	else:
		return -1

func load_scene(index:int) -> void:
	if index >= 0 and index < level_list.levels_ordered.size():
		loading_scene_index = index
		var scene:PackedScene = load(
			(level_list.levels_ordered[index] as LevelData).scene_path )
		if scene != null:
			loading_scene = scene.instance()
			call_deferred("_switch_scene")
		else:
			push_error("Error: Scene for level \"%s\" is null." % \
				level_list.levels_ordered[index].level_data.name)
	else:
		push_error("Error: Invalid index %d given for loading scene.  There are only %d scenes." % \
			[index, level_list.levels_ordered.size()])

func load_next_level() -> void:
	var load_index:int = get_next_valid_index(current_scene_index+1)
	if load_index >= 0:
		load_scene_async(load_index)
	else:
		push_error("Error: There are no enabled levels after the current one.")

func load_scene_async(index:int) -> void:
	if index >= 0 and index < level_list.levels_ordered.size():
		is_loading = true
		loading_scene_index = index
		var request := AsyncLoader.LoadRequest.new(
				level_list.levels_ordered[index].scene_path, "PackedScene",
				funcref(self, "_scene_loaded"), funcref(self, "_update_progress") )
		AsyncLoader.load(request)
	else:
		push_error("Error: Invalid index %d given for loading scene.  There are only %d scenes." % \
			[index, level_list.levels_ordered.size()])

#Switches to loading_scene 
func _switch_scene() -> void:#must always be called deferred, or probably won't work
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

func _update_progress(new_progress:float) -> void:
	progress = new_progress
	emit_signal("progress_changed", new_progress)

# This function gets called in the loader thread instead of the main thread,
# allowing the scene to be instanced without potentially freezing the main thread.
func _scene_loaded(scene) -> void:
	if scene != null:
		call_deferred("_update_loading_scene", scene.instance())
	else:
		call_deferred("push_error", "Error: Could not load scene from specified path \"%s\"." % \
			level_list.levels_ordered[loading_scene_index].level_data.scene.resource_path)

func _update_loading_scene(scene_instance) -> void:#should only ever be called deferred
	loading_scene = scene_instance
	#_switch_scene()
	#emit_signal("progress_changed", 100.0)#_update_progress is already called with 100% on completion
	emit_signal("scene_loaded")
