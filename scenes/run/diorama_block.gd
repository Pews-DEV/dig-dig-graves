class_name DioramaBlock
extends Node2D
## O campo como diorama de brinquedo (UI/UX §1.4, §5.4–5.5): bloco de terra iso sob o losango
## jogável, com estratos nas duas faces (luz NO: face esquerda mais clara) e cerquinha de ferro
## em trechos nas bordas de trás. Desenhado atrás dos tiles; nada invade a grade.
## Placeholder por código até o bloco modular entrar no MANIFEST.

const DEPTH := 24  # UI/UX §5: altura de ~24 px
const FENCE_H := 6
## MANIFEST bloco_a1: 9 peças 32×56, pivô (16, 16) = pivô do tile; desenhar depois dos tiles.
const BLOCK_PATH := "res://assets/sprites/bg/a1/bloco_a1.png"
const BLOCK_CELL := Vector2(32, 56)
## MANIFEST cerca_a1: células 32×32, pivô (16, 24); 0 = borda NO, 1 = borda NE, 2 = poste de quina.
const FENCE_PATH := "res://assets/sprites/bg/a1/cerca_a1.png"
const FENCE_CELL := Vector2(32, 32)
const FENCE_PIVOT := Vector2(16, 24)

## BACK = atrás dos tiles (cerca; faces por código se não houver arte); FRONT = peças do bloco.
enum Mode { BACK, FRONT }
var mode: Mode = Mode.BACK
var _block_tex: Texture2D = AssetManifest.texture(BLOCK_PATH)
var _fence_tex: Texture2D = AssetManifest.texture(FENCE_PATH)

var tiles: TileMapLayer
var n: int = 0
## Coluna (px) → [y do topo do losango, y da base do losango].
var columns: Dictionary = {}
var min_x: int = 0
var max_x: int = 0
var split_x: int = 0  # coluna da ponta de baixo: esquerda/direita


func setup(p_tiles: TileMapLayer, size: int) -> void:
	tiles = p_tiles
	n = size
	columns.clear()
	min_x = 1 << 20
	max_x = -(1 << 20)
	for gx: int in n:
		for gy: int in n:
			var c := Vector2i(tiles.map_to_local(Vector2i(gx, gy)))
			for u: int in range(-16, 16):
				var need := u + 1 if u >= 0 else -u
				var dy := mini(7, (16 - need) >> 1)
				var px := c.x + u
				var top := c.y - dy
				var bottom := c.y + dy
				if columns.has(px):
					var cur: Vector2i = columns[px]
					columns[px] = Vector2i(mini(cur.x, top), maxi(cur.y, bottom))
				else:
					columns[px] = Vector2i(top, bottom)
				min_x = mini(min_x, px)
				max_x = maxi(max_x, px)
	split_x = int(tiles.map_to_local(Vector2i(n - 1, n - 1)).x)
	queue_redraw()


## Base do bloco (y da última linha da face) na coluna `px`.
func base_y(px: int) -> int:
	var c: Vector2i = columns.get(px, Vector2i.ZERO)
	return c.y + DEPTH


func corner_left() -> Vector2:
	var c: Vector2i = columns.get(min_x, Vector2i.ZERO)
	return Vector2(min_x, c.y)


func corner_right() -> Vector2:
	var c: Vector2i = columns.get(max_x, Vector2i.ZERO)
	return Vector2(max_x, c.y)


func corner_bottom() -> Vector2:
	var c: Vector2i = columns.get(split_x, Vector2i.ZERO)
	return Vector2(split_x, c.y)


func corner_top() -> Vector2:
	var c: Vector2i = columns.get(split_x, Vector2i.ZERO)
	return Vector2(split_x, c.x)


func has_block_art() -> bool:
	return _block_tex != null


func _draw() -> void:
	if columns.is_empty():
		return
	if mode == Mode.FRONT:
		if _block_tex != null:
			_draw_block_art()
		return
	if _fence_tex != null:
		_draw_fence_art()
	if _block_tex != null:
		return
	_draw_shadow()
	for px: int in range(min_x, max_x + 1):
		var col: Vector2i = columns[px]
		var left := px < split_x
		var edge := px == min_x or px == max_x
		for d: int in DEPTH:
			var y := col.y + 1 + d
			var idx := _stratum(px, d, left)
			if edge or d == DEPTH - 1:
				idx = Palette.OUTLINE
			if idx > 0:
				draw_rect(Rect2(px, y, 1, 1), Palette.color(idx))
	_draw_fence()


