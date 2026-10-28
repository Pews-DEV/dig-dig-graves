extends "res://tests/test_case.gd"
## Cova como UMA entidade de 2 tiles (GDD §4.6, MANIFEST grave_a1): o caixão aparece
## inteiro, abre inteiro e some inteiro, nos 2 eixos, com e sem luz.
## Uso: godot --headless --path . -s res://tests/test_graves.gd

const HEAD := Vector2i(2, 2)
const BIG := 100000.0


func _initialize() -> void:
	for axis: int in RunState.GRAVE_DIRS.size():
		_test_orientation(axis)
	_test_uneven_progress()
	_test_uneven_progress_in_turn()
	_test_regen_and_field_clear()
	_test_save_load()
	finish()


func _make_run(overrides: Dictionary = {}, seed_value: int = 77) -> RunState:
	var o := {StatSheet.GRAVE_COUNT: 0.0, StatSheet.RADIUS: 1.0, StatSheet.OIL_MAX: 1000.0}
	o.merge(overrides, true)
	return RunState.new(load_area(), load_tool(), clean_balance(), base_stats(o), seed_value)


## Quebra `layers` camadas de solo do tile (−1 = todas; o excedente não passa: 1 golpe por camada).
func _dig_soil(f: FieldModel, cell: Vector2i, layers: int = -1) -> void:
	var n := f.area.layers.size() if layers < 0 else layers
	for _k: int in n:
		f.apply_damage(cell, BIG, 25.0)


## Invariante: nunca só uma metade com caixão; as 2 metades sempre na mesma linha do atlas.
func _grave_whole(f: FieldModel, g: Dictionary) -> bool:
	var one: Array[Dictionary] = [g]
	var tiles := GraveVisuals.atlas_cells(f, one)
	var cells: Array = g.cells
	if tiles.is_empty():
		return true
	if tiles.size() != 2 or not tiles.has(cells[0]) or not tiles.has(cells[1]):
		return false
	var a: Vector2i = tiles[cells[0]]
	var b: Vector2i = tiles[cells[1]]
	return a.y == b.y and b.x == a.x + 1


func _test_orientation(axis: int) -> void:
	var tag := "eixo %d" % axis
	var run := _make_run()
	var f := run.field
	var g := run.spawn_grave_at(HEAD, axis)
	var cells: Array = g.cells
	var head: Vector2i = cells[0]
	var foot: Vector2i = cells[1]
	check_eq(foot - head, RunState.GRAVE_DIRS[axis], tag + ": pés = cabeça + direção do eixo")
	check_eq(g.tombstone as Vector2i, head - RunState.GRAVE_DIRS[axis], tag + ": lápide atrás da cabeça")
	check(f.grave_partner(head) == foot and f.grave_partner(foot) == head, tag + ": metades ligadas no modelo")
	check(GraveVisuals.atlas_cells(f, run.graves).is_empty(), tag + ": cova intacta não mostra caixão")
	_dig_soil(f, head)
	_dig_soil(f, foot)
	var tiles := GraveVisuals.atlas_cells(f, run.graves)
	check_eq(tiles.get(head, Vector2i(-1, -1)), Vector2i(axis * 2, TileAtlas.GRAVE_ROW_EXPOSED), tag + ": cabeça na coluna eixo×2")
	check_eq(tiles.get(foot, Vector2i(-1, -1)), Vector2i(axis * 2 + 1, TileAtlas.GRAVE_ROW_EXPOSED), tag + ": pés na coluna eixo×2+1")
	# Luz (DA §4.2): uma metade no raio → as 2 usam o atlas _lit.
	for lit_cell: Vector2i in [head, foot]:
		var lit := PackedByteArray()
		lit.resize(f.tile_count())
		lit.fill(0)
		lit[f.index_of(lit_cell)] = 1
		var ov := GraveVisuals.light_overrides(f, run.graves, lit)
		check(int(ov.get(f.index_of(head), 0)) == 1 and int(ov.get(f.index_of(foot), 0)) == 1, tag + ": só %s na luz → cova inteira iluminada" % str(lit_cell))
	var dark := PackedByteArray()
	dark.resize(f.tile_count())
	dark.fill(0)
	var ov_dark := GraveVisuals.light_overrides(f, run.graves, dark)
	check(int(ov_dark.get(f.index_of(head), 1)) == 0 and int(ov_dark.get(f.index_of(foot), 1)) == 0, tag + ": fora da luz → as 2 metades no atlas normal")


