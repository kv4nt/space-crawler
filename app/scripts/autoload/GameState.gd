extends Node
## GameState — runtime-состояние текущей сессии.

const DEFAULT_MENU_SCENE := "res://scenes/app/Main.tscn"
const LOADING_SCENE := "res://scenes/app/LoadingScreen.tscn"
const SHOP_SCENE := "res://scenes/app/ShopScreen.tscn"

var loading_target: String = DEFAULT_MENU_SCENE
var credits: int = 500
var current_sector: int = 1
var current_level_in_sector: int = 1
var max_unlocked_global: int = 1
var lives: int = GameBalance.LIVES_START
var warp_core_seconds_left: float = 0.0
var warp_free_used: bool = false
var boosters: Dictionary = {"hint": 0, "unblock": 0, "scan": 0, "pulse": 0, "warp": 0}
var shop_free_claim_day: int = -1
var life_regen_deadlines: Array[int] = []
var vibration_enabled: bool = true


func request_load(path: String) -> void:
	loading_target = path
	get_tree().change_scene_to_file(LOADING_SCENE)


func open_shop() -> void:
	get_tree().change_scene_to_file(SHOP_SCENE)


func open_menu() -> void:
	get_tree().change_scene_to_file(DEFAULT_MENU_SCENE)


func consume_loading_target() -> String:
	var path := loading_target
	loading_target = DEFAULT_MENU_SCENE
	return path


func global_level_id() -> int:
	return GameBalance.global_id(current_sector, current_level_in_sector)


func is_warp_active() -> bool:
	return warp_core_seconds_left > 0.0


func activate_warp_free() -> bool:
	if warp_free_used:
		return false
	warp_core_seconds_left = GameBalance.WARP_CORE_FREE_MINUTES * 60.0
	warp_free_used = true
	SaveService.save_game()
	return true


func activate_warp_paid() -> bool:
	if credits < GameBalance.WARP_CORE_COST_CREDITS:
		return false
	credits -= GameBalance.WARP_CORE_COST_CREDITS
	warp_core_seconds_left = GameBalance.WARP_CORE_FREE_MINUTES * 60.0
	SaveService.save_game()
	return true


func activate_warp_from_booster() -> void:
	warp_core_seconds_left = GameBalance.WARP_CORE_FREE_MINUTES * 60.0
	SaveService.save_game()


func tick_warp(delta: float) -> void:
	if warp_core_seconds_left > 0.0:
		warp_core_seconds_left = maxf(warp_core_seconds_left - delta, 0.0)


func lose_life() -> void:
	if lives <= 0:
		return
	lives -= 1
	if lives < GameBalance.LIVES_MAX:
		life_regen_deadlines.append(_now_unix() + GameBalance.LIFE_REGEN_SECONDS)
		life_regen_deadlines.sort()
	SaveService.save_game()


func tick_lives_regen() -> void:
	sync_life_regen_deadlines()
	if lives >= GameBalance.LIVES_MAX:
		if not life_regen_deadlines.is_empty():
			life_regen_deadlines.clear()
			SaveService.save_game()
		return
	var now := _now_unix()
	life_regen_deadlines.sort()
	var changed := false
	while (
		lives < GameBalance.LIVES_MAX
		and not life_regen_deadlines.is_empty()
		and life_regen_deadlines[0] <= now
	):
		life_regen_deadlines.remove_at(0)
		lives += 1
		changed = true
	if changed:
		sync_life_regen_deadlines()
		SaveService.save_game()


## Поддерживает таймер: у каждой недостающей жизни должен быть дедлайн регенерации.
func sync_life_regen_deadlines() -> void:
	if lives >= GameBalance.LIVES_MAX:
		return
	var missing_lives := GameBalance.LIVES_MAX - lives
	while life_regen_deadlines.size() < missing_lives:
		var queue_idx := life_regen_deadlines.size()
		life_regen_deadlines.append(_now_unix() + GameBalance.LIFE_REGEN_SECONDS * (queue_idx + 1))
	life_regen_deadlines.sort()
	while life_regen_deadlines.size() > missing_lives:
		life_regen_deadlines.pop_back()


func seconds_until_next_life() -> int:
	tick_lives_regen()
	if lives >= GameBalance.LIVES_MAX:
		return 0
	sync_life_regen_deadlines()
	if life_regen_deadlines.is_empty():
		return 0
	life_regen_deadlines.sort()
	return maxi(0, life_regen_deadlines[0] - _now_unix())


