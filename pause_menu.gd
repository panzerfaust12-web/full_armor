extends Control

var speeds: Array[float] = [1.5, 1.0, 0.5, 0.25, 0.1, 0.01]
var speed_in: int = 1

@onready var physics_fps: float = Engine.physics_ticks_per_second


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if get_tree().paused:
			hide()
			if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			get_tree().paused = false
		else:
			show()
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			get_tree().paused = true

func _on_resume_pressed() -> void:
	get_tree().paused = false
	self.hide()
	

func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_camera_pressed() -> void:
	var cam = get_viewport().get_camera_3d()
	if cam.projection == 0:
		cam.projection = 1
		cam.size = 10.0
		print("ORTHO")
	elif cam.projection == 1:
		cam.projection = 2
		cam.size = 0.1
		print("FRUST")
	else:
		cam.projection = 0
		cam.size = 1.0
		print("PERS")

func _on_fov_pressed() -> void:
	var cam = get_viewport().get_camera_3d()
	if cam.projection == 0:
		cam.fov = wrapf(cam.fov+15,30,120)
		print(cam.fov)
	elif cam.projection == 1:
		cam.size = wrapf(cam.size+5,5,45)
		print(cam.size)
	else:
		cam.size = snapped(wrapf(cam.size+0.05,0.1,0.5),0.05)
		print(cam.size)


func _on_skyscale_pressed() -> void:
	var world = get_tree().get_first_node_in_group("WorldEnvironment") #get_node("../../../Skybox/WorldEnvironment")
	world.rotational_speed *= 10.0
	if world.rotational_speed <= -75: world.rotational_speed = -0.00075
	print(world.rotational_speed)

func _on_sunmove_pressed() -> void:
	var sun = get_tree().get_first_node_in_group("Sun")
	sun.rotation.x -= deg_to_rad(45)
	print(rad_to_deg(sun.rotation.x))


func _on_game_speed_pressed() -> void:
	speed_in = wrapi(speed_in + 1,0,speeds.size())
	Engine.time_scale = speeds[speed_in]
	Engine.physics_ticks_per_second = physics_fps * speeds[speed_in]
	print(speeds[speed_in])
