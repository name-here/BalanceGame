tool

extends PolygonBlock


func get_height() -> float:
	return -polygon[3].y

func set_height(new_height:float) -> void:
	polygon[3].y = -new_height
	_update_polygon()

func get_width() -> float:
	return polygon[polygon.size()-2].x

func set_width(new_width:float) -> void:
	polygon[polygon.size()-1].x = new_width
	polygon[polygon.size()-2].x = new_width
	_update_polygon()

func set_depth(new_depth:float) -> void:
	polygon[0].y = new_depth
	polygon[polygon.size()-1].y = new_depth
	_update_polygon()
