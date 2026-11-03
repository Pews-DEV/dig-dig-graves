class_name GraveView
extends Node2D
## Visual das covas (GDD §4.6, DA §7) e dos fogos-fátuos (DA §8.2). Só lê o RunState.
## Duas instâncias: `draw_props = false` desenha o "chão" (tampa do caixão, cova aberta)
## abaixo do contorno da área; `true` desenha lápides, alma subindo e fogos-fátuos por cima.
## A arte do caixão está isolada em _draw_coffin_lid() / _draw_open_grave() para virar atlas.

const OPEN_ANIM_TIME := 0.33  # MANIFEST grave_open_a1: 4 frames, 330 ms
const OPEN_FRAMES := 4
## MANIFEST alma: frames 12×32 na horizontal, 6 frames em 1 s (loop), pivô (6,31).
const SOUL_PATH := "res://assets/sprites/fx/alma.png"
const SOUL_FRAME := Vector2(12, 32)
const SOUL_PIVOT := Vector2(6, 31)
const SOUL_FRAMES := 6
const SOUL_RISE := 24.0
const SOUL_TIME := 1.0
const WISP_PATH := "res://assets/sprites/fx/fogo_fatuo.png"
const WISP_FRAME := Vector2(8, 8)
const CANDLE_PATH := "res://assets/sprites/props/vela_campo.png"
const CANDLE_HALO_PATH := "res://assets/sprites/props/vela_campo_halo.png"
const CANDLE_LIT_PATH := "res://assets/sprites/props/vela_campo_lit.png"
const GOLD_POP_FRAME := 0.083
const GOLD_PATH := "res://assets/sprites/fx/moeda_ouro.png"
const WANDERER_PATH := "res://assets/sprites/chars/title/alma_fila.png"
const TOMBSTONE_CELL := Vector2(16, 24)
const TOMBSTONE_PIVOT := Vector2(8, 23)

var tiles: TileMapLayer
var atlas: TileAtlas
var state: RunState
var draw_props: bool = false

var _time: float = 0.0
var _tombstone: Texture2D
var _tombstone_checked: bool = false
var _wisp: Texture2D = AssetManifest.texture(WISP_PATH)
var _soul: Texture2D = AssetManifest.texture(SOUL_PATH)
var _candle: Texture2D = AssetManifest.texture(CANDLE_PATH)
var _candle_halo: Texture2D = AssetManifest.texture(CANDLE_HALO_PATH)
var _candle_lit: Texture2D = AssetManifest.texture(CANDLE_LIT_PATH)
var _coin_pops: Array[Dictionary] = []
var _connected: bool = false
var _gold_coin: Texture2D = AssetManifest.texture(GOLD_PATH)
var _wanderer: Texture2D = AssetManifest.texture(WANDERER_PATH)


func _process(delta: float) -> void:
	_time += delta
	if draw_props and state != null and not _connected:
		_connected = true
		state.gold_coin_collected.connect(func(coin: Dictionary, _copper: float) -> void:
			_coin_pops.append({"pos": tiles.map_to_local(coin.cell as Vector2i), "t": _time}))
	queue_redraw()


func _draw() -> void:
	if state == null:
		return
	if draw_props:
		_draw_props()
	else:
		_draw_floor()


# --- Chão --------------------------------------------------------------------------

func _draw_floor() -> void:
	if atlas.has_grave_art:
		_draw_open_anims()
		return
	for g: Dictionary in state.graves:
		# Estado decidido para a cova inteira: as 2 metades aparecem juntas ou nenhuma.
		var row := GraveVisuals.state_row(state.field, g)
		if row == GraveVisuals.ROW_BURIED:
			continue
		var cells: Array = g.cells
		var ratio := state.field.hp_ratio(cells[0] as Vector2i)
		for c: Vector2i in cells:
			var center := tiles.map_to_local(c)
			if row == TileAtlas.GRAVE_ROW_OPEN:
				_draw_open_grave(center)
			else:
				_draw_coffin_lid(center, ratio)


## Abertura com arte (MANIFEST grave_open_a1): as 2 metades juntas por 330 ms,
## por cima da célula "aberta" que a FieldView já pôs no lugar.
func _draw_open_anims() -> void:
	if atlas.grave_open == null:
		return
	for g: Dictionary in state.graves:
		if not bool(g.open):
			continue
		var t := state.balance.grave_open_time - float(g.timer)
		if t >= OPEN_ANIM_TIME:
			continue
		var frame := clampi(int(t / (OPEN_ANIM_TIME / OPEN_FRAMES)), 0, OPEN_FRAMES - 1)
		var cells: Array = g.cells
		# Uma luz só para a cova (as 2 metades no mesmo atlas).
		var lit := false
		for c: Vector2i in cells:
			lit = lit or _is_lit(c)
		var tex := atlas.grave_open_lit if lit else atlas.grave_open
		for half: int in cells.size():
			var c: Vector2i = cells[half]
			var row := int(g.axis) * 2 + half
			var cell := Vector2(TileAtlas.CELL)
			draw_texture_rect_region(tex, Rect2(tiles.map_to_local(c) - Vector2(TileAtlas.PIVOT), cell), Rect2(Vector2(frame, row) * cell, cell))


