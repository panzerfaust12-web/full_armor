extends VehicleBody3D



@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
#@onready var playercamera = get_tree().get_nodes_in_group("CameraTest").front()


var target_pos: Vector3
var has_target: bool = false
@export var SPEED: float = 0.0
@export var ROTAT: float = 50000
#var wheels = [$FL,$FR,$BL,$BR]

func _ready() -> void:
	pass
	#has_target = false
	#target_pos = playercamera.click_pos
	
func _physics_process(delta: float) -> void:
	return
	#var click_pos = playercamera.click_pos
	#if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		#if click_pos != target_pos:
			#target_pos = click_pos
			#has_target = true
	
	#if has_target:
		#nav_agent.target_position = target_pos
		#var next_path_pos = nav_agent.get_next_path_position()
		#var direction = global_position.direction_to(next_path_pos)
		#if global_position.distance_to(direction) < 100:
			#SPEED = 20000 * global_position.distance_to(direction) / 100
		#else:
			#SPEED = 20000
		#for w in wheels:
			#engine_force = SPEED
			#brake = 0
		#
		#var target_dir = (global_position - next_path_pos).normalized()
		#var target_r = atan2(target_dir.x,target_dir.z) - global_rotation.y
		#var ROTAT2 = ROTAT
		#if abs(rad_to_deg(target_r)) > 45:
			#ROTAT2 = ROTAT / 2
		#elif abs(rad_to_deg(target_r)) > 90:
			#ROTAT2 = ROTAT / 4
		#constant_torque.y = sign(target_r) * ROTAT2
	#
		#
		#
		#if nav_agent.is_navigation_finished():
			#has_target = false
			#constant_torque.y = 0
			#for w in wheels:
				#engine_force = 0
				#brake = 20000
				#
	
	
