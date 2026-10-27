class_name RunState
extends RefCounted
## Simulação pura de um Turno da Noite (GDD §4). Sem nós de cena: a cena Run
## chama advance() a cada frame e repassa os sinais para Events; os testes
## chamam advance() diretamente.

signal pulse_resolved(report: Dictionary)
signal layer_broken(cell: Vector2i, layer: LayerData, bone: bool, xp: float, crit: bool)
signal tile_regenerated(cell: Vector2i)
signal field_cleared(bonus: float)
signal xp_changed(xp: float, needed: float, level: int)
signal leveled_up(level: int)
signal grave_spawned(grave: Dictionary)
signal grave_opened(grave: Dictionary, rewards: Dictionary)
signal grave_closed(grave: Dictionary)
signal unrest_changed(value: float)
## GDD §10: Inquietação em 100% chama o chefe (M1). Por ora só o sinal.
signal unrest_filled()
signal wisp_spawned(wisp: Dictionary)
signal wisp_collected(wisp: Dictionary, oil: float)
signal wisp_expired(wisp: Dictionary)
signal oil_drained(cells: Array[Vector2i], amount: float)
signal finished(result: TurnResult)

const EPS := 0.000001
## Eixo da cova (MANIFEST grave_a1): 0 = NO–SE (pés em cabeça + (1,0), lápide em cabeça − (1,0));
## 1 = NE–SO (pés em cabeça + (0,1), lápide em cabeça − (0,1)). A lápide fica sempre atrás.
const GRAVE_DIRS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 1)]

var field: FieldModel
var area: AreaData
var tool: ToolData
var balance: BalanceData
var stats: Dictionary  # snapshot de StatSheet no início do turno
var rng: RandomNumberGenerator

var oil: float
var oil_start: float
var elapsed: float = 0.0
var pulse_acc: float = 0.0
var ended: bool = false
var cursor_cell: Vector2i = Vector2i(-1000, -1000)
var tool_rotation: int = 0

var level: int = 1
var xp: float = 0.0  # XP dentro do nível atual
var result: TurnResult = TurnResult.new()
## Níveis pendentes de escolha de Epitáfio (GDD §4.9: fila, uma tela por vez).
var pending_level_ups: Array[int] = []
## Inquietação da área (0–1). Persiste entre turnos: quem cria o RunState passa o valor.
var unrest: float = 0.0

## Covas: {id, head, cells: [cabeça, pés], axis, tombstone: Vector2i, variant, open: bool, timer}.
var graves: Array[Dictionary] = []
## Fogos-fátuos: {id, cell, age}.
var wisps: Array[Dictionary] = []
var _next_id: int = 1
var _wisp_timer: float = 0.0


func _init(p_area: AreaData, p_tool: ToolData, p_balance: BalanceData, p_stats: Dictionary, seed_value: int = 0, p_unrest: float = 0.0) -> void:
	area = p_area
	tool = p_tool
	balance = p_balance
	stats = p_stats.duplicate()
	unrest = clampf(p_unrest, 0.0, 1.0)
	rng = RandomNumberGenerator.new()
	if seed_value != 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	var side := clampi(roundi(stat(StatSheet.FIELD_SIZE)), 1, area.max_field_size)
	var hardest := 0.0
	for l: LayerData in area.layers:
		hardest = maxf(hardest, l.hp)
	var top_hp := area.layers[0].hp if not area.layers.is_empty() else 1.0
	field = FieldModel.new(area, side,
		FieldModel.make_special_layer(area.coffin_layer, balance.coffin_hp_mult * hardest),
		FieldModel.make_special_layer(area.rock_layer, balance.rock_hp_mult * top_hp))
	oil_start = stat(StatSheet.OIL_MAX)
	oil = oil_start
	result.area_id = area.id
	result.unrest_start = unrest
	result.unrest_end = unrest
	_wisp_timer = _next_wisp_delay()
	_place_rocks()
	for i: int in grave_target():
		_spawn_grave()


func stat(id: StringName) -> float:
	return float(stats.get(id, balance.base_stats.get(id, 0.0)))


func pulse_interval() -> float:
	var minimum := float(balance.stat_min.get(StatSheet.PULSE_INTERVAL, 0.15))
	return maxf(stat(StatSheet.PULSE_INTERVAL) * tool.interval_mult, minimum)


func damage() -> float:
	return stat(StatSheet.DAMAGE) * tool.damage_mult


func radius() -> int:
	return roundi(stat(StatSheet.RADIUS))


func grave_target() -> int:
	return roundi(stat(StatSheet.GRAVE_COUNT))


func xp_needed(for_level: int) -> float:
	# GDD §4.9: 10 × 1,35^(n−1), arredondada.
	return float(roundi(balance.xp_base * pow(balance.xp_growth, for_level - 1)))


