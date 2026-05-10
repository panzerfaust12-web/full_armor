extends Node3D
class_name Component_Bullet
var component_name: String = "Bullet"

#Drag Table Credit: https://github.com/dbookstaber/pyballistic/blob/master/pyballistic/drag_tables.py

@export var price: int = 1000 #arbitrary
@export var weight: float = 0.0485992 #kg
@export var length: int = 2000 #mm
@export var width: int = 2000
@export var depth: int = 2000
@export var diameter: float = 12.7 #mm
@export_enum("AP:1","HE:2","APHE:3") var bullet_type: int = 1
@export_enum("G7:0", "G1:1", "G2:2", "G5:3", "G6:4","G8:5", "GI:6", "GS:7", "RA4:8") var ballistic_model: int = 0
@export var muzzle_velocity: float = 1000.0 #m/s at 1m gun length; find calc for this later
@export var max_distance: float = 4000.0
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@export_enum("Raycast:1","Shapecast:2") var collision_type: int = 1
var impact_target: float = 0
var drop_target: float = 0
@export var impact: PackedScene
var exception: Node3D = null
@export var bullet_mesh: MeshInstance3D
@export var tracer_mesh: MeshInstance3D
@export var ballistic_curve: Curve
@export var ballistic_coefficient: float = 1.05

var life: float = 0

@export var debug_enabled: bool = false

#Drag Stuff
@onready var drag_a:float = PI * ((diameter * 0.5 / 1000.0) ** 2)
@onready var drag_k:float = 0.5 * 1.2250 * drag_a / weight  #1.2250 Air Density - kg/m^3
@onready var velocity: Vector2 = Vector2(muzzle_velocity, 0.0) * get_physics_process_delta_time()
@onready var spawn_location: Vector3 = global_position

func _ready() -> void:
	if collision_type == 1:
		$ShapeCast3D.queue_free()
	else:		$RayCast3D.queue_free()
	$Lifetime.wait_time = max_distance / muzzle_velocity
	$Lifetime.start()
	$RayCast3D.target_position.z = impact_target
	$RayCast3D.add_exception(exception)
	

func _process(delta: float) -> void:
	if tracer_mesh != null:
		tracer_mesh.scale.y = lerp(tracer_mesh.scale.y, muzzle_velocity / 10.0 * tracer_mesh.scale.x, delta * 100.0)
	#bullet_mesh.rotation.y += muzzle_velocity / 100.0 * delta
	if $RayCast3D.target_position.y != 0:
		$Bullet_Tilt.look_at(to_global($RayCast3D.target_position))
	$Bullet_Tilt/Bullet_Spin.rotation.z += deg_to_rad(muzzle_velocity * 10.0) * delta
	#print("SPEED FPS: " + str(velocity.length() / delta * 3.28084) + " | DROP F:" + str(int(global_position.y - spawn_location.y)*3.28084) + " | TIME:" + str(life))
	#var raycast_global_target = ($RayCast3D.target_position.x * global_basis.x) + ($RayCast3D.target_position.y * global_basis.y) + ($RayCast3D.target_position.z * global_basis.z)
	#print("SPEED: " + str(velocity.length() / delta) + " | DROP:" + str(raycast_global_target.y / delta))

func _drag(current_velocity: Vector2, delta: float):
	var velocity_length = current_velocity.length()
	var cd = ballistic_curve.sample(velocity_length / delta) / ballistic_coefficient # Length converted back to m/s
	var drag_magnitude = drag_k * cd * (velocity_length ** 2.0)
	var drag = -current_velocity.normalized() * drag_magnitude 
	return drag

func _physics_process(delta: float) -> void:
	#velocity is defined as muzzle, drop
	life += delta
	
	if collision_type == 1:
		raycast()
	else:
		shapecast()
	
	var raycast_global_target = ($RayCast3D.target_position.x * global_basis.x) + ($RayCast3D.target_position.y * global_basis.y) + ($RayCast3D.target_position.z * global_basis.z)
	DebugDraw3D.draw_arrow_ray($RayCast3D.global_position, raycast_global_target, raycast_global_target.length(), Color.RED, 0.1, 1.0, 5.0)
	
	global_position += velocity.x * -global_basis.z
	global_position += -velocity.y * Vector3.UP
	
	velocity.y += gravity * (delta ** 2.0)
	var drag = _drag(velocity,delta)
	velocity += drag

func raycast():
	$RayCast3D.target_position = $RayCast3D.to_local($RayCast3D.global_position + (Vector3.UP * -velocity.y))
	$RayCast3D.target_position.z -= velocity.x
	$RayCast3D.force_raycast_update()
	if $RayCast3D.is_colliding():
		var collider = $RayCast3D.get_collider()
		var c_point = $RayCast3D.get_collision_point()
		var c_normal = $RayCast3D.get_collision_normal()
		hit_object(collider, c_point, c_normal)
		print("DISTANCE: " + str(int((c_point-spawn_location).length())))
	#global_position = $RayCast3D.to_global($RayCast3D.target_position)

func shapecast(): #COME BACK TO
	$ShapeCast3D.target_position.z = impact_target
	$ShapeCast3D.force_shapecast_update()
	if $ShapeCast3D.is_colliding():
		var collider = $ShapeCast3D.get_collider()
		if collider is RigidBody3D:
			collider.apply_impulse(-global_basis.z * weight * muzzle_velocity,global_position - collider.global_position)
		queue_free()

func hit_object(collider:Node3D, point:Vector3, normal:Vector3):
		#DebugDraw3D.draw_arrow_ray(point,normal,10,Color.PURPLE,0.1,1,1)
		if collider is RigidBody3D:
			collider.apply_impulse(-global_basis.z * weight * muzzle_velocity,global_position - collider.global_position)
		if impact != null:
			impact_spawn(collider, point, normal)
		print("MUZZLE VELOCITY AT IMPACT:" + str(velocity.length() / get_process_delta_time()) + " | TIME ALIVE: " + str(life) + " |  GRAVITY: " + str(velocity.y / get_process_delta_time()))
		queue_free()

func impact_spawn(collider:Node3D, point:Vector3, normal:Vector3):
	var impact_fx = impact.instantiate()
	impact_fx.top_level = true
	collider.add_child(impact_fx)
	impact_fx.global_position = point
	if normal != Vector3.UP:
		impact_fx.look_at(point - normal, Vector3.UP)
	impact_fx.align_bullet(global_position)
	#DebugDraw3D.draw_sphere(point, 0.1, Color.WEB_MAROON, 2.0)
	impact_fx.top_level = false

func _on_lifetime_timeout() -> void:
	print("lived too long, RIP")
	queue_free()
