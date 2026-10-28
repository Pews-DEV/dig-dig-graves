extends "res://tests/test_case.gd"
## Campanha automática gulosa para medir ritmo e procurar sequências longas sem compra.

const MAX_TURNS := 180


func _initialize() -> void:
	var seeds := PackedInt64Array([101, 202, 303, 404, 505])
	var seed_override := OS.get_environment("MARCO_A_TEST_SEED")
	var seeds_override := OS.get_environment("MARCO_A_TEST_SEEDS")
	if not seed_override.is_empty():
		seeds = PackedInt64Array([int(seed_override)])
	elif not seeds_override.is_empty():
		seeds.clear()
		for value: String in seeds_override.split(",", false):
			var normalized := value.strip_edges()
			check(normalized.is_valid_int(), "MARCO_A_TEST_SEEDS contém apenas inteiros")
			if normalized.is_valid_int():
				seeds.append(int(normalized))
	check(not seeds.is_empty(), "sim_campaign recebe ao menos uma semente")
	for seed: int in seeds:
		print("\n=== Campanha Marco A · semente %d ===" % seed)
		_run_campaign(seed)
	finish()


func _run_campaign(seed: int) -> void:
	var stage := load("res://data/stages/stage_1.tres") as StageData
	var unrest_override := OS.get_environment("MARCO_A_TEST_UNREST")
	if not unrest_override.is_empty():
		stage.graves_for_unrest = float(unrest_override)
	var balance := clean_balance()
	var shovel := load_tool()
	var tree := SkillTreeModel.new(SkillTreeModel.load_definitions("res://data/skill_nodes/"))
	var e06_test_cost := OS.get_environment("MARCO_A_TEST_E06_COST")
	if not e06_test_cost.is_empty():
		tree.get_node_data(&"E06").base_cost = float(e06_test_cost)
	var wallet := {&"copper": 0.0, &"bones": 0.0, &"souls": 0.0}
	var unrest := 0.0
	var total_time := 0.0
	var dry_streak := 0
	var max_dry_streak := 0
	var reached_boss_at := -1.0
	var reached_3x3_at := -1.0
	var first_purchase_at := -1.0
	var campaign_time := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for turn: int in MAX_TURNS:
		var sheet := StatSheet.from_balance(balance)
		sheet.set_source(SkillTreeModel.TREE_SOURCE, tree.collect_modifiers())
		var stats := sheet.snapshot()
		var run := RunState.new(stage, shovel, balance, stats, 5000 + turn, unrest)
		var guard := 0
		while not run.ended and guard < 5000:
			var cell := _best_target(run, rng)
			if rng.randf() < 0.25:
				cell = Vector2i(-100, -100) # 25% dos golpes em trânsito (§14.1).
			elif not run.wisps.is_empty() and rng.randf() < 0.85:
				# Jogador atento desvia o cursor para pegar a alma; o alvo guloso
				# ainda é usado quando não há fogo-fátuo.
				cell = (run.wisps[0].cell as Vector2i)
			if float(stats.get(StatSheet.STOMP_ENABLED, 0.0)) > 0.0 and run.stomp_cooldown_left <= 0.000001 and rng.randf() < 0.85:
				run.cursor_cell = cell
				run.use_stomp()
			run.advance(run.pulse_interval(), cell)
			guard += 1
		var result := run.result
		unrest = result.unrest_end
		total_time += result.duration
		wallet[&"copper"] = float(wallet[&"copper"]) + result.copper_total()
		wallet[&"bones"] = float(wallet[&"bones"]) + result.bones
		wallet[&"souls"] = float(wallet[&"souls"]) + result.souls
		var buys := 0
		while true:
			var next := _cheapest_legal_affordable(tree, wallet)
			if next.is_empty():
				break
			var id := next.id as StringName
			var cost := float(next.cost)
			var currency := next.currency as StringName
			wallet[currency] = float(wallet.get(currency, 0.0)) - cost
			tree.add_level(id)
			buys += 1
			if first_purchase_at < 0.0:
				first_purchase_at = campaign_time + result.duration + 12.0 + float(buys) * 0.6
		if buys > 0:
			dry_streak = 0
		else:
			dry_streak += 1
			max_dry_streak = maxi(max_dry_streak, dry_streak)
		print("turn %2d: %.1f s | covas %d | inquietação %.0f%% | compra %d | cobre %.0f | ossos %.0f | pá passo %.0f" % [turn + 1, result.duration, result.graves_opened, unrest * 100.0, buys, result.copper_total(), result.bones, float(stats.get(StatSheet.AREA_STEP, 0.0))])
		campaign_time += result.duration + 12.0 + float(buys) * 0.6 # pausa entre noites e compras (§14.1).
		if turn == 0:
			tree.set_trigger(&"turn_2")
		var post_buy_sheet := StatSheet.from_balance(balance)
		post_buy_sheet.set_source(SkillTreeModel.TREE_SOURCE, tree.collect_modifiers())
		if reached_3x3_at < 0.0 and float(post_buy_sheet.snapshot().get(StatSheet.AREA_STEP, 0.0)) >= 4.0:
			reached_3x3_at = campaign_time
		if unrest >= 1.0 - 0.000001:
			reached_boss_at = campaign_time
			var area_time := "não alcançada" if reached_3x3_at < 0.0 else "%.1f min" % (reached_3x3_at / 60.0)
			print("Chefe liberado após %d noites / %.1f min de campanha (%.1f min de escavação); primeiro nó em %.1f s; área 3×3 em %s; E03/E13/E06: %d/%d/%d; Ossos restantes: %.0f; Inquietação alvo: %.0f covas; maior seca de compras: %d noites." % [turn + 1, campaign_time / 60.0, total_time / 60.0, first_purchase_at, area_time, tree.level_of(&"E03"), tree.level_of(&"E13"), tree.level_of(&"E06"), float(wallet[&"bones"]), stage.graves_for_unrest, max_dry_streak])
			break
	if reached_boss_at < 0.0:
		print("Chefe não liberado em %d noites (%.1f min); Inquietação %.0f%%; maior seca de compras: %d noites." % [MAX_TURNS, total_time / 60.0, unrest * 100.0, max_dry_streak])
	check(reached_boss_at >= 0.0, "semente %d: campanha gulosa libera o chefe" % seed)
	check(first_purchase_at >= 0.0 and first_purchase_at <= 40.0, "semente %d: primeiro nó comprado até 40 s (GDD §19.1)" % seed)
	if reached_boss_at >= 0.0 and (reached_boss_at / 60.0 < 35.0 or reached_boss_at / 60.0 > 45.0):
		print("AVISO: campanha sem pausas/UI ficou fora da janela de 35–45 min; confirmar ritmo em playtest humano.")
	if reached_3x3_at < 25.0 * 60.0 or reached_3x3_at > 35.0 * 60.0 + 0.5:
		print("AVISO: área 3×3 ficou fora da janela de 25–35 min do plano do Marco A.")
	check(max_dry_streak < 5, "semente %d: não passa 5 noites sem compra" % seed)
	check(reached_3x3_at >= 25.0 * 60.0 and reached_3x3_at <= 35.0 * 60.0 + 0.5, "semente %d: área 3×3 chega entre 25 e 35 min (plano do Marco A)" % seed)
	check(reached_boss_at >= 35.0 * 60.0 and reached_boss_at <= 45.0 * 60.0, "semente %d: chefe libera entre 35 e 45 min (GDD §19.1)" % seed)


