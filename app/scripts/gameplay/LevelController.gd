extends Control
## LevelController — Шаг 3: Feel. Визуальный слой над логикой Шага 2
## (AsteroidGrid/DockManager/GridCell не меняются). Рисует цвета минералов,
## пульсацию доступных клеток, доки-корабли с прогрессом добычи, лучи
## док->клетка и вспышку частиц при завершении добычи. Звук подключается
## отдельным шагом с лицензированными временными SFX/музыкой.

var grid: AsteroidGrid
var dock_manager: DockManager

var game_over: bool = false
var elapsed_time: float = 0.0

var cell_buttons: Dictionary = {}
var dock_ship_icons: Array = []
var dock_progress_bars: Array = []
var dock_labels: Array = []
var beams: Dictionary = {} # dock_index -> {"line": Line2D, "target": Vector2i}

var progress_swatches: Array = []
var progress_value_labels: Array = []

@onready var grid_container: GridContainer = %GridContainer
@onready var docks_box: HBoxContainer = %DocksBox
@onready var status_label: Label = %StatusLabel
@onready var restart_button: Button = %RestartButton
@onready var progress_box: HBoxContainer = %ProgressBox
@onready var effects_layer: Node2D = %EffectsLayer
@onready var win_loss_panel: Control = %WinLossPanel
@onready var win_loss_label: Label = %WinLossLabel

const COLOR_NAMES := ["Красный", "Зелёный", "Синий"]
const HIDDEN_COLOR := Color(0.16, 0.18, 0.26)
const REVEALED_COLOR := Color(0.22, 0.24, 0.34)
const MINED_COLOR := Color(0.10, 0.11, 0.16)
const DOCK_FREE_COLOR := Color(0.30, 0.32, 0.42)


func _ready() -> void:
	restart_button.pressed.connect(_on_restart_pressed)
	win_loss_panel.visible = false
	_start_level()


func _start_level() -> void:
	game_over = false
	elapsed_time = 0.0
	win_loss_panel.visible = false
	grid = AsteroidGrid.new(GameBalance.GRID_WIDTH, GameBalance.GRID_HEIGHT, GameBalance.DEFAULT_COLOR_COUNT)
	dock_manager = DockManager.new(GameBalance.DEFAULT_DOCK_COUNT, GameBalance.MINE_DURATION_SECONDS)
	_clear_all_beams()
	_build_grid_ui()
	_build_docks_ui()
	_build_progress_ui()
	_refresh_all()


func _build_grid_ui() -> void:
	for child in grid_container.get_children():
		child.queue_free()
	cell_buttons.clear()
	grid_container.columns = grid.width
	for y in range(grid.height):
		for x in range(grid.width):
			var button := Button.new()
			button.custom_minimum_size = Vector2(44, 44)
			button.flat = false
			var pos := Vector2i(x, y)
			button.pressed.connect(_on_cell_pressed.bind(pos))
			grid_container.add_child(button)
			cell_buttons[pos] = button


func _build_docks_ui() -> void:
	for child in docks_box.get_children():
		child.queue_free()
	dock_ship_icons.clear()
	dock_progress_bars.clear()
	dock_labels.clear()
	for i in range(dock_manager.docks.size()):
		var column := VBoxContainer.new()
		column.alignment = BoxContainer.ALIGNMENT_CENTER

		var ship_icon := ColorRect.new()
		ship_icon.custom_minimum_size = Vector2(40, 40)
		ship_icon.color = DOCK_FREE_COLOR
		column.add_child(ship_icon)

		var timer_bar := ProgressBar.new()
		timer_bar.custom_minimum_size = Vector2(56, 10)
		timer_bar.min_value = 0.0
		timer_bar.max_value = 1.0
		timer_bar.value = 0.0
		timer_bar.show_percentage = false
		column.add_child(timer_bar)

		var label := Label.new()
		label.text = "Док %d" % (i + 1)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(label)

		docks_box.add_child(column)
		dock_ship_icons.append(ship_icon)
		dock_progress_bars.append(timer_bar)
		dock_labels.append(label)


func _build_progress_ui() -> void:
	for child in progress_box.get_children():
		child.queue_free()
	progress_swatches.clear()
	progress_value_labels.clear()
	for c in range(grid.color_count):
		var group := HBoxContainer.new()
		group.add_theme_constant_override("separation", 4)

		var swatch := ColorRect.new()
		swatch.custom_minimum_size = Vector2(16, 16)
		swatch.color = GameBalance.MINERAL_COLORS[c]
		group.add_child(swatch)

		var value_label := Label.new()
		group.add_child(value_label)

		progress_box.add_child(group)
		progress_swatches.append(swatch)
		progress_value_labels.append(value_label)


func _process(delta: float) -> void:
	if game_over:
		return
	elapsed_time += delta

	var completed: Array = dock_manager.tick(delta)
	if completed.size() > 0:
		for pos in completed:
			var mined_cell := grid.get_cell(pos.x, pos.y)
			var mined_color: int = mined_cell.color
			grid.complete_mining(pos)
			_spawn_burst(_get_global_center(cell_buttons[pos]), GameBalance.MINERAL_COLORS[mined_color])
		_clear_finished_beams(completed)
		_check_win_loss()

	_update_dock_visuals()
	_update_beams()
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
	_spawn_beam(dock_index, pos, GameBalance.MINERAL_COLORS[cell.color])
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
		_show_win_loss("Победа! Все жилы добыты.")
		return

	if dock_manager.busy_count() == 0:
		var deadlock := true
		for c in range(grid.color_count):
			if grid.mined_count_by_color[c] < target and grid.has_remaining_exposed_of_color(c):
				deadlock = false
				break
		if deadlock:
			game_over = true
			_show_win_loss("Поражение: доступных жил не осталось.")


