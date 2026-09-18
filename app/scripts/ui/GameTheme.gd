class_name GameTheme
extends RefCounted
## Единая sci-fi тема: стеклянные панели, кнопки, клетки минералов.

const COIN_ICON: String = ""
const COIN_FILL: Color = Color(1.0, 0.84, 0.22)
const COIN_FACE: Color = Color(1.0, 0.93, 0.40)
const COIN_RIM: Color = Color(0.72, 0.48, 0.06)
const COIN_SHINE: Color = Color(1.0, 0.98, 0.78, 0.72)


static func draw_coin(item: CanvasItem, center: Vector2, radius: float) -> void:
	var rim := maxf(radius * 0.14, 1.2)
	item.draw_circle(center, radius, COIN_RIM)
	item.draw_circle(center, radius - rim * 0.35, COIN_FILL)
	item.draw_circle(center, radius - rim * 0.95, COIN_FACE)
	item.draw_arc(
		center, radius - rim * 0.55, -2.4, -0.7, 14,
		Color(1.0, 0.98, 0.82, 0.55), maxf(radius * 0.11, 1.0))
	item.draw_circle(center + Vector2(-radius * 0.24, -radius * 0.30), radius * 0.16, COIN_SHINE)
	item.draw_circle(center + Vector2(radius * 0.18, radius * 0.22), radius * 0.07, Color(1, 1, 1, 0.28))


static func make_coin_icon(p_diameter: int = 20) -> CoinIcon:
	var icon := CoinIcon.new(p_diameter)
	return icon


static func coin_text(amount: int) -> String:
	return str(amount)


static func coin_gain_text(amount: int) -> String:
	return "+%d" % amount


static func coin_shortfall_text() -> String:
	return "МАЛО МОНЕТ"


static var _coin_tex_cache: Dictionary = {}


static func get_coin_texture(diameter: int) -> ImageTexture:
	if _coin_tex_cache.has(diameter):
		return _coin_tex_cache[diameter]
	var img := Image.create(diameter, diameter, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var center := Vector2(diameter * 0.5, diameter * 0.5)
	var radius := diameter * 0.44
	for y in range(diameter):
		for x in range(diameter):
			var p := Vector2(x + 0.5, y + 0.5)
			var dist := p.distance_to(center)
			if dist > radius:
				continue
			var rim_t := clampf((dist - radius * 0.72) / (radius * 0.28), 0.0, 1.0)
			var col := COIN_FACE.lerp(COIN_RIM, rim_t)
			if dist < radius * 0.55:
				col = COIN_FACE.lerp(COIN_FILL, dist / (radius * 0.55) * 0.35)
			if p.y < center.y - radius * 0.05 and dist < radius * 0.45:
				col = col.lerp(COIN_SHINE, 0.42)
			img.set_pixel(x, y, col)
	var tex := ImageTexture.create_from_image(img)
	_coin_tex_cache[diameter] = tex
	return tex


static func apply_button_coin(
	btn: Button, amount: int, suffix: String = "", prefix: String = "",
) -> void:
	var icon_size := 26
	var prefix_clean := prefix.strip_edges()
	var suffix_clean := suffix.strip_edges()

	btn.icon = get_coin_texture(icon_size)
	btn.expand_icon = false
	btn.add_theme_constant_override("icon_max_width", icon_size)
	btn.add_theme_constant_override("icon_max_height", icon_size)
	btn.add_theme_constant_override("h_separation", 4)
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	var price_text := str(amount)
	if not suffix_clean.is_empty():
		price_text = "%s %s" % [price_text, suffix_clean]

	if prefix_clean.is_empty():
		btn.text = price_text
	else:
		btn.text = "%s %s" % [prefix_clean, price_text]

	btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	btn.add_theme_color_override("font_disabled_color", Color(0.88, 0.94, 0.90, 1.0))
	btn.add_theme_font_size_override("font_size", 32)


static func coin_need_text(amount: int) -> String:
	return "Нужно %d" % amount


static func glass_panel() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.05, 0.07, 0.14, 0.88)
	s.border_color = Color(0.30, 0.50, 0.90, 0.45)
	s.set_border_width_all(2)
	s.set_corner_radius_all(18)
	s.shadow_color = Color(0.0, 0.1, 0.3, 0.55)
	s.shadow_size = 12
	s.shadow_offset = Vector2(0, 4)
	return s


static func glass_panel_dark() -> StyleBoxFlat:
	var s := glass_panel()
	s.bg_color = Color(0.03, 0.04, 0.10, 0.92)
	return s


static func accent_panel() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.08, 0.12, 0.28, 0.90)
	s.border_color = Color(0.40, 0.65, 1.0, 0.55)
	s.set_border_width_all(2)
	s.set_corner_radius_all(20)
	s.shadow_color = Color(0.1, 0.3, 0.8, 0.35)
	s.shadow_size = 16
	return s


static func btn_normal(accent: Color = Color(0.18, 0.40, 0.92)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = accent
	s.set_corner_radius_all(14)
	s.set_content_margin_all(12)
	s.border_color = accent.lightened(0.25)
	s.set_border_width_all(2)
	s.shadow_color = Color(accent.r * 0.3, accent.g * 0.3, accent.b * 0.5, 0.6)
	s.shadow_size = 8
	return s


static func btn_hover(accent: Color = Color(0.25, 0.50, 1.0)) -> StyleBoxFlat:
	var s := btn_normal(accent)
	s.bg_color = accent
	s.shadow_size = 12
	return s


static func btn_pressed(accent: Color = Color(0.10, 0.28, 0.72)) -> StyleBoxFlat:
	var s := btn_normal(accent)
	s.bg_color = accent
	s.shadow_size = 2
	return s


static func btn_warp() -> StyleBoxFlat:
	return btn_normal(Color(0.12, 0.55, 0.75))


static func btn_warp_hover() -> StyleBoxFlat:
	return btn_hover(Color(0.18, 0.65, 0.88))


static func btn_danger() -> StyleBoxFlat:
	return btn_normal(Color(0.55, 0.18, 0.28))


static func apply_panel(panel: PanelContainer, dark: bool = false) -> void:
	panel.add_theme_stylebox_override("panel", glass_panel_dark() if dark else glass_panel())


static func apply_button(btn: Button, accent: Color = Color(0.18, 0.40, 0.92)) -> void:
	btn.add_theme_stylebox_override("normal", btn_normal(accent))
	btn.add_theme_stylebox_override("hover", btn_hover(accent.lightened(0.15)))
	btn.add_theme_stylebox_override("pressed", btn_pressed(accent.darkened(0.15)))
	btn.add_theme_stylebox_override("focus", btn_hover(accent.lightened(0.15)))
	btn.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0))
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color(0.85, 0.90, 1.0))


