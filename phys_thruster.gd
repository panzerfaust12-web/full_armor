extends Node3D

@export_category("Thruster")
@export_custom(PROPERTY_HINT_NONE, "suffix:N^s2") var thrust_force: float = 100.0
@export_range(0.0, 100.0, 0.1) var throttle: float = 0.0
@export var on: bool = false
@export var sound_toggle: bool = false

var parent: Node3D = null
var yscale: float = 0.0
var prior_on: bool = false #this is sTUPID
var debugarrow

func grab_parent(): # Looks three layers up for first RigidBody3D. If none found, report and kill self.
	# Probably a way smarter way of doing this.
	if get_parent().get_class() == "RigidBody3D":
		parent = get_parent()
		return
	if get_parent().get_parent().get_class() == "RigidBody3D":
		parent = get_parent().get_parent()
		return
	if get_parent().get_parent().get_parent().get_class() == "RigidBody3D":
		parent = get_parent().get_parent().get_parent()
		return
	print("PHYS_THRUSTER FOUND NO PARENT")
	print(self)
	queue_free()
	
func _ready() -> void:
	yscale = $ThrustOrigin.scale.y
	grab_parent()

func _process(delta: float) -> void:
	$ThrustOrigin.scale.y = yscale * (throttle / 100.0)
	
	if throttle == 0:
		$ThrustOrigin.hide()
		if sound_toggle:
			$Loop.stop()
		on = false
	else:
		on = true
		$ThrustOrigin.show()
		if sound_toggle:
			if not $Loop.playing:
				$Loop.seek(randf_range(0.0,9.0))
				$Loop.play()
	if sound_toggle:
		if on != prior_on and on:
			$Start.play()
	
	prior_on = on
	

	
func _physics_process(delta: float) -> void:
	if on:
		var thrust = throttle * thrust_force / 100.0
		var up = global_basis.y.normalized()
		var thrust_applied_force = thrust * up
		var thrust_location = $ThrustOrigin.global_position - parent.global_position
		parent.apply_force(thrust_applied_force, thrust_location)
		
	debug()
	
func debug():
	if Input.is_key_pressed(KEY_KP_ADD):
		throttle = clamp(throttle + (60.0 * get_process_delta_time()), -100.0, 100.0)
	if Input.is_key_pressed(KEY_KP_SUBTRACT):
		throttle = clamp(throttle - (60.0 * get_process_delta_time()), -100.0, 100.0)
	if Input.is_key_pressed(KEY_KP_MULTIPLY):
		throttle = 100.0
	if Input.is_key_pressed(KEY_KP_DIVIDE):
		throttle = 0.0
		
	var thrust = throttle * thrust_force / 100.0
	var up = global_basis.y.normalized()
	var thrust_applied_force = thrust * up
	var thrust_location = $ThrustOrigin.global_position - parent.global_position
	#DebugDraw3D.draw_arrow_ray($ThrustOrigin.global_position,-up,thrust / parent.mass,Color.BLUE_VIOLET,0.25,1)
	
	
	DebugDraw2D.set_text("aa throttle",throttle)
	DebugDraw2D.set_text("aa thrust",thrust)
	DebugDraw2D.set_text("aa thrust_location",thrust_location)
		
