class_name PixelArtLevels
extends RefCounted
## Авторские pixel-art уровни в стиле Food Hunt — детальные силуэты, палитры, звёзды.

const CANVAS: int = 32
const LEVEL_COUNT: int = 24
const ART_SCALE: int = 2

const THEMES: Array[String] = [
	"Космонавт", "Ракета", "НЛО", "Сатурн", "Станция", "Комета",
	"Лунная база", "Марсоход", "Спутник", "Галактика", "Чёрная дыра", "Телескоп",
	"Шаттл", "Пришелец", "Кристалл", "Туманность", "Метеор", "Затмение",
	"Кольцевой мир", "Портал", "Робот", "Двойная звезда", "Сверхновая", "Орбита",
]


static func resolve_index(global_id: int) -> int:
	return ((global_id - 1) % LEVEL_COUNT) + 1


static func try_build(global_id: int) -> Dictionary:
	var idx := resolve_index(global_id)
	return try_build_by_index(idx)


static func try_build_by_index(index: int) -> Dictionary:
	if index < 1 or index > LEVEL_COUNT:
		return {}
	var pattern: Array = build(index)
	if pattern.is_empty():
		return {}
	pattern = trim_pattern(pattern, 1)
	if count_filled(pattern) < 36:
		return {}
	var palette: Array = palette_for(index)
	return {
		"pattern": pattern,
		"color_palette": palette,
		"total_colors": palette.size(),
		"theme_name": THEMES[index - 1],
		"authored_index": index,
	}


static func count_filled(pattern: Array) -> int:
	return _count_filled(pattern)


static func trim_pattern(pattern: Array, pad: int = 1) -> Array:
	return _trim_to_content(pattern, pad)


static func build(index: int) -> Array:
	match index:
		1: return _astronaut()
		2: return _rocket()
		3: return _ufo()
		4: return _saturn()
		5: return _station()
		6: return _comet()
		7: return _moon_base()
		8: return _rover()
		9: return _satellite()
		10: return _galaxy()
		11: return _black_hole()
		12: return _telescope()
		13: return _shuttle()
		14: return _alien()
		15: return _crystal()
		16: return _nebula()
		17: return _meteor()
		18: return _eclipse()
		19: return _ring_world()
		20: return _portal()
		21: return _robot()
		22: return _binary_star()
		23: return _supernova()
		24: return _orbit()
	return []


static func palette_for(index: int) -> Array:
	match index:
		1: return [5, 6, 2, 8, 7]       # контур, белый, синий, оранж, коричневый
		2: return [5, 6, 0, 8, 3]       # контур, белый, красный, оранж, жёлтый
		3: return [5, 2, 3, 6, 4]       # контур, синий, жёлтый, белый, салат
		4: return [5, 2, 8, 3, 6]       # контур, синий, оранж, жёлтый, белый
		5: return [5, 6, 1, 3, 2]       # контур, белый, зелёный, жёлтый, синий
		6: return [5, 6, 2, 8, 0]       # контур, белый, синий, оранж, красный
		7: return [5, 6, 7, 0, 2]       # контур, белый, коричневый, красный, синий
		8: return [5, 7, 8, 6, 1]       # контур, коричневый, оранж, белый, зелёный
		9: return [5, 6, 2, 3, 1]       # контур, белый, синий, жёлтый, зелёный
		10: return [5, 9, 2, 6, 3]      # контур, фиолет, синий, белый, жёлтый
		11: return [5, 9, 2, 6, 0]      # контур, фиолет, синий, белый, красный
		12: return [5, 6, 2, 8, 3]      # контур, белый, синий, оранж, жёлтый
		13: return [6, 5, 0, 8, 2]      # белый, контур, красный, оранж, синий
		14: return [5, 4, 2, 6, 9]      # контур, салат, синий, белый, фиолет
		15: return [5, 2, 9, 6, 3]      # контур, синий, фиолет, белый, жёлтый
		16: return [5, 9, 0, 2, 6]      # контур, фиолет, красный, синий, белый
		17: return [5, 8, 0, 7, 6]      # контур, оранж, красный, коричн, белый
		18: return [5, 3, 6, 2, 8]      # контур, жёлтый, белый, синий, оранж
		19: return [5, 2, 8, 1, 6]      # контур, синий, оранж, зелёный, белый
		20: return [5, 9, 2, 6, 4]      # контур, фиолет, синий, белый, салат
		21: return [5, 6, 2, 8, 1]      # контур, белый, синий, оранж, зелёный
		22: return [5, 3, 0, 6, 2]      # контур, жёлтый, красный, белый, синий
		23: return [5, 3, 0, 8, 2]      # контур, жёлтый, красный, оранж, синий
		24: return [5, 2, 6, 8, 3]      # контур, синий, белый, оранж, жёлтый
	return [5, 6, 2]


