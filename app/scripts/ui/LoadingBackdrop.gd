extends Control
## LoadingBackdrop — фиолетовая стена + деревянный пол (Food Hunt style).

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	resized.connect(queue_redraw)


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w < 10.0:
		return

	var floor_y := h * 0.62
	var wall := Color(0.58, 0.42, 0.82)
	var wall_top := Color(0.66, 0.50, 0.90)

	draw_rect(Rect2(0.0, 0.0, w, floor_y), wall)
	for band in 6:
		var t := float(band) / 6.0
		draw_rect(
			Rect2(0.0, floor_y * t * 0.25, w, floor_y * 0.06),
			Color(1.0, 1.0, 1.0, 0.04 - t * 0.004)
		)
	draw_rect(Rect2(0.0, 0.0, w, floor_y * 0.08), wall_top.lightened(0.06))

	var wood := Color(0.72, 0.52, 0.32)
	draw_rect(Rect2(0.0, floor_y, w, h - floor_y), wood.darkened(0.06))

	var plank_h := 46.0
	var planks := int((h - floor_y) / plank_h) + 2
	for i in planks:
		var py := floor_y + i * plank_h
		var shade := 0.90 + float(i % 2) * 0.10
		draw_rect(
			Rect2(0.0, py, w, plank_h - 2.0),
			wood * Color(shade, shade * 0.97, shade * 0.94, 1.0)
		)
		draw_line(Vector2(0.0, py), Vector2(w, py), Color(0.42, 0.28, 0.16, 0.45), 2.0)
