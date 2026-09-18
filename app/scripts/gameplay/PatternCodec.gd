class_name PatternCodec
extends RefCounted
## Кодирование индекса цвета/уровня палитры в одном символе (0–9, a–j → 10–19).


static func tier_from_char(ch: String) -> int:
	if ch.is_empty() or ch == "." or ch == " ":
		return -1
	if ch.is_valid_int():
		return int(ch)
	var code := ch.unicode_at(0)
	if code >= 97 and code <= 106:
		return code - 97 + 10
	if code >= 65 and code <= 74:
		return code - 65 + 10
	return 0


static func char_from_tier(tier: int) -> String:
	tier = clampi(tier, 0, GameBalance.MAX_MINERAL_COLORS - 1)
	if tier < 10:
		return str(tier)
	return char(97 + tier - 10)
