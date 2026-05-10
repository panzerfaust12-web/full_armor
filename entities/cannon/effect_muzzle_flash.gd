extends Node3D
#Stay at Home Dev E28 Muzzle Flash
@export var parent: Component_Gun

@export var light: OmniLight3D
@export var emitters: Array[GPUParticles3D]

var emit_time: float = 1.0
var flash_time: float = 0.05

func _ready() -> void:
	for emitter in emitters:
		#emitter.lifetime = emit_time
		emitter.one_shot = true
		emitter.emitting = false
		
	if parent == null: return
	
	parent.gun_fired.connect(muzzle_flash)
	emit_time = min((60.0 / parent.rate_of_fire),0.01)
	flash_time = max(emit_time, 0.05)
	
func muzzle_flash() -> void:
	light.visible = true
	for emitter in emitters:
		emitter.restart()
	await  get_tree().create_timer(flash_time).timeout
	light.visible = false
	
