tool

class_name LevelList extends Resource


export(Dictionary) var levels_dict := {} setget _ignore
export(Array) var levels_ordered := [] setget _ignore

class LevelListEntry extends Resource:
	var level_data:LevelData
	var is_active:bool
	
	func _init(set_level_data := LevelData.new(), set_is_active := true):
		level_data = set_level_data
		is_active = set_is_active


func add_level(level_data:LevelData, index:int = -1):
	if not levels_dict.has(level_data.name):
		if index >= 0 and index < levels_ordered.size():
			levels_ordered.insert(index, LevelListEntry.new(level_data))
			levels_dict[level_data.name] = levels_ordered[index]
		else:
			levels_ordered.append(LevelListEntry.new(level_data))
			levels_dict[level_data.name] = levels_ordered.back()

func remove_level(level_name:String):
	if levels_dict.has(level_name):
		levels_ordered.erase(levels_dict[level_name])
		levels_dict.erase(level_name)

func move_level(from_index:int, to_index:int):
	if from_index < 0 or from_index >= levels_ordered.size() or \
			to_index < 0 or to_index >= levels_ordered.size():
		push_error("move index(es) out of bounds")
	var moving:LevelListEntry = levels_ordered[from_index]
	levels_ordered.remove(from_index)
	levels_ordered.insert(to_index, moving)

func _ignore(_data):
	pass
