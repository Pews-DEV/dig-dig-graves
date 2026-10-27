class_name FloatingNumbers
extends Node2D
## Números flutuantes (DA §9.2): sobem 12 px em 600 ms e somem em 2 passos.
## Cores (UI/UX §2): normal 22, crítico 26, Osso 21, Alma 30, perda de óleo 32. Contorno 1 px em 01.
## Fonte m6x11 no tamanho nativo ou no dobro (opção "números flutuantes").
## No 2º passo a cor desce 1 degrau na rampa (sem alfa: paleta fechada).

const LIFETIME := 0.6
const STEP2_AT := 0.4
const RISE := 12.0
const DARKER: Dictionary = {22: 21, 26: 25, 21: 15, 30: 5, 25: 24, 32: 31, 29: 28}

var _items: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()


func spawn(origin: Vector2, text: String, color_index: int, jitter: bool = true) -> void:
	var offset := Vector2(_rng.randi_range(-5, 5), _rng.randi_range(-2, 2)) if jitter else Vector2.ZERO
	_items.append({"pos": origin + offset, "text": text, "color": color_index, "age": 0.0})


func clear() -> void:
	_items.clear()
	queue_redraw()


func _process(delta: float) -> void:
	if _items.is_empty():
		return
	for it: Dictionary in _items:
		it.age = float(it.age) + delta
	_items = _items.filter(func(it: Dictionary) -> bool: return float(it.age) < LIFETIME)
	queue_redraw()


func _draw() -> void:
	var font := UiTheme.title_font()
	var scale_i := clampi(int(Game.settings.get("float_scale", 1)), 1, 2)
	var size := UiTheme.SIZE_FLOAT * scale_i
	var outline := Palette.color(Palette.OUTLINE)
	for it: Dictionary in _items:
		var age := float(it.age)
		var rise := floorf(RISE * minf(age / LIFETIME, 1.0))
		var idx := int(it.color)
		if age >= STEP2_AT:
			idx = int(DARKER.get(idx, idx))
		var text: String = it.text
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		var base: Vector2 = it.pos
		var pos := Vector2(roundf(base.x - w * 0.5), roundf(base.y - rise))
		draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, UiTheme.OUTLINE * scale_i, outline)
		draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Palette.color(idx))
