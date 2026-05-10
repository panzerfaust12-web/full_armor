extends Node3D


func _ready() -> void:
	var wheels = find_children("*","Phys_Wheel",1,1)
	var rigids = find_children("*", "RigidBody3D",1,1)
	
	for wheel in wheels:
		for rigid in rigids:
			wheel.add_exception(rigid)
