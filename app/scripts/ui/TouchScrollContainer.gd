extends ScrollContainer
## Прокрутка жестом поверх кнопок и карточек (мобильный магазин).

var _touch_index := -1
var _touch_start_y := 0.0
var _scroll_start := 0.0
var _dragging := false

const DRAG_THRESHOLD := 10.0


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	var rect := get_global_rect()
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and rect.has_point(touch.position):
			_touch_index = touch.index
			_touch_start_y = touch.position.y
			_scroll_start = scroll_vertical
			_dragging = false
		elif not touch.pressed and touch.index == _touch_index:
			_touch_index = -1
			_dragging = false
	elif event is InputEventScreenDrag and event.index == _touch_index:
		var drag := event as InputEventScreenDrag
		var delta := _touch_start_y - drag.position.y
		if not _dragging and absf(delta) > DRAG_THRESHOLD:
			_dragging = true
		if _dragging:
			scroll_vertical = int(_scroll_start + delta)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed and rect.has_point(mb.position):
				_touch_index = 0
				_touch_start_y = mb.position.y
				_scroll_start = scroll_vertical
				_dragging = false
			elif not mb.pressed and _touch_index == 0:
				_touch_index = -1
				_dragging = false
	elif event is InputEventMouseMotion and _touch_index == 0:
		if not (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):
			return
		var motion := event as InputEventMouseMotion
		var delta := _touch_start_y - motion.position.y
		if not _dragging and absf(delta) > DRAG_THRESHOLD:
			_dragging = true
		if _dragging:
			scroll_vertical = int(_scroll_start + delta)
			get_viewport().set_input_as_handled()
