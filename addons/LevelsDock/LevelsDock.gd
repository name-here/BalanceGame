tool

extends EditorPlugin


var editor_interface:EditorInterface
var dock


func _enter_tree():
	editor_interface = get_editor_interface()
	
	dock = preload("Dock.tscn").instance()
	dock.connect("open_scene", self, "open_scene")
	dock.connect("run_scene", self, "run_scene")
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_BR, dock)
	dock._enter_dock()

func _exit_tree():
	remove_control_from_docks(dock)
	dock.free()

func open_scene(scene:PackedScene):
	print("opening")
	editor_interface.edit_resource(scene)

func run_scene(scene:PackedScene):
	print("running")
	editor_interface.play_custom_scene(scene.resource_path)
