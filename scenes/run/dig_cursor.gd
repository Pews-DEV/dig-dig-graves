class_name DigCursor
extends Node2D
## Pá-cursor placeholder (DA §5: 16×16, ponta da lâmina em (4,14)) desenhada por código.
## Golpe em 4 frames (DA §9.2): sobe · desce · impacto com squash · volta,
## duração = min(250 ms, 80% do intervalo do golpe).

const PIVOT := Vector2i(4, 14)
const FRAME_OFFSETS: Array[int] = [-4, -1, 0, -2]
const REST_OFFSET := -2
const NEIGHBORS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
## MANIFEST cursor_pa: frame 16×16; 0 = idle, 1–4 = act. Pivô (4,14) fixo no frame.
const TEXTURE_PATH := "res://assets/sprites/fx/cursor_pa.png"
const FRAME_SIZE := Vector2(16, 16)

var _texture: Texture2D = AssetManifest.texture(TEXTURE_PATH)
## MANIFEST cursor_pa24 (UI/UX §5.1): frame 24×24, pivô fixo (3, 20) = ponta no idle/impacto.
## idle = frames 0–1 (167 ms, loop); act = frames 2–6 (5 frames; duração = min(250 ms, 80% do intervalo)).
const TEXTURE24_PATH := "res://assets/sprites/fx/cursor_pa24.png"
const FRAME24 := Vector2(24, 24)
const PIVOT24 := Vector2(3, 20)
const IDLE24 := 0.167
var _texture24: Texture2D = AssetManifest.texture(TEXTURE24_PATH)
var _idle_t: float = 0.0

var _strike_time: float = -1.0
var _strike_len: float = 0.25


func strike(pulse_interval: float) -> void:
	_strike_len = minf(0.25, pulse_interval * 0.8)
	_strike_time = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	if _texture24 != null and _strike_time < 0.0:
		var before := int(_idle_t / IDLE24)
		_idle_t += delta
		if int(_idle_t / IDLE24) != before:
			queue_redraw()
	if _strike_time >= 0.0:
		_strike_time += delta
		if _strike_time >= _strike_len:
			_strike_time = -1.0
		queue_redraw()


func _frame() -> int:
	if _strike_time < 0.0:
		return -1
	return clampi(int(_strike_time / (_strike_len / 4.0)), 0, 3)


func _draw() -> void:
	if _texture24 != null:
		var f24 := int(_idle_t / IDLE24) % 2
		if _strike_time >= 0.0:
			f24 = 2 + clampi(int(_strike_time / (_strike_len / 5.0)), 0, 4)
		draw_texture_rect_region(_texture24, Rect2(-PIVOT24, FRAME24), Rect2(Vector2(f24 * FRAME24.x, 0), FRAME24))
		return
	var frame := _frame()
	if _texture != null:
		var index := 0 if frame < 0 else frame + 1
		draw_texture_rect_region(_texture, Rect2(-Vector2(PIVOT), FRAME_SIZE), Rect2(Vector2(index * FRAME_SIZE.x, 0), FRAME_SIZE))
		return
	var dy := REST_OFFSET if frame < 0 else FRAME_OFFSETS[frame]
	var px := _pixels(frame == 2)
	var origin := Vector2(-PIVOT.x, -PIVOT.y + dy)
	var outline := Palette.color(Palette.OUTLINE)
	# Contorno seletivo 01 (DA §2.2): pinta os vizinhos de cada pixel antes do preenchimento.
	for p: Vector2i in px:
		for d: Vector2i in NEIGHBORS:
			draw_rect(Rect2(origin + Vector2(p + d), Vector2.ONE), outline)
	for p: Vector2i in px:
		draw_rect(Rect2(origin + Vector2(p), Vector2.ONE), Palette.color(int(px[p])))


## Mapa pixel → índice da paleta. Squash: lâmina mais larga e mais baixa.
func _pixels(squash: bool) -> Dictionary:
	var px: Dictionary = {}
	for k: int in 7:
		px[Vector2i(12 - k, 1 + k)] = Palette.DIRT_EDGE
	for x: int in range(11, 14):
		px[Vector2i(x, 0)] = Palette.DIRT_LIGHT
	px[Vector2i(5, 8)] = Palette.STONE_DARK
	var top := 10 if squash else 9
	var x0 := 1 if squash else 2
	var x1 := 7 if squash else 6
	for y: int in range(top, 14):
		for x: int in range(x0, x1 + 1):
			px[Vector2i(x, y)] = Palette.STONE
		px[Vector2i(x0, y)] = Palette.STONE_LIGHT
		px[Vector2i(x1, y)] = Palette.STONE_DARK
	for x: int in range(x0 + 1, x1):
		px[Vector2i(x, 14)] = Palette.STONE
	return px
