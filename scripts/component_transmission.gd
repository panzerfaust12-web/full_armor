extends Node3D
class_name Component_Transmission
var component_name: String = "Transmission"

@export_category("Core") # These are basic, shared component value that let attachment points know what is/isn't legal.
@export var long_name: String = "Does Nothing Eats Shells mk 01"
@export var short_name: String = "DNES01"
@export var description: String = "Transmission Stuff"
@export var price: int = 1000
@export_custom(PROPERTY_HINT_NONE, "suffix:mm") var length: int = 200
@export_custom(PROPERTY_HINT_NONE, "suffix:mm") var width: int = 200
@export_custom(PROPERTY_HINT_NONE, "suffix:mm") var depth: int = 200
@export_custom(PROPERTY_HINT_NONE, "suffix:kg")  var weight: int = 2100
@export var fire_chance: float = 0.2 # Percent chance  of fire upon taking damage. Will likely need a cooldown to proc (machine guns.)
@export_category("Specific")
@export_enum("Clutch:1","Differential:2","Twin Transmission:3","Double Differential:4","Electric:5") var steering_type: int
@export var gear_ratio: Array = [7.56, 3.11, 1.78, 1.11, 0.73]
@export var reverse_ratio: Array = [5.65, 3.11, 1.78, 1.11, 0.73]
@export var final_ratio: float = 2.84
@export var gear_shift_time: float  = 0.3 #seconds
@export_category("Debug")
@export var debug_enabled: bool = false

var parent: Node3D


var current_gear: int = 1
var forward_gears: int = 1
var reverse_gears: int = 1
var current_gear_ratio: float = 0.0
var prior_gear: int = 1
var combined_ratio: float = 0.0

var transformed_engine_rpm: float = 0.0
var transformed_wheel_rpm: float = 0.0
var transformed_wheel_torque: float = 0.0

func _ready() -> void:
	forward_gears = gear_ratio.size()
	reverse_gears = reverse_ratio.size()
	
func gear_shift(engine_rpm, engine_shift_up, engine_shift_down, reverse, on):
	current_gear = clampi(current_gear,-reverse_gears,forward_gears)
	if current_gear == 0: current_gear_ratio = 0.0
	if current_gear < 0: current_gear_ratio = -reverse_ratio[-current_gear-1]
	if current_gear > 0: current_gear_ratio = gear_ratio[current_gear-1]
	combined_ratio = final_ratio * current_gear_ratio
	
	if $GearShift.is_stopped():
		if not reverse:
			if current_gear <= 0: current_gear = 1
			if current_gear != forward_gears:
				if engine_rpm > engine_shift_up: current_gear += 1
			if current_gear > 1:
				if engine_rpm < engine_shift_down: current_gear -= 1
		if reverse:
			if current_gear >= 0: current_gear = -1
			if current_gear != -reverse_gears:
				if engine_rpm > engine_shift_up: current_gear -= 1
			if current_gear < -1:
				if engine_rpm < engine_shift_down: current_gear += 1
	if not on: current_gear = 0
	
	if prior_gear != current_gear:
		$Shift_Sound.play()
		$GearShift.start()
		
	prior_gear = current_gear

func convert_engine_rpm(engine_rpm) -> float:
	if combined_ratio == 0: return 0
	else: return engine_rpm / combined_ratio

func convert_engine_torque(engine_torque) -> float:
	return engine_torque * combined_ratio

func convert_wheel_rpm(wheel_rpm) -> float:
	return wheel_rpm * combined_ratio

func convert_wheel_torque(wheel_torque) -> float:
	if combined_ratio == 0: return 0
	else: return wheel_torque / combined_ratio