func oil_fraction() -> float:
	return clampf(oil / oil_start, 0.0, 1.0) if oil_start > 0.0 else 0.0


## GDD §4.5 / DA §4.2: raio de luz em tiles pelo óleo restante (4 → 3 → 2 → 1).
func light_radius() -> int:
	var f := oil_fraction()
	for i: int in balance.light_thresholds.size():
		if f > balance.light_thresholds[i]:
			return balance.light_radii[i]
	return balance.light_radii[balance.light_radii.size() - 1]


## Tiles da área, recortados nas bordas e sem os tiles bloqueados (lápide, GDD §4.6).
func area_cells(center: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for c: Vector2i in field.clip(tool.cells(center, radius(), tool_rotation)):
		if not field.is_blocked(c):
			out.append(c)
	return out


func grave_at(cell: Vector2i) -> Dictionary:
	for g: Dictionary in graves:
		if (g.cells as Array).has(cell):
			return g
	return {}


## Avança o tempo de forma exata por eventos (pulso, fim do óleo, amanhecer),
## independente do tamanho do delta.
func advance(delta: float, cursor: Vector2i) -> void:
	if ended:
		return
	cursor_cell = cursor
	_collect_wisps()
	var left := delta
	while left > 0.0 and not ended:
		var interval := pulse_interval()
		var to_pulse := maxf(interval - pulse_acc, 0.0)
		var to_oil := oil / balance.oil_burn_rate if balance.oil_burn_rate > 0.0 else INF
		var to_dawn := maxf(balance.turn_cap_seconds - elapsed, 0.0)
		var step := minf(left, minf(to_pulse, minf(to_oil, to_dawn)))
		_pass_time(step)
		left -= step
		if oil <= EPS:
			# GDD §4.10: o óleo acaba → a pá dá um último golpe → fim.
			oil = 0.0
			_pulse(true)
			_finish(&"oil")
		elif elapsed >= balance.turn_cap_seconds - EPS:
			_finish(&"dawn")
		elif pulse_acc >= interval - EPS:
			pulse_acc = maxf(pulse_acc - interval, 0.0)
			_pulse(false)
			if oil <= EPS:  # rochas drenaram o resto do óleo neste golpe
				oil = 0.0
				_finish(&"oil")


func _pass_time(step: float) -> void:
	if step <= 0.0:
		return
	oil = maxf(oil - step * balance.oil_burn_rate, 0.0)
	elapsed += step
	pulse_acc += step
	for cell: Vector2i in field.tick_regen(step):
		tile_regenerated.emit(cell)
	_tick_graves(step)
	_tick_wisps(step)


## GDD §18.3: ordem de processamento do pulso.
func _pulse(is_final: bool) -> void:
	result.pulses += 1
	# 1. Tiles da área (ferramenta + raio + centro), recortados nas bordas.
	var cells := area_cells(cursor_cell)
	var rocks_in_area: Array[Vector2i] = []
	for cell: Vector2i in cells:
		if field.kind_of(cell) == FieldModel.Kind.ROCK and not field.is_hole(cell):
			rocks_in_area.append(cell)
	var dmg := damage()
	var crit_chance := stat(StatSheet.CRIT_CHANCE)
	var crit_mult := stat(StatSheet.CRIT_MULT)
	var regen_time := stat(StatSheet.REGEN_TIME)
	var copper_mult := stat(StatSheet.COPPER_MULT)
	var hits: Array[Dictionary] = []
	var broken_by_layer: Dictionary = {}
	var any_crit := false
	# 2. Para cada tile: crítico → dano no topo → Cobre por ponto; XP/Osso se quebrou.
	for cell: Vector2i in cells:
		if field.top_layer(cell) == null:
			continue
		var crit := crit_chance > 0.0 and rng.randf() < crit_chance
		var amount := dmg * crit_mult if crit else dmg
		var hit := field.apply_damage(cell, amount, regen_time)
		var layer: LayerData = hit.layer
		var useful: float = hit.useful
		var copper := useful * field.copper_per_point(layer) * copper_mult
		result.damage_dealt += useful
		result.copper_mined += copper
		if crit:
			any_crit = true
			result.max_crit = maxf(result.max_crit, amount)
		hits.append({"cell": cell, "damage": amount, "useful": useful, "copper": copper, "crit": crit, "layer": layer, "broke": bool(hit.broken)})
		if hit.broken:
			# O Caixão de uma cova quebra nas 2 metades no mesmo golpe (FieldModel.partner).
			var broken_cells: Array = hit.cells
			for bc: Vector2i in broken_cells:
				broken_by_layer[layer.id] = int(broken_by_layer.get(layer.id, 0)) + 1
				_on_layer_broken(bc, layer, crit)
	# 3. Covas completas.
	_resolve_graves()
	# 4. Dreno de rocha (GDD §4.5): por rocha dentro da área, salvo Picareta.
	if not rocks_in_area.is_empty() and not tool.ignores_rock_drain:
		var drain := balance.rock_oil_drain * rocks_in_area.size()
		oil = maxf(oil - drain, 0.0)
		result.oil_drained += drain
		oil_drained.emit(rocks_in_area, drain)
	# Campo Limpo (GDD §4.7).
	if not hits.is_empty() and field.is_all_holes():
		_field_clear()
	# 5. VFX/SFX agregados ficam com quem ouve este sinal.
	pulse_resolved.emit({
		"center": cursor_cell, "cells": cells, "hits": hits, "broken": broken_by_layer,
		"any_crit": any_crit, "final": is_final,
	})


func _on_layer_broken(cell: Vector2i, layer: LayerData, crit: bool) -> void:
	result.layers_broken += 1
	if layer == field.rock_layer:
		result.rocks_broken += 1
	var chance := layer.bone_chance
	if area.layers.has(layer):
		chance += stat(StatSheet.BONE_CHANCE)  # F02 soma nas camadas de solo (não em Rocha/Caixão)
	var bone := chance > 0.0 and rng.randf() < chance
	if bone:
		result.bones += 1.0
	var gained_xp := layer.xp * area.xp_mult * stat(StatSheet.XP_MULT)
	layer_broken.emit(cell, layer, bone, gained_xp, crit)
	if gained_xp > 0.0:
		_add_xp(gained_xp)


func _add_xp(amount: float) -> void:
	xp += amount
	result.xp_total += amount
	while xp >= xp_needed(level):
		xp -= xp_needed(level)
		level += 1
		result.level = level
		pending_level_ups.append(level)
		leveled_up.emit(level)
	xp_changed.emit(xp, xp_needed(level), level)


func _field_clear() -> void:
	var bonus := result.copper_mined * balance.field_clear_bonus
	result.field_clear_bonus += bonus
	result.field_clears += 1
	# Covas abertas fecham na hora; o campo inteiro volta e novas lápides surgem.
	for g: Dictionary in graves.duplicate():
		if bool(g.open):
			_close_grave(g, false)
	field.restore_all()
	field_cleared.emit(bonus)
	while _active_graves() < grave_target() and _spawn_grave():
		pass


# --- Covas (GDD §4.6) -----------------------------------------------------------

func _active_graves() -> int:
	return graves.size()


func _resolve_graves() -> void:
	for g: Dictionary in graves:
		if bool(g.open):
			continue
		var all_open := true
		for c: Vector2i in g.cells:
			if not field.is_hole(c):
				all_open = false
		if all_open:
			_open_grave(g)


func _open_grave(g: Dictionary) -> void:
	g.open = true
	g.timer = balance.grave_open_time
	var rewards := {
		"copper": balance.grave_copper * area.reward_mult * stat(StatSheet.COPPER_MULT),
		"souls": balance.grave_souls,
		"bones": float(rng.randi_range(balance.grave_bones_min, balance.grave_bones_max)),
		"xp": balance.grave_xp * area.xp_mult * stat(StatSheet.XP_MULT),
		"unrest": balance.grave_unrest,
	}
	result.copper_mined += float(rewards.copper)
	result.souls += float(rewards.souls)
	result.bones += float(rewards.bones)
	result.graves_opened += 1
	if result.first_grave_pulse < 0:
		result.first_grave_pulse = result.pulses
	var was_full := unrest >= 1.0
	unrest = minf(unrest + float(rewards.unrest), 1.0)
	result.unrest_end = unrest
	grave_opened.emit(g, rewards)
	unrest_changed.emit(unrest)
	if unrest >= 1.0 and not was_full:
		unrest_filled.emit()
	_add_xp(float(rewards.xp))


func _tick_graves(step: float) -> void:
	for g: Dictionary in graves.duplicate():
		if not bool(g.open):
			continue
		g.timer = float(g.timer) - step
		if float(g.timer) <= 0.0:
			_close_grave(g, true)


## Fecha a cova: os 2 tiles viram solo regenerando e outra lápide surge em outro lugar.
func _close_grave(g: Dictionary, respawn: bool) -> void:
	var regen_time := stat(StatSheet.REGEN_TIME)
	for c: Vector2i in g.cells:
		field.close_grave_tile(c, regen_time)
	# A lápide some: o tile volta a ser solo intacto.
	field.set_kind(g.tombstone as Vector2i, FieldModel.Kind.SOIL)
	graves.erase(g)
	grave_closed.emit(g)
	if respawn:
		_spawn_grave(g.cells as Array)


## Sorteia uma cova de 2 tiles intactos e livres. Retorna false se não houver lugar.
func _spawn_grave(avoid: Array = []) -> bool:
	var candidates: Array[Array] = []
	for i: int in field.tile_count():
		var head := field.cell_of(i)
		for axis: int in GRAVE_DIRS.size():
			var dir := GRAVE_DIRS[axis]
			if _grave_spot_ok(head, head + dir, head - dir, avoid):
				candidates.append([head, head + dir, axis])
	if candidates.is_empty():
		return false
	var pick: Array = candidates[rng.randi() % candidates.size()]
	spawn_grave_at(pick[0] as Vector2i, int(pick[2]))
	return true


## Cria a cova com cabeça em `head` no eixo `axis` (GRAVE_DIRS), sem checar o lugar.
## As 2 metades ficam ligadas no FieldModel: a cova é uma entidade só.
func spawn_grave_at(head: Vector2i, axis: int) -> Dictionary:
	var cells: Array[Vector2i] = [head, head + GRAVE_DIRS[axis]]
	for c: Vector2i in cells:
		field.set_kind(c, FieldModel.Kind.GRAVE)
	field.link_grave(cells[0], cells[1])
	field.set_kind(head - GRAVE_DIRS[axis], FieldModel.Kind.TOMBSTONE)
	var g := {
		"id": _next_id, "head": head, "cells": cells, "axis": axis,
		"tombstone": head - GRAVE_DIRS[axis], "variant": rng.randi() % 3, "open": false, "timer": 0.0,
	}
	_next_id += 1
	graves.append(g)
	grave_spawned.emit(g)
	return g


func _grave_spot_ok(head: Vector2i, foot: Vector2i, tombstone: Vector2i, avoid: Array) -> bool:
	# A lápide fica no tile atrás da cabeça, que vira bloqueado: precisa ser solo intacto.
	if not field.in_bounds(tombstone) or field.kind_of(tombstone) != FieldModel.Kind.SOIL or not field.is_intact(tombstone):
		return false
	if avoid.has(tombstone):
		return false
	for g: Dictionary in graves:
		if (g.tombstone as Vector2i) == tombstone:
			return false
	for c: Vector2i in [head, foot]:
		if not field.in_bounds(c) or field.kind_of(c) != FieldModel.Kind.SOIL or not field.is_intact(c):
			return false
		if avoid.has(c):
			return false
		# Uma faixa de 1 tile entre covas para as lápides não se amontoarem.
		for g: Dictionary in graves:
			for o: Vector2i in g.cells:
				if absi(o.x - c.x) <= 1 and absi(o.y - c.y) <= 1:
					return false
	return true


# --- Rochas (GDD §4.8) -----------------------------------------------------------

func _place_rocks() -> void:
	if field.rock_layer == null:
		return
	var count := rng.randi_range(balance.rocks_min, balance.rocks_max)
	for n: int in count:
		for attempt: int in 50:
			var cell := Vector2i(rng.randi_range(0, field.size - 1), rng.randi_range(0, field.size - 1))
			if field.kind_of(cell) == FieldModel.Kind.SOIL:
				field.set_kind(cell, FieldModel.Kind.ROCK)
				result.rocks_placed += 1
				break


# --- Fogos-fátuos (GDD §4.5) -----------------------------------------------------

func _next_wisp_delay() -> float:
	return maxf(1.0, balance.wisp_interval + rng.randf_range(-balance.wisp_interval_jitter, balance.wisp_interval_jitter))


func _tick_wisps(step: float) -> void:
	for w: Dictionary in wisps.duplicate():
		w.age = float(w.age) + step
		if float(w.age) >= balance.wisp_lifetime:
			wisps.erase(w)
			wisp_expired.emit(w)
	_wisp_timer -= step
	if _wisp_timer <= 0.0:
		_wisp_timer += _next_wisp_delay()
		var w := {"id": _next_id, "cell": Vector2i(rng.randi_range(0, field.size - 1), rng.randi_range(0, field.size - 1)), "age": 0.0}
		_next_id += 1
		wisps.append(w)
		wisp_spawned.emit(w)
	_collect_wisps()


## "Passar o cursor": o fogo-fátuo está dentro da área de escavação atual.
func _collect_wisps() -> void:
	if wisps.is_empty():
		return
	var cells := area_cells(cursor_cell)
	for w: Dictionary in wisps.duplicate():
		if cells.has(w.cell as Vector2i):
			var gain := stat(StatSheet.WISP_OIL)
			oil += gain
			result.wisps_collected += 1
			result.oil_from_wisps += gain
			wisps.erase(w)
			wisp_collected.emit(w, gain)


func _finish(reason: StringName) -> void:
	ended = true
	result.end_reason = reason
	result.duration = elapsed
	result.oil_left = oil
	# GDD §4.5: óleo sobrando vira bônus (1 s = 2% do Cobre do turno).
	result.oil_bonus = (result.copper_mined + result.field_clear_bonus) * oil * balance.oil_bonus_per_second
	result.level = level
	result.unrest_end = unrest
	finished.emit(result)
