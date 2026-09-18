extends Control
## MenuGameTitle — пузырьковый логотип игры на главном экране.

const LINE1 := "STARVEIN"
const LINE2 := "FRONTIER PROTOCOL"

var _pulse: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(680.0, 200.0)
	resized.connect(queue_redraw)


func _process(delta: float) -> void:
	_pulse += delta
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var w := size.x
	var h := size.y
	var bob := sin(_pulse * 1.8) * 2.5
	var glow_alpha := 0.10 + sin(_pulse * 2.4) * 0.04

	draw_circle(Vector2(w * 0.5, h * 0.48), 140.0, Color(0.22, 0.38, 0.92, glow_alpha))
	draw_circle(Vector2(w * 0.5, h * 0.48), 88.0, Color(0.45, 0.72, 1.0, glow_alpha * 0.7))

	for i in 5:
		var angle := _pulse * 0.7 + float(i) * TAU / 5.0
		var radius := 118.0 + sin(_pulse * 2.0 + i) * 8.0
		var spark := Vector2(w * 0.5 + cos(angle) * radius, h * 0.48 + sin(angle) * radius * 0.35)
		var spark_alpha := 0.35 + sin(_pulse * 3.0 + i * 1.4) * 0.25
		draw_circle(spark, 2.5, Color(1.0, 0.95, 0.65, spark_alpha))

	_draw_bubble_line(
		font,
		LINE1,
		Vector2(w * 0.5, h * 0.38 + bob),
		62,
		Color(1.0, 0.90, 0.18),
		Color(0.95, 0.55, 0.10)
	)
	_draw_bubble_line(
		font,
		LINE2,
		Vector2(w * 0.5, h * 0.78 + bob * 0.5),
		24,
		Color(0.62, 0.90, 1.0),
		Color(0.10, 0.28, 0.68)
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
	var outline := Color(0.06, 0.10, 0.42)

	for off: Vector2 in [Vector2(5, 8), Vector2(3, 5)]:
		draw_string(
			font,
			pos + off,
			text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			font_size,
			Color(shadow_tint.r, shadow_tint.g, shadow_tint.b, 0.52)
		)

	for ox in range(-3, 4):
		for oy in range(-3, 4):
			if absi(ox) + absi(oy) > 4:
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
		fill.lightened(0.16)
	)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, fill)
