class_name DockManager
extends RefCounted
## DockManager — управление ограниченными доками (Шаг 2: Вертикальный срез).
## Каждый док добывает одну клетку за раз и освобождается по таймеру
## `mine_duration` (секунды), заданному в GameBalance.

class Dock:
	var busy: bool = false
	var timer_left: float = 0.0
	var target: Vector2i = Vector2i(-1, -1)


var docks: Array = []
var mine_duration: float


func _init(dock_count: int, p_mine_duration: float) -> void:
	mine_duration = p_mine_duration
	for i in range(dock_count):
		docks.append(Dock.new())


func get_free_dock_index() -> int:
	for i in range(docks.size()):
		if not docks[i].busy:
			return i
	return -1


func launch(dock_index: int, target: Vector2i) -> bool:
	if dock_index < 0 or dock_index >= docks.size():
		return false
	var dock: Dock = docks[dock_index]
	if dock.busy:
		return false
	dock.busy = true
	dock.timer_left = mine_duration
	dock.target = target
	return true


## Продвигает таймеры всех занятых доков на delta секунд.
## Возвращает список позиций клеток, добыча которых завершилась в этом тике.
func tick(delta: float) -> Array:
	var completed: Array = []
	for dock in docks:
		if dock.busy:
			dock.timer_left -= delta
			if dock.timer_left <= 0.0:
				completed.append(dock.target)
				dock.busy = false
				dock.timer_left = 0.0
				dock.target = Vector2i(-1, -1)
	return completed


func free_count() -> int:
	var count := 0
	for dock in docks:
		if not dock.busy:
			count += 1
	return count


func busy_count() -> int:
	return docks.size() - free_count()
