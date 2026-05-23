extends Node
# https://blog.febucci.com/2025/08/how-to-dynamically-scale-font-size-in-godot/

@export var extra_parent_up: bool = false
var base_font_size : int
var base_size : Vector2
var label : RichTextLabel
var parent : Node
var font_themes: Array[String] = ["bold_font_size","bold_italics_font_size","italics_font_size","mono_font_size","normal_font_size"]
var base_font_sizes : Dictionary[String, int]

func _enter_tree():
	await get_tree().process_frame
	if extra_parent_up:
		parent = get_parent().get_parent()
	else:
		parent = get_parent()
	label = get_parent() as RichTextLabel
	base_size = parent.size
	base_font_sizes = {}
	for theme in font_themes:
		var size = label.get_theme_font_size(theme, label.get_class())
		base_font_sizes[theme]=size
	parent.resized.connect(set_text_size)

func _exit_tree():
	if parent == null: return
	parent.resized.disconnect(set_text_size)

func set_text_size():
	var new_size = parent.size
	var scale = new_size.x / base_size.x
	parent.resized.disconnect(set_text_size)
	for theme in font_themes:
		var scaled_size: int = floor(base_font_sizes[theme] * scale)
		if scaled_size > 4096:
			print("new size too biggggggggggg")
			return
		label.add_theme_font_size_override(theme, scaled_size)
	parent.resized.connect(set_text_size)