func _is_lit(cell: Vector2i) -> bool:
	return tiles.get_cell_source_id(cell) in [TileAtlas.SOURCE_LIT, TileAtlas.SOURCE_GRAVE_LIT, TileAtlas.SOURCE_ROCK_LIT]


## Placeholder: tampa iso em 19 com luz 20, sombra 18 e pregos 26 (DA §7, "cada tile mostra metade").
func _draw_coffin_lid(center: Vector2, hp_ratio: float) -> void:
	IsoDraw.fill_diamond(self, center, 20, Palette.color(Palette.COFFIN_DARK))
	IsoDraw.fill_diamond(self, center + Vector2(0, -1), 16, Palette.color(Palette.COFFIN))
	IsoDraw.fill_diamond(self, center + Vector2(-2, -2), 4, Palette.color(Palette.COFFIN_LIGHT))
	var nail := Palette.color(Palette.LANTERN_BRIGHT)
	draw_rect(Rect2(center + Vector2(-6, -1), Vector2.ONE), nail)
	draw_rect(Rect2(center + Vector2(5, -1), Vector2.ONE), nail)
	# Tampa rachando conforme o HP do caixão cai.
	if hp_ratio < 0.66:
		draw_rect(Rect2(center + Vector2(-1, -2), Vector2(1, 3)), Palette.color(Palette.OUTLINE))
	if hp_ratio < 0.33:
		draw_rect(Rect2(center + Vector2(1, 0), Vector2(3, 1)), Palette.color(Palette.OUTLINE))


## Placeholder: interior 01 com borda de madeira.
func _draw_open_grave(center: Vector2) -> void:
	IsoDraw.fill_diamond(self, center, 24, Palette.color(Palette.COFFIN_DARK))
	IsoDraw.fill_diamond(self, center, 20, Palette.color(Palette.OUTLINE))


# --- Lápides, almas e fogos-fátuos ------------------------------------------------

func _draw_props() -> void:
	var sorted := state.graves.duplicate()
	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ha: Vector2i = a.head
		var hb: Vector2i = b.head
		return ha.x + ha.y < hb.x + hb.y)
	for g: Dictionary in sorted:
		# MANIFEST grave_a1: a lápide fica no tile atrás da cabeça (nunca tapa a cova).
		_draw_tombstone(tiles.map_to_local(g.tombstone as Vector2i), int(g.variant))
		if bool(g.open):
			var cells: Array = g.cells
			var mid := (tiles.map_to_local(cells[0] as Vector2i) + tiles.map_to_local(cells[1] as Vector2i)) * 0.5
			var t := state.balance.grave_open_time - float(g.timer)
			_draw_soul(mid, t)
	for w: Dictionary in state.wisps:
		_draw_wisp(tiles.map_to_local(w.cell as Vector2i), float(w.age))
	for cell: Vector2i in state.candles:
		var center := tiles.map_to_local(cell)
		if _candle_halo != null:
			draw_texture(_candle_halo, center - Vector2(32, 16))
		# MANIFEST vela_campo_lit: dentro do raio da lanterna usa a versão iluminada.
		var candle := _candle_lit if _candle_lit != null and _is_lit(cell) else _candle
		if candle != null:
			var frame := int(_time * 8.0) % 3
			draw_texture_rect_region(candle, Rect2(center - Vector2(16, 16), Vector2(32, 24)), Rect2(frame * 32, 0, 32, 24))
	if not state.gold_coin.is_empty() and _gold_coin != null:
		var c: Vector2i = state.gold_coin.cell
		var frame := int(_time * 10.0) % 4
		draw_texture_rect_region(_gold_coin, Rect2(tiles.map_to_local(c) - Vector2(4, 13), Vector2(8, 8)), Rect2(frame * 8, 0, 8, 8))
	# MANIFEST moeda_ouro `pop`: frames 4–6, 83 ms cada, depois some.
	for pop: Dictionary in _coin_pops.duplicate():
		var age := _time - float(pop.t)
		var pop_frame := 4 + int(age / GOLD_POP_FRAME)
		if pop_frame > 6 or _gold_coin == null:
			_coin_pops.erase(pop)
			continue
		draw_texture_rect_region(_gold_coin, Rect2((pop.pos as Vector2) - Vector2(4, 13), Vector2(8, 8)), Rect2(pop_frame * 8, 0, 8, 8))
	if _wanderer != null:
		var move_time := maxf(0.001, state.balance.wanderer_move_interval)
		for w: Dictionary in state.wanderers:
			var c: Vector2i = w.cell
			# GDD §4.8: a alminha flutua devagar do tile anterior até o atual.
			var from: Vector2i = w.get("from", c)
			var k := clampf((state.elapsed - float(w.get("moved_at", 0.0))) / move_time, 0.0, 1.0)
			var p := tiles.map_to_local(from).lerp(tiles.map_to_local(c), k).round()
			var frame := int(_time * 7.0) % 4
			var bob := roundf(sin(_time * 4.0 + float(c.x + c.y)) * 1.0)
			var flip := tiles.map_to_local(c).x < tiles.map_to_local(from).x
			var src := Rect2(frame * 8, 0, 8, 10)
			if flip:
				src = Rect2(frame * 8 + 8, 0, -8, 10)
			draw_texture_rect_region(_wanderer, Rect2(p - Vector2(4, 13 + bob), Vector2(8, 10)), src)