static func btn_play_normal() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.22, 0.82, 0.48)
	s.set_corner_radius_all(28)
	s.set_content_margin_all(18)
	s.border_color = Color(0.12, 0.62, 0.32)
	s.set_border_width_all(4)
	s.shadow_color = Color(0.05, 0.35, 0.15, 0.55)
	s.shadow_size = 12
	s.shadow_offset = Vector2(0, 5)
	return s


static func btn_play_hover() -> StyleBoxFlat:
	var s := btn_play_normal()
	s.bg_color = Color(0.28, 0.90, 0.55)
	s.shadow_size = 16
	return s


static func btn_play_pressed() -> StyleBoxFlat:
	var s := btn_play_normal()
	s.bg_color = Color(0.16, 0.65, 0.38)
	s.shadow_size = 4
	s.shadow_offset = Vector2(0, 2)
	return s


static func apply_play_button(btn: Button) -> void:
	btn.add_theme_stylebox_override("normal", btn_play_normal())
	btn.add_theme_stylebox_override("hover", btn_play_hover())
	btn.add_theme_stylebox_override("pressed", btn_play_pressed())
	btn.add_theme_stylebox_override("focus", btn_play_hover())
	btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	btn.add_theme_color_override("font_pressed_color", Color(0.9, 1, 0.95, 1))
	btn.add_theme_font_size_override("font_size", 32)


static func menu_card_panel() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.10, 0.12, 0.26, 0.92)
	s.border_color = Color(0.50, 0.40, 0.90, 0.50)
	s.set_border_width_all(3)
	s.set_corner_radius_all(24)
	s.shadow_color = Color(0.05, 0.05, 0.20, 0.6)
	s.shadow_size = 14
	s.shadow_offset = Vector2(0, 6)
	return s


static func menu_glass_card() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.07, 0.09, 0.20, 0.88)
	s.border_color = Color(0.45, 0.55, 0.95, 0.55)
	s.set_border_width_all(2)
	s.set_corner_radius_all(28)
	s.shadow_color = Color(0, 0, 0, 0.55)
	s.shadow_size = 20
	s.shadow_offset = Vector2(0, 8)
	s.set_content_margin_all(12)
	return s


static func apply_menu_card(panel: PanelContainer) -> void:
	panel.add_theme_stylebox_override("panel", menu_card_panel())


static func apply_warp_button(btn: Button) -> void:
	btn.add_theme_stylebox_override("normal", btn_warp())
	btn.add_theme_stylebox_override("hover", btn_warp_hover())
	btn.add_theme_stylebox_override("pressed", btn_pressed(Color(0.08, 0.40, 0.58)))
	btn.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0))


static func cell_mineral(color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(8)
	s.border_color = color.lightened(0.35)
	s.set_border_width_all(2)
	s.shadow_color = Color(color.r * 0.4, color.g * 0.4, color.b * 0.4, 0.5)
	s.shadow_size = 4
	return s


static func cell_hidden() -> StyleBoxFlat:
	if _cell_hidden_box != null:
		return _cell_hidden_box
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.14, 0.16, 0.28, 0.95)
	s.set_corner_radius_all(6)
	s.border_color = Color(0.42, 0.48, 0.72, 0.85)
	s.set_border_width_all(2)
	_cell_hidden_box = s
	return s


static func cell_locked() -> StyleBoxFlat:
	if _cell_locked_box != null:
		return _cell_locked_box
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.14, 0.10, 0.18)
	s.set_corner_radius_all(8)
	s.border_color = Color(0.35, 0.20, 0.45, 0.6)
	s.set_border_width_all(2)
	_cell_locked_box = s
	return s


static func cell_mined() -> StyleBoxFlat:
	if _cell_mined_box != null:
		return _cell_mined_box
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.06, 0.07, 0.11)
	s.set_corner_radius_all(8)
	s.border_color = Color(0.12, 0.14, 0.20)
	s.set_border_width_all(1)
	_cell_mined_box = s
	return s


static func cell_background() -> StyleBoxFlat:
	if _cell_background_box != null:
		return _cell_background_box
	_cell_background_box = pixel_cell(GameBalance.MINERAL_COLORS[GameBalance.BACKGROUND_COLOR_INDEX])
	return _cell_background_box


static var _cell_empty_box: StyleBoxFlat
static var _cell_void_box: StyleBoxEmpty
static var _dock_empty_box: StyleBoxFlat


static func cell_empty() -> StyleBoxFlat:
	if _cell_empty_box != null:
		return _cell_empty_box
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.16, 0.20, 0.34, 0.88)
	s.border_color = Color(0.72, 0.82, 1.0, 0.55)
	s.set_border_width_all(2)
	s.set_corner_radius_all(5)
	_cell_empty_box = s
	return s


static func cell_void() -> StyleBoxEmpty:
	if _cell_void_box == null:
		_cell_void_box = StyleBoxEmpty.new()
	return _cell_void_box


static func dock_capsule_empty() -> StyleBoxFlat:
	if _dock_empty_box != null:
		return _dock_empty_box
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	s.border_color = Color(0.48, 0.54, 0.72, 0.62)
	s.set_border_width_all(2)
	s.set_corner_radius_all(10)
	s.set_content_margin_all(5)
	_dock_empty_box = s
	return _dock_empty_box


