extends ShapeCast3D
class_name Phys_Wheel

#Desc
#Provides the following:
#  Spring Forces (From contact, suspension forces.)
#  Friction (From contact, X/Z and adjusts for gravity.)
#  Visuals (Rotates wheel, moves it to spring.)
#  Braking (As input, disallows sliding/slipping.)
#  Engine  (As input, provides forward momentum from N/m^2.)
#  Turning (As input, rotates wheel.)

#Wheels are rotated z 90 due to shapecast fuckery, so everything is a little wonk.

#When friction is a 0.0 - 1.0, think of it as max available friction relative to parent mass/gravity/number of wheels.
#This is limited by spring forces applied at the time.

@export_category("Features")
@export var wheel_left: bool = false #Does nothing yet. Needs to flip the mesh 
@export var visuals_enabled: bool = true #Spin wheels, move wheel to spring.
@export var suspension_enabled: bool = true #Provide suspension forces. NO CODE TO NOT ALLOW THIS RIGHT NOW, A LOT RIDES ON THESE FORCES.
@export var friction_enabled: bool = true #Provides friction. Pretty important for a simulation. Not sure why to turn off?
@export var steering_enabled: bool = true #Allows steering. Without, even with input steering angles, nothing happens.
@export var engine_enabled: bool = true #Allows engine forces. Without, even with input engine forces, nothing happens.
@export var braking_enabled: bool = true #You get the picture. Brakkes.
@export_category("Wheel")
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var wheel_radius: float = 0.5
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var wheel_thickness: float = 0.5 #Wheel width might be better name.
@export_custom(PROPERTY_HINT_NONE, "suffix:") var wheel_passive_traction: float = 0.01 #Traction applied when nothing happens. 
@export_range(-45, 45, 1.0, "radians_as_degrees") var wheel_steering_angle: float = 0.0 # Wheel angle in degrees.
@export_range(-45, 45, 1.0, "radians_as_degrees") var wheel_steering_angle_max: float = deg_to_rad(45.0) #Limiter. Unused yet.

# YOU NEED TO COME BACK TO STEERING AT SOME POINT AND ACCOUNT FOR PERFECTED STEERING ANGLES BASED ON VEHICLE WIDTH
# THIS MIGHT COME FROM THE VEHICLE CONTROLLER ITSELF THOUGH, AS IT WOULD CARRY THE WIDTH
# atan(wheelbase / (turning circle - car width)) = angle

@export_custom(PROPERTY_HINT_NONE, "suffix:m") var wheel_track_height: float = 0.015 # This will be used later for tank tracks.
@export var traction_slip_ratio: Curve = null #This is a curve for wheels slipping when provided too much force (burnout.)
@export var traction_side_angle: Curve = null #This is a curve for drifting. Name sucks.
@export var reverse_turn: bool = false #This makes wheels turn the opposite intended way - not set up well yet. Used for back wheels that turn.
@export_category("Suspension")
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var spring_length: float = 0.5
@export_custom(PROPERTY_HINT_NONE, "suffix:N") var spring_force_max: float = 200.0
@export_custom(PROPERTY_HINT_NONE, "suffix:N/M") var spring_stiffness: float = 100.0 #How much N is provided per meter. Important to account for short springs.
@export_custom(PROPERTY_HINT_NONE, "suffix:N * s/M") var spring_dampening: float = 50.0 #This may need to be reviewed again.
@export_category("Engine")
@export_custom(PROPERTY_HINT_NONE, "suffix:N") var RPM_engine_incoming: float = 0.0 #How much RPM the engine is providing. Torque is handled without an export.
@export_category("Brakes")
@export var brakes_on: bool = false
@export_custom(PROPERTY_HINT_NONE, "suffix:N") var brakes_force: float = 5000.0 #Max force brakes can apply in N.
@export_category("Debug")
@export var debug_enabled: bool = false #Turns on a ton of DebugDraw3D, dynamic sizing, and text overlay.

