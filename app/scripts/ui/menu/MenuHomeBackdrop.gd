extends Control
## MenuHomeBackdrop — деревянный пол и «яма» по центру (Food Hunt home).


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	resized.connect(queue_redraw)


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w < 10.0:
		return

	var wall_h := h * 0.22
	var wall := Color(0.62, 0.46, 0.82)
	draw_rect(Rect2(0.0, 0.0, w, wall_h), wall)
	draw_rect(Rect2(0.0, 0.0, w, wall_h * 0.35), wall.lightened(0.08))

	var wood := Color(0.78, 0.58, 0.36)
	draw_rect(Rect2(0.0, wall_h, w, h - wall_h), wood.darkened(0.04))

	var plank_h := 44.0
	var planks := int((h - wall_h) / plank_h) + 2
	for i in planks:
		var py := wall_h + i * plank_h
		var shade := 0.88 + float(i % 2) * 0.12
		draw_rect(
			Rect2(0.0, py, w, plank_h - 2.0),
			wood * Color(shade, shade * 0.97, shade * 0.93, 1.0)
		)
		draw_line(Vector2(0.0, py), Vector2(w, py), Color(0.48, 0.32, 0.18, 0.35), 2.0)

	var hole_center := Vector2(w * 0.5, h * 0.52)
	draw_circle(hole_center, 92.0, Color(0.08, 0.05, 0.04, 0.98))
	draw_arc(hole_center, 92.0, 0.0, TAU, 64, Color(0.42, 0.26, 0.14, 0.90), 6.0)

	var glow := Color(0.62, 0.32, 0.95, 0.22)
	draw_circle(hole_center + Vector2(0.0, -58.0), 70.0, glow)
	draw_circle(hole_center + Vector2(0.0, -58.0), 42.0, Color(0.72, 0.42, 1.0, 0.14))