static func vending_slot_empty() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.12, 0.14, 0.26, 0.72)
	s.border_color = Color(0.55, 0.62, 0.88, 0.55)
	s.set_border_width_all(2)
	s.set_corner_radius_all(6)
	return s


static func vending_color_locked(color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(color.r, color.g, color.b, 0.28)
	s.border_color = Color(0.72, 0.72, 0.82, 0.45)
	s.set_border_width_all(3)
	s.set_corner_radius_all(6)
	return s


static func progress_bar_bg() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.08, 0.10, 0.16)
	s.set_corner_radius_all(4)
	return s


static func progress_bar_fill(color: Color = Color(0.3, 0.7, 1.0)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(4)
	return s


# --- Food Hunt style (космическая версия) ---

static func deck_panel() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.22, 0.18, 0.38, 0.96)
	s.border_color = Color(0.45, 0.38, 0.65, 0.5)
	s.set_border_width_all(0)
	s.set_corner_radius_all(0)
	return s


static func canvas_outer_frame() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.92, 0.94, 0.98, 1.0)
	s.border_color = Color(0.75, 0.78, 0.88, 1.0)
	s.set_border_width_all(6)
	s.set_corner_radius_all(20)
	s.shadow_color = Color(0, 0, 0, 0.35)
	s.shadow_size = 16
	s.shadow_offset = Vector2(0, 6)
	return s


static func canvas_inner() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.04, 0.05, 0.12, 1.0)
	s.border_color = Color(0.15, 0.18, 0.30, 1.0)
	s.set_border_width_all(3)
	s.set_corner_radius_all(12)
	return s


static func dock_capsule(color: Color, busy: bool = false) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color.darkened(0.12) if busy else Color(0.18, 0.20, 0.32, 1.0)
	s.border_color = color.lightened(0.25) if busy else Color(0.40, 0.48, 0.70, 1.0)
	s.set_border_width_all(3)
	s.set_corner_radius_all(10)
	s.shadow_color = Color(0, 0, 0, 0.35)
	s.shadow_size = 4
	s.shadow_offset = Vector2(0, 2)
	s.set_content_margin_all(5)
	return s


static func color_stack_tile(color: Color, locked: bool = false) -> StyleBoxFlat:
	return color_square_tile(color, locked)


static func mineral_color_is_light(color_idx: int) -> bool:
	if color_idx < 0 or color_idx >= GameBalance.MINERAL_COLORS.size():
		return false
	return GameBalance.MINERAL_COLORS[color_idx].get_luminance() > 0.52


static func mineral_chip_text_color(color_idx: int) -> Color:
	if mineral_color_is_light(color_idx):
		return Color(0.06, 0.07, 0.10)
	return Color.WHITE


static func mineral_chip_outline_color(color_idx: int) -> Color:
	if mineral_color_is_light(color_idx):
		return Color(1.0, 1.0, 1.0, 0.95)
	return Color(0.08, 0.08, 0.14)


static func color_square_tile(color: Color, locked: bool = false) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	if locked:
		s.bg_color = Color(0.20, 0.18, 0.28, 1.0)
		s.border_color = Color(0.35, 0.32, 0.45, 1.0)
	else:
		s.bg_color = color.darkened(0.08)
		s.border_color = color.lightened(0.35)
	s.set_border_width_all(4)
	s.set_corner_radius_all(6)
	s.shadow_color = Color(0, 0, 0, 0.35)
	s.shadow_size = 4
	s.shadow_offset = Vector2(0, 2)
	return s


static func footer_bar() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.32, 0.26, 0.52, 0.98)
	s.border_color = Color(0.50, 0.42, 0.72, 0.6)
	s.set_border_width_all(0)
	s.set_corner_radius_all(0)
	return s


static func round_action_btn(accent: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = accent
	s.set_corner_radius_all(40)
	s.border_color = accent.lightened(0.3)
	s.set_border_width_all(4)
	s.shadow_color = Color(0, 0, 0, 0.35)
	s.shadow_size = 8
	s.set_content_margin_all(10)
	return s


static func footer_action_pair() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.12, 0.11, 0.22, 0.78)
	s.border_color = Color(0.42, 0.38, 0.62, 0.55)
	s.set_border_width_all(2)
	s.set_corner_radius_all(56)
	s.shadow_color = Color(0, 0, 0, 0.28)
	s.shadow_size = 6
	s.set_content_margin_all(8)
	return s


static func booster_tile(accent: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.10, 0.12, 0.24, 0.98)
	s.border_color = accent.lightened(0.20)
	s.set_border_width_all(3)
	s.set_corner_radius_all(18)
	s.shadow_color = Color(accent.r * 0.25, accent.g * 0.25, accent.b * 0.35, 0.65)
	s.shadow_size = 12
	s.shadow_offset = Vector2(0, 4)
	return s


static func hud_top_bar() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.06, 0.08, 0.16, 0.94)
	s.border_color = Color(0.28, 0.38, 0.62, 0.55)
	s.set_border_width_all(2)
	s.set_corner_radius_all(16)
	s.shadow_color = Color(0, 0, 0, 0.35)
	s.shadow_size = 8
	s.shadow_offset = Vector2(0, 3)
	s.set_content_margin_all(4)
	return s


static func hud_level_badge() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.12, 0.16, 0.28, 1.0)
	s.border_color = Color(0.42, 0.55, 0.88, 0.75)
	s.set_border_width_all(2)
	s.set_corner_radius_all(12)
	s.set_content_margin(Side.SIDE_LEFT, 10)
	s.set_content_margin(Side.SIDE_RIGHT, 10)
	s.set_content_margin(Side.SIDE_TOP, 4)
	s.set_content_margin(Side.SIDE_BOTTOM, 4)
	return s


