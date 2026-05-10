extends Camera3D

@export var lerp_speed = 10.0

@onready var target = $"../CameraPositions/Node3D"

@onready var target_array = [$"../CameraPositions/Node3D",$"../CameraPositions/Node3D2",$"../CameraPositions/Node3D3"]
@onready var target_num = 0

func _physics_process(delta):
	if !target:
		return
	if target_num == 0: lerp_speed = 60.0
	else: lerp_speed = 10.0
	
	global_transform = global_transform.interpolate_with(target.global_transform, lerp_speed * delta)
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("camera_toggle"):
		target_num = wrapi(target_num + 1, 0, 3)
		target = target_array[target_num]
	if event.is_action("scroll_forward"):
		position.z -= .25
	if event.is_action("scroll_back"):
		position.z += .25
	if Input.is_key_pressed(KEY_UP):
		position.y += 0.25
	if Input.is_key_pressed(KEY_DOWN):
		position.y -= 0.25
	if Input.is_key_pressed(KEY_RIGHT):
		position.x += .25
	if Input.is_key_pressed(KEY_LEFT):
		position.x -= .25
