extends RigidBody3D

#Water Variables
var float_force: float = 2.5
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var water_drag: float = 0.05
var water_angular_drag: float = 0.05
var submerged: bool = false
var depth_max: float = 2.5
#@onready var water: Node = $"../../NavigationRegion3D/WaterPlane"

#func _water_physics():
	#submerged = false
	#var depth = water.get_height(global_position) - global_position.y
	#DebugDraw3D.draw_sphere(global_position - Vector3(0.0,max(-depth,0.0),0.0),1.0,Color.RED)
	#depth = min(depth, depth_max)
	#if depth > 0:
		#submerged = true
		##global_position.y = water.get_height(global_position)
		#apply_central_force(Vector3.UP * float_force * gravity * depth * mass)
		
func _physics_process(delta: float) -> void:
	pass
	#_water_physics()


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if submerged:
		state.linear_velocity *= 1.0 - water_drag
		state.angular_velocity *= 1.0 - water_angular_drag
