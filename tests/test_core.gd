extends "res://tests/test_case.gd"
## Testes da lógica pura do M0: paleta, números, custos, XP, stats, campo, turno, árvore, save.

const NODES_DIR := "res://data/skill_nodes/"


func _initialize() -> void:
	_test_palette()
	_test_number_format()
	_test_costs()
	_test_stats()
	_test_field()
	_test_run_timing()
	_test_xp()
	_test_light()
	_test_field_clear()
	_test_dawn_and_oil_bonus()
	_test_tool_shapes()
	_test_tree()
	_test_copper_per_damage()
	_test_graves()
	_test_rocks()
	_test_wisps()
	_test_save_roundtrip()
	finish()


func _test_palette() -> void:
	check_eq(Palette.size(), 32, "paleta tem 32 cores")
	check_eq(Palette.index_of(Palette.color(11)), 11, "index_of(color(11))")
	check_eq(Palette.lit_index(13), 14, "lit 13 → 14 (DA §4.2)")
	check_eq(Palette.lit_index(25), 25, "lit 25 não muda")
	check_eq(Palette.index_of(Color(0.123, 0.5, 0.9)), 0, "cor fora da paleta → 0")


func _test_number_format() -> void:
	check_eq(NumberFormat.format(0), "0", "0")
	check_eq(NumberFormat.format(1234), "1.234", "1.234")
	check_eq(NumberFormat.format(999999), "999.999", "999.999 por extenso")
	check_eq(NumberFormat.format(1230000), "1,23 mi", "1,23 mi")
	check_eq(NumberFormat.format(999999999), "999,99 mi", "999,99 mi (trunca)")
	check_eq(NumberFormat.format(1e9), "1,00 bi", "bi")
	check_eq(NumberFormat.format(2.5e12), "2,50 tri", "tri")
	check_eq(NumberFormat.format(1e15), "1,00 qua", "qua")
	check_eq(NumberFormat.format(1e18), "1,00 aa", "aa")
	check_eq(NumberFormat.format(1e21), "1,00 ab", "ab")


func _test_costs() -> void:
	var nodes := {}
	for d: SkillNodeData in SkillTreeModel.load_definitions(NODES_DIR):
		nodes[d.id] = d
	check_eq(nodes.size(), 11, "11 nós carregados de data/skill_nodes")
	var e01: SkillNodeData = nodes[&"E01"]
	check_eq(e01.cost_at(0), 10.0, "E01 nv1 = 10")
	check_eq(e01.cost_at(1), 15.0, "E01 nv2 = ceil(14,5) = 15")
	check_eq(e01.cost_at(2), 22.0, "E01 nv3 = ceil(21,025) = 22")
	var e03: SkillNodeData = nodes[&"E03"]
	check_eq([e03.cost_at(0), e03.cost_at(1), e03.cost_at(2)], [15.0, 90.0, 540.0], "E03 15/90/540 Ossos")
	var c03: SkillNodeData = nodes[&"C03"]
	check_eq([c03.cost_at(0), c03.cost_at(1), c03.cost_at(2)], [30.0, 150.0, 750.0], "C03 30/150/750 Ossos")
	check_eq((nodes[&"L01"] as SkillNodeData).cost_at(0), 15.0, "L01 = 15")
	check_eq((nodes[&"F01"] as SkillNodeData).cost_at(0), 20.0, "F01 = 20")
	check_eq((nodes[&"N00"] as SkillNodeData).cost_at(0), 0.0, "N00 grátis")


