extends Node
## SaveService — автозагрузка для локального сохранения прогресса.
## Этап: Foundation. Реальная сериализация появится на Этапе 4 (Прогресс).

const SAVE_PATH: String = "user://savegame.json"
const SCHEMA_VERSION: int = 1


func _ready() -> void:
	pass


func load_game() -> Dictionary:
	return {}


func save_game(_data: Dictionary) -> void:
	pass
