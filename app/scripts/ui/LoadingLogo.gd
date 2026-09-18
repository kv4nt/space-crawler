extends Control
## LoadingLogo — пузырьковый 3D-логотип в стиле Food Hunt.

const LINE1 := "STARVEIN"
const LINE2 := "MINING"

var _pulse: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(720.0, 240.0)
	resized.connect(queue_redraw)


func _process(delta: float) -> void:
	_pulse += delta
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var w := size.x
	var bob := sin(_pulse * 2.0) * 3.0

	_draw_bubble_line(
		font,
		LINE1,
		Vector2(w * 0.5, size.y * 0.34 + bob),
		78,
		Color(1.0, 0.90, 0.18),
		Color(0.95, 0.55, 0.10)
	)
	_draw_bubble_line(
		font,
		LINE2,
		Vector2(w * 0.5, size.y * 0.72 + bob * 0.6),
		72,
		Color(0.55, 0.88, 1.0),
		Color(0.12, 0.22, 0.62)
	)


func _draw_bubble_line(
	font: Font,
	text: String,
	center: Vector2,
	font_size: int,
	fill: Color,
	shadow_tint: Color
) -> void:
	var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var pos := Vector2(center.x - tw * 0.5, center.y)
	var outline := Color(0.08, 0.12, 0.48)

	for off: Vector2 in [Vector2(6, 10), Vector2(4, 6)]:
		draw_string(
			font,
			pos + off,
			text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			font_size,
			Color(shadow_tint.r, shadow_tint.g, shadow_tint.b, 0.55)
		)

	for ox in range(-4, 5):
		for oy in range(-4, 5):
			if absi(ox) + absi(oy) > 5:
				continue
			if ox == 0 and oy == 0:
				continue
			draw_string(
				font,
				pos + Vector2(ox, oy),
				text,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				font_size,
				outline
			)

	draw_string(
		font,
		pos + Vector2(-1.0, -2.0),
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		fill.lightened(0.18)
	)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, fill)
