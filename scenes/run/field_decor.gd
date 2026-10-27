class_name FieldDecor
extends Node2D
## Enfeites vivos em volta do diorama (UI/UX §5): velas tremulando, crisântemos e tufos
## balançando nas quinas, e fogos-fátuos ambientes (decorativos, mais escuros que os coletáveis).
## Tudo fora da grade jogável.

const VELAS_PATH := "res://assets/sprites/props/velas_grupo.png"
const VELA_PATH := "res://assets/sprites/props/vela.png"
const CRIS_PATH := "res://assets/sprites/props/crisantemo.png"
const WISP_COUNT := 4
## MANIFEST tufos_a1: células 12×8 (coluna = frame, linha = variante), pivô (6, 7), ~500 ms.
const TUFOS_PATH := "res://assets/sprites/bg/a1/tufos_a1.png"
## MANIFEST placa_a1: células 56×26, pivô (28, 25); coluna 0 = "PARÓQUIA".
const PLACA_PATH := "res://assets/sprites/bg/a1/placa_a1.png"

var block: DioramaBlock
var _velas: Texture2D = AssetManifest.texture(VELAS_PATH)
var _vela: Texture2D = AssetManifest.texture(VELA_PATH)
var _cris: Texture2D = AssetManifest.texture(CRIS_PATH)
var _tufos: Texture2D = AssetManifest.texture(TUFOS_PATH)
var _placa: Texture2D = AssetManifest.texture(PLACA_PATH)
var _t: float = 0.0
var _items: Array[Dictionary] = []
var _wisps: Array[Dictionary] = []


func setup(p_block: DioramaBlock) -> void:
	block = p_block
	_items.clear()
	var l := block.corner_left()
	var r := block.corner_right()
	var b := block.corner_bottom()
	var ground_l := float(block.base_y(block.min_x))
	var ground_r := float(block.base_y(block.max_x))
	var ground_b := float(block.base_y(block.split_x))
	_items.append({"kind": "placa", "pos": Vector2(l.x - 34, l.y + 30), "phase": 0})
	_items.append({"kind": "velas", "pos": Vector2(l.x - 12, ground_l + 1), "phase": 0})
	_items.append({"kind": "cris", "pos": Vector2(l.x - 24, ground_l + 3), "phase": 0})
	_items.append({"kind": "tuft", "pos": Vector2(l.x - 4, ground_l + 2), "phase": 0})
	_items.append({"kind": "vela", "pos": Vector2(r.x + 10, ground_r + 1), "phase": 1})
	_items.append({"kind": "cris", "pos": Vector2(r.x + 20, ground_r + 4), "phase": 0})
	_items.append({"kind": "tuft", "pos": Vector2(r.x + 2, ground_r + 2), "phase": 2})
	_items.append({"kind": "tuft", "pos": Vector2(b.x - 30, ground_b - 12), "phase": 1})
	_items.append({"kind": "vela", "pos": Vector2(b.x + 34, ground_b - 10), "phase": 2})
	_items.append({"kind": "tuft", "pos": Vector2(b.x + 46, ground_b - 16), "phase": 3})
	var count := maxi(1, roundi(WISP_COUNT * Juice.motion()))
	for i: int in count:
		var base := l + Vector2(-30, -26) if i % 2 == 0 else r + Vector2(28, -30)
		_wisps.append({"base": base + Vector2(randf_range(-14, 14), randf_range(-10, 10)), "phase": randf() * TAU, "speed": randf_range(0.3, 0.6)})


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	for it: Dictionary in _items:
		var pos: Vector2 = (it.pos as Vector2).round()
		var frame := (int(_t * 8.0) + int(it.phase)) % 3
		match String(it.kind):
			"velas":
				if _velas != null:
					draw_texture_rect_region(_velas, Rect2(pos - Vector2(8, 11), Vector2(16, 12)), Rect2(frame * 16, 0, 16, 12))
			"vela":
				if _vela != null:
					draw_texture_rect_region(_vela, Rect2(pos - Vector2(4, 11), Vector2(8, 12)), Rect2(frame * 8, 0, 8, 12))
			"cris":
				if _cris != null:
					draw_texture(_cris, pos - Vector2(4, 9))
			"tuft":
				_draw_tuft(pos, it)
			"placa":
				if _placa != null:
					draw_texture_rect_region(_placa, Rect2(pos - Vector2(28, 25), Vector2(56, 26)), Rect2(0, 0, 56, 26))
	for w: Dictionary in _wisps:
		var a := _t * float(w.speed) + float(w.phase)
		var p := ((w.base as Vector2) + Vector2(sin(a) * 6.0, sin(a * 1.7) * 3.0) * Juice.motion()).round()
		var bright := int(_t * 3.0 + float(w.phase)) % 4 == 0
		draw_rect(Rect2(p + Vector2(-1, -1), Vector2(3, 3)), Palette.color(Palette.ECTO_DARK))
		draw_rect(Rect2(p, Vector2(1, 1)), Palette.color(Palette.ECTO if bright else Palette.ECTO_DARK))


## Tufo de grama balançando com a brisa (2 frames; a onda atravessa pela fase).
func _draw_tuft(pos: Vector2, it: Dictionary) -> void:
	var sway := 1 if int(_t * 2.0 + float(it.phase) * 0.5) % 2 == 0 and not Juice.reduce_motion() else 0
	if _tufos != null:
		# Onda de brisa: frame defasado pela posição.
		var f := (int(_t * 2.0 + pos.x * 0.02) % 2) if not Juice.reduce_motion() else 0
		draw_texture_rect_region(_tufos, Rect2(pos - Vector2(6, 7), Vector2(12, 8)), Rect2(f * 12, (int(it.phase) % 3) * 8, 12, 8))
		return
	var dark := Palette.color(Palette.GRASS_DARK)
	var mid := Palette.color(Palette.GRASS)
	var light := Palette.color(Palette.GRASS_LIGHT)
	draw_rect(Rect2(pos + Vector2(-3, -1), Vector2(7, 1)), dark)
	draw_rect(Rect2(pos + Vector2(-2 + sway, -3), Vector2(1, 2)), mid)
	draw_rect(Rect2(pos + Vector2(0 + sway, -5), Vector2(1, 4)), light)
	draw_rect(Rect2(pos + Vector2(2 + sway, -4), Vector2(1, 3)), mid)
	draw_rect(Rect2(pos + Vector2(-1, -2), Vector2(1, 1)), dark)
