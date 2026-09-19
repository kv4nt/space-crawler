extends Control
## LevelController — Food Hunt механика: тап по стопке цвета → слот → поедание пикселей.

var grid: AsteroidGrid
var slot_manager: SlotManager
var color_vending: ColorVending
var level_config: Dictionary = {}
var game_over := false
var elapsed_time := 0.0
var cell_panels := {}
var dock_ship_icons: Array = []
var dock_slot_bars: Array = []
var dock_slot_counts: Array = []
var dock_lock_labels: Array = []
var dock_labels: Array = []
var dock_capsules: Array = []
var dock_slot_fills: Array = []
var vending_column_tops: Dictionary = {}
var _vending_reels: Array = []
var color_count_squares: Array = []
var slot_vending_col: Dictionary = {}
var slot_launch_points: Dictionary = {}
var booster_entries: Array = []
var hint_color: int = -1
var hint_timer: float = 0.0


func _mineral_color(tier: int) -> Color:
	var mineral_idx := tier if grid == null else grid.mineral_index(tier)
	return GameBalance.MINERAL_COLORS[clampi(mineral_idx, 0, GameBalance.MINERAL_COLORS.size() - 1)]


func _mineral_text_color(tier: int) -> Color:
	var mineral_idx := tier if grid == null else grid.mineral_index(tier)
	return GameTheme.mineral_chip_text_color(mineral_idx)


var level_title: Label
var _difficulty_pill: PanelContainer
var _difficulty_label: Label
var lives_label: Label
var lives_timer_label: Label
var credits_label: Label
var _footer_status_label: Label
var _status_message: String = ""
var _confirm_layer: CanvasLayer
var _confirm_panel: Control
var _confirm_title: Label
var _confirm_message: Label
var _confirm_yes_btn: Button
var _confirm_no_btn: Button
var _confirm_action: Callable
var _storage_bar: BunkerFillGauge
var _booster_modal: BoosterShopModal
var _booster_modal_layer: CanvasLayer
var _resource_modal: ResourcePurchaseModal
var _resource_modal_layer: CanvasLayer
var _remainder_bar: VBoxContainer
var _field_colors_box: VBoxContainer
var _right_sidebar: VBoxContainer
var _fleet_center_wrap: PanelContainer
var _vending_wrap: PanelContainer
var _lives_plus_btn: Button
var _credits_plus_btn: Button
var _effects_ui: Control
var _settings_modal: SettingsModal
var _settings_button: Button
var _footer_actions: HBoxContainer
var _footer_actions_shell: PanelContainer
var _settings_open: bool = false

const FOOTER_ACTION_BTN_SIZE := Vector2(118, 118)
const FOOTER_ACTION_FONT := 42
const BOOSTERS_PANEL_W := 256
const COLOR_TO_SLOT_SECONDS := 0.34

const BOOSTER_DEFS: Array = [
	{
		"id": "hint", "icon": "💡", "title": "Подсказка",
		"desc": "Получи подсказку и продолжай добычу.",
		"cost": GameBalance.BOOSTER_HINT_COST, "accent": Color(0.95, 0.82, 0.25),
	},
	{
		"id": "unblock", "icon": "➕", "title": "Слот",
		"desc": "Добавляет один слот флота (максимум 5).",
		"cost": GameBalance.BOOSTER_UNBLOCK_COST, "accent": Color(0.45, 0.88, 0.55),
	},
	{
		"id": "scan", "icon": "📡", "title": "Сканер",
		"desc": "Показывает до 10 скрытых блоков (?), примыкающих к открытым.",
		"cost": GameBalance.BOOSTER_SCAN_COST, "accent": Color(0.35, 0.72, 1.0),
	},
	{
		"id": "pulse", "icon": "💥", "title": "Импульс",
		"desc": "Мгновенно добудь до 10 пикселей из активного слота.",
		"cost": GameBalance.BOOSTER_PULSE_COST, "accent": Color(1.0, 0.55, 0.35),
	},
	{
		"id": "warp", "icon": "⚡", "title": "Форсаж",
		"desc": "Ускоряет корабли и слоты на 5 мин.",
		"cost": GameBalance.WARP_CORE_COST_CREDITS, "accent": Color(1.0, 0.82, 0.22),
	},
]

@onready var grid_container: GridContainer = %GridContainer
@onready var funnel_zone: Control = %FunnelZone
@onready var color_count_bar: HBoxContainer = %ColorCountBar
@onready var canvas_inner: PanelContainer = %CanvasInner
@onready var canvas_frame: PanelContainer = %CanvasFrame
@onready var playfield_deck: PanelContainer = %PlayfieldDeck
@onready var footer_bar: PanelContainer = %FooterBar
@onready var color_stacks_box: HBoxContainer = %ColorStacksBox
@onready var docks_box: HBoxContainer = %DocksBox
@onready var status_label: Label = %StatusLabel
@onready var restart_button: Button = %RestartButton
@onready var menu_button: Button = %MenuButton
@onready var effects_layer: Node2D = %EffectsLayer
@onready var win_loss_panel: Control = %WinLossPanel
@onready var win_loss_label: Label = %WinLossLabel
@onready var win_loss_title: Label = %WinLossTitle
@onready var overlay_close_button: Button = %OverlayCloseButton
@onready var menu_exit_button: Button = %MenuExitButton
@onready var next_button: Button = %NextButton
@onready var warp_button: Button = %WarpButton
@onready var speed_badge: Button = %SpeedBadge
@onready var warp_label: Label = %WarpLabel
@onready var boosters_box: BoxContainer = %BoostersBox
@onready var buy_life_button: Button = %BuyLifeButton

const DOCK_FREE_COLOR := Color(0.30, 0.35, 0.50)
const GRID_SEPARATION := 3
const HINT_DURATION_SECONDS := 4.0
const HUD_REFRESH_INTERVAL := 0.12
var _cell_size: int = 48
var _booster_btn_w: int = 80
var _booster_btn_h: int = 52
var _remainder_chip_size: int = 50
var _remainder_col_width: int = 118
var _right_col_width: int = 130
var _vending_cell_size: int = 64
var _dock_capsule_w: int = 96
var _dock_capsule_h: int = 100
var _dock_icon_size: int = 56
var _active_ship_tweens: int = 0
var _level_session_id: int = 0
var _hud_refresh_timer: float = 0.0
var _lives_hud_timer: float = 0.0
var _status_clear_timer: float = 0.0
var _status_prominent: bool = false
var _win_progress_applied: bool = false
var _effects_canvas: CanvasLayer
var _win_loss_canvas: CanvasLayer

const STATUS_UNLOCK_TEXT := "Открыт новый цвет!"
const STATUS_UNLOCK_DURATION := 15.0
const STATUS_UNLOCK_FONT := 36
const STATUS_SLOT_UNLOCK_FONT := 42
const STATUS_NORMAL_FONT := 17


func _ready() -> void:
	UiScale.set_gameplay_mode()
	win_loss_panel.visible = false
	next_button.visible = false
	if is_instance_valid(status_label):
		status_label.visible = false
	var color_count_title := get_node_or_null("PlayfieldDeck/DeckMargin/DeckVBox/ColorCountTitle")
	if color_count_title is CanvasItem:
		color_count_title.visible = false
	_build_top_hud()
	if is_instance_valid(restart_button):
		restart_button.pressed.connect(_on_restart_pressed)
	if is_instance_valid(menu_button):
		menu_button.pressed.connect(_on_menu_pressed)
	if is_instance_valid(next_button):
		next_button.pressed.connect(_on_next_pressed)
	if is_instance_valid(warp_button):
		warp_button.pressed.connect(_on_warp_pressed)
	_ensure_effects_on_top()
	_ensure_win_loss_on_top()
	_apply_bottom_layout()
	_apply_theme()
	_build_booster_modal()
	_build_resource_modal()
	_build_confirm_modal()
	_build_settings_modal()
	_build_boosters_ui()
	_start_level()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		call_deferred("_on_viewport_resized")


var _last_layout_size := Vector2.ZERO


func _on_viewport_resized() -> void:
	if grid == null:
		return
	var vp := get_viewport().get_visible_rect().size
	if vp.is_equal_approx(_last_layout_size):
		return
	_last_layout_size = vp
	var prev_cell := _cell_size
	var prev_vending := _vending_cell_size
	_compute_bottom_metrics()
	_apply_bottom_panel_sizes()
	_configure_deck_layout()
	if _compute_cell_size() != prev_cell:
		_build_grid_ui()
		_refresh_all()
	if _vending_cell_size != prev_vending:
		_build_slots_ui()
		_build_vending_ui()
	_apply_bottom_panel_sizes()
	_build_boosters_ui()
	_build_color_count_bar()
	_refresh_hud()


func _apply_theme() -> void:
	if is_instance_valid(playfield_deck):
		GameTheme.apply_deck(playfield_deck)
	if is_instance_valid(canvas_frame):
		GameTheme.apply_canvas_frame(canvas_frame)
	if is_instance_valid(canvas_inner):
		GameTheme.apply_canvas_inner(canvas_inner)
	if is_instance_valid(footer_bar):
		GameTheme.apply_footer(footer_bar)
	_configure_deck_layout()
	if is_instance_valid(warp_button):
		warp_button.visible = false
	if is_instance_valid(speed_badge):
		speed_badge.visible = false
	if is_instance_valid(warp_label):
		warp_label.visible = false
	_style_win_loss_panel()
	if is_instance_valid(next_button):
		GameTheme.apply_game_over_continue_button(next_button)
	if is_instance_valid(buy_life_button):
		GameTheme.apply_game_over_continue_button(buy_life_button)
	if is_instance_valid(overlay_close_button):
		var close_style := GameTheme.booster_modal_close()
		overlay_close_button.add_theme_stylebox_override("normal", close_style)
		overlay_close_button.add_theme_stylebox_override("hover", close_style)
		overlay_close_button.add_theme_stylebox_override("pressed", close_style)
		overlay_close_button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	if has_node("%OverlayRestartButton"):
		GameTheme.apply_game_over_secondary_button(get_node("%OverlayRestartButton"))
	if is_instance_valid(menu_exit_button):
		GameTheme.apply_game_over_secondary_button(menu_exit_button)
	_style_round_footer_button(
		warp_button, Color(0.15, 0.55, 0.85),
		Color(0.22, 0.65, 0.95), Color(0.10, 0.42, 0.68),
	)
	_style_round_footer_button(
		menu_button, Color(0.35, 0.30, 0.55),
		Color(0.45, 0.38, 0.65), Color(0.28, 0.24, 0.45),
	)
	_style_round_footer_button(
		restart_button, Color(0.30, 0.28, 0.48),
		Color(0.40, 0.36, 0.58), Color(0.22, 0.20, 0.38),
	)
	if is_instance_valid(speed_badge):
		GameTheme.apply_button(speed_badge, Color(0.20, 0.45, 0.90))
	_setup_footer_bar()
	_style_bottom_labels()


func _style_round_footer_button(
	btn: Button, normal: Color, hover: Color, pressed: Color,
) -> void:
	if not is_instance_valid(btn):
		return
	GameTheme.apply_button(btn, normal)
	btn.add_theme_stylebox_override("normal", GameTheme.round_action_btn(normal))
	btn.add_theme_stylebox_override("hover", GameTheme.round_action_btn(hover))
	btn.add_theme_stylebox_override("pressed", GameTheme.round_action_btn(pressed))


func _style_win_loss_panel() -> void:
	if not is_instance_valid(win_loss_panel):
		return
	var card := win_loss_panel.get_node_or_null(
		"CenterContainer/ModalWrap/ResultCard") as PanelContainer
	if card == null:
		return
	card.add_theme_stylebox_override("panel", GameTheme.booster_modal_body())
	var header := win_loss_panel.get_node_or_null(
		"CenterContainer/ModalWrap/HeaderBand") as PanelContainer
	if header == null:
		return
	header.add_theme_stylebox_override("panel", GameTheme.booster_modal_header())
	if not card.has_node("Wood"):
		var wood := Control.new()
		wood.name = "Wood"
		wood.set_script(load("res://scripts/ui/shop/BoosterModalWood.gd"))
		wood.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		wood.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(wood)
		card.move_child(wood, 0)
	var dim: ColorRect = win_loss_panel.get_node("DimOverlay")
	dim.color = Color(0.0, 0.0, 0.0, 0.62)
	if is_instance_valid(win_loss_title):
		win_loss_title.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		win_loss_title.add_theme_font_size_override("font_size", 34)
	if is_instance_valid(win_loss_label):
		win_loss_label.add_theme_color_override("font_color", Color(0.38, 0.20, 0.12))
		win_loss_label.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.2))
		win_loss_label.add_theme_constant_override("outline_size", 2)
		win_loss_label.add_theme_font_size_override("font_size", 28)
		win_loss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if is_instance_valid(next_button):
		GameTheme.apply_booster_modal_buy_button(next_button)
		next_button.add_theme_font_size_override("font_size", 30)
	if is_instance_valid(buy_life_button):
		GameTheme.apply_booster_modal_buy_button(buy_life_button)
	if has_node("%OverlayRestartButton"):
		GameTheme.apply_game_over_secondary_button(get_node("%OverlayRestartButton"))
	if is_instance_valid(menu_exit_button):
		GameTheme.apply_game_over_secondary_button(menu_exit_button)