func _show_win_loss(message: String) -> void:
	win_loss_label.text = message
	win_loss_panel.visible = true
	_clear_all_beams()


func _get_global_center(control: Control) -> Vector2:
	return control.get_global_rect().get_center()


func _spawn_beam(dock_index: int, target_pos: Vector2i, color: Color) -> void:
	var line := Line2D.new()
	line.width = GameBalance.BEAM_WIDTH
	line.default_color = color
	line.add_point(Vector2.ZERO)
	line.add_point(Vector2.ZERO)
	effects_layer.add_child(line)
	beams[dock_index] = {"line": line, "target": target_pos}


func _update_beams() -> void:
	for dock_index in beams.keys():
		var data: Dictionary = beams[dock_index]
		var line: Line2D = data["line"]
		var target_pos: Vector2i = data["target"]
		if dock_index >= dock_ship_icons.size():
			continue
		var start := effects_layer.to_local(_get_global_center(dock_ship_icons[dock_index]))
		var end := effects_layer.to_local(_get_global_center(cell_buttons[target_pos]))
		line.set_point_position(0, start)
		line.set_point_position(1, end)


func _clear_finished_beams(completed: Array) -> void:
	for dock_index in beams.keys().duplicate():
		var data: Dictionary = beams[dock_index]
		if completed.has(data["target"]):
			data["line"].queue_free()
			beams.erase(dock_index)


func _clear_all_beams() -> void:
	for dock_index in beams.keys():
		beams[dock_index]["line"].queue_free()
	beams.clear()


func _spawn_burst(global_pos: Vector2, color: Color) -> void:
	var particles := CPUParticles2D.new()
	particles.position = effects_layer.to_local(global_pos)
	particles.emitting = false
	particles.one_shot = true
	particles.amount = GameBalance.MINE_BURST_PARTICLE_AMOUNT
	particles.lifetime = GameBalance.MINE_BURST_LIFETIME_SECONDS
	particles.explosiveness = 1.0
	particles.direction = Vector2.ZERO
	particles.spread = 180.0
	particles.initial_velocity_min = 40.0
	particles.initial_velocity_max = 90.0
	particles.gravity = Vector2.ZERO
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.color = color
	effects_layer.add_child(particles)
	particles.emitting = true
	get_tree().create_timer(GameBalance.MINE_BURST_LIFETIME_SECONDS + 0.1).timeout.connect(particles.queue_free)


func _update_dock_visuals() -> void:
	for i in range(dock_manager.docks.size()):
		var dock = dock_manager.docks[i]
		var bar: ProgressBar = dock_progress_bars[i]
		var icon: ColorRect = dock_ship_icons[i]
		var label: Label = dock_labels[i]
		if dock.busy:
			var progress := 1.0 - (dock.timer_left / dock_manager.mine_duration)
			bar.value = progress
			var mined_cell := grid.get_cell(dock.target.x, dock.target.y)
			icon.color = GameBalance.MINERAL_COLORS[mined_cell.color] if mined_cell != null else DOCK_FREE_COLOR
			label.text = "Док %d: %.1fс" % [i + 1, dock.timer_left]
		else:
			bar.value = 0.0
			icon.color = DOCK_FREE_COLOR
			label.text = "Док %d: своб." % [i + 1]


func _refresh_all() -> void:
	var pulse_phase := sin(elapsed_time * TAU / GameBalance.PULSE_PERIOD_SECONDS) * 0.5 + 0.5
	var pulse_alpha: float = lerp(GameBalance.PULSE_MIN_ALPHA, GameBalance.PULSE_MAX_ALPHA, pulse_phase)

	for pos in cell_buttons.keys():
		var cell := grid.get_cell(pos.x, pos.y)
		var button: Button = cell_buttons[pos]
		match cell.state:
			GridCell.State.HIDDEN:
				button.text = "?"
				button.disabled = true
				button.modulate = Color(1, 1, 1, 1)
				button.self_modulate = HIDDEN_COLOR
			GridCell.State.REVEALED:
				button.text = "?"
				button.disabled = true
				button.modulate = Color(1, 1, 1, 1)
				button.self_modulate = REVEALED_COLOR
			GridCell.State.EXPOSED:
				var color: Color = GameBalance.MINERAL_COLORS[cell.color]
				button.self_modulate = color
				if cell.assigned_dock == -1:
					button.text = "*"
					button.disabled = game_over
					button.modulate = Color(1, 1, 1, pulse_alpha)
				else:
					button.text = "…"
					button.disabled = true
					button.modulate = Color(1, 1, 1, 0.6)
			GridCell.State.MINED:
				button.text = "v"
				button.disabled = true
				button.modulate = Color(1, 1, 1, 1)
				button.self_modulate = MINED_COLOR

	if not game_over:
		for c in range(grid.color_count):
			progress_value_labels[c].text = "%d/%d" % [grid.mined_count_by_color[c], GameBalance.TARGET_PER_COLOR]
		status_label.text = "Выберите доступную (*) клетку и назначьте её на свободный док"