var is_colliding_bool: bool = false #Bool'd so we don't have to call a function to check collision 3+ times per physics update.

var parent: Node3D = null # First RigidBody3D found. Only goes up three layers.
var parent_wheels: float = 0.0 # Number of wheels on parent. This may need to be reviewed when on a vehicle class.
var mass_and_wheel_multiplier: float = 0.0 # A modifier to adjust wheel's maximum target based on parent mass and number of wheels.
# ADDT on Mass/Wheel Multi - no wheel is allowed to target more force than (parent.mass * gravity) / number of wheels. Might not be needed?

var wheel_mesh: Node = null # Wheel mesh, don't show this if visuals are enabled.
var turning_origin: Node = null # Lazy origin because rotations make my head hurt.
var contact: Vector3 = Vector3.ZERO  # Contact with ground, from shapecast, based on unsafe distance length.
var contact_normal: Vector3 = Vector3.ZERO # Normal of contact with the ground, later reviewed by dot products.
var contact_velocity: Vector3 = Vector3.ZERO # Velocity at point of contact in global space.
var contact_length: float = 0.0 # Length of the contact ray. Some nuance takes place in phy_process to adjust for wheel offsets and safety margins.
var force_position: Vector3 = Vector3.ZERO # Offset of where force should be applied to parent.

var collider: Node = null # Call out the actual collider to grab friction amounts.
var collider_friction: float = 1.0 # Friction of contact body.

var up: Vector3 = Vector3.ZERO # Parent Up Basis
var s_up: Vector3 = Vector3.ZERO # Spring Up Basis
var forward: Vector3 = Vector3.ZERO # Parent Forward Basis
var side: Vector3 = Vector3.ZERO # Parent Side Basis

var gravity: float = 0.0 # Gravity, pulled from settings.

var z_speed: float = 0.0 # Forward Speed
var x_speed: float = 0.0 # Side Speed
var y_speed: float = 0.0 # Up Speed

var spring_current_length: float = 0.0 # Spring length at point in time
var spring_compression: float = 0.0 # How compressed the spring is
var spring_force: float = 0.0 # Force the spring is applying
var spring_damp_force: float = 0.0 # Dampening Force
var spring_applied_force: Vector3 = Vector3.ZERO # Spring forced applied by basis.
var shape_offset: float = 0.0 # Used to budge some local positions around and cast safety ranges. Based on wheel radius.

var x_traction_force: float = 0.0 # Raw force applied for side-to-side.
var z_traction_force: float = 0.0 # Raw force applied for forward-to-back.
var z_traction_applied_force: Vector3 = Vector3.ZERO # Side-to-side force by basis.
var x_traction_applied_force: Vector3 = Vector3.ZERO # Forward-to-back force by basis.
var zx_traction_applied_force: Vector3 = Vector3.ZERO # Combination of forces by basis.

var engine_force: float = 0.0 # Engine applied force. This is only on the z-axis, forward and back.
var engine_incoming_force: float = 0.0 # Engine actual torque applied. Cannot exceed this value. Keeps from accelerating to infinity.
var engine_applied_force: Vector3 = Vector3.ZERO # Forward to back force from engine only.

var brake_applied_force: Vector3 = Vector3.ZERO # Forward to back force from brakes only.

var RPM_wheel_free: float = 0.0 # RPM of wheel free-rolling at point in time.
var wheel_free_speed: float = 0.0 # Secondary RPM of wheel free-rolling, but modified for visuals. Done pretty messy, tbh.

var turn_right: bool = false
var turn_left: bool = false
var turn_wheellength: float = 0.0
var turn_wheelwidth: float = 0.0
var turn_speed_adjust: float = 0.0

func get_parent_point_velocity(point: Vector3) -> Vector3: # Get a velocity from a detected point.
	return parent.linear_velocity + parent.angular_velocity.cross(point - parent.global_position + parent.center_of_mass)