static func _blank(size: int = CANVAS) -> Array:
	var lines: Array = []
	for _y in range(size):
		lines.append(".".repeat(size))
	return lines


static func _stamp(base: Array, art: Array, ox: int, oy: int) -> void:
	for y in range(art.size()):
		var row: String = art[y]
		for x in range(row.length()):
			var ch := row[x]
			if ch == "." or ch == " ":
				continue
			var tx := ox + x
			var ty := oy + y
			if ty < 0 or ty >= base.size():
				continue
			var line: String = base[ty]
			if tx < 0 or tx >= line.length():
				continue
			base[ty] = line.substr(0, tx) + ch + line.substr(tx + 1)


static func _center_stamp(base: Array, art: Array, oy: int = -1) -> void:
	var ox: int = int((base[0].length() - art[0].length()) / 2)
	var y: int = oy if oy >= 0 else int((base.size() - art.size()) / 2)
	_stamp(base, art, ox, y)


static func _scale_art(art: Array, factor: int = ART_SCALE) -> Array:
	var out: Array = []
	for row in art:
		var wide := ""
		for ch in String(row):
			if ch == "." or ch == " ":
				wide += ".".repeat(factor)
			else:
				wide += ch.repeat(factor)
		for _i in factor:
			out.append(wide)
	return out


static func _count_filled(pattern: Array) -> int:
	var n := 0
	for row in pattern:
		for ch in String(row):
			if ch != "." and ch != " ":
				n += 1
	return n


static func _trim_to_content(pattern: Array, pad: int = 1) -> Array:
	if pattern.is_empty():
		return pattern
	var min_x: int = String(pattern[0]).length()
	var min_y: int = pattern.size()
	var max_x: int = -1
	var max_y: int = -1
	for y in range(pattern.size()):
		var line := String(pattern[y])
		for x in range(line.length()):
			var ch := line[x]
			if ch == "." or ch == " ":
				continue
			min_x = mini(min_x, x)
			max_x = maxi(max_x, x)
			min_y = mini(min_y, y)
			max_y = maxi(max_y, y)
	if max_x < 0:
		return pattern
	min_x = maxi(0, min_x - pad)
	min_y = maxi(0, min_y - pad)
	max_x = mini(String(pattern[0]).length() - 1, max_x + pad)
	max_y = mini(pattern.size() - 1, max_y + pad)
	var trimmed: Array = []
	for y in range(min_y, max_y + 1):
		trimmed.append(String(pattern[y]).substr(min_x, max_x - min_x + 1))
	return trimmed


static func _place_art(art: Array, scale: int = ART_SCALE) -> Array:
	var g := _blank()
	_center_stamp(g, _scale_art(art, scale))
	return _trim_to_content(g, 1)


static func _astronaut() -> Array:
	var art: Array = [
		"....2222....",
		"...233332...",
		"..233888332..",
		"..2386668832.",
		"..2386668832.",
		"...23388833..",
		"....233332...",
		".....3113....",
		"....311113...",
		"...31111113..",
		"..3111111113.",
		"..3111111113.",
		"...31111113..",
		"....311113...",
		".....3113....",
		".....3113....",
		"....331133...",
		"....331133...",
	]
	return _place_art(art)


static func _rocket() -> Array:
	var art: Array = [
		".....2.....",
		"....222....",
		"...24442...",
		"...24442...",
		"...24442...",
		"....222....",
		"....111....",
		"...11111...",
		"..1111111..",
		"..1111111..",
		"...11111...",
		"....111....",
		"....000....",
		"...00000...",
		"..0000000..",
		"..0333330..",
		"...00000...",
	]
	return _place_art(art)


