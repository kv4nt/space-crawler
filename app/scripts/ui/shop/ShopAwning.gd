extends Control
## ShopAwning — красно-белый навес над магазином.


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0, 92)
	resized.connect(queue_redraw)


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w < 10.0:
		return

	var stripe_w := 44.0
	var stripes := int(w / stripe_w) + 2
	for i in stripes:
		var sx := i * stripe_w - stripe_w * 0.5
		var color := Color(0.92, 0.18, 0.22) if i % 2 == 0 else Color(0.98, 0.98, 0.98)
		draw_rect(Rect2(sx, 0.0, stripe_w, h * 0.78), color)

	draw_rect(Rect2(0.0, h * 0.78, w, h * 0.22), Color(0.55, 0.34, 0.18, 0.95))

	for i in 7:
		var scallop_x := w * (0.08 + i * 0.14)
		draw_arc(
			Vector2(scallop_x, h * 0.78),
			18.0,
			0.0,
			PI,
			16,
			Color(0.98, 0.98, 0.98, 0.95),
			8.0
		)
