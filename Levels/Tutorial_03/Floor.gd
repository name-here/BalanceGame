tool

extends StaticBody2D


export(NodePath) var _polygon:NodePath
onready var polygon:Polygon2D = get_node(_polygon)
export(NodePath) var _collision_polygon:NodePath
onready var collision_polygon:CollisionPolygon2D = get_node(_collision_polygon)

export(NodePath) var _slope_center:NodePath
onready var slope_center:Node2D = get_node(_slope_center)


func _ready() -> void:
	update_polygon()

func set_size(width, height) -> void:
	polygon.polygon[0] = Vector2(-width / 2, height)
	polygon.polygon[1].x = -width / 2
	polygon.polygon[polygon.polygon.size()-2].x = width / 2
	polygon.polygon[polygon.polygon.size()-1] = Vector2(width / 2, height)
	update_polygon()

func update_polygon() -> void:
	collision_polygon.polygon = polygon.polygon
	_set_slope_center()

func _set_slope_center() -> void:
	var slope_points := [polygon.polygon[2], polygon.polygon[3]]
	slope_center.global_position = polygon.global_position + (slope_points[0] + slope_points[1]) / 2
	slope_center.global_rotation = polygon.global_rotation + \
		asin( (slope_points[1].y - slope_points[0].y) / (slope_points[1].x - slope_points[0].x) )
	print(slope_center.rotation)
