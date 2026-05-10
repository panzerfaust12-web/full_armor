extends RigidBody3D
class_name Controller_Vehicle

#Vehicle Variables
var custom_COM: Vector3 = Vector3.ZERO

#Vehicle Inputs (AI and Player)
var move_forward: bool = false
var move_backward: bool = false
var move_left: bool = false
var move_right: bool = false
var brakes: bool = false
var brakes_override: bool = false
var engine_toggle: bool = false
var move_any: bool = false

#Component Carriers
var all_components: Array[Node3D] = []

var mounts: Array[Component_Mount] = []

var engine_mounts: Array[Component_Mount] = []
var transmission_mounts: Array[Component_Mount] = []
var turret_mounts: Array[Component_Mount] = []
var suspension_mounts: Array[Component_Mount] = []
var wheel_mounts: Array[Component_Mount] = []
var gun_mounts: Array[Component_Mount] = []


var hulls: Array[Component_Hull] = []
var engines: Array[Component_Engine] = []
var transmissions: Array[Component_Transmission] = []
var turrets: Array[Component_Turret] = []
var suspensions: Array[Component_Suspension] = []
var wheels: Array[Component_Wheel] = []
var guns: Array[Component_Gun] = []
var driven_suspensions: Array = []

var hull: Component_Hull = null
var engine: Component_Engine = null
var transmission: Component_Transmission = null

var null_components: bool = true

#Directions and Speeds
var up: Vector3 = Vector3.ZERO # Up Basis
var forward: Vector3 = Vector3.ZERO # Forward Basis
var side: Vector3 = Vector3.ZERO # Side Basis

var z_speed: float = 0.0 # Forward Speed
var x_speed: float = 0.0 # Side Speed
var y_speed: float = 0.0 # Up Speed

#Drive Systems
var converted_wheel_RPM: float = 0.0 
var converted_engine_RPM: float = 0.0 
var converted_engine_power: float = 0.0 # Newtons!
var combined_wheel_RPM: float = 0.0

#Owner
var ai: bool = false
var player: bool = true

@export var debug_enabled: bool = false

#Component Variable Carriers - these only need to be loaded on part change.
#Hull Variables
var hull_wheellength: float = 1400 #mm
var hull_wheelbase: float = 2100 #mm
#Engine Variables

#Suspension Variables #Work these together??
#Wheel Variables

#Transmission Variables
var steering_type: int = 1 #"Clutch:1","Differential:2","Twin Transmission:3","Double Differential:4","Electric:5"

func _ready() -> void:
	#await owner.ready
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	add_component_DEBUG()
	get_components()
	assign_component_values()
	regenerate_collisions()

func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	grab_directions()
	grab_speeds()
	air_resis()
	if null_components: return
	human_inputs()
	ai_inputs()
	detect_requests()
	vehicle_driving(delta) # Name or split transmission types?
	power_systems()

func grab_directions(): #Not actually parent directions, live directions for turning.
	up = global_basis.y
	forward = -global_basis.z
	side = global_basis.x

func grab_speeds():
	var velocity = linear_velocity + angular_velocity.cross(center_of_mass)
	z_speed = forward.dot(velocity)
	x_speed = side.dot(velocity)
	y_speed = up.dot(velocity)

func blank_components():
	all_components = []
	hulls = []
	engines = []
	transmissions = []
	turrets = []
	suspensions = []
	wheels = []
	guns = []
	
	engine_mounts = []
	transmission_mounts = []
	turret_mounts = []
	suspension_mounts = []
	wheel_mounts = []
	gun_mounts = []
	
	hull = null
	engine = null
	transmission = null
	
	driven_suspensions = []

func null_component_check():
	if hulls == []: null_components = true
	elif engines == []: null_components = true
	elif transmissions == []: null_components = true
	else: null_components = false

