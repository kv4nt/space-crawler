extends Node
## GameBalance — автозагрузка с балансовыми константами игры.
## Этап: Feel (Шаг 3). Значения являются временными заглушками и будут
## вынесены в data/balance.json на Этапе 4 (Прогресс), без правки UI/логики.

const GRID_WIDTH: int = 14
const GRID_HEIGHT: int = 14
const DEFAULT_DOCK_COUNT: int = 5
const DEFAULT_COLOR_COUNT: int = 3

const MINE_DURATION_SECONDS: float = 2.0
const TARGET_PER_COLOR: int = 12

## Визуальные константы Шага 3 (Feel). Цвет минерала не подсказывает
## игроку его смысл заранее — используется только после раскрытия клетки.
const MINERAL_COLORS: Array[Color] = [
	Color(0.90, 0.28, 0.35),
	Color(0.32, 0.82, 0.52),
	Color(0.30, 0.55, 0.95),
]

const PULSE_PERIOD_SECONDS: float = 1.2
const PULSE_MIN_ALPHA: float = 0.55
const PULSE_MAX_ALPHA: float = 1.0

const BEAM_WIDTH: float = 4.0
const MINE_BURST_PARTICLE_AMOUNT: int = 14
const MINE_BURST_LIFETIME_SECONDS: float = 0.6

const WARP_CORE_FREE_MINUTES: float = 5.0
const WARP_CORE_SPEED_MULTIPLIER: float = 2.0
const WARP_CORE_COST_CREDITS: int = 300


func _ready() -> void:
	pass
