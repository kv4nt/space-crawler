extends Control
## LoadingScreen — стартовый экран загрузки в стиле Food Hunt.

const MIN_DISPLAY_TIME := 2.0

@onready var _loading_bar: Control = %LoadingBar
@onready var _loading_label: Label = %LoadingLabel

var _target_path: String = ""
var _elapsed: float = 0.0
var _load_progress: float = 0.0
var _scene_ready: bool = false
var _finished: bool = false


func _ready() -> void:
	UiScale.set_menu_mode()
	_target_path = GameState.consume_loading_target()
	var err := ResourceLoader.load_threaded_request(_target_path)
	if err != OK:
		push_error("LoadingScreen: не удалось начать загрузку %s" % _target_path)
		_scene_ready = true
	if AudioService.has_method("play_music"):
		AudioService.play_music(&"menu_music")


func _process(delta: float) -> void:
	if _finished:
		return

	_elapsed += delta
	var progress_arr: Array = []
	var status := ResourceLoader.load_threaded_get_status(_target_path, progress_arr)
	if progress_arr.size() > 0:
		_load_progress = float(progress_arr[0])

	match status:
		ResourceLoader.THREAD_LOAD_LOADED:
			_load_progress = 1.0
			_scene_ready = true
		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			push_error("LoadingScreen: ошибка загрузки %s" % _target_path)
			_scene_ready = true

	var time_progress := _elapsed / MIN_DISPLAY_TIME
	var visual := minf(minf(_load_progress, time_progress), 1.0)
	if _loading_bar.has_method("set_progress"):
		_loading_bar.set_progress(visual)

	var dots := int(_elapsed * 3.0) % 4
	_loading_label.text = "ЗАГРУЗКА" + ".".repeat(dots)

	if visual >= 1.0 and _scene_ready and _elapsed >= MIN_DISPLAY_TIME * 0.85:
		_finish()


func _finish() -> void:
	if _finished:
		return
	_finished = true
	set_process(false)

	var packed: PackedScene = ResourceLoader.load_threaded_get(_target_path)
	if packed == null:
		packed = load(_target_path) as PackedScene
	if packed == null:
		push_error("LoadingScreen: сцена не найдена %s" % _target_path)
		get_tree().change_scene_to_file(GameState.DEFAULT_MENU_SCENE)
		return
	var err := get_tree().change_scene_to_packed(packed)
	if err != OK:
		push_error("LoadingScreen: не удалось сменить сцену (%s): %s" % [err, _target_path])
		get_tree().change_scene_to_file(GameState.DEFAULT_MENU_SCENE)
