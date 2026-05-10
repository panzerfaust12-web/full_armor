extends Node

@onready var scroll: ScrollContainer = get_parent()
@onready var rtl: RichTextLabel = get_parent().get_child(0)

func _ready() -> void:
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rtl.autowrap_mode = TextServer.AUTOWRAP_OFF
	rtl.scroll_active = false
	rtl.fit_content = true
	rtl.bbcode_enabled = true


func _process(delta: float) -> void:
	await get_tree().create_timer(2.0).timeout
	if not scroll.scroll_horizontal >= rtl.size.x - scroll.size.x:
		scroll.scroll_horizontal += 1
		#TweenIn.interpolate_property(scroll, "scroll_horizontal", 0, 9999, 1.5, Tween.TRANS_QUAD, Tween.EASE_IN_OUT) 
	elif scroll.scroll_horizontal >= rtl.size.x - scroll.size.x:
		await get_tree().create_timer(1.5).timeout
		scroll.scroll_horizontal = 0
