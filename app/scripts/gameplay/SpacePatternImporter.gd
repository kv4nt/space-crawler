class_name SpacePatternImporter
extends RefCounted
## Пул из 10 PNG-фонов → сетка минералов. На каждом уровне — случайный фон и перестановка цветов.

const LEVELS_DIR := "res://data/levels/"
const BACKGROUND_COUNT: int = 10
const TARGET_W := 40
const TARGET_H := 40
const MIN_FILL_CELLS := 70

const LEVEL_THEMES: Dictionary = {
	1: "Космонавт",
	2: "Ракета",
	3: "НЛО",
	4: "Сатурн",
	5: "Полёт",
	6: "Планета",
	7: "Галактика",
	8: "Космопейзаж",
	9: "Комета",
	10: "Старт",
}


static func path_for_background(index: int) -> String:
	return LEVELS_DIR + "level_%03d.png" % clampi(index, 1, BACKGROUND_COUNT)


static func has_background(index: int) -> bool:
	return FileAccess.file_exists(path_for_background(index))


static func theme_name(bg_index: int) -> String:
	return LEVEL_THEMES.get(clampi(bg_index, 1, BACKGROUND_COUNT), "Космос")


static func pick_background_index(global_id: int) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = global_id * 13337 + 17
	var available: Array[int] = []
	for i in range(1, BACKGROUND_COUNT + 1):
		if has_background(i):
			available.append(i)
	if available.is_empty():
		return 1
	return available[rng.randi_range(0, available.size() - 1)]


static func count_distinct_colors(pattern: Array) -> int:
	var used: Dictionary = {}
	for row in pattern:
		var line := String(row)
		for i in range(line.length()):
			var ch := line[i]
			if ch == "." or ch == " ":
				continue
			var tier := PatternCodec.tier_from_char(ch)
			if tier >= 0:
				used[tier] = true
	return used.size()


static func try_import_background(bg_index: int, max_colors: int) -> Array:
	var path := path_for_background(bg_index)
	if not FileAccess.file_exists(path):
		return []
	var img := Image.load_from_file(path)
	if img == null or img.is_empty():
		return []
	return _image_to_pattern(img, max_colors)


static func remap_pattern_colors(pattern: Array, rng: RandomNumberGenerator) -> Array:
	if pattern.is_empty():
		return pattern

	var used: Array[int] = []
	for row in pattern:
		var line := String(row)
		for i in range(line.length()):
			var ch := line[i]
			if ch == "." or ch == " ":
				continue
			var c := PatternCodec.tier_from_char(ch)
			if c < 0:
				continue
			if used.find(c) == -1:
				used.append(c)
	if used.is_empty():
		return pattern

	used.sort()
	var pool: Array[int] = []
	for i in range(GameBalance.MAX_MINERAL_COLORS):
		pool.append(i)
	_shuffle_array(pool, rng)

	var mapping: Dictionary = {}
	for i in range(used.size()):
		mapping[used[i]] = pool[i]

	var lines: Array = []
	for row in pattern:
		var line := String(row)
		var out := ""
		for i in range(line.length()):
			var ch := line[i]
			if ch == "." or ch == " ":
				out += ch
				continue
			var old_c := PatternCodec.tier_from_char(ch)
			if old_c < 0:
				out += ch
				continue
			out += PatternCodec.char_from_tier(int(mapping.get(old_c, old_c)))
		lines.append(out)
	return lines


static func _shuffle_array(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


static func _image_to_pattern(img: Image, max_colors: int) -> Array:
	img = img.duplicate()
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)

	var src_w := img.get_width()
	var src_h := img.get_height()
	var scale := minf(float(TARGET_W) / float(src_w), float(TARGET_H) / float(src_h))
	var draw_w := float(src_w) * scale
	var draw_h := float(src_h) * scale
	var off_x := (float(TARGET_W) - draw_w) / 2.0
	var off_y := (float(TARGET_H) - draw_h) / 2.0
	var lines: Array = []
	var filled := 0

	for gy in range(TARGET_H):
		var line := ""
		for gx in range(TARGET_W):
			var avg := _average_source_rect(img, gx, gy, off_x, off_y, scale)
			if avg.a < 0.001:
				line += "."
				continue
			var px: Color = avg
			if _is_background(px):
				line += "."
				continue
			var idx := _map_to_mineral_index(px, max_colors)
			line += PatternCodec.char_from_tier(idx)
			filled += 1
		lines.append(line)

	if filled < MIN_FILL_CELLS:
		return []
	return lines


