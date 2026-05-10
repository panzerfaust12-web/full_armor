extends RigidBody3D
class_name VehicleControllerOLD

#Vehicle Variables
var custom_COM: Vector3 = Vector3.ZERO
var custom_mass: float = 1000
var is_slipping = false
var hand_brake = false

#Temporary Car Testing
var acceleration = 3000.0
var max_speed = 240.0
@export var accel_curve: Curve

#Vehicle Inputs (AI and Player)
var motor_input_right: int = 0
var motor_input_left: int = 0
var engine_toggle = false

#Component Carriers
var hull: Component_Hull = null
var turrets: Array = []
var engine: Component_Engine = null
var transmission: Component_Transmission = null
var suspensions: Array = []
var suspension_wheels: Array = []

#Hull Variables

#Engine Variables
#var horsepower: float = 100
#var rpm_max: float = 100
#var rpm_peak: float = 90
#var rpm_idle: float = 10
#var power_curve: Curve = null
var engine_torque_output: float = 0.0
var engine_RPM: float = 0.0
var RPM_shift_up: float = 0
var RPM_shift_down: float = 0
var pseudo_RPM: float = 0.0

#placeholder-y
var engine_power_nms: float = 0.0
var incoming_transformed_wheel_RPM: float = 0.0

#Suspension Variables
var sprocket_RPM: float = 0.0

#Transmission Variables
var steering_type: int = 1 #"Clutch:1","Differential:2","Twin Transmission:3","Double Differential:4","Electric:5"
var gear_ratio : Array = [10.0, 5.0, 2.5, 1.0]
var reverse_ratio : Array = [5.0]

#Wheel Variables

#Water Variables
var float_force: float = 2.5
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var water_drag: float = 0.05
var water_angular_drag: float = 0.05
var submerged: bool = false
var depth_max: float = 2.5
@onready var water: Node = $"../NavigationRegion3D/WaterPlane"

func _water_physics():
	submerged = false
	var depth = water.get_height(global_position) - global_position.y
	depth = min(depth, depth_max)
	if depth > 0:
		submerged = true
		apply_central_force(Vector3.UP * float_force * gravity * depth * mass)

func _ready() -> void:
#	await owner.ready
	_get_components()
	_assign_component_values()
	_regenerate_collisions()


func _get_point_velocity(point: Vector3) -> Vector3:
	return linear_velocity + angular_velocity.cross(point - to_global(center_of_mass))

func _process(delta: float) -> void:
	_component_inputs()
	_hud_stuff()
	#for suspension in suspensions:
		#suspension._suspension_visuals(delta)

func _physics_process(delta: float) -> void:
	_vehicle_driving(delta)
	#_slope_fix()
	#_water_physics()

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if submerged:
		state.linear_velocity *= 1.0 - water_drag
		state.angular_velocity *= 1.0 - water_angular_drag

func _slope_fix(): #This is some temporary stuff - it really needs to come from the suspension call if all wheels are on da ground
	if motor_input_left + motor_input_right == 0:
		var collision_normal: Vector3 = Vector3.ZERO
		var is_in_contact = 0
		for i in suspensions:
			collision_normal += i.normal_average
			if i.is_in_contact: is_in_contact += 1
		collision_normal /= 2
		if is_in_contact > 0:
			linear_velocity -= -9.8 * Vector3.UP * get_physics_process_delta_time()
			linear_velocity += -9.8 * collision_normal * get_physics_process_delta_time()

func _vehicle_driving(delta: float) -> void:
		#Assign some Values
	sprocket_RPM = 0.0
	var contact = 0
	
	for suspension in suspensions:
		suspension._wheel_rotations(delta)
		suspension._suspension_movement()
		if suspension.is_in_contact:
			sprocket_RPM += suspension.sprocket_expected_rpm
			contact += 1
		else:
			sprocket_RPM += transmission.convert_engine_rpm(engine.RPM * (0.99 + ((motor_input_left + motor_input_right) * 0.01))) / 2
	#sprocket_RPM = max(sprocket_RPM,0)
	
	if not engine.on:
		engine_power_nms = 0.0
		engine.RPM = 0.0
		for suspension in suspensions:
			suspension.incoming_engine_power_nms = engine_power_nms
		return
	
	if motor_input_left + motor_input_right >= 0:
		sprocket_RPM = max(sprocket_RPM,0)
	elif motor_input_left + motor_input_right < 0:
		sprocket_RPM = min(sprocket_RPM,0)
		
	if abs(motor_input_left) + abs(motor_input_right) > 0:
		pseudo_RPM += (1000 * delta)
	else:
		pseudo_RPM -= (1000 * delta)
	
	pseudo_RPM = clampf(pseudo_RPM,engine.RPM_idle,engine.RPM_max)
	sprocket_RPM = clampf(sprocket_RPM, -100000,100000)
	incoming_transformed_wheel_RPM = transmission.convert_wheel_rpm(sprocket_RPM)
	#if pseudo_RPM > engine_RPM: engine.RPM_sound = pseudo_RPM

	
	
	engine.RPM = clampf(abs(incoming_transformed_wheel_RPM),engine.RPM_idle,engine.RPM_max)
	#At some point, you need to simulate throttle in first gear to get up hills and such
	
	engine_power_nms = engine._return_power(engine.RPM)
	
	if abs(transmission.current_gear) == 1:
		engine_power_nms = engine._return_power(max(engine.RPM,pseudo_RPM))
	else:
		pseudo_RPM = 0
	
	
	#eventually you'll need to divide the used power between components to enable wheels or half-tracks
	engine_power_nms = engine_power_nms / 4 / max(abs(motor_input_left)+abs(motor_input_right),1)#divide by suspensions, and two points of contact for each

	#Provide transformed power to suspensions
	for suspension in suspensions:
		suspension.incoming_engine_power_nms = engine_power_nms
	var reverse = false
	if (motor_input_left + motor_input_right) < 0: reverse = true
	
	if contact > 0: transmission.gear_shift(engine.RPM,RPM_shift_up,RPM_shift_down, reverse,engine.on)

