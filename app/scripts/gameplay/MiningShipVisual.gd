extends Node2D
class_name MiningShipVisual
## Шаттл: нос вверх (−Y). Поворот через Vector2.UP.angle_to(направление).


var ship_color: Color = Color.WHITE
var _lite_mode: bool = false
var _cargo_bay: Polygon2D
var _cargo_glow: Polygon2D
var _trail_l: CPUParticles2D
var _trail_r: CPUParticles2D
var _engine_glow_l: Polygon2D
var _engine_glow_r: Polygon2D


func _init(color: Color) -> void:
	ship_color = color
	_build()


func _build() -> void:
	_trail_l = _make_engine_trail(Vector2(-5, 20), Color(1.0, 0.52, 0.15, 0.92))
	_trail_r = _make_engine_trail(Vector2(5, 20), Color(1.0, 0.68, 0.22, 0.92))
	add_child(_trail_l)
	add_child(_trail_r)

	var shadow := Polygon2D.new()
	shadow.polygon = PackedVector2Array([
		Vector2(-12, 8), Vector2(12, 8), Vector2(10, 16), Vector2(-10, 16),
	])
	shadow.color = Color(0.06, 0.08, 0.14, 0.72)
	add_child(shadow)

	for sx in [-1, 1]:
		var wing := Polygon2D.new()
		var fx := float(sx)
		wing.polygon = PackedVector2Array([
			Vector2(4 * fx, 0), Vector2(18 * fx, 8), Vector2(14 * fx, 14), Vector2(4 * fx, 10),
		])
		wing.color = ship_color.darkened(0.30)
		add_child(wing)

	var hull := Polygon2D.new()
	hull.polygon = PackedVector2Array([
		Vector2(0, -30),
		Vector2(11, -10),
		Vector2(12, 8),
		Vector2(7, 18),
		Vector2(0, 14),
		Vector2(-7, 18),
		Vector2(-12, 8),
		Vector2(-11, -10),
	])
	hull.color = ship_color.darkened(0.12)
	add_child(hull)

	var hull_hi := Polygon2D.new()
	hull_hi.polygon = PackedVector2Array([
		Vector2(0, -26),
		Vector2(8, -8),
		Vector2(9, 6),
		Vector2(0, 10),
		Vector2(-9, 6),
		Vector2(-8, -8),
	])
	hull_hi.color = ship_color.lightened(0.14)
	add_child(hull_hi)

	var outline := Line2D.new()
	outline.points = hull.polygon
	outline.points.append(hull.polygon[0])
	outline.width = 1.6
	outline.default_color = Color(1.0, 1.0, 1.0, 0.30)
	outline.antialiased = true
	add_child(outline)

	var cockpit_ring := Polygon2D.new()
	cockpit_ring.polygon = _circle_points(Vector2(0, -12), 8.0, 16)
	cockpit_ring.color = Color(0.20, 0.26, 0.40, 1.0)
	add_child(cockpit_ring)

	var cockpit := Polygon2D.new()
	cockpit.polygon = _circle_points(Vector2(0, -12), 6.2, 14)
	cockpit.color = Color(0.42, 0.80, 1.0, 0.96)
	add_child(cockpit)

	var nose_spike := Polygon2D.new()
	nose_spike.polygon = PackedVector2Array([
		Vector2(0, -30), Vector2(-3, -22), Vector2(3, -22),
	])
	nose_spike.color = Color(1.0, 1.0, 1.0, 0.40)
	add_child(nose_spike)

	_cargo_bay = Polygon2D.new()
	_cargo_bay.polygon = PackedVector2Array([
		Vector2(-9, -2), Vector2(9, -2), Vector2(8, 10), Vector2(-8, 10),
	])
	_cargo_bay.color = ship_color
	_cargo_bay.visible = false
	add_child(_cargo_bay)

	_cargo_glow = Polygon2D.new()
	_cargo_glow.polygon = PackedVector2Array([
		Vector2(-10, -3), Vector2(10, -3), Vector2(10, 11), Vector2(-10, 11),
	])
	_cargo_glow.color = Color(1.0, 1.0, 1.0, 0.0)
	add_child(_cargo_glow)

	var cargo_frame := Line2D.new()
	cargo_frame.points = PackedVector2Array([
		Vector2(-9, -2), Vector2(9, -2), Vector2(8, 10), Vector2(-8, 10), Vector2(-9, -2),
	])
	cargo_frame.width = 1.4
	cargo_frame.default_color = Color(0.12, 0.14, 0.22, 0.95)
	cargo_frame.visible = false
	add_child(cargo_frame)
	_cargo_bay.set_meta("frame", cargo_frame)

	for sx in [-1, 1]:
		var nozzle := Polygon2D.new()
		var fx := float(sx)
		nozzle.polygon = PackedVector2Array([
			Vector2(4 * fx - 3, 14), Vector2(4 * fx + 3, 14),
			Vector2(4 * fx + 2, 20), Vector2(4 * fx - 2, 20),
		])
		nozzle.color = Color(0.16, 0.18, 0.26, 1.0)
		add_child(nozzle)

	_engine_glow_l = _make_engine_glow(Vector2(-5, 21))
	_engine_glow_r = _make_engine_glow(Vector2(5, 21))
	add_child(_engine_glow_l)
	add_child(_engine_glow_r)


func set_lite_mode(on: bool) -> void:
	_lite_mode = on
	var trail_amount := VisualFxService.ship_trail_amount(on)
	if is_instance_valid(_trail_l):
		_trail_l.amount = trail_amount
	if is_instance_valid(_trail_r):
		_trail_r.amount = trail_amount


func _make_engine_trail(at: Vector2, flame: Color) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = GameBalance.SHIP_TRAIL_PARTICLE_AMOUNT
	p.lifetime = 0.26
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINT
	p.direction = Vector2(0, 1)
	p.spread = 18.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 50.0
	p.initial_velocity_max = 105.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 2.8
	p.color = flame
	p.position = at
	return p


func _make_engine_glow(at: Vector2) -> Polygon2D:
	var glow := Polygon2D.new()
	glow.polygon = _circle_points(at, 3.2, 10)
	glow.color = Color(1.0, 0.75, 0.22, 0.88)
	glow.visible = false
	return glow


func _circle_points(center: Vector2, radius: float, segments: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(segments):
		var a := TAU * float(i) / float(segments)
		pts.append(center + Vector2(cos(a), sin(a)) * radius)
	return pts


func set_engine_active(on: bool) -> void:
	var trails_on := on and VisualFxService.particles_enabled() and _trail_l.amount > 0
	_trail_l.emitting = trails_on
	_trail_r.emitting = trails_on
	if is_instance_valid(_engine_glow_l):
		_engine_glow_l.visible = trails_on
	if is_instance_valid(_engine_glow_r):
		_engine_glow_r.visible = trails_on


func set_cargo_visible(on: bool) -> void:
	_cargo_bay.visible = on
	if on:
		_cargo_bay.color = ship_color
		_cargo_glow.color = Color(ship_color.lightened(0.35), 0.35)
	else:
		_cargo_glow.color = Color(1.0, 1.0, 1.0, 0.0)
	var frame: Variant = _cargo_bay.get_meta("frame", null)
	if frame is Line2D:
		(frame as Line2D).visible = on


func set_facing_direction(dir: Vector2) -> void:
	if dir.length_squared() > 0.0001:
		rotation = Vector2.UP.angle_to(dir.normalized())


func point_toward(target: Vector2) -> void:
	set_facing_direction(target - position)