func _style_bottom_labels() -> void:
	var docks_title := get_node_or_null(
		"PlayfieldDeck/DeckMargin/DeckVBox/BottomDeckArea/BottomTopRow/FleetCenterWrap/BottomCenterColumn/DocksPanel/DocksTitle")
	if docks_title == null:
		docks_title = get_node_or_null(
			"PlayfieldDeck/DeckMargin/DeckVBox/BottomDeckArea/BottomTopRow/BottomCenterColumn/DocksPanel/DocksTitle")
	if docks_title == null:
		docks_title = get_node_or_null("PlayfieldDeck/DeckMargin/DeckVBox/DocksPanel/DocksTitle")
	if docks_title is CanvasItem:
		docks_title.visible = false
	var stacks_title := get_node_or_null(
		"PlayfieldDeck/DeckMargin/DeckVBox/BottomDeckArea/BottomVendingRow/ColorStacksPanel/StacksTitle")
	if stacks_title == null:
		stacks_title = get_node_or_null("PlayfieldDeck/DeckMargin/DeckVBox/ColorStacksPanel/StacksTitle")
	if stacks_title is CanvasItem:
		stacks_title.visible = false
	var color_count_title := get_node_or_null("PlayfieldDeck/DeckMargin/DeckVBox/ColorCountTitle")
	if color_count_title is CanvasItem:
		color_count_title.visible = false
	if is_instance_valid(color_count_bar):
		color_count_bar.visible = false
	var boosters_title := get_node_or_null(
		"PlayfieldDeck/DeckMargin/DeckVBox/BottomDeckArea/BottomTopRow/BoostersWrap/BoostersPanel/BoostersTitle")
	if boosters_title == null:
		boosters_title = get_node_or_null(
			"PlayfieldDeck/DeckMargin/DeckVBox/BottomDeckArea/BottomTopRow/BoostersPanel/BoostersTitle")
	if boosters_title == null:
		boosters_title = get_node_or_null("PlayfieldDeck/DeckMargin/DeckVBox/BoostersPanel/BoostersTitle")
	if boosters_title is Label:
		(boosters_title as Label).text = "БУСТЕРЫ"
		_style_section_title(boosters_title as Label)
	if is_instance_valid(status_label):
		status_label.visible = false


func _get_deck_inner_width() -> float:
	return maxf(get_viewport().get_visible_rect().size.x - 16.0, 320.0)


func _get_bottom_panel_height() -> float:
	var vp := get_viewport().get_visible_rect().size
	return maxf(vp.y * 0.34, float(GameBalance.BOTTOM_PANEL_MIN_H))


func _compute_bottom_metrics(_slot_count: int = GameBalance.MAX_FLEET_SLOTS) -> void:
	var avail := _get_deck_inner_width()
	var section_gap := 8.0

	_booster_btn_w = BOOSTERS_PANEL_W - 8
	_booster_btn_h = clampi(int(_get_bottom_panel_height() * 0.17), 72, 112)

	_remainder_col_width = clampi(int(avail * 0.20 - section_gap), 168, 280)
	_remainder_chip_size = clampi(int((_remainder_col_width - 24) / 5.0), 44, 58)
	_right_col_width = _remainder_col_width + 14

	var vending_cols := ColorVending.GRID_WIDTH
	var vending_gap := 6.0
	var by_w := int((avail - float(BOOSTERS_PANEL_W) - float(_right_col_width) - 28.0
		- (vending_cols - 1) * vending_gap) / float(vending_cols))
	var bottom_h := _get_bottom_panel_height()
	var vending_avail_h := bottom_h - 52.0 - 88.0
	var by_h := int(vending_avail_h / float(ColorVending.VISIBLE_ROWS)) - 5
	_vending_cell_size = clampi(mini(by_w, by_h), 52, 76)
	var fleet_w := vending_cols * _vending_cell_size + (vending_cols - 1) * int(vending_gap)
	var slots := GameBalance.MAX_FLEET_SLOTS
	var slot_gap := 3
	_dock_capsule_w = clampi(int((fleet_w - (slots - 1) * slot_gap) / float(slots)), 32, 42)
	_dock_capsule_h = _dock_capsule_w
	_dock_icon_size = clampi(int(_dock_capsule_w * 0.38), 20, 28)


func _build_top_hud() -> void:
	var top_bar: HBoxContainer = get_node("%TopBar")
	top_bar.custom_minimum_size = Vector2(0, 96)
	for child in top_bar.get_children():
		child.queue_free()

	var shell := PanelContainer.new()
	shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.clip_contents = false
	shell.add_theme_stylebox_override("panel", GameTheme.hud_top_bar())

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	shell.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)

	# --- Слева: уровень + компактная сложность ---
	var level_chip := PanelContainer.new()
	level_chip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	level_chip.add_theme_stylebox_override("panel", GameTheme.hud_level_badge())
	level_chip.custom_minimum_size = Vector2(0, 52)
	var level_row := HBoxContainer.new()
	level_row.add_theme_constant_override("separation", 8)
	level_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var level_word := Label.new()
	level_word.text = "УРОВЕНЬ"
	level_word.add_theme_font_size_override("font_size", 22)
	level_word.add_theme_color_override("font_color", Color(0.84, 0.88, 0.98))
	level_word.add_theme_color_override("font_outline_color", Color(0.12, 0.16, 0.28, 0.85))
	level_word.add_theme_constant_override("outline_size", 2)
	level_row.add_child(level_word)
	level_title = Label.new()
	level_title.text = "1"
	level_title.add_theme_font_size_override("font_size", 38)
	level_title.add_theme_color_override("font_color", Color(0.98, 0.99, 1.0))
	level_title.add_theme_color_override("font_outline_color", Color(0.20, 0.28, 0.55))
	level_title.add_theme_constant_override("outline_size", 4)
	level_row.add_child(level_title)

	_difficulty_pill = PanelContainer.new()
	_difficulty_pill.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_difficulty_pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_difficulty_pill.custom_minimum_size = Vector2(0, 48)
	_difficulty_label = Label.new()
	_difficulty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_difficulty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_difficulty_label.add_theme_font_size_override("font_size", 24)
	_difficulty_label.add_theme_color_override("font_outline_color", Color(0.08, 0.10, 0.14, 0.9))
	_difficulty_label.add_theme_constant_override("outline_size", 2)
	var diff_pad := MarginContainer.new()
	diff_pad.add_theme_constant_override("margin_left", 16)
	diff_pad.add_theme_constant_override("margin_right", 16)
	diff_pad.add_theme_constant_override("margin_top", 5)
	diff_pad.add_theme_constant_override("margin_bottom", 5)
	diff_pad.add_child(_difficulty_label)
	_difficulty_pill.add_child(diff_pad)
	_update_difficulty_badge()

	level_chip.add_child(level_row)
	row.add_child(level_chip)

	var diff_gap := Control.new()
	diff_gap.custom_minimum_size = Vector2(12, 0)
	row.add_child(diff_gap)
	row.add_child(_difficulty_pill)

	var center_spacer := Control.new()
	center_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(center_spacer)

	# --- Справа: жизни + монеты ---
	var stats_row := HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 8)
	stats_row.alignment = BoxContainer.ALIGNMENT_CENTER
	stats_row.size_flags_horizontal = Control.SIZE_SHRINK_END

	var lives_pill := PanelContainer.new()
	lives_pill.clip_contents = false
	lives_pill.custom_minimum_size = Vector2(168, 76)
	lives_pill.add_theme_stylebox_override("panel", GameTheme.hud_stat_chip_life())
	var lives_pad := MarginContainer.new()
	lives_pad.add_theme_constant_override("margin_left", 6)
	lives_pad.add_theme_constant_override("margin_right", 6)
	lives_pad.add_theme_constant_override("margin_top", 4)
	lives_pad.add_theme_constant_override("margin_bottom", 4)
	lives_pill.add_child(lives_pad)
	var lives_vbox := VBoxContainer.new()
	lives_vbox.add_theme_constant_override("separation", 2)
	lives_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	lives_pad.add_child(lives_vbox)
	var lives_row := HBoxContainer.new()
	lives_row.add_theme_constant_override("separation", 4)
	lives_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var heart_lbl := Label.new()
	heart_lbl.text = "♥"
	heart_lbl.add_theme_font_size_override("font_size", 26)
	heart_lbl.add_theme_color_override("font_color", Color(1.0, 0.45, 0.55))
	heart_lbl.add_theme_color_override("font_outline_color", Color(0.10, 0.08, 0.14, 0.85))
	heart_lbl.add_theme_constant_override("outline_size", 2)
	lives_label = Label.new()
	lives_label.text = "0"
	lives_label.add_theme_font_size_override("font_size", 25)
	lives_label.add_theme_color_override("font_color", Color(0.98, 0.99, 1.0))
	lives_label.add_theme_color_override("font_outline_color", Color(0.08, 0.10, 0.18, 0.9))
	lives_label.add_theme_constant_override("outline_size", 3)
	_lives_plus_btn = _make_hud_plus_button()
	_lives_plus_btn.pressed.connect(_on_hud_lives_plus_pressed)
	lives_row.add_child(heart_lbl)
	lives_row.add_child(lives_label)
	lives_row.add_child(_lives_plus_btn)
	lives_vbox.add_child(lives_row)
	lives_timer_label = Label.new()
	lives_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lives_timer_label.add_theme_font_size_override("font_size", 16)
	lives_timer_label.add_theme_color_override("font_color", Color(0.62, 0.92, 1.0))
	lives_timer_label.add_theme_color_override("font_outline_color", Color(0.06, 0.10, 0.18, 0.95))
	lives_timer_label.add_theme_constant_override("outline_size", 4)
	lives_timer_label.custom_minimum_size = Vector2(150, 20)
	lives_timer_label.text = ""
	lives_timer_label.visible = false
	lives_vbox.add_child(lives_timer_label)
	stats_row.add_child(lives_pill)

	var credits_chip := _make_hud_credits_chip()
	credits_label = credits_chip["value"]
	_credits_plus_btn = credits_chip["plus"]
	_credits_plus_btn.pressed.connect(_on_hud_credits_plus_pressed)
	stats_row.add_child(credits_chip["pill"])

	row.add_child(stats_row)

	top_bar.add_child(shell)
	var deck_margin: MarginContainer = playfield_deck.get_node("DeckMargin")
	deck_margin.add_theme_constant_override("margin_top", 4)
	deck_margin.add_theme_constant_override("margin_left", 8)
	deck_margin.add_theme_constant_override("margin_right", 8)


func _ensure_effects_on_top() -> void:
	if not is_instance_valid(effects_layer):
		return
	if effects_layer.get_parent() is CanvasLayer:
		_effects_canvas = effects_layer.get_parent() as CanvasLayer
		_effects_ui = _effects_canvas.get_node_or_null("EffectsUI") as Control
		return
	var canvas := CanvasLayer.new()
	canvas.name = "EffectsCanvas"
	canvas.layer = 40
	var parent := effects_layer.get_parent()
	var idx := effects_layer.get_index()
	parent.remove_child(effects_layer)
	canvas.add_child(effects_layer)
	_effects_ui = Control.new()
	_effects_ui.name = "EffectsUI"
	_effects_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_effects_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(_effects_ui)
	parent.add_child(canvas)
	parent.move_child(canvas, idx)
	effects_layer.z_index = 0
	_effects_canvas = canvas


func _ensure_win_loss_on_top() -> void:
	if win_loss_panel.get_parent() is CanvasLayer:
		_win_loss_canvas = win_loss_panel.get_parent() as CanvasLayer
		return
	var layer := CanvasLayer.new()
	layer.name = "WinLossCanvas"
	layer.layer = 100
	var parent := win_loss_panel.get_parent()
	var idx := win_loss_panel.get_index()
	parent.remove_child(win_loss_panel)
	layer.add_child(win_loss_panel)
	parent.add_child(layer)
	parent.move_child(layer, idx)
	_win_loss_canvas = layer


func _set_gameplay_fx_visible(visible_state: bool) -> void:
	if is_instance_valid(_effects_canvas):
		_effects_canvas.visible = visible_state
	if is_instance_valid(docks_box):
		docks_box.visible = visible_state
	if is_instance_valid(_fleet_center_wrap):
		_fleet_center_wrap.visible = visible_state
	if is_instance_valid(_vending_wrap):
		_vending_wrap.visible = visible_state


func _reset_level_runtime() -> void:
	_level_session_id += 1
	for tween in get_tree().get_processed_tweens():
		if not tween.is_valid():
			continue
		var bound: Node = tween.get_bound_node()
		if bound == self:
			tween.kill()
	for reel in _vending_reels:
		if not is_instance_valid(reel):
			continue
		for tween in get_tree().get_processed_tweens():
			if tween.is_valid() and tween.get_bound_node() == reel:
				tween.kill()
	_active_ship_tweens = 0
	if is_instance_valid(effects_layer):
		for child in effects_layer.get_children():
			child.queue_free()
	if is_instance_valid(_effects_ui):
		for child in _effects_ui.get_children():
			child.queue_free()
	_set_gameplay_fx_visible(true)


func _set_status(text: String, prominent: bool = false, auto_hide_sec: float = 0.0) -> void:
	_status_message = text
	_status_prominent = prominent
	_status_clear_timer = auto_hide_sec
	_refresh_status_display()


func _set_status_unlock() -> void:
	_set_status(STATUS_UNLOCK_TEXT, true, STATUS_UNLOCK_DURATION)


func _refresh_status_display() -> void:
	var text := _status_message
	var warp_active := GameState.is_warp_active()
	if warp_active:
		var m := int(GameState.warp_core_seconds_left) / 60
		var s := int(GameState.warp_core_seconds_left) % 60
		var warp_text := "⚡ Форсаж: %d:%02d" % [m, s]
		text = warp_text if _status_message.is_empty() else "%s  ·  %s" % [warp_text, _status_message]
	if is_instance_valid(_footer_status_label):
		_footer_status_label.text = text
		var prominent := _status_prominent or text.contains("цвет")
		if warp_active and not prominent:
			_footer_status_label.add_theme_font_size_override("font_size", 26)
			_footer_status_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
			_footer_status_label.add_theme_color_override("font_outline_color", Color(0.20, 0.10, 0.02, 0.95))
			_footer_status_label.add_theme_constant_override("outline_size", 5)
		elif prominent and not text.is_empty():
			var status_font := STATUS_SLOT_UNLOCK_FONT if text.contains("Слот") else STATUS_UNLOCK_FONT
			_footer_status_label.add_theme_font_size_override("font_size", status_font)
			_footer_status_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.45))
			_footer_status_label.add_theme_color_override("font_outline_color", Color(0.18, 0.10, 0.02, 0.95))
			_footer_status_label.add_theme_constant_override("outline_size", 6)
		else:
			_footer_status_label.add_theme_font_size_override("font_size", STATUS_NORMAL_FONT)
			_footer_status_label.add_theme_color_override("font_color", Color(0.86, 0.90, 1.0))
			_footer_status_label.add_theme_color_override("font_outline_color", Color(0.10, 0.12, 0.22, 0.9))
			_footer_status_label.add_theme_constant_override("outline_size", 3)
	if is_instance_valid(status_label):
		status_label.text = text


