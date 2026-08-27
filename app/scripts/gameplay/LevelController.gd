extends Control
## LevelController — Шаг 2: Вертикальный срез. Отладочный UI без визуальных
## эффектов: связывает AsteroidGrid и DockManager, обрабатывает ввод игрока
## (выбор доступной клетки -> назначение на свободный док) и проверяет
## победу/поражение. Визуальные эффекты и арт появятся на Этапе 3 (Feel).

var grid: AsteroidGrid
var dock_manager: DockManager

var game_over: bool = false

var cell_buttons: Dictionary = {}
var dock_labels: Array = []

@onready var grid_container: GridContainer = %GridContainer
@onready var docks_box: HBoxContainer = %DocksBox
@onready var status_label: Label = %StatusLabel
@onready var restart_button: Button = %RestartButton

const COLOR_NAMES := ["Красный", "Зелёный", "Синий"]


func _ready() -> void:
	restart_button.pressed.connect(_on_restart_pressed)
	_start_level()


func _start_level() -> void:
	game_over = false
	grid = AsteroidGrid.new(GameBalance.GRID_WIDTH, GameBalance.GRID_HEIGHT, GameBalance.DEFAULT_COLOR_COUNT)
	dock_manager = DockManager.new(GameBalance.DEFAULT_DOCK_COUNT, GameBalance.MINE_DURATION_SECONDS)
	_build_grid_ui()
	_build_docks_ui()
	_refresh_all()


func _build_grid_ui() -> void:
	for child in grid_container.get_children():
		child.queue_free()
	cell_buttons.clear()
	grid_container.columns = grid.width
	for y in range(grid.height):
		for x in range(grid.width):
			var button := Button.new()
			button.custom_minimum_size = Vector2(48, 48)
			var pos := Vector2i(x, y)
			button.pressed.connect(_on_cell_pressed.bind(pos))
			grid_container.add_child(button)
			cell_buttons[pos] = button


func _build_docks_ui() -> void:
	for child in docks_box.get_children():
		child.queue_free()
	dock_labels.clear()
	for i in range(dock_manager.docks.size()):
		var label := Label.new()
		docks_box.add_child(label)
		dock_labels.append(label)


func _process(delta: float) -> void:
	if game_over:
		return
	var completed: Array = dock_manager.tick(delta)
	if completed.size() > 0:
		for pos in completed:
			grid.complete_mining(pos)
		_check_win_loss()
	_refresh_all()


func _on_cell_pressed(pos: Vector2i) -> void:
	if game_over:
		return
	var cell := grid.get_cell(pos.x, pos.y)
	if cell == null or cell.state != GridCell.State.EXPOSED or cell.assigned_dock != -1:
		return
	var dock_index := dock_manager.get_free_dock_index()
	if dock_index == -1:
		status_label.text = "Все доки заняты"
		return
	grid.assign_cell(pos, dock_index)
	dock_manager.launch(dock_index, pos)
	_refresh_all()


func _on_restart_pressed() -> void:
	_start_level()


func _check_win_loss() -> void:
	var target: int = GameBalance.TARGET_PER_COLOR
	var win := true
	for c in range(grid.color_count):
		if grid.mined_count_by_color[c] < target:
			win = false
			break
	if win:
		game_over = true
		status_label.text = "Победа! Все жилы добыты."
		return

	if dock_manager.busy_count() == 0:
		var deadlock := true
		for c in range(grid.color_count):
			if grid.mined_count_by_color[c] < target and grid.has_remaining_exposed_of_color(c):
				deadlock = false
				break
		if deadlock:
			game_over = true
			status_label.text = "Поражение: доступных жил не осталось."


func _refresh_all() -> void:
	for pos in cell_buttons.keys():
		var cell := grid.get_cell(pos.x, pos.y)
		var button: Button = cell_buttons[pos]
		match cell.state:
			GridCell.State.HIDDEN:
				button.text = "?"
				button.disabled = true
			GridCell.State.REVEALED:
				button.text = "."
				button.disabled = true
			GridCell.State.EXPOSED:
				var mark := "*" if cell.assigned_dock == -1 else "…"
				button.text = "%s%d" % [mark, cell.color]
				button.disabled = cell.assigned_dock != -1 or game_over
			GridCell.State.MINED:
				button.text = "v"
				button.disabled = true

	for i in range(dock_manager.docks.size()):
		var dock = dock_manager.docks[i]
		var label: Label = dock_labels[i]
		if dock.busy:
			label.text = "Док %d: %.1fс" % [i + 1, dock.timer_left]
		else:
			label.text = "Док %d: своб." % [i + 1]

	if not game_over:
		var progress: Array = []
		for c in range(grid.color_count):
			progress.append("%s %d/%d" % [COLOR_NAMES[c], grid.mined_count_by_color[c], GameBalance.TARGET_PER_COLOR])
		status_label.text = ", ".join(progress)
