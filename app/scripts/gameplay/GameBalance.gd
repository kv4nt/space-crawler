extends Node
## GameBalance — секторы, уровни, константы.

const SECTOR_COUNT: int = 10
const LEVELS_PER_SECTOR: int = 30

const DEFAULT_SLOT_COUNT: int = 3
const MAX_FLEET_SLOTS: int = 5
const GRID_TARGET_SIZE: int = 40
const PLAYFIELD_MAX_WIDTH: float = 960.0
const GRID_CELL_MIN: int = 16
const GRID_CELL_MAX: int = 28
const BOTTOM_PANEL_MIN_H: int = 360
const SHIP_LAUNCH_INTERVAL: float = 0.62
const SHIP_TO_MINERAL_SECONDS: float = 3.0
const SHIP_TO_BUNKER_SECONDS: float = 2.2
const SHIP_FLIGHT_ARC_BULGE: float = 0.28
const SHIP_RETURN_SECONDS: float = 1.4
const MAX_SHIPS_PER_COLOR: int = 10

const MINERAL_COLORS: Array[Color] = [
	Color(0.90, 0.28, 0.35),  # 0 красный
	Color(0.28, 0.78, 0.42),  # 1 зелёный
	Color(0.30, 0.55, 0.95),  # 2 синий
	Color(0.95, 0.82, 0.18),  # 3 жёлтый
	Color(0.65, 0.95, 0.35),  # 4 салатовый
	Color(0.07, 0.08, 0.11),  # 5 чёрный
	Color(0.92, 0.94, 0.98),  # 6 белый
	Color(0.55, 0.38, 0.24),  # 7 коричневый
	Color(0.95, 0.52, 0.18),  # 8 оранжевый
	Color(0.62, 0.32, 0.88),  # 9 фиолетовый
	Color(0.72, 0.74, 0.78),  # 10 серебро
	Color(0.50, 0.52, 0.56),  # 11 серый
	Color(0.14, 0.24, 0.58),  # 12 тёмно-синий
	Color(0.35, 0.88, 0.92),  # 13 голубой
	Color(0.95, 0.45, 0.65),  # 14 розовый
	Color(0.55, 0.12, 0.22),  # 15 бордовый
	Color(0.85, 0.68, 0.22),  # 16 золотой
	Color(0.28, 0.72, 0.68),  # 17 мятный
	Color(0.88, 0.78, 0.62),  # 18 бежевый
	Color(0.22, 0.38, 0.82),  # 19 яркий синий
]

const COLOR_NAMES: Array[String] = [
	"Красный", "Зелёный", "Синий", "Жёлтый", "Салатовый",
	"Чёрный", "Белый", "Коричневый", "Оранжевый", "Фиолетовый",
	"Серебро", "Серый", "Тёмно-синий", "Голубой", "Розовый",
	"Бордовый", "Золотой", "Мятный", "Бежевый", "Сапфир",
]

const MAX_MINERAL_COLORS: int = 20
const BACKGROUND_COLOR_INDEX: int = 5

const PULSE_PERIOD_SECONDS: float = 1.2
const PULSE_MIN_ALPHA: float = 0.55
const PULSE_MAX_ALPHA: float = 1.0
const MINE_BURST_PARTICLE_AMOUNT: int = 4
const MINE_BURST_LIFETIME_SECONDS: float = 0.35
const SHIP_TRAIL_PARTICLE_AMOUNT: int = 4
const SHIP_TRAIL_LITE_AMOUNT: int = 0
const SHIP_TRAIL_LITE_THRESHOLD: int = 5

const WARP_CORE_FREE_MINUTES: float = 5.0
const WARP_CORE_SPEED_MULTIPLIER: float = 2.0
const WARP_CORE_COST_CREDITS: int = 300

const LIVES_MAX: int = 5
const LIVES_START: int = 5
const LIFE_REGEN_SECONDS: int = 3600
const LIFE_REFILL_COST: int = 150

const BOOSTER_HINT_COST: int = 120
const BOOSTER_UNBLOCK_COST: int = 180
const BOOSTER_SCAN_COST: int = 200
const BOOSTER_PULSE_COST: int = 250
const BOOSTER_SCAN_REVEAL_COUNT: int = 10
const BOOSTER_PULSE_EAT_COUNT: int = 10

## Спецэффекты минералов (лёд / сплав / печать) — GridCell.Modifier.
const FROST_HITS_DEFAULT: int = 2
const SEAL_SIGNAL_COUNT_DEFAULT: int = 3

enum LevelDifficulty { NORMAL = 0, HARD = 1, EXTREME = 2 }


static func level_difficulty(level_in_sector: int) -> int:
	if level_in_sector % 5 == 0:
		return LevelDifficulty.EXTREME
	if level_in_sector % 3 == 0:
		return LevelDifficulty.HARD
	return LevelDifficulty.NORMAL


static func global_id(sector: int, level_in_sector: int) -> int:
	return (sector - 1) * LEVELS_PER_SECTOR + level_in_sector


static func sector_and_level(global_id: int) -> Vector2i:
	var sector := (global_id - 1) / LEVELS_PER_SECTOR + 1
	var lvl := (global_id - 1) % LEVELS_PER_SECTOR + 1
	return Vector2i(sector, lvl)


func get_level(sector: int, level_in_sector: int) -> Dictionary:
	var s := clampi(sector, 1, SECTOR_COUNT)
	var l := clampi(level_in_sector, 1, LEVELS_PER_SECTOR)
	var gid := global_id(s, l)
	return LevelGenerator.generate(gid, s, l)


func get_level_by_global_id(global_id: int) -> Dictionary:
	var sl := sector_and_level(clampi(global_id, 1, get_max_level()))
	return get_level(sl.x, sl.y)


func get_level_reward(global_id: int) -> int:
	return get_level_by_global_id(global_id).get("reward", 100)


func get_max_level() -> int:
	return SECTOR_COUNT * LEVELS_PER_SECTOR
