extends MeshInstance3D

var material: ShaderMaterial
var noise: Image

var noise_scale: float
var wave_speed: float
var height_scale: float
var time_scale: float

var time: float

var contacts: Array = []

var depth_max: float = 100.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var float_force: float = 1.0

var water_drag: float = 0.01
var water_angular_drag: float = 0.01

var cam_underwater: bool = false
var cam_underwater_p: bool = false #STUPID FIND A CODE AROUND THIS DUMBASS????



#Water Variables
#var float_force: float = 2.5
#var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
#var water_drag: float = 0.05
#var water_angular_drag: float = 0.05
#var submerged: bool = false
#var depth_max: float = 2.5
##@onready var water: Node = $"../../NavigationRegion3D/WaterPlane"

#func _water_physics():
	#submerged = false
	#var depth = water.get_height(global_position) - global_position.y
	#DebugDraw3D.draw_sphere(global_position - Vector3(0.0,max(-depth,0.0),0.0),1.0,Color.RED)
	#depth = min(depth, depth_max)
	#if depth > 0:
		#submerged = true
		##global_position.y = water.get_height(global_position)
		#apply_central_force(Vector3.UP * float_force * gravity * depth * mass)

func _ready() -> void:
	material = get_surface_override_material(0)
	noise = material.get_shader_parameter("wave").noise.get_seamless_image(512,512)
	noise_scale = material.get_shader_parameter("noise_scale")
	wave_speed = material.get_shader_parameter("wave_speed")
	height_scale = material.get_shader_parameter("height_scale")
	time_scale = material.get_shader_parameter("time_scale")
	
func _process(delta: float) -> void:
	time += delta * time_scale
	material.set_shader_parameter("wave_time", time)
	camera_water(delta)
	sounds()
	cam_underwater_p = cam_underwater

func _physics_process(delta: float) -> void:
	if contacts == null:
		return
	for contact in contacts:
		var height = get_height(contact.global_position)# - global_position.y
		var contact_COM = PhysicsServer3D.body_get_direct_state(contact).center_of_mass_local 
		var contact_COM_aligned = contact_COM.dot(global_basis.y)
		var depth = -(contact.global_position.y - global_position.y - height - contact_COM_aligned)
		#var drag = 
		depth = min(depth, depth_max)
		#contact.global_position.y = global_position.y + depth
		if depth > 0:
			#return
			contact.linear_velocity *= (1.0 - water_drag)
			contact.angular_velocity *= (1.0 - water_angular_drag)
			contact.apply_force(Vector3.UP * gravity  * contact.mass, contact_COM)
			contact.apply_force(Vector3.UP * float_force * depth * contact.mass, contact_COM)

#some notes - this world position / noise_scale thing is a little fucky-wucky. Keeping position and scale at 512 seems clean.
func get_height(world_position: Vector3) -> float:
	var wave_time = material.get_shader_parameter("wave_time")
	var uv_x = wrapf(world_position.x / noise_scale + wave_time * wave_speed, 0.0, 1.0)
	var uv_y = wrapf(world_position.z / noise_scale + wave_time * wave_speed, 0.0, 1.0)

	var pixel_pos = Vector2(uv_x * noise.get_width(), uv_y * noise.get_height())
	return (noise.get_pixelv(pixel_pos).r * height_scale);

func camera_water(delta):
	var camera = get_viewport().get_camera_3d()
	if camera != null:
		var cube: AABB = AABB($WaterArea/CollisionShape3D.global_position - ($WaterArea/CollisionShape3D.shape.size * 0.5), $WaterArea/CollisionShape3D.shape.size)
		if cube.has_point(camera.global_position):
			var height = get_height(camera.global_position)
			var depth = -(camera.global_position.y - global_position.y - height)
			var e = get_tree().get_root().find_children("*","WorldEnvironment",1,0)
			if depth > 0.5:
				cam_underwater = true
				e[0].environment.fog_enabled = true
				$DecalHolder.position.x = wrapf($DecalHolder.position.x + (25.0 * delta),0,$DecalHolder/Decal.size.x)
			else:
				cam_underwater = false
				e[0].environment.fog_enabled = false


func sounds():
	if cam_underwater != cam_underwater_p:
		if cam_underwater:
			AudioServer.set_bus_effect_enabled(0,0,1)
			AudioServer.set_bus_effect_enabled(0,1,1)
			$Water.playing = false
			$Sounds/Underwater.playing = true
			$TextureRect.show()
			$DecalHolder.show()
			$".".mesh.flip_faces = true
			if $Sounds/AntiSpam.is_stopped():
				$Sounds/CameraEntered.play()
				$Sounds/AntiSpam.start()
				
		if not cam_underwater:
			AudioServer.set_bus_effect_enabled(0,0,0)
			AudioServer.set_bus_effect_enabled(0,1,0)
			$Water.playing = true
			$".".mesh.flip_faces = false
			$Sounds/Underwater.playing = false
			$DecalHolder.hide()
			$TextureRect.hide()
			if $Sounds/AntiSpam.is_stopped():
				$Sounds/CameraExited.play()
				$Sounds/AntiSpam.start()

func _on_water_area_body_entered(body: Node3D) -> void:
	if body is RigidBody3D:
		contacts.append(body)


func _on_water_area_body_exited(body: Node3D) -> void:
	if body is RigidBody3D:
		contacts.remove_at(contacts.find(body))
