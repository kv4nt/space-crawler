extends Control
## ShopCoinArt — иконки монет/кредитов разного «объёма» для карточек.


@export var tier: int = 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(88, 88)
	resized.connect(queue_redraw)


func set_tier(value: int) -> void:
	tier = clampi(value, 0, 5)
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	match tier:
		0:
			_draw_coin(center, 24.0)
		1:
			_draw_coin(center + Vector2(-10, 8), 18.0)
			_draw_coin(center + Vector2(8, -6), 22.0)
		2:
			for i in 3:
				_draw_coin(center + Vector2(-12 + i * 12, 8 - i * 4), 16.0 + i * 2.0)
		3:
			_draw_pouch(center)
		4:
			_draw_chest(center)
		_:
			_draw_vault(center)


func _draw_coin(center: Vector2, radius: float) -> void:
	GameTheme.draw_coin(self, center, radius)


func _draw_pouch(center: Vector2) -> void:
	var body := PackedVector2Array([
		center + Vector2(-28, -8),
		center + Vector2(28, -8),
		center + Vector2(34, 24),
		center + Vector2(-34, 24),
	])
	draw_colored_polygon(body, Color(0.72, 0.38, 0.18))
	draw_polyline(body, Color(0.45, 0.22, 0.08), 3.0, true)
	draw_arc(center + Vector2(0, -8), 18.0, PI, TAU, 16, Color(0.82, 0.48, 0.22), 6.0)
	_draw_coin(center + Vector2(0, 8), 14.0)


func _draw_chest(center: Vector2) -> void:
	var body := Rect2(center.x - 34, center.y - 8, 68, 40)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.82, 0.18, 0.18)
	sb.border_color = Color(0.55, 0.08, 0.08)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(8)
	draw_style_box(sb, body)
	draw_rect(Rect2(center.x - 34, center.y - 8, 68, 12), Color(0.95, 0.78, 0.12))
	for i in 3:
		_draw_coin(center + Vector2(-16 + i * 16, 10), 10.0)


func _draw_vault(center: Vector2) -> void:
	var body := Rect2(center.x - 36, center.y - 18, 72, 52)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.42, 0.22, 0.72)
	sb.border_color = Color(0.95, 0.78, 0.12)
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(10)
	draw_style_box(sb, body)
	draw_circle(center + Vector2(0, 6), 10.0, Color(0.95, 0.78, 0.12))
	for i in 4:
		_draw_coin(center + Vector2(-24 + i * 16, -2), 9.0)
