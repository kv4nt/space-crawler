class_name AsteroidGrid
extends RefCounted
## Pixel-art поле в стиле Food Hunt: слои, скрытые цвета, поедание снаружи.

var width: int
var height: int
var total_color_count: int
var unlocked_color_count: int
var initial_pixel_count: int
var full_expose: bool = false
var hide_interior: bool = false
var cells: Array = []
var _reserved: Dictionary = {}
var _mineral_for_tier: Array = []


func mineral_index(tier_or_color: int) -> int:
	if _mineral_for_tier.is_empty():
		return tier_or_color
	if tier_or_color < 0 or tier_or_color >= _mineral_for_tier.size():
		return 0
	return int(_mineral_for_tier[tier_or_color])


func uses_authored_palette() -> bool:
	return not _mineral_for_tier.is_empty()


func _init(config: Dictionary) -> void:
	total_color_count = config.get("total_colors", 3)
	unlocked_color_count = config.get("initial_colors", total_color_count)
	full_expose = config.get("full_expose", false)
	hide_interior = config.get("hidden_layers", 0) > 0
	var color_palette: Array = config.get("color_palette", [])
	_load_pattern(config.get("pattern", []), color_palette)


func _load_pattern(pattern: Array, color_palette: Array = []) -> void:
	cells.clear()
	_mineral_for_tier.clear()
	if not color_palette.is_empty():
		for entry in color_palette:
			_mineral_for_tier.append(int(entry))
		total_color_count = _mineral_for_tier.size()
	if pattern.is_empty():
		_generate_default()
		return

	height = pattern.size()
	width = pattern[0].length() if height > 0 else 0
	for y in range(height):
		var line: String = pattern[y]
		var column: Array = []
		for x in range(width):
			var ch := line[x] if x < line.length() else "."
			if ch == "." or ch == " ":
				var empty := GridCell.new(0)
				empty.state = GridCell.State.EMPTY
				column.append(empty)
				continue
			var raw := PatternCodec.tier_from_char(ch)
			if raw < 0:
				var empty := GridCell.new(0)
				empty.state = GridCell.State.EMPTY
				column.append(empty)
				continue
			var color := raw
			if not color_palette.is_empty():
				raw = clampi(raw, 0, _mineral_for_tier.size() - 1)
				color = raw
			else:
				color = clampi(raw, 0, total_color_count - 1)
			column.append(GridCell.new(color))
		cells.append(column)
	initial_pixel_count = count_filled_total()
	_finalize_board()


func _generate_default() -> void:
	width = 8
	height = 8
	for y in range(height):
		var column: Array = []
		for x in range(width):
			column.append(GridCell.new((x + y) % total_color_count))
		cells.append(column)
	initial_pixel_count = count_filled_total()
	_finalize_board()


func is_inside(x: int, y: int) -> bool:
	return x >= 0 and x < width and y >= 0 and y < height


func get_cell(x: int, y: int) -> GridCell:
	if not is_inside(x, y):
		return null
	return cells[y][x]


func is_border(x: int, y: int) -> bool:
	return x == 0 or y == 0 or x == width - 1 or y == height - 1


