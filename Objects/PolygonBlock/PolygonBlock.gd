tool

class_name PolygonBlock extends StaticBody2D


export(PoolVector2Array) var polygon:PoolVector2Array setget set_polygon

export(NodePath) var _polygon2d:NodePath
onready var polygon2d:Polygon2D = get_node(_polygon2d)
export(NodePath) var _collision_polygon:NodePath
onready var collision_polygon:CollisionPolygon2D = get_node(_collision_polygon)


func _ready():
	_update_polygon()

func set_polygon(new_polygon:PoolVector2Array) -> void:
	polygon = new_polygon
	if polygon2d and collision_polygon:
		_update_polygon()

func _update_polygon() -> void:
	polygon2d.polygon = polygon
	collision_polygon.polygon = polygon
