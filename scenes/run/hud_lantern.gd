class_name HudLantern
extends Control
## Lanterna 24×24 do HUD com chama em 3 frames (UI/UX §4). Em alerta, a chama treme mais rápido.
## Placeholder por código até o kit de UI (lanterna 24 animada) entrar no MANIFEST.

const FPS := 8.0
const FPS_ALERT := 16.0

var alert: bool = false
var _t: float = 0.0
var _frame: int = 0
var _jitter: int = 0
static var _body: ImageTexture


## Referência guardada: o canvas só guarda o RID; sem isto a textura seria liberada.
var _art: Texture2D = AssetManifest.texture(UiKit.LANTERN_PATH)


func _init() -> void:
	custom_minimum_size = Vector2(24, 24)
	size = Vector2(24, 24)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


static func body() -> ImageTexture:
	if _body == null:
		_body = ImageTexture.create_from_image(UiKit.ascii([
			"..........oo............",
			".........o..o...........",
			".........o..o...........",
			".......oooooooo.........",
			"......obbbbbbbbo........",
			".....oaaaaaaaaaao.......",
			".....oc........ao.......",
			".....oc........ao.......",
			".....oc........ao.......",
			".....oc........ao.......",
			".....oc........ao.......",
			".....oc........ao.......",
			".....oc........ao.......",
			".....oc........ao.......",
			".....oc........ao.......",
			".....oaaaaaaaaaao.......",
			"......obbbbbbbbo........",
			"......oaaaaaaaao........",
			".......oooooooo.........",
		], {"o": Palette.OUTLINE, "a": Palette.LANTERN_DARK, "b": Palette.LANTERN, "c": Palette.LANTERN_BRIGHT}))
	return _body


func _process(delta: float) -> void:
	_t += delta
	var fps := FPS_ALERT if alert else FPS
	var f := int(_t * fps) % 3 + (3 if alert else 0)
	if f != _frame:
		_frame = f
		_jitter = randi_range(-1, 1) if alert else 0
		queue_redraw()


func _draw() -> void:
	var art := _art
	if art != null:
		# MANIFEST lanterna: idle = frames 0–2 (125 ms); low = frames 3–5 (~83 ms).
		var f := (3 + int(_t / 0.083) % 3) if alert else int(_t / 0.125) % 3
		draw_texture_rect_region(art, Rect2(0, 0, 24, 24), Rect2(f * 24, 0, 24, 24))
		return
	# Vidro escuro com brilho âmbar, chama 26/23 com núcleo; 3 formas alternadas.
	draw_rect(Rect2(7, 6, 8, 9), Palette.color(Palette.NIGHT))
	draw_rect(Rect2(7, 12, 8, 3), Palette.color(Palette.LANTERN_DARK))
	var cx := 10 + _jitter
	var heights: Array[int] = [6, 5, 7]
	var h := heights[_frame % 3]
	var top := 14 - h
	draw_rect(Rect2(cx, top + 1, 2, h), Palette.color(Palette.LANTERN))
	draw_rect(Rect2(cx - 1, top + 3, 4, h - 3), Palette.color(Palette.LANTERN))
	draw_rect(Rect2(cx, top + 3, 2, h - 3), Palette.color(Palette.LANTERN_BRIGHT))
	draw_rect(Rect2(cx + (_frame % 2), top, 1, 1), Palette.color(Palette.LANTERN_BRIGHT))
	draw_rect(Rect2(cx, top + h - 2, 2, 1), Palette.color(Palette.BONE_BRIGHT))
	draw_texture(body(), Vector2.ZERO)
