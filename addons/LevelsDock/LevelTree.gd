tool

extends Tree


signal item_moved(from_index, to_index)


func get_drag_data(position):
	drop_mode_flags = DROP_MODE_INBETWEEN
	var selected = get_selected()
	
	var preview:Control
	var level_icon = selected.get_icon(0)
	if level_icon:
		preview = HBoxContainer.new()
		preview.add_constant_override("separation", 0)
		var icon := TextureRect.new()
		icon.texture = level_icon
		preview.add_child(icon)
		var label := Label.new()
		label.text = selected.get_text(0)
		preview.add_child(label)
		preview.rect_size = Vector2(0, 0)
	else:
		preview = Label.new()
		preview.text = selected.get_text(0)
	set_drag_preview(preview)
	
	return selected

func can_drop_data(position, data):
	return data is TreeItem

func drop_data(position, data):
	var destination:TreeItem = get_item_at_position(position)
	
	var offset:int = get_drop_section_at_position(position)
	if offset == 1:
		var target := destination.get_next()
		if target:
			destination = target
		else:#moving to the end of the list
			move_tree_item(data, -1)
			return
	
	if destination == data or destination.get_prev() == data:
		return
	
	#var destination_index:int = destination.get_meta("index")
	#var target := get_root().get_children()
	#while target != destination and target:
	#	if not target == data:
	#		destination_index += 1
	#	target = target.get_next()
	move_tree_item(data, destination.get_meta("index"))


func move_tree_item(item:TreeItem, to_index:int = -1):
	var from_index:int = item.get_meta("index")
	if from_index <= to_index:
		to_index -= 1
	
	var parent := item.get_parent()
	var meta_dict := {}
	for elem in item.get_meta_list():
		meta_dict[elem] = item.get_meta(elem)
	var checked := item.is_checked(0)
	var checkbox_tooltip := item.get_tooltip(0)
	var icon := item.get_icon(1)
	var text := item.get_text(1)
	var tooltip := item.get_tooltip(1)
	var buttons := []
	var button_tooltips := []
	for i in item.get_button_count(1):
		buttons.append(item.get_button(1, i))
		button_tooltips.append(item.get_button_tooltip(1, i))
	
	var item_count:int = 0
	var target:= get_root().get_children()
	while target:
		var index:int = target.get_meta("index")
		var offset:int = 0
		if index > from_index and (index <= to_index or to_index == -1):
			offset = -1
		elif index >= to_index and (index < from_index and not to_index == -1):
			offset = 1
		target.set_meta("index", index + offset)
		item_count += 1
		target = target.get_next()
	
	if to_index == -1:
		to_index = item_count - 1
	
	item.free()
	
	var new_item = create_item(parent, to_index)
	for elem in meta_dict.keys():
		new_item.set_meta(elem, meta_dict[elem])
	new_item.set_meta("index", to_index)
	new_item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
	new_item.set_checked(0, checked)
	new_item.set_tooltip(0, checkbox_tooltip)
	new_item.set_icon(1, icon)
	new_item.set_text(1, text)
	new_item.set_tooltip(1, tooltip)
	for i in buttons.size():
		new_item.add_button(1, buttons[i], -1, false, button_tooltips[i])
	for column in columns:
		new_item.set_editable(column, true)
	
	#var t := get_root().get_children()
	#while t:
	#	print(t.get_meta("index"))
	#	t = t.get_next()
	
	emit_signal("item_moved", from_index, to_index)
