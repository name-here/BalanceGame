tool

class_name Goal extends Sprite


signal goal_entered

export(NodePath) var _particles:NodePath
onready var particles:CPUParticles2D = get_node(_particles)

export(bool) var is_active := true setget _set_active
export(bool) var emit_particles := true setget _set_emit_particles
export(bool) var disable_particles_in_editor := false setget _set_disable_particles_in_editor

export(Color) var fade_color := Color(1, 1, 1, 1) setget _set_fade_color
export(Color) var base_color := Color(1, 1, 1, 1) setget _set_base_color
export(Color) var particle_color := Color(1, 1, 1, 1) setget _set_particle_color
export(Color) var particle_glow_color := Color(1, 1, 1, 1) setget _set_particle_glow_color

export(NodePath) var _character:NodePath
var character:Character

var is_in_goal := false#true if character is currently in this goal


func _ready() -> void:
	if Engine.editor_hint:
		material = material.duplicate()
	
	if _character:
		character = get_node(_character)
	
	_set_active(is_active)
	_set_fade_color(fade_color)
	if particles:
		if Engine.editor_hint:
			particles.material = particles.material.duplicate()
		_set_emit_particles(emit_particles)
		_set_base_color(base_color)
		_set_particle_color(particle_color)

func _process(_delta) -> void:
	if not Engine.editor_hint and character:
		var goal_position:float = global_position.x - 128
		if character.global_position.x > goal_position:
			if not is_in_goal:
				emit_signal("goal_entered")
				is_in_goal = true
		else:
			is_in_goal = false


func _set_active(value:bool) -> void:
	#set_process(value)
	material.set_shader_param("isActive", value)
	is_active = value

func _set_emit_particles(value:bool) -> void:
	if particles:
		particles.emitting = value and not (Engine.editor_hint and disable_particles_in_editor)
	emit_particles = value

func _set_disable_particles_in_editor(value:bool) -> void:
	if particles and Engine.editor_hint:
		particles.emitting = emit_particles and not value
	disable_particles_in_editor = value

func _set_fade_color(new_color:Color) -> void:
	material.set_shader_param("fadeColor", new_color)
	fade_color = new_color

func _set_base_color(new_color:Color) -> void:
	material.set_shader_param("baseColor", new_color)
	base_color = new_color

func _set_particle_color(new_color:Color) -> void:
	if particles:
		for i in particles.color_ramp.colors.size():
			particles.color_ramp.colors[i].r = new_color.r
			particles.color_ramp.colors[i].g = new_color.g
			particles.color_ramp.colors[i].b = new_color.b
		particles.color_ramp.colors[1].a = new_color.a
	particle_color = new_color

func _set_particle_glow_color(new_color:Color) -> void:
	if particles:
		particles.material.set_shader_param("glowColor", new_color)
	particle_glow_color = new_color
