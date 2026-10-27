class_name TitleWisp
extends Node2D
## Cursor do menu (UI/UX §9.4): um fogo-fátuo (MANIFEST fogo_fatuo, 8×8, pivô (4, 4), 8 fps)
## flutua ao lado do botão em foco e desliza até o próximo quando o foco muda.

const FRAMES: Array[float] = [0.125, 0.125, 0.125, 0.125]
const SLIDE := 0.14
const FLOAT_PX := 2.0

var _tex: Texture2D = TitleArt.texture_path(TitleArt.WISP_PATH)
var _t: float = 0.0
var _tween: Tween


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


## Vai para `target` (deslizando, ou direto se `instant`).
func move_to(target: Vector2, instant: bool = false) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if instant or not visible:
		position = target
		return
	_tween = create_tween()
	_tween.tween_property(self, "position", target, SLIDE).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	var bob := Vector2(0, roundf(sin(_t * 3.0) * FLOAT_PX * Juice.motion()))
	var p := (bob - Vector2(4, 4)).round()
	var f := TreeArt.frame_at(_t, FRAMES)
	if _tex != null:
		draw_texture_rect_region(_tex, Rect2(p, Vector2(8, 8)), Rect2(f * 8, 0, 8, 8))
		return
	# Placeholder: halo 27, corpo 28, núcleo 29/23.
	draw_rect(Rect2(p + Vector2(2, 1), Vector2(4, 6)), Palette.color(Palette.ECTO_DARK))
	draw_rect(Rect2(p + Vector2(1, 2), Vector2(6, 4)), Palette.color(Palette.ECTO_DARK))
	draw_rect(Rect2(p + Vector2(2, 2), Vector2(4, 4)), Palette.color(Palette.ECTO))
	draw_rect(Rect2(p + Vector2(3, 3 - (f % 2)), Vector2(2, 2)), Palette.color(Palette.ECTO_BRIGHT))
	draw_rect(Rect2(p + Vector2(3, 3), Vector2(1, 1)), Palette.color(Palette.BONE_BRIGHT))
