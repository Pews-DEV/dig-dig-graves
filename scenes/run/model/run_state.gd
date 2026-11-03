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
## GDD §4.11: Inquietação em 100% libera "Enfrentar ‹chefe›" no Pátio.
signal unrest_filled()
## GDD §4.11: a Inquietação cruzou `BalanceData.unrest_warning_at` (90%) nesta noite.
signal unrest_warned()
signal wisp_spawned(wisp: Dictionary)
signal wisp_collected(wisp: Dictionary, oil: float)
signal wisp_expired(wisp: Dictionary)
signal oil_drained(cells: Array[Vector2i], amount: float)
## GDD §4.5: L06 devolveu o óleo; LX parou a queima por `duration` s.
signal second_wind_triggered(oil: float)
signal constellation_started(duration: float)
signal stomp_used(cells: Array[Vector2i])
signal stomp_ready()
## Lápide com efeito (cruz/musgo) pagou o bônus dela ao abrir (GDD §4.6).
signal tombstone_effect(grave: Dictionary)
signal boss_changed(hp: float, max_hp: float, cells: Array[Vector2i])
## Dano aplicado no chefe neste golpe (já com `boss_damage`).
signal boss_damaged(amount: float)
signal boss_hopped(old_cells: Array[Vector2i], new_cells: Array[Vector2i])
signal gold_coin_spawned(coin: Dictionary)
signal gold_coin_collected(coin: Dictionary, copper: float)
signal wanderer_collected(wanderer: Dictionary, souls: float)
signal finished(result: TurnResult)

const EPS := 0.000001
## Eixo da cova (MANIFEST grave_a1): 0 = NO–SE (pés em cabeça + (1,0), lápide em cabeça − (1,0));
## 1 = NE–SO (pés em cabeça + (0,1), lápide em cabeça − (0,1)). A lápide fica sempre atrás.
const GRAVE_DIRS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 1)]
const GRAVE_TYPE_OVAL := &"oval"
const GRAVE_TYPE_CROSS := &"cross"
const GRAVE_TYPE_MOSS := &"moss"
const GRAVE_TYPES: Array[StringName] = [GRAVE_TYPE_OVAL, GRAVE_TYPE_CROSS, GRAVE_TYPE_MOSS]

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

## Covas: {id, head, cells, axis, tombstone, type, variant, open, timer}.
var graves: Array[Dictionary] = []
## Fogos-fátuos: {id, cell, age}.
var wisps: Array[Dictionary] = []
var candles: Array[Vector2i] = []
var gold_coin: Dictionary = {}
var wanderers: Array[Dictionary] = []
var _gold_timer: float = 20.0
var _wanderer_timer: float = 15.0
var _wanderer_move_timer: float = 3.0
var _next_id: int = 1
var _wisp_timer: float = 0.0
var _wisps_collected_this_turn: int = 0
## Instantes (elapsed) dos fogos-fátuos ainda contando para a Constelação (LX).
var _constellation_hits: Array[float] = []
## LX: segundos restantes com o óleo parado.
var oil_frozen_left: float = 0.0
var _second_wind_ready: bool = false
## GDD §4.11: tremores (Inquietação cheia numa noite comum).
var tremor: bool = false
var _copper_at_last_clear: float = 0.0
var stomp_cooldown_left: float = 0.0
var normal_pulses: int = 0
var boss_active: bool = false
var boss_data: BossData
var boss_hp: float = 35000.0
var boss_hp_max: float = 35000.0
var boss_cells: Array[Vector2i] = []
var boss_hop_timer: float = 4.0
var boss_invulnerable: float = 0.0
var boss_hops: int = 0
var boss_rematch: bool = false


