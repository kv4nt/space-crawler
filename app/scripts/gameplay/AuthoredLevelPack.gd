class_name AuthoredLevelPack
extends RefCounted
## Загрузка пользовательских уровней из app/data/levels/level_XXX.json

const LEVELS_DIR := "res://data/levels/"
const SCHEMA_VERSION := 1
const MIN_FILL_CELLS := 36


static func pool_size() -> int:
	return maxi(PixelArtLevels.LEVEL_COUNT, _max_custom_id())


static func resolve_index(global_id: int) -> int:
	var size := pool_size()
	if size <= 0:
		return 1
	return ((global_id - 1) % size) + 1


static func try_build(global_id: int) -> Dictionary:
	var idx := resolve_index(global_id)
	var custom := _load_json_level(idx)
	if not custom.is_empty():
		return custom
	return PixelArtLevels.try_build_by_index(idx)


static func _max_custom_id() -> int:
	var max_id := 0
	var dir := DirAccess.open(LEVELS_DIR)
	if dir == null:
		return 0
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if not dir.current_is_dir() and entry.begins_with("level_") and entry.ends_with(".json"):
			var num_str := entry.trim_prefix("level_").trim_suffix(".json")
			if num_str.is_valid_int():
				max_id = maxi(max_id, int(num_str))
		entry = dir.get_next()
	dir.list_dir_end()
	return max_id


static func _load_json_level(level_id: int) -> Dictionary:
	var path := LEVELS_DIR + "level_%03d.json" % level_id
	if not FileAccess.file_exists(path):
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("AuthoredLevelPack: cannot read %s" % path)
		return {}

	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_warning("AuthoredLevelPack: invalid JSON in %s" % path)
		file.close()
		return {}
	file.close()

	var data: Variant = json.data
	if not data is Dictionary:
		return {}

	var pattern: Array = _pattern_from_data(data)
	if pattern.is_empty():
		return {}

	pattern = PixelArtLevels.trim_pattern(pattern, 1)
	if PixelArtLevels.count_filled(pattern) < MIN_FILL_CELLS:
		push_warning("AuthoredLevelPack: level_%03d has too few cells" % level_id)
		return {}

	var palette: Array = _palette_from_data(data)
	if palette.is_empty():
		palette = _palette_from_pattern(pattern)

	return {
		"pattern": pattern,
		"color_palette": palette,
		"total_colors": palette.size(),
		"theme_name": String(data.get("theme_name", "Уровень %d" % level_id)),
		"authored_index": level_id,
		"from_file": path,
	}


static func _pattern_from_data(data: Dictionary) -> Array:
	var raw: Variant = data.get("pattern", [])
	if raw is Array and not raw.is_empty():
		var lines: Array = []
		for row in raw:
			lines.append(String(row))
		return lines

	var png_id := int(data.get("id", 0))
	if png_id > 0:
		var imported := SpacePatternImporter.try_import_background(
			png_id, GameBalance.MAX_MINERAL_COLORS)
		if not imported.is_empty():
			return _minerals_to_tiers(imported)
	return []


static func _palette_from_data(data: Dictionary) -> Array:
	var raw: Variant = data.get("color_palette", [])
	if raw is Array and not raw.is_empty():
		var palette: Array = []
		for entry in raw:
			palette.append(int(entry))
		return palette
	return []


static func _palette_from_pattern(pattern: Array) -> Array:
	var max_tier := -1
	for row in pattern:
		for ch in String(row):
			if ch == "." or ch == " ":
				continue
			var tier := PatternCodec.tier_from_char(ch)
			if tier >= 0:
				max_tier = maxi(max_tier, tier)
	if max_tier < 0:
		return [0]
	var palette: Array = []
	for i in range(max_tier + 1):
		palette.append(i % GameBalance.MAX_MINERAL_COLORS)
	return palette


static func _minerals_to_tiers(pattern: Array) -> Array:
	var mineral_to_tier: Dictionary = {}
	var tiers: Array = []
	var lines: Array = []
	for row in pattern:
		var line := String(row)
		var out := ""
		for ch in line:
			if ch == "." or ch == " ":
				out += "."
				continue
			if not ch.is_valid_int():
				out += "."
				continue
			var mineral := int(ch)
			if not mineral_to_tier.has(mineral):
				mineral_to_tier[mineral] = tiers.size()
				tiers.append(mineral)
			out += PatternCodec.char_from_tier(int(mineral_to_tier[mineral]))
		lines.append(out)
	return lines
