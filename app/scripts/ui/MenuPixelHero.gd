extends Control
## MenuPixelHero — летающий корабль с минералом (экран загрузки / меню).

const MINERAL_COLOR := Color(0.32, 0.58, 0.96)
const SHIP_COLOR := Color(0.28, 0.72, 0.95)

var _time: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	resized.connect(queue_redraw)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w < 10.0:
		return

	var bob := sin(_time * 2.2) * 10.0
	var sway := sin(_time * 1.4) * 18.0
	var center := Vector2(w * 0.5 + sway, h * 0.46 + bob)
	var tilt := sin(_time * 1.8) * 0.12

	_draw_ship_shadow(center + Vector2(0, 58))
	_draw_flying_ship(center, 2.4, tilt)
	_draw_mineral_stacks(w, h)


func _draw_ship_shadow(at: Vector2) -> void:
	draw_circle(at, 52.0, Color(0.08, 0.06, 0.14, 0.22))
	draw_circle(at, 34.0, Color(0.08, 0.06, 0.14, 0.16))


func _draw_flying_ship(center: Vector2, scale: float, tilt: float) -> void:
	var sc := scale

	for side in [-1, 1]:
		var wing := PackedVector2Array([
			center + Vector2(6 * side * sc, 2 * sc).rotated(tilt),
			center + Vector2(28 * side * sc, 14 * sc).rotated(tilt),
			center + Vector2(20 * side * sc, 24 * sc).rotated(tilt),
			center + Vector2(6 * side * sc, 16 * sc).rotated(tilt),
		])
		draw_colored_polygon(wing, SHIP_COLOR.darkened(0.28))

	var hull := PackedVector2Array([
		center + Vector2(0, -42 * sc).rotated(tilt),
		center + Vector2(16 * sc, -8 * sc).rotated(tilt),
		center + Vector2(18 * sc, 18 * sc).rotated(tilt),
		center + Vector2(10 * sc, 30 * sc).rotated(tilt),
		center + Vector2(0, 24 * sc).rotated(tilt),
		center + Vector2(-10 * sc, 30 * sc).rotated(tilt),
		center + Vector2(-18 * sc, 18 * sc).rotated(tilt),
		center + Vector2(-16 * sc, -8 * sc).rotated(tilt),
	])
	draw_colored_polygon(hull, SHIP_COLOR.darkened(0.14))
	draw_polyline(hull, Color(1, 1, 1, 0.35), 2.5, true)

	var mineral_size := 30.0 * sc
	var cargo := center + Vector2(0, 4 * sc).rotated(tilt)
	var mineral_rect := Rect2(
		cargo.x - mineral_size * 0.5,
		cargo.y - mineral_size * 0.5,
		mineral_size,
		mineral_size,
	)
	var mineral_sb := StyleBoxFlat.new()
	mineral_sb.bg_color = MINERAL_COLOR
	mineral_sb.border_color = MINERAL_COLOR.lightened(0.35)
	mineral_sb.set_border_width_all(4)
	mineral_sb.set_corner_radius_all(8)
	draw_style_box(mineral_sb, mineral_rect)

	var font := ThemeDB.fallback_font
	var num := "7"
	var font_size := int(16 * sc)
	var tw := font.get_string_size(num, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(
		font,
		Vector2(cargo.x - tw * 0.5, cargo.y + mineral_size * 0.28),
		num,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		Color.WHITE,
	)

	var cockpit := center + Vector2(0, -14 * sc).rotated(tilt)
	draw_circle(cockpit, 9 * sc, Color(0.42, 0.80, 1.0, 0.95))
	draw_circle(cockpit, 5.5 * sc, Color(0.72, 0.92, 1.0, 0.85))

	var flame_center := center + Vector2(0, 34 * sc).rotated(tilt)
	for i in 3:
		var flicker := 0.75 + sin(_time * 14.0 + i * 2.1) * 0.25
		var flame := PackedVector2Array([
			flame_center + Vector2(-5 * sc, 0),
			flame_center + Vector2(5 * sc, 0),
			flame_center + Vector2(0, (18 + i * 4) * sc * flicker),
		])
		draw_colored_polygon(flame, Color(1.0, 0.55 + i * 0.08, 0.18, 0.85 - i * 0.15))


func _draw_mineral_stacks(w: float, h: float) -> void:
	var colors: Array = [
		Color(0.92, 0.30, 0.38),
		Color(0.28, 0.85, 0.52),
		Color(0.95, 0.78, 0.22),
	]
	var stack_w := 48.0
	var gap := 14.0
	var total := colors.size() * stack_w + (colors.size() - 1) * gap
	var sx := (w - total) * 0.5
	var sy := h * 0.68
	var bob_base := sin(_time * 2.5) * 3.0

	for i in colors.size():
		var cx := sx + i * (stack_w + gap) + stack_w * 0.5
		var bob := bob_base + sin(_time * 3.0 + i * 1.5) * 4.0
		var slot := StyleBoxFlat.new()
		slot.bg_color = Color(0.18, 0.20, 0.34, 0.95)
		slot.set_corner_radius_all(10)
		draw_style_box(slot, Rect2(cx - stack_w * 0.5, sy + bob - 4, stack_w, 52))
		for layer in 3:
			var c: Color = colors[i].darkened(layer * 0.07)
			var tile := StyleBoxFlat.new()
			tile.bg_color = c
			tile.set_corner_radius_all(6)
			draw_style_box(tile, Rect2(cx - 16, sy + bob - layer * 14, 32, 32))
