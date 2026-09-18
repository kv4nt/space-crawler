extends Control
## ShopScreen — экран магазина в стиле Food Hunt.

const CREDIT_PACKS: Array = [
	{"id": "cr_1000", "amount": 1000, "price_label": "199,00 ₽", "tier": 0},
	{"id": "cr_2500", "amount": 2500, "price_label": "449,00 ₽", "tier": 1},
	{"id": "cr_5000", "amount": 5000, "price_label": "799,00 ₽", "tier": 2},
	{"id": "cr_10000", "amount": 10000, "price_label": "1 490,00 ₽", "tier": 3},
	{"id": "cr_25000", "amount": 25000, "price_label": "2 990,00 ₽", "tier": 4},
	{"id": "cr_50000", "amount": 50000, "price_label": "4 990,00 ₽", "tier": 5},
]

const BOOSTER_PACKS: Array = [
	{"id": "hint_pack", "icon": "💡", "title": "Подсказка", "cost": 300, "booster": "hint", "count": 3},
	{"id": "unblock_pack", "icon": "🔓", "title": "Разблок", "cost": 320, "booster": "unblock", "count": 2},
	{"id": "scan_pack", "icon": "📡", "title": "Сканер", "cost": 360, "booster": "scan", "count": 2},
	{"id": "pulse_pack", "icon": "⚡", "title": "Импульс", "cost": 450, "booster": "pulse", "count": 2},
]

@onready var _credits_label: Label = %CreditsLabel
@onready var _toast_label: Label = %ToastLabel
@onready var _mega_bundle: ShopMegaBundle = %MegaBundle
@onready var _free_button: Button = %FreeButton
@onready var _free_timer_label: Label = %FreeTimerLabel
@onready var _buy_life_button: Button = %BuyLifeButton
@onready var _lives_shop_label: Label = %LivesShopLabel
@onready var _lives_timer_label: Label = %LivesTimerLabel
@onready var _nav_bar: ShopNavBar = %NavBar

var _product_cards: Array = []
var _booster_cards: Array = []


func _ready() -> void:
	UiScale.set_menu_mode()
	if AudioService.has_method("play_music"):
		AudioService.play_music(&"menu_music")
	_style_panels()
	_mega_bundle.buy_pressed.connect(_on_mega_bundle_buy)
	_nav_bar.home_pressed.connect(_on_home_pressed)
	_nav_bar.set_active_tab(ShopNavBar.Tab.SHOP)
	_build_credit_grid()
	_build_booster_grid()
	_configure_shop_scroll()
	_refresh_all()


func _style_panels() -> void:
	var title_banner: PanelContainer = $Layout/Header/TitleBanner
	var credits_chip: PanelContainer = $Layout/Header/CreditsChip
	var cat_credits: PanelContainer = $Layout/Scroll/Content/ContentMargin/ContentVBox/CategoryCredits
	var cat_boosters: PanelContainer = $Layout/Scroll/Content/ContentMargin/ContentVBox/CategoryBoosters
	_lives_timer_label.add_theme_color_override("font_color", Color(0.06, 0.06, 0.08))
	_lives_timer_label.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.35))
	_lives_timer_label.add_theme_constant_override("outline_size", 2)
	var cat_lives: PanelContainer = $Layout/Scroll/Content/ContentMargin/ContentVBox/CategoryLives
	var free_row: PanelContainer = $Layout/Scroll/Content/ContentMargin/ContentVBox/FreeRow
	var lives_row: PanelContainer = $Layout/Scroll/Content/ContentMargin/ContentVBox/LivesRow
	title_banner.add_theme_stylebox_override("panel", GameTheme.shop_title_banner())
	credits_chip.add_theme_stylebox_override("panel", GameTheme.shop_credit_chip_white())
	cat_credits.add_theme_stylebox_override("panel", GameTheme.shop_category_pill())
	cat_boosters.add_theme_stylebox_override("panel", GameTheme.shop_category_pill())
	cat_lives.add_theme_stylebox_override("panel", GameTheme.shop_category_pill())
	free_row.add_theme_stylebox_override("panel", GameTheme.shop_free_row())
	lives_row.add_theme_stylebox_override("panel", GameTheme.shop_life_row())
	GameTheme.apply_shop_price_button(_free_button)
	GameTheme.apply_shop_price_button(_buy_life_button)
	var add_btn: Button = $Layout/Header/CreditsChip/CreditsRow/AddCreditsButton
	GameTheme.apply_shop_price_button(add_btn)
	add_btn.custom_minimum_size = Vector2(44, 44)
	add_btn.text = "+"
	var coin_row: HBoxContainer = $Layout/Header/CreditsChip/CreditsRow
	var old_coin := coin_row.get_node_or_null("CoinIcon")
	if old_coin:
		old_coin.queue_free()
	var coin := GameTheme.make_coin_icon(24)
	coin.name = "CoinIcon"
	coin_row.add_child(coin)
	coin_row.move_child(coin, 0)
	_credits_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.28))
	var free_gift: Label = $Layout/Scroll/Content/ContentMargin/ContentVBox/FreeRow/FreeHBox/FreeInfo/FreeIcon
	free_gift.text = "🎁 %s · раз в сутки" % GameTheme.coin_gain_text(100)


