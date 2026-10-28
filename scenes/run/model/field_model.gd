class_name FieldModel
extends RefCounted
## Modelo puro do campo (GDD §4.2, §4.3, §4.6–4.8, §18.2). Sem nós, sem desenho.
## Cada tile tem um tipo, uma pilha de camadas (topo → fundo), o índice da camada do
## topo, o HP dessa camada e um timer de regeneração.

## TOMBSTONE = tile da lápide: bloqueado (sem dano, sem rachadura, fora do CAMPO LIMPO).
enum Kind { SOIL, GRAVE, ROCK, TOMBSTONE, CANDLE }

const HOLE_COLUMN := 3  # coluna S3 do atlas
const ROCK_COLUMN := 4  # desenhado pelo atlas de rochas

var size: int
var area: AreaData
## Camadas especiais com HP já calculado pelas regras (§4.6, §4.8). Podem ser null.
var coffin_layer: LayerData
var rock_layer: LayerData
var stacks: Array = []  # por tile: Array[LayerData] (topo → fundo)
var depth: PackedInt32Array  # índice da camada do topo na pilha; == stack.size() → Buraco
var hp: PackedFloat32Array  # HP restante da camada do topo
var kind: PackedInt32Array
var regen_timer: PackedFloat32Array  # só conta em Buracos (GDD §4.7)
## Cova = UMA entidade de 2 tiles (GDD §4.6). `partner[i]` = índice da outra metade, −1 se não é cova.
## Regra (decisão de jogo): as camadas de solo de cada metade são cavadas separadamente;
## o Caixão só fica exposto quando as DUAS metades chegam a ele (até lá a metade adiantada
## é fundo de buraco, sem dano). Exposto, ele tem HP compartilhado (soma das 2 metades):
## dano em qualquer metade desce o mesmo HP, e as 2 quebram juntas no mesmo golpe.
var partner: PackedInt32Array
## Sobrescritas do Caixão por cova (ex.: lápide com musgo mais resistente).
var _grave_coffin_layers: Dictionary = {}  # índice do tile → LayerData


func _init(p_area: AreaData, p_size: int, p_coffin: LayerData = null, p_rock: LayerData = null) -> void:
	area = p_area
	size = p_size
	coffin_layer = p_coffin
	rock_layer = p_rock
	var n := size * size
	stacks.resize(n)
	depth.resize(n)
	hp.resize(n)
	kind.resize(n)
	regen_timer.resize(n)
	partner.resize(n)
	partner.fill(-1)
	for i: int in n:
		kind[i] = Kind.SOIL
		_restore_index(i)


## Camada especial a partir do modelo da área, com HP calculado (o .tres traz só o resto).
static func make_special_layer(template: LayerData, hp_value: float) -> LayerData:
	if template == null:
		return null
	var l := template.duplicate() as LayerData
	l.hp = hp_value
	return l


func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < size and cell.y < size


func index_of(cell: Vector2i) -> int:
	return cell.y * size + cell.x


func cell_of(i: int) -> Vector2i:
	return Vector2i(i % size, int(i / float(size)))


func tile_count() -> int:
	return size * size


func clip(cells: Array[Vector2i]) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for c: Vector2i in cells:
		if in_bounds(c):
			out.append(c)
	return out


func kind_of(cell: Vector2i) -> int:
	return kind[index_of(cell)]


## GDD §4.6: o tile da lápide não é cavável e a área de escavação o ignora.
func is_blocked(cell: Vector2i) -> bool:
	return kind[index_of(cell)] in [Kind.TOMBSTONE, Kind.CANDLE]


func is_hole(cell: Vector2i) -> bool:
	var i := index_of(cell)
	return not is_blocked(cell) and depth[i] >= (stacks[i] as Array).size()


func is_intact(cell: Vector2i) -> bool:
	return depth[index_of(cell)] == 0


## Camada atingível do topo. null = Buraco, lápide ou Caixão ainda enterrado do outro lado
## (a metade adiantada da cova vira fundo de buraco até a outra chegar ao Caixão).
func top_layer(cell: Vector2i) -> LayerData:
	var i := index_of(cell)
	var layer := _raw_top(i)
	if layer != null and _coffin_waiting(i):
		return null
	return layer


func layer_max_hp(layer: LayerData) -> float:
	return layer.hp * area.hp_mult


## HP cheio da camada do topo deste tile; o Caixão de uma cova vale pelas 2 metades.
func cell_max_hp(cell: Vector2i) -> float:
	var i := index_of(cell)
	var layer := _raw_top(i)
	if layer == null:
		return 0.0
	return _max_hp_at(i, layer)


