extends PanelContainer
class_name ShopBoosterCard
## Карточка бустера в магазине — в стиле карточек кредитов.

signal pressed

const ACCENT: Dictionary = {
	"hint": Color(0.95, 0.82, 0.25),
	"unblock": Color(0.45, 0.88, 0.55),
	"scan": Color(0.35, 0.72, 1.0),
	"pulse": Color(1.0, 0.55, 0.35),
}

var _title_label: Label
var _count_label: Label
var _icon_label: Label
var _price_button: Button
var _pending_pack: Dictionary = {}


func _init() -> void:
	add_theme_stylebox_override("panel", GameTheme.shop_product_card())
	custom_minimum_size = Vector2(0, 220)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(root)

	var count_lbl := Label.new()
	count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_lbl.add_theme_font_size_override("font_size", 22)
	count_lbl.add_theme_color_override("font_color", Color(0.42, 0.24, 0.12))
	count_lbl.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.25))
	count_lbl.add_theme_constant_override("outline_size", 2)
	_count_label = count_lbl
	root.add_child(count_lbl)

	var icon_wrap := CenterContainer.new()
	icon_wrap.custom_minimum_size = Vector2(0, 88)
	root.add_child(icon_wrap)

	var icon_pad := PanelContainer.new()
	icon_pad.custom_minimum_size = Vector2(88, 88)
	icon_wrap.add_child(icon_pad)

	_icon_label = Label.new()
	_icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_icon_label.add_theme_font_size_override("font_size", 46)
	icon_pad.add_child(_icon_label)

	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title_label.custom_minimum_size = Vector2(140, 0)
	_title_label.add_theme_font_size_override("font_size", 22)
	_title_label.add_theme_color_override("font_color", Color(0.28, 0.16, 0.10))
	root.add_child(_title_label)

	_price_button = Button.new()
	_price_button.focus_mode = Control.FOCUS_NONE
	_price_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_price_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	GameTheme.apply_shop_price_button(_price_button)
	_price_button.pressed.connect(func() -> void: pressed.emit())
	root.add_child(_price_button)

	if not _pending_pack.is_empty():
		_apply_pack(_pending_pack)


func setup(pack: Dictionary) -> void:
	_pending_pack = pack
	if is_node_ready():
		_apply_pack(pack)


func _apply_pack(pack: Dictionary) -> void:
	var booster_id := String(pack.get("booster", ""))
	var accent: Color = ACCENT.get(booster_id, Color(0.55, 0.72, 1.0))
	_icon_label.text = String(pack.get("icon", "?"))
	_title_label.text = String(pack.get("title", ""))
	_count_label.text = "×%d" % int(pack.get("count", 1))
	var icon_pad := _icon_label.get_parent() as PanelContainer
	_icon_pad_style(icon_pad, accent)
	GameTheme.apply_button_coin(_price_button, int(pack.get("cost", 0)))


func _icon_pad_style(pad: PanelContainer, accent: Color) -> void:
	if pad == null:
		return
	pad.add_theme_stylebox_override("panel", GameTheme.booster_modal_icon_pad(accent))


func set_affordable(can_buy: bool) -> void:
	_price_button.disabled = not can_buy