static func _ufo() -> Array:
	var art: Array = [
		"....222....",
		"...23332...",
		"..2333332..",
		".2333111332.",
		".2333111332.",
		"..2333332..",
		"...23332...",
		"....222....",
		".....0.....",
		"....000....",
	]
	return _place_art(art)


static func _saturn() -> Array:
	var cx := CANVAS / 2.0
	var cy := CANVAS / 2.0 - 1.0
	var tilt := deg_to_rad(20.0)
	var cos_t := cos(tilt)
	var sin_t := sin(tilt)
	var pr := CANVAS * 0.14
	var lines: Array = _blank()
	for y in range(CANVAS):
		var line := ""
		for x in range(CANVAS):
			var px := float(x) - cx
			var py := float(y) - cy
			var pd := Vector2(px, py * 0.88).length()
			var rx := px * cos_t + py * sin_t
			var ry := -px * sin_t + py * cos_t
			var on_ring := absf(ry) < 3.8 and absf(rx) < CANVAS * 0.44 and pd > pr * 0.72
			var in_hole := pd < pr * 0.62
			var ch := "."
			if on_ring and not in_hole:
				ch = "2" if absf(ry) < 1.4 else "3"
			elif pd < pr:
				ch = "1" if int(py * 0.55) % 4 == 0 else "2"
			line += ch
		lines[y] = line
	return _trim_to_content(lines, 1)


static func _station() -> Array:
	var art: Array = [
		"1........1",
		"11......11",
		".2222222.",
		"..22222..",
		"...22....",
		"...33....",
		"...22....",
		"..22222..",
		".2222222.",
		"11......11",
		"1........1",
	]
	return _place_art(art)


static func _comet() -> Array:
	var g := _blank()
	var head: Array = [
		"....2222....",
		"...233332...",
		"..23333332..",
		".2333333332.",
		".2333333332.",
		"..23333332..",
		"...233332...",
		"....2222....",
	]
	_stamp(g, head, 4, 6)
	for i in range(18):
		var w := maxi(12 - i / 2, 2)
		var row := ""
		for _j in range(w):
			row += str(i % 4)
		_stamp(g, [row], 6 + i, 8 + i)
	return _trim_to_content(g, 1)


static func _moon_base() -> Array:
	var g := _blank()
	var moon: Array = [
		"...222222...",
		"..22222222..",
		".2222111222.",
		"222211112222",
		"222211112222",
		".2222111222.",
		"..22222222..",
		"...222222...",
	]
	_center_stamp(g, _scale_art(moon, ART_SCALE))
	_stamp(g, ["333", "131", "333"], 14, 20)
	_stamp(g, ["000"], 16, 18)
	return _trim_to_content(g, 1)


static func _rover() -> Array:
	var g := _blank()
	var ground: Array = [
		"..............................",
		"..............................",
		"..............................",
		"111111111111111111111111111111",
		"111111111111111111111111111111",
	]
	_stamp(g, ground, 4, 30)
	var rover: Array = [
		"....2222....",
		"...233332...",
		"..23333332..",
		".2333333332.",
		"233333333332",
		"233333333332",
		".2000000002.",
		"..200..002..",
		"..200..002..",
	]
	_center_stamp(g, rover, 18)
	return _trim_to_content(g, 1)


static func _satellite() -> Array:
	var g := _blank()
	var dish: Array = [
		"1..............1",
		"11............11",
		".22..........22.",
		"..222222222222..",
		"...2222222222...",
		"....22222222....",
		".....222222.....",
		"......2222......",
		"......2222......",
		"......2222......",
		"......1111......",
		"......1111......",
		".....111111.....",
		"....11111111....",
	]
	_center_stamp(g, dish, 3)
	return _trim_to_content(g, 1)


static func _galaxy() -> Array:
	var cx := CANVAS / 2.0
	var cy := CANVAS / 2.0
	var lines: Array = _blank()
	for y in range(CANVAS):
		var line := ""
		for x in range(CANVAS):
			var px := float(x) - cx
			var py := float(y) - cy
			var angle := atan2(py, px)
			var dist := Vector2(px, py * 0.55).length()
			var arm := sin(angle * 2.0 + dist * 0.35) * 0.5 + 0.5
			if dist < 4.0:
				line += "3"
			elif dist < CANVAS * 0.42 and arm > 0.55:
				var band := int(dist / 3.5) % 4
				line += str(band)
			else:
				line += "."
		lines[y] = line
	return _trim_to_content(lines, 1)