func get_components():
	blank_components()
	var components = find_children("*")
	for component in components:
		if component is Component_Mount:
			mounts.append(component)
			if component.accepts == "Turret": turret_mounts.append(component)
			if component.accepts == "Engine": engine_mounts.append(component)
			if component.accepts == "Transmission": transmission_mounts.append(component)
			if component.accepts == "Suspension": suspension_mounts.append(component)
			if component.accepts == "Wheel": wheel_mounts.append(component)
		if component is Component_Hull: hulls.append(component)
		if component is Component_Engine: engines.append(component)
		if component is Component_Transmission: transmissions.append(component)
		if component is Component_Turret: turrets.append(component)
		if component is Component_Suspension: suspensions.append(component)
		if component is Component_Wheel: wheels.append(component)
		if component is Component_Gun: guns.append(component)
	
	all_components.append_array(hulls)
	all_components.append_array(engines)
	all_components.append_array(transmissions)
	all_components.append_array(turrets)
	all_components.append_array(suspensions)
	all_components.append_array(wheels)
	all_components.append_array(guns)
	
	null_component_check()
	if null_components: return
	
	hull = hulls[0]
	engine = engines[0]
	transmission = transmissions[0]
	
	hull.parent = self
	engine.parent = self
	transmission.parent = self
	
	for component in all_components:
		component.parent = self
	for wheel in wheels:
		if wheel.engine_driven:
			driven_suspensions.append(wheel)
	for suspension in suspensions:
		if suspension.engine_driven:
			driven_suspensions.append(suspension)

func assign_component_values():
	#Clear Weight Calcs
	mass = 1.0
	custom_COM = Vector3.ZERO
	
	#Calculated Mass
	for component in all_components:
		mass += component.weight
	mass -= 1.0
	
	#Calculated COM
	for component in all_components:
		custom_COM += to_local(component.global_position) * (component.weight / mass)
	center_of_mass = custom_COM
	$COM_Ball.position = center_of_mass

func regenerate_collisions():
	var owned_collisions: Array = find_children("*","CollisionShape3D",0,0) # Nuke any direct collisions still existing.
	for ow in owned_collisions:
		ow.queue_free()

	var collisions: Array = find_children("*","CollisionShape3D",1,0) # Find all collisions, duplicate them in place (without adding to array), steal originals.
	for cm in collisions:
		cm.get_parent().add_child(cm.duplicate())
		cm.reparent(self, 1)




#func get_mounts(): NOT NEEDED - GET COMPONENTS DOES THIS
func add_component(mount:Component_Mount,component: PackedScene):
	if mount == null:
		print("TRIED TO ADD TO NULL MOUNT")
		print(self)
		return
	if component == null:
		print("TRIED TO ADD NULL TO MOUNT")
		print(self)
		return
	var mounted = component.instantiate()
	if mount.accepts != mounted.component_name:
		print("TRIED TO ASSIGN WRONG PART TO WRONG MOUNT, DIPSHIT LMAO, FUCKIN GOTTEM")
		return
	mount.add_child(mounted)
	mounted.owner = mounted.get_parent()
	mounted.parent = self
	get_components()


func add_component_DEBUG():
	if name != "Vehicle": return #This is debug stuff
	add_component($Mount_Hull,load("res://entities/hull/hull03_test_wv2000.tscn"))
	add_component(wheel_mounts[0],load("res://entities/wheel/wheel02_wz2000.tscn"))
	add_component(wheel_mounts[1],load("res://entities/wheel/wheel02_wz2000.tscn"))
	add_component(wheel_mounts[2],load("res://entities/hull/hull03_test_wv2000.tscn"))
	add_component(engine_mounts[0],load("res://entities/engine/engine03_test_wv2000.tscn"))
	add_component(transmission_mounts[0],load("res://entities/transmission/trans01_test.tscn"))
	
	
	
