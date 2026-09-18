extends Control
## MainMenu — главное меню с космической темой.

const LEVEL_PATH := "res://scenes/gameplay/Level.tscn"

@onready var _play_button: Button = %PlayButton
@onready var _credits_label: Label = %CreditsLabel
@onready var _lives_label: Label = %LivesLabel
@onready var _lives_timer: Label = %LivesTimer
@onready var _shop_button: Button = %ShopButton
@onready var _level_block: MenuLevelBlock = %LevelBlock
@onready var _nav_bar: ShopNavBar = %NavBar
@onready var _free_side_btn: MenuSideButton = %FreeSideBtn

var _pulse: float = 0.0
var _busy: bool = false
var _settings_modal: SettingsModal
var _lives_plus_btn: Button


func _ready() -> void:
	UiScale.set_menu_mode()
	_setup_side_buttons()
	_style_ui()
	_ensure_lives_plus()
	_build_settings_modal()
	_connect_buttons()
	_nav_bar.set_active_tab(ShopNavBar.Tab.HOME)
	_refresh_labels()
	call_deferred("_bind_level_block")
	if AudioService.has_method("play_music"):
		AudioService.play_music(&"menu_music")


func _setup_side_buttons() -> void:
	%OfferBtn.setup("🎁", "Акция", "!", Color(1.0, 0.65, 0.18))
	%FreeSideBtn.setup("🎬", GameTheme.coin_gain_text(100), "!", Color(0.35, 0.95, 0.55))
	var quest := MenuSideButton.new()
	quest.setup("📦", "0/6", "", Color(0.35, 0.78, 1.0))
	%SideLeft.add_child(quest)
	var event_btn := MenuSideButton.new()
	event_btn.setup("🏆", "Событие", "", Color(1.0, 0.82, 0.22))
	%SideRight.add_child(event_btn)
	%SideRight.move_child(event_btn, 0)


func _bind_level_block() -> void:
	if is_instance_valid(_level_block):
		_level_block.bind_base_y(_level_block.offset_top)


func _style_ui() -> void:
	%TopBar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	%SideLeft.mouse_filter = Control.MOUSE_FILTER_IGNORE
	%SideRight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	%PlayArea.mouse_filter = Control.MOUSE_FILTER_IGNORE
	%GameTitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	%UILayer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_nav_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	%LivesPill.add_theme_stylebox_override("panel", GameTheme.menu_space_hud_pill_life())
	%CreditsPill.add_theme_stylebox_override("panel", GameTheme.menu_space_hud_pill_gold())
	%ProfileFrame.add_theme_stylebox_override("panel", GameTheme.menu_profile_frame())
	_ensure_credits_coin()

	GameTheme.apply_menu_profile_button(%ProfileButton)
	GameTheme.apply_shop_price_button(_shop_button)
	GameTheme.apply_menu_play_button(_play_button)

	var settings_style := GameTheme.menu_settings_button()
	%SettingsButton.add_theme_stylebox_override("normal", settings_style)
	%SettingsButton.add_theme_stylebox_override("hover", settings_style)
	%SettingsButton.add_theme_stylebox_override("pressed", settings_style)
	%SettingsButton.add_theme_stylebox_override("focus", settings_style)
	%SettingsButton.add_theme_color_override("font_color", Color(0.72, 0.88, 1.0))


func _ensure_lives_plus() -> void:
	var vbox: VBoxContainer = %LivesPill.get_node("LivesVBox")
	if vbox.get_node_or_null("LivesTopRow"):
		return
	var row := HBoxContainer.new()
	row.name = "LivesTopRow"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	vbox.remove_child(_lives_label)
	vbox.remove_child(_lives_timer)
	row.add_child(_lives_label)
	_lives_plus_btn = Button.new()
	_lives_plus_btn.name = "LivesPlusBtn"
	_lives_plus_btn.text = "+"
	_lives_plus_btn.custom_minimum_size = Vector2(36, 36)
	_lives_plus_btn.focus_mode = Control.FOCUS_NONE
	GameTheme.apply_shop_price_button(_lives_plus_btn)
	_lives_plus_btn.add_theme_font_size_override("font_size", 22)
	_lives_plus_btn.pressed.connect(_on_lives_plus_pressed)
	row.add_child(_lives_plus_btn)
	vbox.add_child(row)
	vbox.add_child(_lives_timer)
	vbox.move_child(row, 0)