static func hud_difficulty_hard() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.48, 0.20, 0.04, 0.97)
	s.border_color = Color(1.0, 0.68, 0.18, 1.0)
	s.set_border_width_all(3)
	s.set_corner_radius_all(16)
	s.shadow_color = Color(1.0, 0.45, 0.05, 0.45)
	s.shadow_size = 9
	s.shadow_offset = Vector2(0, 2)
	s.set_content_margin(Side.SIDE_LEFT, 12)
	s.set_content_margin(Side.SIDE_RIGHT, 12)
	s.set_content_margin(Side.SIDE_TOP, 3)
	s.set_content_margin(Side.SIDE_BOTTOM, 3)
	return s


static func hud_difficulty_normal() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.08, 0.22, 0.16, 0.95)
	s.border_color = Color(0.45, 0.95, 0.62, 0.9)
	s.set_border_width_all(2)
	s.set_corner_radius_all(16)
	s.shadow_color = Color(0.25, 0.85, 0.45, 0.30)
	s.shadow_size = 5
	s.set_content_margin(Side.SIDE_LEFT, 12)
	s.set_content_margin(Side.SIDE_RIGHT, 12)
	s.set_content_margin(Side.SIDE_TOP, 3)
	s.set_content_margin(Side.SIDE_BOTTOM, 3)
	return s


static func hud_difficulty_extreme() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.46, 0.04, 0.14, 0.98)
	s.border_color = Color(1.0, 0.22, 0.42, 1.0)
	s.set_border_width_all(3)
	s.set_corner_radius_all(16)
	s.shadow_color = Color(1.0, 0.10, 0.30, 0.55)
	s.shadow_size = 12
	s.shadow_offset = Vector2(0, 3)
	s.set_content_margin(Side.SIDE_LEFT, 14)
	s.set_content_margin(Side.SIDE_RIGHT, 14)
	s.set_content_margin(Side.SIDE_TOP, 4)
	s.set_content_margin(Side.SIDE_BOTTOM, 4)
	return s


static func hud_stat_chip(accent: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.09, 0.11, 0.20, 0.96)
	s.border_color = accent.lightened(0.15)
	s.set_border_width_all(2)
	s.set_corner_radius_all(14)
	s.set_content_margin(Side.SIDE_LEFT, 8)
	s.set_content_margin(Side.SIDE_RIGHT, 10)
	s.set_content_margin(Side.SIDE_TOP, 4)
	s.set_content_margin(Side.SIDE_BOTTOM, 4)
	return s


static func hud_stat_chip_life() -> StyleBoxFlat:
	var s := hud_stat_chip(Color(1.0, 0.38, 0.50))
	s.bg_color = Color(0.24, 0.08, 0.14, 0.96)
	s.border_color = Color(1.0, 0.45, 0.55, 0.88)
	s.shadow_color = Color(1.0, 0.25, 0.35, 0.22)
	s.shadow_size = 6
	return s


static func hud_stat_chip_credits() -> StyleBoxFlat:
	var s := hud_stat_chip(Color(1.0, 0.82, 0.22))
	s.bg_color = Color(0.22, 0.17, 0.05, 0.96)
	s.border_color = Color(1.0, 0.86, 0.32, 0.92)
	s.shadow_color = Color(1.0, 0.75, 0.12, 0.18)
	s.shadow_size = 6
	return s


static func booster_icon_chip(accent: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.08, 0.10, 0.20, 1.0)
	s.border_color = accent.lightened(0.12)
	s.set_border_width_all(2)
	s.set_corner_radius_all(14)
	s.set_content_margin_all(6)
	return s


