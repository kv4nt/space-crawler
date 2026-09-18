extends Control
## BoosterModalWood — лёгкая имитация деревянной текстуры для модалки.


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	resized.connect(queue_redraw)


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w < 10.0:
		return

	var base := Color(0.96, 0.84, 0.70)
	draw_rect(Rect2(0.0, 0.0, w, h), base)

	var stripe_w := 14.0
	var stripes := int(w / stripe_w) + 2
	for i in stripes:
		var sx := i * stripe_w
		var shade := 0.97 + float(i % 3) * 0.015
		draw_rect(
			Rect2(sx, 0.0, stripe_w * 0.55, h),
			base * Color(shade, shade * 0.98, shade * 0.94, 0.35)
		)

	for i in 5:
		var gy := h * (0.12 + i * 0.18)
		draw_line(
			Vector2(8.0, gy),
			Vector2(w - 8.0, gy + sin(i * 1.7) * 3.0),
			Color(0.55, 0.36, 0.22, 0.08),
			2.0
		)
