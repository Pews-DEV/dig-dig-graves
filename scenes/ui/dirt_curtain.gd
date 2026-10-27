class_name DirtCurtain
extends Control
## Transição de tela "cortina de terra" (UI/UX §6): torrões em xadrez caem de cima cobrindo
## a tela e depois escorrem para baixo revelando a próxima. 450 ms no total.

const TOTAL := 0.45
const EDGE := 8  # faixa de xadrez na borda da terra
const W := 640
const H := 360

## 0..1 = cobrindo; 1..2 = revelando; < 0 = inativa.
var phase: float = -1.0:
	set(v):
		phase = v
		visible = v >= 0.0
		mouse_filter = Control.MOUSE_FILTER_STOP if visible else Control.MOUSE_FILTER_IGNORE
		queue_redraw()

var _pebbles: Array[Vector3i] = []  # x, y, cor
var _clods: Array[Vector3] = []  # x, atraso, tamanho
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	size = Vector2(W, H)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.seed = 7
	var colors: Array[int] = [Palette.DIRT, Palette.DIRT_BOTTOM, Palette.STONE_DARK, Palette.DIRT_LIGHT]
	for i: int in 260:
		_pebbles.append(Vector3i(_rng.randi_range(0, W - 2), _rng.randi_range(0, H - 2), colors[_rng.randi() % colors.size()]))
	for i: int in 70:
		_clods.append(Vector3(_rng.randi_range(0, W - 3), _rng.randf_range(0.0, 0.35), _rng.randi_range(1, 3)))
	phase = -1.0


## Cobre a tela (metade do tempo). Aguarde o sinal `finished` do tween retornado.
func cover() -> Tween:
	phase = 0.0
	Audio.play(&"screen_transition")
	var t := create_tween()
	t.tween_property(self, "phase", 1.0, TOTAL * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	return t


func reveal() -> Tween:
	phase = 1.0
	var t := create_tween()
	t.tween_property(self, "phase", 2.0, TOTAL * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(func() -> void: phase = -1.0)
	return t


func _draw() -> void:
	if phase < 0.0:
		return
	var top := 0
	var bottom := 0
	if phase <= 1.0:
		bottom = roundi(phase * (H + EDGE))
	else:
		top = roundi((phase - 1.0) * (H + EDGE))
		bottom = H + EDGE
	var solid_top := top + (EDGE if top > 0 else 0)
	var solid_bottom := bottom - EDGE
	if solid_bottom > solid_top:
		draw_rect(Rect2(0, solid_top, W, solid_bottom - solid_top), Palette.color(Palette.DIRT_DARK))
		for p: Vector3i in _pebbles:
			if p.y >= solid_top and p.y < solid_bottom - 1:
				draw_rect(Rect2(p.x, p.y, 2, 1), Palette.color(p.z))
	# Bordas em xadrez (DA: transições por dithering, sem alfa).
	_checker_band(maxi(bottom - EDGE, top), bottom, Palette.DIRT_DARK)
	if top > 0:
		_checker_band(top, top + EDGE, Palette.DIRT_DARK)
	# Torrões caindo à frente da borda (cobrindo) ou escorrendo (revelando).
	var lead := float(bottom) if phase <= 1.0 else float(H)
	for c: Vector3 in _clods:
		var local := (phase if phase <= 1.0 else phase - 1.0) - c.y
		if local < 0.0:
			continue
		var y := lead + local * 60.0 if phase > 1.0 else lead - 12.0 + local * 40.0
		if phase > 1.0:
			y = float(top) + 4.0 + local * 90.0
		if y < 0.0 or y > H:
			continue
		draw_rect(Rect2(c.x, roundf(y), c.z, c.z), Palette.color(Palette.DIRT if int(c.x) % 3 else Palette.DIRT_LIGHT))


func _checker_band(y0: int, y1: int, idx: int) -> void:
	var c := Palette.color(idx)
	for y: int in range(maxi(y0, 0), mini(y1, H)):
		var density := float(y - y0) / maxf(1.0, float(y1 - y0))
		# Mais cheio perto do miolo: xadrez completo na metade de dentro, esparso na de fora.
		var dense := density > 0.5 if y0 < y1 and phase <= 1.0 else density < 0.5
		var x0 := y % 2
		var step := 2 if dense else 4
		for x: int in range(x0 + (0 if dense or y % 4 < 2 else 2), W, step):
			draw_rect(Rect2(x, y, 1, 1), c)