# NEED CODE FOR WHEELS TO RE-GENERATED PARENT WHEELS? OR PARENT DOES THIS AND CALLS BACK?
func add_component_DEBUG1(): #mount: Component_Mount, component: PackedScene
	var component = load("res://entities/hull/hull03_test_wv2000.tscn")
	var mount = get_node_or_null("Mount_Hull")
	if mount == null: return
	var mounted = component.instantiate()
	mount.add_child(mounted)
	mounted.owner = mounted.get_parent()
	mounted.parent = self
	
	component = load("res://entities/wheel/wheel02_wz2000.tscn")
	var mmounts = find_children("Mount_Wheel*")
	mounted = component.instantiate()
	for m in mmounts:
		mounted = component.instantiate()
		m.add_child(mounted)
		mounted.owner = mounted.get_parent()
		mounted.parent = self
		
	component = load("res://entities/engine/engine03_test_wv2000.tscn")
	mmounts = find_children("Mount_Engine*")
	mounted = component.instantiate()
	for m in mmounts:
		mounted = component.instantiate()
		m.add_child(mounted)
		mounted.owner = mounted.get_parent()
		mounted.parent = self
	
	component = load("res://entities/transmission/trans01_test.tscn")
	mmounts = find_children("Mount_Transmission*")
	mounted = component.instantiate()
	for m in mmounts:
		mounted = component.instantiate()
		m.add_child(mounted)
		mounted.owner = mounted.get_parent()
		mounted.parent = self
	

func air_resis():
	var r: float = 1.2250 #Air Density - kg/m^3
	var Cd: float = 1.0 #Drag Coeffcient; review shapes, weird. 1.28 = Flat, 0.5 = Sphere. 1.14 = Prism.
	var Cl: float = 1.0 #Lift/Down Coefficient
	var V: float = (Vector2(z_speed, x_speed).length()) ** 2 #Linear Velocity, Flat, ^2
	var A: float = 0.25 #Frontal Area of Parent
	var force_equation = 0.5 * r * V * A
	var down_force = Cl * force_equation
	var drag_force = Cd * force_equation
	down_force = clampf(down_force,0.0,mass / 2.0)

	var momentum = -Vector3(linear_velocity.x, 0.0, linear_velocity.z).normalized()
	#@warning_ignore("unused_variable")
	var downforce_applied = down_force * Vector3.DOWN
	var drag_force_applied = drag_force * momentum
	
	apply_central_force(downforce_applied)
	apply_central_force(drag_force_applied)
	#if debug_enabled:
	#DebugDraw3D.draw_arrow_ray(global_position, Vector3.UP, down_force, Color.GOLD,0.05,0)
	#DebugDraw3D.draw_arrow_ray(global_position, drag_force_applied.normalized(), drag_force, Color.GOLD,0.05,0)
	#DebugDraw2D.set_text("down_force",down_force)
	#DebugDraw2D.set_text("drag_force",drag_force)

func detect_requests():
	if move_forward or move_backward or move_left or move_right: move_any = true
	else: move_any = false

func vehicle_driving(delta: float) -> void:
	var reverse: bool = false
	
	if null_components:
		return
		
	if not engine.on and (move_forward or move_backward):
		engine.on = true
		
	if not move_forward and not move_backward:
			engine.throttle = 0.0
			engine.clutch = 1.0
			brakes = false
	
	if move_forward:
		reverse = false
		if transmission.current_gear < 0:
			engine.throttle = 0.0
			engine.clutch = 1.0
		if transmission.current_gear > 0:
			engine.throttle = 1.0
			engine.clutch = 0.0
		if z_speed < -0.02:
			brakes = true
			engine.clutch = 1.0
			engine.throttle = 0.0
		else:
			brakes = false
	
	if move_backward:
		reverse = true
		if transmission.current_gear > 0:
			engine.throttle = 0.0
			engine.clutch = 1.0
		if transmission.current_gear < 0:
			engine.throttle = 1.0
			engine.clutch = 0.0
		if z_speed > 0.02:
			brakes = true
			engine.clutch = 1.0
			engine.throttle = 0.0
		else:
			brakes = false
	
	if brakes_override:
		brakes = true
		engine.clutch = 1.0
	
	for wheel in wheels:
		wheel.brakes_on = brakes
		wheel.turn_wheelwidth = hull_wheellength
		wheel.turn_wheellength = hull_wheelbase
		wheel.turn_left = move_left
		wheel.turn_right = move_right
		
	for suspension in suspensions:
		suspension.brakes_on = brakes
		suspension.turn_left = move_left
		suspension.turn_right = move_right
		
		
	if not brakes: #somehing something don't shift right away after breaking so that you can burn out >:3
		transmission.gear_shift(engine.RPM, engine.RPM_shift_up, engine.RPM_shift_down, reverse, engine.on)

