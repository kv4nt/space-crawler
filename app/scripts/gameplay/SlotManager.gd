class_name SlotManager
extends RefCounted
## Слоты Food Hunt: 1 корабль = 1 минерал, до 10 кораблей одного цвета.

const _FleetSlot := preload("res://scripts/gameplay/FleetSlot.gd")
const _MAX_SLOTS := 5
const _DEFAULT_UNLOCKED := 3

var _slots: Array = []
var launch_interval: float
var ships_in_flight: Dictionary = {}
var unlocked_slots: int = _DEFAULT_UNLOCKED
var _rng := RandomNumberGenerator.new()


func _init(initial_unlocked: int, p_launch_interval: float) -> void:
	launch_interval = p_launch_interval
	_rng.randomize()
	for _i in range(_MAX_SLOTS):
		_slots.append(_FleetSlot.new())
	unlocked_slots = clampi(initial_unlocked, 1, _MAX_SLOTS)


func slot_count() -> int:
	return _MAX_SLOTS


func is_slot_unlocked(index: int) -> bool:
	return index >= 0 and index < unlocked_slots


func can_unlock_slot() -> bool:
	return unlocked_slots < _MAX_SLOTS


func unlock_slot() -> bool:
	if not can_unlock_slot():
		return false
	unlocked_slots += 1
	return true


func get_slot(index: int):
	return _slots[index]


func slot_remaining(slot_idx: int) -> int:
	var s = _slots[slot_idx]
	if not s.active:
		return 0
	return s.launch_quota + s.ships_in_flight


func get_free_slot_index() -> int:
	for i in range(unlocked_slots):
		if not _slots[i].active:
			return i
	return -1


func has_color_active(color: int) -> bool:
	for i in range(unlocked_slots):
		var s = _slots[i]
		if s.active and s.color == color:
			return true
	return false


func get_ships_in_flight(color: int) -> int:
	return int(ships_in_flight.get(color, 0))


func on_ship_launched(slot_idx: int, color: int) -> void:
	ships_in_flight[color] = get_ships_in_flight(color) + 1
	if slot_idx >= 0 and slot_idx < _slots.size():
		_slots[slot_idx].ships_in_flight += 1


func on_ship_returned(slot_idx: int, color: int, grid: AsteroidGrid) -> Array:
	ships_in_flight[color] = maxi(get_ships_in_flight(color) - 1, 0)
	if slot_idx >= 0 and slot_idx < _slots.size():
		_slots[slot_idx].ships_in_flight = maxi(_slots[slot_idx].ships_in_flight - 1, 0)
	for i in range(unlocked_slots):
		var s = _slots[i]
		if s.active and s.color == color:
			_update_blocked_state(s, grid)
	return _try_free_slot(slot_idx, grid)


## Возвращает индекс слота или -1 (нет места).
func assign_color(color: int, quota: int = 0) -> int:
	var idx := get_free_slot_index()
	if idx == -1:
		return -1
	var s = _slots[idx]
	s.active = true
	s.color = color
	s.launch_timer = 0.0
	s.blocked = false
	s.launch_quota = maxi(quota, 0)
	s.initial_quota = maxi(quota, 0)
	s.ships_in_flight = 0
	return idx


func tick(delta: float, grid: AsteroidGrid) -> Array:
	var events: Array = []
	for i in range(unlocked_slots):
		var s = _slots[i]
		if not s.active:
			continue

		_update_blocked_state(s, grid)

		if s.blocked:
			continue

		s.launch_timer -= delta
		if s.launch_timer > 0.0:
			continue

		if s.launch_quota <= 0:
			continue

		if get_ships_in_flight(s.color) >= GameBalance.MAX_SHIPS_PER_COLOR:
			continue

		var pos: Variant = grid.get_random_exposed_of_color(s.color, _rng)
		if pos == null:
			_update_blocked_state(s, grid)
			continue

		if not grid.reserve_cell(pos):
			continue

		s.launch_timer = launch_interval
		s.launch_quota -= 1
		events.append({"launch": true, "slot": i, "pos": pos, "color": s.color})

	return events


func on_mineral_collected(slot_index: int, grid: AsteroidGrid) -> Array:
	return _try_free_slot(slot_index, grid)


func _try_free_slot(slot_idx: int, grid: AsteroidGrid) -> Array:
	var events: Array = []
	if slot_idx < 0 or slot_idx >= _slots.size():
		return events
	var s = _slots[slot_idx]
	if not s.active:
		return events
	if s.launch_quota <= 0 and s.ships_in_flight <= 0:
		s.active = false
		s.color = -1
		s.blocked = false
		s.launch_timer = 0.0
		s.launch_quota = 0
		s.initial_quota = 0
		s.ships_in_flight = 0
		events.append({"slot": slot_idx, "freed": true})
	else:
		_update_blocked_state(s, grid)
	return events


func _update_blocked_state(s, grid: AsteroidGrid) -> void:
	if grid.count_filled_of_color(s.color) == 0:
		s.blocked = false
		return
	if s.ships_in_flight > 0:
		s.blocked = false
		return
	s.blocked = not grid.has_collectible_of_color(s.color)


func busy_count() -> int:
	var n := 0
	for i in range(unlocked_slots):
		if _slots[i].active:
			n += 1
	return n


func free_count() -> int:
	return unlocked_slots - busy_count()


func all_full_and_blocked() -> bool:
	if free_count() > 0:
		return false
	for i in range(unlocked_slots):
		var s = _slots[i]
		if s.active and not s.blocked:
			return false
		if s.active and s.ships_in_flight > 0:
			return false
		if s.active and get_ships_in_flight(s.color) > 0:
			return false
	return busy_count() > 0


func get_active_colors() -> Array[int]:
	var result: Array[int] = []
	for i in range(unlocked_slots):
		var s = _slots[i]
		if s.active:
			result.append(s.color)
	return result


func release_first_blocked_slot() -> int:
	for i in range(unlocked_slots):
		var s = _slots[i]
		if s.active and s.blocked:
			s.active = false
			s.color = -1
			s.launch_timer = 0.0
			s.blocked = false
			s.launch_quota = 0
			s.initial_quota = 0
			s.ships_in_flight = 0
			return i
	return -1


func find_slot_for_color(color: int) -> int:
	for i in range(unlocked_slots):
		if _slots[i].active and _slots[i].color == color:
			return i
	return -1


func cancel_launch(slot_idx: int) -> void:
	if slot_idx < 0 or slot_idx >= _slots.size():
		return
	var s = _slots[slot_idx]
	if s.active:
		s.launch_quota += 1


func get_rng() -> RandomNumberGenerator:
	return _rng


func reset() -> void:
	for s in _slots:
		s.active = false
		s.color = -1
		s.launch_timer = 0.0
		s.blocked = false
		s.launch_quota = 0
		s.initial_quota = 0
		s.ships_in_flight = 0
	ships_in_flight.clear()
	unlocked_slots = _DEFAULT_UNLOCKED