static func booster_buy_button(accent: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = accent.darkened(0.08)
	s.border_color = accent.lightened(0.22)
	s.set_border_width_all(2)
	s.set_corner_radius_all(12)
	s.shadow_color = Color(accent.r * 0.2, accent.g * 0.2, accent.b * 0.3, 0.5)
	s.shadow_size = 4
	s.set_content_margin(Side.SIDE_LEFT, 10)
	s.set_content_margin(Side.SIDE_RIGHT, 10)
	s.set_content_margin(Side.SIDE_TOP, 6)
	s.set_content_margin(Side.SIDE_BOTTOM, 6)
	return s


static func modal_card(accent: Color = Color(0.45, 0.55, 0.95)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.08, 0.10, 0.22, 0.98)
	s.border_color = accent.lightened(0.15)
	s.set_border_width_all(3)
	s.set_corner_radius_all(24)
	s.shadow_color = Color(0, 0, 0, 0.55)
	s.shadow_size = 18
	s.shadow_offset = Vector2(0, 8)
	s.set_content_margin_all(8)
	return s


static func count_badge(accent: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = accent.lightened(0.35)
	s.border_color = Color(0.08, 0.08, 0.12, 0.85)
	s.set_border_width_all(2)
	s.set_corner_radius_all(12)
	return s


static func booster_tile_large(accent: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.09, 0.11, 0.22, 1.0)
	s.border_color = accent.lightened(0.18)
	s.set_border_width_all(3)
	s.set_corner_radius_all(18)
	s.shadow_color = Color(accent.r * 0.25, accent.g * 0.25, accent.b * 0.35, 0.55)
	s.shadow_size = 8
	s.shadow_offset = Vector2(0, 3)
	s.set_content_margin_all(10)
	return s


static func booster_tile_fill(accent: Color) -> StyleBoxFlat:
	var s := booster_tile_large(accent)
	s.set_content_margin_all(3)
	s.set_corner_radius_all(12)
	s.set_border_width_all(2)
	return s


static func booster_action_btn(accent: Color, disabled: bool = false) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	if disabled:
		s.bg_color = Color(0.18, 0.20, 0.28, 0.75)
		s.border_color = Color(0.28, 0.30, 0.38, 0.6)
	else:
		s.bg_color = accent.darkened(0.08)
		s.border_color = accent.lightened(0.22)
	s.set_border_width_all(2)
	s.set_corner_radius_all(8)
	s.set_content_margin_all(4)
	return s


static func bottom_section_panel(accent: Color = Color(0.40, 0.65, 1.0)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.06, 0.08, 0.15, 0.94)
	s.border_color = Color(accent.r, accent.g, accent.b, 0.38)
	s.set_border_width_all(2)
	s.set_corner_radius_all(16)
	s.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	s.shadow_size = 6
	s.shadow_offset = Vector2(0, 2)
	s.set_content_margin_all(10)
	return s


static func remainder_chip_tile(color: Color) -> StyleBoxFlat:
	var s := color_square_tile(color, false)
	s.set_border_width_all(3)
	s.border_color = color.lightened(0.42)
	s.set_corner_radius_all(8)
	s.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	s.shadow_size = 5
	s.shadow_offset = Vector2(0, 2)
	return s


static func pixel_cell(color: Color) -> StyleBoxFlat:
	var key := color.to_html(false)
	if _pixel_cell_cache.has(key):
		return _pixel_cell_cache[key]
	var s := StyleBoxFlat.new()
	s.bg_color = color
	var lum := color.r * 0.299 + color.g * 0.587 + color.b * 0.114
	if lum > 0.82:
		s.border_color = color.darkened(0.30)
	elif lum < 0.22:
		s.border_color = color.lightened(0.50)
	else:
		s.border_color = color.lightened(0.35)
	s.set_corner_radius_all(6)
	s.set_border_width_all(3)
	s.shadow_color = Color(0, 0, 0, 0.4)
	s.shadow_size = 4
	s.shadow_offset = Vector2(0, 3)
	_pixel_cell_cache[key] = s
	return s


static var _pixel_cell_cache: Dictionary = {}
static var _cell_hidden_box: StyleBoxFlat
static var _cell_locked_box: StyleBoxFlat
static var _cell_mined_box: StyleBoxFlat
static var _cell_background_box: StyleBoxFlat


static func apply_deck(panel: PanelContainer) -> void:
	panel.add_theme_stylebox_override("panel", deck_panel())


static func apply_canvas_frame(panel: PanelContainer) -> void:
	panel.add_theme_stylebox_override("panel", canvas_outer_frame())


static func apply_canvas_inner(panel: PanelContainer) -> void:
	panel.add_theme_stylebox_override("panel", canvas_inner())


static func apply_footer(panel: PanelContainer) -> void:
	panel.add_theme_stylebox_override("panel", footer_bar())


# --- Shop (Food Hunt style) ---

static func shop_product_card() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.98, 0.97, 0.94, 1.0)
	s.border_color = Color(0.95, 0.78, 0.12, 1.0)
	s.set_border_width_all(5)
	s.set_corner_radius_all(22)
	s.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	s.shadow_size = 10
	s.shadow_offset = Vector2(0, 5)
	s.set_content_margin_all(10)
	return s


static func shop_mega_bundle() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.82, 0.92, 0.98, 1.0)
	s.border_color = Color(0.95, 0.78, 0.12, 1.0)
	s.set_border_width_all(6)
	s.set_corner_radius_all(24)
	s.shadow_color = Color(0.0, 0.0, 0.0, 0.30)
	s.shadow_size = 12
	s.shadow_offset = Vector2(0, 6)
	s.set_content_margin_all(14)
	return s


static func shop_category_pill() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.22, 0.48, 0.95, 1.0)
	s.border_color = Color(0.10, 0.28, 0.72, 1.0)
	s.set_border_width_all(4)
	s.set_corner_radius_all(20)
	s.shadow_color = Color(0.05, 0.15, 0.45, 0.45)
	s.shadow_size = 6
	s.shadow_offset = Vector2(0, 3)
	s.set_content_margin(Side.SIDE_LEFT, 22)
	s.set_content_margin(Side.SIDE_RIGHT, 22)
	s.set_content_margin(Side.SIDE_TOP, 8)
	s.set_content_margin(Side.SIDE_BOTTOM, 8)
	return s


static func shop_price_button() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.28, 0.82, 0.38)
	s.border_color = Color(0.12, 0.58, 0.22, 1.0)
	s.set_border_width_all(3)
	s.set_corner_radius_all(18)
	s.shadow_color = Color(0.05, 0.30, 0.10, 0.45)
	s.shadow_size = 5
	s.shadow_offset = Vector2(0, 3)
	s.set_content_margin(Side.SIDE_LEFT, 10)
	s.set_content_margin(Side.SIDE_RIGHT, 10)
	s.set_content_margin(Side.SIDE_TOP, 8)
	s.set_content_margin(Side.SIDE_BOTTOM, 8)
	return s


static func shop_price_button_hover() -> StyleBoxFlat:
	var s := shop_price_button()
	s.bg_color = Color(0.34, 0.90, 0.45)
	s.shadow_size = 8
	return s


static func shop_price_button_pressed() -> StyleBoxFlat:
	var s := shop_price_button()
	s.bg_color = Color(0.18, 0.68, 0.30)
	s.shadow_size = 2
	s.shadow_offset = Vector2(0, 1)
	return s


static func shop_title_banner() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.55, 0.34, 0.18, 1.0)
	s.border_color = Color(0.95, 0.78, 0.15, 1.0)
	s.set_border_width_all(5)
	s.set_corner_radius_all(18)
	s.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	s.shadow_size = 8
	s.shadow_offset = Vector2(0, 4)
	s.set_content_margin(Side.SIDE_LEFT, 28)
	s.set_content_margin(Side.SIDE_RIGHT, 28)
	s.set_content_margin(Side.SIDE_TOP, 10)
	s.set_content_margin(Side.SIDE_BOTTOM, 10)
	return s


static func shop_credit_chip() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.12, 0.10, 0.22, 0.92)
	s.border_color = Color(0.95, 0.78, 0.15, 0.85)
	s.set_border_width_all(3)
	s.set_corner_radius_all(18)
	s.set_content_margin(Side.SIDE_LEFT, 12)
	s.set_content_margin(Side.SIDE_RIGHT, 8)
	s.set_content_margin(Side.SIDE_TOP, 6)
	s.set_content_margin(Side.SIDE_BOTTOM, 6)
	return s