static func _black_hole() -> Array:
	var cx := CANVAS / 2.0
	var cy := CANVAS / 2.0
	var lines: Array = _blank()
	for y in range(CANVAS):
		var line := ""
		for x in range(CANVAS):
			var d := Vector2(x - cx, y - cy).length()
			if d < 5.5:
				line += "0"
			elif d < 9.0:
				line += "1"
			elif d < 14.0:
				line += "2"
			elif d < 19.0:
				line += "3"
			elif d < CANVAS * 0.46:
				line += "4" if int(atan2(y - cy, x - cx) * 3.0) % 2 == 0 else "."
			else:
				line += "."
		lines[y] = line
	return _trim_to_content(lines, 1)


static func _telescope() -> Array:
	var g := _blank()
	var scope: Array = [
		"........1111........",
		".......111111.......",
		"......11111111......",
		".....1122222111.....",
		"....112222222211....",
		"...11222222222211...",
		"..1122222222222211..",
		"...11222222222211...",
		"....112222222211....",
		".....1122222111.....",
		"......11111111......",
		".......111111.......",
		"........1111........",
		".........11.........",
		".........11.........",
		"........1111........",
		".......111111.......",
		"......11111111......",
		".....1111111111.....",
	]
	_center_stamp(g, scope, 4)
	return _trim_to_content(g, 1)


static func _shuttle() -> Array:
	var g := _blank()
	var craft: Array = [
		"......2222......",
		".....222222.....",
		"....22222222....",
		"...2222222222...",
		"..222211112222..",
		"..222211112222..",
		"...2222222222...",
		"....22222222....",
		".....222222.....",
		"......2222......",
		"......1111......",
		".....111111.....",
		"....11111111....",
		"...1111111111...",
		"..111111111111..",
		"...0000..0000...",
	]
	_center_stamp(g, craft, 5)
	return _trim_to_content(g, 1)


static func _alien() -> Array:
	var g := _blank()
	var face: Array = [
		"......2222......",
		".....233332.....",
		"....23333332....",
		"....23111332....",
		"....23111332....",
		"....23333332....",
		".....233332.....",
		"......2222......",
		".....111111.....",
		"....11111111....",
		"...1111111111...",
		"...1111111111...",
		"....11111111....",
		".....111111.....",
		"......1111......",
		".....11..11.....",
		".....11..11.....",
	]
	_center_stamp(g, face, 4)
	return _trim_to_content(g, 1)


static func _crystal() -> Array:
	var g := _blank()
	var gem: Array = [
		".......2.......",
		"......232......",
		".....23332.....",
		"....2333332....",
		"...233333332...",
		"..23333333332..",
		".2333333333332.",
		"..23333333332..",
		"...233333332...",
		"....2333332....",
		".....23332.....",
		"......232......",
		".......2.......",
		"......111......",
		".....11111.....",
	]
	_center_stamp(g, gem, 6)
	return _trim_to_content(g, 1)


static func _nebula() -> Array:
	var cx := CANVAS / 2.0
	var cy := CANVAS / 2.0
	var lines: Array = _blank()
	for y in range(CANVAS):
		var line := ""
		for x in range(CANVAS):
			var n := sin(float(x) * 0.22 + 1.2) * cos(float(y) * 0.18 - 0.5)
			var n2 := sin(float(x + y) * 0.15) * 0.6
			var v := n + n2
			if v > 0.55:
				line += "3"
			elif v > 0.25:
				line += "2"
			elif v > 0.05:
				line += "1"
			elif v > -0.15:
				line += "4"
			else:
				line += "."
		lines[y] = line
	return _trim_to_content(lines, 1)


static func _meteor() -> Array:
	var g := _blank()
	var rock: Array = [
		"....2222....",
		"...233332...",
		"..23333332..",
		".2333333332.",
		".2333333332.",
		"..23333332..",
		"...233332...",
		"....2222....",
	]
	_stamp(g, rock, 6, 5)
	for i in range(16):
		var row := ""
		var w := maxi(10 - i / 2, 1)
		for j in range(w):
			row += str((i + j) % 4)
		_stamp(g, [row], 8 + i, 10 + i)
	return _trim_to_content(g, 1)


