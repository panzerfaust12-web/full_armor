extends RigidBody3D

@export var wheels: Array[RaycastWheel]
@export var acceleration = 5000.0
@export var max_speed = 50
@export var accel_curve: Curve
@export var max_pitch : float = 89
@export var min_pitch : float = -89
@export_range(1, 100, 1) var mouse_sensitivity: int = 20
var motor_input_right = 0
var motor_input_left = 0
var wheels_total = 0
var wheels_right = 0
var wheels_left = 0
var wheels_right_contact = 0
var wheels_left_contact = 0
var prior_right_input = 0
var prior_left_input = 0
var impact_speed = 16
var cam_y_rot : float = 0
var tricknoise = 0
var prior_gear = 0
var old_position = Vector3.ZERO
var step = Vector3.ZERO

var gear_ratio : Array = [7.56, 3.11, 1.78, 1.11, 0.73]
var reverse_ratio : float = 5.65
var final_drive_ratio : float = 2.84
var max_engine_rpm = 2800.0
@export var power_curve : Curve = null

var MAX_ENGINE_FORCE = 800
var current_gear = 1
var current_speed_mps = 0.0
var gear_shift_time = 0.3
var gear_timer = 0.0
var clutch_position : float = 1.0 #0.0 clutch fully engaged
@onready var last_pos = position
@onready var TankShell = preload("res://tank_shell_generic.tscn")

func get_speed_kph():
	return current_speed_mps * 3600.0 / 1000.0

func _calculate_rpm() -> float:
	if current_gear == 0:
		return 0.0
	
	var wheel_circ : float = 2.0 * PI * 0.5
	var wheel_rot_speed : float = 60.0 * current_speed_mps / wheel_circ
	var drive_shaft_rot_speed : float  = wheel_rot_speed * final_drive_ratio
	if current_gear == -1:
		return drive_shaft_rot_speed * reverse_ratio
	elif current_gear <= gear_ratio.size():
		return drive_shaft_rot_speed * gear_ratio[current_gear - 1]
	else:
		return 0.0

