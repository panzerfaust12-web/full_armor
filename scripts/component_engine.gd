extends Node3D
class_name Component_Engine
var component_name: String = "Engine"

@export_category("Core") # These are basic, shared component value that let attachment points know what is/isn't legal.
@export var long_name: String = "Model 19 (Multibank)"
@export var short_name: String = "M19x5"
@export var description: String = "This is a test description."
@export var price: int = 1000
@export_custom(PROPERTY_HINT_NONE, "suffix:mm") var length: int = 200
@export_custom(PROPERTY_HINT_NONE, "suffix:mm") var width: int = 200
@export_custom(PROPERTY_HINT_NONE, "suffix:mm") var depth: int = 200
@export_custom(PROPERTY_HINT_NONE, "suffix:kg")  var weight: int = 2100
@export var fire_chance: float = 0.2 # Percent chance  of fire upon taking damage. Will likely need a cooldown to proc (machine guns.)
@export_category("Specific")
@export var horsepower: float = 30 # This is peak horsepower - curve at Y 1.0. Based on RPM / RPM_MAX. Will be converted to N M/s (735.49875)
@export var power_curve: Curve = null # Defines how power is produced based on RPM / RPM_MAX. 
@export var RPM_max: float = 2700 # Absolute max RPM the engine is allowed. Not the ideal range, but max safe.
@export var RPM_idle: float = 400 # RPM engine will fall to with no input at all.
@export var RPM_shift_up: float = 2400 # RPM engine will attempt to raise gears. Should be just slightly past peak power; redline zone in most cars.
@export var RPM_shift_down: float = 800 # RPM engine will attempt to drop gears. Should be pretty low. Completely arbitrary. Maybe define this as a flat point on curve.
@export var RPM_accel: float = 2700 # Max RPM generated per second, assuming neutral and no friction. Should be VERY high. 2-5x RPM Max.
@export var RPM_decel: float = 1000 # RPM lost per second, assuming neutral and no friction. Should be about 0.25-0.75 RPM Max. Not very important either.
@export var RPM_noise_array: Array = [400.0, 1000.0, 1300.0, 1500.0, 1800.0, 2100.0, 2500.0]
@export_category("Debug")
@export var debug_enabled: bool = false

var on: bool = false # Is on.
var on_prior: bool = false # Was on.

var throttle: float = 0.0 # Make engine make RPM. Gonna keep this 1 or 0 for now, but float just in case.
var clutch: float = 0.0 # Disconnect engine from vehicle systems. May not use this.

var z_rattle: float = 0.0 # A dumb little visual thing to make the engine shake when running.

var RPM: float = 0.01 # RPM
var RPM_sound: float = 0.01 #RPM for sound side to use (why?)
var RPM_incoming: float = 0.0 #RPM from Wheel or Sprocket

var newtonpower: float = 0.0 # Horsepower set to Newton M/s on ready or debug.
var output_power: float = 0.0 # Power at point in time.

var parent: Node3D = null # Rigid body parent.
var fan = null

#sounds

var RPM_noise_volume: Array = []
var RPM_noise_volume_adjust: float = 1.0


func _ready():
	if parent == null:
		parent = GlobalFunctions.grab_rigid_parent(self)
	newtonpower = horsepower * 735.49875
	power_curve.bake()
	RPM_noise_volume_adjust = $Throttle_Mix.volume_linear 
	
	z_rattle = deg_to_rad(max(5.0,15.0/horsepower/weight)) # what are we doin here
	
	for i in range(RPM_noise_array.size()):
		RPM_noise_volume.append(0.0)
	
	fan = get_node_or_null("EngineMesh/Fan_Offset/Fan")
	
func _process(delta: float) -> void:
	on_off(delta)
	engine_sounds(delta)
	visuals(delta)
	debug_controls()

func _physics_process(delta: float) -> void:
	engine(delta)

func engine(delta):
	if not on:
		RPM = max(RPM - (RPM_decel * delta), 0.0)
		output_power = 0.0
	if on:
		if throttle == 0 or clutch == 1:
			#if RPM < RPM_idle:
				#RPM += RPM_accel * delta
			if RPM > 0:
				RPM -= RPM_decel * delta
		if throttle > 0:
			RPM += RPM_accel * delta
		
		if RPM_incoming != 0.0:
			RPM += ((RPM_incoming - RPM) * (1.0 - clutch)) #* 0.02
		RPM = clampf(RPM, 0.0, RPM_max)
		
		output_power = power_curve.sample(RPM / RPM_max) * (1.0 - clutch) * newtonpower
	