func _test_stats() -> void:
	var sheet := StatSheet.from_balance(load_balance())
	check_eq(sheet.get_value(StatSheet.DAMAGE), 1.0, "dano base 1")
	check_eq(sheet.get_value(StatSheet.PULSE_INTERVAL), 1.0, "intervalo base 1,00 s")
	check_eq(sheet.get_value(StatSheet.OIL_MAX), 15.0, "óleo base 15 s")
	var mods: Array[StatModifier] = [
		StatModifier.make(StatSheet.DAMAGE, StatModifier.Op.ADD, 1).scaled(3),
		StatModifier.make(StatSheet.PULSE_INTERVAL, StatModifier.Op.MUL, 0.94).scaled(2),
		StatModifier.make(StatSheet.COPPER_MULT, StatModifier.Op.ADD, 0.1).scaled(2),
	]
	sheet.set_source(&"tree", mods)
	check_eq(sheet.get_value(StatSheet.DAMAGE), 4.0, "dano 1 + 3")
	check_eq(sheet.get_value(StatSheet.PULSE_INTERVAL), 0.94 * 0.94, "intervalo 0,94² (multiplicativo)")
	check_eq(sheet.get_value(StatSheet.COPPER_MULT), 1.2, "Cobre +20% aditivo")
	var big: Array[StatModifier] = [
		StatModifier.make(StatSheet.PULSE_INTERVAL, StatModifier.Op.MUL, 0.01),
		StatModifier.make(StatSheet.RADIUS, StatModifier.Op.ADD, 10),
		StatModifier.make(StatSheet.REGEN_TIME, StatModifier.Op.MUL, 0.01),
	]
	sheet.set_source(&"relics", big)
	check_eq(sheet.get_value(StatSheet.PULSE_INTERVAL), 0.15, "intervalo mínimo 0,15 s (§14.4)")
	check_eq(sheet.get_value(StatSheet.RADIUS), 4.0, "raio máximo 4 (§14.4)")
	check_eq(sheet.get_value(StatSheet.REGEN_TIME), 6.0, "regeneração mínima 6 s (§4.7)")
	var preview := sheet.with_source(&"tree", [] as Array[StatModifier])
	check_eq(preview.get_value(StatSheet.DAMAGE), 1.0, "prévia não altera o original (cópia)")
	check_eq(sheet.get_value(StatSheet.DAMAGE), 4.0, "original intacto após prévia")


func _test_field() -> void:
	var area := load_area()
	var f := FieldModel.new(area, 12)
	var c := Vector2i(3, 4)
	check_eq(f.stage_column(c), 0, "tile novo em S0 (grama)")
	var hit := f.apply_damage(c, 5.0, 25.0)
	check(bool(hit.broken) and (hit.layer as LayerData).id == &"grass", "dano 5 quebra a grama")
	check_eq(float(hit.useful), 2.0, "dano útil limitado ao HP restante (2)")
	check_eq(f.top_layer(c).id, &"dirt", "topo vira terra")
	check_eq(f.hp[f.index_of(c)], 4.0, "sem overflow: terra com HP cheio (4)")
	check_eq(f.copper_per_point(f.top_layer(c)), 0.5, "terra paga 0,5 Cobre por ponto (§4.3 v1.1)")
	f.apply_damage(c, 1.0, 25.0)
	f.tick_regen(100.0)
	check_eq(f.top_layer(c).id, &"dirt", "tile parcial não regenera (§4.7)")
	check_eq(f.hp[f.index_of(c)], 3.0, "HP parcial mantido")
	f.apply_damage(c, 3.0, 25.0)
	f.apply_damage(c, 8.0, 25.0)
	check(f.is_hole(c), "barro quebrado → Buraco")
	check_eq(f.stage_column(c), FieldModel.HOLE_COLUMN, "Buraco = coluna S3")
	check(f.apply_damage(c, 10.0, 25.0).layer == null, "dano em Buraco não faz nada")
	var regen := f.tick_regen(24.9)
	check(regen.is_empty() and f.is_hole(c), "ainda Buraco aos 24,9 s")
	regen = f.tick_regen(0.2)
	check(regen.has(c) and f.top_layer(c).id == &"grass", "regenera aos 25 s com todas as camadas")
	check_eq(f.hp[f.index_of(c)], 2.0, "HP da grama restaurado")
	check(not f.is_all_holes(), "campo não está todo em Buraco")


## Turno determinístico: sem covas, rochas nem fogos-fátuos, salvo se pedido.
func _make_run(overrides: Dictionary = {}, seed_value: int = 1234, balance: BalanceData = null) -> RunState:
	var o := {StatSheet.GRAVE_COUNT: 0.0}
	o.merge(overrides, true)
	return RunState.new(load_area(), load_tool(), balance if balance != null else clean_balance(), base_stats(o), seed_value)


