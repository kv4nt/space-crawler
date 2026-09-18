extends Control
## LoadingBar — полоска загрузки с градиентом и зелёным «бусином» на конце.

const BAR_W := 560.0
const BAR_H := 26.0

var _progress: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(BAR_W + 12.0, BAR_H + 12.0)
	resized.connect(queue_redraw)


func set_progress(value: float) -> void:
	var next := clampf(value, 0.0, 1.0)
	if is_equal_approx(next, _progress):
		return
	_progress = next
	queue_redraw()


func _draw() -> void:
	var cx := size.x * 0.5
	var bar_rect := Rect2(cx - BAR_W * 0.5, (size.y - BAR_H) * 0.5, BAR_W, BAR_H)
	var radius := int(BAR_H * 0.5)

	var frame := StyleBoxFlat.new()
	frame.bg_color = Color(1.0, 1.0, 1.0, 0.10)
	frame.border_color = Color(1.0, 1.0, 1.0, 0.95)
	frame.set_border_width_all(3)
	frame.set_corner_radius_all(radius)
	draw_style_box(frame, bar_rect)

	var inner := bar_rect.grow(-4.0)
	var fill_w := inner.size.x * _progress
	if fill_w <= 1.0:
		return

	var fill_rect := Rect2(inner.position, Vector2(fill_w, inner.size.y))
	var steps := maxi(int(fill_w / 3.0), 1)
	var slice_w := fill_w / float(steps)
	for i in steps:
		var t := float(i) / float(steps)
		var color := Color(0.68, 0.36, 0.96).lerp(Color(0.22, 0.14, 0.72), t)
		draw_rect(
			Rect2(fill_rect.position.x + slice_w * i, fill_rect.position.y, slice_w + 1.0, fill_rect.size.y),
			color
		)

	var clip_sb := StyleBoxFlat.new()
	clip_sb.bg_color = Color(1.0, 1.0, 1.0, 0.0)
	clip_sb.set_corner_radius_all(int(inner.size.y * 0.5))
	draw_style_box(clip_sb, inner)

	var tip_x := fill_rect.position.x + fill_w
	var tip_y := inner.position.y + inner.size.y * 0.5
	var tip := Vector2(tip_x, tip_y)
	draw_circle(tip, 16.0, Color(0.35, 1.0, 0.50, 0.30))
	draw_circle(tip, 10.0, Color(0.45, 1.0, 0.55, 0.92))
	draw_circle(tip, 5.5, Color(0.90, 1.0, 0.92, 1.0))
