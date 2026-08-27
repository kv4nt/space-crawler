extends Node
## GameBalance — автозагрузка с балансовыми константами игры.
## Этап: Вертикальный срез (Шаг 2). Значения являются временными заглушками
## и будут вынесены в data/balance.json на Этапе 4 (Прогресс), без правки UI/логики.

const GRID_WIDTH: int = 14
const GRID_HEIGHT: int = 14
const DEFAULT_DOCK_COUNT: int = 5
const DEFAULT_COLOR_COUNT: int = 3

const MINE_DURATION_SECONDS: float = 2.0
const TARGET_PER_COLOR: int = 12

const WARP_CORE_FREE_MINUTES: float = 5.0
const WARP_CORE_SPEED_MULTIPLIER: float = 2.0
const WARP_CORE_COST_CREDITS: int = 300


func _ready() -> void:
	pass
