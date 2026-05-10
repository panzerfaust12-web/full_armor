extends Node3D

func _ready() -> void:
	$GPUParticles3D.restart()
	$GPUParticles3D.one_shot = true

func _on_lifetime_timeout() -> void:
	queue_free()

func align_bullet(bullet_from: Vector3):
	$From_Carrier.look_at(bullet_from, Vector3.UP, true)
	$From_Carrier.rotation.z = randf_range(-PI, PI)
