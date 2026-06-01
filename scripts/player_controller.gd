extends Node3D

#Camera Variables
@export var click_pos = Vector3.ZERO
var camera: Camera3D = null
var cam_y_rot: float = 0
@export_range(1, 100, 1) var mouse_sensitivity: int = 25
@export var max_pitch : float = 89
@export var min_pitch : float = -89

#Control Stuff
var motor_input_right: int = 0
var motor_input_left: int = 0

var tank = null
var pause_menu: Node = null

func _ready() -> void:
	camera = find_child("MainCamera")
	var mco = get_parent().find_child("MainCameraPivot")
	if mco != null:
		find_child("CameraPivot").global_position.y = mco.global_position.y
	tank = get_parent()
	if tank.get_class() != "RigidBody3D": queue_free()
	pause_menu = find_child("Pause_Menu")
	var camp = $CameraPivot
	camp.global_position = self.global_position
	camp.global_rotation.y = self.global_rotation.y
	

func _process(delta: float) -> void:
	_camera(delta)
	
	

func _physics_process(delta: float) -> void:
	pass
	
#INPUT
func _unhandled_input(event: InputEvent) -> void:
	#if event.is_action_pressed("tread_right_forward"):
		#tank.motor_input_right = 1
	#elif event.is_action_released("tread_right_forward"):
		#tank.motor_input_right = 0
	#if event.is_action_pressed("tread_right_backward"):
		#tank.motor_input_right = -1
	#elif event.is_action_released("tread_right_backward"):
		#tank.motor_input_right = 0
	#if event.is_action_pressed("tread_left_forward"):
		#tank.motor_input_left = 1
	#elif event.is_action_released("tread_left_forward"):
		#tank.motor_input_left = 0
	#if event.is_action_pressed("tread_left_backward"):
		#tank.motor_input_left = -1
	#elif event.is_action_released("tread_left_backward"):
		#tank.motor_input_left = 0
	#
	#if event.is_action_pressed("jumppu"):
		#tank.apply_impulse(global_basis.y * tank.mass * 4)
	#if event.is_action_pressed("flippu"):
		#tank.apply_impulse(global_basis.y.normalized() * tank.mass * 3,global_basis.x * 5)
		#await get_tree().create_timer(0.2).timeout
	#
	#if event.is_action_pressed("engine_toggle"):
		#tank.engine_toggle = not tank.engine_toggle
	
	
	#if event.is_action_pressed("click"):
		#shoot_ray()
	
	
	
	#CAMERA FUNCTIONS
	if event.is_action_pressed("camera_toggle"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion: Vector2 = event.relative
		var degrees_per_unit: float = 0.001
		motion *= mouse_sensitivity
		motion *= degrees_per_unit
		$CameraPivot.global_rotation.x += deg_to_rad(-motion.y)
		$CameraPivot.global_rotation.x = clamp($CameraPivot.global_rotation.x, deg_to_rad(min_pitch),deg_to_rad(max_pitch))
		cam_y_rot += deg_to_rad(-motion.x)
	if event.is_action("scroll_forward"):
		camera.position.z -= .25
	if event.is_action("scroll_back"):
		camera.position.z += .25
	if Input.is_key_pressed(KEY_UP):
		camera.position.y += 0.25
	if Input.is_key_pressed(KEY_DOWN):
		camera.position.y -= 0.25
	if Input.is_key_pressed(KEY_RIGHT):
		camera.position.x += .25
	if Input.is_key_pressed(KEY_LEFT):
		camera.position.x -= .25
	

#PROCESS FUNCTIONS
func _camera(delta) -> void:
	var offset = Vector3(0,0,0)
	var camp = $CameraPivot
	camp.global_position = lerp(camp.global_position, self.global_position + offset, delta * 10.0)
	camp.global_rotation.y = lerp_angle(camp.global_rotation.y, self.global_rotation.y + cam_y_rot, delta * 10.0)
	camp.orthonormalize()
#	$HUD/SubViewportContainer/SubViewport/Node3D.global_transform = global_transform



#ACTIONED FUNCTIONS
#Shoot raycast from var camera
func shoot_ray():
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_length = 10000
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * ray_length
	var space = get_world_3d().direct_space_state
	var ray_query = PhysicsRayQueryParameters3D.new()
	ray_query.from = from
	ray_query.to = to
	var raycast_result = space.intersect_ray(ray_query)
	if !raycast_result.is_empty():
		click_pos = raycast_result.position