func grab_directions(): #Not actually parent directions, live directions for turning.
	up = global_basis.x.rotated(global_basis.y, rotation.x).normalized()
	s_up = global_basis.x.normalized()
	forward = -global_basis.z.rotated(global_basis.y, rotation.x).normalized().rotated(up,wheel_steering_angle)
	side = global_basis.y.rotated(global_basis.y, rotation.x).normalized().rotated(up,wheel_steering_angle)

func assign_sizes(): # Separate class so that if debug is enabled, can play with these live. Doesn't always play nice with wheel resize. Spring works good.
	#Offset the shapecast origin so that it doesn't get stuck in the fuckin ground
	shape_offset = wheel_radius
	
	#Assign shapecast size. Has to already be a cylinder and rotated z 90.
	shape.radius = wheel_radius
	shape.height = wheel_thickness
	
	#Assign shapecast targets. X because rotation of z 90.
	target_position.x = -spring_length - shape_offset
	
	#Set spring to max length.
	spring_current_length = spring_length

func RPM_rolling(): # Grab the free-rolling wheel RPM at point in time.
	RPM_wheel_free = (z_speed * 60) / (PI * (wheel_radius + wheel_radius))

func return_RPM_free():
	var r_speed = forward.dot(get_parent_point_velocity(global_position))
	return (r_speed * 60) / (PI * (wheel_radius + wheel_radius))

func _ready() -> void:
	#await owner.ready
	#Grab nodes.
	wheel_mesh = get_node_or_null("Turning_Origin/Wheel")
	wheel_mesh.rotation.y += deg_to_rad(randf_range(0, 360)) # Rotate the damn wheel, CJ.
	turning_origin = get_node_or_null("Turning_Origin")
	var ColZero = get_node_or_null("Col_Zero")
	var ColIllegal = get_node_or_null("Col_Illegal")
	
	if wheel_mesh == null or turning_origin == null or ColZero == null or ColIllegal == null:
		print("Saucy little freak. You forgot a critical node!")
		queue_free()
	
	
	#Assign various sizes.
	assign_sizes()
	
	#Safety offset for shapecast casting. Originally in assign_sizes()
	position.y += shape_offset 
	
	#Get the parent and parent wheels.
	if parent == null:
		parent = GlobalFunctions.grab_rigid_parent(self)
	if parent == null: return #lmao what
	parent_wheels = parent.find_children("*","Phys_Wheel",1,1).size()
	if parent_wheels == 0:
		print(self)
		print("MISSING WHEELS!!!")
		parent_wheels = 4.0
	
	#Grab directional basis to start.
	grab_directions()
	
	#Error out and kill self if you forget to assign slip ratios.
	if traction_slip_ratio == null:
		print("SLIP RATIO NOT ASSIGNED ON WHEEL")
		print(parent.to_string() + " "  + self.to_string())
		queue_free()
	if traction_side_angle == null:
		print("SIDE ANGLE NOT ASSIGNED ON WHEEL")
		print(parent.to_string() + " "  + self.to_string())
		queue_free()
	
	#Grab gravity.
	gravity = parent.get_gravity_scale() * ProjectSettings.get_setting("physics/3d/default_gravity")
	
	#Assign maximum allowed force / force multiplier for wheel.
	mass_and_wheel_multiplier = ((parent.mass * gravity) / parent_wheels)
	
	#Bake the ratios. I don't really get baking - acted wonky with non-bake samples later. Maybe not needed?
	traction_slip_ratio.bake()
	traction_side_angle.bake()
	
	#Don't hit the parent, idiot.
	add_exception(parent)
	
	if parent is Controller_Vehicle:
		$Col_Zero.position.x -= wheel_radius
		$Col_Illegal.position.x -= wheel_radius
		return
		
	#This is for dumb rigid bodies only.
	#This is copying some collisions to the parent. This disallows illegal shapecast/spring positions and contacts.
	var cmcopy = $Col_Zero.duplicate()
	cmcopy.position = (global_position - parent.global_position)
	cmcopy.position.y += -shape_offset
	cmcopy.rotation.z = (PI / 2.0)
	cmcopy.rotation.x = rotation.x
	cmcopy.name = str(name) + "_Col_Zero"
	parent.add_child.call_deferred(cmcopy)
	
	#Same thing. Review these sizes
	var cmcopy2 = $Col_Illegal.duplicate()
	cmcopy2.shape.size.x = shape_offset + wheel_radius + 0.01
	cmcopy2.shape.size.y = wheel_thickness + 0.01
	cmcopy2.shape.size.z = (wheel_radius * 2) + 0.01
	cmcopy2.position = global_position - parent.global_position
	cmcopy2.rotation.x = rotation.x
	cmcopy2.rotation.z = (PI / 2.0)
	cmcopy2.name = str(name) + "_Col_Illegal"
	parent.add_child.call_deferred(cmcopy2)
	
