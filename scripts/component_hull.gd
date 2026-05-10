extends Node3D
class_name Component_Hull
var component_name: String = "Hull"

@export var price: int = 1000 #arbitrary
@export var weight: int = 5000 #kg
@export var ideal_weight_capacity: int = 5000 #kg
@export var maximum_weight_capacity: int = 12000 #kg
@export var track_width_max: int = 500 #mm
@export var fire_chance: float = 0.2
@export var length: int = 2000 #mm
@export var width: int = 2000
@export var depth: int = 2000
@export var long_name: String = "Big Angular Green Shitbox 01"
@export var short_name: String = "BAGS01"
@export var description: String = "This would be about the 40-50th hour I've spent looking at this fucking thing."

var parent: Node3D
