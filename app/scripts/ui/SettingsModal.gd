extends Control
class_name SettingsModal
## Модальное окно настроек: звуки, вибрация, информация о разработчике.

signal closed

const MODAL_W := 700.0
const MODAL_H := 800.0

var _backdrop: ColorRect
var _card: PanelContainer
var _sounds_btn: Button
var _vibration_btn: Button
var _fx_btn: Button
var _sounds_on: bool = true
var _vibration_on: bool = true


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 220
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()


func _build_ui() -> void:
	_backdrop = ColorRect.new()
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.color = Color(0.0, 0.0, 0.0, 0.62)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_backdrop.gui_input.connect(_on_backdrop_input)
	add_child(_backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_card = PanelContainer.new()
	_card.custom_minimum_size = Vector2(MODAL_W, MODAL_H)
	_card.add_theme_stylebox_override("panel", GameTheme.booster_modal_body())
	center.add_child(_card)

	var wood := Control.new()
	wood.set_script(load("res://scripts/ui/shop/BoosterModalWood.gd"))
	wood.set_anchors_preset(Control.PRESET_FULL_RECT)
	wood.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(wood)

	var outer := MarginContainer.new()
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 24)
	outer.add_theme_constant_override("margin_right", 24)
	outer.add_theme_constant_override("margin_top", 48)
	outer.add_theme_constant_override("margin_bottom", 24)
	_card.add_child(outer)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 16)
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	outer.add_child(body)

	var header := PanelContainer.new()
	header.custom_minimum_size = Vector2(0, 56)
	header.add_theme_stylebox_override("panel", GameTheme.booster_modal_header())
	body.add_child(header)

	var header_row := HBoxContainer.new()
	header_row.set_anchors_preset(Control.PRESET_FULL_RECT)
	header_row.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_child(header_row)

	var header_label := Label.new()
	header_label.text = "НАСТРОЙКИ"
	header_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_label.add_theme_font_size_override("font_size", 34)
	header_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	header_label.add_theme_color_override("font_outline_color", Color(0.18, 0.10, 0.06, 0.90))
	header_label.add_theme_constant_override("outline_size", 6)
	header_row.add_child(header_label)

	var close_button := Button.new()
	close_button.text = "✕"
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.custom_minimum_size = Vector2(48, 48)
	close_button.add_theme_font_size_override("font_size", 30)
	close_button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	var close_style := GameTheme.booster_modal_close()
	close_button.add_theme_stylebox_override("normal", close_style)
	close_button.add_theme_stylebox_override("hover", close_style)
	close_button.add_theme_stylebox_override("pressed", close_style)
	close_button.add_theme_stylebox_override("focus", close_style)
	close_button.pressed.connect(hide_modal)
	header_row.add_child(close_button)

	_sounds_btn = _make_setting_row(body, "🔊  Звуки")
	_sounds_btn.pressed.connect(_on_sounds_pressed)

	_vibration_btn = _make_setting_row(body, "📳  Вибрация")
	_vibration_btn.pressed.connect(_on_vibration_pressed)

	_fx_btn = _make_setting_row(body, VisualFxService.quality_row_title())
	_fx_btn.pressed.connect(_on_fx_pressed)

	var sep := ColorRect.new()
	sep.custom_minimum_size = Vector2(520, 3)
	sep.color = Color(0.55, 0.34, 0.22, 0.45)
	body.add_child(sep)

	var about_title := Label.new()
	about_title.text = "Starvein: Frontier Protocol"
	about_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	about_title.add_theme_font_size_override("font_size", 28)
	about_title.add_theme_color_override("font_color", Color(0.28, 0.16, 0.10))
	body.add_child(about_title)

	var about_dev := Label.new()
	about_dev.text = "Разработчик: kv4nt"
	about_dev.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	about_dev.add_theme_font_size_override("font_size", 24)
	about_dev.add_theme_color_override("font_color", Color(0.38, 0.22, 0.14))
	body.add_child(about_dev)

	var about_contact := Label.new()
	about_contact.text = "Связь: github.com/kv4nt · support@starvein.game"
	about_contact.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	about_contact.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	about_contact.custom_minimum_size = Vector2(560, 0)
	about_contact.add_theme_font_size_override("font_size", 22)
	about_contact.add_theme_color_override("font_color", Color(0.45, 0.28, 0.18))
	body.add_child(about_contact)

	var version_lbl := Label.new()
	version_lbl.text = "v1.0.4 · Godot 4.7"
	version_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version_lbl.add_theme_font_size_override("font_size", 20)
	version_lbl.add_theme_color_override("font_color", Color(0.52, 0.36, 0.26))
	body.add_child(version_lbl)


func _make_setting_row(parent: VBoxContainer, title: String) -> Button:
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(560, 72)
	row.add_theme_stylebox_override("panel", GameTheme.shop_product_card())
	parent.add_child(row)

	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 18)
	pad.add_theme_constant_override("margin_right", 14)
	pad.add_theme_constant_override("margin_top", 10)
	pad.add_theme_constant_override("margin_bottom", 10)
	row.add_child(pad)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	pad.add_child(hbox)

	var label := Label.new()
	label.text = title
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color(0.18, 0.22, 0.34))
	hbox.add_child(label)

	var btn := Button.new()
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(128, 48)
	hbox.add_child(btn)
	return btn


func _style_toggle_button(btn: Button, enabled: bool) -> void:
	if enabled:
		btn.text = "ВКЛ"
		GameTheme.apply_shop_price_button(btn)
	else:
		btn.text = "ВЫКЛ"
		GameTheme.apply_game_over_secondary_button(btn)


func _style_fx_button(btn: Button) -> void:
	btn.text = VisualFxService.quality_button_label()
	if VisualFxService.quality == VisualFxService.Quality.FULL:
		GameTheme.apply_shop_price_button(btn)
	elif VisualFxService.quality == VisualFxService.Quality.REDUCED:
		GameTheme.apply_shop_price_button(btn)
	else:
		GameTheme.apply_game_over_secondary_button(btn)


func open() -> void:
	var vp := get_viewport().get_visible_rect().size
	var w := minf(MODAL_W, vp.x * 0.92)
	var h := minf(MODAL_H, vp.y * 0.78)
	_card.custom_minimum_size = Vector2(w, h)

	_sounds_on = AudioService.sounds_enabled
	_vibration_on = GameState.vibration_enabled
	_style_toggle_button(_sounds_btn, _sounds_on)
	_style_toggle_button(_vibration_btn, _vibration_on)
	_style_fx_button(_fx_btn)
	visible = true
	move_to_front()


func hide_modal() -> void:
	visible = false
	closed.emit()


func _on_sounds_pressed() -> void:
	_sounds_on = not _sounds_on
	_style_toggle_button(_sounds_btn, _sounds_on)
	AudioService.set_sounds_enabled(_sounds_on)
	if _sounds_on:
		AudioService.play_sfx(&"tap")
		AudioService.play_music(&"menu_music")


func _on_vibration_pressed() -> void:
	_vibration_on = not _vibration_on
	_style_toggle_button(_vibration_btn, _vibration_on)
	GameState.set_vibration_enabled(_vibration_on)
	if _vibration_on:
		GameState.vibrate_handheld(35)


func _on_fx_pressed() -> void:
	VisualFxService.cycle_visual_fx_quality()
	_style_fx_button(_fx_btn)
	AudioService.play_sfx(&"tap")


func _on_backdrop_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		hide_modal()
