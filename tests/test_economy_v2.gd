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
	finish()
