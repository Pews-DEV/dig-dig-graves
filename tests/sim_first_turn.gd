extends "res://tests/test_case.gd"
## Simulação do primeiro turno conforme GDD §14.1 e plano do Marco A.
## Escava uma camada de cada vez com a área inicial 1×1; seed fixo torna o alvo reprodutível.

const RUNS := 100


func _initialize() -> void:
	var total_copper := 0.0
	var min_copper := INF
	var max_copper := -INF
	for seed_value: int in RUNS:
		var balance := clean_balance()
		var stats := base_stats({StatSheet.GRAVE_COUNT: 0.0, StatSheet.AREA_STEP: 0.0, StatSheet.FIELD_SIZE: 5.0})
		var run := RunState.new(load("res://data/stages/stage_1.tres") as StageData, load_tool(), balance, stats, 1000 + seed_value)
		var target := Vector2i(-1, -1)
		for y: int in run.field.size:
			for x: int in run.field.size:
				var cell := Vector2i(x, y)
				if not run.field.is_blocked(cell) and run.field.top_layer(cell) != null:
					target = cell
					break
			if target.x >= 0:
				break
		check(target.x >= 0, "seed %d tem um tile cavável" % seed_value)
		while not run.ended:
			run.advance(run.pulse_interval(), target)
		var copper := run.result.copper_total()
		total_copper += copper
		min_copper = minf(min_copper, copper)
		max_copper = maxf(max_copper, copper)
	var average := total_copper / RUNS
	print("Primeiro turno: média %.1f Cobre, faixa %.1f–%.1f (%d seeds)" % [average, min_copper, max_copper, RUNS])
	check(average >= 19.0 and average <= 29.0, "primeiro turno fica em 24 ± 5 Cobre")
	finish()
