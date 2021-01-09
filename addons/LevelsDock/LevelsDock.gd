tool

extends EditorPlugin


var editor_interface:EditorInterface
var dock


func _enter_tree() -> void:
	editor_interface = get_editor_interface()
	
	dock = preload("Dock.tscn").instance()
	dock.connect("open_scene", self, "open_scene")
	dock.connect("run_scene", self, "run_scene")
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_BR, dock)
	dock._enter_dock()

func _exit_tree() -> void:
	remove_control_from_docks(dock)
	dock.free()

func open_scene(scene_path:String) -> void:
	editor_interface.open_scene_from_path(scene_path)#opens the scene for editing
	#editor_interface.edit_resource(scene)#opens it in the inspector
	
	#TODO: Add code here to set the tab title to the level name (if possible)

func run_scene(scene_path:String) -> void:
	editor_interface.play_custom_scene(scene_path)