func _test_uneven_progress() -> void:
	var run := _make_run()
	var f := run.field
	var g := run.spawn_grave_at(HEAD, 0)
	var cells: Array = g.cells
	var head: Vector2i = cells[0]
	var foot: Vector2i = cells[1]
	_dig_soil(f, head)
	check(f.top_layer(head) == null and not f.is_hole(head), "cabeça adiantada: sem camada atingível, mas não é Buraco")
	check_eq(f.stage_column(head), FieldModel.HOLE_COLUMN, "cabeça adiantada desenha fundo de buraco (S3)")
	check(not f.is_coffin_exposed(head) and not f.is_coffin_exposed(foot), "caixão não exposto com os pés ainda em solo")
	check_eq(GraveVisuals.state_row(f, g), GraveVisuals.ROW_BURIED, "nenhuma metade do caixão aparece")
	var hit := f.apply_damage(head, BIG, 25.0)
	check(hit.layer == null and float(hit.useful) == 0.0, "metade adiantada não recebe dano")
	check_eq(f.tick_regen(1000.0).size(), 0, "metade adiantada não regenera")
	_dig_soil(f, foot, 1)
	check_eq(GraveVisuals.state_row(f, g), GraveVisuals.ROW_BURIED, "pés pela metade: caixão continua enterrado")
	_dig_soil(f, foot, f.area.layers.size() - 1)
	check(f.is_coffin_exposed(head) and f.is_coffin_exposed(foot), "as 2 metades chegaram: caixão exposto")
	var full := f.layer_max_hp(f.coffin_layer) * 2.0
	check_eq(f.hp[f.index_of(head)], full, "HP do caixão = soma das 2 metades")
	check_eq(f.hp[f.index_of(foot)], full, "mesmo HP nas 2 metades")
	check(_grave_whole(f, g) and GraveVisuals.state_row(f, g) == TileAtlas.GRAVE_ROW_EXPOSED, "caixão inteiro, linha 'exposto'")
	# Dano só nos pés racha o caixão inteiro.
	f.apply_damage(foot, full * 0.5 + 1.0, 25.0)
	check_eq(f.hp[f.index_of(head)], f.hp[f.index_of(foot)], "dano nos pés desce o HP da cabeça junto")
	check(_grave_whole(f, g) and GraveVisuals.state_row(f, g) == TileAtlas.GRAVE_ROW_CRACKED, "as 2 metades rachadas juntas")
	var last := f.apply_damage(head, BIG, 25.0)
	var broke: Array = last.cells
	check(bool(last.broken) and broke.size() == 2 and broke.has(head) and broke.has(foot), "caixão quebra nas 2 metades no mesmo golpe")
	check(f.is_hole(head) and f.is_hole(foot), "as 2 metades viram Buraco juntas")


## Turno de verdade: a área pega só os pés e depois a cova toda; a cada golpe a cova é inteira.
func _test_uneven_progress_in_turn() -> void:
	var run := _make_run()
	var g := run.spawn_grave_at(HEAD, 1)
	var cells: Array = g.cells
	var head: Vector2i = cells[0]
	var foot: Vector2i = cells[1]
	var only_foot := foot
	var area := run.area_cells(only_foot)
	check(area.has(foot) and not area.has(head), "cursor além dos pés: área pega só uma metade")
	var opened := [0]
	run.grave_opened.connect(func(_gr: Dictionary, _rw: Dictionary) -> void: opened[0] += 1)
	var coffins: Array[Vector2i] = []
	run.layer_broken.connect(func(c: Vector2i, l: LayerData, _b: bool, _x: float, _cr: bool) -> void:
		if l == run.field.coffin_layer:
			coffins.append(c))
	var whole := true
	for _p: int in 60:
		run.advance(1.0, only_foot)
		whole = whole and _grave_whole(run.field, g)
	check(whole, "só os pés cavados: nunca aparece meio caixão")
	check(run.field.top_layer(foot) == null and not run.field.is_hole(foot), "pés esperam a cabeça (fundo de buraco)")
	check(run.field.is_intact(head), "cabeça intocada")
	var pulses := 0
	while opened[0] == 0 and pulses < 400:
		run.advance(1.0, head)
		run.advance(1.0, foot)
		pulses += 1
		whole = whole and _grave_whole(run.field, g)
	check(whole, "cavando a cova toda: caixão sempre inteiro")
	check_eq(opened[0], 1, "cova abre uma vez")
	check(coffins.size() == 2 and coffins.has(head) and coffins.has(foot), "Caixão quebra nas 2 metades (XP/Osso de 2 caixões, como antes)")
	var tiles := GraveVisuals.atlas_cells(run.field, run.graves)
	check(tiles.get(head, Vector2i(-1, -1)) == Vector2i(2, TileAtlas.GRAVE_ROW_OPEN) and tiles.get(foot, Vector2i(-1, -1)) == Vector2i(3, TileAtlas.GRAVE_ROW_OPEN), "cova aberta: as 2 metades na linha 'aberta'")