func _best_target(run: RunState, _rng: RandomNumberGenerator) -> Vector2i:
	var f := run.field
	var best := Vector2i(2, 2)
	var best_score := -INF
	for y: int in f.size:
		for x: int in f.size:
			var center := Vector2i(x, y)
			var score := 0.0
			var cells := run.area_cells(center)
			for grave: Dictionary in run.graves:
				if bool(grave.open):
					continue
				var covers := 0
				for grave_cell: Vector2i in grave.cells:
					if cells.has(grave_cell):
						covers += 1
				if covers == 2:
					score += 100000.0
				elif covers == 1:
					score += 100.0
			for cell: Vector2i in cells:
				var layer := f.top_layer(cell)
				if layer != null:
					score += minf(run.damage(), f.hp[f.index_of(cell)]) * f.copper_per_point(layer)
			if score > best_score:
				best_score = score
				best = center
	return best


func _cheapest_legal_affordable(tree: SkillTreeModel, wallet: Dictionary) -> Dictionary:
	var best: Dictionary = {}
	for id: StringName in tree.order:
		if not tree.can_buy(id, wallet):
			continue
		var cost := tree.next_cost(id)
		if best.is_empty() or cost < float(best.cost):
			best = {"id": id, "cost": cost, "currency": tree.get_node_data(id).currency}
	return best
