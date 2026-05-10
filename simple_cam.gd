extends Camera3D
var offset: Vector3 = Vector3.ZERO
var r_offset

#func _ready() -> void:
	#offset = get_parent().global_position - $"../..".global_position
	#r_offset = get_parent().global_rotation.y - $"../..".global_rotation.y
	#
#func _process(delta: float) -> void:
	#get_parent().global_position = $"../..".global_position + offset
	#get_parent().global_rotation.y = $"../..".global_rotation.y + r_offset