static func shop_free_row() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.98, 0.97, 0.94, 1.0)
	s.border_color = Color(0.95, 0.78, 0.12, 1.0)
	s.set_border_width_all(5)
	s.set_corner_radius_all(20)
	s.shadow_color = Color(0.0, 0.0, 0.0, 0.18)
	s.shadow_size = 6
	s.set_content_margin_all(12)
	return s


static func shop_life_row() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.98, 0.97, 0.94, 1.0)
	s.border_color = Color(0.92, 0.38, 0.48, 1.0)
	s.set_border_width_all(5)
	s.set_corner_radius_all(20)
	s.shadow_color = Color(0.0, 0.0, 0.0, 0.18)
	s.shadow_size = 6
	s.set_content_margin_all(12)
	return s


static func shop_nav_wood() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.62, 0.44, 0.26, 1.0)
	s.border_color = Color(0.42, 0.28, 0.14, 1.0)
	s.set_border_width_all(0)
	s.set_corner_radius_all(0)
	s.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	s.shadow_size = 10
	s.shadow_offset = Vector2(0, -4)
	return s


static func shop_nav_slot_active() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.78, 0.58, 0.34, 1.0)
	s.border_color = Color(0.95, 0.78, 0.15, 0.75)
	s.set_border_width_all(3)
	s.set_corner_radius_all(16)
	return s


static func shop_nav_slot() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.52, 0.36, 0.20, 0.65)
	s.set_corner_radius_all(16)
	return s


static func shop_credit_chip_white() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.98, 0.97, 0.95, 1.0)
	s.border_color = Color(0.62, 0.40, 0.22, 0.85)
	s.set_border_width_all(4)
	s.set_corner_radius_all(22)
	s.shadow_color = Color(0.0, 0.0, 0.0, 0.20)
	s.shadow_size = 6
	s.set_content_margin(Side.SIDE_LEFT, 12)
	s.set_content_margin(Side.SIDE_RIGHT, 8)
	s.set_content_margin(Side.SIDE_TOP, 6)
	s.set_content_margin(Side.SIDE_BOTTOM, 6)
	return s


static func apply_shop_price_button(btn: Button) -> void:
	btn.add_theme_stylebox_override("normal", shop_price_button())
	btn.add_theme_stylebox_override("hover", shop_price_button_hover())
	btn.add_theme_stylebox_override("pressed", shop_price_button_pressed())
	btn.add_theme_stylebox_override("focus", shop_price_button_hover())
	btn.add_theme_stylebox_override("disabled", shop_price_button_pressed())
	btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	btn.add_theme_color_override("font_disabled_color", Color(0.85, 0.92, 0.88, 1.0))
	btn.add_theme_font_size_override("font_size", 26)


# --- Game over modal (Food Hunt "Out Of Space" style) ---

static func game_over_modal_body() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.74, 0.90, 0.98, 1.0)
	s.border_color = Color(0.10, 0.28, 0.62, 1.0)
	s.set_border_width_all(6)
	s.set_corner_radius_all(32)
	s.shadow_color = Color(0.05, 0.12, 0.35, 0.45)
	s.shadow_size = 18
	s.shadow_offset = Vector2(0, 8)
	s.set_content_margin(Side.SIDE_LEFT, 32)
	s.set_content_margin(Side.SIDE_RIGHT, 32)
	s.set_content_margin(Side.SIDE_TOP, 56)
	s.set_content_margin(Side.SIDE_BOTTOM, 28)
	return s


static func game_over_modal_header() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.12, 0.34, 0.68, 1.0)
	s.border_color = Color(0.08, 0.22, 0.52, 1.0)
	s.set_border_width_all(4)
	s.set_corner_radius_all(22)
	s.shadow_color = Color(0.0, 0.0, 0.0, 0.30)
	s.shadow_size = 8
	s.set_content_margin(Side.SIDE_LEFT, 28)
	s.set_content_margin(Side.SIDE_RIGHT, 28)
	s.set_content_margin(Side.SIDE_TOP, 10)
	s.set_content_margin(Side.SIDE_BOTTOM, 10)
	return s


static func game_over_modal_close() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.92, 0.18, 0.22, 1.0)
	s.border_color = Color(0.62, 0.08, 0.12, 1.0)
	s.set_border_width_all(4)
	s.set_corner_radius_all(32)
	s.shadow_color = Color(0.35, 0.05, 0.08, 0.45)
	s.shadow_size = 8
	return s


static func game_over_continue_button() -> StyleBoxFlat:
	var s := shop_price_button()
	s.set_corner_radius_all(28)
	s.set_content_margin(Side.SIDE_LEFT, 24)
	s.set_content_margin(Side.SIDE_RIGHT, 24)
	s.set_content_margin(Side.SIDE_TOP, 14)
	s.set_content_margin(Side.SIDE_BOTTOM, 14)
	return s


static func game_over_secondary_button() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.42, 0.44, 0.52, 1.0)
	s.border_color = Color(0.28, 0.30, 0.38, 1.0)
	s.set_border_width_all(4)
	s.set_corner_radius_all(24)
	s.set_content_margin(Side.SIDE_LEFT, 20)
	s.set_content_margin(Side.SIDE_RIGHT, 20)
	s.set_content_margin(Side.SIDE_TOP, 12)
	s.set_content_margin(Side.SIDE_BOTTOM, 12)
	return s


static func apply_game_over_continue_button(btn: Button) -> void:
	btn.add_theme_stylebox_override("normal", game_over_continue_button())
	btn.add_theme_stylebox_override("hover", shop_price_button_hover())
	btn.add_theme_stylebox_override("pressed", shop_price_button_pressed())
	btn.add_theme_stylebox_override("focus", shop_price_button_hover())
	btn.add_theme_stylebox_override("disabled", shop_price_button_pressed())
	btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	btn.add_theme_font_size_override("font_size", 26)


