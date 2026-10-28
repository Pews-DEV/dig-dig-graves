extends "res://tests/test_case.gd"
## Migração do save de demo/M0 para o formato v2 do Marco A.


func _initialize() -> void:
	var legacy := {
		"version": 1,
		"currencies": {"copper": 20.0, "bones": 4.0},
		"tree": {"E01": 2, "E03": 2},
		"progress": {"turns_played": 8, "unrest": {"1": 0.8}, "boss_1_won": true},
	}
	var migrated := SaveIO.migrate(legacy)
	check_eq(int(migrated.get("version", 0)), 2, "save antigo migra para v2")
	var currencies: Dictionary = migrated.get("currencies", {})
	check_eq(float(currencies.get("copper", 0.0)), 45.0, "E01 nv2 devolve 25 Cobre")
	check_eq(float(currencies.get("bones", 0.0)), 109.0, "E03 nv2 devolve 105 Ossos")
	check((migrated.get("tree", {}) as Dictionary).is_empty(), "árvore M0 é convertida em reembolso")
	var progress: Dictionary = migrated.get("progress", {})
	check((progress.get("unrest", {}) as Dictionary).is_empty(), "Inquietação começa zerada")
	check(not bool(progress.get("boss_1_won", true)), "chefe permanece disponível no Marco A")
	check_eq(int(progress.get("turns_played", 0)), 8, "histórico de noites é mantido")
	var migrated_twice := SaveIO.migrate(migrated.duplicate(true))
	check_eq(float((migrated_twice.currencies as Dictionary).get("copper", 0.0)), 45.0, "migração v2 não reembolsa duas vezes")
	finish()