func _test_run_timing() -> void:
	var run := _make_run()
	var pulses := [0]
	run.pulse_resolved.connect(func(_r: Dictionary) -> void: pulses[0] += 1)
	var ended := [false]
	run.finished.connect(func(_r: TurnResult) -> void: ended[0] = true)
	# Passos irregulares para provar que o resultado não depende do delta.
	var deltas := [0.016, 0.033, 0.1, 0.007, 0.25]
	var i := 0
	while not run.ended and i < 100000:
		run.advance(deltas[i % deltas.size()], Vector2i(6, 6))
		i += 1
	check(ended[0], "turno termina")
	check_eq(pulses[0], 15, "15 s / 1 s = 15 golpes (14 + último golpe §4.10)")
	check_eq(run.result.end_reason, &"oil", "fim por óleo")
	check_eq(run.result.duration, 15.0, "duração 15 s")
	# Parado no centro: 3×3 → grama (2) + terra (4) + barro (8) = 14 golpes por tile.
	check_eq(run.result.copper_mined, 126.0 * 0.5, "parado no centro: 126 de dano útil × 0,5 = 63 Cobre")
	check_eq(run.result.layers_broken, 27, "27 camadas")
	check_eq(run.result.xp_total, 9.0 * 6.0, "54 XP")


func _test_xp() -> void:
	var run := _make_run()
	check_eq(run.xp_needed(1), 10.0, "XP nv1→2 = 10")
	check_eq(run.xp_needed(2), 14.0, "XP nv2→3 = round(13,5) = 14")
	check_eq(run.xp_needed(3), 18.0, "XP nv3→4 = round(18,225) = 18")
	check_eq(run.xp_needed(4), 25.0, "XP nv4→5 = round(24,60) = 25")
	var levels: Array[int] = []
	run.leveled_up.connect(func(l: int) -> void: levels.append(l))
	run._add_xp(10.0 + 14.0 + 5.0)
	check_eq(levels, [2, 3] as Array[int], "29 XP → sobe para 2 e 3 (fila)")
	check_eq(run.xp, 5.0, "sobra 5 XP no nível 3")
	check_eq(run.pending_level_ups.size(), 2, "2 escolhas pendentes na fila")


func _test_light() -> void:
	var run := _make_run()
	check_eq(run.light_radius(), 4, "óleo cheio → raio de luz 4")
	run.oil = 15.0 * 0.6
	check_eq(run.light_radius(), 3, "60% → 3")
	run.oil = 15.0 * 0.3
	check_eq(run.light_radius(), 2, "30% → 2")
	run.oil = 1.0
	check_eq(run.light_radius(), 1, "<25% → 1")


func _test_field_clear() -> void:
	# Campo 3×3 inteiro dentro da área e dano alto: 3 golpes limpam tudo.
	var run := _make_run({StatSheet.FIELD_SIZE: 3.0, StatSheet.DAMAGE: 100.0})
	var bonus := [0.0]
	run.field_cleared.connect(func(b: float) -> void: bonus[0] = b)
	run.advance(3.0, Vector2i(1, 1))
	check_eq(run.result.field_clears, 1, "CAMPO LIMPO disparou 1 vez")
	check_eq(bonus[0], 63.0 * 0.2, "bônus = 20% do Cobre do turno")
	check(not run.field.is_all_holes() and run.field.hole_count() == 0, "campo regenerou na hora")


func _test_dawn_and_oil_bonus() -> void:
	var run := _make_run({StatSheet.OIL_MAX: 400.0})
	run.advance(1000.0, Vector2i(-50, -50))  # cursor fora do campo
	check_eq(run.result.end_reason, &"dawn", "300 s → o sol nasce (§4.1)")
	check_eq(run.result.duration, 300.0, "turno parou em 300 s")
	check_eq(run.result.oil_left, 100.0, "sobraram 100 s de óleo")
	var run2 := _make_run({StatSheet.OIL_MAX: 400.0})
	run2.result.copper_mined = 50.0
	run2.advance(1000.0, Vector2i(-50, -50))
	check_eq(run2.result.oil_bonus, 50.0 * 100.0 * 0.02, "bônus de óleo = 2% por segundo restante")


