extends Node3D
class_name Component_SuspensionOLD

#These are for components
@export var price: int = 1000 #arbitrary
@export var weight: int = 500 #kg
@export var ideal_weight_capacity: int = 5000 #kg
@export var maximum_weight_capacity: int = 12000 #kg
@export var track_width_max: int = 500 #mm
@export var track_ground_length: int = 4000 #mm
@export_enum("Clutch:1","Differential:2","Twin Transmission:3","Double Differential:4","Electric:5") var steering_type: int
@export var length: int = 200 #mm
@export var width: int = 200
@export var depth: int = 200
@export var long_name: String = "Super Fucking Annoying Suspension: Take 1 (of 4)"
@export var short_name: String = "SUS01"
@export var description: String = "This suspension was the fucking death of me I swear"

#These are things to make this fucked choo-choo train work
@export var track_flex: float = 12
var track_thickness: float = 0.05
var track_length: float
var track_ratio_dist: float
var treads: Array
var curvepath: Array
var wheelpin: Array
var counterpin: Array
var wheels: Array
var old: float = 0
var treadcount = 0
var trackstartlength: float = 0.0
var counters: float = 0.0
var tread_length = 0.182
var gap = -0.07
var copies: int = 0
var points: int = 0
var previewerspeed: float = 0.005

var old_position = Vector3.ZERO
var step = Vector3.ZERO

func _ready() -> void:
	$Path.curve.up_vector_enabled = false 
	#wrangle the fuckers
	curvepath = $PathContainer.get_children()
	points = $PathContainer.get_child_count()
	
	#generate blank curve
	for i in points:
		$Path.curve.add_point(curvepath[i].position * Vector3(0,1,1))
		#$Path.curve.set_point_position(index,i.position)
		#$Path.curve.set_point_tilt(index,i.rotation.x+deg_to_rad(180))
		if curvepath[i].Attachment != null:
			wheelpin.append(curvepath[i])
		if curvepath[i].Counter:
			counterpin.append(curvepath[i])
		curvepath[i].ypos = curvepath[i].position.y
		curvepath[i].Index = i
	
	#write the track length, number of tracks, and convert to a ratio for later
	track_length = $Path.curve.get_baked_length()
	
	copies = snapped((track_length / (tread_length + gap)),1)

	track_ratio_dist = track_length / copies
	
	#draw the rest of the fucking owl
	for i in copies:
		var copy = $Path/PathFollow3D.duplicate()
		$Path/PathFollow3D.progress = i * track_ratio_dist
		$Path.add_child(copy)
		treadcount += 1
	treads = $Path.get_children()
	trackstartlength = $Path.curve.get_baked_length()
	counters -= 1
	counters = max(counters,1)
	wheels = find_children("*","RaycastWheel",1,0)
	
	$Path.curve.up_vector_enabled = true
	
	#
	##Previwer Node because fuck:this:curve
	#$Previewer.visible = true
	#if get_node_or_null(^"Previewer") != null and get_parent().name != "root":
		#$Previewer.queue_free()
		#previewerspeed = 0
		
	#let's make a pizza pie
	#for wheel in wheels:
		#if wheel.is_suspension:
			#$CollisionShape3D.position = wheel.position
			#add_child($CollisionShape3D.duplicate())
	#$CollisionShape3D.queue_free()
	
	
	#unused curve smoothing potential
	#_curve_smoother($Path.curve)
	
#func _curve_smoother(curve: Curve):
	#var index = 0
	#for i in points: 
		#curve.set_point_left_mode(index,0)
		#curve.set_point_right_mode(index,0)
		#index += 1
		
		
		
		
	
func _process(delta: float) -> void:
	_audio(delta)

func _physics_process(delta: float) -> void:
	track_length = $Path.curve.get_baked_length()
	_suspension_bend()
	_tread_progress()
	
func _tread_progress() -> void:
	track_ratio_dist = track_length / copies
	var index = 0
	
	step = to_local(global_position) - to_local(old_position)
	old_position = global_position
	
	#$Path/PathFollow3D.progress += previewerspeed
	#will need to be changed to meet wheel RPM at some point?
	$Path/PathFollow3D.progress += step.z
	
	for i in treads:
		if index != 0:
			i.progress = $Path/PathFollow3D.progress + (track_ratio_dist * index)
		index += 1

func _suspension_bend() -> void:
	var bend = 0
	for i in wheelpin:
		i.position.y = i.Attachment.position.y + i.Attachment.wheel_y_pos - i.Attachment.wheel_radius + track_thickness
		#$Path.curve.set_point_position(i.Index, i.position)
		bend += i.Attachment.rest_dist + i.Attachment.wheel_y_pos
	
	bend = bend / track_flex
	
# THIS IS A FUCKING MESSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS
# I HATE THISAAAAAAAAAAAAAAAAAAAHHHHHHHHHHHHHHHHHHHHHHHHHH
	#for i in counterpin:
		##if bend > 0.06: c.position.y = lerp(c.position.y, c.ypos - bend, 1)
		##else: c.position.y = lerp(c.position.y, c.ypos, 1)
		#i.position.y = lerp(i.position.y, i.ypos - bend, get_process_delta_time() * 10)
		#$Path.curve.set_point_position(i.Index, i.position)
	#$Path.curve.set_point_out(0,curvepath[1].position)
	#$Path.curve.set_point_in(0,curvepath[curvepath.size()-1].position)
	
func _audio(delta) -> void:
	var volume_mod = clampf(abs(step.z) / 0.05,0,1.0)
	#var pitch_mod = clampf(abs(step.z) / 0.075,0.9,1.1)
	if abs(step.z) < 0.01:
		$Moving.volume_linear = lerp($Moving.volume_linear,0.0,delta)
	if not abs(step.z) < 0.01:
		if not $Moving.playing: $Moving.play()
		#$Moving.pitch_scale = lerp($Moving.pitch_scale,pitch_mod,delta)
		$Moving.volume_linear = lerp($Moving.volume_linear,0.25*volume_mod,delta)
