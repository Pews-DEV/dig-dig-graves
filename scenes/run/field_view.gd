class_name FieldView
extends Node2D
## Visualização do campo (GDD §18.2): lê o FieldModel e espelha num TileMapLayer iso.
## Não guarda regra de jogo. A origem deste nó é o centro visual do campo.

const GRAVE_KEY := 4096  # chaves de cache ≥ isto = tile do atlas de covas
const HEADROOM := 9  # folga acima do losango para tufos (DA §5)

var model: FieldModel
var atlas: TileAtlas
var content: Node2D
var tiles: TileMapLayer
var cracks: CrackOverlay
var regen_fx: RegenOverlay
var outline: AreaOutline
var particles: DirtParticles
var cursor: DigCursor
var numbers: FloatingNumbers
var grave_floor: GraveView
var grave_props: GraveView
var block: DioramaBlock
var block_front: DioramaBlock
var decor: FieldDecor

var state: RunState
var _shown: PackedInt32Array = PackedInt32Array()
var _lit: PackedByteArray = PackedByteArray()
var _base_offset: Vector2 = Vector2.ZERO
var _shake_time: float = 0.0
var _shake_px: int = 0
var _rng := RandomNumberGenerator.new()


func setup(p_model: FieldModel, area: AreaData) -> void:
	model = p_model
	atlas = TileAtlas.build(area)
	content = Node2D.new()
	content.name = "Content"
	add_child(content)
	block = DioramaBlock.new()
	block.name = "Block"
	content.add_child(block)
	decor = FieldDecor.new()
	decor.name = "Decor"
	content.add_child(decor)
	tiles = TileMapLayer.new()
	tiles.name = "Tiles"
	tiles.tile_set = atlas.tile_set
	tiles.y_sort_enabled = true
	content.add_child(tiles)
	cracks = CrackOverlay.new()
	cracks.tiles = tiles
	cracks.atlas = atlas
	cracks.model = model
	content.add_child(cracks)
	regen_fx = RegenOverlay.new()
	regen_fx.tiles = tiles
	regen_fx.atlas = atlas
	regen_fx.is_lit = func(cell: Vector2i) -> bool: return _lit[model.index_of(cell)] == 1
	content.add_child(regen_fx)
	block_front = DioramaBlock.new()
	block_front.name = "BlockFront"
	block_front.mode = DioramaBlock.Mode.FRONT
	content.add_child(block_front)
	grave_floor = GraveView.new()
	grave_floor.tiles = tiles
	grave_floor.atlas = atlas
	grave_floor.draw_props = false
	content.add_child(grave_floor)
	outline = AreaOutline.new()
	outline.tiles = tiles
	content.add_child(outline)
	grave_props = GraveView.new()
	grave_props.tiles = tiles
	grave_props.atlas = atlas
	grave_props.draw_props = true
	content.add_child(grave_props)
	particles = DirtParticles.new()
	content.add_child(particles)
	cursor = DigCursor.new()
	content.add_child(cursor)
	numbers = FloatingNumbers.new()
	content.add_child(numbers)
	_center_field()
	block.setup(tiles, model.size)
	block_front.setup(tiles, model.size)
	decor.setup(block)
	_shown.resize(model.tile_count())
	_shown.fill(-1)
	_lit.resize(model.tile_count())
	cracks.lit_flags = _lit
	refresh(Vector2i(-1000, -1000), 0)


## Liga as camadas de cova/fogo-fátuo ao estado do turno (só leitura).
func attach_run(p_state: RunState) -> void:
	state = p_state
	grave_floor.state = p_state
	grave_props.state = p_state


func _center_field() -> void:
	var n := model.size
	var left := tiles.map_to_local(Vector2i(0, n - 1)).x - (IsoDraw.TILE_W >> 1)
	var right := tiles.map_to_local(Vector2i(n - 1, 0)).x + (IsoDraw.TILE_W >> 1)
	var top := tiles.map_to_local(Vector2i(0, 0)).y - (IsoDraw.TILE_H >> 1) - HEADROOM
	var bottom := tiles.map_to_local(Vector2i(n - 1, n - 1)).y + (IsoDraw.TILE_H >> 1)
	_base_offset = -Vector2(roundf((left + right) * 0.5), roundf((top + bottom) * 0.5))
	content.position = _base_offset


## UI/UX §5 "Enquadramento": grade centralizada na faixa livre entre as plaquetas do HUD;
## o HUD nunca cobre a grade. Se grade + bloco não cabem, só o bloco vai para trás da plaqueta.
func frame_in(free_top: int, free_bottom: int) -> void:
	var grid_h := model.size * IsoDraw.TILE_H
	var total := grid_h + DioramaBlock.DEPTH
	var avail := free_bottom - free_top
	var top: int
	if total <= avail:
		top = free_top + (avail - total) / 2
	else:
		top = free_top + maxi(0, (avail - grid_h) / 2)
	var t0 := tiles.map_to_local(Vector2i.ZERO)
	_base_offset = Vector2(roundf(320.0 - t0.x), roundf(top + 7 - t0.y)) - position
	content.position = _base_offset


