extends Node
# https://blog.febucci.com/2025/08/how-to-dynamically-scale-font-size-in-godot/

var base_font_size : int
var base_size : Vector2
var button : Button

func _enter_tree():
	button = get_parent() as Button
	base_size = button.size
	base_font_size = button.get_theme_font_size("font_size", button.get_class())
	button.resized.connect(set_text_size)

func _exit_tree():
	button.resized.disconnect(set_text_size)

func set_text_size():
	var new_size = button.size
	var scale = new_size.x / base_size.x
	var scaled_size :int= floor(base_font_size * scale)
	if scaled_size>4096:
		return
	button.resized.disconnect(set_text_size)
	button.add_theme_font_size_override("font_size", scaled_size)
	button.resized.connect(set_text_size)