func _draw_tombstone(pivot: Vector2, variant: int) -> void:
	var origin := pivot - TOMBSTONE_PIVOT
	if not _tombstone_checked:
		_tombstone_checked = true
		_tombstone = AssetManifest.texture(state.area.tombstone_path)
	if _tombstone != null:
		var cols := maxi(1, int(_tombstone.get_width() / TOMBSTONE_CELL.x))
		var src := Rect2(Vector2((variant % cols) * TOMBSTONE_CELL.x, 0), TOMBSTONE_CELL)
		draw_texture_rect_region(_tombstone, Rect2(origin, TOMBSTONE_CELL), src)
		return
	# Placeholder: lápide arredondada 07/08/06 com contorno 01.
	var o := origin.floor()
	draw_rect(Rect2(o + Vector2(3, 6), Vector2(10, 17)), Palette.color(Palette.OUTLINE))
	draw_rect(Rect2(o + Vector2(4, 4), Vector2(8, 2)), Palette.color(Palette.OUTLINE))
	draw_rect(Rect2(o + Vector2(4, 6), Vector2(8, 16)), Palette.color(Palette.STONE))
	draw_rect(Rect2(o + Vector2(5, 5), Vector2(6, 1)), Palette.color(Palette.STONE))
	draw_rect(Rect2(o + Vector2(4, 6), Vector2(2, 16)), Palette.color(Palette.STONE_LIGHT))
	draw_rect(Rect2(o + Vector2(10, 6), Vector2(2, 16)), Palette.color(Palette.STONE_DARK))
	draw_rect(Rect2(o + Vector2(7, 9), Vector2(2, 6)), Palette.color(Palette.STONE_DARK))
	draw_rect(Rect2(o + Vector2(6, 11), Vector2(4, 1)), Palette.color(Palette.STONE_DARK))


## Placeholder da alma (DA §9.2): gota 30 com núcleo 23 subindo 24 px em 1 s.
func _draw_soul(base: Vector2, t: float) -> void:
	if _soul != null:
		# A alma entra depois da abertura do caixão e fica em loop enquanto a cova está aberta.
		var st := t - (OPEN_ANIM_TIME if atlas.grave_open != null else 0.0)
		if st < 0.0:
			return
		var frame := int(st / (1.0 / SOUL_FRAMES)) % SOUL_FRAMES
		draw_texture_rect_region(_soul, Rect2(base.floor() - SOUL_PIVOT, SOUL_FRAME), Rect2(Vector2(frame * SOUL_FRAME.x, 0), SOUL_FRAME))
		return
	if t > SOUL_TIME:
		return
	var p := (base - Vector2(0, 6 + floorf(SOUL_RISE * t / SOUL_TIME))).floor()
	# Some em xadrez no fim: pisca a cada 2 frames de 12 fps.
	if t > SOUL_TIME * 0.75 and int(t * 12.0) % 2 == 1:
		return
	var body := Palette.color(Palette.SOUL)
	draw_rect(Rect2(p + Vector2(-2, -1), Vector2(4, 4)), body)
	draw_rect(Rect2(p + Vector2(-1, -3), Vector2(2, 2)), body)
	draw_rect(Rect2(p + Vector2(-1, 0), Vector2(2, 2)), Palette.color(Palette.BONE_BRIGHT))


## Fogo-fátuo (DA §8.2): 8×8, núcleo 29/23, corpo 28, halo 27; flutua 2 px; pisca no fim.
func _draw_wisp(center: Vector2, age: float) -> void:
	var life := state.stat(StatSheet.WISP_LIFE)
	if age > life - 1.0 and int(age * 10.0) % 2 == 1:
		return
	var bob := roundf(sin((_time + age) * 4.0) * 2.0)
	var c := (center - Vector2(0, 10 + bob)).floor()
	var frame := int((_time + age) * 8.0) % 4
	if _wisp != null:
		draw_texture_rect_region(_wisp, Rect2(c - WISP_FRAME * 0.5, WISP_FRAME), Rect2(Vector2(frame * WISP_FRAME.x, 0), WISP_FRAME))
		return
	var halo := Palette.color(Palette.ECTO_DARK)
	draw_rect(Rect2(c + Vector2(-3, -2), Vector2(6, 5)), halo)
	draw_rect(Rect2(c + Vector2(-2, -4), Vector2(4, 8)), halo)
	draw_rect(Rect2(c + Vector2(-2, -2), Vector2(4, 4)), Palette.color(Palette.ECTO))
	draw_rect(Rect2(c + Vector2(-1, -3 - (frame % 2)), Vector2(2, 1)), Palette.color(Palette.ECTO))
	draw_rect(Rect2(c + Vector2(-1, -1), Vector2(2, 2)), Palette.color(Palette.ECTO_BRIGHT if frame < 2 else Palette.BONE_BRIGHT))
