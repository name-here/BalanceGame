tool

class_name Goal extends Sprite


signal goal_entered

export(NodePath) var _particles:NodePath
onready var particles:CPUParticles2D = get_node(_particles)

export(bool) var is_active := true setget _set_active
export(bool) var emit_particles := true setget _set_emit_particles
export(Color) var fade_color := Color(1, 1, 1, 1) setget _set_fade_color
export(Color) var base_color := Color(1, 1, 1, 1) setget _set_base_color
export(Color) var particle_color := Color(1, 1, 1, 1) setget _set_particle_color
export(Color) var particle_glow_color := Color(1, 1, 1, 1) setget _set_particle_glow_color

export(NodePath) var _character:NodePath
onready var character:Character = get_node(_character)

func _ready() -> void:
	material = material.duplicate()
	_set_active(is_active)
	_set_fade_color(fade_color)
	if particles:
		particles.material = particles.material.duplicate()
		_set_emit_particles(emit_particles)
		_set_base_color(base_color)
		_set_particle_color(particle_color)

func _process(_delta) -> void:
	if not Engine.editor_hint and character != null:
		var goal_position:float = global_position.x - 128
		if character.global_position.x > goal_position:
			emit_signal("goal_entered")


func _set_active(value:bool) -> void:
	material.set_shader_param("isActive", value)
	is_active = value

func _set_emit_particles(value:bool) -> void:
	if particles:
		particles.emitting = value
	emit_particles = value

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