func _build_settings_modal() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 120
	add_child(layer)
	_settings_modal = SettingsModal.new()
	_settings_modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_settings_modal)


func _connect_buttons() -> void:
	_play_button.pressed.connect(_on_play_pressed)
	_shop_button.pressed.connect(_on_shop_pressed)
	%SettingsButton.pressed.connect(_on_settings_pressed)
	%OfferBtn.pressed.connect(_on_shop_pressed)
	_free_side_btn.pressed.connect(_on_free_reward_pressed)
	_nav_bar.shop_pressed.connect(_on_shop_pressed)


func _process(delta: float) -> void:
	GameState.tick_warp(delta)
	GameState.tick_lives_regen()
	_pulse += delta
	_refresh_labels()
	_update_play_button()
	var can_play := GameState.can_play_level()
	var glow := 0.94 + sin(_pulse * 2.2) * 0.06
	_play_button.modulate = Color(glow, glow, glow, 1.0) if can_play else Color(0.55, 0.60, 0.72, 1.0)


func _ensure_credits_coin() -> void:
	var row: HBoxContainer = %CreditsPill.get_node("CreditsRow")
	if row.get_node_or_null("CoinIconWidget"):
		return
	var coin := GameTheme.make_coin_icon(22)
	coin.name = "CoinIconWidget"
	row.add_child(coin)
	row.move_child(coin, 0)


func _refresh_labels() -> void:
	_credits_label.text = str(GameState.credits)
	_credits_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.48))
	_credits_label.add_theme_color_override("font_outline_color", Color(0.22, 0.12, 0.02, 0.9))
	var lives := clampi(GameState.lives, 0, GameBalance.LIVES_MAX)
	_lives_label.text = "❤ %d/%d" % [lives, GameBalance.LIVES_MAX]
	var timer_text := GameState.lives_timer_text()
	_lives_timer.text = ("+1 через %s" % timer_text) if timer_text != "" else ""
	_lives_timer.visible = timer_text != ""
	_level_block.set_level(GameState.current_level_in_sector, GameState.get_level_difficulty())
	_refresh_free_side_button()


func _refresh_free_side_button() -> void:
	if GameState.can_claim_free_shop_reward():
		_free_side_btn.modulate = Color(1, 1, 1, 1)
		_free_side_btn.set_caption(GameTheme.coin_gain_text(100))
		_free_side_btn.set_badge("!")
	else:
		_free_side_btn.modulate = Color(0.55, 0.58, 0.65, 0.85)
		var timer_text := GameState.free_shop_timer_text()
		_free_side_btn.set_caption(timer_text if timer_text != "" else "завтра")
		_free_side_btn.set_badge("")


func _update_play_button() -> void:
	if _busy:
		return
	var can_play := GameState.can_play_level()
	_play_button.disabled = false
	_play_button.text = "ИГРАТЬ" if can_play else "НЕТ ЖИЗНЕЙ"


func _on_play_pressed() -> void:
	if _busy:
		return
	AudioService.play_sfx(&"tap")
	if not GameState.can_play_level():
		GameState.open_shop()
		return
	_busy = true
	GameState.request_load(LEVEL_PATH)


func _on_shop_pressed() -> void:
	if _busy:
		return
	AudioService.play_sfx(&"tap")
	GameState.open_shop()


func _on_lives_plus_pressed() -> void:
	if _busy:
		return
	AudioService.play_sfx(&"tap")
	GameState.open_shop()


func _on_settings_pressed() -> void:
	if _busy:
		return
	AudioService.play_sfx(&"tap")
	_settings_modal.open()


func _on_free_reward_pressed() -> void:
	if _busy:
		return
	if GameState.claim_free_shop_reward():
		AudioService.play_sfx(&"tap")
		_refresh_labels()
	else:
		GameState.open_shop()