func hp_ratio(cell: Vector2i) -> float:
	if top_layer(cell) == null:
		return 0.0
	return hp[index_of(cell)] / cell_max_hp(cell)


# --- Covas (entidade de 2 tiles) ------------------------------------------------

## Liga as 2 metades de uma cova (os tiles já devem ser Kind.GRAVE).
func link_grave(head: Vector2i, foot: Vector2i, coffin_override: LayerData = null) -> void:
	var a := index_of(head)
	var b := index_of(foot)
	partner[a] = b
	partner[b] = a
	if coffin_override != null:
		_grave_coffin_layers[a] = coffin_override
		_grave_coffin_layers[b] = coffin_override
		(stacks[a] as Array)[-1] = coffin_override
		(stacks[b] as Array)[-1] = coffin_override


func unlink_grave(cell: Vector2i) -> void:
	var a := index_of(cell)
	var b: int = partner[a]
	partner[a] = -1
	_grave_coffin_layers.erase(a)
	if b >= 0:
		partner[b] = -1
		_grave_coffin_layers.erase(b)


## Outra metade da cova, ou (−1, −1) se o tile não é de cova.
func grave_partner(cell: Vector2i) -> Vector2i:
	var j: int = partner[index_of(cell)]
	return cell_of(j) if j >= 0 else Vector2i(-1, -1)


## Caixão à mostra: as 2 metades chegaram a ele e ele ainda não quebrou.
func is_coffin_exposed(cell: Vector2i) -> bool:
	var i := index_of(cell)
	if coffin_layer == null or kind[i] != Kind.GRAVE or _raw_top(i) != _coffin_layer_at(i):
		return false
	return not _coffin_waiting(i)


func _raw_top(i: int) -> LayerData:
	if is_blocked(cell_of(i)):
		return null
	var stack: Array = stacks[i]
	if depth[i] >= stack.size():
		return null
	return stack[depth[i]] as LayerData


func _is_shared_coffin(i: int, layer: LayerData) -> bool:
	return layer != null and layer == _coffin_layer_at(i) and kind[i] == Kind.GRAVE and partner[i] >= 0


func _coffin_layer_at(i: int) -> LayerData:
	return _grave_coffin_layers.get(i, coffin_layer) as LayerData


## A metade i já está no Caixão, mas a outra ainda tem solo por cima.
func _coffin_waiting(i: int) -> bool:
	if not _is_shared_coffin(i, _raw_top(i)):
		return false
	var j: int = partner[i]
	return depth[j] < (stacks[j] as Array).size() and _raw_top(j) != _coffin_layer_at(j)


func _max_hp_at(i: int, layer: LayerData) -> float:
	var m := layer_max_hp(layer)
	return m * 2.0 if _is_shared_coffin(i, layer) else m


## Coluna do atlas a desenhar (S0..S2 pela camada do topo, S3 = Buraco/Caixão, 4 = Rocha).
func stage_column(cell: Vector2i) -> int:
	if is_blocked(cell):
		return 0  # solo intacto sob a lápide
	var layer := top_layer(cell)
	return HOLE_COLUMN if layer == null else layer.stage_column


## Cobre pago por ponto de dano na camada (GDD §4.3 v1.1): Cobre ÷ HP, já com os
## multiplicadores da área. O total por camada continua sendo Cobre × recompensa.
func copper_per_point(layer: LayerData) -> float:
	return layer.copper * area.reward_mult / layer_max_hp(layer)


## GDD §4.3: o dano atinge só a camada do topo; o excedente NÃO passa para baixo.
## Retorna {"useful": dano efetivo (≤ HP restante), "layer": camada atingida,
## "broken": bool, "cells": tiles que quebraram (2 quando é o Caixão de uma cova)}.
## Buraco/fora do campo/Caixão ainda enterrado → useful 0 e layer null.
func apply_damage(cell: Vector2i, amount: float, regen_time: float, carry: bool = false, deep_mult: float = 1.0) -> Dictionary:
	var out := {"useful": 0.0, "layer": null, "broken": false, "cells": [], "layers": []}
	if not in_bounds(cell) or amount <= 0.0:
		return out
	var i := index_of(cell)
	var remaining := amount
	while remaining > 0.000001:
		var layer := top_layer(cell)
		if layer == null:
			break
		if out.layer == null:
			out.layer = layer
		var layer_mult := maxf(1.0, deep_mult) if layer.deep else 1.0
		var useful := minf(remaining * layer_mult, hp[i])
		remaining -= useful / layer_mult
		out.useful = float(out.useful) + useful
		hp[i] -= useful
		var band := {"layer": layer, "useful": useful, "broken": false, "cells": []}
		var shared := _is_shared_coffin(i, layer)
		if shared:
			hp[partner[i]] = hp[i]  # HP do Caixão é um só para as 2 metades
		if hp[i] > 0.000001:
			(out.layers as Array).append(band)
			break
		band.broken = true
		var broken_cells: Array = band.cells
		broken_cells.append(cell)
		_break_top(i, regen_time)
		if shared:
			broken_cells.append(cell_of(partner[i]))
			_break_top(partner[i], regen_time)
		for broken_cell: Vector2i in broken_cells:
			(out.cells as Array).append(broken_cell)
		(out.layers as Array).append(band)
		out.broken = true
		if not carry or remaining <= 0.000001:
			break
	return out