## Montagem N×N do MANIFEST: borda SO = tiles (i, N−1), borda SE = tiles (N−1, j).
func _draw_block_art() -> void:
	for i: int in n:
		var col := 3 if i == 0 else (8 if i == n - 1 else i % 3)
		_piece(Vector2i(i, n - 1), col)
	for j: int in n - 1:
		_piece(Vector2i(n - 1, j), 7 if j == 0 else 4 + j % 3)


func _piece(cell: Vector2i, col: int) -> void:
	var origin := tiles.map_to_local(cell) - Vector2(16, 16)
	draw_texture_rect_region(_block_tex, Rect2(origin, BLOCK_CELL), Rect2(Vector2(col * BLOCK_CELL.x, 0), BLOCK_CELL))


## Cerquinha em trechos nas bordas de trás (4 tiles com, 2 sem) e poste no vértice de trás.
func _draw_fence_art() -> void:
	for k: int in range(1, n):
		if k % 6 >= 4:
			continue
		_fence(Vector2i(0, k), 0)
		_fence(Vector2i(k, 0), 1)
	var top := tiles.map_to_local(Vector2i.ZERO) - Vector2(0, 8)
	draw_texture_rect_region(_fence_tex, Rect2(top - Vector2(16, 31), FENCE_CELL), Rect2(Vector2(2 * FENCE_CELL.x, 0), FENCE_CELL))


func _fence(cell: Vector2i, col: int) -> void:
	var origin := tiles.map_to_local(cell) - FENCE_PIVOT
	draw_texture_rect_region(_fence_tex, Rect2(origin, FENCE_CELL), Rect2(Vector2(col * FENCE_CELL.x, 0), FENCE_CELL))


## Sombra do bloco no chão (01), deslocada para baixo-direita (luz NO).
func _draw_shadow() -> void:
	for px: int in range(min_x + 6, max_x + 7):
		var src := clampi(px - 6, min_x, max_x)
		var y := base_y(src) + 2
		draw_rect(Rect2(px, y - 3, 1, 4), Palette.color(Palette.OUTLINE))


## Estratos: grama 10/11 · terra 14/15 · barro 13 · pedrinhas 06, transições em xadrez.
func _stratum(px: int, d: int, left: bool) -> int:
	var odd := (px + d) % 2 == 0
	var h := (px * 73 + d * 151) % 97
	if d <= 2:
		if d == 0 and left:
			return Palette.GRASS_LIGHT if px % 3 != 0 else Palette.GRASS
		return Palette.GRASS if left else Palette.GRASS_DARK
	if d == 3:
		return (Palette.GRASS if left else Palette.GRASS_DARK) if odd else (Palette.DIRT if left else Palette.DIRT_DARK)
	if d <= 12:
		if h < 4:
			return Palette.STONE_DARK
		return Palette.DIRT if left else Palette.DIRT_DARK
	if d == 13:
		return (Palette.DIRT if left else Palette.DIRT_DARK) if odd else (Palette.DIRT_DARK if left else Palette.DIRT_BOTTOM)
	if d >= DEPTH - 3 and odd:
		return Palette.OUTLINE
	if h < 3:
		return Palette.STONE_DARK
	return Palette.DIRT_DARK if left else Palette.DIRT_BOTTOM


## Cerquinha de ferro baixa, em trechos, só nas bordas de trás (atrás dos tiles).
func _draw_fence() -> void:
	var iron := Palette.color(Palette.OUTLINE)
	var shine := Palette.color(Palette.STONE_DARK)
	for px: int in range(min_x + 6, max_x - 5):
		var section := floori(float(px - min_x) / 40.0) % 3
		if section == 1:
			continue
		var top := int((columns[px] as Vector2i).x) - 3
		if px % 6 == 0:
			draw_rect(Rect2(px, top - FENCE_H, 1, FENCE_H), iron)
			draw_rect(Rect2(px, top - FENCE_H - 1, 1, 1), shine)
		draw_rect(Rect2(px, top - FENCE_H + 2, 1, 1), iron)
		draw_rect(Rect2(px, top - 2, 1, 1), iron)
