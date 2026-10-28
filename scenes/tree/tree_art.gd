class_name TreeArt
extends RefCounted
## Arte da Árvore aconchegante (MANIFEST tree_* / fx_tree_*). Mundo de 1936×1024.
## Cada textura vem do manifesto; ausente = null e quem desenha usa o placeholder.

const DIR := "res://assets/ui/tree/"
const WORLD := Vector2(1936, 1024)
const GRASS_Y := 176
const TRUNK_ROOT := Vector2(968, 212)  # ponta central do tronco, ligada ao N00
const SOIL_POS := Vector2(0, 64)  # asset antigo começa a desenhar o solo na linha y=112.
const SKY_PARALLAX := 0.5
const CANOPY_POS := Vector2(760, 64)
const CANOPY_FRAME := Vector2(416, 100)
const TRUNK_POS := Vector2(896, 100)
const GRASS_POS := Vector2(0, 168)

static var _cache: Dictionary = {}


static func tex(file: String) -> Texture2D:
	if not _cache.has(file):
		_cache[file] = AssetManifest.texture(DIR + file)
	return _cache[file] as Texture2D


## Desenha a célula (col, row) de uma folha com o pivô em `pos`; `flip` espelha na horizontal.
static func draw_cell(ci: CanvasItem, t: Texture2D, frame: Vector2, col: int, row: int, pos: Vector2, pivot: Vector2 = Vector2.ZERO, flip: bool = false) -> void:
	if t == null:
		return
	var src := Rect2(Vector2(col, row) * frame, frame)
	if flip:
		ci.draw_set_transform(pos.round(), 0.0, Vector2(-1, 1))
		ci.draw_texture_rect_region(t, Rect2(-pivot, frame), src)
		ci.draw_set_transform(Vector2.ZERO)
	else:
		ci.draw_texture_rect_region(t, Rect2((pos - pivot).round(), frame), src)


## Frame de uma animação com durações (s) em loop.
static func frame_at(t: float, durations: Array[float]) -> int:
	var total := 0.0
	for d: float in durations:
		total += d
	var x := fmod(t, total)
	for i: int in durations.size():
		if x < durations[i]:
			return i
		x -= durations[i]
	return durations.size() - 1


## Ping-pong de n frames com duração fixa (copa: 0,1,2,1,0…).
static func pingpong(t: float, n: int, each: float) -> int:
	if n <= 1:
		return 0
	var period := (n - 1) * 2
	var i := int(t / each) % period
	return i if i < n else period - i
