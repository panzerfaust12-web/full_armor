extends ShapeCast3D
class_name Shapecast_Sus_Wheel

#Desc
#This component is a suspension wheel for a set of tracks, only.
#Provides spring forces for it's parent. Provides counter forces to other physics objects.

#Wheel Properties
@export var spring_max_force: float = 8000.0
@export var spring_stiffness: float = 1000.0
@export var spring_damping: float = 250.0
@export var spring_compression: float = 50.0
@export var spring_relaxation: float = 50.0
@export var spring_length: float = 0.25
@export var wheel_radius: float = 0.25

#Type
@export var wheel_visible: bool = true
@export var is_suspension: bool = true

var wheel: Node = null

var track_thickness: float = 0.05
var spring_prior_position: float = 0.0

var contact: Vector3
var prior_contact: Vector3
var spring_target_length: float
var offset: float
var target_length: float

var force_pos: Vector3

#Spring Forces
var spring_force: float
var spring_vel: float
var contact_vel: float
var spring_damp_f: float
var suspension_force: float
var y_force: Vector3
var tire_vel: Vector3
var up
var debug: bool = false

var distance_to_ground: float = 0


func _ready() -> void:
	up = get_parent().global_basis.y
	if not is_suspension: return
	shape.radius = wheel_radius
	target_position.x = -(spring_length + wheel_radius)
	spring_prior_position = spring_length
	wheel = get_node_or_null("Wheel")

func apply_wheel_physics(vehicle: RigidBody3D) -> void:
	if not is_suspension: return
	apply_suspension_forces(vehicle)

func apply_suspension_forces(vehicle: RigidBody3D) -> void:
	target_position.x = -(spring_length + wheel_radius)
	target_length = get_closest_collision_safe_fraction() * -target_position.x
	
	if not is_colliding():
		spring_target_length = spring_length
		if wheel_visible:
			wheel.position.x = lerp(wheel.position.x,-spring_target_length - wheel_radius + track_thickness,get_physics_process_delta_time() * 10)
		return
	
	#From here, the wheel raycast is colliding
	spring_target_length = clampf(target_length - wheel_radius,0.0,spring_length)
	
	contact = global_position + (global_basis.x * -(target_length))
	
	force_pos = contact - vehicle.global_position
	
	#Spring Forces
	offset = 1.0 - (spring_target_length / max(spring_length,0.01))
	spring_force = spring_stiffness * offset
	spring_force = min(spring_force,spring_max_force)
	tire_vel = vehicle._get_point_velocity(contact)
	spring_damp_f = spring_damping * up.dot(tire_vel)
	suspension_force = (spring_force - spring_damp_f)
	y_force = suspension_force * vehicle.global_basis.y #* up #get_collision_normal(0)

	vehicle.apply_force(y_force, force_pos)
	
	spring_prior_position = spring_target_length
	prior_contact = contact
	
	if wheel_visible:
		wheel.position.x = lerp(wheel.position.x,-target_length,get_physics_process_delta_time() * 10)
		
	distance_to_ground = (global_basis.x * -(target_length)).length()+wheel_radius+wheel_radius
	
	#for i in get_collision_count():
		#var col = get_collider(0)
		#var norm = get_collision_normal(0)
		#if col is RigidBody3D:
			#var force = -y_force * norm
			#force.clampf(-vehicle.mass,vehicle.mass)
			#col.apply_force(force, force_pos)
	
	if debug: DebugDraw3D.draw_arrow_ray(contact,y_force/vehicle.mass, y_force.length()/vehicle.mass,Color.GREEN,0.05,false,0)

func get_suspension_average_position() -> Vector3:
	if not is_suspension: contact = global_position + (global_basis.x * -(wheel_radius))
	return contact

func get_suspension_average_normal() -> Vector3:
	var norm = get_collision_normal(0)
	return norm
