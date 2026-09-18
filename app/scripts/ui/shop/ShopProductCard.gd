extends PanelContainer
class_name ShopProductCard
## Карточка товара в сетке магазина (Food Hunt style).

signal pressed

var _amount_label: Label
var _price_button: Button
var _pack_id: String = ""
var _pending_pack: Dictionary = {}
var _coin_art: Control


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

	var amount_row := HBoxContainer.new()
	amount_row.alignment = BoxContainer.ALIGNMENT_CENTER
	amount_row.add_theme_constant_override("separation", 6)
	var coin := GameTheme.make_coin_icon(18)
	amount_row.add_child(coin)
	_amount_label = Label.new()
	_amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_amount_label.add_theme_font_size_override("font_size", 24)
	_amount_label.add_theme_color_override("font_color", Color(0.72, 0.48, 0.06))
	_amount_label.add_theme_color_override("font_outline_color", Color(0.95, 0.95, 0.95, 0.35))
	_amount_label.add_theme_constant_override("outline_size", 2)
	amount_row.add_child(_amount_label)
	root.add_child(amount_row)

	var art_holder := CenterContainer.new()
	art_holder.custom_minimum_size = Vector2(0, 88)
	root.add_child(art_holder)

	_coin_art = Control.new()
	_coin_art.set_script(load("res://scripts/ui/shop/ShopCoinArt.gd"))
	_coin_art.name = "CoinArt"
	art_holder.add_child(_coin_art)

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
	_pack_id = String(pack.get("id", ""))
	var amount := int(pack.get("amount", 0))
	_amount_label.text = _format_amount(amount)
	_price_button.text = String(pack.get("price_label", ""))
	if _coin_art and _coin_art.has_method("set_tier"):
		_coin_art.set_tier(int(pack.get("tier", 0)))


func set_price_enabled(enabled: bool) -> void:
	_price_button.disabled = not enabled


func _format_amount(amount: int) -> String:
	if amount >= 1000:
		var whole := amount / 1000
		var rem := amount % 1000
		if rem == 0:
			return "%d.000" % whole
		return "%d.%03d" % [whole, rem]
	return str(amount)
