extends Node
## VisualFxService — уровень визуальных эффектов (полные / упрощённые / выкл).

signal quality_changed(quality: int)

enum Quality { OFF = 0, REDUCED = 1, FULL = 2 }

const CHIP_FLIGHT_SECONDS: float = 0.34
const SLOT_FILL_SECONDS: float = 0.34
const SLOT_FILL_FROM_EMPTY_SECONDS: float = 0.28
const VENDING_SCROLL_SECONDS: float = 0.26
const SHIP_FADE_SECONDS: float = 0.18

var quality: int = Quality.FULL


func apply_quality(value: int, emit_signal: bool = true) -> void:
	quality = clampi(value, Quality.OFF, Quality.FULL)
	if emit_signal:
		quality_changed.emit(quality)


func set_visual_fx_quality(value: int) -> void:
	apply_quality(value, true)
	SaveService.save_game()


func cycle_visual_fx_quality() -> void:
	set_visual_fx_quality((quality + 1) % (Quality.FULL + 1))


func quality_button_label() -> String:
	match quality:
		Quality.OFF:
			return "ВЫКЛ"
		Quality.REDUCED:
			return "УПРОЩ."
		_:
			return "ПОЛН."


func quality_row_title() -> String:
	return "✨  Эффекты"


func particles_enabled() -> bool:
	return quality != Quality.OFF


func burst_amount() -> int:
	if quality == Quality.OFF:
		return 0
	if quality == Quality.REDUCED:
		return 2
	return GameBalance.MINE_BURST_PARTICLE_AMOUNT


func ship_trail_lite_threshold() -> int:
	if quality != Quality.FULL:
		return 1
	return GameBalance.SHIP_TRAIL_LITE_THRESHOLD


func ship_trail_amount(force_lite: bool) -> int:
	if quality == Quality.OFF:
		return 0
	if quality == Quality.REDUCED or force_lite:
		return GameBalance.SHIP_TRAIL_LITE_AMOUNT
	return GameBalance.SHIP_TRAIL_PARTICLE_AMOUNT


func chip_flight_seconds() -> float:
	return tween_seconds(CHIP_FLIGHT_SECONDS)


func slot_fill_seconds(from_empty: bool) -> float:
	var base := SLOT_FILL_FROM_EMPTY_SECONDS if from_empty else SLOT_FILL_SECONDS
	return tween_seconds(base)


func vending_scroll_seconds() -> float:
	return tween_seconds(VENDING_SCROLL_SECONDS)


func ship_fade_seconds() -> float:
	if quality == Quality.OFF:
		return 0.0
	if quality == Quality.REDUCED:
		return SHIP_FADE_SECONDS * 0.55
	return SHIP_FADE_SECONDS


func tween_seconds(base: float) -> float:
	if quality == Quality.OFF:
		return 0.0
	if quality == Quality.REDUCED:
		return base * 0.55
	return base


func background_anim_enabled() -> bool:
	return quality != Quality.OFF


func decor_anim_enabled() -> bool:
	return quality == Quality.FULL


func hint_glow_enabled() -> bool:
	return quality == Quality.FULL


func star_count_default() -> int:
	if quality == Quality.OFF:
		return 0
	if quality == Quality.REDUCED:
		return 48
	return 120
