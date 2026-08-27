class_name GridCell
extends RefCounted
## GridCell — данные одной клетки поля добычи. Шаг 2: Вертикальный срез.
## Состояния: hidden -> revealed -> exposed -> mined.

enum State { HIDDEN, REVEALED, EXPOSED, MINED }

var color: int = -1
var state: int = State.HIDDEN
var assigned_dock: int = -1


func _init(p_color: int = -1) -> void:
	color = p_color
