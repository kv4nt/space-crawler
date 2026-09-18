extends Node
## Масштаб UI для телефонов. Меню — крупнее; уровень — без глобального зума (иначе поле не влезает).

enum SceneScale { MENU, GAMEPLAY }

const MENU_BOOST := 1.75
const GAMEPLAY_BOOST := 1.0

var scene_scale: SceneScale = SceneScale.MENU
var factor: float = 1.0


func _ready() -> void:
	if not get_tree().root.size_changed.is_connected(_apply):
		get_tree().root.size_changed.connect(_apply)


func set_menu_mode() -> void:
	scene_scale = SceneScale.MENU
	_apply()


func set_gameplay_mode() -> void:
	scene_scale = SceneScale.GAMEPLAY
	_apply()


func _apply() -> void:
	if Engine.is_editor_hint():
		factor = 1.0
		return

	var os_name := OS.get_name()
	if os_name != "Android" and os_name != "iOS":
		factor = 1.0
		_set_root_scale(1.0)
		return

	match scene_scale:
		SceneScale.MENU:
			factor = MENU_BOOST
		SceneScale.GAMEPLAY:
			factor = GAMEPLAY_BOOST

	_set_root_scale(factor)


func _set_root_scale(scale: float) -> void:
	var win: Window = get_tree().root
	if scale <= 1.001:
		win.content_scale_factor = 1.0
		return
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	win.content_scale_factor = scale


static func font(size: int) -> int:
	return int(round(float(size) * UiScale.factor))


static func px(value: float) -> float:
	return value * UiScale.factor


static func vec(value: Vector2) -> Vector2:
	return value * UiScale.factor
