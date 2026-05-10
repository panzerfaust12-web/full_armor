extends Node3D
class_name OLD_DNU_Component_Suspension

#These are for components
@export var price: int = 1000 #arbitrary
@export var weight: float = 100 #kg
@export var ideal_weight_capacity: float = 5000 #kg
@export var maximum_weight_capacity: float = 12000 #kg
@export var track_width_max: float = 500 #mm
@export var track_ground_length: float = 4.0 #mm
@export var length: float = 200 #mm
@export var width: float = 200
@export var depth: float = 200
@export var long_name: String = "Super Fucking Annoying Suspension: Take 1 (of 4)"
@export var short_name: String = "SUS01"
@export var description: String = "This suspension was the fucking death of me I swear"

#These are things to make this fucked choo-choo train work
var is_left: bool = false
var is_right: bool = false
var rigid: Node = null
var has_parent: bool = false
var wheels: Array
var ground_wheels: int = 0
var contacts: int = 0
var contact_average: Vector3 = Vector3.ZERO
var normal_average: Vector3 = Vector3.ZERO
var track_segmented_length: float = 100.0

#placeholders
var grip_factor: float = 0.010
var z_traction: float = 0.05
@export var grip_curve: Curve

var sprocket_prior_rotation: float = 0.0
var sprocket_rotation: float = 0.0
var sprocket_current_rpm: float = 0.0
var sprocket_prior_rpm: float = 0.0
var sprocket_expected_rpm: float = 0.0
var sprocket_radius: float = 0.0

var incoming_transformed_engine_torque: float = 0.0
var incoming_transformed_engine_RPM: float = 0.0
var wheel_torque_output: float = 0.0
var wheel_force_output: float = 0.0
var incoming_engine_power_nms: float = 0.0

var contact1 = Vector3.ZERO
var contact2 = Vector3.ZERO
var contact_distance: float = 0.0
var is_in_contact: bool

var debug: bool = false

#temp track testing
var track_length: float = 0.0
var track_length_current: float = 0.0
var tread_length: float = 0.125
var tread_gap: float = 0.0
var tread_copies: int = 0
var tread_distance: float = 0.0
var tread_thickness: float = 0.0
var treads: Array = []

var forward_dir: Vector3 = Vector3.ZERO
var vel: float = 0.0

var susp_force: float = 0.0

#review the Octodemy video at some point, may be a way to mess with sideways grip over time and stopped



func _ready() -> void:
	#fix this parenting later jfc, make it a unified function or sum shit
	if get_parent().name != "root":
		rigid = get_parent().get_parent()
		if rigid.name == "Hull": rigid = rigid.get_parent()
		if rigid.get_class() != "RigidBody3D": rigid = null
		if rigid != null: has_parent = true
	
	if has_parent:
		if get_parent().name.contains("Left"): is_left = true
		if get_parent().name.contains("Right"): is_right = true
	
	wheels = find_children("*","Shapecast_Sus_Wheel",1,1)
	for wheel in wheels:
		if wheel.is_suspension and wheel.wheel_visible: ground_wheels += 1
		if wheel.wheel_visible: wheel.get_child(0).rotate_y(randf_range(-2*PI,2*PI))
	
	sprocket_radius = $SuspensionWheels/Sprocket.wheel_radius
	
	if is_left:
		var meshes: Array = find_children("Wheel","MeshInstance3D",1,1)
		for m in meshes:
			m.scale = m.scale * -1
	
	#temp track stuff guh
	track_length = $Path.curve.get_baked_length()
	track_length_current = track_length
	tread_copies = int(track_length / (tread_length + tread_gap))
	tread_distance = float(track_length / tread_copies)
	
	
	for i in tread_copies:
		var tread_copy = $Path/PathFollow3D.duplicate()
		tread_copy.progress = i * tread_distance
		$Path.add_child(tread_copy)
	treads = $Path.get_children()
	
	
	forward_dir = -global_basis.z.normalized()
	
	pass
	#add stuff to get track information to calculate additional weight and ground pressure


func rads_to_rpm(rads: float) -> float:
	return (rads) * (60 / (2 * PI))

func rpm_to_rads(rpm: float) -> float:
	return (rpm) * ((2 * PI) / 60)

func _suspension_visuals(delta: float) -> void:
	if $VisibleOnScreenNotifier3D.is_on_screen() and get_viewport().get_camera_3d().global_position.distance_to(global_position) < 25.00:
		_suspension_bend()
		_tread_progress(delta)
	_audio(delta)
	