func _update_difficulty_badge() -> void:
	if not is_instance_valid(_difficulty_pill) or not is_instance_valid(_difficulty_label):
		return
	match GameState.get_level_difficulty():
		GameBalance.LevelDifficulty.EXTREME:
			_difficulty_pill.add_theme_stylebox_override("panel", GameTheme.hud_difficulty_extreme())
			_difficulty_label.text = "💀 ЭКСТРЕМАЛЬНЫЙ"
			_difficulty_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.62))
		GameBalance.LevelDifficulty.HARD:
			_difficulty_pill.add_theme_stylebox_override("panel", GameTheme.hud_difficulty_hard())
			_difficulty_label.text = "🔥 СЛОЖНЫЙ"
			_difficulty_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.42))
		_:
			_difficulty_pill.add_theme_stylebox_override("panel", GameTheme.hud_difficulty_normal())
			_difficulty_label.text = "✓ ОБЫЧНЫЙ"
			_difficulty_label.add_theme_color_override("font_color", Color(0.72, 0.96, 0.78))


func _setup_footer_bar() -> void:
	if not is_instance_valid(footer_bar) or not is_instance_valid(menu_button) or not is_instance_valid(restart_button):
		return
	menu_button.text = "🏠"
	menu_button.tooltip_text = "В главное меню"
	restart_button.tooltip_text = "Перезапустить уровень"
	menu_button.custom_minimum_size = FOOTER_ACTION_BTN_SIZE
	restart_button.custom_minimum_size = FOOTER_ACTION_BTN_SIZE
	menu_button.add_theme_font_size_override("font_size", FOOTER_ACTION_FONT)
	restart_button.add_theme_font_size_override("font_size", FOOTER_ACTION_FONT + 2)
	var footer_row := footer_bar.get_node_or_null("FooterMargin/FooterRow") as HBoxContainer
	if footer_row == null:
		return
	_ensure_footer_settings_button(footer_row)
	if not is_instance_valid(_footer_status_label):
		_footer_status_label = Label.new()
		_footer_status_label.name = "FooterStatusLabel"
		_footer_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_footer_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_footer_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_footer_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_footer_status_label.add_theme_font_size_override("font_size", 17)
		_footer_status_label.add_theme_color_override("font_color", Color(0.86, 0.90, 1.0))
		_footer_status_label.add_theme_color_override("font_outline_color", Color(0.10, 0.12, 0.22, 0.9))
		_footer_status_label.add_theme_constant_override("outline_size", 3)
	if menu_button.get_parent() == footer_row:
		footer_row.remove_child(menu_button)
	if restart_button.get_parent() == footer_row:
		footer_row.remove_child(restart_button)
	if is_instance_valid(_footer_actions_shell) and _footer_actions_shell.get_parent() == footer_row:
		footer_row.remove_child(_footer_actions_shell)
	footer_row.add_child(menu_button)
	footer_row.add_child(_footer_status_label)
	footer_row.add_child(_footer_actions_shell)
	_refresh_status_display()


func _ensure_footer_settings_button(footer_row: HBoxContainer) -> void:
	if not is_instance_valid(_footer_actions_shell):
		_footer_actions_shell = PanelContainer.new()
		_footer_actions_shell.name = "FooterActionsShell"
		_footer_actions_shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_footer_actions_shell.add_theme_stylebox_override("panel", GameTheme.footer_action_pair())
	if not is_instance_valid(_footer_actions):
		_footer_actions = HBoxContainer.new()
		_footer_actions.name = "FooterActions"
		_footer_actions.alignment = BoxContainer.ALIGNMENT_CENTER
		_footer_actions.add_theme_constant_override("separation", 8)
		_footer_actions_shell.add_child(_footer_actions)
	if not is_instance_valid(_settings_button):
		_settings_button = Button.new()
		_settings_button.name = "SettingsButton"
		_settings_button.focus_mode = Control.FOCUS_NONE
		_settings_button.text = "⚙"
		_settings_button.tooltip_text = "Настройки"
		_settings_button.custom_minimum_size = FOOTER_ACTION_BTN_SIZE
		_settings_button.add_theme_font_size_override("font_size", FOOTER_ACTION_FONT - 4)
		_settings_button.add_theme_color_override("font_color", Color(0.88, 0.94, 1.0))
		_style_round_footer_button(
			_settings_button,
			Color(0.16, 0.30, 0.46),
			Color(0.22, 0.40, 0.58),
			Color(0.12, 0.24, 0.36),
		)
		_settings_button.pressed.connect(_on_settings_pressed)
		_footer_actions.add_child(_settings_button)
	if restart_button.get_parent() != _footer_actions:
		if restart_button.get_parent():
			restart_button.get_parent().remove_child(restart_button)
		_footer_actions.add_child(restart_button)


func _build_settings_modal() -> void:
	if is_instance_valid(_settings_modal):
		return
	var layer := CanvasLayer.new()
	layer.name = "SettingsLayer"
	layer.layer = 130
	add_child(layer)
	_settings_modal = SettingsModal.new()
	_settings_modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_settings_modal)
	_settings_modal.closed.connect(_on_settings_closed)


func _on_settings_pressed() -> void:
	if not is_instance_valid(_settings_modal):
		return
	AudioService.play_sfx(&"tap")
	_settings_open = true
	_settings_modal.open()


func _on_settings_closed() -> void:
	_settings_open = false


func _style_section_title(lbl: Label) -> void:
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Color(0.94, 0.96, 1.0))
	lbl.add_theme_color_override("font_outline_color", Color(0.12, 0.16, 0.32, 0.95))
	lbl.add_theme_constant_override("outline_size", 6)


func _make_hud_stat_chip(
	icon: String, accent: Color, font_size: int = 18, panel_style: StyleBox = null,
	min_size: Vector2 = Vector2(84, 36),
) -> Dictionary:
	var pill := PanelContainer.new()
	pill.custom_minimum_size = min_size
	var style := panel_style if panel_style != null else GameTheme.hud_stat_chip(accent)
	pill.add_theme_stylebox_override("panel", style)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 4)
	pad.add_theme_constant_override("margin_right", 6)
	pad.add_theme_constant_override("margin_top", 2)
	pad.add_theme_constant_override("margin_bottom", 2)
	pill.add_child(pad)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var icon_lbl := Label.new()
	icon_lbl.text = icon
	icon_lbl.add_theme_font_size_override("font_size", font_size + 2)
	icon_lbl.add_theme_color_override("font_color", accent.lightened(0.18))
	icon_lbl.add_theme_color_override("font_outline_color", Color(0.10, 0.08, 0.14, 0.85))
	icon_lbl.add_theme_constant_override("outline_size", 2)
	var value_lbl := Label.new()
	value_lbl.text = "0"
	value_lbl.add_theme_font_size_override("font_size", font_size + 1)
	value_lbl.add_theme_color_override("font_color", Color(0.98, 0.99, 1.0))
	value_lbl.add_theme_color_override("font_outline_color", Color(0.08, 0.10, 0.18, 0.9))
	value_lbl.add_theme_constant_override("outline_size", 3)
	row.add_child(icon_lbl)
	row.add_child(value_lbl)
	pad.add_child(row)
	return {"pill": pill, "value": value_lbl}


func _make_hud_plus_button() -> Button:
	var btn := Button.new()
	btn.text = "+"
	btn.custom_minimum_size = Vector2(30, 30)
	btn.focus_mode = Control.FOCUS_NONE
	GameTheme.apply_shop_price_button(btn)
	btn.add_theme_font_size_override("font_size", 20)
	return btn


func _make_hud_credits_chip() -> Dictionary:
	var pill := PanelContainer.new()
	pill.custom_minimum_size = Vector2(148, 44)
	pill.add_theme_stylebox_override("panel", GameTheme.hud_stat_chip_credits())
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 4)
	pad.add_theme_constant_override("margin_right", 6)
	pad.add_theme_constant_override("margin_top", 2)
	pad.add_theme_constant_override("margin_bottom", 2)
	pill.add_child(pad)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var coin := GameTheme.make_coin_icon(26)
	row.add_child(coin)
	var value_lbl := Label.new()
	value_lbl.text = "0"
	value_lbl.add_theme_font_size_override("font_size", 22)
	value_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.48))
	value_lbl.add_theme_color_override("font_outline_color", Color(0.20, 0.12, 0.02, 0.9))
	value_lbl.add_theme_constant_override("outline_size", 3)
	row.add_child(value_lbl)
	var plus_btn := _make_hud_plus_button()
	row.add_child(plus_btn)
	pad.add_child(row)
	return {"pill": pill, "value": value_lbl, "plus": plus_btn}


func _deck_panel(deck_vbox: VBoxContainer, panel_name: String) -> Node:
	var panel := deck_vbox.get_node_or_null(panel_name)
	if panel != null:
		return panel
	return deck_vbox.find_child(panel_name, true, false)


func _apply_bottom_layout() -> void:
	_compute_bottom_metrics(3)
	var deck_vbox: VBoxContainer = playfield_deck.get_node("DeckMargin/DeckVBox")
	for node_name in ["BottomDeckArea", "BottomDeckRow"]:
		var stale: Node = deck_vbox.get_node_or_null(node_name)
		if stale:
			stale.queue_free()

	var boosters_panel: Node = _deck_panel(deck_vbox, "BoostersPanel")
	var docks_panel: Node = _deck_panel(deck_vbox, "DocksPanel")
	var stacks_panel: Node = _deck_panel(deck_vbox, "ColorStacksPanel")
	var funnel: Node = deck_vbox.get_node_or_null("FunnelZone")
	if boosters_panel == null or docks_panel == null or stacks_panel == null:
		push_error("LevelController: не найдены панели нижнего UI")
		return
	if funnel == null:
		push_error("LevelController: не найден FunnelZone")
		return

	var bottom_area := VBoxContainer.new()
	bottom_area.name = "BottomDeckArea"
	bottom_area.add_theme_constant_override("separation", 4)
	bottom_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_area.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var top_row := HBoxContainer.new()
	top_row.name = "BottomTopRow"
	top_row.add_theme_constant_override("separation", 6)
	top_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.size_flags_vertical = Control.SIZE_EXPAND_FILL

	if boosters_panel.get_parent() == deck_vbox:
		deck_vbox.remove_child(boosters_panel)
	var boosters_wrap := PanelContainer.new()
	boosters_wrap.name = "BoostersWrap"
	boosters_wrap.custom_minimum_size = Vector2(BOOSTERS_PANEL_W, 0)
	boosters_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	boosters_wrap.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	boosters_wrap.size_flags_stretch_ratio = 0.0
	boosters_wrap.z_index = 0
	boosters_wrap.add_theme_stylebox_override(
		"panel", GameTheme.bottom_section_panel(Color(0.85, 0.75, 0.35)))
	boosters_wrap.add_child(boosters_panel)
	boosters_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	boosters_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if boosters_box is Control:
		(boosters_box as Control).size_flags_vertical = Control.SIZE_EXPAND_FILL
	if boosters_box is BoxContainer:
		(boosters_box as BoxContainer).alignment = BoxContainer.ALIGNMENT_BEGIN

	if funnel.get_parent() == deck_vbox:
		deck_vbox.remove_child(funnel)
	funnel.custom_minimum_size = Vector2(0, 0)
	funnel.visible = false

	if docks_panel.get_parent() == deck_vbox:
		deck_vbox.remove_child(docks_panel)
	docks_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	docks_panel.size_flags_vertical = Control.SIZE_SHRINK_END

	if stacks_panel.get_parent() == deck_vbox:
		deck_vbox.remove_child(stacks_panel)
	stacks_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stacks_panel.size_flags_vertical = Control.SIZE_SHRINK_END

	var right_wrap := PanelContainer.new()
	right_wrap.name = "RightPanel"
	right_wrap.custom_minimum_size = Vector2(_right_col_width, 0)
	right_wrap.size_flags_horizontal = Control.SIZE_SHRINK_END
	right_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_wrap.size_flags_stretch_ratio = 0.0
	right_wrap.add_theme_stylebox_override(
		"panel", GameTheme.bottom_section_panel(Color(0.45, 0.78, 1.0)))

	_right_sidebar = VBoxContainer.new()
	_right_sidebar.name = "RightSidebar"
	_right_sidebar.add_theme_constant_override("separation", 8)
	_right_sidebar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_right_sidebar.size_flags_vertical = Control.SIZE_EXPAND_FILL

	_remainder_bar = VBoxContainer.new()
	_remainder_bar.name = "RemainderPanel"
	_remainder_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_remainder_bar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_remainder_bar.add_theme_constant_override("separation", 5)
	var rem_title := Label.new()
	rem_title.text = "НА КАРТЕ"
	rem_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_section_title(rem_title)
	rem_title.add_theme_font_size_override("font_size", 18)
	_remainder_bar.add_child(rem_title)
	var colors_box := VBoxContainer.new()
	colors_box.name = "FieldColorsBox"
	colors_box.alignment = BoxContainer.ALIGNMENT_CENTER
	colors_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	colors_box.add_theme_constant_override("separation", 5)
	_remainder_bar.add_child(colors_box)
	_field_colors_box = colors_box
	_right_sidebar.add_child(_remainder_bar)
	right_wrap.add_child(_right_sidebar)
	if is_instance_valid(color_count_bar):
		color_count_bar.visible = false

	var center_outer := VBoxContainer.new()
	center_outer.name = "BottomCenterOuter"
	center_outer.alignment = BoxContainer.ALIGNMENT_BEGIN
	center_outer.add_theme_constant_override("separation", 8)
	center_outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_outer.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var center_col := VBoxContainer.new()
	center_col.name = "BottomCenterColumn"
	center_col.alignment = BoxContainer.ALIGNMENT_BEGIN
	center_col.add_theme_constant_override("separation", 6)
	center_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_col.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	_fleet_center_wrap = PanelContainer.new()
	_fleet_center_wrap.name = "FleetCenterWrap"
	_fleet_center_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fleet_center_wrap.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_fleet_center_wrap.size_flags_stretch_ratio = 0.0
	_fleet_center_wrap.clip_contents = false
	_fleet_center_wrap.z_index = 0
	_fleet_center_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fleet_center_wrap.add_theme_stylebox_override(
		"panel", GameTheme.bottom_section_panel(Color(0.55, 0.48, 0.95)))

	var fleet_title := Label.new()
	fleet_title.text = "ФЛОТ"
	fleet_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_section_title(fleet_title)
	center_col.add_child(fleet_title)
	center_col.add_child(docks_panel)
	_fleet_center_wrap.add_child(center_col)
	center_outer.add_child(_fleet_center_wrap)

	var vending_wrap := PanelContainer.new()
	vending_wrap.name = "VendingWrap"
	vending_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vending_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vending_wrap.size_flags_stretch_ratio = 1.0
	vending_wrap.clip_contents = false
	vending_wrap.mouse_filter = Control.MOUSE_FILTER_PASS
	vending_wrap.add_theme_stylebox_override(
		"panel", GameTheme.bottom_section_panel(Color(0.42, 0.48, 0.62)))
	var vending_pad := MarginContainer.new()
	vending_pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vending_pad.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vending_pad.add_theme_constant_override("margin_top", 6)
	vending_pad.add_theme_constant_override("margin_bottom", 4)
	vending_pad.add_theme_constant_override("margin_left", 8)
	vending_pad.add_theme_constant_override("margin_right", 8)
	var vending_center := CenterContainer.new()
	vending_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vending_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stacks_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stacks_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	vending_center.add_child(stacks_panel)
	vending_pad.add_child(vending_center)
	vending_wrap.add_child(vending_pad)
	center_outer.add_child(vending_wrap)
	_vending_wrap = vending_wrap

	if is_instance_valid(status_label):
		status_label.visible = false

	var fleet_lift := MarginContainer.new()
	fleet_lift.name = "FleetColumnLift"
	fleet_lift.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fleet_lift.size_flags_vertical = Control.SIZE_EXPAND_FILL
	fleet_lift.size_flags_stretch_ratio = 1.0
	fleet_lift.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fleet_lift.add_child(center_outer)

	top_row.add_child(boosters_wrap)
	top_row.add_child(fleet_lift)
	top_row.add_child(right_wrap)

	bottom_area.add_child(top_row)

	deck_vbox.add_child(funnel)

	var footer_idx := deck_vbox.get_child_count() - 1
	deck_vbox.add_child(bottom_area)
	deck_vbox.move_child(bottom_area, footer_idx)
	_style_bottom_labels()