func reready():
	mass_and_wheel_multiplier = ((parent.mass * gravity) / parent_wheels)

#func _process(delta: float) -> void: #Dunno if visuals should go here :V
	#pass

func _physics_process(delta: float) -> void:
	is_colliding_bool = is_colliding()
	if debug_enabled: assign_sizes() # To play with spring and wheel sizes when debug is enabled.
	mass_and_wheel_multiplier = ((parent.mass * gravity) / parent_wheels)
	grab_directions()
	
	RPM_rolling()
	
	if is_colliding_bool:
		#Offsetting and trying to find two critical things - center of wheel in global space, and local space, and length thereof.
		var wheel_offset = (wheel_radius * up)
		var contact_raw_length = max((global_position - wheel_offset - get_collision_point(0)).dot(s_up), shape_offset)
		var contact_to_mid = (s_up * contact_raw_length)
		
		contact = global_position - contact_to_mid - wheel_offset
		contact_length = contact_to_mid.length()
		contact_velocity = get_parent_point_velocity(contact)
		
		#Force is being applied from center of wheel and not ground. A little cheaty, but feels better since wheel has 0 mass.
		force_position = contact - parent.global_position + wheel_offset
		
		#Maybe kick these back to individual calls for minor performance gain later.
		z_speed = forward.dot(contact_velocity)
		x_speed = side.dot(contact_velocity)
		y_speed = up.dot(contact_velocity)
		contact_normal = get_collision_normal(0)
		
		collider = get_collider(0)
		if collider is RigidBody3D or StaticBody3D:
			if collider is not Terrain3D:
				if collider.physics_material_override != null:
					collider_friction = collider.physics_material_override.friction
			else: collider_friction = 1.0
	
	suspension()
	friction()
	engine(delta)
	braking()
	steering(delta)
	visuals(delta)
	apply_forces()
	apply_opposing_forces()
	debug_forces()
	debug_controls()

func _process(delta: float) -> void:
	#audio(delta)
	pass