static func apply_game_over_secondary_button(btn: Button) -> void:
	var s := game_over_secondary_button()
	btn.add_theme_stylebox_override("normal", s)
	btn.add_theme_stylebox_override("hover", s)
	btn.add_theme_stylebox_override("pressed", s)
	btn.add_theme_stylebox_override("focus", s)
	btn.add_theme_color_override("font_color", Color(0.95, 0.96, 1.0, 1.0))
	btn.add_theme_font_size_override("font_size", 26)


static func menu_level_badge() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.18, 0.46, 0.95, 1.0)
	s.border_color = Color(0.08, 0.24, 0.68, 1.0)
	s.set_border_width_all(5)
	s.set_corner_radius_all(24)
	s.shadow_color = Color(0.05, 0.12, 0.35, 0.50)
	s.shadow_size = 8
	s.shadow_offset = Vector2(0, 4)
	s.set_content_margin(Side.SIDE_LEFT, 28)
	s.set_content_margin(Side.SIDE_RIGHT, 28)
	s.set_content_margin(Side.SIDE_TOP, 10)
	s.set_content_margin(Side.SIDE_BOTTOM, 10)
	return s


static func menu_lives_chip() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.12, 0.10, 0.22, 0.90)
	s.border_color = Color(0.95, 0.78, 0.15, 0.80)
	s.set_border_width_all(3)
	s.set_corner_radius_all(18)
	s.set_content_margin(Side.SIDE_LEFT, 12)
	s.set_content_margin(Side.SIDE_RIGHT, 14)
	s.set_content_margin(Side.SIDE_TOP, 6)
	s.set_content_margin(Side.SIDE_BOTTOM, 6)
	return s


static func menu_warp_chip() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.96, 0.95, 0.92, 0.95)
	s.border_color = Color(0.45, 0.72, 1.0, 0.85)
	s.set_border_width_all(3)
	s.set_corner_radius_all(16)
	s.set_content_margin(Side.SIDE_LEFT, 14)
	s.set_content_margin(Side.SIDE_RIGHT, 14)
	s.set_content_margin(Side.SIDE_TOP, 6)
	s.set_content_margin(Side.SIDE_BOTTOM, 6)
	return s


static func menu_hud_pill() -> StyleBoxFlat:
	return menu_space_hud_pill()


static func menu_space_hud_pill() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.06, 0.10, 0.22, 0.88)
	s.border_color = Color(0.35, 0.72, 1.0, 0.72)
	s.set_border_width_all(3)
	s.set_corner_radius_all(22)
	s.shadow_color = Color(0.10, 0.30, 0.70, 0.35)
	s.shadow_size = 8
	s.shadow_offset = Vector2(0, 3)
	s.set_content_margin(Side.SIDE_LEFT, 14)
	s.set_content_margin(Side.SIDE_RIGHT, 14)
	s.set_content_margin(Side.SIDE_TOP, 8)
	s.set_content_margin(Side.SIDE_BOTTOM, 8)
	return s


static func menu_space_hud_pill_gold() -> StyleBoxFlat:
	var s := menu_space_hud_pill()
	s.border_color = Color(1.0, 0.82, 0.22, 0.85)
	s.shadow_color = Color(0.55, 0.35, 0.05, 0.35)
	return s


static func menu_space_hud_pill_life() -> StyleBoxFlat:
	var s := menu_space_hud_pill()
	s.border_color = Color(1.0, 0.38, 0.48, 0.85)
	s.shadow_color = Color(0.55, 0.10, 0.18, 0.35)
	return s


static func menu_profile_frame() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.08, 0.14, 0.32, 0.92)
	s.border_color = Color(0.40, 0.78, 1.0, 0.95)
	s.set_border_width_all(4)
	s.set_corner_radius_all(18)
	s.shadow_color = Color(0.15, 0.45, 0.95, 0.40)
	s.shadow_size = 10
	s.set_content_margin_all(6)
	return s


static func menu_settings_button() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.06, 0.10, 0.22, 0.88)
	s.border_color = Color(0.35, 0.72, 1.0, 0.72)
	s.set_border_width_all(3)
	s.set_corner_radius_all(28)
	s.shadow_color = Color(0.10, 0.30, 0.70, 0.35)
	s.shadow_size = 8
	return s


static func menu_level_block() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.10, 0.18, 0.42, 0.95)
	s.border_color = Color(0.45, 0.82, 1.0, 0.95)
	s.set_border_width_all(5)
	s.set_corner_radius_all(28)
	s.shadow_color = Color(0.15, 0.45, 0.95, 0.45)
	s.shadow_size = 18
	s.shadow_offset = Vector2(0, 8)
	s.set_content_margin_all(16)
	return s


static func menu_play_yellow_normal() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.18, 0.55, 0.95, 1.0)
	s.border_color = Color(0.55, 0.88, 1.0, 1.0)
	s.set_border_width_all(5)
	s.set_corner_radius_all(40)
	s.shadow_color = Color(0.10, 0.35, 0.85, 0.55)
	s.shadow_size = 16
	s.shadow_offset = Vector2(0, 7)
	s.set_content_margin(Side.SIDE_LEFT, 36)
	s.set_content_margin(Side.SIDE_RIGHT, 36)
	s.set_content_margin(Side.SIDE_TOP, 20)
	s.set_content_margin(Side.SIDE_BOTTOM, 20)
	return s


static func menu_play_yellow_hover() -> StyleBoxFlat:
	var s := menu_play_yellow_normal()
	s.bg_color = Color(0.28, 0.65, 1.0, 1.0)
	s.shadow_size = 22
	return s


static func menu_play_yellow_pressed() -> StyleBoxFlat:
	var s := menu_play_yellow_normal()
	s.bg_color = Color(0.12, 0.42, 0.78, 1.0)
	s.shadow_size = 4
	s.shadow_offset = Vector2(0, 2)
	return s


static func menu_side_button(accent: Color = Color(0.40, 0.78, 1.0)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.07, 0.11, 0.26, 0.94)
	s.border_color = accent.lightened(0.12)
	s.set_border_width_all(4)
	s.set_corner_radius_all(48)
	s.shadow_color = Color(accent.r * 0.35, accent.g * 0.35, accent.b * 0.35, 0.55)
	s.shadow_size = 12
	s.shadow_offset = Vector2(0, 4)
	return s


