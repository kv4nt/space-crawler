extends PanelContainer
class_name EmptyCellPanel
## Клетка поля: пустая (штриховка), скрытая (?), закрытый цвет (🔒).

enum OverlayMode { NONE, QUESTION, LOCK }

var show_stripes: bool = false
var overlay_mode: OverlayMode = OverlayMode.NONE


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", GameTheme.cell_empty())
	resized.connect(queue_redraw)


func set_striped(on: bool) -> void:
	show_stripes = on
	queue_redraw()


func set_overlay(mode: OverlayMode) -> void:
	overlay_mode = mode
	queue_redraw()


func _draw() -> void:
	if size.x < 2.0 or size.y < 2.0:
		return
	if show_stripes:
		var stripe := Color(0.78, 0.88, 1.0, 0.34)
		var step := 5.0
		var w := size.x
		var h := size.y
		var count := int((w + h) / step) + 2
		for i in range(count):
			var off := i * step - h * 0.15
			draw_line(Vector2(off, 0.0), Vector2(off - h, h), stripe, 1.8)
		draw_rect(Rect2(Vector2(0.5, 0.5), size - Vector2(1.0, 1.0)), Color(0.82, 0.90, 1.0, 0.42), false, 1.6)
		var center := size * 0.5
		draw_circle(center, minf(w, h) * 0.08, Color(0.82, 0.90, 1.0, 0.25))

	match overlay_mode:
		OverlayMode.QUESTION:
			_draw_overlay_glyph("?", Color(0.92, 0.95, 1.0, 0.98), 0.58)
		OverlayMode.LOCK:
			_draw_overlay_glyph("🔒", Color(1.0, 1.0, 1.0, 0.78), 0.46)


func _draw_overlay_glyph(text: String, color: Color, size_ratio: float) -> void:
	var font := ThemeDB.fallback_font
	var fs := maxi(int(minf(size.x, size.y) * size_ratio), 12)
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var pos := Vector2(
		(size.x - text_size.x) * 0.5,
		(size.y + font.get_ascent(fs) - font.get_descent(fs)) * 0.5,
	)
	for ox in [-2, -1, 0, 1, 2]:
		for oy in [-2, -1, 0, 1, 2]:
			if ox == 0 and oy == 0:
				continue
			draw_string(
				font, pos + Vector2(ox, oy), text,
				HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.06, 0.08, 0.18, 0.88))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)