func apply_forces(): #Allows things to be modified before being applied by other functions.
	if not is_colliding_bool:
		return
	
	
	parent.apply_force(spring_applied_force, force_position)
	
	var combined_applied_force: Vector3 = Vector3.ZERO
	
	#Apply Forces
	zx_traction_applied_force = z_traction_applied_force + x_traction_applied_force
	
	# THIS SECTION NEEDS TO ONLY HAPPEN WHEN BRAKING, NO PLAYER INPUT, LOW SPEED
	var low_speed_modifier: float = min(0.2 / Vector2(x_speed,z_speed).length(), 1.0)
	
	# If recieving Engine Input, do not let the low-speed modifer kick in.
	if engine_incoming_force > 0: low_speed_modifier = 0

	#THIS IS FRONT SOMEHOW? SHOULD ONLY APPLY WHILE BRAKING
	zx_traction_applied_force.x -= spring_applied_force.x * low_speed_modifier
	#THIS IS SIDE
	zx_traction_applied_force.z -= spring_applied_force.z * low_speed_modifier
	
	combined_applied_force = zx_traction_applied_force + engine_applied_force + brake_applied_force
	if debug_enabled:
		if engine_applied_force.length() > spring_force: DebugDraw2D.set_text("1111. SLIPPING", spring_force)
		if engine_applied_force.length() > spring_force: DebugDraw2D.set_text("1111. B SLIPS", spring_force)
		if zx_traction_applied_force.length() > spring_force: DebugDraw2D.set_text("1111. SKIDDING", zx_traction_applied_force.length())
	combined_applied_force = combined_applied_force.limit_length(abs(spring_force * 1.0))
	
	parent.apply_force(combined_applied_force * collider_friction, force_position)
	if debug_enabled:
		DebugDraw2D.set_text("zzzzz combined_applied_force:", combined_applied_force)
		DebugDraw3D.draw_arrow_ray(contact,combined_applied_force.normalized(),combined_applied_force.length() / parent.mass,Color.WEB_MAROON,0.5,1)

func apply_opposing_forces(): # Apply inversed spring and friction forces to other rigid bodies.
	if not is_colliding_bool: # Dunno if it's faster to declare is_colliding once in main loop and use variable. Used 10 times.
		return
	if collider is RigidBody3D:
		
		var inverse_spring_force = -spring_applied_force.dot(contact_normal) * contact_normal
		var inverse_friction_force = -zx_traction_applied_force * collider_friction
		
		var inverse_forces = inverse_spring_force + inverse_friction_force
		
		collider.apply_force(inverse_forces, collider.to_local(contact))
		if debug_enabled:
			DebugDraw3D.draw_arrow_ray(contact, -inverse_forces.normalized(), inverse_forces.length() / mass_and_wheel_multiplier, Color.SKY_BLUE,0.05,0,0.5)
	pass

func suspension():
	if suspension_enabled != true:
		return
	
	# If not colliding, set target to full length, and return.
	if not is_colliding_bool:
		spring_current_length = spring_length
		return
	
	#Spring Length
	spring_current_length = contact_length - shape_offset
	spring_compression = clamp(spring_length - spring_current_length, 0.0, spring_length)
	# code a if spring velo later here for compress/relax
	spring_damp_force = spring_dampening * y_speed
	spring_force = spring_stiffness * spring_compression
	spring_force = clamp(spring_force - spring_damp_force, 0.0, spring_force_max)
	spring_applied_force = spring_force * up * s_up.dot(up) * contact_normal.dot(up)
	#if abs(x_speed) < 0.2:
	spring_applied_force.y -= gravity / parent_wheels # * up.dot(Vector3.UP) * mass_and_wheel_multiplier
	spring_applied_force.y += gravity / parent_wheels * up.dot(Vector3.UP)
	#parent.apply_force(spring_applied_force, force_position)

func friction():
	if not is_colliding_bool:
		return

	#Side to Side Traction
	var side_traction = clampf(absf(x_speed / contact_velocity.length()),0.0,1.0)
	var x_traction = traction_side_angle.sample(side_traction)
	if absf(z_speed) < 0.2:
		x_traction = 1.0
	x_traction_force = x_speed * x_traction * mass_and_wheel_multiplier
	x_traction_applied_force = -side * x_traction_force
	
	
	#Front Back Traction
	var z_traction = wheel_passive_traction
	if RPM_engine_incoming != 0.0: z_traction = 0.0
	if absf(z_speed) < 0.2:
		z_traction = 1.0
	
	z_traction_force = z_speed * z_traction * mass_and_wheel_multiplier
	z_traction_applied_force = -forward * z_traction_force

