extends Control

var vehicle_load = null:
	set(value):
		update_vehicle(value)
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


func update_vehicle(value):
	if loadto.get_children() != []:
		for n in loadto.get_children():
			loadto.remove_child(n)
			n.queue_free()
	#await get_tree().process_frame
	vehicle = value.duplicate()
	loadto.add_child(vehicle)
	vehicle.global_position = loadto.global_position + Vector3(0,5,0)
	vehicle.mass = value.mass
	vehicle.owner = $AspectRatioContainer/SubViewportContainer/SubViewport
	for a in vehicle.find_children("*","*",1,0):
		a.owner = vehicle
	vehicle.freeze = false
	vehicle.blank_components()
	vehicle.get_components()
	vehicle.assign_component_values()
	vehicle.regenerate_collisions()
	#var modifier = 1.5
	#loadto.get_child(0).regenerate_collisions()
#	camera.position.z = vehicle.length * modifier / 1000
#	camera.position.x = vehicle.width * modifier / 1000
#	camera.position.y = vehicle.depth * modifier / 1000
	camera.look_at(Vector3.ZERO)
