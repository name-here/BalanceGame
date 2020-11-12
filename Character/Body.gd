extends RigidBody2D


signal hit_floor(collision_point, collision_normal)


func _integrate_forces(state):
	for i in range( state.get_contact_count() ):
		var collider_object = state.get_contact_collider_object(i)
		if collider_object.collision_layer & 0b100:
			emit_signal( "hit_floor", state.get_contact_local_position(i) + global_position, state.get_contact_local_normal(i)+global_position)
		break#only emits hit_floor for the first collision, if hitting more than one floor at the same time