func visuals(delta):
	if not visuals_enabled: return
	if wheel_mesh == null:
		print("You're running visuals with no mesh!")
		print(self)
		return
	
	#Magic number is just a RPM to Rads thing. Drink your Rad-Away.
	var wheel_rpm_speed = RPM_engine_incoming * 0.10472 * delta
	
	
	
	#Some funny shit here. Wheel needs to spin, except when in the air, except when under engine power, except when braking.
	#Clean this up later. Bad.
	if not is_colliding_bool:
		turning_origin.position.x = move_toward(turning_origin.position.x,target_position.x,delta * 5.0)
		wheel_free_speed = move_toward(wheel_free_speed, 0.0, delta * 0.01)
	else:
		turning_origin.position.x = move_toward(turning_origin.position.x,-(shape_offset + spring_length - spring_compression),delta * 5.0)
		wheel_free_speed = z_speed * delta / (wheel_radius)
	
	if brakes_on: wheel_free_speed = 0.0

	if engine_enabled and RPM_engine_incoming > RPM_wheel_free and RPM_engine_incoming != 0.0:
		wheel_mesh.rotation.y += wheel_rpm_speed 
	else:
		wheel_mesh.rotation.y += wheel_free_speed
	return

func steering(delta):
	if not steering_enabled: return
	
	var turn: float = int(turn_left) - int(turn_right)
	if reverse_turn: turn = -turn
	var wheel_steering_goal = wheel_steering_angle_max
	
	var turn_steering_adjust = atan(turn_wheellength / ((turn_wheellength / tan(wheel_steering_angle_max)) + turn_wheelwidth))
	
	
	
	if turn != 0: turn_speed_adjust = 1.0
	
	var inner: bool = false
	if (turn > 0 and wheel_left) or (turn < 0 and not wheel_left): inner = true
	if turn_wheellength != 0 and turn_wheelwidth != 0 and not inner:
		wheel_steering_goal = turn_steering_adjust
		if turn != 0: turn_speed_adjust = turn_steering_adjust / wheel_steering_angle_max
	
	wheel_steering_angle = move_toward(wheel_steering_angle, wheel_steering_goal * turn, delta * 2.0 * turn_speed_adjust)
	
	turning_origin.rotation = Vector3(wheel_steering_angle, rotation.x, 0)

func braking():
	if not braking_enabled or not brakes_on or not is_colliding_bool:
		brake_applied_force = Vector3.ZERO
		return

	
	#This basically is trying to say - brakes can't apply more traction than spring allows, banded to max brake force in N right now.
	#var brake_force = 1.0 - wheel_passive_traction
	#
	#var brake_applied_force = clamp(abs(z_speed) * brake_traction * mass_and_wheel_multiplier, -brakes_force, brakes_force)
	#This could later be a seperate variable rather than a straight addition to friction.
	var brake_application = clamp(brakes_force * z_speed, -brakes_force, brakes_force)
	brake_applied_force = -forward * brake_application

func engine(delta):
	# Combine these into one big call?
	if not engine_enabled or brakes_on or not is_colliding_bool:
		engine_applied_force = Vector3.ZERO
		return

	#var wheel_speed = (RPM_wheel_free - RPM_engine_incoming) * (2 * wheel_radius * PI) / 60.0
	
	engine_applied_force = forward * engine_incoming_force
	#engine_applied_force += forward * wheel_speed * mass_and_wheel_multiplier
	
	# Gonna be real chief, I forgot how I got to this stuff below, but it kinda worked?
	## All this shit is dumb imo
	#var engine_factor: float = 0.0
	#if RPM_wheel_free == 0.0:
		#engine_factor = 1.0
	#elif RPM_engine_incoming == 0.0:
		#engine_factor = 0.0
	#else:
		#engine_factor = clampf(absf(RPM_engine_incoming / RPM_wheel_free), 0.0, 1.0)
	## Slip ratio to keep engine from overshooting target as well as being weaker when RPMs misaligned.
	#var engine_traction = traction_slip_ratio.sample_baked(engine_factor)
	#var wheel_speed = (RPM_wheel_free - RPM_engine_incoming) * (2 * wheel_radius * PI) / 60.0
	
	#ACCOUNT FOR NEGATIVE RPM (?)
	
	#engine_force = clamp((engine_incoming_force),-spring_force,spring_force)
	#engine_force += wheel_speed
	#if engine_max_force != 0.0: # Lets this run without engine hookups.
		#engine_force = clamp(engine_force,-engine_max_force,engine_max_force)

