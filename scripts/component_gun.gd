extends Node3D
class_name Component_Gun
var component_name: String = "Gun"

signal gun_fired

#Base Component Stuff
@export var price: int = 1000 #arbitrary
@export var weight: int = 5000 #kg
@export var length: int = 2000 #mm
@export var width: int = 2000
@export var depth: int = 2000
@export var long_name: String = "Issa Gun 1907"
@export var short_name: String = "IG1907"
@export var description: String = "pew pew pew mudafuckah"

#Gun Specific Stuff
@export var rate_of_fire: float = 240.0 #RPM
@export_enum("Single:1","Burst:2","Automatic:3") var firing_type: int = 1
@export var caliber: float = 20 #mm
@export var magazine_size: int = 5
@export var magazine_reload_time: float = 5.0
var magazine_count_loaded: int = 1

#Dispersion Stuff
@export var dispersion_mil_horizontal: float = 8.0
@export var dispersion_mil_vertical: float = 8.0
@export var dispersion_bloom_penalty_percent: float = 500.0
@export var dispersion_time_to_bloom: float = 2.5
@export var dispension_time_to_center: float = 2.5
var dispersion: Vector2 = Vector2.ZERO #Calculated from vert and horz
var dispersion_bloomed: Vector2 = Vector2.ZERO
var dispersion_bloom_percent: float = 0
var dispersion_bloom_shot_impact: float = 0
@export var debug: bool = false


#this shit moved to bullet?
@export var projectile_mass: float = 3.0
@export var projectile_speed: float = 870
@export var recoil_dampening: float = 0.25
@export var debug_key: Key


var recoil: float = 1.0
var fired: bool = false
var first_fire: bool = true
var reloaded: bool = true


@export var bullet: PackedScene

var parent: RigidBody3D

func _ready() -> void:
	if caliber >= 20:
		component_name = "Cannon"
	if parent == null:
		parent = GlobalFunctions.grab_rigid_parent(self)
	if parent == null: print("CANNON MISSING PARENT")
	$RateOfFire.wait_time = 60.0 / rate_of_fire
	$FirstFire.wait_time = $RateOfFire.wait_time * 2.0
	recoil = projectile_mass * projectile_speed * max(1 - recoil_dampening,0.0)
	dispersion = Vector2(dispersion_mil_vertical * 0.000982, dispersion_mil_horizontal * 0.000982)
	dispersion_bloom_shot_impact = (1 / (rate_of_fire / 60.0 * dispersion_time_to_bloom)) + (1 / (rate_of_fire / 60.0 * dispension_time_to_center)) 
	magazine_count_loaded = magazine_size
	$Reload.wait_time = magazine_reload_time

func _physics_process(delta: float) -> void:
	dispersion_bloomed = dispersion + ((dispersion_bloom_penalty_percent * dispersion_bloom_percent / 100.0) * dispersion)
	
	if magazine_count_loaded < 1 and $Reload.is_stopped():
		reloaded = false
		fired = false
		$Reload.start()
	
	if not fired:
		dispersion_bloom_percent = clampf(dispersion_bloom_percent - (delta / dispension_time_to_center), 0.0, 1.0)
		
	if not reloaded:
		return
	
	if debug:
		if firing_type == 1:
			if Input.is_key_pressed(debug_key) and not fired:
				fire()
			if not Input.is_key_pressed(debug_key):
				fired = false
		if firing_type == 3:
			if Input.is_key_pressed(debug_key):
				if $RateOfFire.is_stopped():
					if $FirstFire.is_stopped():
						$RateOfFire.wait_time = randf_range(0, $RateOfFire.wait_time)
						$FirstFire.start()
					else:
						$RateOfFire.wait_time = 60.0 / rate_of_fire
					$RateOfFire.start()
					$FirstFire.start()
					fire()
			else: fired = false


func fire():
	gun_fired.emit()
	fired = true
	var new_pew = $Sound_Firing.duplicate()
	new_pew.pitch_scale = randf_range(0.95,1.05)
	new_pew.play_once = true
	add_child(new_pew)
	if parent != null:
		await get_tree().create_timer(0.01,0,1,0).timeout
		parent.apply_impulse($BarrelExit.global_basis.z * recoil,$BarrelExit.global_position - parent.global_position)
	if bullet != null:
		var nbullet = bullet.instantiate()
		nbullet.exception = parent
		nbullet.global_transform = $BarrelExit.global_transform
		nbullet.rotation.y += randf_range(-dispersion_bloomed.y,dispersion_bloomed.y)
		nbullet.rotation.x += randf_range(-dispersion_bloomed.x,dispersion_bloomed.x)
		add_sibling(nbullet)
	dispersion_bloom_percent = clampf(dispersion_bloom_percent + dispersion_bloom_shot_impact, 0.0, 1.0)
	magazine_count_loaded -= 1
	


func _on_reload_timeout() -> void:
	magazine_count_loaded = magazine_size
	reloaded = true
