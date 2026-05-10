extends Node

var thing = null

func _process(delta: float) -> void:
	if thing is Component_Engine:
		$"../Engine_Toggle".show()
		$"../Engine_Rev".show()
	else:
		$"../Engine_Toggle".hide()
		$"../Engine_Rev".hide()
	
func _on_engine_toggle_pressed() -> void:
	if thing != null:
		thing.on = not thing.on

func _on_engine_rev_button_up() -> void:
	if thing != null:
			thing.throttle = 0.0

func _on_engine_rev_button_down() -> void:
	if thing != null:
			thing.throttle = 1.0
