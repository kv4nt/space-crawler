extends Control
class_name ColorVendingReel
## Одна колонка автомата: до 5 видимых ячеек, стек прокручивается снизу.


signal stack_refreshed(col: int)

var column_index: int = 0
var _cell_size: int = 56
var _gap: int = 4
var _inner: VBoxContainer
var _make_chip: Callable
var _game_over: bool = false
var _top_button: Control
var _visible_rows: int = 0


func _init() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_PASS


func configure(
	col_idx: int, cell_size: int, gap: int, make_chip_fn: Callable, _make_empty_fn: Callable,
) -> void:
	column_index = col_idx
	_cell_size = cell_size
	_gap = gap
	_make_chip = make_chip_fn
	if _inner == null:
		_inner = VBoxContainer.new()
		_inner.name = "InnerStack"
		_inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_inner.add_theme_constant_override("separation", _gap)
		add_child(_inner)


func set_game_over(on: bool) -> void:
	_game_over = on


func get_top_button() -> Control:
	return _top_button


func refresh_stack(stack: Array, instant: bool = true) -> void:
	_fill_inner(stack)
	if instant:
		_inner.position.y = 0.0
	stack_refreshed.emit(column_index)


func animate_scroll_after_pop(stack: Array, duration: float = 0.26) -> void:
	if duration <= 0.0:
		refresh_stack(stack, true)
		return
	var row_h := _row_height()
	_fill_inner(stack)
	_inner.position.y = row_h
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_inner, "position:y", 0.0, duration)
	tween.tween_callback(func() -> void:
		stack_refreshed.emit(column_index)
	)


func _viewport_height(rows: int) -> float:
	if rows <= 0:
		return 0.0
	return float(_cell_size * rows + _gap * (rows - 1))


func _row_height() -> float:
	return float(_cell_size + _gap)


func _fill_inner(stack: Array) -> void:
	for child in _inner.get_children():
		child.queue_free()
	_top_button = null

	_visible_rows = ColorVending.visible_row_count(stack.size())
	custom_minimum_size = Vector2(_cell_size, _viewport_height(_visible_rows))

	if stack.is_empty():
		_inner.position.y = 0.0
		return

	for i in range(stack.size() - 1, -1, -1):
		var chip: Dictionary = stack[i]
		var launches := int(chip.get("launches", 0))
		var color_idx := int(chip.get("color", 0))
		var is_top := i == stack.size() - 1
		var row_from_top := stack.size() - 1 - i
		var node: Control = _make_chip.call(launches, color_idx, is_top, column_index, row_from_top)
		if is_top:
			_top_button = node
			if node is BaseButton:
				(node as BaseButton).disabled = _game_over
		_inner.add_child(node)