func _hud_stuff():
	$PlayerController/HUD/Engine.text = str("Sprocket RPM: ",int(sprocket_RPM), " | Sprocket Power: ",int(engine_power_nms))
	$"PlayerController/HUD/Sprocket to Engine".text = str("Current Speed: ",int((linear_velocity * -global_basis.z).length() * 2.23694))
	$PlayerController/HUD/Sprocket.text = str("Engine RPM: ",int(engine.RPM)," | Sound RPM:",int(engine.RPM_sound)," | Pseudo RPM:",int(pseudo_RPM))
	$PlayerController/HUD/Gearbox.text = str("Gearbox Gear: ",transmission.current_gear, " | Gearbox Combined Ratio: ",snapped(transmission.combined_ratio,0.01))
	var speed_ratio: float = (deg_to_rad(430.0) - deg_to_rad(110.0)) / 100.0
	$PlayerController/HUD/SpNeed.rotation = deg_to_rad(110.0) + (speed_ratio * int((linear_velocity * -global_basis.z).length() * 2.23694))
	
func _get_components():
	var hull_a = find_children("*","Component_Hull",1,1)
	if hull_a.size() > 0:
		hull = hull_a[0]
	turrets = find_children("*","Component_Turret",1,1)
	var engine_a = find_children("*","Component_Engine",1,1)
	if engine_a.size() > 0:
		engine = engine_a[0]
	transmission = find_children("*","Component_Transmission",1,1)[0]
	suspensions = find_children("*","Component_Suspension",1,1)
	suspension_wheels = find_children("*","Shapecast_Sus_Wheel",1,1)
	#Guns need to go here

func _assign_component_values():
	#Clear Weight Calcs
	mass = 100
	custom_COM = Vector3.ZERO
	
	#Calculated Mass
	custom_mass = hull.weight + engine.weight + transmission.weight
	for turret in turrets:
		custom_mass += turret.weight
	for suspension in suspensions:
		custom_mass += suspension.weight
	mass = custom_mass
	
	#Calculated COM
	custom_COM += engine.get_parent().position * (engine.weight / custom_mass)
	custom_COM += transmission.get_parent().position * (transmission.weight / custom_mass)
	for turret in turrets:
		custom_COM += turret.get_parent().position * (turret.weight / custom_mass)
	for suspension in suspensions:
		custom_COM += suspension.get_parent().position * (suspension.weight / custom_mass)
	center_of_mass = custom_COM
	$COM_Ball.position = center_of_mass
	
	#Keep wheels from colliding with self
	for wheel in suspension_wheels:
		wheel.add_exception(self)
	
	
	#Engine Variables
	#horsepower = engine.horsepower
	#rpm_max = engine.RPM_max
	#rpm_peak = engine.RPM_peak
	#rpm_idle = engine.RPM_idle
	#power_curve = engine.power_curve
	RPM_shift_up = engine.RPM_shift_up
	RPM_shift_down = engine.RPM_shift_down
	
	#Transmission Variables
	steering_type = transmission.steering_type
	gear_ratio = transmission.gear_ratio
	reverse_ratio = transmission.reverse_ratio

func _regenerate_collisions():
	#Remove Any Leftover Duplicated Collisions
	var colremove: Array = find_children("DuplicatedCollision*","CollisionShape3D")
	for i in colremove:
		queue_free()
	#Reassign Collisions from Children
	var collisions: Array = find_children("*Collision*","CollisionShape3D",1,0)
	var index = 0
	for cm in collisions:
		var cmcopy = cm.duplicate()
		cmcopy.name = "DuplicatedCollision" + str(index)
		if cm.get_parent().get_parent().name.contains("Mount"):
			cmcopy.position += cm.get_parent().get_parent().position
		add_child(cmcopy)
		index += 1


func _component_inputs():
	if engine_toggle == true:
		engine.on = not engine.on
		engine_toggle = false
