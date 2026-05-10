extends Control

var part_load = null:
	set(value):
		update_part(value)
var part = null
@onready var loadto = $AspectRatioContainer/SubViewportContainer/SubViewport/PartHolder/RigidBody3D
@onready var camera = $AspectRatioContainer/SubViewportContainer/SubViewport/Camera3D

func _ready() -> void:
	pass
	

func update_part(value):
	if loadto.get_children() != []:
		for n in loadto.get_children():
			loadto.remove_child(n)
			n.queue_free()
	part = value.instantiate()
	loadto.add_child(part)
	var modifier = 1.5
	camera.position.z = part.length * modifier / 1000
	camera.position.x = part.width * modifier / 1000
	camera.position.y = part.depth * modifier / 1000
	camera.look_at(Vector3.ZERO)
