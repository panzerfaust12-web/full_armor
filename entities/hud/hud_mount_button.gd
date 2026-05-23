extends MarginContainer
class_name HUD_Mount_Button
@onready var button = $Button
signal mount_selected(mount)

var mount_load = null

func _ready() -> void:
	if mount_load == null:
		print("BUTTON LOADED NULL")
		return
	load_mount(mount_load)

func _on_button_button_down() -> void:
	if mount_load != null:
		AudioController.play_sound("ButtonClick")
		print("THE BUTTON WAS PUSHED, " + str(self.name) + " | "+str(mount_load.accepts))
		mount_selected.emit(self, mount_load.accepts)
	else:
		AudioController.play_sound("ButtonError")
		print("ERROR: No mount loaded to mount_button at " + str(self))
	pass #show/hide available parts?

func load_mount(mount: Component_Mount):
	#add_child(mount.instantiate())
	for mounts in find_children("*"):
		if mounts is Component_Mount:
			mount_load = mounts
	$PartDescriptionContainer/PartDescription.text = mount_load.accepts + " Mount"
	#$PartDescriptionContainer/PartLimits.text = str(mount_load.size_limit) + "\n" + str(mount_load.weight_limit)
	
	pass

func clear_mount():
	for mounts in find_children("*"):
		if mounts is Component_Mount:
			mounts.queue_free()
	$PartDescriptionContainer/PartDescription.text = ""