func _configure_deck_layout() -> void:
	canvas_frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	canvas_frame.size_flags_stretch_ratio = 0.0
	canvas_inner.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var frame_margin: Control = canvas_frame.get_node("FrameMargin")
	frame_margin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var grid_margin: Control = canvas_inner.get_node("GridMargin")
	grid_margin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var grid_center: Control = grid_margin.get_node("GridCenter")
	grid_center.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	footer_bar.size_flags_vertical = Control.SIZE_SHRINK_END
	footer_bar.custom_minimum_size.y = 112
	var deck_vbox: VBoxContainer = playfield_deck.get_node("DeckMargin/DeckVBox")
	deck_vbox.add_theme_constant_override("separation", 6)
	var bottom_area := deck_vbox.get_node_or_null("BottomDeckArea")
	if bottom_area is Control:
		var bottom_ctrl := bottom_area as Control
		bottom_ctrl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		bottom_ctrl.size_flags_stretch_ratio = 1.0
		bottom_ctrl.custom_minimum_size.y = GameBalance.BOTTOM_PANEL_MIN_H


func _playfield_budget() -> Vector2:
	var vp := get_viewport().get_visible_rect().size
	var side_margin := 36.0
	var top_reserve := 58.0
	var bottom_reserve := float(GameBalance.BOTTOM_PANEL_MIN_H) + 108.0
	return Vector2(
		minf(vp.x - side_margin, GameBalance.PLAYFIELD_MAX_WIDTH),
		maxf(vp.y - top_reserve - bottom_reserve, 320.0),
	)


func _compute_cell_size() -> int:
	if grid == null:
		return 22
	var budget := _playfield_budget()
	var sep := float(GRID_SEPARATION)
	var by_w := int((budget.x - sep * float(grid.width - 1)) / float(grid.width))
	var by_h := int((budget.y - sep * float(grid.height - 1)) / float(grid.height))
	return clampi(mini(by_w, by_h), GameBalance.GRID_CELL_MIN, GameBalance.GRID_CELL_MAX)


func _apply_bottom_panel_sizes() -> void:
	if is_instance_valid(_right_sidebar):
		var right_wrap_node := _right_sidebar.get_parent()
		if right_wrap_node is Control:
			(right_wrap_node as Control).custom_minimum_size.x = _right_col_width
	var boosters_wrap := get_node_or_null(
		"PlayfieldDeck/DeckMargin/DeckVBox/BottomDeckArea/BottomTopRow/BoostersWrap")
	if boosters_wrap is Control:
		(boosters_wrap as Control).custom_minimum_size.x = BOOSTERS_PANEL_W
	_update_fleet_panel_width()


func _start_level() -> void:
	if not GameState.can_play_level():
		_show_no_lives_overlay()
		return

	_reset_level_runtime()
	game_over = false
	elapsed_time = 0.0
	hint_color = -1
	hint_timer = 0.0
	win_loss_panel.visible = false
	next_button.visible = false
	buy_life_button.visible = false
	if is_instance_valid(menu_exit_button):
		menu_exit_button.visible = false

	level_config = GameBalance.get_level(GameState.current_sector, GameState.current_level_in_sector)
	grid = AsteroidGrid.new(level_config)
	color_vending = ColorVending.new()
	color_vending.setup_from_grid(
		grid,
		level_config.get("vending_columns", 5),
		GameState.global_level_id(),
		int(level_config.get("difficulty", GameBalance.LevelDifficulty.NORMAL)),
	)
	slot_vending_col.clear()
	slot_launch_points.clear()
	var launch: float = level_config.get("launch_interval", GameBalance.SHIP_LAUNCH_INTERVAL)
	if GameState.is_warp_active():
		launch /= GameBalance.WARP_CORE_SPEED_MULTIPLIER
	slot_manager = SlotManager.new(level_config.get("slot_count", GameBalance.DEFAULT_SLOT_COUNT), launch)
	_compute_bottom_metrics()
	_apply_bottom_panel_sizes()

	var theme := String(level_config.get("theme_name", ""))
	if theme.is_empty():
		_set_status("")
	else:
		_set_status(theme)
	_build_grid_ui()
	_build_storage_gauge()
	_build_slots_ui()
	_build_vending_ui()
	_build_color_count_bar()
	_lives_hud_timer = 0.0
	_refresh_hud()
	_refresh_all()
	AudioService.play_music(&"menu_music")


func _process(delta: float) -> void:
	GameState.tick_warp(delta)
	_update_warp_display()
	_lives_hud_timer -= delta
	if _lives_hud_timer <= 0.0:
		_lives_hud_timer = 1.0
		_update_lives_regen_display()
	if _status_clear_timer > 0.0:
		_status_clear_timer = maxf(_status_clear_timer - delta, 0.0)
		if _status_clear_timer <= 0.0:
			_status_message = ""
			_status_prominent = false
			_refresh_status_display()
	if hint_timer > 0.0:
		hint_timer = maxf(hint_timer - delta, 0.0)
		if hint_timer <= 0.0:
			hint_color = -1
			_refresh_color_counts()
	if game_over or _settings_open:
		return

	elapsed_time += delta
	var speed_mult := GameBalance.WARP_CORE_SPEED_MULTIPLIER if GameState.is_warp_active() else 1.0
	var events: Array = slot_manager.tick(delta * speed_mult, grid)

	for ev in events:
		if ev.get("launch", false):
			var col: int = int(slot_vending_col.get(ev["slot"], 0))
			_launch_ship(ev["slot"], ev["color"], ev["pos"], col, true)

	if not events.is_empty():
		if grid.should_unlock_next_color() and grid.try_unlock_next_color():
			AudioService.play_sfx(&"unlock")
			_set_status_unlock()
			color_vending.add_chip_for_color(
				grid, grid.unlocked_color_count - 1, GameState.global_level_id())
			_build_color_count_bar()
			_refresh_vending_reels()
			_refresh_all()
		_check_win_loss()
		_hud_refresh_timer = HUD_REFRESH_INTERVAL

	_hud_refresh_timer -= delta
	if _hud_refresh_timer <= 0.0:
		_hud_refresh_timer = HUD_REFRESH_INTERVAL
		_update_storage_gauge()
		_refresh_color_counts()
		if not game_over and _active_ship_tweens == 0:
			_check_win_loss()
		if hint_timer > 0.0:
			_hud_refresh_timer = 0.04


func _on_vending_column_pressed(col: int) -> void:
	if game_over:
		return
	var chip: Dictionary = color_vending.peek_top(col)
	if chip.is_empty():
		return
	var color: int = int(chip.get("color", -1))
	var quota: int = int(chip.get("launches", 0))
	if color < 0 or quota <= 0:
		return
	if grid.count_filled_of_color(color) == 0:
		return
	if not _vending_chip_usable(color):
		_set_status("Сначала откройте этот цвет снаружи", false, 1.6)
		return
	var result := slot_manager.assign_color(color, quota)
	if result == -1:
		_check_win_loss()
		return
	_refresh_slot_visual(result, true)
	call_deferred("_refresh_slot_visual", result, true)
	var from_pos := _vending_launch_point(col)
	var to_pos := _dock_point(result)
	slot_vending_col[result] = col
	slot_launch_points[result] = to_pos
	var stack_before := color_vending.get_column_stack(col).size()
	color_vending.pop_top(col)
	AudioService.play_sfx(&"tap")
	if ColorVending.should_scroll_after_pop(stack_before):
		_animate_vending_column_scroll(col)
	else:
		_refresh_vending_column(col)
	_animate_color_chip_to_slot(from_pos, to_pos, color, quota, result)


func _on_restart_pressed() -> void:
	AudioService.play_sfx(&"tap")
	if game_over:
		_do_restart_level()
		return
	_show_confirm(
		"Перезапуск уровня",
		"Начать уровень заново?\nПрогресс текущей попытки будет потерян.",
		_do_restart_level,
	)


func _do_restart_level() -> void:
	if not GameState.can_play_level():
		_show_no_lives_overlay()
		return
	_start_level()


func _on_menu_pressed() -> void:
	AudioService.play_sfx(&"tap")
	if game_over:
		_do_exit_to_menu()
		return
	_show_confirm(
		"Выход в меню",
		"Выйти в главное меню?\nПрогресс уровня не сохранится.",
		_do_exit_to_menu,
	)


func _do_exit_to_menu() -> void:
	SaveService.save_game()
	get_tree().change_scene_to_file("res://scenes/app/Main.tscn")


func _on_buy_life_pressed() -> void:
	AudioService.play_sfx(&"tap")
	if GameState.buy_life():
		_refresh_hud()
		if game_over:
			_start_level()
		else:
			_set_status("Жизнь восстановлена!")
	else:
		_set_status(GameTheme.coin_need_text(GameBalance.LIFE_REFILL_COST))


func _on_next_pressed() -> void:
	AudioService.play_sfx(&"tap")
	if GameState.global_level_id() <= GameBalance.get_max_level():
		get_tree().change_scene_to_file("res://scenes/gameplay/Level.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/app/Main.tscn")


func _on_warp_pressed() -> void:
	_on_booster_use("warp")


func _apply_launch_speed() -> void:
	var launch: float = level_config.get("launch_interval", GameBalance.SHIP_LAUNCH_INTERVAL)
	if GameState.is_warp_active():
		launch /= GameBalance.WARP_CORE_SPEED_MULTIPLIER
	slot_manager.launch_interval = launch


func _check_win_loss() -> void:
	if grid.is_board_clear():
		game_over = true
		GameState.complete_level(GameState.global_level_id())
		_show_win_loss(true)
		return
	if grid.try_unlock_if_stuck():
		AudioService.play_sfx(&"unlock")
		_set_status_unlock()
		color_vending.add_chip_for_color(
			grid, grid.unlocked_color_count - 1, GameState.global_level_id())
		_build_color_count_bar()
		_refresh_vending_reels()
		_refresh_all()
		return
	if not _has_available_moves():
		game_over = true
		GameState.lose_life()
		_show_win_loss(false)


func _show_no_lives_overlay() -> void:
	game_over = true
	_set_gameplay_fx_visible(false)
	win_loss_title.text = "Нет жизней"
	win_loss_label.text = "Купите продолжение\nили вернитесь в меню."
	next_button.visible = false
	buy_life_button.visible = true
	GameTheme.apply_button_coin(buy_life_button, GameBalance.LIFE_REFILL_COST, "  Продолжить")
	if is_instance_valid(menu_exit_button):
		menu_exit_button.visible = true
	win_loss_panel.visible = true
	_refresh_hud()


