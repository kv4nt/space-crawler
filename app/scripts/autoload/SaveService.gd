extends Node
## SaveService — локальное сохранение прогресса в user://savegame.json.

const SAVE_PATH: String = "user://savegame.json"
const SCHEMA_VERSION: int = 8

const DEFAULTS: Dictionary = {
	"schema_version": SCHEMA_VERSION,
	"credits": 500,
	"current_sector": 1,
	"current_level_in_sector": 1,
	"max_unlocked_global": 1,
	"lives": GameBalance.LIVES_START,
	"life_regen_deadlines": [],
	"warp_core_seconds_left": 0.0,
	"warp_free_used": false,
	"boosters": {"hint": 0, "unblock": 0, "scan": 0, "pulse": 0, "warp": 0},
	"shop_free_claim_day": -1,
	"music_volume": 0.7,
	"sfx_volume": 0.8,
	"sounds_enabled": true,
	"vibration_enabled": true,
	"visual_fx_quality": VisualFxService.Quality.FULL,
}


func _ready() -> void:
	load_game()


func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		_apply_to_state(DEFAULTS.duplicate(true))
		return DEFAULTS.duplicate(true)

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("SaveService: cannot read save file")
		_apply_to_state(DEFAULTS.duplicate(true))
		return DEFAULTS.duplicate(true)

	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()

	if err != OK:
		push_warning("SaveService: invalid JSON, resetting")
		_apply_to_state(DEFAULTS.duplicate(true))
		return DEFAULTS.duplicate(true)

	var data: Dictionary = json.data
	_migrate_save(data)
	_apply_to_state(data)
	return data


func save_game() -> void:
	var data := {
		"schema_version": SCHEMA_VERSION,
		"credits": GameState.credits,
		"current_sector": GameState.current_sector,
		"current_level_in_sector": GameState.current_level_in_sector,
		"max_unlocked_global": GameState.max_unlocked_global,
		"lives": GameState.lives,
		"life_regen_deadlines": GameState.life_regen_deadlines.duplicate(),
		"warp_core_seconds_left": GameState.warp_core_seconds_left,
		"warp_free_used": GameState.warp_free_used,
		"boosters": GameState.boosters.duplicate(true),
		"shop_free_claim_day": GameState.shop_free_claim_day,
		"music_volume": AudioService.music_volume,
		"sfx_volume": AudioService.sfx_volume,
		"sounds_enabled": AudioService.sounds_enabled,
		"vibration_enabled": GameState.vibration_enabled,
		"visual_fx_quality": VisualFxService.quality,
	}

	var json_text := JSON.stringify(data, "\t")
	var tmp_path := SAVE_PATH + ".tmp"
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		push_warning("SaveService: cannot write temp save")
		return
	file.store_string(json_text)
	file.close()

	var dir := DirAccess.open("user://")
	if dir:
		if dir.file_exists("savegame.json"):
			dir.remove("savegame.json")
		dir.rename("savegame.json.tmp", "savegame.json")


func _migrate_save(data: Dictionary) -> void:
	if not data.has("current_sector"):
		var old_level: int = data.get("current_level", 1)
		var sl := GameBalance.sector_and_level(old_level)
		data["current_sector"] = sl.x
		data["current_level_in_sector"] = sl.y
		data["max_unlocked_global"] = data.get("max_unlocked_level", 1)
	if int(data.get("schema_version", 0)) < 5:
		data["lives"] = mini(int(data.get("lives", GameBalance.LIVES_START)), GameBalance.LIVES_MAX)
		if not data.has("life_regen_deadlines"):
			data["life_regen_deadlines"] = []
		data["schema_version"] = 5
	if int(data.get("schema_version", 0)) < 6:
		data["music_enabled"] = true
		data["vibration_enabled"] = true
		data["schema_version"] = 6
	if int(data.get("schema_version", 0)) < 7:
		data["sounds_enabled"] = data.get("music_enabled", true)
		data.erase("music_enabled")
		data["schema_version"] = 7
	if int(data.get("schema_version", 0)) < 8:
		data["visual_fx_quality"] = VisualFxService.Quality.FULL
		data["schema_version"] = 8
	elif not data.has("current_sector"):
		data["schema_version"] = SCHEMA_VERSION


func _apply_to_state(data: Dictionary) -> void:
	GameState.credits = data.get("credits", DEFAULTS.credits)
	GameState.current_sector = data.get("current_sector", DEFAULTS.current_sector)
	GameState.current_level_in_sector = data.get(
		"current_level_in_sector", DEFAULTS.current_level_in_sector)
	GameState.max_unlocked_global = data.get("max_unlocked_global", DEFAULTS.max_unlocked_global)
	GameState.lives = mini(int(data.get("lives", DEFAULTS.lives)), GameBalance.LIVES_MAX)
	var saved_deadlines: Variant = data.get("life_regen_deadlines", [])
	GameState.life_regen_deadlines.clear()
	if saved_deadlines is Array:
		for entry in saved_deadlines:
			GameState.life_regen_deadlines.append(int(entry))
	GameState.sync_life_regen_deadlines()
	GameState.tick_lives_regen()
	GameState.warp_core_seconds_left = data.get("warp_core_seconds_left", 0.0)
	GameState.warp_free_used = data.get("warp_free_used", false)
	var saved_boosters: Variant = data.get("boosters", {})
	if saved_boosters is Dictionary:
		for key in GameState.boosters.keys():
			GameState.boosters[key] = int(saved_boosters.get(key, 0))
	GameState.shop_free_claim_day = int(data.get("shop_free_claim_day", -1))
	AudioService.music_volume = data.get("music_volume", DEFAULTS.music_volume)
	AudioService.sfx_volume = data.get("sfx_volume", DEFAULTS.sfx_volume)
	AudioService.sounds_enabled = data.get(
		"sounds_enabled", data.get("music_enabled", DEFAULTS.sounds_enabled))
	GameState.vibration_enabled = data.get("vibration_enabled", DEFAULTS.vibration_enabled)
	VisualFxService.apply_quality(
		int(data.get("visual_fx_quality", DEFAULTS.visual_fx_quality)), false)
