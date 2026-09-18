extends Control
class_name BunkerFillGauge
## Индикатор заполнения бункера — светящийся «топливный» бак.

var fill_color: Color = Color(0.35, 0.55, 0.95)
var fill_ratio: float = 0.0
var blocked: bool = false
var _pulse: float = 0.0
var _progress_tween: Tween


func _ready() -> void:
	custom_minimum_size = Vector2(88, 22)
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


func set_progress(current: int, total: int, color: Color, is_blocked: bool = false) -> void:
	fill_ratio = clampf(float(current) / float(maxi(total, 1)), 0.0, 1.0)
	fill_color = color
	blocked = is_blocked
	queue_redraw()


func animate_progress(
	current: int, total: int, color: Color, duration: float = 0.38, instant: bool = false,
) -> void:
	if _progress_tween and _progress_tween.is_valid():
		_progress_tween.kill()
	var target := clampf(float(current) / float(maxi(total, 1)), 0.0, 1.0)
	if instant or duration <= 0.0:
		set_progress(current, total, color)
		return
	var start := fill_ratio
	_progress_tween = create_tween()
	_progress_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_progress_tween.tween_method(func(r: float) -> void:
		fill_ratio = r
		fill_color = color
		blocked = false
		queue_redraw()
	, start, target, duration)


func _draw() -> void:
	var pad := 4.0
	var track_h := 16.0
	var track_y := size.y - track_h - 2.0
	var track_w := size.x - pad * 2.0
	var track := Rect2(pad, track_y, track_w, track_h)

	var track_col := Color(0.06, 0.07, 0.12, 0.95) if not blocked else Color(0.10, 0.08, 0.14, 0.95)
	draw_rounded_rect(track, track_col, track_h * 0.5)

	var inner := track.grow(-2.0)
	draw_rounded_rect(inner, Color(0.04, 0.05, 0.09, 1.0), inner.size.y * 0.5)

	if fill_ratio > 0.01:
		var fill_w := maxf((inner.size.x - 2.0) * fill_ratio, 4.0)
		var fill_rect := Rect2(inner.position.x + 1.0, inner.position.y + 1.0, fill_w, inner.size.y - 2.0)
		var top := fill_color.lightened(0.35)
		var mid := fill_color
		var bot := fill_color.darkened(0.22)
		draw_rounded_rect(fill_rect, mid, fill_rect.size.y * 0.45)
		draw_rect(Rect2(fill_rect.position.x, fill_rect.position.y, fill_rect.size.x, fill_rect.size.y * 0.45), top)
		draw_rect(
			Rect2(fill_rect.position.x, fill_rect.position.y + fill_rect.size.y * 0.55, fill_rect.size.x, fill_rect.size.y * 0.45),
			bot,
		)
		var shine_w := fill_rect.size.x * 0.55
		var shine_alpha := 0.22 + sin(_pulse * 5.0) * 0.12
		draw_rect(
			Rect2(fill_rect.position.x + 2.0, fill_rect.position.y + 2.0, shine_w, fill_rect.size.y * 0.35),
			Color(1.0, 1.0, 1.0, shine_alpha),
		)
		if fill_ratio >= 0.98:
			var spark_x := fill_rect.position.x + fill_rect.size.x - 3.0
			draw_circle(Vector2(spark_x, fill_rect.position.y + fill_rect.size.y * 0.5), 3.0, Color(1, 1, 0.85, 0.85))

	var border_col := fill_color.lightened(0.45) if fill_ratio > 0.05 else Color(0.28, 0.32, 0.48)
	if blocked:
		border_col = Color(0.55, 0.35, 0.35)
	draw_rounded_rect(track, border_col, track_h * 0.5, false, 2.0)


func draw_rounded_rect(rect: Rect2, color: Color, radius: float, filled: bool = true, width: float = 1.0) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color if filled else Color(0, 0, 0, 0)
	if not filled:
		sb.border_color = color
		sb.set_border_width_all(int(width))
	sb.set_corner_radius_all(int(radius))
	draw_style_box(sb, rect)