func _engine_stuff(delta) ->void:
	current_speed_mps = (position - last_pos).length() / delta
	last_pos = position
	var rpm = _calculate_rpm()
	rpm += 400.0
	var rpm_factor = clamp(rpm / max_engine_rpm, 0.0, 1.0)
	var power_factor = power_curve.sample_baked(rpm_factor)
	
	var speed = get_speed_kph()
	var info = 'Speed: %.0f, RPM: %.0f (gear: %d)'  % [ speed, rpm, current_gear ]
	if rpm > max_engine_rpm:
		current_gear += 1
	if rpm < 1000 and current_gear > 1:
		current_gear -= 1
	$HUD/RichTextLabel.text = info

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("tread_right_forward"):
		motor_input_right = 1
	elif event.is_action_released("tread_right_forward"):
		motor_input_right = 0

	if event.is_action_pressed("tread_right_backward"):
		motor_input_right = -1
	elif event.is_action_released("tread_right_backward"):
		motor_input_right = 0
		
	if event.is_action_pressed("tread_left_forward"):
		motor_input_left = 1
	elif event.is_action_released("tread_left_forward"):
		motor_input_left = 0
	if event.is_action_pressed("tread_left_backward"):
		motor_input_left = -1
	elif event.is_action_released("tread_left_backward"):
		motor_input_left = 0
	if event.is_action_pressed("jumppu"):
		apply_impulse(basis.y * 20000)
		$SoundController/Jumppu.play()
	if event.is_action_pressed("flippu"):
		apply_impulse(basis.y * 5000,basis.x * 9 * ((randi() & 1) * 2 - 1))
		await get_tree().create_timer(0.2).timeout
		tricknoise = 1

	#if event.is_action("cam_left"):
		#$CameraPivot.rotation.y = $CameraPivot.rotation.y - (0.1)
		#$CameraPivot.rotation.y = snapped($CameraPivot.rotation.y, 0.1)
	#if event.is_action("cam_right"):
		#$CameraPivot.rotation.y = $CameraPivot.rotation.y + (0.1)
		#$CameraPivot.rotation.y = snapped($CameraPivot.rotation.y, 0.1)
	#if event.is_action("cam_up"):
		#$CameraPivot.rotation.x = $CameraPivot.rotation.x - (0.1)
		#$CameraPivot.rotation.x = snapped($CameraPivot.rotation.x, 0.1)
	#if event.is_action("cam_down"):
		#$CameraPivot.rotation.x = $CameraPivot.rotation.x + (0.1)
		#$CameraPivot.rotation.x = snapped($CameraPivot.rotation.x, 0.1)
	#if event.is_action("cam_back"):
		#$CameraPivot/Camera3D.position.z = $CameraPivot/Camera3D.position.z + (1)
		#$CameraPivot/Camera3D.position.z = snapped($CameraPivot/Camera3D.position.z, 0.1)
	#if event.is_action("cam_forward"):
		#$CameraPivot/Camera3D.position.z = $CameraPivot/Camera3D.position.z - (1)
		#$CameraPivot/Camera3D.position.z = snapped($CameraPivot/Camera3D.position.z, 0.1)
	if event.is_action_pressed("camera_toggle"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if event.is_action_pressed("fire"):
		_cannon()
		
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion: Vector2 = event.relative
		var degrees_per_unit: float = 0.001
		motion *= mouse_sensitivity
		motion *= degrees_per_unit
		$CameraPivot.global_rotation.x += deg_to_rad(-motion.y)
		$CameraPivot.global_rotation.x = clamp($CameraPivot.global_rotation.x, deg_to_rad(min_pitch),deg_to_rad(max_pitch))
		cam_y_rot += deg_to_rad(-motion.x)
	if event.is_action("scroll_forward"):
		$CameraPivot/Camera3D.position.z -= .25
	if event.is_action("scroll_back"):
		$CameraPivot/Camera3D.position.z += .25

func _ready() -> void:
	for wheel in wheels:
		if wheel.is_motor_left:
			wheels_left += 1
			wheels_total += 1
		if wheel.is_motor_right:
			wheels_right += 1
			wheels_total += 1
	_tread_spawner()
	Input.set_use_accumulated_input(true)

func _physics_process(delta: float) -> void:
	_engine_stuff(delta)
	_tread_mess()
	for wheel in wheels:
		wheel.force_raycast_update()
		_do_single_wheel_contact_math(wheel)
		_do_single_wheel_suspension(wheel)
		_do_single_wheel_acceleration(wheel)
		_do_single_wheel_traction(wheel)
	_do_steering_cheat()
	if tricknoise == 1 and (wheels_left_contact + wheels_right_contact) > 0:
		$SoundController/Flippu.play()
		tricknoise = 0

	
func _process(delta: float) -> void:
	_sounds()
	_camera()
	_turret_aiming()
	_hud()

func _cannon() -> void:
	var tankshell = TankShell.instantiate()
	tankshell.global_transform = $Turret/Gun/GunSpawn.global_transform
	tankshell.linear_velocity = $Turret/Gun/GunSpawn.global_basis.y * -1 * 100
	add_sibling(tankshell)
	print("pew")

func _turret_aiming() ->void:
	$Turret.rotation.y = $CameraPivot.rotation.y - global_rotation.y + deg_to_rad(180)
	$Turret/Gun.rotation.x = clampf(-$CameraPivot.rotation.x, deg_to_rad(-35.00), deg_to_rad(15.00))
	
func _camera() -> void:
	#holyshitfixthislmao
	var offset = Vector3(0,2.435,0)
	var camp = $CameraPivot
	camp.global_position = self.global_position + offset
	camp.global_rotation.y = self.global_rotation.y + cam_y_rot
	camp.orthonormalize()
	$HUD/SubViewportContainer/SubViewport/Node3D.global_transform = global_transform

func _sounds() -> void:
	if abs(motor_input_left) + abs(motor_input_right) == 2:
		$SoundController/ThrottleFull.volume_db = -4.0
		$SoundController/ThrottleHalf.volume_db = -80.0
		$SoundController/ThrottleIdle.volume_db = -80.0
	elif abs(motor_input_left) + abs(motor_input_right) == 1:
		$SoundController/ThrottleFull.volume_db = -80.0
		$SoundController/ThrottleHalf.volume_db = -4.0
		$SoundController/ThrottleIdle.volume_db = -80.0
	else:
		$SoundController/ThrottleFull.volume_db = -80.0
		$SoundController/ThrottleHalf.volume_db = -80.0
		$SoundController/ThrottleIdle.volume_db = -4.0
	if abs(prior_left_input) + abs(prior_right_input) < abs(motor_input_left) + abs(motor_input_right):
		pass
		#$SoundController/WindUp.play()
	if abs(prior_left_input) + abs(prior_right_input) > abs(motor_input_left) + abs(motor_input_right):
		pass
		#$SoundController/WindDown.play()
	prior_left_input = motor_input_left
	prior_right_input = motor_input_right
	var rpm_s = _calculate_rpm() + 400
	var engine_s_ratio = (rpm_s / max_engine_rpm) / 5
	$SoundController/ThrottleFull.pitch_scale = engine_s_ratio + .8
	$SoundController/ThrottleHalf.pitch_scale  = engine_s_ratio + .8
	$SoundController/ThrottleIdle.pitch_scale  = engine_s_ratio + .8
	if prior_gear != current_gear:
		$SoundController/GearS.pitch_scale = randf_range(0.9,1.2)
		$SoundController/GearS.play()
	prior_gear = current_gear

	
func _do_steering_cheat() -> void:
	var steer_amount = 160000*0
	var steer_direction = motor_input_right - motor_input_left
	var wheel_contact_steer = (wheels_left_contact + wheels_right_contact) / (wheels_left + wheels_right + 1.0)
	var steer_force = steer_amount * steer_direction * wheel_contact_steer
	self.constant_torque = (Vector3(0,-steer_force,0))

func _do_single_wheel_traction(ray: RaycastWheel) -> void:
	if not ray.is_colliding(): return
	
	var steer_side_dir = ray.global_basis.x
	var tire_vel = _get_point_velocity(ray.wheel.global_position)
	var steering_x_vel = steer_side_dir.dot(tire_vel)
	var x_traction = 1.0
	var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
	var x_force = -steer_side_dir * steering_x_vel * x_traction * ((mass * gravity)/wheels_total)
	
	var f_vel = -ray.global_basis.z.dot(tire_vel)
	var z_traction = 0.05
	if motor_input_left + motor_input_right == 0:
		z_traction = .5
	else:
		z_traction = 0.05
	var z_force = global_basis.z * f_vel * z_traction * ((mass * gravity)/wheels_total)
	
	var force_pos = ray.wheel.global_position - global_position
	apply_force(x_force, force_pos)
	apply_force(z_force, force_pos)
	
func _do_single_wheel_contact_math(ray: RaycastWheel) -> void:
	wheels_left_contact = 0
	wheels_right_contact = 0
	if ray.is_colliding():
		if ray.is_motor_left:
			wheels_left_contact += 1
		if ray.is_motor_right:
			wheels_right_contact += 1

func _do_single_wheel_acceleration(ray: RaycastWheel) -> void:
	var forward_dir = -ray.global_basis.z
	var vel = forward_dir.dot(linear_velocity)
	var wheel_left_ratio: float = ((wheels_left + 1.0) / (wheels_left_contact + 1.0)) * (1.0 / (wheels_left + 1.0))
	var wheel_right_ratio: float = ((wheels_right + 1.0) / (wheels_right_contact + 1.0)) * (1.0 / (wheels_right + 1.0))
	ray.wheel.rotate_x((-vel * get_process_delta_time()) / ray.wheel_radius)
	
	if ray.is_colliding():
		var contact = ray.wheel.global_position
		var force_pos = contact - global_position
		if ray.is_motor_left and motor_input_left:
			var speed_ratio = vel / max_speed
			var ac = accel_curve.sample_baked(speed_ratio)
			var force_vector = forward_dir * acceleration * wheel_left_ratio * motor_input_left * ac
			apply_force(force_vector, force_pos)
		if ray.is_motor_right and motor_input_right:
			var speed_ratio = vel / max_speed
			var ac = accel_curve.sample_baked(speed_ratio)
			var force_vector = forward_dir * acceleration * wheel_right_ratio * motor_input_right * ac
			apply_force(force_vector, force_pos)

func _get_point_velocity(point: Vector3) -> Vector3:
	return linear_velocity + angular_velocity.cross(point - global_position)

func _do_single_wheel_suspension(ray: RaycastWheel) -> void:
	if ray.is_colliding():
		ray.target_position.y = -(ray.rest_dist + ray.wheel_radius + ray.over_extend)
		var contact = ray.get_collision_point()
		var spring_up_dir = ray.global_transform.basis.y
		var spring_len = ray.global_position.distance_to(contact) - ray.wheel_radius
		var offset = ray.rest_dist - spring_len
		
		ray.wheel.position.y = -spring_len + 0.125
		
		var world_vel = _get_point_velocity(contact)
		var relative_vel = spring_up_dir.dot(world_vel)
		var spring_damp_force = ray.spring_damping * relative_vel
		var spring_force = ray.spring_strength * offset
		
		var force_vector = (spring_force  - spring_damp_force) * ray.get_collision_normal()
		
		contact = ray.wheel.global_position
		var force_pos_offset = contact - global_position
		apply_force(force_vector, force_pos_offset)
	else:
		ray.target_position.y = -(ray.rest_dist + ray.wheel_radius + ray.over_extend)
		var contact = ray.get_collision_point()
		var spring_up_dir = ray.global_transform.basis.y
		var spring_len = ray.rest_dist
		var offset = ray.rest_dist - spring_len
		
		ray.wheel.position.y = -spring_len + 0.125
		
		var world_vel = _get_point_velocity(contact)
		var relative_vel = spring_up_dir.dot(world_vel)
		var spring_damp_force = ray.spring_damping * relative_vel
		var spring_force = ray.spring_strength * offset
		
		var force_vector = (spring_force  - spring_damp_force) * ray.get_collision_normal()
		
		contact = ray.wheel.global_position
		var force_pos_offset = contact - global_position

func _on_body_entered(body: Node) -> void:
	if abs(linear_velocity.x) > impact_speed or abs(linear_velocity.y) > impact_speed or abs(linear_velocity.z) > impact_speed:
		#$SoundController/Impact.play()
		pass

func _tread_spawner() -> void:
	var length = $LeftPath.curve.get_baked_length()
	var tread_length = 0.1
	var gap = -0.01
	var copies = snapped((length / (tread_length + gap)),1)
	var ratio_dist = 1.00 / (copies - 1)
	for i in copies:
		var copy = $LeftPath/PathFollow3D.duplicate()
		$LeftPath/PathFollow3D.progress_ratio = i * ratio_dist
		$LeftPath.add_child(copy)
		var copy2 = $RightPath/PathFollow3D.duplicate()
		$RightPath/PathFollow3D.progress_ratio = i * ratio_dist
		$RightPath.add_child(copy2)

func _tread_mess() -> void:
	var gap = 0.175
	var LeftTread = $LeftPath.get_children()
	var RightTread = $RightPath.get_children()
	var tread_length = 0.12
	var length_l = $LeftPath.curve.get_baked_length()
	var gap_l = -0.01
	var copies_l = snapped((length_l / (tread_length + gap_l)),1)
	var ratio_dist_l = 1.00 / (copies_l - 1)
	var length_r = $LeftPath.curve.get_baked_length()
	var gap_r = -0.01
	var copies_r = snapped((length_r / (tread_length + gap_r)),1)
	var ratio_dist_r = 1.00 / (copies_r - 1)
	var left_lead = $LeftPath/PathFollow3D
	var right_lead = $RightPath/PathFollow3D
	step = to_local(global_position) - to_local(old_position)
	old_position = global_position
	
	left_lead.progress += step.z
	right_lead.progress += step.z
	var counter = 0
	for i in LeftTread:
		counter += 1
		i.progress_ratio = left_lead.progress_ratio + (counter * ratio_dist_l)
	for i in RightTread:
		counter += 1
		i.progress_ratio = right_lead.progress_ratio + (counter * ratio_dist_r)
	$LeftPath.curve.set_point_position(11, Vector3(0,$Left2/Wheel.position.y - gap, 1.777))
	$LeftPath.curve.set_point_position(12, Vector3(0,$Left3/Wheel.position.y - gap, 0.965))
	$LeftPath.curve.set_point_position(0, Vector3(0,$Left4/Wheel.position.y - gap, 0.214))
	$LeftPath.curve.set_point_position(1, Vector3(0,$Left5/Wheel.position.y - gap,-0.540))
	$LeftPath.curve.set_point_position(2, Vector3(0,$Left6/Wheel.position.y - gap,-1.300))
	$LeftPath.curve.set_point_position(3, Vector3(0,$Left7/Wheel.position.y - gap,-2.140))
	
	$RightPath.curve.set_point_position(11, Vector3(0,$Right2/Wheel.position.y - gap, 1.777))
	$RightPath.curve.set_point_position(12, Vector3(0,$Right3/Wheel.position.y - gap, 0.965))
	$RightPath.curve.set_point_position(0, Vector3(0,$Right4/Wheel.position.y - gap, 0.214))
	$RightPath.curve.set_point_position(1, Vector3(0,$Right5/Wheel.position.y - gap,-0.540))
	$RightPath.curve.set_point_position(2, Vector3(0,$Right6/Wheel.position.y - gap,-1.300))
	$RightPath.curve.set_point_position(3, Vector3(0,$Right7/Wheel.position.y - gap,-2.140))

func _hud() -> void:
	var hudspeed: float = clampf(self.linear_velocity.length(),0,100)
	var hudspeedratio: float = (72.0 - -248.0) / 100.0
	$HUD/SpNeed.rotation = deg_to_rad(-248 + (hudspeed * hudspeedratio))
