tool

extends Control


signal open_scene(scene)
signal run_scene(scene)


export(NodePath) var _tree:NodePath
onready var tree:Tree = get_node(_tree)
#export(PackedScene) var list_item:PackedScene
onready var tree_root:TreeItem = tree.create_item()

export(Texture) var edit_icon:Texture
export(Texture) var play_icon:Texture
export(Texture) var level_default_icon:Texture

export(String) var levels_folder:String
export(String) var level_list_path:String
onready var level_list:LevelList = load(level_list_path)


func _ready() -> void:
	#Should NOT end up in levels (for now, anyways)
	assert(Engine.editor_hint)

func _enter_dock() -> void:
	tree.connect("item_edited", self, "_on_item_edited")
	tree.connect("item_moved", self, "_on_item_moved")
	tree.connect("button_pressed", self, "_on_button_pressed")
	tree.set_column_min_width(0, 48)
	tree.set_column_expand(0, false)
	
	for entry in level_list.levels_ordered:
		add_item(entry)
	update_list()


func update_list() -> void:#read folder and update list
	var dir := Directory.new()
	if dir.open(levels_folder) != OK:
		push_error("Error accessing level path %s"%levels_folder)
	else:
		dir.list_dir_begin(true, true)
		var file_path = dir.get_next()
		while file_path:
			var data_path:String = str(file_path+"/Data.tres")
			if dir.current_is_dir() and dir.file_exists(data_path):
				var level_data:LevelData = load(dir.get_current_dir()+data_path)
				if not level_list.levels_dict.has(level_data.name):
					level_list.add_level(level_data)
					add_item(level_data)
			file_path = dir.get_next()


func add_item(level_data:LevelData) -> void:
	var item := tree.create_item(tree_root)
	#var item:LevelListItem = list_item.instance()
	item.set_meta("level_data", level_data)
	var previous := item.get_prev()
	if previous:
		item.set_meta("index", previous.get_meta("index") + 1)
	else:
		item.set_meta("index", 0)
	item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
	item.set_checked(0, level_data.is_active)
	item.set_tooltip(0, "Include in / Exclude from Game")
	if level_data.icon:
		item.set_icon(1, level_data.icon)
	else:
		item.set_icon(1, level_default_icon)
	item.set_text(1, level_data.name)
	item.set_tooltip(1, level_data.scene_path)
	item.add_button(1, edit_icon, -1, false,
		str("Edit Level (", level_data.scene_path, ")"))
	item.add_button(1, play_icon, -1, false,
		str("Play Level (", level_data.scene_path, ")"))
	for column in tree.columns:
		item.set_editable(column, true)


func _on_item_edited() -> void:
	var item:TreeItem = tree.get_edited()
	var data:LevelData = item.get_meta("level_data")
	data.name = item.get_text(1)
	data.is_active = item.is_checked(0)

func _on_item_moved(from_index:int, to_index:int) -> void:
	level_list.move_level(from_index, to_index)

func _on_button_pressed(item:TreeItem, column:int, id:int) -> void:
	match id:
		0:
			emit_signal("open_scene", (item.get_meta("level_data") as LevelData).scene_path)
		1:
			emit_signal("run_scene", (item.get_meta("level_data") as LevelData).scene_path)