func _init(p_area: AreaData, p_tool: ToolData, p_balance: BalanceData, p_stats: Dictionary, seed_value: int = 0, p_unrest: float = 0.0, p_boss: bool = false, p_boss_data: BossData = null) -> void:
	area = p_area.duplicate() as AreaData
	if not bool(p_stats.get("ossuary_layer", false)):
		var active_layers: Array[LayerData] = []
		for layer: LayerData in area.layers:
			if not layer.deep or layer.id != &"ossada":
				active_layers.append(layer)
		area.layers = active_layers
	tool = p_tool
	balance = p_balance
	stats = p_stats.duplicate()
	boss_rematch = bool(p_stats.get("boss_1_won", false))
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
	boss_active = p_boss
	boss_data = p_boss_data
	result.boss_encounter = p_boss
	result.boss_rematch = p_boss and boss_rematch
	tremor = not p_boss and unrest >= 1.0 - EPS
	result.tremor = tremor
	_second_wind_ready = stat(StatSheet.SECOND_WIND) > 0.0
	_gold_timer = _gold_interval()
	_wanderer_timer = balance.wanderer_respawn
	_wanderer_move_timer = balance.wanderer_move_interval
	_wisp_timer = _next_wisp_delay()
	_place_rocks()
	for i: int in grave_target():
		_spawn_grave()
	_place_candles()
	for i: int in wanderer_target():
		_spawn_wanderer()
	if p_boss and boss_data != null:
		boss_hp = boss_data.hp
		boss_hp_max = boss_hp
		boss_hop_timer = boss_data.hop_interval
		boss_cells = _boss_start_cells()
		result.boss_hp_remaining = boss_hp
		result.boss_hp_max = boss_hp_max


func stat(id: StringName) -> float:
	return float(stats.get(id, balance.base_stats.get(id, 0.0)))


func pulse_interval() -> float:
	var minimum := float(balance.stat_min.get(StatSheet.PULSE_INTERVAL, 0.15))
	return maxf(stat(StatSheet.PULSE_INTERVAL) * tool.interval_mult, minimum)


func damage() -> float:
	return stat(StatSheet.DAMAGE) * tool.damage_mult


func radius() -> int:
	return roundi(stat(StatSheet.RADIUS))


func area_step() -> int:
	return clampi(roundi(stat(StatSheet.AREA_STEP)), 0, 10)


func grave_target() -> int:
	return roundi(stat(StatSheet.GRAVE_COUNT))


func wanderer_target() -> int:
	return clampi(roundi(stat(StatSheet.WANDERERS)), 0, balance.wanderer_max)


func xp_needed(for_level: int) -> float:
	# GDD §4.9: 10 × 1,45^(n−1) × XP do estágio, arredondada.
	return float(roundi(balance.xp_base * pow(balance.xp_growth, for_level - 1) * area.xp_mult))


## Ossos por camada que solta Osso (Rocha inclusive): 1 × Ossos do estágio × all_mult.
func bone_value() -> float:
	return area.bones_mult * stat(StatSheet.ALL_MULT)


## LX: o óleo está parado pela Constelação.
func oil_frozen() -> bool:
	return oil_frozen_left > EPS


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
func area_cells(center: Vector2i, include_ring: bool = false) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var base_cells := field.clip(tool.cells_for_step(center, area_step(), tool_rotation))
	var candidates := base_cells.duplicate()
	if include_ring:
		var seen: Dictionary = {}
		for c: Vector2i in base_cells:
			seen[c] = true
			for offset: Vector2i in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)]:
				seen[c + offset] = true
		candidates.clear()
		for candidate: Variant in seen:
			candidates.append(candidate as Vector2i)
	for c: Vector2i in field.clip(candidates):
		if not field.is_blocked(c):
			out.append(c)
	return out


## Recarga do Pisão em s (E11; mínimo em `BalanceData.stat_min`).
func stomp_cooldown() -> float:
	return stat(StatSheet.STOMP_COOLDOWN)


func stomp_is_ready() -> bool:
	return stat(StatSheet.STOMP_ENABLED) > 0.0 and stomp_cooldown_left <= EPS


## Pisão manual (GDD §4.4): clique/Q/A ou auto-pisão. Golpe extra ×4 que não gasta o relógio.
func use_stomp() -> bool:
	if ended or not stomp_is_ready():
		return false
	stomp_cooldown_left = stomp_cooldown()
	_stomp()
	return true


