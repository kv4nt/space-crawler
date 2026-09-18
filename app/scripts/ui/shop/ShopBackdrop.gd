extends Control
## ShopBackdrop — фиолетовый фон с ромбовым паттерном.


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	resized.connect(queue_redraw)


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w < 10.0:
		return

	draw_rect(Rect2(0.0, 0.0, w, h), Color(0.28, 0.16, 0.42, 1.0))

	var step := 56.0
	var diamond := PackedVector2Array([
		Vector2(0, -10), Vector2(10, 0), Vector2(0, 10), Vector2(-10, 0)
	])
	var col := 0
	var x := -step * 0.5
	while x < w + step:
		var row := 0
		var y := -step * 0.5 + (float(col % 2) * step * 0.5)
		while y < h + step:
			var center := Vector2(x, y)
			var poly: PackedVector2Array = []
			for p in diamond:
				poly.append(center + p)
			draw_colored_polygon(poly, Color(0.32, 0.20, 0.48, 0.55))
			draw_polyline(poly, Color(0.38, 0.24, 0.56, 0.35), 1.5, true)
			y += step
			row += 1
		x += step
		col += 1
