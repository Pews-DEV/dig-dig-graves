class_name RegenOverlay
extends Node2D
## Animação de regeneração (DA §9.2: 4 frames, 330 ms). Com o asset `regen_a1` do
## manifesto, toca os frames no lugar do tile (a FieldView esconde a célula enquanto isso);
## sem ele, desenha por código um buraco fechando sobre o tile já restaurado.

const DURATION := 0.33
const FRAMES := 4
const HOLE_WIDTHS: Array[int] = [28, 20, 12, 4]

var tiles: TileMapLayer
var atlas: TileAtlas
## Callable(cell: Vector2i) -> bool: tile está iluminado (usa o atlas _lit).
var is_lit: Callable
var _active: Dictionary = {}  # Vector2i -> tempo decorrido


func uses_texture() -> bool:
	return atlas != null and atlas.regen != null


func play(cell: Vector2i) -> void:
	_active[cell] = 0.0
	queue_redraw()


func is_playing(cell: Vector2i) -> bool:
	return _active.has(cell)


func _process(delta: float) -> void:
	if _active.is_empty():
		return
	for cell: Vector2i in _active.keys():
		_active[cell] = float(_active[cell]) + delta
		if float(_active[cell]) >= DURATION:
			_active.erase(cell)
	queue_redraw()


func _draw() -> void:
	for cell: Vector2i in _active:
		var frame := clampi(int(float(_active[cell]) / (DURATION / FRAMES)), 0, FRAMES - 1)
		var center := tiles.map_to_local(cell)
		if uses_texture():
			var lit := is_lit.is_valid() and bool(is_lit.call(cell))
			var tex := atlas.regen_lit if lit else atlas.regen
			var region := Rect2(Vector2(frame * TileAtlas.CELL.x, 0), Vector2(TileAtlas.CELL))
			draw_texture_rect_region(tex, Rect2(center - Vector2(TileAtlas.PIVOT), Vector2(TileAtlas.CELL)), region)
		else:
			var w := HOLE_WIDTHS[frame]
			IsoDraw.fill_diamond(self, center, w, Palette.color(Palette.DIRT_DARK))
			if w > 4:
				IsoDraw.fill_diamond(self, center, w - 4, Palette.color(Palette.DIRT_BOTTOM))
