extends Node3D

var parent: Component_Gun

func _ready() -> void:
	parent = get_parent()

func _process(delta: float) -> void:
	$Ammo.text = "Ammo: " + str(parent.magazine_count_loaded)
	if parent.reloaded:
		$Reload.text = "Reload: " + str(float(int($"../Reload".wait_time*100.0)/100.0))
	else:
		$Reload.text = "Reload: " + str(float(int($"../Reload".time_left*100.0)/100.0))
	$Bloom.text = "Bloom: " + str(int(parent.dispersion_bloom_percent * 100.0))
