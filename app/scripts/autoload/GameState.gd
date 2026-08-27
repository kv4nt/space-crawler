extends Node
## GameState — автозагрузка с runtime-состоянием текущей сессии игрока:
## кредиты, звёзды, открытые уровни, статус форсажа. Этап: Foundation.

var credits: int = 0
var unlocked_level_id: String = ""
var warp_core_seconds_left: float = 0.0


func _ready() -> void:
	pass
