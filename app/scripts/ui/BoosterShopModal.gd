extends Control
class_name BoosterShopModal
## Модальное окно покупки бустера в стиле Food Hunt «Booster Up».

signal purchased(booster_id: String)
signal closed

const MODAL_W := 700.0

var _booster_id: String = ""
var _cost: int = 0
var _pack_count: int = 1
var _accent: Color = Color.WHITE

var _backdrop: ColorRect
var _root: Control
var _card: PanelContainer
var _header: PanelContainer
var _icon_pad: PanelContainer
var _icon_label: Label
var _qty_label: Label
var _title_label: Label
var _desc_label: Label
var _buy_button: Button
var _close_button: Button


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
	_root.custom_minimum_size = Vector2(MODAL_W, 760)
	center.add_child(_root)

	_card = PanelContainer.new()
	_card.set_anchors_preset(Control.PRESET_FULL_RECT)
	_card.add_theme_stylebox_override("panel", GameTheme.booster_modal_body())
	_root.add_child(_card)

	var wood := Control.new()
	wood.set_script(load("res://scripts/ui/shop/BoosterModalWood.gd"))
	wood.set_anchors_preset(Control.PRESET_FULL_RECT)
	wood.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(wood)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	_card.add_child(body)

	var icon_wrap := CenterContainer.new()
	icon_wrap.custom_minimum_size = Vector2(0, 168)
	body.add_child(icon_wrap)

	_icon_pad = PanelContainer.new()
	_icon_pad.custom_minimum_size = Vector2(148, 148)
	_icon_pad.add_theme_stylebox_override("panel", GameTheme.booster_modal_icon_pad(Color.WHITE))
	icon_wrap.add_child(_icon_pad)

	_icon_label = Label.new()
	_icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_icon_label.add_theme_font_size_override("font_size", 86)
	_icon_pad.add_child(_icon_label)

	_qty_label = Label.new()
	_qty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_qty_label.add_theme_font_size_override("font_size", 40)
	_qty_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	_qty_label.add_theme_color_override("font_outline_color", Color(0.18, 0.10, 0.06, 0.95))
	_qty_label.add_theme_constant_override("outline_size", 8)
	body.add_child(_qty_label)

	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 38)
	_title_label.add_theme_color_override("font_color", Color(0.28, 0.16, 0.10))
	_title_label.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.25))
	_title_label.add_theme_constant_override("outline_size", 2)
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

	var btn_spacer := Control.new()
	btn_spacer.custom_minimum_size = Vector2(0, 8)
	body.add_child(btn_spacer)

	_buy_button = Button.new()
	_buy_button.custom_minimum_size = Vector2(420, 80)
	_buy_button.focus_mode = Control.FOCUS_NONE
	GameTheme.apply_booster_modal_buy_button(_buy_button)
	_buy_button.pressed.connect(_on_buy_pressed)
	body.add_child(_buy_button)

	_header = PanelContainer.new()
	_header.custom_minimum_size = Vector2(320, 0)
	_header.add_theme_stylebox_override("panel", GameTheme.booster_modal_header())
	_header.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_header.offset_left = -160.0
	_header.offset_top = -18.0
	_header.offset_right = 160.0
	_header.offset_bottom = 56.0
	_root.add_child(_header)

	var header_label := Label.new()
	header_label.text = "БУСТЕР UP"
	header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_label.add_theme_font_size_override("font_size", 36)
	header_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	header_label.add_theme_color_override("font_outline_color", Color(0.18, 0.10, 0.06, 0.90))
	header_label.add_theme_constant_override("outline_size", 6)
	_header.add_child(header_label)

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


func open(def: Dictionary) -> void:
	_booster_id = String(def.get("id", ""))
	_cost = int(def.get("cost", 0))
	_pack_count = maxi(int(def.get("pack_count", 1)), 1)
	_accent = def.get("accent", Color.WHITE)

	_icon_label.text = String(def.get("icon", "?"))
	_title_label.text = String(def.get("title", ""))
	_desc_label.text = String(def.get("desc", ""))
	_qty_label.text = "×%d" % _pack_count
	_icon_pad.add_theme_stylebox_override("panel", GameTheme.booster_modal_icon_pad(_accent))
	_refresh_buy_state()
	visible = true
	move_to_front()


func hide_modal() -> void:
	visible = false
	closed.emit()


func _refresh_buy_state() -> void:
	var can_buy := GameState.credits >= _cost
	_buy_button.disabled = not can_buy
	if can_buy:
		GameTheme.apply_button_coin(_buy_button, _cost)
	else:
		_buy_button.icon = null
		_buy_button.text = GameTheme.coin_shortfall_text()


func _on_buy_pressed() -> void:
	if GameState.spend_credits(_cost):
		GameState.add_booster(_booster_id, _pack_count)
		AudioService.play_sfx(&"tap")
		purchased.emit(_booster_id)
		hide_modal()


func _on_backdrop_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		hide_modal()
