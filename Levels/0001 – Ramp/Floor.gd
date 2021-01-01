tool

extends StaticBody2D


export(PoolVector2Array) var polygon:PoolVector2Array setget set_polygon

export(NodePath) var _polygon2d:NodePath
onready var polygon2d:Polygon2D = get_node(_polygon2d)
export(NodePath) var _collision_polygon:NodePath
onready var collision_polygon:CollisionPolygon2D = get_node(_collision_polygon)

export(NodePath) var _ramp_center:NodePath
onready var ramp_center:Node2D = get_node(_ramp_center)


func _ready() -> void:
	_update_polygon()

func set_size(width:float, height:float) -> void:
	polygon[0] = Vector2(-width / 2, height)
	polygon[1].x = -width / 2
	polygon[polygon.size()-2].x = width / 2
	polygon[polygon.size()-1] = Vector2(width / 2, height)
	_update_polygon()

func get_ramp_start_height() -> float:
	return polygon[2].y

func set_ramp_start_height(height:float) -> void:
	polygon[1].y = height
	polygon[2].y = height
	_update_polygon()

func get_ramp_end_height() -> float:
	return polygon[3].y

func set_ramp_end_height(height:float) -> void:
	polygon[3].y = height
	polygon[4].y = height
	_update_polygon()

func set_polygon(new_polygon:PoolVector2Array) -> void:
	polygon = new_polygon
	if polygon2d and collision_polygon:
		_update_polygon()
	#else:
	#	call_deferred("_update_polygon")

func _update_polygon() -> void:
	polygon2d.polygon = polygon
	collision_polygon.polygon = polygon
	_update_ramp_center()

func _update_ramp_center() -> void:
	var ramp_points := [polygon[2], polygon[3]]
	ramp_center.global_position = global_position + (ramp_points[0] + ramp_points[1]) / 2
	ramp_center.global_rotation = global_rotation + \
		asin( (ramp_points[1].y - ramp_points[0].y) / (ramp_points[1].x - ramp_points[0].x) )
