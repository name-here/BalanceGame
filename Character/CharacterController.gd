extends Node2D


signal character_torque_changed(value)
signal character_tension_changed(value)

signal body_hit_floor

export(NodePath) var _followed:NodePath
onready var followed:Node2D = get_node(_followed)

export(NodePath) var _wheel:NodePath
onready var wheel:RigidBody2D = get_node(_wheel)
export(NodePath) var _body:NodePath
onready var body:RigidBody2D = get_node(_body)
export(NodePath) var _spring:NodePath
onready var spring:DampedSpringJoint2D = get_node(_spring)
export(NodePath) var _connector:NodePath
onready var connector:Node2D = get_node(_connector)

export(bool) var do_torque_input := true
export(bool) var do_compress_input := true

# Mouse position is scaled based on viewport size (-1 to 1), with (0, 0) at the center
var mouse_pos := Vector2()
export(float) var sensitivity:float = 40000
export(float) var friction:float = 0.02

var tension:float = 0 setget _set_tension
export(float) var max_tension:float = 0.95
export(float) var tension_step:float = 0.01

func _set_tension(value:float):
	tension = value
	spring.rest_length = (value + 1) * spring.length
	emit_signal("character_tension_changed", value / max_tension)


#func _ready():
#	update_mouse(get_viewport().get_mouse_position())#for some reason, this always gives the same value

func _physics_process(delta):
	var torque_to_apply:float = 0
	if do_torque_input:
		torque_to_apply +=  mouse_pos.x * sensitivity * delta
	torque_to_apply -= friction * wheel.angular_velocity * wheel.angular_velocity * sign(wheel.angular_velocity)
	torque_against(wheel, torque_to_apply, body)
	if do_compress_input:
		if Input.is_action_pressed("character_compress") and tension > -max_tension:
			_set_tension( clamp(tension - tension_step, -max_tension, max_tension) )
		elif tension > 0:
			_set_tension( clamp(tension - tension_step, 0, max_tension) )
	
	connector.global_position = wheel.global_position
	update_origin()

# Rotates body1 and applies corresponding torque to body2
func torque_against(body1:RigidBody2D, torque:float, body2:RigidBody2D):
	var offset:Vector2 = body2.global_position - body1.global_position
	body1.apply_torque_impulse(torque)
	body2.apply_impulse(offset + Vector2(1, 0), Vector2(0, -torque/2))
	body2.apply_impulse(offset + Vector2(-1, 0), Vector2(0, torque/2))


func _input(event):
	if event is InputEventMouseMotion:
		update_mouse(event.position)
	if do_compress_input and event.is_action_released("character_compress"):
		_set_tension(max_tension)

func update_mouse(position:Vector2):
	mouse_pos = (position * 2 / get_viewport_rect().size) - Vector2(1, 1)
	mouse_pos.x = clamp(mouse_pos.x, -1, 1)
	mouse_pos.y = clamp(mouse_pos.y, -1, 1)
	
	emit_signal("character_torque_changed", mouse_pos.x)

func update_origin():
	if followed != null:
		var offset:Vector2
		offset = followed.global_position - global_position
		wheel.position -= offset
		body.position -= offset
		position += offset


func _body_hit_floor():
	emit_signal("body_hit_floor")
