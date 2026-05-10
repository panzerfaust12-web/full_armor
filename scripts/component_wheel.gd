extends Node3D
class_name Component_Wheel
var component_name: String = "Wheel"

@export_category("Core") # These are basic, shared component value that let attachment points know what is/isn't legal.
@export var price: int = 1000 #arbitrary
@export_custom(PROPERTY_HINT_NONE, "suffix:mm") var length: int = 200
@export_custom(PROPERTY_HINT_NONE, "suffix:mm") var width: int = 200
@export_custom(PROPERTY_HINT_NONE, "suffix:mm") var depth: int = 200
@export_custom(PROPERTY_HINT_NONE, "suffix:kg")  var weight: int = 50
@export var long_name: String = "Test Wheel 01"
@export var short_name: String = "IASFSOTW202622"
@export var description: String = "blah blah blah wheels"
@export_category("Specific") # These are basic, shared component value that let attachment points know what is/isn't legal.
@export_custom(PROPERTY_HINT_NONE, "suffix:kg") var safe_weight: int = 200
@export_custom(PROPERTY_HINT_NONE, "suffix:kg") var maximum_weight: int = 200
@export var engine_driven: bool = false

# PUT SOME EXPORT VARS HERE TO INFORM THE USER ABOUT MAXIMUM WEIGHT AND SUCH.

var RPM_engine_incoming: float = 0.0
var RPM_wheel_outgoing: float = 0.0
var engine_max_force: float = 0.0

var turn_left: bool = false
var turn_right: bool = false

var brakes_on: bool = false
var is_left: bool = false

var turn_wheellength: float = 0
var turn_wheelwidth: float = 0
var wheel_radius: float = 0

var is_colliding: bool = false

var parent: Node3D

#ALL THIS CLASS DOES IS PASS INPUTS TO A PHYS_WHEEL
#I'm too tired for this :(
# DO THE MOUNTS THEMSELVES NEED TO SAY WHAT GOES WHERE FOR INPUTS??? ?AUGHUIAGHUAHGUASGHUSG

func _ready() -> void:
	if owner != null: await owner.ready
	if parent == null:
		parent = GlobalFunctions.grab_rigid_parent(self)
	$Phys_Wheel.parent = parent
	if get_child(0).is_class("Phys_Wheel"):
		print("PHYS WHEEL NOT ASSIGNED TO COMPONENT WHEEL")
		print(self)
		queue_free()
	wheel_radius = $Phys_Wheel.wheel_radius


func _physics_process(delta: float) -> void:
	$Phys_Wheel.RPM_engine_incoming = RPM_engine_incoming
	$Phys_Wheel.engine_incoming_force = engine_max_force
	$Phys_Wheel.brakes_on = brakes_on
	$Phys_Wheel.turn_left = turn_left
	$Phys_Wheel.turn_right = turn_right
	$Phys_Wheel.turn_wheellength = turn_wheellength
	$Phys_Wheel.turn_wheelwidth = turn_wheelwidth
	RPM_wheel_outgoing = $Phys_Wheel.RPM_wheel_free
	is_colliding = $Phys_Wheel.is_colliding_bool