func get_neighbors(x: int, y: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for offset: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var nx := x + offset.x
		var ny := y + offset.y
		if is_inside(nx, ny):
			result.append(Vector2i(nx, ny))
	return result


func _finalize_board() -> void:
	_recompute_exposure()
	_ensure_surface_colors_unlocked()


## Верхний ряд каждой колонки должен быть собираемым — иначе уровень не стартует.
func _ensure_surface_colors_unlocked() -> void:
	var max_surface_tier := -1
	for x in range(width):
		for y in range(height):
			var cell := get_cell(x, y)
			if cell.state == GridCell.State.EMPTY:
				continue
			max_surface_tier = maxi(max_surface_tier, cell.color)
			break
	if max_surface_tier >= 0:
		unlocked_color_count = maxi(unlocked_color_count, max_surface_tier + 1)
	unlocked_color_count = mini(unlocked_color_count, total_color_count)


func _recompute_exposure() -> void:
	for y in range(height):
		for x in range(width):
			var cell := get_cell(x, y)
			if cell.state == GridCell.State.EMPTY:
				continue
			if cell.scanned:
				cell.state = GridCell.State.EXPOSED
			elif hide_interior and not _is_on_surface(x, y):
				cell.state = GridCell.State.HIDDEN
			else:
				cell.state = GridCell.State.EXPOSED


func is_surface(x: int, y: int) -> bool:
	return _is_on_surface(x, y)


func _is_on_surface(x: int, y: int) -> bool:
	for offset: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var nx := x + offset.x
		var ny := y + offset.y
		if not is_inside(nx, ny):
			return true
		if get_cell(nx, ny).state == GridCell.State.EMPTY:
			return true
	return false


func _is_collectible_at(pos: Vector2i, target_color: int) -> bool:
	if is_cell_reserved(pos):
		return false
	var cell := get_cell(pos.x, pos.y)
	if cell.state == GridCell.State.EMPTY:
		return false
	if cell.color != target_color:
		return false
	if not is_color_unlocked(target_color):
		return false
	return _is_on_surface(pos.x, pos.y)


func is_color_unlocked(color_index: int) -> bool:
	return color_index < unlocked_color_count


func try_unlock_next_color() -> bool:
	if unlocked_color_count >= total_color_count:
		return false
	unlocked_color_count += 1
	_recompute_exposure()
	return true


## Разблокировать цвет, если на поле остались только недоступные блоки.
func try_unlock_if_stuck() -> bool:
	if unlocked_color_count >= total_color_count:
		return false
	if not _has_locked_color_blocks():
		return false
	if _has_any_collectible_unlocked_color():
		return false
	return try_unlock_next_color()


func _has_locked_color_blocks() -> bool:
	for y in range(height):
		for x in range(width):
			var cell := get_cell(x, y)
			if cell.state == GridCell.State.EMPTY:
				continue
			if cell.color >= unlocked_color_count:
				return true
	return false


func _has_any_collectible_unlocked_color() -> bool:
	for c in range(unlocked_color_count):
		if has_collectible_of_color(c):
			return true
	return false


func should_unlock_next_color() -> bool:
	if unlocked_color_count >= total_color_count:
		return false
	var ratio := 0.35
	if total_color_count >= 5:
		ratio = 0.22
	elif total_color_count >= 4:
		ratio = 0.28
	var threshold := maxi(1, int(initial_pixel_count * ratio))
	return count_collectibles_eaten() >= threshold


func count_collectibles_eaten() -> int:
	return initial_pixel_count - count_filled_total()


func eat_cell(pos: Vector2i, recompute: bool = true) -> void:
	var cell := get_cell(pos.x, pos.y)
	if cell == null or cell.state != GridCell.State.EXPOSED:
		return
	cell.state = GridCell.State.EMPTY
	unreserve_cell(pos)
	if recompute:
		_recompute_exposure()


func reserve_cell(pos: Vector2i) -> bool:
	if _reserved.has(pos):
		return false
	var cell := get_cell(pos.x, pos.y)
	if cell == null or cell.state != GridCell.State.EXPOSED:
		return false
	_reserved[pos] = true
	return true


func unreserve_cell(pos: Vector2i) -> void:
	_reserved.erase(pos)


func is_cell_reserved(pos: Vector2i) -> bool:
	return _reserved.has(pos)


func has_collectible_of_color(target_color: int) -> bool:
	return get_first_exposed_of_color(target_color) != null


## Съедает до max_count доступных пикселей цвета (каскад Food Hunt).
func eat_burst_of_color(target_color: int, max_count: int) -> Array[Vector2i]:
	var eaten: Array[Vector2i] = []
	for _i in range(max_count):
		var pos: Variant = get_first_exposed_of_color(target_color)
		if pos == null:
			break
		eat_cell(pos, false)
		eaten.append(pos)
	if not eaten.is_empty():
		_recompute_exposure()
	return eaten


func get_first_exposed_of_color(target_color: int) -> Variant:
	for y in range(height):
		for x in range(width):
			var pos := Vector2i(x, y)
			if _is_collectible_at(pos, target_color):
				return pos
	return null


func get_random_exposed_of_color(target_color: int, rng: RandomNumberGenerator) -> Variant:
	var candidates: Array[Vector2i] = []
	for y in range(height):
		for x in range(width):
			var pos := Vector2i(x, y)
			if _is_collectible_at(pos, target_color):
				candidates.append(pos)
	if candidates.is_empty():
		return null
	return candidates[rng.randi_range(0, candidates.size() - 1)]


func count_filled_of_color(target_color: int) -> int:
	var n := 0
	for y in range(height):
		for x in range(width):
			var cell := get_cell(x, y)
			if cell.state == GridCell.State.EMPTY:
				continue
			if cell.color == target_color:
				n += 1
	return n


func count_filled_total() -> int:
	var n := 0
	for y in range(height):
		for x in range(width):
			var cell := get_cell(x, y)
			if cell.state == GridCell.State.EMPTY:
				continue
			n += 1
	return n


func count_empty_total() -> int:
	return width * height - count_filled_total()


func is_board_clear() -> bool:
	return count_filled_total() == 0


func has_exposed_of_color(c: int) -> bool:
	return get_first_exposed_of_color(c) != null


func count_exposed_of_color(target_color: int) -> int:
	var n := 0
	for y in range(height):
		for x in range(width):
			if _is_collectible_at(Vector2i(x, y), target_color):
				n += 1
	return n


func count_hidden_of_color(target_color: int) -> int:
	var n := 0
	for y in range(height):
		for x in range(width):
			var cell := get_cell(x, y)
			if cell.state == GridCell.State.HIDDEN and cell.color == target_color:
				n += 1
	return n


## Подсказка: цвет с наибольшим числом доступных пикселей, который ещё не в слоте.
func get_hint_color(active_colors: Array[int]) -> int:
	var best := -1
	var best_score := 0
	for c in range(total_color_count):
		if not is_color_unlocked(c):
			continue
		if c in active_colors:
			continue
		if count_filled_of_color(c) == 0:
			continue
		var exposed := count_exposed_of_color(c)
		if exposed <= 0:
			continue
		if exposed > best_score:
			best_score = exposed
			best = c
	if best == -1:
		for c in range(total_color_count):
			if not is_color_unlocked(c) or c in active_colors:
				continue
			if count_filled_of_color(c) == 0:
				continue
			if count_exposed_of_color(c) > 0:
				return c
	return best


## Сканер: показывает до max_count скрытых блоков (?), примыкающих к открытым.
func scan_reveal(max_count: int, rng: RandomNumberGenerator) -> int:
	var stale: Array = _reserved.keys()
	for pos in stale:
		var cell := get_cell(pos.x, pos.y)
		if cell == null or cell.state != GridCell.State.EXPOSED:
			unreserve_cell(pos)

	var candidates: Array[Vector2i] = []
	for y in range(height):
		for x in range(width):
			if not _is_fogged(x, y):
				continue
			if _has_scan_neighbor(x, y):
				candidates.append(Vector2i(x, y))

	if candidates.is_empty():
		return 0

	for i in range(candidates.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := candidates[i]
		candidates[i] = candidates[j]
		candidates[j] = tmp

	var opened := 0
	for pos in candidates:
		if opened >= max_count:
			break
		var cell := get_cell(pos.x, pos.y)
		if cell == null or cell.scanned:
			continue
		cell.scanned = true
		cell.state = GridCell.State.EXPOSED
		opened += 1
	return opened


func _is_fogged(x: int, y: int) -> bool:
	var cell := get_cell(x, y)
	if cell == null or cell.state == GridCell.State.EMPTY or cell.scanned:
		return false
	if not is_color_unlocked(cell.color):
		return false
	if cell.state == GridCell.State.HIDDEN:
		return true
	return not _is_on_surface(x, y)


func _is_revealed_for_scan(x: int, y: int) -> bool:
	var cell := get_cell(x, y)
	if cell == null:
		return false
	if cell.state == GridCell.State.EMPTY:
		return true
	if cell.state != GridCell.State.EXPOSED:
		return false
	return cell.scanned or _is_on_surface(x, y)


func _has_scan_neighbor(x: int, y: int) -> bool:
	for neighbor: Vector2i in get_neighbors(x, y):
		if _is_revealed_for_scan(neighbor.x, neighbor.y):
			return true
	return false


## Устаревший пересчёт — оставлен для совместимости.
func scan_refresh() -> int:
	_recompute_exposure()
	return 0


func get_pulse_color(active_colors: Array[int]) -> int:
	var best := -1
	var best_score := 0
	for c in active_colors:
		if not is_color_unlocked(c):
			continue
		var exposed := count_exposed_of_color(c)
		if exposed <= 0:
			continue
		if exposed > best_score:
			best_score = exposed
			best = c
	return best


## Импульс: мгновенно отправляет корабли к доступным минералам активного цвета в слоте.
func get_pulse_targets(active_colors: Array[int], max_count: int, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var best := get_pulse_color(active_colors)
	if best == -1:
		return []
	var targets: Array[Dictionary] = []
	for _i in range(max_count):
		var pos: Variant = get_random_exposed_of_color(best, rng)
		if pos == null:
			break
		if not reserve_cell(pos):
			continue
		targets.append({"pos": pos, "color": best})
	return targets