func _test_regen_and_field_clear() -> void:
	var run := _make_run()
	var f := run.field
	var g := run.spawn_grave_at(HEAD, 0)
	var cells: Array = g.cells
	var head: Vector2i = cells[0]
	var foot: Vector2i = cells[1]
	# Campo limpo/restauração mantém a cova ligada e inteira.
	_dig_soil(f, head)
	f.restore_all()
	check(f.grave_partner(head) == foot and f.is_intact(head) and f.is_intact(foot), "restore_all mantém a cova ligada e intacta")
	var regen_at: Dictionary = {}
	run.tile_regenerated.connect(func(c: Vector2i) -> void: regen_at[c] = run.elapsed)
	var guard := 0
	while not bool(g.open) and guard < 400:
		run.advance(1.0, head)
		run.advance(1.0, foot)
		guard += 1
	check(bool(g.open), "cova abriu")
	var timer := run.balance.grave_open_time
	run.advance(timer * 0.5, Vector2i(-50, -50))
	check(run.graves.has(g) and GraveVisuals.state_row(f, g) == TileAtlas.GRAVE_ROW_OPEN, "aberta inteira durante os 3 s")
	run.advance(timer, Vector2i(-50, -50))
	check(not run.graves.has(g), "cova fechou")
	check(f.grave_partner(head) == Vector2i(-1, -1) and f.grave_partner(foot) == Vector2i(-1, -1), "fechada: metades desligadas")
	check(f.is_hole(head) and f.is_hole(foot), "as 2 metades viram Buraco juntas")
	check_eq(f.regen_timer[f.index_of(head)], f.regen_timer[f.index_of(foot)], "mesmo timer de regeneração nas 2 metades")
	run.advance(run.stat(StatSheet.REGEN_TIME) + 1.0, Vector2i(-50, -50))
	check(regen_at.has(head) and regen_at.has(foot), "as 2 metades regeneraram")
	check_eq(float(regen_at.get(head, -1.0)), float(regen_at.get(foot, -2.0)), "regeneram no mesmo instante")
	for ng: Dictionary in run.graves:
		var nc: Array = ng.cells
		check(f.grave_partner(nc[0] as Vector2i) == (nc[1] as Vector2i), "nova cova surge já ligada")


## Não há save no meio do turno (o RunState não é persistido): o que vai para o disco entre
## turnos é a Inquietação. Ao carregar, cada cova nasce inteira e ligada.
func _test_save_load() -> void:
	var path := "res://.test_graves_save.json"
	var run := _make_run({StatSheet.GRAVE_COUNT: 2.0})
	var g0: Dictionary = run.graves[0]
	var c0: Array = g0.cells
	_dig_soil(run.field, c0[0] as Vector2i)  # metade adiantada no turno abandonado
	check(SaveIO.write(path, {"unrest": {str(run.area.id): 0.4}}), "save escrito")
	var data := SaveIO.read(path)
	SaveIO.delete(path)
	var unrest_map: Dictionary = data.get("unrest", {})
	var unrest: float = float(unrest_map.get(str(run.area.id), 0.0))
	check_eq(unrest, 0.4, "Inquietação volta do save")
	var stats := base_stats({StatSheet.GRAVE_COUNT: 2.0, StatSheet.RADIUS: 1.0})
	var loaded := RunState.new(load_area(), load_tool(), clean_balance(), stats, 78, unrest)
	check_eq(loaded.graves.size(), 2, "2 covas no turno carregado")
	for g: Dictionary in loaded.graves:
		var cells: Array = g.cells
		var head: Vector2i = cells[0]
		var foot: Vector2i = cells[1]
		check(loaded.field.grave_partner(head) == foot and loaded.field.grave_partner(foot) == head, "cova carregada com as 2 metades ligadas")
		check(loaded.field.is_intact(head) and loaded.field.is_intact(foot), "cova carregada intacta nas 2 metades")
		check(loaded.field.kind_of(head) == FieldModel.Kind.GRAVE and loaded.field.kind_of(foot) == FieldModel.Kind.GRAVE, "as 2 metades são tiles de cova")
	check(GraveVisuals.atlas_cells(loaded.field, loaded.graves).is_empty(), "nenhum caixão à mostra ao carregar")
