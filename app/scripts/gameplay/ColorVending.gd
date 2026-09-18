class_name ColorVending
extends RefCounted
## Автомат 5×5 видимых ячеек; полный стек патронов хранится в колонках.

const GRID_WIDTH: int = 5
const VISIBLE_ROWS: int = 5
const GRID_HEIGHT: int = VISIBLE_ROWS
const MAX_CHIP_LAUNCHES: int = 200
const PREFERRED_CHIP_MIN: int = 8
const PREFERRED_CHIP_MAX: int = 36

var columns: Array = []


func setup_from_grid(
	grid: AsteroidGrid, _column_count: int, global_id: int,
	difficulty: int = GameBalance.LevelDifficulty.NORMAL,
) -> void:
	columns.clear()
	for _i in range(GRID_WIDTH):
		columns.append([])

	var rng := RandomNumberGenerator.new()
	rng.seed = global_id * 3571

	var color_entries: Array = []
	for c in range(grid.total_color_count):
		var on_field := grid.count_filled_of_color(c)
		if on_field <= 0:
			continue
		color_entries.append({"color": c, "count": on_field})

	if color_entries.is_empty():
		return

	var chips: Array = []
	for entry in color_entries:
		var parts: Array[int] = _split_total_into_parts(int(entry.count), rng)
		for p in parts:
			chips.append({"color": int(entry.color), "launches": p})

	chips = _ensure_exact_totals(chips, color_entries)
	chips = _split_oversized_chips(chips, rng)
	_distribute_chips(chips, grid, rng, difficulty)


func column_count() -> int:
	return columns.size()


static func should_scroll_after_pop(stack_size_before: int) -> bool:
	return stack_size_before > VISIBLE_ROWS


static func visible_row_count(stack_size: int) -> int:
	if stack_size <= 0:
		return 0
	return mini(stack_size, VISIBLE_ROWS)


func get_column_stack(col: int) -> Array:
	if col < 0 or col >= columns.size():
		return []
	return columns[col]


func peek_top(col: int) -> Dictionary:
	if col < 0 or col >= columns.size():
		return {}
	var stack: Array = columns[col]
	if stack.is_empty():
		return {}
	return stack[stack.size() - 1]


func pop_top(col: int) -> Dictionary:
	var chip := peek_top(col)
	if chip.is_empty():
		return {}
	columns[col].pop_back()
	return chip


func get_visible_from_top(col: int, max_rows: int = VISIBLE_ROWS) -> Array:
	var stack: Array = columns[col]
	if stack.is_empty():
		return []
	var result: Array = []
	var n := mini(max_rows, stack.size())
	for i in range(n):
		result.append(stack[stack.size() - 1 - i])
	return result


func has_launchable() -> bool:
	for i in range(columns.size()):
		if not peek_top(i).is_empty():
			return true
	return false


func total_launches_for_color(color: int) -> int:
	var total := 0
	for col in columns:
		for chip in col:
			if int(chip.get("color", -1)) == color:
				total += int(chip.get("launches", 0))
	return total


func is_chip_usable(chip: Dictionary, grid: AsteroidGrid) -> bool:
	if chip.is_empty():
		return false
	var color := int(chip.get("color", -1))
	if color < 0:
		return false
	if not grid.is_color_unlocked(color):
		return false
	if grid.count_filled_of_color(color) <= 0:
		return false
	return grid.has_collectible_of_color(color)


func _distribute_chips(
	chips: Array, grid: AsteroidGrid, rng: RandomNumberGenerator, difficulty: int,
) -> void:
	columns.clear()
	for _i in range(GRID_WIDTH):
		columns.append([])

	if chips.is_empty():
		return

	var peel_order := _compute_color_peel_order(grid)
	var by_color: Dictionary = {}
	for chip in chips:
		var color := int(chip.get("color", -1))
		if not by_color.has(color):
			by_color[color] = []
		by_color[color].append(chip)

	var peel_groups: Dictionary = {}
	for color in by_color.keys():
		var peel: int = int(peel_order.get(color, 999))
		if not peel_groups.has(peel):
			peel_groups[peel] = []
		peel_groups[peel].append(color)

	var peel_levels: Array = peel_groups.keys()
	peel_levels.sort()
	peel_levels.reverse()

	var col_idx := 0
	for peel in peel_levels:
		var layer_colors: Array = peel_groups[peel]
		layer_colors.sort_custom(func(a: int, b: int) -> bool:
			return grid.count_filled_of_color(a) > grid.count_filled_of_color(b)
		)
		if difficulty >= GameBalance.LevelDifficulty.HARD:
			_shuffle_in_place(layer_colors, rng)
		if (
			difficulty >= GameBalance.LevelDifficulty.EXTREME
			and layer_colors.size() > 1
			and rng.randf() < 0.35
		):
			var swap_idx := rng.randi_range(1, layer_colors.size() - 1)
			var tmp = layer_colors[0]
			layer_colors[0] = layer_colors[swap_idx]
			layer_colors[swap_idx] = tmp

		for color in layer_colors:
			var bucket: Array = (by_color[color] as Array).duplicate()
			if difficulty >= GameBalance.LevelDifficulty.HARD:
				_shuffle_in_place(bucket, rng)
			else:
				bucket.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
					return int(a.get("launches", 0)) > int(b.get("launches", 0))
				)
			for chip in bucket:
				columns[col_idx % GRID_WIDTH].append(chip)
				col_idx += 1