func _break_top(i: int, regen_time: float) -> void:
	depth[i] += 1
	var next := _raw_top(i)
	if next == null:
		hp[i] = 0.0
		regen_timer[i] = regen_time
		if kind[i] == Kind.ROCK:
			kind[i] = Kind.SOIL  # rocha quebrada vira solo comum ao regenerar
	else:
		hp[i] = _max_hp_at(i, next)


## GDD §4.7: só Buracos regeneram; tiles de cova esperam a cova abrir/fechar.
## Retorna as células regeneradas.
func tick_regen(delta: float, candle_cells: Array[Vector2i] = []) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for i: int in tile_count():
		if kind[i] == Kind.GRAVE or is_blocked(cell_of(i)) or depth[i] < (stacks[i] as Array).size():
			continue
		var rate := 2.0 if _near_any(cell_of(i), candle_cells) else 1.0
		regen_timer[i] -= delta * rate
		if regen_timer[i] <= 0.0:
			_restore_index(i)
			out.append(cell_of(i))
	return out


func _near_any(cell: Vector2i, centers: Array[Vector2i]) -> bool:
	for center: Vector2i in centers:
		if Vector2(cell - center).length() <= 1.5:
			return true
	return false


## Muda o tipo do tile. `restore` = refaz a pilha inteira; senão só acrescenta/remove
## a camada especial mantendo o que já foi cavado (usado ao surgir uma cova em tile intacto).
func set_kind(cell: Vector2i, new_kind: int, restore_stack: bool = true) -> void:
	var i := index_of(cell)
	if new_kind != Kind.GRAVE:
		unlink_grave(cell)
	kind[i] = new_kind
	if restore_stack:
		_restore_index(i)


## Fecha um tile de cova: vira solo, Buraco, regenerando normalmente (GDD §4.6).
func close_grave_tile(cell: Vector2i, regen_time: float) -> void:
	var i := index_of(cell)
	unlink_grave(cell)
	kind[i] = Kind.SOIL
	stacks[i] = area.layers.duplicate()
	depth[i] = (stacks[i] as Array).size()
	hp[i] = 0.0
	regen_timer[i] = regen_time


func restore(cell: Vector2i) -> void:
	_restore_index(index_of(cell))


func restore_all() -> void:
	for i: int in tile_count():
		_restore_index(i)


## O chefe deixa um buraco no ponto em que afundou (GDD §10.2 HOP).
func leave_hole(cell: Vector2i, regen_time: float) -> void:
	if not in_bounds(cell) or kind_of(cell) == Kind.GRAVE or is_blocked(cell):
		return
	var i := index_of(cell)
	kind[i] = Kind.SOIL
	depth[i] = (stacks[i] as Array).size()
	hp[i] = 0.0
	regen_timer[i] = regen_time


## CAMPO LIMPO: tiles de lápide ficam fora do denominador.
func is_all_holes() -> bool:
	for i: int in tile_count():
		if not is_blocked(cell_of(i)) and depth[i] < (stacks[i] as Array).size():
			return false
	return true


func hole_count() -> int:
	var n := 0
	for i: int in tile_count():
		if not is_blocked(cell_of(i)) and depth[i] >= (stacks[i] as Array).size():
			n += 1
	return n


func _restore_index(i: int) -> void:
	var stack: Array
	match kind[i]:
		Kind.ROCK:
			stack = [rock_layer] if rock_layer != null else area.layers.duplicate()
		Kind.GRAVE:
			stack = area.layers.duplicate()
			var grave_coffin := _coffin_layer_at(i)
			if grave_coffin != null:
				stack.append(grave_coffin)
		_:
			stack = area.layers.duplicate()
	stacks[i] = stack
	depth[i] = 0
	regen_timer[i] = 0.0
	hp[i] = _max_hp_at(i, stack[0] as LayerData) if not stack.is_empty() else 0.0