func _wheel_rotations(delta: float):
	sprocket_radius = 0.635
	var forward_dir = -rigid.global_basis.z.normalized()
	var vel = forward_dir.dot(rigid.linear_velocity)
	sprocket_rotation = ((vel * get_physics_process_delta_time()) / sprocket_radius)
	sprocket_expected_rpm = (rads_to_rpm(sprocket_rotation) / delta)
	if contacts == 0: sprocket_expected_rpm = 0
	sprocket_prior_rpm = sprocket_current_rpm
	
	for wheel in wheels:
		if wheel.wheel_visible:
			var child = wheel.get_child(0)
			if incoming_engine_power_nms <= 0 or not is_in_contact:
				child.rotate_y(lerp_angle((vel * get_physics_process_delta_time()) / wheel.wheel_radius,0.0,0.5))
			else:
				child.rotate_y((vel * get_physics_process_delta_time()) / wheel.wheel_radius)
			

func _suspension_movement() -> void:
	contacts = 0
	contact_average = Vector3.ZERO
	normal_average = Vector3.ZERO
	susp_force = 0
	if has_parent:
		for wheel in wheels:
			wheel.apply_wheel_physics(rigid)
			if wheel.is_colliding():
				contact_average += wheel.get_suspension_average_position()
				normal_average += wheel.get_suspension_average_normal()
				contacts += 1
				susp_force += wheel.suspension_force
		
	
	if contacts == 0:
		is_in_contact = false
		contact_average = Vector3.ZERO
		normal_average = Vector3.ZERO
		
	if contacts != 0:
		is_in_contact = true
		contact_average = contact_average / contacts
		normal_average = normal_average / contacts
		contact_distance = track_ground_length / ground_wheels * contacts * 0.5
		contact1 = contact_average + (global_basis.z.normalized() * contact_distance)
		contact2 = contact_average - (global_basis.z.normalized() * contact_distance)
		_traction_suspension(contact1)
		_traction_suspension(contact2)
	
	#DebugDraw3D.draw_arrow_ray(contact_average,normal_average,3.0,Color.RED,0.05)
	if debug: DebugDraw3D.draw_arrow_ray(contact1,normal_average,3.0,Color.RED,0.05)
	if debug: DebugDraw3D.draw_arrow_ray(contact2,normal_average,3.0,Color.RED,0.05)

func _traction_suspension(contact: Vector3) -> void:
	#track_length_current = $Path.curve.get_baked_length()
	vel = forward_dir.dot(rigid.linear_velocity)
	
	
	var gravity = -rigid.get_gravity().y
	#var forward_dir = -global_basis.z.normalized()
	var forward_dir = normal_average.normalized().rotated(-global_basis.x.normalized(),PI/2) # NORMALIZE THIS BOY
	var force_pos = contact - rigid.global_position
	#var vel = forward_dir.dot(rigid.linear_velocity)
	var contact_vel = rigid._get_point_velocity(contact)
	z_traction = 0.25
	if rigid.motor_input_left or rigid.motor_input_right: z_traction = 0.05
	
	##Acceleration Goes Here; THESE NEED TO BE NORMALIZED FRONT FACING ONLY
	if rigid.motor_input_left and is_left:
		var accel_force = forward_dir * incoming_engine_power_nms * rigid.motor_input_left
		rigid.apply_force(accel_force, force_pos)
		if debug: DebugDraw3D.draw_arrow_ray(contact,accel_force,0.005,Color.PURPLE,0.05)
	if rigid.motor_input_right and is_right:
		var accel_force = forward_dir * incoming_engine_power_nms * rigid.motor_input_right
		rigid.apply_force(accel_force, force_pos)
		if debug: DebugDraw3D.draw_arrow_ray(contact,accel_force,0.005,Color.PURPLE,0.05)
		
	
	##Tire X Traction (Steering)
	var steering_x_vel = global_basis.x.normalized().dot(contact_vel)
	grip_factor = absf(steering_x_vel/contact_vel.length())
	
	var x_traction = grip_curve.sample_baked(grip_factor)
	
	if not rigid.hand_brake and grip_factor < 0.2:
		rigid.is_slipping = false
	if rigid.hand_brake:
		x_traction = 0.01
	elif rigid.is_slipping:
		x_traction = 0.1
	
	if not rigid.motor_input_right and not rigid.motor_input_left:
		z_traction = 0.75
		x_traction = 0.75
	
	
	var x_force = -global_basis.x.normalized() * steering_x_vel * x_traction * ((rigid.mass * gravity)/4)
	
	## Tire Z Traction
	var f_vel = forward_dir.dot(contact_vel)
	var z_friction = z_traction
	var z_force = global_basis.z.normalized() * f_vel * z_friction * ((rigid.mass * gravity)/4)
	
	##Sliding Fix - Ehh, I like the no gravity better
	#if not rigid.motor_input_left and not rigid.motor_input_right:
		#var susp = global_basis.y * (susp_force / 2)
		#z_force.z -= susp.z * rigid.global_basis.y.dot(Vector3.UP)
		#x_force.x -= susp.x * rigid.global_basis.y.dot(Vector3.UP)
	
	rigid.apply_force(x_force, force_pos)
	rigid.apply_force(z_force, force_pos)
	if debug: DebugDraw3D.draw_arrow_ray(contact,z_force/rigid.mass, z_force.length()/rigid.mass,Color.BLUE,0.05,false,0.5)
	if debug: DebugDraw3D.draw_arrow_ray(contact,x_force/rigid.mass, x_force.length()/rigid.mass,Color.RED,0.05,false,0.5)


