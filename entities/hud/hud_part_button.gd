extends MarginContainer
var part_load
@onready var button = $Button
signal part_selected(part)

func _ready() -> void:
	if part_load == null:
		print("BUTTON LOADED NULL")
		return
	$PartSnapshotter.part_load = part_load
	$PartDescriptionContainer2/PartDescription.text = $PartSnapshotter.part.short_name


func _on_button_button_down() -> void:
	part_selected.emit($PartSnapshotter.part)
	pass # Replace with function body.
