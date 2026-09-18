class_name GridCell
extends RefCounted
## Одна клетка pixel-art поля.

enum State { HIDDEN, EXPOSED, EMPTY }

var color: int = 0
var state: int = State.HIDDEN
var scanned: bool = false


func _init(p_color: int = 0) -> void:
	color = p_color