func _stomp() -> void:
	result.stomps += 1
	var ring := stat(StatSheet.STOMP_RING) > 0.0
	var cells := area_cells(cursor_cell, ring)
	stomp_used.emit(cells)
	_pulse(false, stat(StatSheet.STOMP_MULT), true)


func grave_at(cell: Vector2i) -> Dictionary:
	for g: Dictionary in graves:
		if (g.cells as Array).has(cell) or (g.tombstone as Vector2i) == cell:
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
		var oil_rate := _oil_rate()
		var to_oil := oil / oil_rate if oil_rate > 0.0 else INF
		var to_thaw := oil_frozen_left if oil_frozen() else INF
		var to_dawn := maxf(balance.turn_cap_seconds - elapsed, 0.0)
		var to_boss_hop := boss_hop_timer if boss_active and boss_hp > 0.0 else INF
		var step := minf(left, minf(to_pulse, minf(to_oil, minf(to_thaw, minf(to_dawn, to_boss_hop)))))
		_pass_time(step)
		left -= step
		if oil <= EPS:
			oil = 0.0
			if _try_second_wind():
				continue
			# GDD §4.10: o óleo acaba → a pá dá um último golpe → fim.
			_pulse(true)
			if not ended:
				_finish(&"oil")
		elif elapsed >= balance.turn_cap_seconds - EPS:
			_finish(&"dawn")
		elif pulse_acc >= interval - EPS:
			pulse_acc = maxf(pulse_acc - interval, 0.0)
			_pulse(false)
			if oil <= EPS and not ended and not _try_second_wind():  # rochas drenaram o resto do óleo neste golpe
				oil = 0.0
				_finish(&"oil")
		# GDD §16: auto-pisão dispara assim que o Pisão recarrega.
		if not ended and bool(stats.get("auto_stomp_option", false)) and stomp_is_ready():
			use_stomp()


func _oil_rate() -> float:
	if oil_frozen():
		return 0.0
	return balance.oil_burn_rate * stat(StatSheet.OIL_BURN)


## GDD §4.5 / L06: 1× por noite, ao zerar o óleo, a lanterna volta com 5 s.
func _try_second_wind() -> bool:
	if not _second_wind_ready or ended:
		return false
	_second_wind_ready = false
	oil = balance.second_wind_oil
	result.second_wind_used = true
	second_wind_triggered.emit(oil)
	return true


func _pass_time(step: float) -> void:
	if step <= 0.0:
		return
	oil = maxf(oil - step * _oil_rate(), 0.0)
	if oil_frozen():
		oil_frozen_left = maxf(0.0, oil_frozen_left - step)
	elapsed += step
	pulse_acc += step
	for cell: Vector2i in field.tick_regen(step, candles, balance.candle_regen_mult, balance.candle_radius):
		tile_regenerated.emit(cell)
	_tick_board_elements(step)
	if stomp_cooldown_left > 0.0:
		stomp_cooldown_left = maxf(0.0, stomp_cooldown_left - step)
		if stomp_cooldown_left <= EPS:
			stomp_ready.emit()
	if boss_active and not ended:
		boss_invulnerable = maxf(0.0, boss_invulnerable - step)
		boss_hop_timer -= step
		if boss_hop_timer <= 0.0 and boss_hp > 0.0:
			_hop_boss()
	_tick_graves(step)
	_tick_wisps(step)