func debug_forces():
	if debug_enabled != true: return
	assign_sizes() #Left in debug as option to dynamically play with wheel sizes.

	# Lets you fuck with the gravity scale of the parent live.
	gravity = parent.get_gravity_scale() * ProjectSettings.get_setting("physics/3d/default_gravity")
	
	# Some DebugDraw Arrows. If you don't have this, install it. If you refuse, comment these out (same with controls.)
	if is_colliding_bool:
		#DebugDraw3D.draw_sphere(get_collision_point(0),0.25,Color.GREEN)
		DebugDraw3D.draw_sphere(contact,0.25,Color.RED)
		DebugDraw3D.draw_arrow_ray(force_position + parent.global_position, spring_applied_force.normalized(), spring_force / parent.mass, Color.LAWN_GREEN,0.05,0)
		
		if debug_enabled and name == "Phys_Wheel":
			#DebugDraw2D.set_text("1. Parent Linear Vel",parent.linear_velocity)
			#DebugDraw2D.set_text("1. Parent Linear Len",parent.linear_velocity.length())
			#DebugDraw2D.set_text("2. KPH Flat",Vector2(parent.linear_velocity.x,parent.linear_velocity.z).length()  * 3.6)
			#DebugDraw2D.set_text("speed x",x_speed)
			#DebugDraw2D.set_text("speed y",y_speed)
			#DebugDraw2D.set_text("speed z",z_speed)
			#DebugDraw2D.set_text("contact_velocity",contact_velocity)
			#DebugDraw2D.set_text("contact_velocity.length()",contact_velocity.length())
			#DebugDraw2D.set_text("spring_force",spring_force)
			##DebugDraw2D.set_text("low_speed_modifier",low_speed_modifier)
			#DebugDraw2D.set_text("zz x_traction_applied_force",x_traction_applied_force)
			#DebugDraw2D.set_text("zz ZX",zx_traction_applied_force)
			#DebugDraw2D.set_text("zzzz Wheel RPM:", RPM_wheel_free)
			#DebugDraw2D.set_text("zzzz Incoming RPM:", RPM_engine_incoming)
			#DebugDraw2D.set_text("zzzzz Spring Length:", spring_current_length)
			#DebugDraw2D.set_text("zzzzz contact_to_mid:", contact_length)
			DebugDraw2D.set_text("zzzzz engine_applied_force:", engine_applied_force)

