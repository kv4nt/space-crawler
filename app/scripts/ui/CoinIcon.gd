extends Control
class_name CoinIcon
## Компактная золотая монета для HUD, магазина и кнопок.


@export var diameter: int = 20:
	set(value):
		diameter = maxi(value, 10)
		custom_minimum_size = Vector2(diameter, diameter)
		size = custom_minimum_size
		queue_redraw()


func _init(p_diameter: int = 20) -> void:
	diameter = p_diameter
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(diameter, diameter)
	size = custom_minimum_size
	resized.connect(queue_redraw)


func _draw() -> void:
	var radius := minf(size.x, size.y) * 0.44
	GameTheme.draw_coin(self, size * 0.5, radius)