## Célula sob o mouse (GDD §18.4 via TileMapLayer.local_to_map).
func mouse_cell() -> Vector2i:
	return tiles.local_to_map(tiles.get_local_mouse_position())


## Centro (pivô) da célula em coordenadas de `content` (onde ficam efeitos e cursor).
func cell_center(cell: Vector2i) -> Vector2:
	return tiles.map_to_local(cell)


## Sincroniza estágio/variante/luz de cada tile com o modelo. Só toca o que mudou.
## Luz (DA §4.2): tiles no raio usam o atlas _lit; anel de 1 tile em xadrez.
func refresh(light_center: Vector2i, light_radius: int) -> void:
	var hide_regen := regen_fx.uses_texture()
	var grave_tiles := _grave_tiles()
	for i: int in model.tile_count():
		_lit[i] = 1 if _is_lit(model.cell_of(i), light_center, light_radius) else 0
	if state != null:
		# A cova usa uma luz só para as 2 metades (GraveVisuals.light_overrides).
		var overrides := GraveVisuals.light_overrides(model, state.graves, _lit)
		for idx: int in overrides:
			_lit[idx] = int(overrides[idx])
	for i: int in model.tile_count():
		var cell := model.cell_of(i)
		var lit: int = _lit[i]
		var key: int
		if hide_regen and regen_fx.is_playing(cell):
			key = -2  # o frame de regeneração ocupa o lugar do tile
		elif grave_tiles.has(cell):
			var gt: Vector2i = grave_tiles[cell]
			key = GRAVE_KEY + gt.x * 16 + gt.y + lit * 256
		else:
			var col := model.stage_column(cell)
			var variant := atlas.rock_variant_for(cell) if col == FieldModel.ROCK_COLUMN else atlas.variant_for(col, cell)
			key = col | (variant << 4) | (lit << 8)
		if _shown[i] == key:
			continue
		_shown[i] = key
		if key == -2:
			tiles.erase_cell(cell)
		elif key >= GRAVE_KEY:
			var k := key - GRAVE_KEY
			tiles.set_cell(cell, TileAtlas.SOURCE_GRAVE_LIT if lit == 1 else TileAtlas.SOURCE_GRAVE, Vector2i((k % 256) >> 4, k & 0xF))
		elif (key & 0xF) == FieldModel.ROCK_COLUMN:
			# Rocha é desenhada no lugar do tile de solo (MANIFEST rocha).
			tiles.set_cell(cell, TileAtlas.SOURCE_ROCK_LIT if lit == 1 else TileAtlas.SOURCE_ROCK, Vector2i((key >> 4) & 0xF, 0))
		else:
			tiles.set_cell(cell, TileAtlas.SOURCE_LIT if lit == 1 else TileAtlas.SOURCE_NORMAL, Vector2i(key & 0xF, (key >> 4) & 0xF))
	cracks.lit_flags = _lit
	cracks.queue_redraw()


## Células de cova que usam o atlas de covas: caixão à mostra ou cova aberta, sempre
## as 2 metades juntas. Valor = (coluna eixo×2+metade, linha de estado).
func _grave_tiles() -> Dictionary:
	if state == null or not atlas.has_grave_art:
		return {}
	return GraveVisuals.atlas_cells(model, state.graves)


func _is_lit(cell: Vector2i, center: Vector2i, radius: int) -> bool:
	if radius <= 0:
		return false
	var dist := Vector2(cell - center).length()
	if dist <= radius + 0.5:
		return true
	return dist <= radius + 1.5 and (cell.x + cell.y) % 2 == 0


func play_regen(cell: Vector2i) -> void:
	regen_fx.play(cell)


## DA §9.3: tremor máx. 2 px, escalonado pela opção de acessibilidade.
func shake(px: float, duration: float) -> void:
	var scaled := roundi(px * float(Game.settings.get("shake_intensity", 1.0)) * Juice.motion())
	if scaled <= 0:
		return
	_shake_px = maxi(_shake_px, mini(scaled, roundi(Game.balance.max_shake_px)))
	_shake_time = maxf(_shake_time, duration)


func _process(delta: float) -> void:
	if _shake_time > 0.0:
		_shake_time -= delta
		if _shake_time <= 0.0:
			_shake_px = 0
			content.position = _base_offset
		else:
			content.position = _base_offset + Vector2(_rng.randi_range(-_shake_px, _shake_px), _rng.randi_range(-_shake_px, _shake_px))