static func _eclipse() -> Array:
	var art: Array = [
		"....3333....",
		"..33333333..",
		".3333222333.",
		"333322223333",
		"333222222333",
		"333222222333",
		".33332222333.",
		"..33333333..",
		"....3333....",
	]
	return _place_art(art)


static func _ring_world() -> Array:
	var cx := CANVAS / 2.0
	var cy := CANVAS / 2.0
	var outer := minf(cx, cy) * 0.88
	var inner := outer * 0.55
	var lines: Array = _blank()
	for y in range(CANVAS):
		var line := ""
		for x in range(CANVAS):
			var d := Vector2(x - cx, y - cy).length()
			if d > outer or d < inner:
				line += "."
			else:
				var band := int((d - inner) / maxf(outer - inner, 0.01) * 4.0) % 4
				line += str(band)
		lines[y] = line
	return _trim_to_content(lines, 1)


static func _portal() -> Array:
	var cx := CANVAS / 2.0
	var cy := CANVAS / 2.0
	var lines: Array = _blank()
	for y in range(CANVAS):
		var line := ""
		for x in range(CANVAS):
			var d := Vector2(x - cx, (y - cy) * 0.85).length()
			if d < 5.0:
				line += "3"
			elif d < 9.0:
				line += "2"
			elif d < 13.0:
				line += "1"
			elif d < 17.0:
				line += "4"
			elif d < CANVAS * 0.42:
				line += "0" if (x + y) % 3 == 0 else "."
			else:
				line += "."
		lines[y] = line
	return _trim_to_content(lines, 1)


static func _robot() -> Array:
	var g := _blank()
	var bot: Array = [
		"......2222......",
		".....233332.....",
		"....23333332....",
		"....23000332....",
		"....23000332....",
		"....23333332....",
		".....233332.....",
		"......2222......",
		".....111111.....",
		"....11111111....",
		"...1111111111...",
		"...1111111111...",
		"....11111111....",
		".....111111.....",
		"......1111......",
		".....11..11.....",
		".....11..11.....",
		"....111..111....",
	]
	_center_stamp(g, bot, 4)
	return _trim_to_content(g, 1)


static func _binary_star() -> Array:
	var g := _blank()
	for y in range(CANVAS):
		for x in range(CANVAS):
			var d1 := Vector2(x - 14, y - 16).length()
			var d2 := Vector2(x - 24, y - 20).length()
			if d1 < 7.0:
				var ch := "2" if d1 < 3.5 else "1"
				g[y] = String(g[y]).substr(0, x) + ch + String(g[y]).substr(x + 1)
			elif d2 < 5.5:
				var ch2 := "3" if d2 < 2.5 else "2"
				g[y] = String(g[y]).substr(0, x) + ch2 + String(g[y]).substr(x + 1)
	for i in range(8):
		_stamp(g, ["0000000000000000000000000000000000"], 2, 26 + i)
	return _trim_to_content(g, 1)


static func _supernova() -> Array:
	var cx := CANVAS / 2.0
	var cy := CANVAS / 2.0
	var lines: Array = _blank()
	for y in range(CANVAS):
		var line := ""
		for x in range(CANVAS):
			var d := Vector2(x - cx, y - cy).length()
			var rays := absf(sin(atan2(y - cy, x - cx) * 5.0))
			if d < 4.0:
				line += "3"
			elif d < 8.0:
				line += "2"
			elif d < 14.0 and rays > 0.65:
				line += "1"
			elif d < 20.0 and rays > 0.78:
				line += "4"
			else:
				line += "."
		lines[y] = line
	return _trim_to_content(lines, 1)


static func _orbit() -> Array:
	var g := _blank()
	var cx := CANVAS / 2.0
	var cy := CANVAS / 2.0 + 2.0
	for y in range(CANVAS):
		for x in range(CANVAS):
			var d := Vector2(x - cx, (y - cy) * 0.75).length()
			if absf(d - 14.0) < 1.2 or absf(d - 20.0) < 1.0:
				g[y] = String(g[y]).substr(0, x) + "2" + String(g[y]).substr(x + 1)
	_stamp(g, ["333", "333", "333"], int(cx) - 1, int(cy) - 1)
	_stamp(g, ["111"], 8, 10)
	_stamp(g, ["444"], 28, 8)
	_stamp(g, ["000"], 30, 24)
	return _trim_to_content(g, 1)