## GDD §18.3: ordem de processamento do pulso.
func _pulse(is_final: bool, damage_scale: float = 1.0, is_stomp: bool = false) -> void:
	result.pulses += 1
	if not is_stomp:
		normal_pulses += 1
	# 1. Tiles da área (ferramenta + passo + centro), recortados nas bordas.
	var cells := area_cells(cursor_cell, is_stomp and stat(StatSheet.STOMP_RING) > 0.0)
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
	var boss_damage := 0.0
	var ring := is_stomp and stat(StatSheet.STOMP_RING) > 0.0
	var base_area: Dictionary = {}
	if ring:
		for c: Vector2i in area_cells(cursor_cell):
			base_area[c] = true
	var double_hit := stat(StatSheet.DOUBLE_HIT) > 0.0
	var carry := stat(StatSheet.EXCESS_CARRIES) > 0.0
	var deep_mult := stat(StatSheet.DEEP_MULT)
	# 2. Para cada tile: crítico → dano no topo → Cobre por ponto; XP/Osso se quebrou.
	for cell: Vector2i in cells:
		if gold_coin.has("cell") and (gold_coin.cell as Vector2i) == cell:
			_collect_gold_coin()
		for wanderer: Dictionary in wanderers.duplicate():
			if (wanderer.cell as Vector2i) == cell:
				_collect_wanderer(wanderer)
		var crit := crit_chance > 0.0 and rng.randf() < crit_chance
		var amount := (dmg * crit_mult if crit else dmg) * damage_scale
		if ring and not base_area.has(cell):
			# E12a: o anel em volta da área leva ×2 (no lugar do ×4 do Pisão).
			amount = (dmg * crit_mult if crit else dmg) * balance.stomp_ring_mult
		var boss_amount := amount * (1.0 + balance.double_hit_share if double_hit else 1.0)
		if boss_active and boss_cells.has(cell) and boss_invulnerable <= EPS:
			boss_damage += boss_amount
		if crit:
			any_crit = true
			result.max_crit = maxf(result.max_crit, amount)
		if field.top_layer(cell) == null:
			continue
		# Lápide com musgo: o Caixão já nasce mais duro (spawn_grave_at); o dano é o normal.
		var hit := field.apply_damage(cell, amount, regen_time, carry, deep_mult)
		if double_hit:
			var extra_hit := field.apply_damage(cell, amount * balance.double_hit_share, regen_time, carry, deep_mult)
			(hit.layers as Array).append_array(extra_hit.layers as Array)
			hit.useful = float(hit.useful) + float(extra_hit.useful)
			hit.broken = bool(hit.broken) or bool(extra_hit.broken)
		var layer: LayerData = hit.layer
		var useful: float = hit.useful
		var copper := 0.0
		var candle_bonus := balance.candle_copper_mult if _near_candle(cell) else 1.0
		for band: Dictionary in hit.layers:
			var band_layer: LayerData = band.layer
			var band_useful: float = float(band.useful)
			copper += band_useful * field.copper_per_point(band_layer) * copper_mult * stat(StatSheet.ALL_MULT) * candle_bonus
			if bool(band.broken):
				for bc: Vector2i in band.cells:
					broken_by_layer[band_layer.id] = int(broken_by_layer.get(band_layer.id, 0)) + 1
					_on_layer_broken(bc, band_layer, crit)
		result.damage_dealt += useful
		result.copper_mined += copper
		hits.append({"cell": cell, "damage": amount, "useful": useful, "copper": copper, "crit": crit, "layer": layer, "broke": bool(hit.broken)})
	# 3. Covas completas.
	_resolve_graves()
	# 4. Chefe: cada tile da área sobre a posição dele aplica dano uma vez.
	if boss_active and boss_hp > 0.0 and boss_damage > 0.0:
		var dealt := minf(boss_hp, boss_damage * stat(StatSheet.BOSS_DAMAGE))
		boss_hp = maxf(0.0, boss_hp - dealt)
		result.boss_damage_dealt += dealt
		result.boss_hp_remaining = boss_hp
		boss_damaged.emit(dealt)
		boss_changed.emit(boss_hp, boss_hp_max, boss_cells)
		if boss_hp <= EPS:
			_boss_victory()
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
		"center": cursor_cell, "cells": cells, "hits": hits, "broken": broken_by_layer, "stomp": is_stomp,
		"any_crit": any_crit, "final": is_final,
	})
	# E12b (Pisão Ritmado): a cada N golpes normais sai um Pisão extra, sem depender
	# nem gastar a recarga do manual ("além do manual", GDD §4.4).
	var every := maxi(1, balance.stomp_auto_every)
	if not is_stomp and not is_final and not ended and normal_pulses % every == 0 \
			and stat(StatSheet.STOMP_ENABLED) > 0.0 and stat(StatSheet.STOMP_AUTO) > 0.0:
		_stomp()


