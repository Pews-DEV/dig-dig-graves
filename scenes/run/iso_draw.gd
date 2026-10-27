class_name IsoDraw
extends RefCounted
## Desenho de losangos iso pixel-perfeitos (DA §2.1 e §5.1 rev. 1.1).
## Losango 32×16 = 15 linhas (larguras 4, 8 … 32 … 8, 4) com uma única linha de 32 px
## no centro da célula (pivô). Usado para gerar texturas e para desenhar por código.

const TILE_W := 32
const TILE_H := 16

## Arestas de um tile, nomeadas pela direção do vizinho na grade (Diamond Down:
## +x = baixo-direita, +y = baixo-esquerda).
const EDGE_NEIGHBORS: Dictionary = {
	&"ul": Vector2i(-1, 0),
	&"ur": Vector2i(0, -1),
	&"lr": Vector2i(1, 0),
	&"ll": Vector2i(0, 1),
}


## Linhas (dy relativo ao centro, meia-largura) de um losango de largura `w` (múltiplo de 4).
static func rows(w: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var n := (w >> 2) - 1
	for dy: int in range(-n, n + 1):
		out.append(Vector2i(dy, (w >> 1) - 2 * absi(dy)))
	return out


static func _edge_rows(w: int, edge: StringName) -> Array[Vector2i]:
	var upper := edge == &"ul" or edge == &"ur"
	var out: Array[Vector2i] = []
	for r: Vector2i in rows(w):
		# A linha central pertence às arestas de cima e de baixo (cantos).
		if (upper and r.x <= 0) or (not upper and r.x >= 0):
			out.append(r)
	return out


static func _is_left(edge: StringName) -> bool:
	return edge == &"ul" or edge == &"ll"


## Losango cheio numa Image, centrado na coluna `cx` (borda entre os 2 px do meio) e linha `cy`.
static func fill_diamond_image(img: Image, cx: int, cy: int, w: int, color: Color) -> void:
	for r: Vector2i in rows(w):
		for x: int in range(cx - r.y, cx + r.y):
			_put(img, x, cy + r.x, color)


## Pinta uma aresta (2 px por linha) de um losango numa Image.
static func edge_diamond_image(img: Image, cx: int, cy: int, w: int, edge: StringName, color: Color) -> void:
	for r: Vector2i in _edge_rows(w, edge):
		var x0 := cx - r.y if _is_left(edge) else cx + r.y - 2
		_put(img, x0, cy + r.x, color)
		_put(img, x0 + 1, cy + r.x, color)


static func _put(img: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, color)


## Losango cheio num CanvasItem, centrado em `center` (centro da célula).
static func fill_diamond(ci: CanvasItem, center: Vector2, w: int, color: Color) -> void:
	var cx := int(center.x)
	var cy := int(center.y)
	for r: Vector2i in rows(w):
		ci.draw_rect(Rect2(cx - r.y, cy + r.x, r.y * 2, 1), color)


## Contorno de 1 px (só os extremos de cada linha) de um losango num CanvasItem.
static func outline_diamond(ci: CanvasItem, center: Vector2, w: int, color: Color) -> void:
	var cx := int(center.x)
	var cy := int(center.y)
	for r: Vector2i in rows(w):
		ci.draw_rect(Rect2(cx - r.y, cy + r.x, 1, 1), color)
		ci.draw_rect(Rect2(cx + r.y - 1, cy + r.x, 1, 1), color)


## Aresta (degraus 2-2-2, 1 px de espessura) do losango de um tile num CanvasItem.
## `center` = centro da célula (TileMapLayer.map_to_local).
static func draw_tile_edge(ci: CanvasItem, center: Vector2, edge: StringName, color: Color) -> void:
	var cx := int(center.x)
	var cy := int(center.y)
	for r: Vector2i in _edge_rows(TILE_W, edge):
		var x0 := cx - r.y if _is_left(edge) else cx + r.y - 2
		ci.draw_rect(Rect2(x0, cy + r.x, 2, 1), color)
