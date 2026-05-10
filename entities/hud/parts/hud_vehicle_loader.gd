extends Control

var part_load = null:
	set(value):
		update_part(value)
var vehicle = null
@onready var loadto = $AspectRatioContainer/SubViewportContainer/SubViewport/VehicleSpawn
@onready var camera = $AspectRatioContainer/SubViewportContainer/SubViewport/CameraPivot/Camera3D
@onready var camerap = $AspectRatioContainer/SubViewportContainer/SubViewport/CameraPivot

func _ready() -> void:
	vehicle = $AspectRatioContainer/SubViewportContainer/SubViewport/Vehicle
	camera.look_at(Vector3.ZERO)
	pass


func _process(delta) -> void:
	camerap.rotation.y -= delta * deg_to_rad(30)
	camera.look_at(Vector3.ZERO)


func update_part(value):
	if loadto.get_children() != []:
		for n in loadto.get_children():
			loadto.remove_child(n)
			n.queue_free()
	vehicle = value.instantiate()
	loadto.add_child(vehicle)
	var modifier = 1.5
	camera.position.z = vehicle.length * modifier / 1000
	camera.position.x = vehicle.width * modifier / 1000
	camera.position.y = vehicle.depth * modifier / 1000
	camera.look_at(Vector3.ZERO)
