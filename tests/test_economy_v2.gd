extends "res://tests/test_case.gd"
## Invariantes econômicas da escavação por passos no Marco A.


func _initialize() -> void:
	var shovel := load_tool()
	check_eq(shovel.cells_for_step(Vector2i(4, 4), 0).size(), 1, "área passo 0 é 1×1")
	check_eq(shovel.cells_for_step(Vector2i(4, 4), 1).size(), 2, "área passo 1 é 1×2")
	check_eq(shovel.cells_for_step(Vector2i(4, 4), 2).size(), 4, "área passo 2 é 2×2")
	check_eq(shovel.cells_for_step(Vector2i(4, 4), 10).size(), 36, "área passo 10 é 6×6")
	var stage := load("res://data/stages/stage_1.tres") as StageData
	check_eq(stage.base_field_size, 5, "campo inicia em 5×5")
	check_eq(stage.max_field_size, 18, "campo pode crescer até 18×18")
	check_eq(stage.graves_for_unrest, 900.0, "900 covas enchem a Inquietação do estágio 1")
	var b := clean_balance()
	var stats := base_stats({StatSheet.GRAVE_COUNT: 0.0, StatSheet.FIELD_SIZE: 5.0})
	var run := RunState.new(stage, shovel, b, stats, 42)
	var cell := Vector2i(2, 2)
	var grass := run.field.top_layer(cell)
	check(grass != null and grass.id == &"grass", "tile inicial começa com Grama")
	check_eq(run.field.copper_per_point(grass), 1.0, "Grama rende 1 Cobre por ponto")
	var hit := run.field.apply_damage(cell, 1.0, 18.0)
	check_eq(float(hit.useful), 1.0, "dano útil é limitado ao HP restante")
	check_eq(float(hit.layers[0].get("useful", 0.0)), 1.0, "dano parcial permanece na camada")
	_test_inheritance(stage, shovel)
	_test_second_wind(stage, shovel)
	_test_constellation(stage, shovel)
	_test_tremor(stage, shovel)
	_test_grave_oil_cap(stage, shovel)
	finish()


func _test_inheritance(stage: StageData, shovel: ToolData) -> void:
	var stats := base_stats({StatSheet.GRAVE_COUNT: 0.0, StatSheet.INHERITANCE: 0.10})
	var run := RunState.new(stage, shovel, clean_balance(), stats, 3)
	run.result.copper_mined = 200.0
	run._finish(&"oil")
	check_eq(run.result.inheritance_bonus, 20.0, "F05: Herança paga 10% do Cobre da noite")
	check(run.result.copper_total() >= 220.0, "Herança entra no total do Resumo")


func _test_second_wind(stage: StageData, shovel: ToolData) -> void:
	var b := clean_balance()
	var stats := base_stats({StatSheet.GRAVE_COUNT: 0.0, StatSheet.SECOND_WIND: 1.0})
	var run := RunState.new(stage, shovel, b, stats, 5)
	run.advance(float(stats[StatSheet.OIL_MAX]) + 0.5, Vector2i(2, 2))
	check(not run.ended, "L06: ao zerar o óleo a lanterna volta")
	check(run.result.second_wind_used, "Segundo Fôlego registrado no resultado")
	run.advance(b.second_wind_oil + 1.0, Vector2i(2, 2))
	check(run.ended, "Segundo Fôlego vale 1× por noite")


func _test_constellation(stage: StageData, shovel: ToolData) -> void:
	var b := clean_balance()
	var stats := base_stats({StatSheet.GRAVE_COUNT: 0.0, StatSheet.CONSTELLATION: 1.0})
	var run := RunState.new(stage, shovel, b, stats, 6)
	run.cursor_cell = Vector2i(2, 2)
	for i: int in b.constellation_wisps:
		run.wisps.append({"id": 900 + i, "cell": Vector2i(2, 2), "age": 0.0})
		run._collect_wisps()
	check(run.oil_frozen(), "LX: 3 fogos-fátuos em menos de 6 s param o óleo")
	var before := run.oil
	run.advance(2.0, Vector2i(0, 0))
	check_eq(run.oil, before, "óleo não queima durante a Constelação")


func _test_tremor(stage: StageData, shovel: ToolData) -> void:
	var stats := base_stats({StatSheet.GRAVE_COUNT: 0.0})
	var calm := RunState.new(stage, shovel, clean_balance(), stats, 7, 0.5)
	calm._open_grave(calm.spawn_grave_at(Vector2i(2, 2), 0, RunState.GRAVE_TYPE_OVAL))
	var shaking := RunState.new(stage, shovel, clean_balance(), stats, 7, 1.0)
	check(shaking.tremor, "Inquietação cheia numa noite comum = tremores")
	shaking._open_grave(shaking.spawn_grave_at(Vector2i(2, 2), 0, RunState.GRAVE_TYPE_OVAL))
	check_eq(shaking.result.souls, calm.result.souls * 1.25, "tremores: covas dão +25% de Almas")


func _test_grave_oil_cap(stage: StageData, shovel: ToolData) -> void:
	var stats := base_stats({StatSheet.GRAVE_COUNT: 0.0, StatSheet.OIL_PER_GRAVE: 0.5, StatSheet.OIL_GRAVE_CAP: 3.0})
	var run := RunState.new(stage, shovel, clean_balance(), stats, 8)
	for i: int in 10:
		run._open_grave(run.spawn_grave_at(Vector2i(2, 2), 0, RunState.GRAVE_TYPE_OVAL))
		run._close_grave(run.graves[0], false)
	check_eq(run.result.oil_from_graves, 3.0, "L04: óleo de cova para no teto de 3 s por nível")
