extends Control
class_name CircularProgressGauge
## Круговой индикатор прогресса — склад (заполнение) или слот (опустошение).

var fill_color: Color = Color(0.35, 0.72, 1.0)
var fill_ratio: float = 0.0
var show_percent: bool = true
var center_text: String = ""
var _pulse: float = 0.0
var _ratio_tween: Tween


func _ready() -> void:
	custom_minimum_size = Vector2(104, 104)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_pulse += delta
	queue_redraw()


func set_ratio(ratio: float, color: Color = fill_color) -> void:
	fill_ratio = clampf(ratio, 0.0, 1.0)
	fill_color = color
	queue_redraw()


func set_center_label(text: String, use_percent: bool = false) -> void:
	center_text = text
	show_percent = use_percent
	queue_redraw()


func animate_to(
	target_ratio: float, color: Color, label: String = "", duration: float = 0.38, instant: bool = false,
) -> void:
	if _ratio_tween and _ratio_tween.is_valid():
		_ratio_tween.kill()
	target_ratio = clampf(target_ratio, 0.0, 1.0)
	if label != "":
		set_center_label(label, false)
	if instant or duration <= 0.0:
		set_ratio(target_ratio, color)
		return
	var start := fill_ratio
	_ratio_tween = create_tween()
	_ratio_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_ratio_tween.tween_method(func(r: float) -> void:
		set_ratio(r, color)
	, start, target_ratio, duration)


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.42
	var track_w := maxf(radius * 0.30, 10.0)

	draw_circle(center, radius + track_w * 0.62, Color(0.02, 0.04, 0.10, 0.92))
	draw_arc(center, radius + track_w * 0.48, 0.0, TAU, 2.0, Color(0.45, 0.62, 1.0, 0.28), false)

	draw_arc(center, radius, 0.0, TAU, track_w, Color(0.08, 0.10, 0.18, 0.98), true)
	draw_arc(center, radius, 0.0, TAU, 2.0, Color(0.38, 0.46, 0.72, 0.55), false)

	if fill_ratio > 0.001:
		var start := -PI * 0.5
		var end := start + TAU * fill_ratio
		var glow := fill_color.lightened(0.18 + sin(_pulse * 3.0) * 0.10)
		draw_arc(center, radius, start, end, track_w, glow, true)
		draw_arc(center, radius, start, end, track_w * 0.42, fill_color.lightened(0.42), true)
		var tip := center + Vector2(cos(end), sin(end)) * radius
		draw_circle(tip, track_w * 0.42, fill_color.lightened(0.55))

	var font := ThemeDB.fallback_font
	var fs := int(radius * (0.92 if show_percent else 0.78))
	var text := "%d%%" % int(round(fill_ratio * 100.0)) if show_percent else center_text
	if text == "":
		return
	var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
	var text_pos := center - Vector2(tw * 0.5, fs * 0.34)
	for ox in [-2, -1, 0, 1, 2]:
		for oy in [-2, -1, 0, 1, 2]:
			if ox == 0 and oy == 0:
				continue
			draw_string(
				font, text_pos + Vector2(ox, oy), text,
				HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.04, 0.08, 0.18, 0.90))
	draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1.0, 0.98, 0.88))
