extends Control
## MenuArt — декоративный флот кораблей и свечение заголовка.

var _time: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w < 1.0:
		return

	var cx := w * 0.5
	var cy := h * 0.38

	# Glow behind ships
	draw_circle(Vector2(cx, cy), 120, Color(0.2, 0.4, 0.9, 0.12))
	draw_circle(Vector2(cx, cy), 80, Color(0.3, 0.6, 1.0, 0.08))

	# Three ships in formation
	var colors := [
		Color(0.90, 0.30, 0.35),
		Color(0.30, 0.80, 0.55),
		Color(0.35, 0.60, 0.95),
	]
	var offsets := [-80.0, 0.0, 80.0]
	for i in 3:
		var bob := sin(_time * 1.5 + i * 1.2) * 6.0
		var pos := Vector2(cx + offsets[i], cy + bob)
		_draw_ship(pos, colors[i], 1.0 + sin(_time + i) * 0.05)

	# Mining beams
	for i in 3:
		var bob := sin(_time * 1.5 + i * 1.2) * 6.0
		var from := Vector2(cx + offsets[i], cy + bob + 20)
		var to := from + Vector2(0, 40 + sin(_time * 2 + i) * 10)
		draw_line(from, to, colors[i].darkened(0.2), 2.0)


func _draw_ship(center: Vector2, color: Color, scale: float) -> void:
	var hull := PackedVector2Array([
		center + Vector2(0, -22 * scale),
		center + Vector2(14 * scale, 8 * scale),
		center + Vector2(6 * scale, 16 * scale),
		center + Vector2(0, 10 * scale),
		center + Vector2(-6 * scale, 16 * scale),
		center + Vector2(-14 * scale, 8 * scale),
	])
	draw_colored_polygon(hull, color)
	draw_polyline(hull, color.lightened(0.3), 2.0, true)

	# Engine glow
	draw_circle(center + Vector2(0, 14 * scale), 4 * scale, Color(0.4, 0.8, 1.0, 0.8))
