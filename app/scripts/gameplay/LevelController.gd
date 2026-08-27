extends Control
## Step 3b: visual mining flights. Gameplay models remain unchanged.

var grid: AsteroidGrid
var dock_manager: DockManager
var game_over := false
var elapsed_time := 0.0
var cell_buttons := {}
var dock_ship_icons: Array = []
var dock_progress_bars: Array = []
var dock_labels: Array = []
var beams := {}
var drones := {} # dock_index -> {node: Polygon2D, target: Vector2i, tween: Tween}
var progress_value_labels: Array = []

@onready var grid_container: GridContainer = %GridContainer
@onready var docks_box: HBoxContainer = %DocksBox
@onready var status_label: Label = %StatusLabel
@onready var restart_button: Button = %RestartButton
@onready var progress_box: HBoxContainer = %ProgressBox
@onready var effects_layer: Node2D = %EffectsLayer
@onready var win_loss_panel: Control = %WinLossPanel
@onready var win_loss_label: Label = %WinLossLabel

const HIDDEN_COLOR := Color(0.16, 0.18, 0.26)
const REVEALED_COLOR := Color(0.22, 0.24, 0.34)
const MINED_COLOR := Color(0.10, 0.11, 0.16)
const DOCK_FREE_COLOR := Color(0.30, 0.32, 0.42)
const DRONE_FLIGHT_SECONDS := 0.28

func _ready() -> void:
	restart_button.pressed.connect(_on_restart_pressed)
	_start_level()

func _start_level() -> void:
	game_over = false
	elapsed_time = 0.0
	win_loss_panel.visible = false
	_clear_all_beams()
	_clear_all_drones()
	grid = AsteroidGrid.new(GameBalance.GRID_WIDTH, GameBalance.GRID_HEIGHT, GameBalance.DEFAULT_COLOR_COUNT)
	dock_manager = DockManager.new(GameBalance.DEFAULT_DOCK_COUNT, GameBalance.MINE_DURATION_SECONDS)
	_build_grid_ui()
	_build_docks_ui()
	_build_progress_ui()
	_refresh_all()

func _build_grid_ui() -> void:
	for child in grid_container.get_children(): child.queue_free()
	cell_buttons.clear()
	grid_container.columns = grid.width
	for y in range(grid.height):
		for x in range(grid.width):
			var button := Button.new()
			button.custom_minimum_size = Vector2(44, 44)
			var pos := Vector2i(x, y)
			button.pressed.connect(_on_cell_pressed.bind(pos))
			grid_container.add_child(button)
			cell_buttons[pos] = button

func _build_docks_ui() -> void:
	for child in docks_box.get_children(): child.queue_free()
	dock_ship_icons.clear(); dock_progress_bars.clear(); dock_labels.clear()
	for i in range(dock_manager.docks.size()):
		var column := VBoxContainer.new()
		column.alignment = BoxContainer.ALIGNMENT_CENTER
		var icon := ColorRect.new(); icon.custom_minimum_size = Vector2(40, 40); icon.color = DOCK_FREE_COLOR
		var bar := ProgressBar.new(); bar.custom_minimum_size = Vector2(56, 10); bar.max_value = 1.0; bar.show_percentage = false
		var label := Label.new(); label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(icon); column.add_child(bar); column.add_child(label); docks_box.add_child(column)
		dock_ship_icons.append(icon); dock_progress_bars.append(bar); dock_labels.append(label)

func _build_progress_ui() -> void:
	for child in progress_box.get_children(): child.queue_free()
	progress_value_labels.clear()
	for c in range(grid.color_count):
		var group := HBoxContainer.new(); group.add_theme_constant_override("separation", 4)
		var swatch := ColorRect.new(); swatch.custom_minimum_size = Vector2(16, 16); swatch.color = GameBalance.MINERAL_COLORS[c]
		var label := Label.new()
		group.add_child(swatch); group.add_child(label); progress_box.add_child(group)
		progress_value_labels.append(label)

func _process(delta: float) -> void:
	if game_over: return
	elapsed_time += delta
	var completed: Array = dock_manager.tick(delta)
	for pos in completed:
		var cell := grid.get_cell(pos.x, pos.y)
		var color := GameBalance.MINERAL_COLORS[cell.color]
		grid.complete_mining(pos)
		_spawn_burst(_get_global_center(cell_buttons[pos]), color)
	_clear_finished_beams(completed)
	_return_finished_drones(completed)
	if not completed.is_empty(): _check_win_loss()
	_update_dock_visuals(); _update_beams(); _refresh_all()

func _on_cell_pressed(pos: Vector2i) -> void:
	if game_over: return
	var cell := grid.get_cell(pos.x, pos.y)
	if cell == null or cell.state != GridCell.State.EXPOSED or cell.assigned_dock != -1: return
	var dock_index := dock_manager.get_free_dock_index()
	if dock_index == -1: status_label.text = "Все доки заняты"; return
	grid.assign_cell(pos, dock_index); dock_manager.launch(dock_index, pos)
	var color := GameBalance.MINERAL_COLORS[cell.color]
	_spawn_beam(dock_index, pos, color); _spawn_drone(dock_index, pos, color); _refresh_all()

func _on_restart_pressed() -> void: _start_level()

func _check_win_loss() -> void:
	var won := true
	for c in range(grid.color_count):
		if grid.mined_count_by_color[c] < GameBalance.TARGET_PER_COLOR: won = false; break
	if won: game_over = true; _show_win_loss("Победа! Все жилы добыты."); return
	if dock_manager.busy_count() == 0:
		var deadlock := true
		for c in range(grid.color_count):
			if grid.mined_count_by_color[c] < GameBalance.TARGET_PER_COLOR and grid.has_remaining_exposed_of_color(c): deadlock = false; break
		if deadlock: game_over = true; _show_win_loss("Поражение: доступных жил не осталось.")

