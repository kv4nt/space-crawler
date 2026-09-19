class_name LevelGenerator
extends RefCounted
## Уровни: авторский pixel-art → PNG-пул → процедурный fallback.


static func generate(global_id: int, sector: int, level_in_sector: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = global_id * 7919 + sector * 997

	var difficulty := GameBalance.level_difficulty(level_in_sector)
	var authored: Dictionary = AuthoredLevelPack.try_build(global_id)
	var from_authored := not authored.is_empty()
	var pattern: Array = []
	var color_palette: Array = []
	var total_colors := 3
	var initial_colors := 2
	var theme := "Космос"
	var shape := SpaceLevelPatterns.shape_for_level(global_id)
	var bg_index := 0
	var from_image := false

	if from_authored:
		pattern = authored.pattern
		color_palette = authored.color_palette
		total_colors = int(authored.total_colors)
		theme = String(authored.theme_name)
	else:
		total_colors = clampi(2 + (global_id - 1) / 6, 2, GameBalance.MAX_MINERAL_COLORS)
		initial_colors = clampi(2 + (global_id - 1) / 10, 2, total_colors)
		bg_index = SpacePatternImporter.pick_background_index(global_id)
		pattern = SpacePatternImporter.try_import_background(
			bg_index, GameBalance.MAX_MINERAL_COLORS)
		from_image = not pattern.is_empty()

		if from_image:
			pattern = SpacePatternImporter.remap_pattern_colors(pattern, rng)
			var detected := SpacePatternImporter.count_distinct_colors(pattern)
			total_colors = clampi(maxi(detected, total_colors), 2, GameBalance.MAX_MINERAL_COLORS)
			initial_colors = mini(initial_colors, total_colors)
		else:
			var w := clampi(32 + sector, 36, GameBalance.GRID_TARGET_SIZE)
			var h := clampi(32 + sector, 36, GameBalance.GRID_TARGET_SIZE)
			pattern = SpaceLevelPatterns.build(shape, w, h, total_colors, rng)
			var pw: int = String(pattern[0]).length() if not pattern.is_empty() else w
			var ph: int = pattern.size()
			pattern = _ensure_color_diversity(pattern, pw, ph, total_colors, rng)

		pattern = _remove_isolated_components(pattern)
		theme = SpacePatternImporter.theme_name(bg_index) if from_image else SpaceLevelPatterns.theme_name(shape)

	if from_authored:
		initial_colors = clampi(2 + (global_id - 1) / 8, 2, total_colors)
		if difficulty == GameBalance.LevelDifficulty.NORMAL and total_colors <= 6:
			initial_colors = total_colors
		elif difficulty == GameBalance.LevelDifficulty.EXTREME:
			initial_colors = maxi(2, total_colors - 2)
		elif difficulty == GameBalance.LevelDifficulty.HARD:
			initial_colors = maxi(2, total_colors - 1)

	var hidden_layers := 0
	if not from_authored:
		match difficulty:
			GameBalance.LevelDifficulty.EXTREME:
				hidden_layers = 3
			GameBalance.LevelDifficulty.HARD:
				hidden_layers = 2
			_:
				hidden_layers = 0
	else:
		match difficulty:
			GameBalance.LevelDifficulty.EXTREME:
				hidden_layers = 2
			GameBalance.LevelDifficulty.HARD:
				hidden_layers = 1
			_:
				hidden_layers = 0

	if not from_authored:
		if difficulty == GameBalance.LevelDifficulty.EXTREME:
			initial_colors = maxi(2, total_colors - 2)
		elif difficulty == GameBalance.LevelDifficulty.HARD:
			initial_colors = maxi(2, total_colors - 1)

	var reward_bonus := 0
	match difficulty:
		GameBalance.LevelDifficulty.EXTREME:
			reward_bonus = 60
		GameBalance.LevelDifficulty.HARD:
			reward_bonus = 40

	## Спецэффекты минералов (лёд / печать) — растут вместе со сложностью уровня.
	## FUSED (сплав) отключён: меняет цвет клетки после старта уровня, что ломает
	## зафиксированные при старте квоты ColorVending. Вернётся после интеграции с квотами.
	var frost_cell_count := 0
	var fused_pair_count := 0
	var sealed_cell_count := 0
	match difficulty:
		GameBalance.LevelDifficulty.EXTREME:
			frost_cell_count = 4
			fused_pair_count = 0
			sealed_cell_count = 3
		GameBalance.LevelDifficulty.HARD:
			frost_cell_count = 2
			fused_pair_count = 0
			sealed_cell_count = 2
		_:
			frost_cell_count = 0
			fused_pair_count = 0
			sealed_cell_count = 0
	var modifier_seed := rng.randi()

	return {
		"id": global_id,
		"sector": sector,
		"level_in_sector": level_in_sector,
		"difficulty": difficulty,
		"initial_colors": initial_colors,
		"total_colors": total_colors,
		"color_palette": color_palette,
		"slot_count": GameBalance.DEFAULT_SLOT_COUNT,
		"launch_interval": maxf(0.32 - float(global_id) * 0.001, 0.16),
		"reward": 80 + global_id * 12 + reward_bonus,
		"pattern": pattern,
		"hidden_layers": hidden_layers,
		"is_hard_level": difficulty >= GameBalance.LevelDifficulty.HARD,
		"is_extreme_level": difficulty == GameBalance.LevelDifficulty.EXTREME,
		"shape": shape,
		"theme_name": theme,
		"background_index": bg_index,
		"vending_columns": clampi(4 + global_id / 15, 4, 6),
		"authored": from_authored,
		"frost_cell_count": frost_cell_count,
		"fused_pair_count": fused_pair_count,
		"sealed_cell_count": sealed_cell_count,
		"modifier_seed": modifier_seed,
	}


static func _shuffle_in_place(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


static func _ensure_color_diversity(
	pattern: Array, w: int, h: int, colors: int, rng: RandomNumberGenerator,
) -> Array:
	if colors <= 1:
		return pattern

	var lines: Array = []
	for row in pattern:
		lines.append(String(row))

	var counts: Dictionary = {}
	var positions: Array[Vector2i] = []
	for y in range(lines.size()):
		var line: String = lines[y]
		for x in range(line.length()):
			var ch := line[x]
			if ch == "." or ch == " ":
				continue
			var c := int(ch.to_int()) if ch.is_valid_int() else 0
			c = clampi(c, 0, colors - 1)
			counts[c] = int(counts.get(c, 0)) + 1
			positions.append(Vector2i(x, y))

	var total := positions.size()
	if total == 0:
		return lines

	var dominant := 0
	var max_count := 0
	for c in counts.keys():
		var n: int = int(counts[c])
		if n > max_count:
			max_count = n
			dominant = int(c)

	if max_count > int(total * 0.55):
		var others: Array[int] = []
		for c in range(colors):
			if c != dominant:
				others.append(c)
		_shuffle_in_place(positions, rng)
		var changed := 0
		var need := maxi(int(total * 0.22), 4)
		for pos in positions:
			if changed >= need:
				break
			var line: String = lines[pos.y]
			var ch := line[pos.x]
			var c := int(ch.to_int()) if ch.is_valid_int() else 0
			if c != dominant:
				continue
			var new_color: int = others[rng.randi_range(0, others.size() - 1)]
			lines[pos.y] = line.substr(0, pos.x) + str(new_color) + line.substr(pos.x + 1)
			changed += 1

	var surface_colors: Dictionary = {}
	for x in range(w):
		for y in range(h):
			if y >= lines.size():
				break
			var line: String = lines[y]
			if x >= line.length():
				continue
			var ch := line[x]
			if ch == "." or ch == " ":
				continue
			var c := clampi(int(ch.to_int()) if ch.is_valid_int() else 0, 0, colors - 1)
			surface_colors[c] = true
			break

	if surface_colors.size() < mini(colors, 2):
		for x in range(w):
			if surface_colors.size() >= mini(colors, 2):
				break
			for y in range(h):
				if y >= lines.size():
					break
				var line: String = lines[y]
				if x >= line.length() or line[x] == "." or line[x] == " ":
					continue
				for c in range(colors):
					if surface_colors.has(c):
						continue
					lines[y] = line.substr(0, x) + str(c) + line.substr(x + 1)
					surface_colors[c] = true
					break
				break

	return lines


static func _remove_isolated_components(pattern: Array) -> Array:
	if pattern.is_empty():
		return pattern
	var lines: Array = []
	for row in pattern:
		lines.append(String(row))
	var h: int = lines.size()
	var w: int = String(lines[0]).length() if h > 0 else 0
	var visited: Dictionary = {}
	var components: Array = []
	for y in range(h):
		for x in range(w):
			var pos := Vector2i(x, y)
			if visited.has(pos):
				continue
			var ch: String = String(lines[y])[x]
			if ch == "." or ch == " ":
				continue
			var comp: Array[Vector2i] = []
			var stack: Array[Vector2i] = [pos]
			while not stack.is_empty():
				var p: Vector2i = stack.pop_back()
				if visited.has(p):
					continue
				if p.x < 0 or p.y < 0 or p.y >= h or p.x >= w:
					continue
				var cell_ch: String = String(lines[p.y])[p.x]
				if cell_ch == "." or cell_ch == " ":
					continue
				visited[p] = true
				comp.append(p)
				stack.append(p + Vector2i(1, 0))
				stack.append(p + Vector2i(-1, 0))
				stack.append(p + Vector2i(0, 1))
				stack.append(p + Vector2i(0, -1))
			if not comp.is_empty():
				components.append(comp)
	if components.size() <= 1:
		return lines
	var largest: Array = components[0]
	for comp in components:
		if comp.size() > largest.size():
			largest = comp
	var keep: Dictionary = {}
	for p in largest:
		keep[p] = true
	for comp in components:
		for p in comp:
			if keep.has(p):
				continue
			var line: String = lines[p.y]
			lines[p.y] = line.substr(0, p.x) + "." + line.substr(p.x + 1)
	return lines