func _show_win_loss(is_win: bool) -> void:
	_set_gameplay_fx_visible(false)
	if is_win and not _win_progress_applied:
		_win_progress_applied = true
		GameState.advance_to_next_level()
		SaveService.save_game()
	if is_win:
		win_loss_title.text = "Уровень пройден!"
		win_loss_label.text = "%s\nПоследний пиксель уничтожен." % GameTheme.coin_gain_text(level_config.reward)
		win_loss_label.add_theme_color_override("font_color", Color(0.42, 0.22, 0.10))
		win_loss_label.add_theme_font_size_override("font_size", 30)
		next_button.visible = GameState.global_level_id() < GameBalance.get_max_level()
		buy_life_button.visible = false
		if is_instance_valid(menu_exit_button):
			menu_exit_button.visible = true
		AudioService.play_sfx(&"win")
	else:
		win_loss_title.text = "Тупик!"
		win_loss_label.add_theme_color_override("font_color", Color(0.38, 0.20, 0.12))
		win_loss_label.add_theme_font_size_override("font_size", 28)
		var lives_left := GameState.lives
		if lives_left > 0:
			win_loss_label.text = "Нет доступных ходов.\nОсталось жизней: %d" % lives_left
			buy_life_button.visible = false
		else:
			win_loss_label.text = "Жизни закончились.\nКупите продолжение или выйдите в меню."
			buy_life_button.visible = true
			GameTheme.apply_button_coin(buy_life_button, GameBalance.LIFE_REFILL_COST, "  Продолжить")
		next_button.visible = false
		if is_instance_valid(menu_exit_button):
			menu_exit_button.visible = true
		AudioService.play_sfx(&"lose")
	win_loss_panel.visible = true
	_refresh_vending_reels()
	_refresh_hud()



func _refresh_hud() -> void:
	_update_lives_regen_display()
	if is_instance_valid(level_title):
		level_title.text = GameState.level_compact_label()
	_update_difficulty_badge()
	if is_instance_valid(credits_label):
		credits_label.text = str(GameState.credits)
	_update_storage_gauge()
	_update_warp_display()
	_update_booster_badges()
	_refresh_color_counts()


func _update_lives_regen_display() -> void:
	GameState.tick_lives_regen()
	if is_instance_valid(lives_label):
		lives_label.text = "%d/%d" % [GameState.lives, GameBalance.LIVES_MAX]
	if is_instance_valid(_lives_plus_btn):
		_lives_plus_btn.disabled = GameState.lives >= GameBalance.LIVES_MAX
	if not is_instance_valid(lives_timer_label):
		return
	if GameState.lives >= GameBalance.LIVES_MAX:
		lives_timer_label.text = ""
		lives_timer_label.visible = false
		return
	var timer_text := GameState.lives_timer_text()
	if timer_text != "":
		lives_timer_label.text = "+1 через %s" % timer_text
	else:
		lives_timer_label.text = "+1 скоро"
	lives_timer_label.visible = true


func _on_hud_lives_plus_pressed() -> void:
	AudioService.play_sfx(&"tap")
	if not is_instance_valid(_resource_modal):
		return
	_resource_modal.open_life()
	if is_instance_valid(_resource_modal_layer):
		_resource_modal_layer.layer = 91


func _on_hud_credits_plus_pressed() -> void:
	AudioService.play_sfx(&"tap")
	if not is_instance_valid(_resource_modal):
		return
	_resource_modal.open_credits()
	if is_instance_valid(_resource_modal_layer):
		_resource_modal_layer.layer = 91


func _update_warp_display() -> void:
	_refresh_status_display()


func _cell_center(pos: Vector2i) -> Vector2:
	if cell_panels.has(pos):
		return cell_panels[pos].get_global_rect().get_center()
	return Vector2.ZERO


func _ui_center_global(control: Control) -> Vector2:
	if not is_instance_valid(control):
		return Vector2.ZERO
	return control.get_global_transform_with_canvas() * (control.size * 0.5)


func _ui_center_to_effects(control: Control) -> Vector2:
	if not is_instance_valid(effects_layer):
		return _ui_center_global(control)
	var center := _ui_center_global(control)
	return effects_layer.get_global_transform_with_canvas().affine_inverse() * center


func _effects_flight_parent() -> Node:
	if is_instance_valid(_effects_ui):
		return _effects_ui
	return effects_layer


func _effects_local_to_global(local_pos: Vector2) -> Vector2:
	if not is_instance_valid(effects_layer):
		return local_pos
	return effects_layer.to_global(local_pos)


func _update_fleet_panel_width() -> void:
	if not is_instance_valid(_fleet_center_wrap):
		return
	var vending_cols := ColorVending.GRID_WIDTH
	var gap := 8
	var content_w := vending_cols * _vending_cell_size + (vending_cols - 1) * gap + 24
	_fleet_center_wrap.custom_minimum_size = Vector2(content_w, 0)
	if is_instance_valid(_vending_wrap):
		var max_rows := 0
		if color_vending != null:
			for col_idx in range(color_vending.column_count()):
				max_rows = maxi(
					max_rows,
					ColorVending.visible_row_count(color_vending.get_column_stack(col_idx).size()),
				)
		var vending_h := _vending_cell_size * max_rows + 28 if max_rows > 0 else 0
		_vending_wrap.custom_minimum_size = Vector2(content_w, vending_h)


func _animate_color_chip_to_slot(
	from_pos: Vector2, to_pos: Vector2, color_idx: int, quota: int, slot_idx: int,
) -> void:
	var fly_seconds := VisualFxService.chip_flight_seconds()
	if fly_seconds <= 0.0:
		_on_color_chip_arrived(slot_idx)
		return

	var session := _level_session_id
	var mineral := _mineral_color(color_idx)
	var chip_size := Vector2(float(_vending_cell_size) * 0.92, float(_vending_cell_size) * 0.92)
	var from_global := effects_layer.to_global(from_pos)
	var to_global := effects_layer.to_global(to_pos)

	if is_instance_valid(_effects_ui):
		var chip := PanelContainer.new()
		chip.custom_minimum_size = chip_size
		chip.size = chip_size
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.z_index = 30
		chip.pivot_offset = chip_size * 0.5
		chip.add_theme_stylebox_override("panel", GameTheme.remainder_chip_tile(mineral))
		var quota_lbl := Label.new()
		quota_lbl.text = str(quota)
		quota_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		quota_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		quota_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		quota_lbl.add_theme_font_size_override("font_size", maxi(int(chip_size.x * 0.42), 22))
		quota_lbl.add_theme_color_override("font_color", _mineral_text_color(color_idx))
		quota_lbl.add_theme_color_override("font_outline_color", GameTheme.mineral_chip_outline_color(color_idx))
		quota_lbl.add_theme_constant_override("outline_size", 4)
		quota_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_child(quota_lbl)
		_effects_ui.add_child(chip)
		chip.global_position = from_global - chip_size * 0.5
		var fly_dir := to_global - from_global
		if fly_dir.length_squared() > 1.0:
			chip.rotation = fly_dir.angle()
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(chip, "global_position", to_global - chip_size * 0.5, fly_seconds)
		tween.parallel().tween_property(chip, "scale", Vector2(0.78, 0.78), fly_seconds)
		tween.tween_callback(func() -> void:
			if session != _level_session_id:
				if is_instance_valid(chip):
					chip.queue_free()
				return
			_spawn_burst(to_global, mineral)
			chip.queue_free()
			_on_color_chip_arrived(slot_idx)
		)
		return

	var chip2d := Node2D.new()
	chip2d.z_index = 10
	var half := chip_size.x * 0.5
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half),
	])
	body.color = mineral.darkened(0.06)
	chip2d.add_child(body)
	var frame := Line2D.new()
	frame.points = PackedVector2Array([
		Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half), Vector2(-half, -half),
	])
	frame.width = 3.5
	frame.default_color = mineral.lightened(0.45)
	chip2d.add_child(frame)
	effects_layer.add_child(chip2d)
	chip2d.position = from_pos
	var fly_dir2 := to_pos - from_pos
	if fly_dir2.length_squared() > 1.0:
		chip2d.rotation = fly_dir2.angle()
	var tween2 := create_tween()
	tween2.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween2.tween_property(chip2d, "position", to_pos, fly_seconds)
	tween2.parallel().tween_property(chip2d, "scale", Vector2(0.72, 0.72), fly_seconds)
	tween2.tween_callback(func() -> void:
		if session != _level_session_id:
			if is_instance_valid(chip2d):
				chip2d.queue_free()
			return
		_spawn_burst(effects_layer.to_global(to_pos), mineral)
		chip2d.queue_free()
		_on_color_chip_arrived(slot_idx)
	)


func _on_color_chip_arrived(slot_idx: int) -> void:
	_refresh_slot_visual(slot_idx, true)


func _set_slot_fill(
	fill: ColorRect, ratio: float, color: Color, instant: bool, duration: float = 0.34
) -> void:
	if not is_instance_valid(fill):
		return
	var target_top := _dock_capsule_h * (1.0 - clampf(ratio, 0.0, 1.0))
	fill.color = color
	fill.visible = ratio > 0.01
	var anim_duration := duration if duration > 0.0 else VisualFxService.slot_fill_seconds(false)
	if instant or anim_duration <= 0.0:
		fill.offset_top = target_top
		return
	var tween := fill.create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(fill, "offset_top", target_top, anim_duration)


func _clear_slot_fill(fill: ColorRect, instant: bool) -> void:
	if not is_instance_valid(fill):
		return
	var duration := VisualFxService.slot_fill_seconds(false)
	if instant or duration <= 0.0:
		fill.offset_top = _dock_capsule_h
		fill.visible = false
		return
	var tween := fill.create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(fill, "offset_top", _dock_capsule_h, duration)
	tween.tween_callback(func() -> void:
		if is_instance_valid(fill):
			fill.visible = false
	)


func _refresh_slot_visual(slot_idx: int, fill_from_empty: bool = false) -> void:
	if slot_idx < 0 or slot_idx >= dock_capsules.size() or slot_manager == null:
		return
	var icon: DockShipIcon = dock_ship_icons[slot_idx]
	var count_lbl: Label = dock_slot_counts[slot_idx]
	var bar: BunkerFillGauge = dock_slot_bars[slot_idx]
	var label: Label = dock_labels[slot_idx]
	var capsule: PanelContainer = dock_capsules[slot_idx]
	if not is_instance_valid(capsule):
		return
	var fill: ColorRect = dock_slot_fills[slot_idx] if slot_idx < dock_slot_fills.size() else null
	capsule.custom_minimum_size = Vector2(_dock_capsule_w, _dock_capsule_h)
	capsule.size = capsule.custom_minimum_size

	if not slot_manager.is_slot_unlocked(slot_idx):
		capsule.add_theme_stylebox_override("panel", GameTheme.dock_capsule(DOCK_FREE_COLOR))
		icon.visible = false
		count_lbl.visible = false
		bar.visible = false
		if is_instance_valid(fill):
			_clear_slot_fill(fill, true)
		var lock_lbl: Label = dock_lock_labels[slot_idx]
		lock_lbl.visible = true
		label.text = ""
		capsule.modulate = Color(0.72, 0.74, 0.82, 0.95)
		return

	capsule.modulate = Color.WHITE
	dock_lock_labels[slot_idx].visible = false
	var s = slot_manager.get_slot(slot_idx)
	if s.active:
		var col := _mineral_color(s.color)
		capsule.add_theme_stylebox_override("panel", GameTheme.dock_capsule(col, true))
		var initial: int = maxi(int(s.initial_quota), 1)
		var ratio := float(s.launch_quota) / float(initial)
		icon.set_color(col)
		icon.visible = false
		count_lbl.visible = true
		count_lbl.text = str(s.launch_quota)
		count_lbl.add_theme_color_override("font_color", _mineral_text_color(s.color))
		count_lbl.add_theme_color_override("font_outline_color", GameTheme.mineral_chip_outline_color(s.color))
		count_lbl.add_theme_constant_override(
			"outline_size", 5 if GameTheme.mineral_color_is_light(s.color) else 3)
		bar.visible = false
		label.text = ""
		label.visible = false
		if is_instance_valid(fill):
			_set_slot_fill(
				fill,
				ratio,
				col,
				fill_from_empty,
				VisualFxService.slot_fill_seconds(fill_from_empty),
			)
	else:
		capsule.add_theme_stylebox_override("panel", GameTheme.dock_capsule_empty())
		icon.visible = false
		count_lbl.visible = false
		bar.visible = false
		label.text = ""
		label.visible = false
		if is_instance_valid(fill):
			_clear_slot_fill(fill, true)


func _dock_point(slot_idx: int) -> Vector2:
	if slot_idx >= 0 and slot_idx < dock_capsules.size():
		var cap: Control = dock_capsules[slot_idx]
		if is_instance_valid(cap):
			return _ui_center_to_effects(cap)
	return _bunker_point()


func _flight_hub_global() -> Vector2:
	var grid_rect := grid_container.get_global_rect()
	return Vector2(grid_rect.position.x + grid_rect.size.x * 0.5, grid_rect.end.y + 10.0)


func _flight_hub_point() -> Vector2:
	if not is_instance_valid(effects_layer):
		return _flight_hub_global()
	return effects_layer.get_global_transform_with_canvas().affine_inverse() * _flight_hub_global()


func _segment_durations(from: Vector2, via: Vector2, to: Vector2, total_seconds: float) -> Vector2:
	var leg_a := from.distance_to(via)
	var leg_b := via.distance_to(to)
	var sum := leg_a + leg_b
	if sum < 1.0:
		return Vector2(total_seconds * 0.5, total_seconds * 0.5)
	return Vector2(total_seconds * (leg_a / sum), total_seconds * (leg_b / sum))


