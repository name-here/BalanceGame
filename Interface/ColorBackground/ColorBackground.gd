extends ColorRect

onready var target:Node2D = get_parent()
onready var viewport:= get_viewport()


func _ready():
	set_visible(true)
	update_size()
	viewport.connect("size_changed", self, "update_size")
	call_deferred("_reparent")

func _process(_delta):
	rect_global_position = target.global_position - get_viewport_rect().size / 2

func update_size():
	rect_size = get_viewport_rect().size

func _reparent():
	target.remove_child(self)
	viewport.add_child_below_node(viewport.get_children()[0], self)
	update_size()
