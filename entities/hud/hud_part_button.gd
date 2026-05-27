extends MarginContainer
class_name HUD_Part_Button

var part_load
@onready var button = $Button
signal part_selected(part,mount)
var referenced_mount: Component_Mount = null

func _ready() -> void:
	if part_load == null:
		print("BUTTON LOADED NULL")
		return
	$PartSnapshotter.part_load = part_load
	$PartDescriptionContainer2/PartDescription.text = $PartSnapshotter.part.short_name


func _on_button_button_down() -> void:
	if referenced_mount == null:
		print("BUTTON WITH NO MOUNT REFERENCE")
		return
	part_selected.emit($PartSnapshotter.part,referenced_mount)
	AudioController.play_sound("ButtonClick")
	pass # Replace with function body.