func lives_timer_text() -> String:
	var sec := seconds_until_next_life()
	if sec <= 0:
		return ""
	var mins := sec / 60
	var secs := sec % 60
	return "%d:%02d" % [mins, secs]


func can_play_level() -> bool:
	tick_lives_regen()
	return lives > 0


func buy_life() -> bool:
	tick_lives_regen()
	if lives >= GameBalance.LIVES_MAX:
		return false
	if credits < GameBalance.LIFE_REFILL_COST:
		return false
	credits -= GameBalance.LIFE_REFILL_COST
	lives += 1
	if not life_regen_deadlines.is_empty():
		life_regen_deadlines.sort()
		life_regen_deadlines.remove_at(0)
	SaveService.save_game()
	return true


func can_buy_life() -> bool:
	tick_lives_regen()
	return lives < GameBalance.LIVES_MAX and credits >= GameBalance.LIFE_REFILL_COST


func spend_credits(amount: int) -> bool:
	if credits < amount:
		return false
	credits -= amount
	SaveService.save_game()
	return true


func add_credits(amount: int) -> void:
	credits += maxi(amount, 0)
	SaveService.save_game()


func can_claim_free_shop_reward() -> bool:
	return shop_free_claim_day != _today_day_index()


func seconds_until_free_shop_reward() -> int:
	if can_claim_free_shop_reward():
		return 0
	var next_day_start := (_today_day_index() + 1) * 86400
	return maxi(0, next_day_start - _now_unix())


func free_shop_timer_text() -> String:
	var sec := seconds_until_free_shop_reward()
	if sec <= 0:
		return ""
	var hours := sec / 3600
	var mins := (sec % 3600) / 60
	var secs := sec % 60
	if hours > 0:
		return "%d:%02d:%02d" % [hours, mins, secs]
	return "%d:%02d" % [mins, secs]


func claim_free_shop_reward() -> bool:
	if not can_claim_free_shop_reward():
		return false
	shop_free_claim_day = _today_day_index()
	add_credits(100)
	return true


func buy_mega_bundle() -> bool:
	const COST := 650
	if not spend_credits(COST):
		return false
	for booster_id in boosters.keys():
		add_booster(booster_id, 2)
	add_credits(300)
	return true


func _today_day_index() -> int:
	return int(Time.get_unix_time_from_system() / 86400)


func _now_unix() -> int:
	return int(Time.get_unix_time_from_system())


func get_booster_count(booster_id: String) -> int:
	return int(boosters.get(booster_id, 0))


func add_booster(booster_id: String, count: int = 1) -> void:
	if not boosters.has(booster_id):
		return
	boosters[booster_id] = int(boosters[booster_id]) + maxi(count, 0)
	SaveService.save_game()


func consume_booster(booster_id: String) -> bool:
	if get_booster_count(booster_id) <= 0:
		return false
	boosters[booster_id] = int(boosters[booster_id]) - 1
	SaveService.save_game()
	return true


func complete_level(_global_id: int) -> void:
	var reward := GameBalance.get_level_reward(_global_id)
	credits += reward
	if _global_id >= max_unlocked_global:
		max_unlocked_global = _global_id + 1
	SaveService.save_game()


func advance_to_next_level() -> void:
	current_level_in_sector += 1
	if current_level_in_sector > GameBalance.LEVELS_PER_SECTOR:
		current_sector = mini(current_sector + 1, GameBalance.SECTOR_COUNT)
		current_level_in_sector = 1
	SaveService.save_game()


func get_level_difficulty() -> int:
	return GameBalance.level_difficulty(current_level_in_sector)


func is_hard_level() -> bool:
	return get_level_difficulty() >= GameBalance.LevelDifficulty.HARD


func is_extreme_level() -> bool:
	return get_level_difficulty() == GameBalance.LevelDifficulty.EXTREME


func level_compact_label() -> String:
	return str(current_level_in_sector)


func level_display_name(theme: String = "") -> String:
	var name := "Сектор %d · Уровень %d" % [current_sector, current_level_in_sector]
	if theme != "":
		name += " · %s" % theme
	match get_level_difficulty():
		GameBalance.LevelDifficulty.EXTREME:
			name += " · Экстремальный"
		GameBalance.LevelDifficulty.HARD:
			name += " · Сложный"
	return name


func set_vibration_enabled(enabled: bool) -> void:
	vibration_enabled = enabled
	SaveService.save_game()


func vibrate_handheld(duration_ms: int = 30) -> void:
	if not vibration_enabled:
		return
	Input.vibrate_handheld(duration_ms)
