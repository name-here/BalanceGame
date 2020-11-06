extends RigidBody2D

signal hit_floor

func _integrate_forces(state):
	for i in range( state.get_contact_count() ):
		var collider_object = state.get_contact_collider_object(i)
		if collider_object.collision_layer & 0b100:
			emit_signal("hit_floor")
