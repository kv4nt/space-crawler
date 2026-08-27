extends Node
## LevelService — автозагрузка для загрузки и валидации уровней
## из data/levels/*.json. Этап: Foundation. Реальная загрузка появится
## на Этапе 4 (Прогресс); на Этапе 2 уровень собирается в коде вручную.


func _ready() -> void:
	pass


func load_level(_id: String) -> Dictionary:
	return {}


func validate_level(_data: Dictionary) -> bool:
	return true
