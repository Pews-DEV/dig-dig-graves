class_name PixelBar
extends Control
## Barra lisa com contorno 01 (HUD: óleo, XP). Cores sempre da paleta.

@export_range(0.0, 1.0) var value: float = 1.0:
	set(v):
		var clamped := clampf(v, 0.0, 1.0)
		if not is_equal_approx(clamped, value):
			value = clamped
			queue_redraw()
@export var fill_color: int = Palette.LANTERN:
	set(v):
		if v != fill_color:
			fill_color = v
			queue_redraw()
@export var back_color: int = Palette.BG
@export var highlight_color: int = 0
## Preenchimento em textura (MANIFEST barra_oleo/_alerta/_xp/_inquietacao). Vazio = cor sólida.
var fill_texture_path: String = "":
	set(v):
		fill_texture_path = v
		_fill_tex = AssetManifest.texture(v) if not v.is_empty() else null
		queue_redraw()
var frame_texture_path: String = "res://assets/ui/hud/barra_moldura.png"
var frame_margin: int = 3

## Cor sólida que substitui a textura de preenchimento (alertas pulsando). 0 = desligado.
var override_color: int = 0:
	set(v):
		if v != override_color:
			override_color = v
			queue_redraw()
## Varredura de brilho (subir de nível): 0..1 = posição da faixa; < 0 = desligada.
var sweep: float = -1.0:
	set(v):
		sweep = v
		queue_redraw()

const TIP_COLOR := Palette.BONE_BRIGHT  # UI/UX §3: ponta do preenchimento com 1 px de brilho 23
const FRAME_PATH := "res://assets/ui/hud/barra_moldura.png"
## MANIFEST barra_moldura: margens 3; preenchimento a partir de (3,3), altura 4.
const FRAME_MARGIN := 3
const FILL_HEIGHT := 4
## Altura da barra quando a moldura de arte está disponível.
const ART_HEIGHT := 10

static var _frame_styles: Dictionary = {}
var _fill_tex: Texture2D


static func frame_style(texture_path: String = FRAME_PATH, margin: int = FRAME_MARGIN) -> StyleBoxTexture:
	var key := "%s:%d" % [texture_path, margin]
	if _frame_styles.has(key):
		return _frame_styles[key] as StyleBoxTexture
	var style: StyleBoxTexture
	var tex := AssetManifest.texture(texture_path)
	if tex != null:
		style = StyleBoxTexture.new()
		style.texture = tex
		style.set_texture_margin_all(margin)
	_frame_styles[key] = style
	return style


static func uses_art() -> bool:
	return frame_style() != null


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size.floor())
	var style := frame_style(frame_texture_path, frame_margin)
	var fill_rect: Rect2
	var inner_w: float
	if style != null:
		draw_style_box(style, r)
		inner_w = r.size.x - frame_margin * 2
		fill_rect = Rect2(frame_margin, frame_margin, floorf(inner_w * value), FILL_HEIGHT)
	else:
		draw_rect(r, Palette.color(Palette.OUTLINE))
		var inner := r.grow(-1)
		draw_rect(inner, Palette.color(back_color))
		inner_w = inner.size.x
		fill_rect = Rect2(inner.position, Vector2(floorf(inner.size.x * value), inner.size.y))
	if fill_rect.size.x > 0.0:
		if override_color > 0:
			draw_rect(fill_rect, Palette.color(override_color))
		elif _fill_tex != null and style != null:
			draw_texture_rect(_fill_tex, fill_rect, false)
		else:
			draw_rect(fill_rect, Palette.color(fill_color))
			if highlight_color > 0:
				draw_rect(Rect2(fill_rect.position, Vector2(fill_rect.size.x, 1)), Palette.color(highlight_color))
		if fill_rect.size.x >= 2.0 and value < 1.0:
			draw_rect(Rect2(fill_rect.end.x - 1, fill_rect.position.y, 1, fill_rect.size.y), Palette.color(TIP_COLOR))
	if sweep >= 0.0:
		var x := fill_rect.position.x + floorf((inner_w + 4.0) * sweep) - 2.0
		var band := Rect2(x, fill_rect.position.y, 2, fill_rect.size.y).intersection(Rect2(fill_rect.position, Vector2(inner_w, fill_rect.size.y)))
		if band.size.x > 0.0:
			draw_rect(band, Palette.color(TIP_COLOR))