func _tween_linear_segment(
	tween: Tween, ship: MiningShipVisual, from: Vector2, to: Vector2, duration: float,
) -> void:
	var dir := to - from
	tween.tween_callback(func() -> void:
		if not is_instance_valid(ship):
			return
		ship.global_position = from
		if dir.length_squared() > 0.01:
			ship.set_facing_direction(dir)
	)
	tween.tween_property(ship, "global_position", to, duration)


func _has_available_moves() -> bool:
	if grid == null or grid.is_board_clear():
		return false
	for c in range(grid.total_color_count):
		if slot_manager.get_ships_in_flight(c) > 0:
			return true
	for i in range(slot_manager.unlocked_slots):
		var s = slot_manager.get_slot(i)
		if s.active and not s.blocked and grid.count_filled_of_color(s.color) > 0:
			return true
	if slot_manager.free_count() > 0:
		for col in range(color_vending.column_count()):
			var chip: Dictionary = color_vending.peek_top(col)
			if chip.is_empty():
				continue
			var c: int = int(chip.get("color", -1))
			if c < 0:
				continue
			if grid.count_filled_of_color(c) <= 0:
				continue
			return true
	return false


func _flight_speed_mult() -> float:
	return GameBalance.WARP_CORE_SPEED_MULTIPLIER if GameState.is_warp_active() else 1.0


func _bunker_point_global() -> Vector2:
	if is_instance_valid(_storage_bar):
		return _ui_center_global(_storage_bar)
	if is_instance_valid(_right_sidebar):
		return _ui_center_global(_right_sidebar)
	return _ui_center_global(funnel_zone)


func _bunker_point() -> Vector2:
	if not is_instance_valid(effects_layer):
		return _bunker_point_global()
	return effects_layer.get_global_transform_with_canvas().affine_inverse() * _bunker_point_global()


func _vending_launch_point(col: int) -> Vector2:
	var btn: Control = vending_column_tops.get(col)
	if is_instance_valid(btn):
		return _ui_center_to_effects(btn)
	return _dock_point(0)


func _launch_ship(
	slot_idx: int, color_idx: int, target: Vector2i, vending_col: int, already_reserved: bool,
) -> void:
	if slot_manager.get_ships_in_flight(color_idx) >= GameBalance.MAX_SHIPS_PER_COLOR:
		if already_reserved:
			grid.unreserve_cell(target)
			slot_manager.cancel_launch(slot_idx)
		return
	if not already_reserved and not grid.reserve_cell(target):
		return

	slot_manager.on_ship_launched(slot_idx, color_idx)
	_active_ship_tweens += 1
	_refresh_slot_visual(slot_idx, false)

	var color := _mineral_color(color_idx)
	var ship := MiningShipVisual.new(color)
	ship.visible = false
	ship.z_index = 12
	ship.set_lite_mode(_active_ship_tweens >= VisualFxService.ship_trail_lite_threshold())
	var from_local: Vector2 = slot_launch_points.get(slot_idx, _dock_point(slot_idx))
	ship.global_position = _effects_local_to_global(from_local)
	_effects_flight_parent().add_child(ship)
	ship.scale = Vector2(1.55, 1.55)
	_run_ship_flight(ship, slot_idx, color_idx, target, color, vending_col)


func _run_ship_flight(
	ship: MiningShipVisual,
	slot_idx: int,
	color_idx: int,
	target: Vector2i,
	color: Color,
	vending_col: int,
) -> void:
	var session := _level_session_id
	await get_tree().process_frame
	if session != _level_session_id or not is_instance_valid(ship):
		if is_instance_valid(ship):
			ship.queue_free()
		return

	var from_local: Vector2 = slot_launch_points.get(slot_idx, _dock_point(slot_idx))
	var from_pos := _effects_local_to_global(from_local)
	var target_pos := (
		_ui_center_global(cell_panels[target] as Control)
		if cell_panels.has(target)
		else _cell_center(target)
	)
	var hub_pos := _flight_hub_global()
	var bunker_pos := _bunker_point_global()
	ship.global_position = from_pos
	ship.visible = true
	ship.set_facing_direction(hub_pos - from_pos)
	ship.set_engine_active(true)

	var to_mineral := GameBalance.SHIP_TO_MINERAL_SECONDS / _flight_speed_mult()
	var to_bunker := GameBalance.SHIP_TO_BUNKER_SECONDS / _flight_speed_mult()
	var out_legs := _segment_durations(from_pos, hub_pos, target_pos, to_mineral)
	var back_legs := _segment_durations(target_pos, hub_pos, bunker_pos, to_bunker)

	var tween := create_tween()
	_tween_linear_segment(tween, ship, from_pos, hub_pos, out_legs.x)
	_tween_linear_segment(tween, ship, hub_pos, target_pos, out_legs.y)
	tween.tween_callback(func() -> void:
		if session != _level_session_id or not is_instance_valid(ship):
			if is_instance_valid(ship):
				ship.queue_free()
			return
		ship.set_facing_direction(hub_pos - target_pos)
		grid.eat_cell(target)
		_spawn_burst(_cell_center(target), color)
		AudioService.play_sfx(&"mine")
		ship.set_cargo_visible(true)
		_refresh_after_eat(target)
		var post_events := slot_manager.on_mineral_collected(slot_idx, grid)
		for pe in post_events:
			if pe.has("freed"):
				slot_vending_col.erase(pe["slot"])
				slot_launch_points.erase(pe["slot"])
				_refresh_vending_reels()
				AudioService.play_sfx(&"tap")
		if grid.should_unlock_next_color() and grid.try_unlock_next_color():
			AudioService.play_sfx(&"unlock")
			_set_status_unlock()
			color_vending.add_chip_for_color(
				grid, grid.unlocked_color_count - 1, GameState.global_level_id())
			_build_color_count_bar()
			_refresh_vending_reels()
			_refresh_all()
		elif grid.try_unlock_if_stuck():
			AudioService.play_sfx(&"unlock")
			_set_status_unlock()
			color_vending.add_chip_for_color(
				grid, grid.unlocked_color_count - 1, GameState.global_level_id())
			_build_color_count_bar()
			_refresh_vending_reels()
			_refresh_all()
		_update_slot_visuals()
		_check_win_loss()
	)
	_tween_linear_segment(tween, ship, target_pos, hub_pos, back_legs.x)
	_tween_linear_segment(tween, ship, hub_pos, bunker_pos, back_legs.y)
	tween.tween_callback(func() -> void:
		if session != _level_session_id or not is_instance_valid(ship):
			if is_instance_valid(ship):
				ship.queue_free()
			return
		ship.set_engine_active(false)
		ship.set_facing_direction(bunker_pos - ship.global_position)
		var return_events := slot_manager.on_ship_returned(slot_idx, color_idx, grid)
		for re in return_events:
			if re.has("freed"):
				slot_vending_col.erase(re["slot"])
				slot_launch_points.erase(re["slot"])
				_refresh_vending_reels()
				AudioService.play_sfx(&"tap")
		_update_slot_visuals()
		_check_win_loss()
	)
	var fade_seconds := VisualFxService.ship_fade_seconds()
	if fade_seconds > 0.0:
		tween.tween_property(ship, "scale", Vector2(0.25, 0.25), fade_seconds)
		tween.parallel().tween_property(ship, "modulate:a", 0.0, fade_seconds)
	tween.tween_callback(func() -> void:
		_active_ship_tweens = maxi(_active_ship_tweens - 1, 0)
		if is_instance_valid(ship):
			ship.visible = false
			ship.queue_free()
	)


func _spawn_burst(global_pos: Vector2, color: Color) -> void:
	if not VisualFxService.particles_enabled():
		return
	var amount := VisualFxService.burst_amount()
	if amount <= 0:
		return
	var p := CPUParticles2D.new()
	p.position = effects_layer.to_local(global_pos)
	p.one_shot = true
	p.amount = amount
	p.lifetime = GameBalance.MINE_BURST_LIFETIME_SECONDS
	p.explosiveness = 1.0
	p.spread = 180.0
	p.gravity = Vector2.ZERO
	p.color = color
	effects_layer.add_child(p)
	p.emitting = true
	get_tree().create_timer(0.5).timeout.connect(p.queue_free)


func _build_grid_ui() -> void:
	for child in grid_container.get_children():
		child.queue_free()
	cell_panels.clear()
	grid_container.columns = grid.width
	_cell_size = _compute_cell_size()
	grid_container.add_theme_constant_override("h_separation", GRID_SEPARATION)
	grid_container.add_theme_constant_override("v_separation", GRID_SEPARATION)
	for y in range(grid.height):
		for x in range(grid.width):
			var panel := EmptyCellPanel.new()
			panel.custom_minimum_size = Vector2(_cell_size, _cell_size)
			panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			grid_container.add_child(panel)
			var pos := Vector2i(x, y)
			cell_panels[pos] = panel
	var gw := grid.width * _cell_size + (grid.width - 1) * GRID_SEPARATION
	var gh := grid.height * _cell_size + (grid.height - 1) * GRID_SEPARATION
	grid_container.custom_minimum_size = Vector2(gw, gh)
	grid_container.size = Vector2(gw, gh)
	canvas_inner.custom_minimum_size = Vector2(gw + 20, gh + 20)
	canvas_inner.size = canvas_inner.custom_minimum_size
	_configure_deck_layout()


func _build_storage_gauge() -> void:
	if not is_instance_valid(_right_sidebar):
		return

	var header: VBoxContainer = _right_sidebar.get_node_or_null("StorageHeader") as VBoxContainer
	if header == null:
		header = VBoxContainer.new()
		header.name = "StorageHeader"
		header.alignment = BoxContainer.ALIGNMENT_CENTER
		header.add_theme_constant_override("separation", 6)
		var storage_title := Label.new()
		storage_title.text = "СКЛАД"
		storage_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_style_section_title(storage_title)
		header.add_child(storage_title)
		_right_sidebar.add_child(header)
		_right_sidebar.move_child(header, 0)

	for child in _right_sidebar.get_children():
		if child.name == "StorageHeader" and child != header:
			_right_sidebar.remove_child(child)
			child.free()

	if not is_instance_valid(_storage_bar) or _storage_bar.get_parent() != header:
		if is_instance_valid(_storage_bar):
			_storage_bar.queue_free()
		_storage_bar = BunkerFillGauge.new()
		_storage_bar.custom_minimum_size = Vector2(_remainder_col_width, 22)
		_storage_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header.add_child(_storage_bar)
	else:
		_storage_bar.custom_minimum_size = Vector2(_remainder_col_width, 22)

	var sep: Node = _right_sidebar.get_node_or_null("StorageSeparator")
	if sep == null:
		sep = HSeparator.new()
		sep.name = "StorageSeparator"
		(sep as HSeparator).modulate = Color(0.45, 0.58, 0.92, 0.45)
		_right_sidebar.add_child(sep)
		_right_sidebar.move_child(sep, 1)

	for child in _right_sidebar.get_children():
		if child.name == "StorageSeparator" and child != sep:
			_right_sidebar.remove_child(child)
			child.free()

	if is_instance_valid(docks_box):
		docks_box.alignment = BoxContainer.ALIGNMENT_CENTER
		docks_box.add_theme_constant_override("separation", 4)

	_update_storage_gauge()


func _update_storage_gauge() -> void:
	if grid == null:
		return
	var total := maxi(grid.initial_pixel_count, 1)
	var current := grid.count_collectibles_eaten()
	var accent := Color(0.35, 0.78, 1.0)
	if is_instance_valid(_storage_bar):
		_storage_bar.set_progress(current, total, accent)


func _build_slots_ui() -> void:
	if not is_instance_valid(docks_box):
		return
	for child in docks_box.get_children():
		child.queue_free()
	dock_ship_icons.clear()
	dock_slot_counts.clear()
	dock_slot_bars.clear()
	dock_lock_labels.clear()
	dock_labels.clear()
	dock_capsules.clear()
	dock_slot_fills.clear()
	var stack_side := _dock_capsule_w - 8
	var count_font := maxi(int(stack_side * 0.56), 18)
	for i in range(GameBalance.MAX_FLEET_SLOTS):
		var capsule := PanelContainer.new()
		capsule.custom_minimum_size = Vector2(_dock_capsule_w, _dock_capsule_h)
		capsule.size = capsule.custom_minimum_size
		capsule.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		capsule.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		capsule.add_theme_stylebox_override("panel", GameTheme.dock_capsule_empty())

		var fill := ColorRect.new()
		fill.name = "SlotFill"
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fill.z_index = -1
		fill.visible = false
		fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fill.offset_top = _dock_capsule_h
		capsule.add_child(fill)

		var lock_lbl := Label.new()
		lock_lbl.text = "🔒"
		lock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lock_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		lock_lbl.add_theme_font_size_override("font_size", maxi(int(_dock_capsule_w * 0.52), 26))
		lock_lbl.add_theme_color_override("font_color", Color(0.98, 0.82, 0.28))
		lock_lbl.add_theme_color_override("font_outline_color", Color(0.12, 0.10, 0.22, 0.95))
		lock_lbl.add_theme_constant_override("outline_size", 5)
		lock_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lock_lbl.visible = false
		capsule.add_child(lock_lbl)

		var col := MarginContainer.new()
		col.z_index = 1
		col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		col.add_theme_constant_override("margin_left", 4)
		col.add_theme_constant_override("margin_right", 4)
		col.add_theme_constant_override("margin_top", 4)
		col.add_theme_constant_override("margin_bottom", 4)
		var col_box := VBoxContainer.new()
		col_box.alignment = BoxContainer.ALIGNMENT_CENTER
		col_box.add_theme_constant_override("separation", 2)

		var slot_stack := Control.new()
		slot_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
		slot_stack.custom_minimum_size = Vector2(stack_side, stack_side)

		var count_lbl := Label.new()
		count_lbl.name = "SlotCount"
		count_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		count_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		count_lbl.add_theme_font_size_override("font_size", count_font)
		count_lbl.add_theme_color_override("font_color", Color.WHITE)
		count_lbl.add_theme_color_override("font_outline_color", Color(0.06, 0.08, 0.16, 0.95))
		count_lbl.add_theme_constant_override("outline_size", 5)
		count_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		count_lbl.visible = false
		slot_stack.add_child(count_lbl)

		var icon_wrap := CenterContainer.new()
		icon_wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icon := DockShipIcon.new()
		icon.custom_minimum_size = Vector2(_dock_icon_size, _dock_icon_size)
		icon.size = icon.custom_minimum_size
		icon_wrap.add_child(icon)
		slot_stack.add_child(icon_wrap)

		var bar := BunkerFillGauge.new()
		bar.custom_minimum_size = Vector2(stack_side, 5)
		bar.size = bar.custom_minimum_size
		bar.modulate = Color(1, 1, 1, 0)
		bar.visible = false

		var label := Label.new()
		label.visible = false
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		col_box.add_child(slot_stack)
		col_box.add_child(bar)
		col_box.add_child(label)
		col.add_child(col_box)
		capsule.add_child(col)
		docks_box.add_child(capsule)
		dock_capsules.append(capsule)
		dock_slot_fills.append(fill)
		dock_ship_icons.append(icon)
		dock_slot_counts.append(count_lbl)
		dock_slot_bars.append(bar)
		dock_lock_labels.append(lock_lbl)
		dock_labels.append(label)
	_update_slot_visuals()