func _test_tool_shapes() -> void:
	var shovel := load_tool()
	check_eq(shovel.cells(Vector2i(5, 5), 1).size(), 9, "Pá raio 1 = 3×3")
	var f := FieldModel.new(load_area(), 12)
	check_eq(f.clip(shovel.cells(Vector2i(0, 0), 1)).size(), 4, "área recortada no canto = 4 tiles")
	check_eq(f.clip(shovel.cells(Vector2i(-2, -2), 1)).size(), 0, "fora do campo = 0 tiles")


func _test_tree() -> void:
	var tree := SkillTreeModel.new(SkillTreeModel.load_definitions(NODES_DIR))
	var shown: PackedStringArray = []
	for id: StringName in tree.order:
		if tree.is_revealed(id):
			shown.append(String(id))
	shown.sort()
	check_eq(",".join(shown), "E01,F01,L01,N00", "início: N00 + E01, L01, F01 revelados")
	check(tree.is_hinted(&"E02") and tree.is_hinted(&"E04"), "E02/E04 aparecem como '?'")
	check(not tree.is_hinted(&"E03") and not tree.is_revealed(&"E03"), "E03 invisível")
	var wallet := {&"copper": 0.0, &"bones": 0.0}
	var pending := tree.cheapest_pending(wallet)
	check_eq(pending.id, &"E01", "mais barato faltando = E01")
	check_eq(pending.missing, 10.0, "faltam 10")
	check(not tree.can_buy(&"E02", {&"copper": 999.0}), "não compra nó oculto")
	wallet[&"copper"] = 12.0
	check(tree.can_buy(&"E01", wallet), "compra E01 com 12")
	var revealed: PackedStringArray = []
	for id: StringName in tree.add_level(&"E01"):
		revealed.append(String(id))
	revealed.sort()
	check_eq(",".join(revealed), "E02,E04", "comprar E01 revela E02 e E04")
	check(tree.is_hinted(&"E03") and tree.is_hinted(&"E05"), "E03/E05 viram '?'")
	tree.add_level(&"E02")
	tree.add_level(&"E02")
	var sheet := StatSheet.from_balance(load_balance())
	sheet.set_source(SkillTreeModel.TREE_SOURCE, tree.collect_modifiers())
	check_eq(sheet.get_value(StatSheet.DAMAGE), 2.0, "E01 nv1 → dano 2")
	check_eq(sheet.get_value(StatSheet.PULSE_INTERVAL), 0.94 * 0.94, "E02 nv2 → intervalo 0,8836")
	var after := sheet.with_source(SkillTreeModel.TREE_SOURCE, tree.collect_modifiers(&"E01", 2))
	check_eq(after.get_value(StatSheet.DAMAGE), 3.0, "prévia E01 nv2 → dano 3")
	var saved := tree.to_save()
	var tree2 := SkillTreeModel.new(SkillTreeModel.load_definitions(NODES_DIR))
	tree2.load_save(saved)
	check_eq(tree2.level_of(&"E02"), 2, "níveis da árvore sobrevivem ao save")
	check(tree2.is_revealed(&"E03"), "revelação recalculada do save")


func _test_save_roundtrip() -> void:
	var path := "user://test_save.json"
	var ok := SaveIO.write(path, {"currencies": {"copper": 42.5}, "tree": {"E01": 3}})
	check(ok, "save escrito")
	var data := SaveIO.read(path)
	check_eq(int(data.get("version", 0)), 1, "save tem version = 1")
	check_eq(float((data.currencies as Dictionary).copper), 42.5, "Cobre salvo")
	check_eq(int((data.tree as Dictionary).E01), 3, "árvore salva")
	check_eq(int(SaveIO.migrate({}).version), 1, "save sem version migra para v1")
	SaveIO.delete(path)
	check(not FileAccess.file_exists(path), "save de teste apagado")


