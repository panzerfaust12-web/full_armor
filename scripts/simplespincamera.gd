extends Node3D

#Camera Variables
@export var click_pos = Vector3.ZERO
var camera: Camera3D = null
var cam_y_rot: float = 0
@export_range(1, 100, 1) var mouse_sensitivity: int = 25
@export var max_pitch : float = 89
@export var min_pitch : float = -89

func _ready() -> void:
	camera = find_child("MainCamera")

func _process(delta: float) -> void:
	_camera()
	
#PROCESS FUNCTIONS
func _camera() -> void:
	var offset = Vector3(0,2.435,0)
	var camp = $CameraPivot
	camp.global_position = self.global_position + offset
	camp.global_rotation.y = self.global_rotation.y + cam_y_rot
	camp.orthonormalize()

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

func _unhandled_input(event: InputEvent) -> void:
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
