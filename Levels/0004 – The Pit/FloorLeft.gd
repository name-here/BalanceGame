tool

extends PolygonBlock

func set_height(new_height:float) -> void:
	polygon[0].y = new_height
	polygon[polygon.size()-1].y = new_height
	_update_polygon()
