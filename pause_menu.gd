extends Control

var speeds: Array[float] = [1.5, 1.0, 0.5, 0.25, 0.1, 0.01]
var speed_in: int = 1

@onready var physics_fps: float = Engine.physics_ticks_per_second

var reset_pos: Vector3
var reset_rotation: Vector3

var world: Sky3D

var hours: float
var minutes: float
var seconds: float
var timestring: String
var vehicle: Controller_Vehicle

func _ready() -> void:
	world = get_tree().get_first_node_in_group("WorldEnvironment") 
	vehicle = get_parent().get_parent()
	if vehicle == null: return
	reset_pos = vehicle.global_position
	reset_rotation = vehicle.global_rotation

	

func _process(delta: float) -> void:
	if world == null:return
	hours = float(int(world.current_time))
	minutes = (world.current_time - int(world.current_time)) * 60.0
	seconds = (minutes - int(minutes)) * 60.0
	timestring = "%02d:%02d:%02d" % [hours, minutes, seconds]
	$MarginContainer/VBoxContainer/Time.text = timestring
	$MarginContainer/VBoxContainer/Current.text = Time.get_time_string_from_system()
	
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
	world.minutes_per_day = wrapf(world.minutes_per_day + 5, 0, 60)
	print(world.minutes_per_day)

func _on_sunmove_pressed() -> void:
	world.current_time = round(world.current_time + 1.0)
	print(world.current_time)


func _on_game_speed_pressed() -> void:
	speed_in = wrapi(speed_in + 1,0,speeds.size())
	Engine.time_scale = speeds[speed_in]
	Engine.physics_ticks_per_second = physics_fps * speeds[speed_in]
	print(speeds[speed_in])


func _on_load_pressed() -> void:
	if vehicle is Controller_Vehicle:
		vehicle.load_build()
	pass # Replace with function body.


func _on_reset_position_pressed() -> void:
	vehicle.global_position = reset_pos
	vehicle.global_rotation = reset_rotation
	vehicle.linear_velocity = Vector3.ZERO
	vehicle.angular_velocity = Vector3.ZERO


func _on_save_game_pressed() -> void:
	GlobalVariables.save_game()


func _on_load_game_pressed() -> void:
	GlobalVariables.load_game()


func _on_delete_save_pressed() -> void:
	GlobalVariables.delete_save()


func _on_speak_pressed() -> void:
	var voices = DisplayServer.tts_get_voices_for_language("en")
	var voice_id = voices[0]
	DisplayServer.tts_stop()
	DisplayServer.tts_speak($Camera/VBoxContainer/Words.text,voice_id)
