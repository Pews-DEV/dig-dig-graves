extends "res://tests/test_case.gd"
## Contrato HOP do Caixão Fujão (GDD §10.2).


func _initialize() -> void:
	var stage := load("res://data/stages/stage_1.tres") as StageData
	var boss := load("res://data/bosses/caixao_fujao.tres") as BossData
	var stats := base_stats({StatSheet.GRAVE_COUNT: 0.0, StatSheet.OIL_MAX: 100.0})
	var run := RunState.new(stage, load_tool(), clean_balance(), stats, 101, 1.0, true, boss)
	check(run.boss_active and run.boss_cells.size() == 4, "chefe começa no campo ocupando 2×2")
	var old_cells := run.boss_cells.duplicate()
	var hops := [0]
	run.boss_hopped.connect(func(_old: Array[Vector2i], _new: Array[Vector2i]) -> void: hops[0] += 1)
	run.advance(3.9, Vector2i(-100, -100))
	check_eq(run.boss_hops, 0, "chefe não salta antes de 4 s")
	run.advance(0.2, Vector2i(-100, -100))
	check_eq(run.boss_hops, 1, "chefe salta aos 4 s")
	check_eq(hops[0], 1, "salto emite um evento")
	check(not run.boss_cells.is_empty() and run.boss_cells != old_cells, "chefe reaparece em outra posição")
	check(run.boss_invulnerable > 0.0, "salto dá janela de invulnerabilidade")
	check_eq(run.boss_hp, boss.hp, "salto não reduz a vida")
	finish()
