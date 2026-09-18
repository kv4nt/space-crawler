extends Control
class_name ResourcePurchaseModal
## Модальное окно покупки жизней (за монеты) или монет (за рубли) во время игры.

signal life_purchased
signal message_requested(text: String)
signal closed

const MODAL_W := 700.0
const MODAL_H := 760.0

const CREDIT_PACKS: Array = [
	{"id": "cr_1000", "amount": 1000, "price_label": "199,00 ₽"},
	{"id": "cr_2500", "amount": 2500, "price_label": "449,00 ₽"},
	{"id": "cr_5000", "amount": 5000, "price_label": "799,00 ₽"},
	{"id": "cr_10000", "amount": 10000, "price_label": "1 490,00 ₽"},
	{"id": "cr_25000", "amount": 25000, "price_label": "2 990,00 ₽"},
	{"id": "cr_50000", "amount": 50000, "price_label": "4 990,00 ₽"},
]

var _backdrop: ColorRect
var _root: Control
var _header_label: Label
var _icon_label: Label
var _icon_pad: PanelContainer
var _qty_label: Label
var _title_label: Label
var _desc_label: Label
var _life_panel: VBoxContainer
var _credits_panel: ScrollContainer
var _packs_box: VBoxContainer
var _life_buy_button: Button
var _close_button: Button
var _accent: Color = Color.WHITE


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 200
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

	_root = Control.new()
	_root.custom_minimum_size = Vector2(MODAL_W, MODAL_H)
	center.add_child(_root)

	var card := PanelContainer.new()
	card.set_anchors_preset(Control.PRESET_FULL_RECT)
	card.add_theme_stylebox_override("panel", GameTheme.booster_modal_body())
	_root.add_child(card)

	var wood := Control.new()
	wood.set_script(load("res://scripts/ui/shop/BoosterModalWood.gd"))
	wood.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wood.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(wood)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(body)

	var icon_wrap := CenterContainer.new()
	icon_wrap.custom_minimum_size = Vector2(0, 148)
	body.add_child(icon_wrap)

	_icon_pad = PanelContainer.new()
	_icon_pad.custom_minimum_size = Vector2(132, 132)
	_icon_pad.add_theme_stylebox_override("panel", GameTheme.booster_modal_icon_pad(Color.WHITE))
	icon_wrap.add_child(_icon_pad)

	_icon_label = Label.new()
	_icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_icon_label.add_theme_font_size_override("font_size", 82)
	_icon_pad.add_child(_icon_label)

	_qty_label = Label.new()
	_qty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_qty_label.add_theme_font_size_override("font_size", 38)
	_qty_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	_qty_label.add_theme_color_override("font_outline_color", Color(0.18, 0.10, 0.06, 0.95))
	_qty_label.add_theme_constant_override("outline_size", 6)
	body.add_child(_qty_label)

	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 36)
	_title_label.add_theme_color_override("font_color", Color(0.28, 0.16, 0.10))
	body.add_child(_title_label)

	var sep := ColorRect.new()
	sep.custom_minimum_size = Vector2(360, 3)
	sep.color = Color(0.55, 0.34, 0.22, 0.45)
	body.add_child(sep)

	_desc_label = Label.new()
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_desc_label.custom_minimum_size = Vector2(460, 0)
	_desc_label.add_theme_font_size_override("font_size", 26)
	_desc_label.add_theme_color_override("font_color", Color(0.45, 0.24, 0.16))
	body.add_child(_desc_label)

	_life_panel = VBoxContainer.new()
	_life_panel.alignment = BoxContainer.ALIGNMENT_CENTER
	_life_buy_button = Button.new()
	_life_buy_button.custom_minimum_size = Vector2(420, 80)
	_life_buy_button.focus_mode = Control.FOCUS_NONE
	GameTheme.apply_booster_modal_buy_button(_life_buy_button)
	_life_buy_button.pressed.connect(_on_life_buy_pressed)
	_life_panel.add_child(_life_buy_button)
	body.add_child(_life_panel)

	_credits_panel = ScrollContainer.new()
	_credits_panel.custom_minimum_size = Vector2(520, 280)
	_credits_panel.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_credits_panel.visible = false
	body.add_child(_credits_panel)

	_packs_box = VBoxContainer.new()
	_packs_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_packs_box.add_theme_constant_override("separation", 8)
	_credits_panel.add_child(_packs_box)

	for pack in CREDIT_PACKS:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(440, 64)
		btn.focus_mode = Control.FOCUS_NONE
		btn.text = "%s  —  %s" % [GameTheme.coin_gain_text(int(pack.amount)), String(pack.price_label)]
		btn.add_theme_font_size_override("font_size", 28)
		btn.add_theme_color_override("font_color", Color(0.98, 0.99, 1.0))
		GameTheme.apply_booster_modal_buy_button(btn)
		btn.pressed.connect(_on_credit_pack_pressed.bind(pack))
		_packs_box.add_child(btn)

	var header := PanelContainer.new()
	header.custom_minimum_size = Vector2(320, 0)
	header.add_theme_stylebox_override("panel", GameTheme.booster_modal_header())
	header.set_anchors_preset(Control.PRESET_CENTER_TOP)
	header.offset_left = -160.0
	header.offset_top = -18.0
	header.offset_right = 160.0
	header.offset_bottom = 56.0
	_root.add_child(header)

	_header_label = Label.new()
	_header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_header_label.add_theme_font_size_override("font_size", 36)
	_header_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	_header_label.add_theme_color_override("font_outline_color", Color(0.18, 0.10, 0.06, 0.90))
	_header_label.add_theme_constant_override("outline_size", 6)
	header.add_child(_header_label)

	_close_button = Button.new()
	_close_button.text = "✕"
	_close_button.focus_mode = Control.FOCUS_NONE
	_close_button.custom_minimum_size = Vector2(56, 56)
	_close_button.add_theme_font_size_override("font_size", 34)
	_close_button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	var close_style := GameTheme.booster_modal_close()
	_close_button.add_theme_stylebox_override("normal", close_style)
	_close_button.add_theme_stylebox_override("hover", close_style)
	_close_button.add_theme_stylebox_override("pressed", close_style)
	_close_button.add_theme_stylebox_override("focus", close_style)
	_close_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_close_button.offset_left = -28.0
	_close_button.offset_top = -20.0
	_close_button.offset_right = 28.0
	_close_button.offset_bottom = 36.0
	_close_button.pressed.connect(hide_modal)
	_root.add_child(_close_button)