func _show_win_loss(message: String) -> void:
	win_loss_label.text = message; win_loss_panel.visible = true; _clear_all_beams(); _clear_all_drones()

func _get_global_center(control: Control) -> Vector2: return control.get_global_rect().get_center()
func _dock_point(index: int) -> Vector2: return effects_layer.to_local(_get_global_center(dock_ship_icons[index]))
func _cell_point(pos: Vector2i) -> Vector2: return effects_layer.to_local(_get_global_center(cell_buttons[pos]))

func _spawn_drone(index: int, target: Vector2i, color: Color) -> void:
	var drone := Polygon2D.new()
	drone.polygon = PackedVector2Array([Vector2(0, -12), Vector2(10, 10), Vector2(0, 6), Vector2(-10, 10)])
	drone.color = color; drone.position = _dock_point(index)
	effects_layer.add_child(drone)
	var tween := create_tween(); tween.tween_property(drone, "position", _cell_point(target), DRONE_FLIGHT_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	drones[index] = {"node": drone, "target": target, "tween": tween}

func _return_finished_drones(completed: Array) -> void:
	for index in drones.keys().duplicate():
		var data: Dictionary = drones[index]
		if completed.has(data.target):
			var drone: Polygon2D = data.node
			if is_instance_valid(data.tween): data.tween.kill()
			var tween := create_tween(); tween.tween_property(drone, "position", _dock_point(index), DRONE_FLIGHT_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			tween.tween_callback(drone.queue_free); drones.erase(index)

func _clear_all_drones() -> void:
	for data in drones.values():
		if is_instance_valid(data.tween): data.tween.kill()
		if is_instance_valid(data.node): data.node.queue_free()
	drones.clear()

func _spawn_beam(index: int, target: Vector2i, color: Color) -> void:
	var line := Line2D.new(); line.width = GameBalance.BEAM_WIDTH; line.default_color = color
	line.add_point(Vector2.ZERO); line.add_point(Vector2.ZERO); effects_layer.add_child(line); beams[index] = {"line": line, "target": target}
func _update_beams() -> void:
	for index in beams.keys():
		var data: Dictionary = beams[index]
		data.line.set_point_position(0, _dock_point(index)); data.line.set_point_position(1, _cell_point(data.target))
func _clear_finished_beams(completed: Array) -> void:
	for index in beams.keys().duplicate():
		if completed.has(beams[index].target): beams[index].line.queue_free(); beams.erase(index)
func _clear_all_beams() -> void:
	for data in beams.values(): data.line.queue_free()
	beams.clear()

func _spawn_burst(global_pos: Vector2, color: Color) -> void:
	var particles := CPUParticles2D.new(); particles.position = effects_layer.to_local(global_pos); particles.one_shot = true; particles.amount = GameBalance.MINE_BURST_PARTICLE_AMOUNT; particles.lifetime = GameBalance.MINE_BURST_LIFETIME_SECONDS; particles.explosiveness = 1.0; particles.spread = 180.0; particles.initial_velocity_min = 40.0; particles.initial_velocity_max = 90.0; particles.gravity = Vector2.ZERO; particles.color = color
	effects_layer.add_child(particles); particles.emitting = true
	get_tree().create_timer(GameBalance.MINE_BURST_LIFETIME_SECONDS + 0.1).timeout.connect(particles.queue_free)

func _update_dock_visuals() -> void:
	for i in range(dock_manager.docks.size()):
		var dock = Dictionary = dock_manager.docks[i]; var bar: ProgressBar = dock_progress_bars[i]; var icon: ColorRect = dock_ship_icons[i]; var label: Label = dock_labels[i]
		if dock.busy:
			bar.value = 1.0 - dock.timer_left / dock_manager.mine_duration
			icon.color = GameBalance.MINERAL_COLORS[grid.get_cell(dock.target.x, dock.target.y).color]
			label.text = "Док %d: %.1fс" % [i + 1, dock.timer_left]
		else: bar.value = 0.0; icon.color = DOCK_FREE_COLOR; label.text = "Док %d: своб." % [i + 1]

func _refresh_all() -> void:
	var pulse := lerp(GameBalance.PULSE_MIN_ALPHA, GameBalance.PULSE_MAX_ALPHA, sin(elapsed_time * TAU / GameBalance.PULSE_PERIOD_SECONDS) * 0.5 + 0.5)
	for pos in cell_buttons.keys():
		var cell = grid.get_cell(pos.x, pos.y); var button: Button = cell_buttons[pos]
		if cell.state == GridCell.State.HIDDEN: button.text = "?"; button.disabled = true; button.modulate = Color.WHITE; button.self_modulate = HIDDEN_COLOR
		elif cell.state == GridCell.State.REVEALED: button.text = "?"; button.disabled = true; button.modulate = Color.WHITE; button.self_modulate = REVEALED_COLOR
		elif cell.state == GridCell.State.EXPOSED:
			button.self_modulate = GameBalance.MINERAL_COLORS[cell.color]
			button.text = "*" if cell.assigned_dock == -1 else "…"; button.disabled = cell.assigned_dock != -1 or game_over; button.modulate = Color(1, 1, 1, pulse if cell.assigned_dock == -1 else 0.6)
		else: button.text = "v"; button.disabled = true; button.modulate = Color.WHITE; button.self_modulate = MINED_COLOR
	if not game_over:
		for c in range(grid.color_count): progress_value_labels[c].text = "%d/%d" % [grid.mined_count_by_color[c], GameBalance.TARGET_PER_COLOR]
		status_label.text = "Выберите доступную (*) клетку и назначьте её на свободный док"