func _add_lock_overlay(parent: Control, size: int) -> void:
	var lock := Label.new()
	lock.text = "🔒"
	lock.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lock.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lock.add_theme_font_size_override("font_size", maxi(int(size * 0.46), 22))
	lock.modulate = Color(1, 1, 1, 0.78)
	lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(lock)


func _make_color_square(
	text: String, color_idx: int, locked: bool, clickable: bool, size: int = 64,
	remainder_style: bool = false,
) -> Control:
	var mineral_color: Color = _mineral_color(color_idx)
	var label_color := _mineral_text_color(color_idx)
	var outline_color := GameTheme.mineral_chip_outline_color(color_idx)
	var normal_style: StyleBoxFlat = (
		GameTheme.remainder_chip_tile(mineral_color)
		if remainder_style
		else (
			GameTheme.vending_color_locked(mineral_color)
			if locked
			else GameTheme.color_square_tile(mineral_color, false)
		)
	)
	if clickable:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(size, size)
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_stylebox_override("normal", normal_style)
		btn.add_theme_stylebox_override("hover", GameTheme.color_square_tile(
			mineral_color.lightened(0.08), locked))
		btn.add_theme_stylebox_override("pressed", GameTheme.color_square_tile(
			mineral_color.darkened(0.08), locked))
		btn.add_theme_stylebox_override("disabled", normal_style)
		btn.add_theme_font_size_override("font_size", maxi(int(size * 0.42), 22))
		btn.add_theme_color_override("font_color", label_color)
		btn.add_theme_color_override("font_outline_color", outline_color)
		btn.add_theme_constant_override("outline_size", 2 if color_idx == 6 else 3)
		btn.text = "" if locked else text
		btn.disabled = locked
		if locked:
			btn.modulate = Color(1, 1, 1, 0.82)
			_add_lock_overlay(btn, size)
		else:
			btn.text = text
		return btn
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(size, size)
	panel.add_theme_stylebox_override("panel", normal_style)
	if locked:
		panel.modulate = Color(1, 1, 1, 0.82)
		_add_lock_overlay(panel, size)
	else:
		var lbl := Label.new()
		lbl.text = text
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		lbl.add_theme_font_size_override("font_size", maxi(int(size * 0.44), 20))
		lbl.add_theme_color_override("font_color", label_color)
		lbl.add_theme_color_override("font_outline_color", outline_color)
		lbl.add_theme_constant_override("outline_size", 2 if color_idx == 6 else 3)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(lbl)
	return panel


func _vending_chip_usable(color_idx: int) -> bool:
	if grid == null:
		return false
	if not grid.is_color_unlocked(color_idx):
		return false
	if grid.count_filled_of_color(color_idx) <= 0:
		return false
	return grid.has_collectible_of_color(color_idx)


func _make_vending_chip(
	launches: int, color_idx: int, is_top: bool, col_idx: int, row_from_top: int,
) -> Control:
	var size := _vending_cell_size
	if is_top:
		var usable := _vending_chip_usable(color_idx)
		var btn := _make_color_square(str(launches), color_idx, false, true, size) as Button
		btn.disabled = game_over or not usable
		if not usable:
			btn.modulate = Color(0.55, 0.58, 0.65, 0.72)
		btn.pressed.connect(_on_vending_column_pressed.bind(col_idx))
		return btn
	var preview := _make_color_square(str(launches), color_idx, false, false, size)
	var alpha := 0.78 if row_from_top == 1 else 0.55
	preview.modulate = Color(1, 1, 1, alpha)
	return preview


func _sync_vending_column_top(col: int) -> void:
	if col < 0 or col >= _vending_reels.size():
		return
	var reel: ColorVendingReel = _vending_reels[col]
	var top := reel.get_top_button()
	if is_instance_valid(top):
		vending_column_tops[col] = top
	else:
		vending_column_tops.erase(col)


func _refresh_vending_column(col: int) -> void:
	if col < 0 or col >= _vending_reels.size():
		return
	var reel: ColorVendingReel = _vending_reels[col]
	reel.set_game_over(game_over)
	reel.refresh_stack(color_vending.get_column_stack(col), true)
	_sync_vending_column_top(col)


func _refresh_vending_reels(instant: bool = true) -> void:
	if _vending_reels.is_empty():
		_build_vending_ui()
		return
	for col_idx in range(_vending_reels.size()):
		var reel: ColorVendingReel = _vending_reels[col_idx]
		reel.set_game_over(game_over)
		reel.refresh_stack(color_vending.get_column_stack(col_idx), instant)
		_sync_vending_column_top(col_idx)
	_update_fleet_panel_width()


func _animate_vending_column_scroll(col: int) -> void:
	if col < 0 or col >= _vending_reels.size():
		_refresh_vending_reels()
		return
	var reel: ColorVendingReel = _vending_reels[col]
	reel.animate_scroll_after_pop(
		color_vending.get_column_stack(col),
		VisualFxService.vending_scroll_seconds(),
	)


func _build_vending_ui() -> void:
	if not is_instance_valid(color_stacks_box) or color_vending == null:
		return
	for child in color_stacks_box.get_children():
		child.queue_free()
	_vending_reels.clear()
	vending_column_tops.clear()

	var row_box := HBoxContainer.new()
	row_box.alignment = BoxContainer.ALIGNMENT_CENTER
	row_box.add_theme_constant_override("separation", 6)
	var stack_root := VBoxContainer.new()
	stack_root.alignment = BoxContainer.ALIGNMENT_CENTER
	stack_root.add_theme_constant_override("separation", 4)
	stack_root.add_child(row_box)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.add_child(stack_root)
	color_stacks_box.add_child(center)

	for col_idx in range(ColorVending.GRID_WIDTH):
		var reel := ColorVendingReel.new()
		reel.configure(
			col_idx,
			_vending_cell_size,
			4,
			Callable(self, "_make_vending_chip"),
			Callable(),
		)
		reel.stack_refreshed.connect(_sync_vending_column_top)
		reel.set_game_over(game_over)
		reel.refresh_stack(color_vending.get_column_stack(col_idx), true)
		_sync_vending_column_top(col_idx)
		row_box.add_child(reel)
		_vending_reels.append(reel)

	_update_fleet_panel_width()
	if is_instance_valid(color_stacks_box):
		color_stacks_box.alignment = BoxContainer.ALIGNMENT_CENTER


func _remainder_chip_side() -> int:
	var gap := 6
	return maxi(int((_remainder_col_width - gap * 2 - 6) / 3.0), 40)


func _build_color_count_bar() -> void:
	var target: Container = _field_colors_box if is_instance_valid(_field_colors_box) else color_count_bar
	if not is_instance_valid(target):
		return
	for child in target.get_children():
		child.queue_free()
	color_count_squares.clear()
	var entries: Array = []
	for c in range(grid.total_color_count):
		var rem := grid.count_filled_of_color(c)
		if rem <= 0 or not grid.is_color_unlocked(c):
			continue
		entries.append(c)
	var avail_w := _remainder_col_width - 8
	var sq_size := clampi(avail_w, 40, 56) if is_instance_valid(_field_colors_box) else (44 if grid.total_color_count > 6 else 56)
	for c in entries:
		var rem := grid.count_filled_of_color(c)
		var square := _make_color_square(str(rem), c, false, false, sq_size, true)
		if is_instance_valid(_field_colors_box) and square is Control:
			square.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			square.custom_minimum_size = Vector2(sq_size, sq_size)
		target.add_child(square)
		color_count_squares.append({"square": square, "color": c})


func _refresh_color_counts() -> void:
	if grid == null or color_count_squares.is_empty():
		return
	for entry in color_count_squares:
		var square: Control = entry["square"]
		var c: int = int(entry["color"])
		var rem := grid.count_filled_of_color(c)
		var text := str(rem)
		if square is Button:
			(square as Button).text = text
		else:
			var lbl := square.get_child(0) as Label
			if lbl:
				lbl.text = text
		if c == hint_color and hint_timer > 0.0 and VisualFxService.hint_glow_enabled():
			var glow := 1.0 + sin(elapsed_time * 10.0) * 0.35
			square.modulate = Color(glow, glow, 0.6, 1.0)
		else:
			square.modulate = Color.WHITE
	# Перестроить, если на поле появился/пропал цвет.
	var on_field := 0
	for c in range(grid.total_color_count):
		if grid.is_color_unlocked(c) and grid.count_filled_of_color(c) > 0:
			on_field += 1
	if on_field != color_count_squares.size():
		_build_color_count_bar()


func _build_booster_modal() -> void:
	_booster_modal_layer = CanvasLayer.new()
	_booster_modal_layer.layer = 90
	_booster_modal_layer.name = "BoosterModalLayer"
	add_child(_booster_modal_layer)
	_booster_modal = BoosterShopModal.new()
	_booster_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	_booster_modal_layer.add_child(_booster_modal)
	_booster_modal.purchased.connect(func(_id: String) -> void:
		_update_booster_badges()
		_refresh_hud()
	)


func _build_resource_modal() -> void:
	_resource_modal_layer = CanvasLayer.new()
	_resource_modal_layer.layer = 91
	_resource_modal_layer.name = "ResourceModalLayer"
	add_child(_resource_modal_layer)
	_resource_modal = ResourcePurchaseModal.new()
	_resource_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	_resource_modal_layer.add_child(_resource_modal)
	_resource_modal.life_purchased.connect(func() -> void:
		_refresh_hud()
		_set_status("Жизнь восстановлена!")
	)
	_resource_modal.message_requested.connect(_set_status)


func _build_confirm_modal() -> void:
	_confirm_layer = CanvasLayer.new()
	_confirm_layer.layer = 95
	_confirm_layer.name = "ConfirmModalLayer"
	add_child(_confirm_layer)

	_confirm_panel = Control.new()
	_confirm_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_confirm_panel.visible = false
	_confirm_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_confirm_layer.add_child(_confirm_panel)

	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.0, 0.0, 0.0, 0.62)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_hide_confirm()
	)
	_confirm_panel.add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_confirm_panel.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(620, 0)
	card.add_theme_stylebox_override("panel", GameTheme.booster_modal_body())
	center.add_child(card)

	var wood := Control.new()
	wood.set_script(load("res://scripts/ui/shop/BoosterModalWood.gd"))
	wood.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wood.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(wood)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(body)

	var header := PanelContainer.new()
	header.custom_minimum_size = Vector2(0, 56)
	header.add_theme_stylebox_override("panel", GameTheme.booster_modal_header())
	body.add_child(header)

	_confirm_title = Label.new()
	_confirm_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_confirm_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_confirm_title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_confirm_title.add_theme_font_size_override("font_size", 32)
	_confirm_title.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	header.add_child(_confirm_title)

	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 24)
	pad.add_theme_constant_override("margin_right", 24)
	pad.add_theme_constant_override("margin_top", 8)
	pad.add_theme_constant_override("margin_bottom", 8)
	body.add_child(pad)

	_confirm_message = Label.new()
	_confirm_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_confirm_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_confirm_message.add_theme_font_size_override("font_size", 28)
	_confirm_message.add_theme_color_override("font_color", Color(0.38, 0.20, 0.12))
	pad.add_child(_confirm_message)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	body.add_child(btn_row)

	_confirm_no_btn = Button.new()
	_confirm_no_btn.text = "Отмена"
	_confirm_no_btn.custom_minimum_size = Vector2(180, 58)
	GameTheme.apply_game_over_secondary_button(_confirm_no_btn)
	_confirm_no_btn.add_theme_font_size_override("font_size", 26)
	_confirm_no_btn.pressed.connect(_hide_confirm)
	btn_row.add_child(_confirm_no_btn)

	_confirm_yes_btn = Button.new()
	_confirm_yes_btn.text = "Да"
	_confirm_yes_btn.custom_minimum_size = Vector2(180, 58)
	GameTheme.apply_booster_modal_buy_button(_confirm_yes_btn)
	_confirm_yes_btn.add_theme_font_size_override("font_size", 26)
	_confirm_yes_btn.pressed.connect(_on_confirm_yes)
	btn_row.add_child(_confirm_yes_btn)


