extends Node3D

@onready var parent = get_parent()
@onready var tracker = get_parent().get_parent()
@onready var offset = parent.position
@export var enabled: bool = false

func _ready() -> void:
	if not enabled:
		parent.queue_free()
	parent.global_position = tracker.global_position + offset
	parent.look_at(tracker.global_position)

func _process(delta: float) -> void:
	parent.global_position = lerp(parent.global_position, tracker.global_position + offset, delta * 50.0)
	parent.basis = parent.basis.slerp(parent.basis.looking_at(-offset), delta)