func _on_layer_broken(cell: Vector2i, layer: LayerData, crit: bool) -> void:
	result.layers_broken += 1
	if layer == field.rock_layer:
		result.rocks_broken += 1
	var chance := layer.bone_chance
	if area.layers.has(layer):
		chance += stat(StatSheet.BONE_CHANCE)  # F02 soma nas camadas de solo (não em Rocha/Caixão)
	var bone := chance > 0.0 and rng.randf() < chance
	if bone:
		# GDD §4.3/§4.8: 1 Osso × Ossos do estágio (Rocha inclusive).
		result.bones += bone_value()
	var gained_xp := layer.xp * area.xp_mult * stat(StatSheet.XP_MULT)
	layer_broken.emit(cell, layer, bone, gained_xp, crit)
	if gained_xp > 0.0:
		_add_xp(gained_xp)


func _add_xp(amount: float) -> void:
	xp += amount
	result.xp_total += amount
	# GDD §4.9: teto de nível por noite (o XP excedente não vira nível).
	while level < balance.max_night_level and xp >= xp_needed(level):
		xp -= xp_needed(level)
		level += 1
		result.level = level
		pending_level_ups.append(level)
		leveled_up.emit(level)
	if level >= balance.max_night_level:
		xp = minf(xp, xp_needed(level))
	xp_changed.emit(xp, xp_needed(level), level)


func _field_clear() -> void:
	var bonus := maxf(0.0, result.copper_mined - _copper_at_last_clear) * balance.field_clear_bonus
	_copper_at_last_clear = result.copper_mined
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


func _boss_start_cells() -> Array[Vector2i]:
	var candidates := _boss_positions()
	if candidates.is_empty():
		var fallback := Vector2i.ZERO
		return _boss_cells_at(fallback)
	return _boss_cells_at(candidates[rng.randi() % candidates.size()])


func _boss_positions() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var width := boss_data.cells.x if boss_data != null else 2
	var height := boss_data.cells.y if boss_data != null else 2
	for y: int in range(maxi(1, field.size - height + 1)):
		for x: int in range(maxi(1, field.size - width + 1)):
			var origin := Vector2i(x, y)
			var valid := true
			for cell: Vector2i in _boss_cells_at(origin):
				if field.kind_of(cell) == FieldModel.Kind.GRAVE or field.is_blocked(cell) or field.kind_of(cell) == FieldModel.Kind.ROCK:
					valid = false
					break
			if valid:
				out.append(origin)
	return out