## GDD §4.3 v1.1: Cobre por ponto de dano, frações acumulam, excedente não paga.
func _test_copper_per_damage() -> void:
	var run := _make_run()
	run.advance(1.0, Vector2i(6, 6))
	check_eq(run.result.copper_mined, 9.0 * 0.5, "1 golpe de dano 1 em 9 tiles = 4,5 Cobre (antes de quebrar)")
	check_eq(run.result.layers_broken, 0, "nenhuma camada quebrou ainda")
	check_eq(run.result.xp_total, 0.0, "XP só na quebra")
	var run2 := _make_run({StatSheet.DAMAGE: 5.0})
	run2.advance(1.0, Vector2i(6, 6))
	check_eq(run2.result.copper_mined, 9.0 * 1.0, "dano 5 na grama (HP 2): só 2 pontos pagam → 9 Cobre")
	check_eq(run2.result.damage_dealt, 18.0, "dano útil 2 por tile")
	var run3 := _make_run({StatSheet.COPPER_MULT: 1.1})
	run3.advance(1.0, Vector2i(6, 6))
	check_eq(run3.result.copper_mined, 9.0 * 0.5 * 1.1, "F01 multiplica o Cobre por ponto")


func _test_graves() -> void:
	var run := _make_run({StatSheet.GRAVE_COUNT: 2.0})
	check_eq(run.graves.size(), 2, "2 covas simultâneas no início")
	var g: Dictionary = run.graves[0]
	var cells: Array = g.cells
	var d: Vector2i = (cells[1] as Vector2i) - (cells[0] as Vector2i)
	check(d == Vector2i(1, 0) or d == Vector2i(0, 1), "cova de 2 tiles alinhados (NO/NE)")
	var stack: Array = run.field.stacks[run.field.index_of(cells[0] as Vector2i)]
	check_eq(stack.size(), 4, "tile de cova = 3 camadas + Caixão")
	check_eq((stack[3] as LayerData).hp, 16.0, "Caixão HP = 2 × Barro (8) = 16")
	var tomb: Vector2i = g.tombstone
	check_eq(tomb, (cells[0] as Vector2i) - d, "lápide no tile atrás da cabeça")
	check(run.field.is_blocked(tomb), "tile da lápide bloqueado")
	check(not run.area_cells(tomb).has(tomb), "área de escavação ignora a lápide")
	check(run.field.top_layer(tomb) == null and not run.field.is_hole(tomb), "lápide: sem camada atingível e não conta como Buraco")
	check(run.field.apply_damage(tomb, 99.0, 25.0).layer == null, "lápide não recebe dano")
	check_eq(run.field.copper_per_point(stack[3] as LayerData), 0.0, "Caixão não paga Cobre por ponto")
	# Cava só a cova, com o cursor sobre ela: 14 + 40 = 54 golpes de dano 1.
	var opened := [{}]
	run.grave_opened.connect(func(_gr: Dictionary, rw: Dictionary) -> void: opened[0] = rw)
	run.oil = 1000.0
	run.oil_start = 1000.0
	var center: Vector2i = cells[0]
	var pulses := 0
	while run.result.graves_opened == 0 and pulses < 200:
		run.advance(1.0, center)
		pulses += 1
	check_eq(pulses, 30, "cova abre no 30º golpe com dano 1 (14 + 16)")
	check_eq(run.result.first_grave_pulse, 30, "first_grave_pulse registrado")
	var rw: Dictionary = opened[0]
	check_eq(float(rw.copper), 25.0, "cova paga 25 Cobre")
	check_eq(run.result.souls, 1.0, "1 Alma garantida")
	check(float(rw.bones) >= 2.0 and float(rw.bones) <= 5.0, "2–5 Ossos")
	check_eq(float(rw.xp), 15.0, "15 XP")
	check_eq(run.unrest, 0.1, "+10% de Inquietação")
	check(bool(g.open), "cova marcada como aberta")
	run.advance(2.9, Vector2i(-50, -50))
	check(run.graves.has(g), "cova aberta continua visível antes de 3 s")
	run.advance(0.2, Vector2i(-50, -50))
	check(not run.graves.has(g), "cova fecha após 3 s")
	check_eq(run.graves.size(), 2, "nova lápide surgiu (2 covas de novo)")
	check(run.field.kind_of(tomb) == FieldModel.Kind.SOIL and run.field.is_intact(tomb), "lápide some: tile volta a solo intacto")
	check(run.field.kind_of(cells[0] as Vector2i) == FieldModel.Kind.SOIL and run.field.is_hole(cells[0] as Vector2i), "tiles da cova viram Buraco de solo regenerando")
	var new_g: Dictionary = run.graves[run.graves.size() - 1]
	check(not (new_g.cells as Array).has(cells[0]) and not (new_g.cells as Array).has(cells[1]), "respawn em outro lugar")
	var unrest_run := _make_run({StatSheet.GRAVE_COUNT: 2.0}, 99)
	unrest_run.unrest = 0.95
	var filled := [false]
	unrest_run.unrest_filled.connect(func() -> void: filled[0] = true)
	unrest_run._open_grave(unrest_run.graves[0])
	check(filled[0] and unrest_run.unrest == 1.0, "Inquietação satura em 100% e avisa")
	# CAMPO LIMPO com lápides no campo: elas ficam fora do denominador.
	var clear_run := _make_run({StatSheet.GRAVE_COUNT: 1.0, StatSheet.FIELD_SIZE: 4.0, StatSheet.DAMAGE: 100.0, StatSheet.RADIUS: 4.0}, 11)
	check_eq(clear_run.graves.size(), 1, "campo 4×4 com 1 cova")
	clear_run.advance(4.0, Vector2i(1, 1))
	check(clear_run.result.field_clears >= 1, "CAMPO LIMPO dispara com a lápide em pé")


