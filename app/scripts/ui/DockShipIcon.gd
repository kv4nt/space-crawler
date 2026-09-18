extends Control
class_name DockShipIcon
## Иконка корабля в слоте — тот же силуэт ракеты, что и у летящего шаттла.

var ship_color: Color = Color(0.3, 0.35, 0.45)
var _pulse: float = 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(68, 68)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	VisualFxService.quality_changed.connect(_on_fx_quality_changed)
	_apply_fx_quality()


func _on_fx_quality_changed(_quality: int) -> void:
	_apply_fx_quality()


func _apply_fx_quality() -> void:
	set_process(VisualFxService.decor_anim_enabled())
	queue_redraw()


func _process(delta: float) -> void:
	_pulse += delta
	queue_redraw()


func set_color(c: Color) -> void:
	ship_color = c
	queue_redraw()


func _draw() -> void:
	var cx := size.x * 0.5
	var cy := size.y * 0.48
	var bob := sin(_pulse * 2.0) * 1.2
	var s := minf(size.x, size.y) / 68.0
	var o := Vector2(cx, cy + bob)

	# Крылья.
	for side in [-1, 1]:
		var wing := PackedVector2Array([
			o + Vector2(4 * side, 2) * s,
			o + Vector2(20 * side, 8) * s,
			o + Vector2(14 * side, 13) * s,
			o + Vector2(4 * side, 10) * s,
		])
		draw_colored_polygon(wing, ship_color.darkened(0.28))

	# Корпус-ракета.
	var hull := PackedVector2Array([
		o + Vector2(0, -22) * s,
		o + Vector2(8, -8) * s,
		o + Vector2(10, 6) * s,
		o + Vector2(6, 14) * s,
		o + Vector2(0, 11) * s,
		o + Vector2(-6, 14) * s,
		o + Vector2(-10, 6) * s,
		o + Vector2(-8, -8) * s,
	])
	draw_colored_polygon(hull, ship_color)
	draw_polyline(hull, ship_color.lightened(0.22), 1.8 * s, true)

	# Купол кабины.
	if ship_color.a > 0.45:
		draw_circle(o + Vector2(0, -10) * s, 6.0 * s, Color(0.42, 0.78, 1.0, 0.92))
		draw_arc(o + Vector2(0, -10) * s, 6.0 * s, 0.0, TAU, 16, Color(0.18, 0.24, 0.38, 0.9), 1.2 * s)

	# Сопла.
	for sx in [-5, 5]:
		draw_colored_polygon(PackedVector2Array([
			o + Vector2(sx - 2, 11) * s,
			o + Vector2(sx + 2, 11) * s,
			o + Vector2(sx + 1, 15) * s,
			o + Vector2(sx - 1, 15) * s,
		]), Color(0.16, 0.18, 0.26, 1.0))

	if ship_color.a > 0.5:
		draw_circle(o + Vector2(-4, 13) * s, 2.0 * s, Color(1.0, 0.65, 0.2, 0.75))
		draw_circle(o + Vector2(4, 13) * s, 2.0 * s, Color(1.0, 0.65, 0.2, 0.75))
