extends PanelContainer
class_name ShopNavBar
## ShopNavBar — нижняя деревянная навигация (Магазин / Дом / Замок).

signal home_pressed
signal shop_pressed

enum Tab { SHOP, HOME, LOCKED }

var _active_tab: Tab = Tab.SHOP
var _shop_btn: Button
var _home_btn: Button
var _lock_btn: Button


func _init() -> void:
	add_theme_stylebox_override("panel", GameTheme.shop_nav_wood())
	custom_minimum_size = Vector2(0, 136)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 14)
	add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(row)

	_shop_btn = _make_nav_button("🏪", Tab.SHOP)
	_home_btn = _make_nav_button("🏠", Tab.HOME)
	_lock_btn = _make_nav_button("🔒", Tab.LOCKED)
	_lock_btn.disabled = true

	row.add_child(_shop_btn)
	row.add_child(_home_btn)
	row.add_child(_lock_btn)

	_shop_btn.pressed.connect(func() -> void: shop_pressed.emit())
	_home_btn.pressed.connect(func() -> void: home_pressed.emit())
	_apply_tab_styles()


func set_active_tab(tab: Tab) -> void:
	_active_tab = tab
	_apply_tab_styles()


func _make_nav_button(icon: String, tab: Tab) -> Button:
	var btn := Button.new()
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(156, 96)
	btn.text = icon
	btn.add_theme_font_size_override("font_size", 58)
	btn.set_meta("tab", tab)
	return btn


func _apply_tab_styles() -> void:
	for btn in [_shop_btn, _home_btn, _lock_btn]:
		var tab: Tab = btn.get_meta("tab")
		var active := tab == _active_tab
		var style := GameTheme.shop_nav_slot_active() if active else GameTheme.shop_nav_slot()
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_stylebox_override("pressed", style)
		btn.add_theme_stylebox_override("disabled", style)
		btn.modulate = Color(1, 1, 1, 1) if active or btn != _lock_btn else Color(0.7, 0.7, 0.7, 0.8)