static func _compute_color_peel_order(grid: AsteroidGrid) -> Dictionary:
	var board: Array = []
	for y in range(grid.height):
		var row: Array = []
		for x in range(grid.width):
			var cell := grid.get_cell(x, y)
			if cell == null or cell.state == GridCell.State.EMPTY:
				row.append(-1)
			else:
				row.append(cell.color)
		board.append(row)

	var first_peel: Dictionary = {}
	for c in range(grid.total_color_count):
		first_peel[c] = -1

	var peel := 0
	var max_passes := grid.width * grid.height + 2
	while peel < max_passes:
		var any_filled := false
		for y in range(grid.height):
			for x in range(grid.width):
				var color: int = int(board[y][x])
				if color < 0:
					continue
				any_filled = true
				if not _board_cell_is_surface(board, grid.width, grid.height, x, y):
					continue
				if int(first_peel.get(color, -1)) == -1:
					first_peel[color] = peel

		if not any_filled:
			break

		for y in range(grid.height):
			for x in range(grid.width):
				if int(board[y][x]) < 0:
					continue
				if _board_cell_is_surface(board, grid.width, grid.height, x, y):
					board[y][x] = -1
		peel += 1

	for c in range(grid.total_color_count):
		if int(first_peel.get(c, -1)) < 0 and grid.count_filled_of_color(c) > 0:
			first_peel[c] = peel
	return first_peel


static func _board_cell_is_surface(board: Array, w: int, h: int, x: int, y: int) -> bool:
	if int(board[y][x]) < 0:
		return false
	for offset: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var nx := x + offset.x
		var ny := y + offset.y
		if nx < 0 or ny < 0 or nx >= w or ny >= h:
			return true
		if int(board[ny][nx]) < 0:
			return true
	return false


func add_chip_for_color(grid: AsteroidGrid, color: int, global_id: int) -> void:
	if grid.count_filled_of_color(color) <= 0:
		return
	var on_field := grid.count_filled_of_color(color)
	var already := total_launches_for_color(color)
	var need := maxi(on_field - already, 0)
	var rng := RandomNumberGenerator.new()
	rng.seed = global_id * 7919 + color * 131
	while need > 0:
		var chunk := mini(need, _random_chip_size(rng))
		columns[_shortest_column()].append({"color": color, "launches": chunk})
		need -= chunk


static func _ensure_exact_totals(chips: Array, color_entries: Array) -> Array:
	for entry in color_entries:
		var color: int = int(entry.get("color", -1))
		var expected: int = int(entry.get("count", 0))
		if color < 0 or expected <= 0:
			continue
		var actual := 0
		var color_chips: Array = []
		for chip in chips:
			if int(chip.get("color", -1)) == color:
				actual += int(chip.get("launches", 0))
				color_chips.append(chip)
		var diff := expected - actual
		if diff == 0:
			continue
		if diff > 0:
			var rng := RandomNumberGenerator.new()
			while diff > 0:
				var chunk := mini(diff, _random_chip_size(rng))
				chips.append({"color": color, "launches": chunk})
				diff -= chunk
		else:
			var remaining := -diff
			for chip in color_chips:
				if remaining <= 0:
					break
				var launches := int(chip.get("launches", 0))
				var take := mini(launches, remaining)
				chip["launches"] = launches - take
				remaining -= take
			for i in range(chips.size() - 1, -1, -1):
				if int(chips[i].get("launches", 0)) <= 0:
					chips.remove_at(i)
	return chips


static func _split_oversized_chips(chips: Array, rng: RandomNumberGenerator) -> Array:
	var result: Array = []
	for chip in chips:
		var launches := int(chip.get("launches", 0))
		var color := int(chip.get("color", -1))
		while launches > PREFERRED_CHIP_MAX:
			var chunk := rng.randi_range(PREFERRED_CHIP_MIN, PREFERRED_CHIP_MAX)
			chunk = mini(chunk, launches)
			result.append({"color": color, "launches": chunk})
			launches -= chunk
		if launches > 0:
			result.append({"color": color, "launches": launches})
	return result


func _shortest_column() -> int:
	var best := 0
	var best_h := 999999
	for i in range(columns.size()):
		var h: int = columns[i].size()
		if h < best_h:
			best_h = h
			best = i
	return best


static func _split_total_into_parts(total: int, rng: RandomNumberGenerator) -> Array[int]:
	var parts: Array[int] = []
	var remaining := total
	while remaining > 0:
		if remaining <= PREFERRED_CHIP_MAX:
			parts.append(remaining)
			break
		var chunk := _random_chip_size(rng)
		chunk = mini(chunk, remaining)
		parts.append(chunk)
		remaining -= chunk
	return parts


static func _random_chip_size(rng: RandomNumberGenerator) -> int:
	return rng.randi_range(PREFERRED_CHIP_MIN, PREFERRED_CHIP_MAX)


static func _shuffle_in_place(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
