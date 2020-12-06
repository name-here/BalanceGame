extends Polygon2D


signal polygon_changed(poylgon)

func set_polygon(new_polygon:PoolVector2Array) -> void:
	print("polygon changed")
	emit_signal("polygon_changed", new_polygon)
	polygon = new_polygon
