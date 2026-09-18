class_name GridCell
extends RefCounted
## Одна клетка pixel-art поля.

enum State { HIDDEN, EXPOSED, EMPTY }
enum Modifier { NONE, FROZEN, FUSED, SEALED }

var color: int = 0
var state: int = State.HIDDEN
var scanned: bool = false

## Спецэффекты минералов (лёд / сплав / печать) — см. AsteroidGrid._apply_special_modifiers().
var modifier: int = Modifier.NONE
var frost_hits: int = 0
var fused_color: int = -1
var seal_signal_color: int = -1
var seal_signal_needed: int = 0
var seal_signal_progress: int = 0


func _init(p_color: int = 0) -> void:
	color = p_color


func is_frozen() -> bool:
	return modifier == Modifier.FROZEN and frost_hits > 0


func is_sealed() -> bool:
	return modifier == Modifier.SEALED and seal_signal_progress < seal_signal_needed


func has_fused_partner() -> bool:
	return modifier == Modifier.FUSED and fused_color >= 0