func _show_confirm(title: String, message: String, action: Callable) -> void:
	if not is_instance_valid(_confirm_panel):
		return
	_confirm_action = action
	_confirm_title.text = title
	_confirm_message.text = message
	_confirm_panel.visible = true


func _hide_confirm() -> void:
	if is_instance_valid(_confirm_panel):
		_confirm_panel.visible = false
	_confirm_action = Callable()


func _on_confirm_yes() -> void:
	AudioService.play_sfx(&"tap")
	var action := _confirm_action
	_hide_confirm()
	if action.is_valid():
		action.call()


func _get_booster_def(booster_id: String) -> Dictionary:
	for def in BOOSTER_DEFS:
		if String(def.get("id", "")) == booster_id:
			return def
	return {}


func _build_boosters_ui() -> void:
	if not is_instance_valid(boosters_box):
		return
	for child in boosters_box.get_children():
		child.queue_free()
	booster_entries.clear()
	var list_box := VBoxContainer.new()
	list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_box.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	list_box.add_theme_constant_override("separation", 5)
	boosters_box.add_child(list_box)

	for def in BOOSTER_DEFS:
		var accent: Color = def.get("accent", Color.WHITE)
		var booster_id := String(def.get("id", ""))
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(_booster_btn_w, _booster_btn_h)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		card.add_theme_stylebox_override("panel", GameTheme.booster_tile_fill(accent))

		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 6)
		margin.add_theme_constant_override("margin_right", 6)
		margin.add_theme_constant_override("margin_top", 4)
		margin.add_theme_constant_override("margin_bottom", 4)
		card.add_child(margin)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		margin.add_child(row)

		var icon_center := CenterContainer.new()
		icon_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		icon_center.size_flags_stretch_ratio = 1.0
		icon_center.custom_minimum_size = Vector2(58, 0)
		row.add_child(icon_center)

		var icon_lbl := Label.new()
		icon_lbl.text = String(def.get("icon", "?"))
		icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon_lbl.add_theme_font_size_override("font_size", 52)
		icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_center.add_child(icon_lbl)

		var actions := HBoxContainer.new()
		actions.add_theme_constant_override("separation", 6)
		actions.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_child(actions)

		var use_btn := Button.new()
		use_btn.text = "▶"
		use_btn.tooltip_text = "Использовать"
		use_btn.custom_minimum_size = Vector2(38, 36)
		use_btn.focus_mode = Control.FOCUS_NONE
		use_btn.add_theme_font_size_override("font_size", 18)
		use_btn.add_theme_stylebox_override("normal", GameTheme.booster_action_btn(accent, false))
		use_btn.add_theme_stylebox_override("hover", GameTheme.booster_action_btn(accent.lightened(0.12), false))
		use_btn.add_theme_stylebox_override("pressed", GameTheme.booster_action_btn(accent.darkened(0.1), false))
		use_btn.add_theme_stylebox_override("disabled", GameTheme.booster_action_btn(Color(0.35, 0.38, 0.48), true))
		use_btn.pressed.connect(_on_booster_use.bind(booster_id))
		actions.add_child(use_btn)

		var count_lbl := Label.new()
		count_lbl.name = "Count"
		count_lbl.text = "0"
		count_lbl.custom_minimum_size = Vector2(30, 36)
		count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		count_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		count_lbl.add_theme_font_size_override("font_size", 26)
		count_lbl.add_theme_color_override("font_color", Color(0.98, 0.98, 1.0))
		count_lbl.add_theme_color_override("font_outline_color", Color(0.10, 0.12, 0.22, 0.95))
		count_lbl.add_theme_constant_override("outline_size", 4)
		actions.add_child(count_lbl)

		var buy_btn := Button.new()
		buy_btn.text = "+"
		buy_btn.tooltip_text = "Купить"
		buy_btn.custom_minimum_size = Vector2(38, 36)
		buy_btn.focus_mode = Control.FOCUS_NONE
		buy_btn.add_theme_font_size_override("font_size", 24)
		buy_btn.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0))
		buy_btn.add_theme_stylebox_override("normal", GameTheme.booster_action_btn(Color(0.42, 0.72, 0.48), false))
		buy_btn.add_theme_stylebox_override("hover", GameTheme.booster_action_btn(Color(0.48, 0.78, 0.54), false))
		buy_btn.add_theme_stylebox_override("pressed", GameTheme.booster_action_btn(Color(0.34, 0.62, 0.40), false))
		buy_btn.pressed.connect(_on_booster_buy.bind(booster_id))
		actions.add_child(buy_btn)

		list_box.add_child(card)
		booster_entries.append({
			"id": booster_id, "badge": count_lbl, "use_btn": use_btn, "buy_btn": buy_btn,
		})
	_update_booster_badges()


func _update_booster_badges() -> void:
	for entry in booster_entries:
		var count := GameState.get_booster_count(String(entry.id))
		var badge: Label = entry.badge
		badge.text = str(count)
		var has := count > 0
		if entry.has("use_btn") and is_instance_valid(entry.use_btn):
			entry.use_btn.disabled = not has or game_over


func _on_booster_use(booster_id: String) -> void:
	if game_over or grid == null:
		return
	if GameState.get_booster_count(booster_id) <= 0:
		_open_booster_shop(booster_id)
		return
	if _apply_booster(booster_id):
		GameState.consume_booster(booster_id)
		_update_booster_badges()


func _on_booster_buy(booster_id: String) -> void:
	if game_over:
		return
	_open_booster_shop(booster_id)


func _open_booster_shop(booster_id: String) -> void:
	var def := _get_booster_def(booster_id)
	if def.is_empty() or not is_instance_valid(_booster_modal):
		return
	_booster_modal.open(def)
	_booster_modal.move_to_front()
	if is_instance_valid(_booster_modal_layer):
		_booster_modal_layer.layer = 90


func _apply_booster(booster_id: String) -> bool:
	match booster_id:
		"hint":
			return _apply_hint_booster()
		"unblock":
			return _apply_unblock_booster()
		"scan":
			return _apply_scan_booster()
		"pulse":
			return _apply_pulse_booster()
		"warp":
			return _apply_warp_booster()
	return false


func _apply_warp_booster() -> bool:
	if GameState.is_warp_active():
		_set_status("Форсаж уже активен")
		return false
	GameState.activate_warp_from_booster()
	_apply_launch_speed()
	AudioService.play_sfx(&"warp")
	_set_status("Форсаж активен")
	_refresh_hud()
	return true


func _apply_hint_booster() -> bool:
	var active := slot_manager.get_active_colors()
	hint_color = grid.get_hint_color(active)
	if hint_color == -1:
		_set_status("Подсказка недоступна")
		return false
	hint_timer = HINT_DURATION_SECONDS
	AudioService.play_sfx(&"unlock")
	_set_status("Подсказка: %s" % GameBalance.COLOR_NAMES[hint_color])
	_refresh_hud()
	return true


func _apply_unblock_booster() -> bool:
	if not slot_manager.unlock_slot():
		_set_status("Максимум %d слотов" % GameBalance.MAX_FLEET_SLOTS)
		return false
	_update_slot_visuals()
	AudioService.play_sfx(&"warp")
	_set_status("Слот %d открыт!" % slot_manager.unlocked_slots, true, 2.8)
	_refresh_hud()
	_check_win_loss()
	return true


func _apply_scan_booster() -> bool:
	var opened := grid.scan_reveal(GameBalance.BOOSTER_SCAN_REVEAL_COUNT, slot_manager.get_rng())
	if opened <= 0:
		_set_status("Сканер: нет скрытых блоков рядом")
		status_label.visible = true
		return false
	AudioService.play_sfx(&"unlock")
	_set_status("Сканер: открыто %d блоков" % opened)
	status_label.visible = true
	_refresh_all()
	_refresh_hud()
	_check_win_loss()
	return true


func _apply_pulse_booster() -> bool:
	var active := slot_manager.get_active_colors()
	if active.is_empty():
		_set_status("Импульс: сначала отправьте цвет в слот")
		status_label.visible = true
		return false

	var color_idx := grid.get_pulse_color(active)
	if color_idx == -1:
		_set_status("Импульс: нет доступных минералов в слотах")
		status_label.visible = true
		return false

	var slot_idx := slot_manager.find_slot_for_color(color_idx)
	if slot_idx == -1:
		_set_status("Импульс: слот для этого цвета не найден")
		status_label.visible = true
		return false

	var s = slot_manager.get_slot(slot_idx)
	var eat_goal := mini(
		GameBalance.BOOSTER_PULSE_EAT_COUNT,
		mini(s.launch_quota, grid.count_exposed_of_color(color_idx)),
	)
	if eat_goal <= 0:
		_set_status("Импульс: нет запусков или минералов")
		status_label.visible = true
		return false

	var mineral := _mineral_color(color_idx)
	var eaten := grid.eat_burst_of_color(color_idx, eat_goal)
	if eaten.is_empty():
		_set_status("Импульс: не удалось добыть")
		status_label.visible = true
		return false

	s.launch_quota -= eaten.size()
	for pos in eaten:
		_spawn_burst(_cell_center(pos), mineral)
		_refresh_cell_visual(pos)
		for neighbor: Vector2i in grid.get_neighbors(pos.x, pos.y):
			_refresh_cell_visual(neighbor)

	_hud_refresh_timer = 0.0
	_refresh_color_counts()
	_update_storage_gauge()

	var post_events := slot_manager.on_mineral_collected(slot_idx, grid)
	for pe in post_events:
		if pe.has("freed"):
			slot_vending_col.erase(pe["slot"])
			slot_launch_points.erase(pe["slot"])
			_refresh_vending_reels()
			AudioService.play_sfx(&"tap")

	if grid.should_unlock_next_color() and grid.try_unlock_next_color():
		AudioService.play_sfx(&"unlock")
		_set_status_unlock()
		color_vending.add_chip_for_color(
			grid, grid.unlocked_color_count - 1, GameState.global_level_id())
		_build_color_count_bar()
		_refresh_vending_reels()
		_refresh_all()
	elif grid.try_unlock_if_stuck():
		AudioService.play_sfx(&"unlock")
		_set_status_unlock()
		color_vending.add_chip_for_color(
			grid, grid.unlocked_color_count - 1, GameState.global_level_id())
		_build_color_count_bar()
		_refresh_vending_reels()
		_refresh_all()

	_refresh_slot_visual(slot_idx, false)
	AudioService.play_sfx(&"mine")
	_set_status("Импульс: %d пикселей" % eaten.size())
	status_label.visible = true
	_refresh_hud()
	_check_win_loss()
	return true


func _update_slot_visuals() -> void:
	for i in range(GameBalance.MAX_FLEET_SLOTS):
		_refresh_slot_visual(i, false)


func _refresh_all() -> void:
	for pos in cell_panels.keys():
		_refresh_cell_visual(pos)
	if not game_over:
		_hud_refresh_timer = 0.0
		_refresh_color_counts()
		_update_booster_badges()
		_update_storage_gauge()


func _refresh_after_eat(pos: Vector2i) -> void:
	_refresh_cell_visual(pos)
	for neighbor: Vector2i in grid.get_neighbors(pos.x, pos.y):
		_refresh_cell_visual(neighbor)
	_hud_refresh_timer = 0.0
	_refresh_color_counts()
	_update_storage_gauge()
	_refresh_vending_reels()


func _refresh_cell_visual(pos: Vector2i) -> void:
	if not cell_panels.has(pos) or grid == null:
		return
	var cell: GridCell = grid.get_cell(pos.x, pos.y)
	var panel: EmptyCellPanel = cell_panels[pos]
	if not is_instance_valid(panel):
		return
	match cell.state:
		GridCell.State.EMPTY:
			panel.add_theme_stylebox_override("panel", GameTheme.cell_void())
			panel.modulate = Color.WHITE
			panel.set_striped(false)
			panel.set_overlay(EmptyCellPanel.OverlayMode.NONE)
		GridCell.State.HIDDEN:
			panel.set_striped(false)
			panel.add_theme_stylebox_override("panel", GameTheme.cell_hidden())
			panel.modulate = Color.WHITE
			panel.set_overlay(EmptyCellPanel.OverlayMode.QUESTION)
		GridCell.State.EXPOSED:
			panel.set_striped(false)
			if (
				grid.hide_interior
				and not grid.is_surface(pos.x, pos.y)
				and not cell.scanned
			):
				panel.add_theme_stylebox_override("panel", GameTheme.cell_hidden())
				panel.modulate = Color.WHITE
				panel.set_overlay(EmptyCellPanel.OverlayMode.QUESTION)
			elif not grid.is_color_unlocked(cell.color):
				panel.add_theme_stylebox_override("panel", GameTheme.cell_locked())
				panel.modulate = Color.WHITE
				panel.set_overlay(EmptyCellPanel.OverlayMode.LOCK)
			else:
				panel.set_overlay(EmptyCellPanel.OverlayMode.NONE)
				var mineral := _mineral_color(cell.color)
				if cell.modifier == GridCell.Modifier.FROZEN and cell.frost_hits > 0:
					panel.add_theme_stylebox_override("panel", GameTheme.cell_frozen(mineral))
					panel.modulate = Color.WHITE
				elif cell.modifier == GridCell.Modifier.SEALED and cell.is_sealed():
					panel.add_theme_stylebox_override("panel", GameTheme.cell_sealed(mineral))
					panel.modulate = Color.WHITE
				elif cell.modifier == GridCell.Modifier.FUSED and cell.has_fused_partner():
					panel.add_theme_stylebox_override("panel", GameTheme.pixel_cell(mineral))
					panel.modulate = Color(1.0, 0.92, 0.55, 1.0)
				else:
					panel.add_theme_stylebox_override("panel", GameTheme.pixel_cell(mineral))
					panel.modulate = Color.WHITE
				panel.add_theme_stylebox_override("panel", GameTheme.pixel_cell(mineral))
				panel.modulate = Color.WHITE
