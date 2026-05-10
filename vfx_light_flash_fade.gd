extends OmniLight3D

@export var flash_timer: float = 0.05

func _process(delta: float) -> void:
	light_energy = move_toward(light_energy, 0.0, 1.0 / flash_timer / 2.0)
	if is_zero_approx(light_energy): queue_free()
