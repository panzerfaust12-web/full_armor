extends AudioStreamPlayer3D
var playing_once: bool = false
var play_once: bool = false

func _process(delta: float) -> void:
	if not play_once: return
	if play_once and not playing_once:
		play()
		playing_once = true
	if play_once and playing_once and not playing:
		queue_free()