func visuals(delta):
	if not on:
		return
	if not fan == null:
		var rot = max(RPM_idle, RPM)
		fan.rotation.z += wrapf(rot * 0.10472 * delta / 10.0,0,PI * 2)
	
	# Rattle Rattle
	if on and on_prior:
		$EngineMesh.rotation.z = -$EngineMesh.rotation.z + (randf_range(-z_rattle,z_rattle) * (1.0))
		$EngineMesh.rotation.z = clampf($EngineMesh.rotation.z,-z_rattle,z_rattle)

func on_off(delta):
	if not on and on_prior: #this is a one shot
		$Throttle_Mix.stop()
		$EngineMesh.rotation.z = 0.0
		$Start.stop()
		$Stop.play()
		if parent != null: parent.apply_impulse(global_basis.x * newtonpower / (weight + parent.mass) * delta / 5.0, parent.global_position - global_position)
	if on and not on_prior:
		RPM = 1.0
		$Stop.stop()
		$Start.play()
		$Throttle_Mix.play()
		$EngineMesh.rotation.z = z_rattle * ((randi() & 2)- 1)
		if parent != null: parent.apply_impulse(global_basis.x * newtonpower / (weight + parent.mass) * delta / 5.0, parent.global_position - global_position)
	on_prior = on
	
func engine_sounds(delta):
	RPM_sound = lerp(RPM_sound,RPM,delta * 10)
	RPM_sound = clamp(RPM_sound,RPM_idle,RPM_max)
	var array_count = range(RPM_noise_volume.size()-1)
	if not on:
		var index = 0
		for i in range(RPM_noise_volume.size()):
			RPM_noise_volume[index]=lerp(RPM_noise_volume[index],0.0,delta)
			index += 1
	if on and not is_zero_approx(RPM_sound):
		for i in range(RPM_noise_volume.size()):
			RPM_noise_volume[i] = 0.0
		if RPM_sound <= RPM_noise_array[0]:
			RPM_noise_volume[0] = 1.0
			RPM_noise_volume[RPM_noise_volume.size()-1] = 0.0
		if RPM_sound >= RPM_noise_array[RPM_noise_array.size()-1]: RPM_noise_volume[RPM_noise_volume.size()-1] = 1.0
		for i in array_count:
			var low = RPM_noise_array[i]
			var high = RPM_noise_array[i + 1]
			if RPM_sound >= low and RPM_sound <= high:
				var range_size = high - low
				var t = (RPM_sound - low) / range_size
				RPM_noise_volume[i] = 1.0 - t
				RPM_noise_volume[i + 1] = t
				break
		for i in range(RPM_noise_volume.size()): # Jank
			RPM_noise_volume[i] = clampf(RPM_noise_volume[i] * 1.5,0.0,1.0)
			$Throttle_Mix.stream.set_sync_stream_volume(i,linear_to_db(RPM_noise_volume[i]))



func debug_controls():
	if not debug_enabled:
		return
		
	newtonpower = horsepower * 735.49875
	power_curve.bake()
	
	if Input.is_action_just_pressed("jumppu"):
		on = not on
	if Input.is_key_pressed(KEY_KP_0):
		RPM += 5.0
		RPM = clamp(RPM, 0.0, RPM_max)
	if Input.is_key_pressed(KEY_KP_PERIOD):
		RPM -= 5.0
		RPM = clamp(RPM, 0.0, RPM_max)
	if Input.is_key_pressed(KEY_KP_7):
		throttle = 1.0
	if Input.is_key_pressed(KEY_KP_9):
		throttle = 0.0
	if Input.is_key_pressed(KEY_KP_4):
		RPM_incoming = 800.0
	if Input.is_key_pressed(KEY_KP_6):
		RPM_incoming = 0
	if Input.is_key_pressed(KEY_KP_8):
		clutch = 1.0
	if Input.is_key_pressed(KEY_KP_5):
		clutch = 0.0