func debug_controls(): # Enables controlling wheels without any actual controls assigned in Godot. Use your own keys below.
	if not debug_enabled:
		return
	# Main go forces and juices below. Up down left right forward back based on parent mass.
	if Input.is_key_pressed(KEY_KP_8):
		parent.apply_force(forward * mass_and_wheel_multiplier,wheel_mesh.global_position - parent.global_position)
		DebugDraw3D.draw_arrow_ray(wheel_mesh.global_position, forward, 10, Color.PURPLE,0.1)
	if Input.is_key_pressed(KEY_KP_2):
		parent.apply_force(-forward * mass_and_wheel_multiplier,wheel_mesh.global_position - parent.global_position)
		DebugDraw3D.draw_arrow_ray(wheel_mesh.global_position, -forward, 10, Color.PURPLE,0.1)
	if Input.is_key_pressed(KEY_KP_4):
		parent.apply_force(side * mass_and_wheel_multiplier,wheel_mesh.global_position - parent.global_position)
		DebugDraw3D.draw_arrow_ray(wheel_mesh.global_position, side, 10, Color.PURPLE,0.1)
	if Input.is_key_pressed(KEY_KP_6):
		parent.apply_force(-side * mass_and_wheel_multiplier,wheel_mesh.global_position - parent.global_position)
		DebugDraw3D.draw_arrow_ray(wheel_mesh.global_position, -side, 10, Color.PURPLE,0.1)
	if Input.is_key_pressed(KEY_KP_0):
		parent.apply_force(up * mass_and_wheel_multiplier,wheel_mesh.global_position - parent.global_position)
		DebugDraw3D.draw_arrow_ray(wheel_mesh.global_position, up, 10, Color.PURPLE,0.1)
	if Input.is_key_pressed(KEY_KP_PERIOD):
		parent.apply_force(-up * mass_and_wheel_multiplier,wheel_mesh.global_position - parent.global_position)
		DebugDraw3D.draw_arrow_ray(wheel_mesh.global_position, -up, 10, Color.PURPLE,0.1)
	# Engine Fake Simulation
	if Input.is_key_pressed(KEY_KP_ENTER):
		RPM_engine_incoming = 0.0
	if Input.is_key_pressed(KEY_KP_1):
		RPM_engine_incoming += 2.0
	# Brakes (duh)
	#if Input.is_key_pressed(KEY_KP_3):
		#brakes_on = true
	#else: brakes_on = false
	if steering_enabled:
		if Input.is_key_pressed(KEY_KP_5): # Silly attempt at force-wheels-to-face-camera. Kinda works.
			var cam = get_viewport().get_camera_3d()
			var cam_p = (cam.global_position + (100.0 * cam.global_basis.z)) - global_position
			cam_p = cam_p.normalized()
			var ang = rad_to_deg(atan2(cam_p.x, cam_p.z) - global_rotation.y)
			print(ang)
			var goal = wrapf(ang,-90.0,90.0)
			if not reverse_turn: wheel_steering_angle = lerp(wheel_steering_angle, deg_to_rad(goal), get_physics_process_delta_time() * 5.0)
			else: wheel_steering_angle = lerp(wheel_steering_angle, -deg_to_rad(goal), get_physics_process_delta_time() * 5.0)
		if Input.is_key_pressed(KEY_KP_7):
			if not reverse_turn: wheel_steering_angle = lerp(wheel_steering_angle, deg_to_rad(25), get_physics_process_delta_time() * 2.5)
			else: wheel_steering_angle = lerp(wheel_steering_angle, -deg_to_rad(25), get_physics_process_delta_time() * 2.5)
		if Input.is_key_pressed(KEY_KP_9):
			if not reverse_turn: wheel_steering_angle = lerp(wheel_steering_angle, -deg_to_rad(25), get_physics_process_delta_time() * 2.5)
			else: wheel_steering_angle = lerp(wheel_steering_angle, deg_to_rad(25), get_physics_process_delta_time() * 2.5)
		if not Input.is_key_pressed(KEY_KP_9) and not Input.is_key_pressed(KEY_KP_7) and not Input.is_key_pressed(KEY_KP_5):
			wheel_steering_angle = lerp(wheel_steering_angle, 0.0, get_physics_process_delta_time() * 1.0)

func audio(delta):
	if not is_colliding_bool:
		$Audio/Skidding.volume_linear = 0.0
		return
	if abs(y_speed) > 1.0 and $Audio/CompressTimer.is_stopped():
		$Audio/Compress.play()
		$Audio/CompressTimer.wait_time = 1.0+ randf()
		$Audio/CompressTimer.start()
	if zx_traction_applied_force.length() > spring_force or (brake_applied_force.length() > spring_force and brakes_on):
		$Audio/Skidding.volume_linear = move_toward($Audio/Skidding.volume_linear, 0.25, delta * 25.0)
	else: $Audio/Skidding.volume_linear = move_toward($Audio/Skidding.volume_linear, 0.0, delta * 25.0)
		
