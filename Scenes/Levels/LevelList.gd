tool

class_name LevelList extends Resource


# The ignore setgets make saving the resource not work
export(Dictionary) var levels_dict := {}# setget _ignore
export(Array) var levels_ordered := []# setget _ignore

#class LevelListEntry extends Reference:
#	var level_data:LevelData
#	var is_active:bool
#	
#	func _init(set_level_data := LevelData.new(), set_is_active := true):
#		level_data = set_level_data
#		is_active = set_is_active


func save() -> void:
	ResourceSaver.save(resource_path, self)

func add_level(level_data:LevelData, index:int = -1) -> void:
	if not levels_dict.has(level_data.name):
		if index >= 0 and index < levels_ordered.size():
			levels_ordered.insert(index, level_data)
			levels_dict[level_data.name] = levels_ordered[index]
		else:
			levels_ordered.append(level_data)
			levels_dict[level_data.name] = levels_ordered.back()
		save()

func remove_level(level_name:String) -> void:
	if levels_dict.has(level_name):
		levels_ordered.erase(levels_dict[level_name])
		levels_dict.erase(level_name)
		save()

func move_level(from_index:int, to_index:int) -> void:
	if from_index < 0 or from_index >= levels_ordered.size() or \
			to_index < 0 or to_index >= levels_ordered.size():
		push_error("move index(es) out of bounds")
	else:
		var moving:LevelData = levels_ordered[from_index]
		levels_ordered.remove(from_index)
		levels_ordered.insert(to_index, moving)
		save()

func clear_levels() -> void:
	levels_dict = {}
	levels_ordered = []

#func _ignore(_data) -> void:
#	push_error("Thou shalt not write to this directly.  Use add_level(), remove_level(), move_level(), and clear_levels() instead.")
#	pass
