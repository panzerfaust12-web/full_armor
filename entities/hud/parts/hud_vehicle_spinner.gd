extends Node3D
var child = null

func _process(delta: float) -> void:
	child = get_child(0)
	if child == null:
		return
	child.rotation.y += delta * deg_to_rad(60)
	
