extends "res://tests/test_case.gd"
## Tipos de lápide da Paróquia (GDD §4.6): distribuição, identidade e efeitos.

const HEAD := Vector2i(2, 2)
const BIG := 100000.0


func _initialize() -> void:
	_test_stage_weights()
	_test_tombstone_identity()
	_test_cross_rewards()
	_test_moss_coffin_and_bones()
	_test_wanderer_drift()
	finish()


func _make_run(seed_value: int = 27) -> RunState:
	var stats := base_stats({StatSheet.GRAVE_COUNT: 0.0, StatSheet.RADIUS: 0.0})
	return RunState.new(load_area(), load_tool(), clean_balance(), stats, seed_value)


func _expose_coffin(run: RunState, grave: Dictionary) -> void:
	for cell: Vector2i in grave.cells:
		for _layer: int in run.area.layers.size():
			run.field.apply_damage(cell, BIG, 6.0)


func _test_stage_weights() -> void:
	var area := load_area().duplicate() as AreaData
	area.grave_type_weights = PackedFloat32Array([0.0, 100.0, 0.0])
	var stats := base_stats({StatSheet.GRAVE_COUNT: 0.0})
	var run := RunState.new(area, load_tool(), clean_balance(), stats, 44)
	var grave := run.spawn_grave_at(HEAD, 0)
	check_eq(grave.type, RunState.GRAVE_TYPE_CROSS, "pesos do estágio selecionam o tipo da lápide")
	check_eq(int(grave.variant), 1, "cruz de pedra usa a coluna visual 1")


func _test_tombstone_identity() -> void:
	var run := _make_run()
	var oval := run.spawn_grave_at(Vector2i(1, 2), 0, RunState.GRAVE_TYPE_OVAL)
	var cross := run.spawn_grave_at(Vector2i(3, 1), 1, RunState.GRAVE_TYPE_CROSS)
	var moss := run.spawn_grave_at(Vector2i(3, 4), 0, RunState.GRAVE_TYPE_MOSS)
	check_eq(int(oval.variant), 0, "foto oval usa a coluna visual 0")
	check_eq(int(cross.variant), 1, "cruz de pedra usa a coluna visual 1")
	check_eq(int(moss.variant), 2, "lápide com musgo usa a coluna visual 2")
	check(run.grave_at(oval.tombstone as Vector2i) == oval, "ponteiro sobre a lápide encontra a cova para o tooltip")


func _test_cross_rewards() -> void:
	var run := _make_run()
	var grave := run.spawn_grave_at(HEAD, 0, RunState.GRAVE_TYPE_CROSS)
	run._open_grave(grave)
	check_eq(float(run.result.souls), 2.0, "cruz de pedra dá 1 Alma adicional no estágio 1")


func _test_moss_coffin_and_bones() -> void:
	var normal_run := _make_run()
	var normal := normal_run.spawn_grave_at(HEAD, 0, RunState.GRAVE_TYPE_OVAL)
	_expose_coffin(normal_run, normal)
	var normal_hp := normal_run.field.cell_max_hp(normal.cells[0])
	var normal_before := float(normal_run.field.hp[normal_run.field.index_of(normal.cells[0])])
	normal_run.cursor_cell = normal.cells[0]
	normal_run._pulse(false)
	var normal_loss := normal_before - float(normal_run.field.hp[normal_run.field.index_of(normal.cells[0])])
	check_eq(normal_loss, 1.0, "Caixão da foto oval recebe o dano normal")

	var moss_run := _make_run()
	var moss := moss_run.spawn_grave_at(Vector2i(1, 2), 0, RunState.GRAVE_TYPE_MOSS)
	_expose_coffin(moss_run, moss)
	var moss_hp := moss_run.field.cell_max_hp(moss.cells[0])
	var moss_before := float(moss_run.field.hp[moss_run.field.index_of(moss.cells[0])])
	moss_run.cursor_cell = moss.cells[0]
	moss_run._pulse(false)
	var moss_loss := moss_before - float(moss_run.field.hp[moss_run.field.index_of(moss.cells[0])])
	check_eq(moss_hp, normal_hp * 1.5, "Caixão da lápide com musgo tem 1,5× HP")
	# GDD §4.6: "1,5× mais duro" vale uma vez só (no HP); o golpe tira o dano normal.
	check_eq(moss_loss, 1.0, "Caixão da lápide com musgo recebe o dano normal (dureza só no HP)")
	var reward_run := _make_run()
	reward_run.balance.grave_bones_min = 3
	reward_run.balance.grave_bones_max = 3
	var reward_grave := reward_run.spawn_grave_at(HEAD, 0, RunState.GRAVE_TYPE_MOSS)
	reward_run._open_grave(reward_grave)
	check_eq(float(reward_run.result.bones), 6.0, "lápide com musgo dobra os Ossos da cova")


func _test_wanderer_drift() -> void:
	var stats := base_stats({StatSheet.GRAVE_COUNT: 0.0, StatSheet.WANDERERS: 1.0})
	var run := RunState.new(load_area(), load_tool(), clean_balance(), stats, 31)
	check_eq(run.wanderers.size(), 1, "S04: 1 alminha errante no campo")
	var before: Vector2i = run.wanderers[0].cell
	run.advance(run.balance.wanderer_move_interval + 0.01, Vector2i(-100, -100))
	var after: Vector2i = run.wanderers[0].cell
	check(absi(after.x - before.x) + absi(after.y - before.y) <= 1, "alminha flutua para um tile vizinho (não teleporta)")
	check(run.wanderers[0].has("from"), "alminha guarda o tile de origem para a animação")
