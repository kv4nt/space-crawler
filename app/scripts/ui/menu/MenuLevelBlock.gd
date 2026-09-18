extends PanelContainer
class_name MenuLevelBlock
## MenuLevelBlock — фиолетовый блок уровня над «ямой».

var _level_label: Label
var _mode_label: Label
var _pulse: float = 0.0
var _base_offset_top: float = 0.0


func _init() -> void:
	add_theme_stylebox_override("panel", GameTheme.menu_level_block())
	custom_minimum_size = Vector2(220, 220)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	var root := VBoxContainer.new()
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 4)
	add_child(root)

	_level_label = Label.new()
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_label.add_theme_font_size_override("font_size", 34)
	_level_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	_level_label.add_theme_color_override("font_outline_color", Color(0.05, 0.12, 0.35, 0.9))
	_level_label.add_theme_constant_override("outline_size", 6)
	root.add_child(_level_label)

	_mode_label = Label.new()
	_mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mode_label.add_theme_font_size_override("font_size", 22)
	root.add_child(_mode_label)


func _process(delta: float) -> void:
	_pulse += delta
	offset_top = _base_offset_top + sin(_pulse * 2.0) * 4.0


func bind_base_y(offset_y: float) -> void:
	_base_offset_top = offset_y


func set_level(level: int, difficulty: int = GameBalance.LevelDifficulty.NORMAL) -> void:
	if _level_label:
		_level_label.text = "Уровень %d" % level
	if _mode_label:
		match difficulty:
			GameBalance.LevelDifficulty.EXTREME:
				_mode_label.text = "Экстремальный"
				_mode_label.add_theme_color_override("font_color", Color(1.0, 0.52, 0.58))
			GameBalance.LevelDifficulty.HARD:
				_mode_label.text = "Сложный"
				_mode_label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.35))
			_:
				_mode_label.text = "Обычный"
				_mode_label.add_theme_color_override("font_color", Color(0.92, 0.88, 1.0))