func _boss_cells_at(origin: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var width := boss_data.cells.x if boss_data != null else 2
	var height := boss_data.cells.y if boss_data != null else 2
	for y: int in height:
		for x: int in width:
			out.append(origin + Vector2i(x, y))
	return out


func _hop_boss() -> void:
	var hop_interval := boss_data.hop_interval if boss_data != null else 4.0
	boss_hop_timer += hop_interval
	boss_invulnerable = boss_data.hop_invulnerability if boss_data != null else 0.6
	boss_hops += 1
	var old_cells: Array[Vector2i] = boss_cells.duplicate()
	for old_cell: Vector2i in old_cells:
		field.leave_hole(old_cell, stat(StatSheet.REGEN_TIME))
	var candidates := _boss_positions()
	if not candidates.is_empty():
		var movable: Array[Vector2i] = []
		for candidate: Vector2i in candidates:
			if candidate != (old_cells[0] as Vector2i):
				movable.append(candidate)
		var choices: Array[Vector2i] = movable if not movable.is_empty() else candidates
		var origin: Vector2i = choices[rng.randi() % choices.size()]
		boss_cells = _boss_cells_at(origin)
	boss_hopped.emit(old_cells, boss_cells)
	boss_changed.emit(boss_hp, boss_hp_max, boss_cells)


func _boss_victory() -> void:
	result.boss_victory = true
	result.boss_hp_remaining = 0.0
	var data := boss_data if boss_data != null else BossData.new()
	if boss_rematch:
		# GDD §4.11: revanche paga só 20% das Almas da 1ª vitória.
		result.boss_reward_souls = data.rematch_souls
	else:
		result.boss_reward_souls = data.first_victory_souls
		result.boss_reward_bones = data.first_victory_bones
	result.souls += result.boss_reward_souls
	result.bones += result.boss_reward_bones
	_finish(&"boss_victory")


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
	var grave_type := StringName(g.get("type", GRAVE_TYPE_OVAL))
	var interest_mult := 1.0 + float(result.graves_opened) * stat(StatSheet.GRAVE_INTEREST)
	var rewards := {
		"copper": balance.grave_copper * area.reward_mult * stat(StatSheet.GRAVE_REWARD) * interest_mult * stat(StatSheet.COPPER_MULT) * stat(StatSheet.ALL_MULT),
		"souls": balance.grave_souls * area.souls_mult * stat(StatSheet.SOUL_MULT) * stat(StatSheet.ALL_MULT),
		"bones": float(rng.randi_range(balance.grave_bones_min, balance.grave_bones_max)) * area.bones_mult,
		"xp": balance.grave_xp * area.xp_mult * stat(StatSheet.XP_MULT),
		"unrest": (1.0 / maxf(1.0, area.graves_for_unrest)) * stat(StatSheet.UNREST_MULT),
	}
	var effect := false
	if grave_type == GRAVE_TYPE_CROSS:
		rewards.souls = float(rewards.souls) + balance.cross_souls * area.souls_mult * stat(StatSheet.SOUL_MULT) * stat(StatSheet.ALL_MULT)
		effect = true
	elif grave_type == GRAVE_TYPE_MOSS:
		rewards.bones = float(rewards.bones) * balance.moss_bones_mult
		effect = true
	rewards.bones = float(rewards.bones) * stat(StatSheet.ALL_MULT)
	if tremor:
		# GDD §4.11: tremores dão +25% de Almas nas covas (incentivo, não punição).
		var extra := float(rewards.souls) * balance.unrest_tremor_souls
		rewards.souls = float(rewards.souls) + extra
		result.tremor_souls += extra
	# L04: o teto (oil_grave_cap) já vem em segundos por noite (3 s por nível).
	var oil_cap := stat(StatSheet.OIL_GRAVE_CAP)
	var oil_gain := minf(stat(StatSheet.OIL_PER_GRAVE), maxf(0.0, oil_cap - result.oil_from_graves))
	rewards["oil"] = oil_gain
	result.oil_from_graves += oil_gain
	oil += oil_gain
	result.copper_mined += float(rewards.copper)
	result.souls += float(rewards.souls)
	result.bones += float(rewards.bones)
	result.graves_opened += 1
	if result.first_grave_pulse < 0:
		result.first_grave_pulse = result.pulses
	var was_full := unrest >= 1.0
	var was_warned := unrest >= balance.unrest_warning_at
	unrest = minf(unrest + float(rewards.unrest), 1.0)
	result.unrest_end = unrest
	grave_opened.emit(g, rewards)
	if effect:
		tombstone_effect.emit(g)
	unrest_changed.emit(unrest)
	if unrest >= balance.unrest_warning_at and not was_warned:
		unrest_warned.emit()
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
func spawn_grave_at(head: Vector2i, axis: int, forced_type: StringName = &"") -> Dictionary:
	var grave_type := forced_type if GRAVE_TYPES.has(forced_type) else _roll_grave_type()
	var cells: Array[Vector2i] = [head, head + GRAVE_DIRS[axis]]
	for c: Vector2i in cells:
		field.set_kind(c, FieldModel.Kind.GRAVE)
	var coffin_override: LayerData = null
	if grave_type == GRAVE_TYPE_MOSS and field.coffin_layer != null:
		coffin_override = field.coffin_layer.duplicate() as LayerData
		coffin_override.hp *= balance.moss_coffin_mult
	field.link_grave(cells[0], cells[1], coffin_override)
	field.set_kind(head - GRAVE_DIRS[axis], FieldModel.Kind.TOMBSTONE)
	var g := {
		"id": _next_id, "head": head, "cells": cells, "axis": axis,
		"tombstone": head - GRAVE_DIRS[axis], "type": grave_type,
		"variant": GRAVE_TYPES.find(grave_type), "open": false, "timer": 0.0,
	}
	_next_id += 1
	graves.append(g)
	grave_spawned.emit(g)
	return g


func _roll_grave_type() -> StringName:
	var weights := area.grave_type_weights
	if weights.size() != GRAVE_TYPES.size():
		weights = PackedFloat32Array([50.0, 25.0, 25.0])
	var total := 0.0
	for weight: float in weights:
		total += maxf(0.0, weight)
	if total <= EPS:
		return GRAVE_TYPE_OVAL
	var roll := rng.randf() * total
	for index: int in GRAVE_TYPES.size():
		roll -= maxf(0.0, weights[index])
		if roll < 0.0:
			return GRAVE_TYPES[index]
	return GRAVE_TYPE_OVAL


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
	var rate := maxf(0.1, stat(StatSheet.WISP_RATE))
	return maxf(1.0, (balance.wisp_interval + rng.randf_range(-balance.wisp_interval_jitter, balance.wisp_interval_jitter)) / rate)


func _tick_wisps(step: float) -> void:
	for w: Dictionary in wisps.duplicate():
		w.age = float(w.age) + step
		if float(w.age) >= stat(StatSheet.WISP_LIFE):
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
			# GDD §4.5 (D10): cada fogo-fátuo da noite vale wisp_decay do anterior.
			var gain := stat(StatSheet.WISP_OIL) * pow(stat(StatSheet.WISP_DECAY), _wisps_collected_this_turn)
			_wisps_collected_this_turn += 1
			oil += gain
			result.wisps_collected += 1
			result.oil_from_wisps += gain
			wisps.erase(w)
			wisp_collected.emit(w, gain)
			_check_constellation()


## LX (GDD §4.5/§14.4): N fogos-fátuos em menos de `constellation_window` s param o óleo
## por `constellation_freeze` s; a contagem zera a cada Constelação (1× a cada 3 fogos).
func _check_constellation() -> void:
	if stat(StatSheet.CONSTELLATION) <= 0.0:
		return
	_constellation_hits.append(elapsed)
	while not _constellation_hits.is_empty() and elapsed - _constellation_hits[0] > balance.constellation_window:
		_constellation_hits.pop_front()
	if _constellation_hits.size() >= maxi(1, balance.constellation_wisps):
		_constellation_hits.clear()
		oil_frozen_left = maxf(oil_frozen_left, balance.constellation_freeze)
		result.constellations += 1
		constellation_started.emit(balance.constellation_freeze)


func _finish(reason: StringName) -> void:
	ended = true
	result.end_reason = reason
	result.duration = elapsed
	result.oil_left = oil
	var night_copper := result.copper_mined + result.field_clear_bonus
	# GDD §4.5: óleo sobrando vira bônus (1 s = 2% do Cobre do turno).
	result.oil_bonus = night_copper * oil * balance.oil_bonus_per_second
	# F05 (Herança): % do Cobre da noite como bônus no Resumo.
	result.inheritance_bonus = night_copper * stat(StatSheet.INHERITANCE)
	result.level = level
	result.unrest_end = unrest
	if boss_active and not result.boss_victory:
		# O chefe foge sem custo; a Inquietação continua cheia para permitir revanche.
		result.boss_hp_max = boss_hp_max
		result.unrest_end = 1.0
		unrest = 1.0
	finished.emit(result)


# --- Elementos de tabuleiro (GDD §4.8) ---------------------------------------------

func _place_candles() -> void:
	var count := clampi(roundi(stat(StatSheet.CANDLES)), 0, balance.candle_max)
	for n: int in count:
		var candidates: Array[Vector2i] = []
		for i: int in field.tile_count():
			var candidate_cell := field.cell_of(i)
			if field.kind_of(candidate_cell) == FieldModel.Kind.SOIL and field.is_intact(candidate_cell):
				candidates.append(candidate_cell)
		if candidates.is_empty():
			break
		var candle_cell: Vector2i = candidates[rng.randi() % candidates.size()]
		field.set_kind(candle_cell, FieldModel.Kind.CANDLE)
		candles.append(candle_cell)


func _near_candle(cell: Vector2i) -> bool:
	return FieldModel.near_any(cell, candles, balance.candle_radius)


func _tick_board_elements(step: float) -> void:
	if stat(StatSheet.GOLD_COIN) > 0.0:
		if gold_coin.is_empty():
			_gold_timer -= step
			if _gold_timer <= 0.0:
				var cell := _random_open_cell()
				if cell.x >= 0:
					gold_coin = {"cell": cell, "age": maxf(0.0, -_gold_timer)}
					gold_coin_spawned.emit(gold_coin)
				_gold_timer = _gold_interval()
		else:
			gold_coin.age = float(gold_coin.age) + step
			if float(gold_coin.age) >= balance.gold_coin_life:
				gold_coin.clear()
				_gold_timer = _gold_interval()
	_wanderer_timer -= step
	_wanderer_move_timer -= step
	if _wanderer_move_timer <= 0.0:
		_wanderer_move_timer += balance.wanderer_move_interval
		for w: Dictionary in wanderers:
			_drift_wanderer(w)
	if _wanderer_timer <= 0.0:
		_wanderer_timer += balance.wanderer_respawn
		if wanderers.size() < wanderer_target():
			_spawn_wanderer()
	_collect_board_elements()


func _spawn_wanderer() -> void:
	var cell := _random_open_cell()
	if cell.x >= 0:
		wanderers.append({"cell": cell, "from": cell, "moved_at": elapsed})


## A alminha flutua devagar (GDD §4.8): a cada intervalo segue para um tile vizinho livre.
## `from` e `moved_at` deixam a visualização interpolar o caminho.
func _drift_wanderer(w: Dictionary) -> void:
	var here: Vector2i = w.cell
	var options: Array[Vector2i] = []
	for offset: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var next := here + offset
		if field.in_bounds(next) and not field.is_blocked(next):
			options.append(next)
	w.from = here
	w.moved_at = elapsed
	if not options.is_empty():
		w.cell = options[rng.randi() % options.size()]


func _random_open_cell() -> Vector2i:
	var cells: Array[Vector2i] = []
	for i: int in field.tile_count():
		var cell := field.cell_of(i)
		if field.kind_of(cell) == FieldModel.Kind.SOIL and not field.is_hole(cell):
			cells.append(cell)
	return cells[rng.randi() % cells.size()] if not cells.is_empty() else Vector2i(-1, -1)


func _collect_board_elements() -> void:
	if gold_coin.is_empty() and wanderers.is_empty():
		return
	var cells := area_cells(cursor_cell)
	if not gold_coin.is_empty() and cells.has(gold_coin.cell as Vector2i):
		_collect_gold_coin()
	for w: Dictionary in wanderers.duplicate():
		if cells.has(w.cell as Vector2i):
			_collect_wanderer(w)


func _collect_gold_coin() -> void:
	if gold_coin.is_empty():
		return
	var coin := gold_coin
	var reward := (result.copper_mined + result.field_clear_bonus) * balance.gold_coin_share
	result.copper_mined += reward
	gold_coin = {}
	_gold_timer = _gold_interval()
	gold_coin_collected.emit(coin, reward)


## F09: a cada 20 s, −3 s por nível acima do 1º (mínimo 5 s).
func _gold_interval() -> float:
	var extra_levels := maxf(0.0, stat(StatSheet.GOLD_COIN) - 1.0)
	return maxf(balance.gold_coin_min_interval, balance.gold_coin_interval - balance.gold_coin_interval_step * extra_levels)


func _collect_wanderer(wanderer: Dictionary) -> void:
	if not wanderers.has(wanderer):
		return
	var reward := balance.wanderer_souls * area.souls_mult * stat(StatSheet.SOUL_MULT) * stat(StatSheet.ALL_MULT)
	result.souls += reward
	wanderers.erase(wanderer)
	_wanderer_timer = balance.wanderer_respawn
	wanderer_collected.emit(wanderer, reward)
