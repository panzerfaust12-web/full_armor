extends Node3D
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

var old_position = Vector3.ZERO
var step = Vector3.ZERO

func _ready() -> void:
	curvepath = $PathContainer.get_children()
	var index = 0
	$Path.curve.up_vector_enabled = false
	for i in curvepath:
		$Path.curve.add_point(i.position)
		if i.Attachment != null:
			i.Index = index
			wheelpin.append(i)
		if i.Counter:
			i.Index = index
			i.ypos = i.position.y
			counters += 1
			counterpin.append(i)
		index += 1
		i.rotation.normalized()
	var length = $Path.curve.get_baked_length()
	copies = snapped((length / (tread_length + gap)),1)
	var ratio_dist = 1.00 / (copies - 1)
	for i in copies:
		var copy = $Path/PathFollow3D.duplicate()
		$Path/PathFollow3D.progress_ratio = i * ratio_dist
		$Path.add_child(copy)
		treadcount += 1
	treads = $Path.get_children()
	trackstartlength = $Path.curve.get_baked_length()
	$Path.curve.up_vector_enabled = true

func _process(delta: float) -> void:
	$Path.curve.clear_points()
	$Path.curve.up_vector_enabled = false
	var index = 0
	for i in curvepath:
		$Path.curve.add_point(i.position)
		if i.Attachment != null:
			i.Index = index
			wheelpin.append(i)
		if i.Counter:
			i.Index = index
			i.ypos = i.position.y
			counters += 1
			counterpin.append(i)
		index += 1
	$Path.curve.up_vector_enabled = true
