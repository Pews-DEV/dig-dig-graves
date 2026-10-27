class_name ArrowGlyph
extends Control
## Seta "→" desenhada em pixel (as fontes não têm o glifo), andando 1 px em loop (UI/UX §7.4).

var color_index: int = Palette.OUTLINE
var _t: float = 0.0


func _init() -> void:
	custom_minimum_size = Vector2(10, 10)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	var before := int(_t / 0.35)
	_t += delta
	if int(_t / 0.35) != before:
		queue_redraw()


func _draw() -> void:
	var dx := (int(_t / 0.35) % 2) if not Juice.reduce_motion() else 0
	var c := Palette.color(color_index)
	var y := floorf(size.y * 0.5)
	draw_rect(Rect2(1 + dx, y, 6, 1), c)
	draw_rect(Rect2(5 + dx, y - 2, 1, 5), c)
	draw_rect(Rect2(6 + dx, y - 1, 1, 3), c)
