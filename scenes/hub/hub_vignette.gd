class_name HubVignette
extends Control
## Vinheta de 200 ms ao Enfrentar o chefe (UI/UX §10, fluxo "[Enfrentar / F] ─ vinheta 200 ms ►
## [cortina] ► NOITE DO CHEFE"). Escurece as bordas em 2 degraus de xadrez (sem alfa) e bloqueia
## cliques enquanto dura.

signal finished()

const VIGNETTE_PATH := "res://assets/sprites/bg/a1/vinheta.png"
const DURATION := 0.2
const W := 640
const H := 360
## Espessura (px) da borda escura de cada degrau no placeholder / reforço.
const STEP_EDGE: Array[int] = [28, 56]

static var _fallback: ImageTexture

var _art: Texture2D = AssetManifest.texture(VIGNETTE_PATH)
var _t: float = 0.0
var _done: bool = false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	size = Vector2(W, H)
	z_index = 50
	mouse_filter = Control.MOUSE_FILTER_STOP
	if _fallback == null:
		_fallback = ImageTexture.create_from_image(_edge_image(STEP_EDGE[0]))


## Toca a vinheta e espera terminar.
func play() -> void:
	_t = 0.0
	_done = false
	queue_redraw()
	await finished


func _process(delta: float) -> void:
	if _done:
		return
	var step_before := _step()
	_t += delta
	if _step() != step_before:
		queue_redraw()
	if _t >= DURATION:
		_done = true
		finished.emit()


## 0 na primeira metade, 1 na segunda (2 degraus em 200 ms).
func _step() -> int:
	return 0 if _t < DURATION * 0.5 else 1


func _draw() -> void:
	var base: Texture2D = _art if _art != null else _fallback
	draw_texture(base, Vector2.ZERO)
	if _step() >= 1:
		# 2º degrau: mais uma passada da vinheta + faixa sólida 01 nas bordas.
		draw_texture(base, Vector2.ZERO)
		var c := Palette.color(Palette.OUTLINE)
		var e := 6.0
		draw_rect(Rect2(0, 0, W, e), c)
		draw_rect(Rect2(0, H - e, W, e), c)
		draw_rect(Rect2(0, 0, e, H), c)
		draw_rect(Rect2(W - e, 0, e, H), c)


## Placeholder da `vinheta`: bordas em xadrez 01, mais denso perto da borda (paleta fechada).
static func _edge_image(edge: int) -> Image:
	var img := Image.create_empty(W, H, false, Image.FORMAT_RGBA8)
	var dark := Palette.color(Palette.OUTLINE)
	for y: int in H:
		for x: int in W:
			var d := mini(mini(x, W - 1 - x), mini(y, H - 1 - y))
			if d >= edge:
				continue
			if float(d) < float(edge) / 3.0 or (x + y) % 2 == 0:
				img.set_pixel(x, y, dark)
	return img
