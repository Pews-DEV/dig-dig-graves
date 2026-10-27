extends "res://tests/test_case.gd"
## Sanidade do GDD §14.1 (v1.1, Cobre por ponto de dano): 1º turno (15 s, 3×3, dano 1,
## 1 golpe/s) deve render ~50–60 Cobre com ~75% de aproveitamento, e nenhuma estratégia
## ativa razoável pode render menos que ficar parado. Inclui covas, rochas e fogos-fátuos
## com o balanceamento real, e uma progressão de vários turnos para achar a 1ª Cova Aberta (§14.3).

const RUNS := 500
const WASTE := 0.25  # "~75% de aproveitamento": 1 em cada 4 golpes cai em trânsito
const OFF := Vector2i(-100, -100)
const PROGRESSION_TURNS := 15
const PROGRESSION_RUNS := 100


func _initialize() -> void:
	print("=== 1º turno (GDD §14.1), %d sementes, campo real com covas/rochas/fogos-fátuos ===" % RUNS)
	var parked := _simulate(_strategy_parked, RUNS)
	var greedy := _simulate(_strategy_greedy, 60)
	var walk_deep := _simulate(_strategy_blocks.bind(false, 0.0), RUNS)
	var walk_shallow := _simulate(_strategy_blocks.bind(true, 0.0), RUNS)
	var deep := _simulate(_strategy_blocks.bind(false, WASTE), RUNS)
	var shallow := _simulate(_strategy_blocks.bind(true, WASTE), RUNS)
	var hunter := _simulate(_strategy_grave.bind(WASTE), RUNS)
	_print("Parado no centro", parked)
	_print("Ótimo guloso (Cobre por golpe)", greedy)
	_print("Ativo 100%: cava cada 3×3 até o fundo", walk_deep)
	_print("Ativo 100%: raspa grama+terra e segue", walk_shallow)
	_print("Humano 75%: até o fundo", deep)
	_print("Humano 75%: raspa e segue", shallow)
	_print("Humano 75%: caça a cova", hunter)
	var max_copper := 15.0 * 9.0 * 0.5
	print("Teto teórico (sem cova): 15 golpes × 9 tiles × 0,5 Cobre/ponto = %.1f" % max_copper)

	var human: float = (float(deep.copper) + float(shallow.copper)) * 0.5
	# Alvo "~50–60" (§14.1) com tolerância de 5%% no piso: 47,5–60.
	check(human >= 47.5 and human <= 60.0, "humano ~75%%: média %.1f Cobre (alvo ~50–60, piso 47,5)" % human)
	for pair: Array in [["ativo 100% fundo", walk_deep], ["ativo 100% raso", walk_shallow], ["ótimo guloso", greedy]]:
		var r: Dictionary = pair[1]
		check(float(r.copper) >= float(parked.copper) - 0.01, "%s (%.1f) ≥ parado (%.1f)" % [pair[0], r.copper, parked.copper])
	var human_xp: float = (float(deep.xp) + float(shallow.xp)) * 0.5
	check(human_xp >= 25.0 and human_xp <= 50.0, "XP humano ~35–40 (%.1f)" % human_xp)

	print("\n=== Covas no 1º turno ===")
	var to_open := _pulses_to_open_grave()
	print("Golpes para abrir 1 cova com dano 1 e a cova inteira na área: %d (14 de solo + 16 de Caixão por tile)" % to_open)
	print("Covas abertas no 1º turno (caçador 75%%): %.2f por turno" % hunter.graves)
	check_eq(to_open, 30, "30 golpes por cova com dano 1")

	print("\n=== Progressão (%d jogadores, compra o nó mais barato possível ao fim de cada turno) ===" % PROGRESSION_RUNS)
	var first_turns: Array[int] = []
	for i: int in PROGRESSION_RUNS:
		first_turns.append(_progression(3000 + i, i == 0))
	first_turns.sort()
	var never := first_turns.count(-1)
	var opened := first_turns.filter(func(t: int) -> bool: return t > 0)
	var median: int = opened[opened.size() / 2] if not opened.is_empty() else -1
	print("1ª Cova Aberta (caçador 75%%): turno mínimo %s, mediana %s, máximo %s; %d de %d sem cova em %d turnos" % [
		str(opened.front()) if not opened.is_empty() else "—", str(median), str(opened.back()) if not opened.is_empty() else "—",
		never, PROGRESSION_RUNS, PROGRESSION_TURNS])
	check(median > 0 and median <= 2, "GDD §14.3/§4.6: 1ª Cova Aberta com mediana ≤ turno 2 (mediana: turno %d)" % median)
	finish()


func _warn(ok: bool, label: String) -> void:
	print(("OK    " if ok else "AVISO ") + label)


func _print(label: String, r: Dictionary) -> void:
	print("%-40s Cobre %5.1f | XP %5.1f | dano útil %5.1f | golpes %4.1f | covas %.2f | rochas %.2f | fogos %.2f" % [
		label, r.copper, r.xp, r.damage, r.pulses, r.graves, r.rocks, r.wisps])


func _new_run(seed_value: int, stats_overrides: Dictionary = {}) -> RunState:
	return RunState.new(load_area(), load_tool(), load_balance(), base_stats(stats_overrides), seed_value)


