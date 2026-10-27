class_name AreaOutline
extends Node2D
## Contorno da área de escavação desenhado por código (DA §4.2, UI/UX §5.1): só o PERÍMETRO
## externo em degraus iso de 1 px (nenhum traço interno), cor 25 em repouso e 26 no pulso
## (DA §9.2: 25 → 26 → 25), com cantoneiras de 3 px nas 4 pontas.

const FLASH_TIME := 0.12

var tiles: TileMapLayer
var _cells: Dictionary = {}
var _flash: float = 0.0


func set_cells(cells: Array[Vector2i]) -> void:
	var next: Dictionary = {}
	for c: Vector2i in cells:
		next[c] = true
	if next.hash() != _cells.hash():
		_cells = next
		queue_redraw()


func flash() -> void:
	_flash = FLASH_TIME
	queue_redraw()


func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash -= delta
		if _flash <= 0.0:
			queue_redraw()


func _draw() -> void:
	if tiles == null or _cells.is_empty():
		return
	var color := Palette.color(Palette.LANTERN_BRIGHT if _flash > 0.0 else Palette.LANTERN)
	var top := Vector2i(0, 1 << 20)
	var bottom := Vector2i(0, -(1 << 20))
	var left := Vector2i(1 << 20, 0)
	var right := Vector2i(-(1 << 20), 0)
	for cell: Vector2i in _cells:
		var center := tiles.map_to_local(cell)
		var c := Vector2i(center)
		for edge: StringName in IsoDraw.EDGE_NEIGHBORS:
			if not _cells.has(cell + (IsoDraw.EDGE_NEIGHBORS[edge] as Vector2i)):
				IsoDraw.draw_tile_edge(self, center, edge, color)
		if c.y - 7 < top.y:
			top = Vector2i(c.x, c.y - 7)
		if c.y + 7 > bottom.y:
			bottom = Vector2i(c.x, c.y + 7)
		if c.x - 16 < left.x:
			left = Vector2i(c.x - 16, c.y)
		if c.x + 15 > right.x:
			right = Vector2i(c.x + 15, c.y)
	_corner_v(top, -1, color)
	_corner_v(bottom, 1, color)
	_corner_h(left, -1, color)
	_corner_h(right, 1, color)


## Cantoneira em "^" (dir = −1) ou "v" (dir = 1), 2 px para fora da ponta, degraus 2:1.
func _corner_v(p: Vector2i, dir: int, color: Color) -> void:
	draw_rect(Rect2(p.x - 1, p.y + 3 * dir, 2, 1), color)
	draw_rect(Rect2(p.x - 3, p.y + 2 * dir, 2, 1), color)
	draw_rect(Rect2(p.x + 1, p.y + 2 * dir, 2, 1), color)


## Cantoneira em "<" (dir = −1) ou ">" (dir = 1) nas pontas laterais.
func _corner_h(p: Vector2i, dir: int, color: Color) -> void:
	var x := p.x + 3 * dir
	draw_rect(Rect2(x - (1 if dir > 0 else 0), p.y, 2, 1), color)
	draw_rect(Rect2(x - 2 * dir - (1 if dir > 0 else 0), p.y - 1, 2, 1), color)
	draw_rect(Rect2(x - 2 * dir - (1 if dir > 0 else 0), p.y + 1, 2, 1), color)