static func apply_menu_profile_button(btn: Button) -> void:
	var empty := StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty)
	btn.add_theme_stylebox_override("hover", empty)
	btn.add_theme_stylebox_override("pressed", empty)
	btn.add_theme_stylebox_override("focus", empty)


static func apply_menu_play_button(btn: Button) -> void:
	btn.add_theme_stylebox_override("normal", menu_play_yellow_normal())
	btn.add_theme_stylebox_override("hover", menu_play_yellow_hover())
	btn.add_theme_stylebox_override("pressed", menu_play_yellow_pressed())
	btn.add_theme_stylebox_override("focus", menu_play_yellow_hover())
	btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	btn.add_theme_color_override("font_pressed_color", Color(0.95, 0.95, 0.95, 1))
	btn.add_theme_color_override("font_outline_color", Color(0.05, 0.18, 0.42, 0.95))
	btn.add_theme_constant_override("outline_size", 8)
	btn.add_theme_font_size_override("font_size", 46)


static func apply_menu_side_button(btn: Button, accent: Color = Color(0.40, 0.78, 1.0)) -> void:
	var normal := menu_side_button(accent)
	var hover := menu_side_button(accent.lightened(0.15))
	hover.shadow_size = 16
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", menu_side_button(accent.darkened(0.12)))
	btn.add_theme_stylebox_override("focus", hover)


# --- Booster modal (Food Hunt "Booster Up") ---

static func booster_modal_body() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.96, 0.84, 0.70)
	s.border_color = Color(0.72, 0.48, 0.30)
	s.set_border_width_all(8)
	s.set_corner_radius_all(48)
	s.shadow_color = Color(0.0, 0.0, 0.0, 0.38)
	s.shadow_size = 20
	s.shadow_offset = Vector2(0, 10)
	s.set_content_margin(Side.SIDE_LEFT, 28)
	s.set_content_margin(Side.SIDE_RIGHT, 28)
	s.set_content_margin(Side.SIDE_TOP, 52)
	s.set_content_margin(Side.SIDE_BOTTOM, 28)
	return s


static func booster_modal_header() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.36, 0.22, 0.14)
	s.border_color = Color(0.22, 0.12, 0.08)
	s.set_border_width_all(4)
	s.set_corner_radius_all(22)
	s.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	s.shadow_size = 8
	s.shadow_offset = Vector2(0, 4)
	s.set_content_margin(Side.SIDE_LEFT, 32)
	s.set_content_margin(Side.SIDE_RIGHT, 32)
	s.set_content_margin(Side.SIDE_TOP, 10)
	s.set_content_margin(Side.SIDE_BOTTOM, 10)
	return s


static func booster_modal_icon_pad(accent: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.96, 0.78, 0.82)
	s.border_color = accent.darkened(0.18)
	s.set_border_width_all(5)
	s.set_corner_radius_all(28)
	s.shadow_color = Color(accent.r * 0.2, accent.g * 0.2, accent.b * 0.2, 0.45)
	s.shadow_size = 10
	s.shadow_offset = Vector2(0, 5)
	s.set_content_margin_all(18)
	return s


static func booster_modal_close() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.91, 0.30, 0.24)
	s.border_color = Color(1.0, 1.0, 1.0, 0.95)
	s.set_border_width_all(3)
	s.set_corner_radius_all(30)
	s.shadow_color = Color(0.35, 0.05, 0.05, 0.55)
	s.shadow_size = 6
	s.shadow_offset = Vector2(0, 3)
	return s


static func booster_modal_buy_button() -> StyleBoxFlat:
	var s := shop_price_button()
	s.set_corner_radius_all(28)
	s.set_content_margin(Side.SIDE_LEFT, 24)
	s.set_content_margin(Side.SIDE_RIGHT, 24)
	s.set_content_margin(Side.SIDE_TOP, 14)
	s.set_content_margin(Side.SIDE_BOTTOM, 14)
	s.shadow_size = 8
	return s


static func booster_modal_buy_hover() -> StyleBoxFlat:
	var s := booster_modal_buy_button()
	s.bg_color = Color(0.38, 0.90, 0.48)
	return s


static func booster_modal_buy_pressed() -> StyleBoxFlat:
	var s := booster_modal_buy_button()
	s.bg_color = Color(0.20, 0.68, 0.32)
	s.shadow_size = 3
	return s


static func apply_booster_modal_buy_button(btn: Button) -> void:
	btn.add_theme_stylebox_override("normal", booster_modal_buy_button())
	btn.add_theme_stylebox_override("hover", booster_modal_buy_hover())
	btn.add_theme_stylebox_override("pressed", booster_modal_buy_pressed())
	btn.add_theme_stylebox_override("focus", booster_modal_buy_hover())
	btn.add_theme_stylebox_override("disabled", booster_modal_buy_pressed())
	btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	btn.add_theme_color_override("font_disabled_color", Color(0.88, 0.94, 0.90, 1.0))
	btn.add_theme_font_size_override("font_size", 34)


# --- Спецэффекты минералов (лёд / сплав / печать) ---

static func cell_frozen(base_color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = base_color.lerp(Color(0.75, 0.92, 1.0), 0.55)
	s.set_corner_radius_all(8)
	s.border_color = Color(0.85, 0.97, 1.0, 0.9)
	s.set_border_width_all(3)
	s.shadow_color = Color(0.6, 0.85, 1.0, 0.45)
	s.shadow_size = 6
	return s


static func cell_sealed(base_color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = base_color.darkened(0.35)
	s.set_corner_radius_all(6)
	s.border_color = Color(0.85, 0.30, 0.85, 0.85)
	s.set_border_width_all(3)
	s.shadow_color = Color(0.55, 0.10, 0.55, 0.4)
	s.shadow_size = 6
	return s
