class_name FoodHuntLevels
extends RefCounted
## Чёткий pixel-art как в Food Hunt — узнаваемые силуэты на пустом фоне.
## В паттерне только цифры 0..N-1; реальные цвета задаёт palette().

const CANVAS: int = 36


static func has_level(global_id: int) -> bool:
	return global_id >= 1 and global_id <= 6


static func color_count(global_id: int) -> int:
	match global_id:
		1: return 4
		2: return 3
		3: return 4
		4: return 3
		5: return 4
		6: return 3
	return 3


## Индексы в GameBalance.MINERAL_COLORS для каждой цифры паттерна.
static func palette(global_id: int) -> Array:
	match global_id:
		1: return [6, 8, 2, 7]   # белый, оранжевый, синий, коричневый
		2: return [6, 8, 0]      # белый корпус, оранжевый, красное пламя
		3: return [2, 3, 6, 5]   # синий купол, жёлтый, белый, чёрный
		4: return [2, 8, 3]      # синий шар, оранжевые кольца, жёлтая полоса
		5: return [6, 8, 0, 2]   # белая ракета, оранж, красное, синяя планета
		6: return [9, 3, 2]      # фиолетовая планета, жёлтое кольцо, синие полосы
	return [0, 1, 2]


static func build(global_id: int) -> Array:
	match global_id:
		1: return _make_astronaut(CANVAS)
		2: return _make_rocket(CANVAS)
		3: return _make_ufo(CANVAS)
		4: return _make_saturn(CANVAS)
		5: return _make_rocket_flight(CANVAS)
		6: return _make_pink_planet(CANVAS)
	return []


static func _blank(size: int) -> Array:
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


static func _make_astronaut(size: int) -> Array:
	var g := _blank(size)
	var art: Array = [
		"......22......",
		".....2222.....",
		"....222882....",
		"....228882....",
		".....2222.....",
		".....28882....",
		".....28882....",
		"......00......",
		".....0000.....",
		"....000000....",
		"...00000000...",
		"..0000000000..",
		"..0000000000..",
		"...00000000...",
		"....000000....",
		".....0000.....",
		"......00......",
		"......00......",
		".....0000.....",
	]
	_stamp(g, art, (size - 14) / 2, 3)
	_stamp(g, ["111", "101", ".0."], (size - 14) / 2 - 5, 9)
	return g


static func _make_rocket(size: int) -> Array:
	var g := _blank(size)
	var art: Array = [
		"......1......",
		".....111.....",
		"....11111....",
		"....10001....",
		"....10001....",
		"....10001....",
		".....1001.....",
		"......0......",
		"......2......",
		".....222.....",
		"....22222....",
		"...2222222...",
		"..222222222..",
		"..222222222..",
		"...2222222...",
		"....22222....",
		".....222.....",
		"......2......",
	]
	_stamp(g, art, (size - 13) / 2, 2)
	return g


static func _make_ufo(size: int) -> Array:
	var cx := size / 2.0
	var cy := size / 2.0
	var lines: Array = []
	for y in range(size):
		var line := ""
		for x in range(size):
			var px := float(x) - cx
			var py := float(y) - cy
			var saucer := Vector2(px, py * 0.52).length()
			var dome := Vector2(px, py * 0.52 + 4.5).length()
			if dome < 7.0 and py < 0.5:
				line += "0"
			elif saucer < 14.0 and absf(py) < 6.0:
				if absf(px) < 2.8 and py > 0.8:
					line += "2"
				elif absf(px) < 1.5 and py > 0.2:
					line += "3"
				else:
					line += "1"
			elif absf(px) < 11.0 and py > 5.0 and py < 10.0:
				line += "3"
			else:
				line += "."
		lines.append(line)
	return lines


static func _make_saturn(size: int) -> Array:
	var cx := size / 2.0
	var cy := size / 2.0
	var tilt := deg_to_rad(18.0)
	var cos_t := cos(tilt)
	var sin_t := sin(tilt)
	var pr := size * 0.17
	var lines: Array = []
	for y in range(size):
		var line := ""
		for x in range(size):
			var px := float(x) - cx
			var py := float(y) - cy
			var pd := Vector2(px, py * 0.90).length()
			var rx := px * cos_t + py * sin_t
			var ry := -px * sin_t + py * cos_t
			var on_ring := absf(ry) < 4.5 and absf(rx) < size * 0.46
			var in_hole := pd < pr * 0.68
			var planet := pd < pr
			var ch := "."

			if on_ring and not in_hole:
				if absf(ry) < 1.6:
					ch = "2"
				else:
					ch = "1"
			if planet:
				if int(py * 0.5) % 5 == 0:
					ch = "2"
				else:
					ch = "0"
			line += ch
		lines.append(line)
	return lines


static func _make_rocket_flight(size: int) -> Array:
	var g := _blank(size)
	var planet_cx := size * 0.26
	var planet_cy := size * 0.74
	for y in range(size):
		for x in range(size):
			var d := Vector2(x - planet_cx, y - planet_cy).length()
			if d < 8.5:
				var ch := "3"
				if Vector2(x - planet_cx + 2, y - planet_cy + 1).length() < 2.2:
					ch = "1"
				g[y] = String(g[y]).substr(0, x) + ch + String(g[y]).substr(x + 1)
	var ship: Array = [
		"..1..",
		".111.",
		".1000",
		"..100",
		"...10",
		"...22",
		"..222",
		".2222",
	]
	for i in range(ship.size()):
		_stamp(g, [ship[i]], 7 + i, size - 15 - i)
	return g


static func _make_pink_planet(size: int) -> Array:
	var cx := size / 2.0
	var cy := size / 2.0
	var tilt := deg_to_rad(15.0)
	var cos_t := cos(tilt)
	var sin_t := sin(tilt)
	var pr := size * 0.18
	var lines: Array = []
	for y in range(size):
		var line := ""
		for x in range(size):
			var px := float(x) - cx
			var py := float(y) - cy
			var pd := Vector2(px, py * 0.92).length()
			var rx := px * cos_t + py * sin_t
			var ry := -px * sin_t + py * cos_t
			var on_ring := absf(ry) < 2.5 and absf(rx) < size * 0.40 and pd > pr * 0.85
			if pd < pr:
				if int(py) % 5 == 0:
					line += "2"
				else:
					line += "0"
			elif on_ring:
				line += "1"
			else:
				line += "."
		lines.append(line)
	return lines