func open_life() -> void:
	_accent = Color(1.0, 0.38, 0.50)
	_header_label.text = "ЖИЗНЬ"
	_icon_label.text = "♥"
	_title_label.text = "+1 жизнь"
	_qty_label.text = "%d / %d" % [GameState.lives, GameBalance.LIVES_MAX]
	_desc_label.text = "Восстановите жизнь за монеты и продолжите уровень."
	_life_panel.visible = true
	_credits_panel.visible = false
	_icon_pad.add_theme_stylebox_override("panel", GameTheme.booster_modal_icon_pad(_accent))
	_refresh_life_buy_state()
	visible = true
	move_to_front()


func open_credits() -> void:
	_accent = Color(1.0, 0.82, 0.22)
	_header_label.text = "МОНЕТЫ"
	_icon_label.text = "⬡"
	_title_label.text = "Пополнить запас"
	_qty_label.text = GameTheme.coin_text(GameState.credits)
	_desc_label.text = "Выберите пакет монет. Оплата в рублях."
	_life_panel.visible = false
	_credits_panel.visible = true
	_icon_pad.add_theme_stylebox_override("panel", GameTheme.booster_modal_icon_pad(_accent))
	visible = true
	move_to_front()


func hide_modal() -> void:
	visible = false
	closed.emit()


func _refresh_life_buy_state() -> void:
	if GameState.lives >= GameBalance.LIVES_MAX:
		_life_buy_button.disabled = true
		_life_buy_button.icon = null
		_life_buy_button.text = "Жизни полные"
	elif GameState.can_buy_life():
		_life_buy_button.disabled = false
		GameTheme.apply_button_coin(_life_buy_button, GameBalance.LIFE_REFILL_COST, "", "КУПИТЬ")
	else:
		_life_buy_button.disabled = true
		_life_buy_button.icon = null
		_life_buy_button.text = GameTheme.coin_shortfall_text()


func _on_life_buy_pressed() -> void:
	if GameState.buy_life():
		AudioService.play_sfx(&"tap")
		life_purchased.emit()
		hide_modal()
	else:
		_refresh_life_buy_state()


func _on_credit_pack_pressed(_pack: Dictionary) -> void:
	AudioService.play_sfx(&"tap")
	message_requested.emit("Покупки за реальные деньги — скоро")


func _on_backdrop_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		hide_modal()