func _tread_progress(delta: float) -> void:
	var forward_dir = -rigid.global_basis.z.normalized()
	var vel = forward_dir.dot(rigid.linear_velocity)
	if incoming_engine_power_nms <= 0 or not is_in_contact:
		$Path/PathFollow3D.progress += -lerp((vel * delta),0.0,0.5)
	else:
		$Path/PathFollow3D.progress += -(vel * delta)
	var distance: float = track_length_current / float(tread_copies)
	for i in range(1, tread_copies+1):
		treads[i].progress = $Path/PathFollow3D.progress + (distance * i)
	pass


func _suspension_bend() -> void:
	#rewrite this mess later; here we bendy da tracks
	var new_curve = $Path.curve
	new_curve.set_point_position(0,Vector3(0.0,$SuspensionWheels/Wheel3.position.y - $SuspensionWheels/Wheel3.target_length - $SuspensionWheels/Wheel3.wheel_radius,-0.418))
	new_curve.set_point_position(1,Vector3(0.0,$SuspensionWheels/Wheel4.position.y - $SuspensionWheels/Wheel4.target_length - $SuspensionWheels/Wheel4.wheel_radius,-1.709))
	new_curve.set_point_position(2,Vector3(0.0,$SuspensionWheels/Wheel5.position.y - $SuspensionWheels/Wheel5.target_length - $SuspensionWheels/Wheel5.wheel_radius,-3.044))
	new_curve.set_point_position(14,Vector3(0.0,$SuspensionWheels/Wheel2.position.y - $SuspensionWheels/Wheel2.target_length - $SuspensionWheels/Wheel2.wheel_radius,0.909))
	new_curve.set_point_position(13,Vector3(0.0,$SuspensionWheels/Wheel.position.y - $SuspensionWheels/Wheel.target_length - $SuspensionWheels/Wheel.wheel_radius,2.193))
	$Path.curve = new_curve
	
	#here we gonna do the floppy bitz
	
	#holy shit what are yoy doing
	#var floppiness = $SuspensionWheels/Wheel3.spring_target_length-0.05
	#floppiness += $SuspensionWheels/Wheel4.spring_target_length-0.05
	#floppiness += $SuspensionWheels/Wheel5.spring_target_length-0.05
	#floppiness += $SuspensionWheels/Wheel6.spring_target_length-0.05
	#floppiness += $SuspensionWheels/Wheel.spring_target_length-0.05
	#floppiness += $SuspensionWheels/Wheel2.spring_target_length-0.05
	#floppiness /= 12.0
	#
	#$Path.curve.set_point_position(9,Vector3(0.0,-0.023-floppiness,-0.94))
	#$Path.curve.set_point_position(11,Vector3(0.0,-0.023-floppiness,0.615))
	#$Path.curve.set_point_position(13,Vector3(0.0,-0.023-floppiness,2.033))
	#pass


func _audio(delta) -> void:
	var volume_mod = clampf(abs(vel),0.0,1.0)
	#var pitch_mod = clampf(abs(step.z) / 0.075,0.9,1.1)
	if abs(vel) < 0.1:
		$Moving.volume_linear = lerp($Moving.volume_linear,0.0,delta)
	if not abs(vel) < 0.1:
		if not $Moving.playing: $Moving.play()
		#$Moving.pitch_scale = lerp($Moving.pitch_scale,pitch_mod,delta)
		$Moving.volume_linear = lerp($Moving.volume_linear,volume_mod,delta)
