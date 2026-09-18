extends Control
## SpaceBackground — яркий космический градиент + звёзды + планета.

@export var star_count: int = 120

var _stars: Array[Dictionary] = []
var _time: float = 0.0


func _ready() -> void:
	z_index = -100
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_generate_stars()
	resized.connect(queue_redraw)
	VisualFxService.quality_changed.connect(_on_fx_quality_changed)
	_apply_fx_quality()
	call_deferred("queue_redraw")


func _on_fx_quality_changed(_quality: int) -> void:
	_apply_fx_quality()


func _apply_fx_quality() -> void:
	var target_stars := VisualFxService.star_count_default()
	if star_count != target_stars:
		star_count = target_stars
		_generate_stars()
	set_process(VisualFxService.background_anim_enabled())
	queue_redraw()


func _generate_stars() -> void:
	_stars.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in star_count:
		_stars.append({
			"pos": Vector2(rng.randf(), rng.randf()),
			"size": rng.randf_range(1.5, 4.0),
			"bright": rng.randf_range(0.4, 1.0),
			"speed": rng.randf_range(1.0, 3.5),
			"phase": rng.randf_range(0, TAU),
		})


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w < 2.0:
		return

	# Яркий градиент (не чёрный!)
	for step in 24:
		var t := float(step) / 23.0
		var y0 := h * t
		var y1 := h * (t + 1.0 / 23.0) + 1.0
		var c := Color(0.14, 0.08, 0.32).lerp(Color(0.06, 0.14, 0.38), t)
		draw_rect(Rect2(0, y0, w, y1 - y0), c)

	# Туманности
	draw_circle(Vector2(w * 0.78, h * 0.18), 200, Color(0.75, 0.25, 0.65, 0.10))
	draw_circle(Vector2(w * 0.22, h * 0.42), 160, Color(0.20, 0.45, 0.90, 0.08))
	draw_circle(Vector2(w * 0.55, h * 0.55), 120, Color(0.40, 0.20, 0.80, 0.06))

	# Планета
	var pc := Vector2(w * 0.82, h * 0.72)
	var pr := minf(w, h) * 0.09
	draw_circle(pc, pr + 10, Color(0.3, 0.5, 0.9, 0.12))
	draw_circle(pc, pr, Color(0.28, 0.42, 0.72, 0.85))
	draw_circle(pc + Vector2(-pr * 0.3, -pr * 0.25), pr * 0.3, Color(0.45, 0.58, 0.82, 0.5))

	# Звёзды
	for star: Dictionary in _stars:
		var p := Vector2(star["pos"].x * w, star["pos"].y * h)
		var tw: float = star["bright"] * (0.6 + 0.4 * sin(_time * star["speed"] + star["phase"]))
		draw_circle(p, star["size"], Color(1, 1, 1, tw))
