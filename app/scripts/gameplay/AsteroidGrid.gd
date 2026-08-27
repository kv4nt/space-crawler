class_name AsteroidGrid
extends RefCounted
## AsteroidGrid — модель поля добычи (Шаг 2: Вертикальный срез).
## Хранит клетки, пересчитывает связность с открытой областью (границей поля
## и уже добытыми клетками) и предоставляет операции раскрытия/добычи без
## какой-либо визуализации.

var width: int
var height: int
var color_count: int
var cells: Array = [] # Array[Array[GridCell]], индекс [x][y]

var mined_count_by_color: Dictionary = {}


func _init(p_width: int, p_height: int, p_color_count: int) -> void:
	width = p_width
	height = p_height
	color_count = p_color_count
	for c in range(color_count):
		mined_count_by_color[c] = 0
	_generate()


func _generate() -> void:
	cells.clear()
	for x in range(width):
		var column: Array = []
		for y in range(height):
			var color := randi() % color_count
			column.append(GridCell.new(color))
		cells.append(column)
	_recompute_exposure()


func is_inside(x: int, y: int) -> bool:
	return x >= 0 and x < width and y >= 0 and y < height


func get_cell(x: int, y: int) -> GridCell:
	if not is_inside(x, y):
		return null
	return cells[x][y]


func is_border(x: int, y: int) -> bool:
	return x == 0 or y == 0 or x == width - 1 or y == height - 1


func get_neighbors(x: int, y: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []

	var offsets: Array[Vector2i] = [
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1),
	]

	for offset: Vector2i in offsets:
		var nx: int = x + offset.x
		var ny: int = y + offset.y

		if is_inside(nx, ny):
			result.append(Vector2i(nx, ny))

	return result


## Флуд-филл от открытой области (граница поля + уже добытые клетки).
## Любая hidden/revealed клетка, достижимая по такому маршруту, становится
## exposed (доступной для назначения на добычу).
func _recompute_exposure() -> void:
	var visited: Dictionary = {}
	var queue: Array = []

	for x in range(width):
		for y in range(height):
			var cell := get_cell(x, y)
			if cell.state == GridCell.State.MINED or is_border(x, y):
				var pos := Vector2i(x, y)
				if not visited.has(pos):
					visited[pos] = true
					queue.append(pos)

	var head := 0
	while head < queue.size():
		var pos: Vector2i = queue[head]
		head += 1
		var cell := get_cell(pos.x, pos.y)
		if cell.state == GridCell.State.HIDDEN or cell.state == GridCell.State.REVEALED:
			cell.state = GridCell.State.EXPOSED
		if cell.state == GridCell.State.MINED or is_border(pos.x, pos.y):
			for neighbor in get_neighbors(pos.x, pos.y):
				if not visited.has(neighbor):
					visited[neighbor] = true
					queue.append(neighbor)


func get_exposed_unassigned_cells() -> Array:
	var result: Array = []
	for x in range(width):
		for y in range(height):
			var cell := get_cell(x, y)
			if cell.state == GridCell.State.EXPOSED and cell.assigned_dock == -1:
				result.append(Vector2i(x, y))
	return result


func assign_cell(pos: Vector2i, dock_index: int) -> bool:
	var cell := get_cell(pos.x, pos.y)
	if cell == null:
		return false
	if cell.state != GridCell.State.EXPOSED or cell.assigned_dock != -1:
		return false
	cell.assigned_dock = dock_index
	return true


func complete_mining(pos: Vector2i) -> void:
	var cell := get_cell(pos.x, pos.y)
	if cell == null:
		return
	cell.state = GridCell.State.MINED
	cell.assigned_dock = -1
	mined_count_by_color[cell.color] += 1
	_recompute_exposure()


func cancel_assignment(pos: Vector2i) -> void:
	var cell := get_cell(pos.x, pos.y)
	if cell != null and cell.state == GridCell.State.EXPOSED:
		cell.assigned_dock = -1


func has_remaining_exposed_of_color(target_color: int) -> bool:
	for x in range(width):
		for y in range(height):
			var cell := get_cell(x, y)
			if cell.state == GridCell.State.EXPOSED and cell.assigned_dock == -1 and cell.color == target_color:
				return true
	return false
