class_name GraveVisuals
extends RefCounted
## Regras puras de desenho das covas (GDD §4.6, MANIFEST grave_a1), sem nós, para teste.
## A cova é uma peça só: as 2 metades mostram sempre o mesmo estado (exposto, rachado,
## aberto) e a mesma luz, ou nenhuma mostra o caixão (enquanto ele está enterrado).

const ROW_BURIED := -1


## Célula → Vector2i(coluna = eixo × 2 + metade, linha de estado) do atlas de covas.
## Covas com o caixão ainda enterrado ficam de fora (os tiles mostram solo/buraco).
static func atlas_cells(field: FieldModel, graves: Array[Dictionary]) -> Dictionary:
	var out: Dictionary = {}
	for g: Dictionary in graves:
		var row := state_row(field, g)
		if row == ROW_BURIED:
			continue
		var cells: Array = g.cells
		for half: int in cells.size():
			var c: Vector2i = cells[half]
			out[c] = Vector2i(int(g.axis) * 2 + half, row)
	return out


## Linha do atlas para a cova inteira (decidida uma vez, nunca por metade).
static func state_row(field: FieldModel, g: Dictionary) -> int:
	if bool(g.open):
		return TileAtlas.GRAVE_ROW_OPEN
	var cells: Array = g.cells
	for c: Vector2i in cells:
		if not field.is_coffin_exposed(c):
			return ROW_BURIED
	# HP compartilhado: a razão é a mesma nas 2 metades.
	var head: Vector2i = cells[0]
	return TileAtlas.GRAVE_ROW_CRACKED if field.hp_ratio(head) < TileAtlas.GRAVE_CRACK_RATIO else TileAtlas.GRAVE_ROW_EXPOSED


## DA §4.2 aplicada à cova inteira: se qualquer metade está na luz, as 2 usam o atlas `_lit`
## (o anel em xadrez do raio não pode partir o caixão em dois tons).
## Retorna índice do tile → 0/1 para sobrescrever `lit`.
static func light_overrides(field: FieldModel, graves: Array[Dictionary], lit: PackedByteArray) -> Dictionary:
	var out: Dictionary = {}
	for g: Dictionary in graves:
		var cells: Array = g.cells
		var lit_any := 0
		for c: Vector2i in cells:
			var i := field.index_of(c)
			if i < lit.size() and lit[i] == 1:
				lit_any = 1
		for c: Vector2i in cells:
			out[field.index_of(c)] = lit_any
	return out