static func _average_source_rect(
	img: Image, gx: int, gy: int, off_x: float, off_y: float, scale: float,
) -> Color:
	var src_w := img.get_width()
	var src_h := img.get_height()
	var sx0 := int(floor((float(gx) - off_x) / scale))
	var sx1 := int(ceil((float(gx + 1) - off_x) / scale))
	var sy0 := int(floor((float(gy) - off_y) / scale))
	var sy1 := int(ceil((float(gy + 1) - off_y) / scale))
	if sx1 <= 0 or sy1 <= 0 or sx0 >= src_w or sy0 >= src_h:
		return Color(0, 0, 0, 0)
	sx0 = clampi(sx0, 0, src_w - 1)
	sx1 = clampi(sx1, 0, src_w)
	sy0 = clampi(sy0, 0, src_h - 1)
	sy1 = clampi(sy1, 0, src_h)
	if sx1 <= sx0 or sy1 <= sy0:
		return Color(0, 0, 0, 0)

	var r_sum := 0.0
	var g_sum := 0.0
	var b_sum := 0.0
	var a_sum := 0.0
	var count := 0
	for sy in range(sy0, sy1):
		for sx in range(sx0, sx1):
			var px: Color = img.get_pixel(sx, sy)
			r_sum += px.r
			g_sum += px.g
			b_sum += px.b
			a_sum += px.a
			count += 1
	if count == 0:
		return Color(0, 0, 0, 0)
	return Color(r_sum / count, g_sum / count, b_sum / count, a_sum / count)


static func _is_background(c: Color) -> bool:
	if c.a < 0.20:
		return true
	var lum := c.r * 0.299 + c.g * 0.587 + c.b * 0.114
	var sat := _saturation(c)
	if lum > 0.94 and sat < 0.08:
		return true
	return false


static func _saturation(c: Color) -> float:
	var mx := maxf(c.r, maxf(c.g, c.b))
	var mn := minf(c.r, minf(c.g, c.b))
	if mx <= 0.001:
		return 0.0
	return (mx - mn) / mx


static func _color_distance(a: Color, b: Color) -> float:
	var la := _rgb_to_lab(a)
	var lb := _rgb_to_lab(b)
	var dl := la.x - lb.x
	var da := la.y - lb.y
	var db := la.z - lb.z
	return sqrt(dl * dl + da * da + db * db)


static func _rgb_to_lab(c: Color) -> Vector3:
	var r := _linearize(c.r)
	var g := _linearize(c.g)
	var b := _linearize(c.b)
	var x := r * 0.4124564 + g * 0.3575761 + b * 0.1804375
	var y := r * 0.2126729 + g * 0.7151522 + b * 0.0721750
	var z := r * 0.0193339 + g * 0.1191920 + b * 0.9503041
	x /= 0.95047
	y /= 1.0
	z /= 1.08883
	x = _lab_f(x)
	y = _lab_f(y)
	z = _lab_f(z)
	return Vector3(116.0 * y - 16.0, 500.0 * (x - y), 200.0 * (y - z))


static func _linearize(v: float) -> float:
	if v <= 0.04045:
		return v / 12.92
	return pow((v + 0.055) / 1.055, 2.4)


static func _lab_f(t: float) -> float:
	if t > 0.008856:
		return pow(t, 1.0 / 3.0)
	return 7.787 * t + 16.0 / 116.0


static func _map_to_mineral_index(color: Color, max_colors: int) -> int:
	var best := 0
	var best_d := 999999.0
	var limit := mini(max_colors, GameBalance.MINERAL_COLORS.size())
	var blueish := color.b > color.r * 1.02 and color.b >= color.g * 0.92
	for i in range(limit):
		var d := _color_distance(color, GameBalance.MINERAL_COLORS[i])
		if blueish:
			if i in [2, 12, 13, 19]:
				d *= 0.55
			if i in [5, 10, 11]:
				d *= 1.45
		if d < best_d:
			best_d = d
			best = i
	return best
