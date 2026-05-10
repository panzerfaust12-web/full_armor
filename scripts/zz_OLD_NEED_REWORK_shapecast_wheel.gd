extends ShapeCast3D
class_name ShapeCastWheel

#Wheel Properties
@export var spring_strength = 100.0
@export var spring_damping = 2.0
@export var rest_dist = 1.0
@export var wheel_radius = 0.5
@export var over_extend = 0.0
@export var z_traction = 0.05
@export var grip_curve: Curve
@export var spring_down: float = 25.0
@export var spring_up: float = 15.0

#Type
@export var is_left = false
@export var is_right = false
@export var is_suspension = false

#Antiqated, DNU
@export var is_motor_right = false
@export var is_motor_left = false

@onready var wheel: Node3D = get_child(0)

var track_thickness: float = 0.05
var wheel_y_pos: float = 0.0
var engine_force: float = 0.0
var grip_factor: float = 0.0

func _ready() -> void:
	wheel.rotation.x = randf_range(0,360)
	target_position.y = -(rest_dist + wheel_radius + over_extend)

func apply_wheel_physics(tank) -> void:
	force_shapecast_update()
	target_position.y = -(rest_dist + wheel_radius + over_extend)
	
	#Rotate wheel visuals
	var forward_dir = -global_basis.z
	var vel = forward_dir.dot(tank.linear_velocity)
	wheel.rotate_x((-vel * get_physics_process_delta_time()) / wheel_radius)
	
	if not is_colliding():
		wheel_y_pos = lerp(wheel_y_pos, -rest_dist, get_physics_process_delta_time() * spring_up)
		return
		
	#From here, the wheel raycast is colliding
	var gravity = -tank.get_gravity().y
	var contact = get_collision_point(0)
	var spring_len = maxf(0.0,global_position.distance_to(contact) - wheel_radius)
	var offset = rest_dist - spring_len
	var lerpspeed = 10
	if wheel_y_pos > -spring_len:
		lerpspeed = spring_down
	else:
		lerpspeed = spring_up
	
	wheel_y_pos = move_toward(wheel_y_pos, -spring_len, get_physics_process_delta_time() * lerpspeed)
	contact = wheel.global_position
	
	if is_suspension: wheel.position.y = wheel_y_pos + track_thickness
	var force_pos = contact - tank.global_position
	

	#Spring Forces
	var spring_force = spring_strength * offset
	var tire_vel = tank._get_point_velocity(contact)
	var spring_damp_f = spring_damping * global_basis.y.dot(tire_vel)
	var y_force = (spring_force - spring_damp_f) * get_collision_normal(0)
	
	##Acceleration Goes Here
	if tank.motor_input_left and is_left:
		var speed_ratio = vel / tank.max_speed
		var ac = tank.accel_curve.sample_baked(speed_ratio)
		var accel_force = forward_dir * tank.acceleration * tank.motor_input_left * ac
		tank.apply_force(accel_force, force_pos)
	if tank.motor_input_right and is_right:
		var speed_ratio = vel / tank.max_speed
		var ac = tank.accel_curve.sample_baked(speed_ratio)
		var accel_force = forward_dir * tank.acceleration * tank.motor_input_right * ac
		tank.apply_force(accel_force, force_pos)
	
	##Tire X Traction (Steering)
	var steering_x_vel = global_basis.x.dot(tire_vel)
	grip_factor = absf(steering_x_vel/tire_vel.length())
	
	var x_traction = grip_curve.sample_baked(grip_factor)
	
	if not tank.hand_brake and grip_factor < 0.2:
		tank.is_slipping = false
	if tank.hand_brake:
		x_traction = 0.01
	elif tank.is_slipping:
		x_traction = 0.1
	
	
	var x_force = -global_basis.x * steering_x_vel * x_traction * ((tank.mass * gravity)/tank.wheels_total)
	
	## Tire Z Traction
	var f_vel = forward_dir.dot(tire_vel)
	var z_friction = z_traction
	var z_force = global_basis.z * f_vel * z_friction * ((tank.mass * gravity)/tank.wheels_total)
	
	tank.apply_force(y_force, force_pos)
	tank.apply_force(x_force, force_pos)
	tank.apply_force(z_force, force_pos)
	
	DebugDraw3D.draw_arrow_ray(contact,y_force/tank.mass, y_force.length()/tank.mass,Color.GREEN,0.05,false,0.5)
	DebugDraw3D.draw_arrow_ray(contact,z_force/tank.mass, z_force.length()/tank.mass,Color.BLUE,0.05,false,0.5)
	DebugDraw3D.draw_arrow_ray(contact,x_force/tank.mass, x_force.length()/tank.mass,Color.RED,0.05,false,0.5)