func power_systems():
	var sus_count = max(float(roundi(driven_suspensions.size() / 2.0)), 1.0)
	if not engine.on or transmission.current_gear == 0 or brakes:
		for ds in driven_suspensions:
			ds.RPM_engine_incoming = 0.0
			ds.engine_max_force = 0.0
			combined_wheel_RPM = 0.0
	else:
		for ds in driven_suspensions:
			ds.RPM_engine_incoming = converted_engine_RPM
			ds.engine_max_force = converted_engine_power
			combined_wheel_RPM += abs(ds.RPM_wheel_outgoing)
	engine.RPM_incoming = converted_wheel_RPM
	
	combined_wheel_RPM /= 2.0
	
	
	engine.RPM_incoming = converted_wheel_RPM
	
	converted_wheel_RPM = transmission.convert_wheel_rpm(combined_wheel_RPM)
	converted_engine_RPM = transmission.convert_engine_rpm(engine.RPM) / sus_count * (1 - engine.clutch)
	converted_engine_power = transmission.convert_engine_torque(engine.output_power) / driven_suspensions.size() * (1 - engine.clutch) / max(z_speed, 1.0)
	
	if engine_toggle: engine.on = false
	
	if debug_enabled:
		DebugDraw2D.set_text("1. engine RPM", engine.RPM)
		DebugDraw2D.set_text("2. KPH", z_speed * 3.6)
		DebugDraw2D.set_text("2. MPH", z_speed * 2.23694)
		DebugDraw2D.set_text("3. Gear",transmission.current_gear)
		DebugDraw2D.set_text("3. Gearin",transmission.combined_ratio)
		DebugDraw2D.set_text("4. Brakes",brakes)
		DebugDraw2D.set_text("4. E T",engine.throttle)
		DebugDraw2D.set_text("4. E C",engine.clutch)
		DebugDraw2D.set_text("5. Sus Count",sus_count)
		DebugDraw2D.set_text("converted_wheel_RPM",converted_wheel_RPM)
		DebugDraw2D.set_text("converted_engine_RPM",converted_engine_RPM)
		DebugDraw2D.set_text("converted_engine_power",converted_engine_power)

func human_inputs():
	if not player:
		return
	move_forward = Input.is_action_pressed("movement_forward")
	move_backward = Input.is_action_pressed("movement_backward")
	move_left = Input.is_action_pressed("movement_left")
	move_right = Input.is_action_pressed("movement_right")
	brakes_override = Input.is_action_pressed("jumppu")
	engine_toggle = Input.is_action_just_pressed("flippu")
	
	
	#double tap stuff to think about?
	#const DOUBLETAP_DELAY = .25
	#var doubletap_time = DOUBLETAP_DELAY
	#var last_keycode = 0
	#
	#func _process(delta):
		#doubletap_time -= delta
		#
	#func _input(event):
		#if event is InputEventKey and event.is_pressed():
			#if last_keycode == event.keycode and doubletap_time >= 0: 
				#print("DOUBLETAP: ", String.chr(event.keycode))
				#last_keycode = 0
			#else:
				#last_keycode = event.keycode
			#doubletap_time = DOUBLETAP_DELAY

func ai_inputs():
	if not ai:
		return
	pass
