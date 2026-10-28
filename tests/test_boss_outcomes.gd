extends Node
## Fuga, vitória, prêmio, desbloqueio e revanche do Caixão Fujão (GDD §10.2).

var _checks := 0
var _failures := 0


func _ready() -> void:
	var saved_game := Game.to_save_dict()
	var saved_path := SaveManager.save_path
	SaveManager.save_path = "res://.test_boss_outcomes.json"
	SaveIO.delete(SaveManager.save_path)

	var boss := (load("res://data/bosses/caixao_fujao.tres") as BossData).duplicate(true) as BossData
	boss.hp = 3.0
	var stats := StatSheet.from_balance(Game.balance).snapshot()
	stats[StatSheet.GRAVE_COUNT] = 0.0
	stats[StatSheet.OIL_MAX] = 20.0
	stats[StatSheet.DAMAGE] = 2.0

	var flee_run := _make_boss_run(boss, stats, 1.0, 0.6)
	flee_run.advance(1.01, Vector2i(-100, -100))
	check(flee_run.ended and flee_run.result.end_reason == &"oil", "óleo encerra a Noite do Chefe quando ele continua vivo")
	check(not flee_run.result.boss_victory, "fuga não conta como vitória")
	check_eq(flee_run.result.unrest_end, 1.0, "fuga mantém Inquietação cheia para revanche")
	check_eq(flee_run.result.souls, 0.0, "fuga não concede Almas de vitória")
	check_eq(flee_run.result.bones, 0.0, "fuga não concede Ossos de vitória")

	Game.apply_save_dict({
		"version": 2,
		"currencies": {"copper": 0.0, "bones": 0.0, "souls": 0.0},
		"tree": {"N00": 1},
		"progress": {"turns_played": 1, "stage_unlocked": 1, "unrest": {"1": 0.6}, "boss_1_won": false, "boss_1_attempts": 0},
		"settings": {},
		"telemetry": [],
	})
	Game.finish_turn(flee_run.result)
	check_eq(Game.boss_1_attempts, 1, "fuga fica registrada como tentativa")
	check(not Game.boss_1_won, "tentativa perdida não marca chefe vencido")
	check_eq(Game.stage_unlocked, 1, "fuga não libera o próximo estágio")
	check_eq(Game.unrest_of(1), 1.0, "progresso salva Inquietação cheia após fuga")

	var first_win := _kill_test_boss(boss, stats, false)
	check(first_win.ended and first_win.result.boss_victory, "chefe pode ser derrotado por dano sobreposto aos tiles")
	check_eq(first_win.result.souls, boss.first_victory_souls, "primeira vitória concede Almas configuradas")
	check_eq(first_win.result.bones, boss.first_victory_bones, "primeira vitória concede Ossos configurados")
	Game.finish_turn(first_win.result)
	check_eq(Game.boss_1_attempts, 2, "vitória fica registrada como segunda tentativa")
	check(Game.boss_1_won, "vitória fica persistida no progresso")
	check_eq(Game.stage_unlocked, 2, "vitória libera o estágio 2")
	check_eq(Game.unrest_of(1), 0.0, "vitória zera a Inquietação do estágio")
	check_eq(Economy.get_amount(Economy.SOULS), boss.first_victory_souls, "Almas da vitória são creditadas à carteira")
	check_eq(Economy.get_amount(Economy.BONES), boss.first_victory_bones, "Ossos da vitória são creditados à carteira")
	var saved_progress: Dictionary = SaveIO.read(SaveManager.save_path).get("progress", {})
	check(bool(saved_progress.get("boss_1_won", false)), "save v2 registra vitória do chefe")
	check_eq(int(saved_progress.get("stage_unlocked", 1)), 2, "save v2 registra estágio liberado")

	var rematch := _kill_test_boss(boss, stats, true)
	check(rematch.ended and rematch.result.boss_victory, "revanche também permite vencer o chefe")
	check_eq(rematch.result.souls, boss.rematch_souls, "revanche concede apenas o prêmio de Almas reduzido")
	check_eq(rematch.result.bones, 0.0, "revanche não repete prêmio de Ossos")

	SaveIO.delete(SaveManager.save_path)
	SaveManager.save_path = saved_path
	Game.apply_save_dict(saved_game)
	print("\n%d verificações, %d falhas" % [_checks, _failures])
	print("RESULTADO: ", "PASS" if _failures == 0 else "FAIL")
	get_tree().quit(1 if _failures > 0 else 0)


func _make_boss_run(boss: BossData, stats: Dictionary, oil_max: float, unrest: float) -> RunState:
	var run_stats := stats.duplicate()
	run_stats[StatSheet.OIL_MAX] = oil_max
	return RunState.new(Game.area, Game.tool, Game.balance, run_stats, 101, unrest, true, boss)


func _kill_test_boss(boss: BossData, stats: Dictionary, rematch: bool) -> RunState:
	var run_stats := stats.duplicate()
	run_stats["boss_1_won"] = rematch
	var run := _make_boss_run(boss, run_stats, 20.0, 1.0)
	var target: Vector2i = run.boss_cells[0]
	run.advance(run.pulse_interval() + 0.01, target)
	if not run.ended:
		run.advance(run.pulse_interval() + 0.01, target)
	return run


func check(condition: bool, label: String) -> void:
	_checks += 1
	if condition:
		print("PASS  ", label)
	else:
		_failures += 1
		printerr("FAIL  ", label)


func check_eq(actual: Variant, expected: Variant, label: String) -> void:
	var equal: bool = actual == expected
	if typeof(actual) == TYPE_FLOAT or typeof(expected) == TYPE_FLOAT:
		equal = is_equal_approx(float(actual), float(expected))
	check(equal, "%s (esperado %s, obtido %s)" % [label, str(expected), str(actual)])
