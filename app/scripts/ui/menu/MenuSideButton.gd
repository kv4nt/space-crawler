extends VBoxContainer
class_name MenuSideButton
## MenuSideButton — боковая кнопка с космическим свечением.

signal pressed

var _button: Button
var _badge_label: Label
var _caption_label: Label
var _accent: Color = Color(0.40, 0.78, 1.0)


func setup(
	icon: String,
	caption: String,
	badge: String = "",
	accent: Color = Color(0.40, 0.78, 1.0)
) -> void:
	_accent = accent
	add_theme_constant_override("separation", 8)
	alignment = BoxContainer.ALIGNMENT_CENTER

	_button = Button.new()
	_button.text = icon
	_button.focus_mode = Control.FOCUS_NONE
	_button.custom_minimum_size = Vector2(98, 98)
	_button.add_theme_font_size_override("font_size", 40)
	GameTheme.apply_menu_side_button(_button, _accent)
	_button.pressed.connect(func() -> void: pressed.emit())
	add_child(_button)

	if badge != "":
		_badge_label = Label.new()
		_badge_label.text = badge
		_badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_badge_label.add_theme_font_size_override("font_size", 17)
		_badge_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.35))
		_badge_label.add_theme_color_override("font_outline_color", Color(0.45, 0.08, 0.08, 0.95))
		_badge_label.add_theme_constant_override("outline_size", 5)
		_badge_label.position = Vector2(64, -4)
		_button.add_child(_badge_label)

	_caption_label = Label.new()
	_caption_label.text = caption
	_caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption_label.custom_minimum_size = Vector2(112, 0)
	_caption_label.add_theme_font_size_override("font_size", 17)
	_caption_label.add_theme_color_override("font_color", Color(0.88, 0.94, 1.0))
	_caption_label.add_theme_color_override("font_outline_color", Color(0.05, 0.10, 0.28, 0.95))
	_caption_label.add_theme_constant_override("outline_size", 4)
	add_child(_caption_label)


func set_caption(text: String) -> void:
	if _caption_label:
		_caption_label.text = text


func set_badge(text: String) -> void:
	if text == "":
		if is_instance_valid(_badge_label):
			_badge_label.visible = false
		return
	if not is_instance_valid(_badge_label):
		_badge_label = Label.new()
		_badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_badge_label.add_theme_font_size_override("font_size", 17)
		_badge_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.35))
		_badge_label.add_theme_color_override("font_outline_color", Color(0.45, 0.08, 0.08, 0.95))
		_badge_label.add_theme_constant_override("outline_size", 5)
		_badge_label.position = Vector2(64, -4)
		_button.add_child(_badge_label)
	_badge_label.text = text
	_badge_label.visible = true