func _test_rocks() -> void:
	var b := clean_balance()
	b.rocks_min = 1
	b.rocks_max = 1
	var run := _make_run({}, 7, b)
	var rock := Vector2i(-1, -1)
	for i: int in run.field.tile_count():
		if run.field.kind[i] == FieldModel.Kind.ROCK:
			rock = run.field.cell_of(i)
	check(rock != Vector2i(-1, -1), "1 rocha posicionada")
	check_eq(run.field.top_layer(rock).hp, 60.0, "Rocha HP = 30 × Grama (2) = 60")
	var oil_before := run.oil
	run.advance(1.0, rock)
	check_eq(run.oil, oil_before - 1.0 - 0.5, "rocha na área drena 0,5 s por golpe")
	run.oil = 1000.0
	var bones_before := run.result.bones
	while run.field.kind_of(rock) == FieldModel.Kind.ROCK:
		run.advance(1.0, rock)
	check(run.result.bones >= bones_before + 1.0, "rocha quebrada solta 1 Osso")
	check_eq(run.result.rocks_broken, 1, "rocks_broken = 1")
	check(run.field.is_hole(rock), "rocha quebrada vira Buraco (regenera como solo)")


func _test_wisps() -> void:
	var b := clean_balance()
	b.wisp_interval = 12.0
	b.wisp_interval_jitter = 0.0
	var run := _make_run({StatSheet.OIL_MAX: 100.0}, 5, b)
	var spawned := [{}]
	run.wisp_spawned.connect(func(w: Dictionary) -> void: spawned[0] = w)
	run.advance(11.9, Vector2i(-50, -50))
	check(run.wisps.is_empty(), "sem fogo-fátuo antes de ~12 s")
	run.advance(0.2, Vector2i(-50, -50))
	check_eq(run.wisps.size(), 1, "fogo-fátuo surge aos 12 s")
	var w: Dictionary = spawned[0]
	var oil_before := run.oil
	run.advance(0.01, w.cell as Vector2i)
	check(run.wisps.is_empty() and run.result.wisps_collected == 1, "passar o cursor coleta")
	check_eq(run.oil, oil_before - 0.01 + 2.0, "+2 s de óleo")
	run.advance(12.0, Vector2i(-50, -50))
	check_eq(run.wisps.size(), 1, "outro fogo-fátuo")
	run.advance(5.1, Vector2i(-50, -50))
	check(run.wisps.is_empty(), "some após 5 s")
