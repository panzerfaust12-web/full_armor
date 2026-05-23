extends Node

var thing = null


# this needs to not be in process???
func _process(delta: float) -> void:
	if thing is Component_Engine:
		$"../Engine_Toggle".show()
		$"../Engine_Rev".show()
	else:
		$"../Engine_Toggle".hide()
		$"../Engine_Rev".hide()
	
func _on_engine_toggle_pressed() -> void:
	if thing != null:
		AudioController.play_sound("ButtonClick")
		thing.on = not thing.on
	else: AudioController.play_sound("ButtonError")

func _on_engine_rev_button_up() -> void:
	if thing != null:
		AudioController.play_sound("ButtonClick")
		thing.throttle = 0.0
	else: AudioController.play_sound("ButtonError")

func _on_engine_rev_button_down() -> void:
	if thing != null:
		AudioController.play_sound("ButtonClick")
		thing.throttle = 1.0
	else: AudioController.play_sound("ButtonError")

func _on_equip_pressed() -> void:
	if thing != null:
		AudioController.play_sound("ButtonClick")
	else: AudioController.play_sound("ButtonError")
		