func _configure_shop_scroll() -> void:
	var scroll_root: Node = $Layout/Scroll/Content
	_set_scroll_passthrough(scroll_root)


func _set_scroll_passthrough(node: Node) -> void:
	for child in node.get_children():
		if child is Button:
			continue
		if child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_scroll_passthrough(child)


func _build_credit_grid() -> void:
	var grid: GridContainer = %CreditGrid
	for pack in CREDIT_PACKS:
		var card := ShopProductCard.new()
		grid.add_child(card)
		card.setup(pack)
		card.pressed.connect(_on_credit_pack_pressed.bind(pack))
		_product_cards.append(card)


func _build_booster_grid() -> void:
	var grid: GridContainer = %BoosterGrid
	for pack in BOOSTER_PACKS:
		var card := ShopBoosterCard.new()
		grid.add_child(card)
		card.setup(pack)
		card.pressed.connect(_on_booster_pack_pressed.bind(pack))
		_booster_cards.append({"pack": pack, "button": card})


func _refresh_booster_buttons() -> void:
	for entry in _booster_cards:
		var pack: Dictionary = entry.pack
		var card: ShopBoosterCard = entry.button
		card.set_affordable(GameState.credits >= int(pack.cost))


func _process(_delta: float) -> void:
	GameState.tick_lives_regen()
	_refresh_lives_ui()
	_refresh_free_button()


func _refresh_all() -> void:
	_credits_label.text = str(GameState.credits)
	if _mega_bundle.has_method("refresh_state"):
		_mega_bundle.refresh_state()
	_refresh_booster_buttons()
	_refresh_free_button()
	_refresh_lives_ui()


func _refresh_lives_ui() -> void:
	var lives := clampi(GameState.lives, 0, GameBalance.LIVES_MAX)
	_lives_shop_label.text = "❤ %d/%d" % [lives, GameBalance.LIVES_MAX]
	var timer_text := GameState.lives_timer_text()
	_lives_timer_label.text = ("+1 через %s" % timer_text) if timer_text != "" else "Полный запас"
	if lives >= GameBalance.LIVES_MAX:
		_buy_life_button.text = "ПОЛНО"
		_buy_life_button.disabled = true
	elif GameState.can_buy_life():
		GameTheme.apply_button_coin(_buy_life_button, GameBalance.LIFE_REFILL_COST, "", "КУПИТЬ")
		_buy_life_button.disabled = false
	else:
		GameTheme.apply_button_coin(_buy_life_button, GameBalance.LIFE_REFILL_COST, "", "КУПИТЬ")
		_buy_life_button.disabled = true


func _refresh_free_button() -> void:
	if GameState.can_claim_free_shop_reward():
		_free_button.text = "▶ FREE"
		_free_button.disabled = false
		_free_timer_label.text = "Доступно!"
		_free_timer_label.add_theme_color_override("font_color", Color(0.18, 0.55, 0.22))
	else:
		_free_button.text = "FREE"
		_free_button.disabled = true
		var timer_text := GameState.free_shop_timer_text()
		_free_timer_label.text = "через %s" % timer_text if timer_text != "" else "завтра"
		_free_timer_label.add_theme_color_override("font_color", Color(0.35, 0.28, 0.18))


func _on_mega_bundle_buy() -> void:
	if GameState.buy_mega_bundle():
		AudioService.play_sfx(&"tap")
		_show_toast("Мега-набор получен!")
		_refresh_all()
	else:
		_show_toast(GameTheme.coin_shortfall_text())


func _on_credit_pack_pressed(pack: Dictionary) -> void:
	AudioService.play_sfx(&"tap")
	_show_toast("Покупки за реальные деньги — скоро")


func _on_booster_pack_pressed(pack: Dictionary) -> void:
	var cost := int(pack.cost)
	if not GameState.spend_credits(cost):
		_show_toast(GameTheme.coin_shortfall_text())
		return
	GameState.add_booster(String(pack.booster), int(pack.count))
	AudioService.play_sfx(&"tap")
	_show_toast("Бустеры добавлены!")
	_refresh_all()


func _on_free_pressed() -> void:
	if GameState.claim_free_shop_reward():
		AudioService.play_sfx(&"tap")
		_show_toast("%s — ежедневная награда!" % GameTheme.coin_gain_text(100))
		_refresh_all()
	else:
		_show_toast("Уже забрали сегодня")


func _on_buy_life_pressed() -> void:
	if GameState.buy_life():
		AudioService.play_sfx(&"tap")
		_show_toast("+1 жизнь!")
		_refresh_all()
	else:
		if GameState.lives >= GameBalance.LIVES_MAX:
			_show_toast("Жизни уже полные")
		else:
			_show_toast(GameTheme.coin_shortfall_text())


func _on_home_pressed() -> void:
	AudioService.play_sfx(&"tap")
	GameState.open_menu()


func _on_add_credits_pressed() -> void:
	AudioService.play_sfx(&"tap")
	_refresh_all()


func _show_toast(message: String) -> void:
	_toast_label.text = message
	_toast_label.visible = true
	var tween := create_tween()
	tween.tween_interval(1.6)
	tween.tween_callback(func() -> void: _toast_label.visible = false)
