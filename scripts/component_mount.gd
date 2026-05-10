extends Node3D
class_name Component_Mount
var component_name: String = "Mount"

@export_enum("Any","Hull","Turret","Engine","Transmission","Suspension","Wheel") var accepts: String = "Any"
@export var weight_limit: float = 10000.0
@export var size_limit: Vector3 = Vector3(10000.0, 10000.0, 10000.0)