## Roda `runs` turnos; a estratégia escolhe o centro antes de cada golpe.
func _simulate(strategy: Callable, runs: int, stats_overrides: Dictionary = {}) -> Dictionary:
	var acc := {"copper": 0.0, "xp": 0.0, "damage": 0.0, "pulses": 0.0, "graves": 0.0, "rocks": 0.0, "wisps": 0.0}
	for i: int in runs:
		var r := _play(_new_run(1000 + i, stats_overrides), strategy, 77 + i)
		acc.copper += r.copper_total()
		acc.xp += r.xp_total
		acc.damage += r.damage_dealt
		acc.pulses += r.pulses
		acc.graves += r.graves_opened
		acc.rocks += r.rocks_placed
		acc.wisps += r.wisps_collected
	for k: String in acc:
		acc[k] = float(acc[k]) / runs
	return acc


func _play(run: RunState, strategy: Callable, seed_value: int) -> TurnResult:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var memory := {"block": 0}
	while not run.ended:
		var cell: Vector2i = strategy.call(run, rng, memory)
		run.advance(run.pulse_interval(), cell)
	return run.result


func _strategy_parked(_run: RunState, _rng: RandomNumberGenerator, _mem: Dictionary) -> Vector2i:
	return Vector2i(6, 6)


## Centro que mais rende Cobre neste golpe (evita rocha, que drena óleo).
func _strategy_greedy(run: RunState, _rng: RandomNumberGenerator, _mem: Dictionary) -> Vector2i:
	var best := Vector2i(6, 6)
	var best_score := -INF
	var f := run.field
	for y: int in f.size:
		for x: int in f.size:
			var score := 0.0
			for c: Vector2i in run.area_cells(Vector2i(x, y)):
				var top := f.top_layer(c)
				if top == null:
					continue
				if f.kind_of(c) == FieldModel.Kind.ROCK:
					score -= 5.0
				score += minf(run.damage(), f.hp[f.index_of(c)]) * f.copper_per_point(top)
			if score > best_score:
				best_score = score
				best = Vector2i(x, y)
	return best


## Percorre blocos 3×3 em ordem; `shallow` = sai quando o bloco não tem mais grama/terra.
## Evita blocos com rocha (o jogador vê a rocha e desvia).
func _strategy_blocks(run: RunState, rng: RandomNumberGenerator, mem: Dictionary, shallow: bool, waste: float) -> Vector2i:
	if waste > 0.0 and rng.randf() < waste:
		return OFF
	var f := run.field
	var per_row := int(f.size / 3.0)
	for guard: int in per_row * per_row * 2:
		var b := int(mem.block) % (per_row * per_row)
		var center := Vector2i(1 + (b % per_row) * 3, 1 + int(b / float(per_row)) * 3)
		var useful := false
		var rock := false
		for c: Vector2i in run.area_cells(center):
			var top := f.top_layer(c)
			if f.kind_of(c) == FieldModel.Kind.ROCK and top != null:
				rock = true
			elif top != null and top.copper > 0.0 and (not shallow or top.stage_column < 2):
				useful = true
		if useful and not rock:
			return center
		mem.block = int(mem.block) + 1
	return _strategy_greedy(run, rng, mem)


## Fica sobre a primeira cova (área 3×3 cobre os 2 tiles); sem cova, raspa blocos.
func _strategy_grave(run: RunState, rng: RandomNumberGenerator, mem: Dictionary, waste: float) -> Vector2i:
	if waste > 0.0 and rng.randf() < waste:
		return OFF
	for g: Dictionary in run.graves:
		if not bool(g.open):
			return g.head as Vector2i
	return _strategy_blocks(run, rng, mem, true, 0.0)


func _pulses_to_open_grave() -> int:
	var b := clean_balance()
	var stats := base_stats({StatSheet.OIL_MAX: 1000.0})
	var run := RunState.new(load_area(), load_tool(), b, stats, 42)
	var head: Vector2i = run.graves[0].head
	while run.result.graves_opened == 0 and run.result.pulses < 1000:
		run.advance(1.0, head)
	return run.result.first_grave_pulse


## Vários turnos com compra do nó mais barato; retorna o turno da 1ª Cova Aberta (−1 = nunca).
func _progression(seed_value: int, verbose: bool) -> int:
	var tree := SkillTreeModel.new(SkillTreeModel.load_definitions("res://data/skill_nodes/"))
	var wallet := {&"copper": 0.0, &"bones": 0.0, &"souls": 0.0}
	var sheet := StatSheet.from_balance(load_balance())
	for turn: int in range(1, PROGRESSION_TURNS + 1):
		sheet.set_source(SkillTreeModel.TREE_SOURCE, tree.collect_modifiers())
		var run := RunState.new(load_area(), load_tool(), load_balance(), sheet.snapshot(), seed_value * 31 + turn)
		var r := _play(run, _strategy_grave.bind(WASTE), seed_value + turn)
		wallet[&"copper"] = float(wallet[&"copper"]) + r.copper_total()
		wallet[&"bones"] = float(wallet[&"bones"]) + r.bones
		var bought: PackedStringArray = []
		while true:
			var p := tree.cheapest_pending(wallet)
			if p.is_empty() or not bool(p.affordable):
				break
			wallet[p.currency] = float(wallet[p.currency]) - float(p.cost)
			tree.add_level(p.id as StringName)
			bought.append(String(p.id))
		if verbose:
			print("  turno %2d: Cobre %5.1f, golpes %2d, dano %.0f, óleo %2.0f s, covas %d | comprou %s" % [
				turn, r.copper_total(), r.pulses, run.damage(), run.oil_start, r.graves_opened, ",".join(bought)])
		if r.graves_opened > 0:
			return turn
	return -1
