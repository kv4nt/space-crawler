extends Control
## PlayfieldFunnel — «червоточина» между полем и доками (как лунка в Food Hunt).

var _time: float = 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(0, 72)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	VisualFxService.quality_changed.connect(_on_fx_quality_changed)
	_apply_fx_quality()


func _on_fx_quality_changed(_quality: int) -> void:
	_apply_fx_quality()


func _apply_fx_quality() -> void:
	set_process(VisualFxService.decor_anim_enabled())
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var cx := size.x * 0.5
	var cy := size.y * 0.5
	var r := minf(size.x, size.y) * 0.32

	# Платформа
	draw_circle(Vector2(cx, cy + 8), r + 14, Color(0.12, 0.14, 0.28, 0.9))
	draw_arc(Vector2(cx, cy + 8), r + 14, 0, TAU, 48, Color(0.35, 0.45, 0.75, 0.5), 3.0)

	# Воронка
	var pulse := 1.0 + sin(_time * 3.0) * 0.08
	draw_circle(Vector2(cx, cy), r * pulse, Color(0.02, 0.03, 0.08, 1.0))
	draw_arc(Vector2(cx, cy), r * pulse, 0, TAU, 64, Color(0.45, 0.65, 1.0, 0.7), 4.0)

	# Свечение
	draw_circle(Vector2(cx, cy), r * 0.55 * pulse, Color(0.25, 0.45, 0.95, 0.15 + sin(_time * 4.0) * 0.08))

	# Частицы всасывания
	for i in 6:
		var angle := _time * 2.5 + i * TAU / 6.0
		var dist := r * 0.7 + sin(_time * 3 + i) * 6.0
		var p := Vector2(cx + cos(angle) * dist, cy + sin(angle) * dist * 0.35)
		draw_circle(p, 3, Color(0.5, 0.75, 1.0, 0.6))
