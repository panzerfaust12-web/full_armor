@tool
extends SubViewport

func _ready() -> void:
	size = $Label.size
func _process(delta: float) -> void:
	size = $Label.size
