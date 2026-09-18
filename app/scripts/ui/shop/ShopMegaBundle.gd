extends PanelContainer
class_name ShopMegaBundle
## ShopMegaBundle — большой горизонтальный баннер «Мега-набор».

signal buy_pressed

const BUNDLE_COST := 650


func _init() -> void:
	add_theme_stylebox_override("panel", GameTheme.shop_mega_bundle())
	custom_minimum_size = Vector2(0, 140)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	var root := HBoxContainer.new()
	root.add_theme_constant_override("separation", 16)
	add_child(root)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 6)
	root.add_child(left)

	var title := Label.new()
	title.text = "МЕГА-НАБОР"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.12, 0.22, 0.48))
	left.add_child(title)

	var desc := Label.new()
	desc.text = "×2 все бустеры + %d" % 300
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 18)
	desc.add_theme_color_override("font_color", Color(0.22, 0.32, 0.52))
	left.add_child(desc)

	var icons := HBoxContainer.new()
	icons.add_theme_constant_override("separation", 8)
	left.add_child(icons)
	for emoji in ["💡", "🔓", "📡", "⚡"]:
		var chip := Label.new()
		chip.text = emoji
		chip.add_theme_font_size_override("font_size", 30)
		icons.add_child(chip)

	var buy := Button.new()
	buy.focus_mode = Control.FOCUS_NONE
	buy.mouse_filter = Control.MOUSE_FILTER_STOP
	buy.custom_minimum_size = Vector2(170, 0)
	GameTheme.apply_shop_price_button(buy)
	GameTheme.apply_button_coin(buy, BUNDLE_COST)
	buy.pressed.connect(func() -> void: buy_pressed.emit())
	buy.name = "BuyButton"
	root.add_child(buy)


func refresh_state() -> void:
	var buy: Button = find_child("BuyButton", true, false)
	if buy:
		buy.disabled = GameState.credits < BUNDLE_COST
