extends Node
## LevelService — загрузка и валидация уровней из GameBalance (JSON позже).


func load_level(level_id: int) -> Dictionary:
	return GameBalance.get_level_by_global_id(level_id)


func validate_level(data: Dictionary) -> bool:
	return data.has("id") and data.has("width") and data.has("height")
