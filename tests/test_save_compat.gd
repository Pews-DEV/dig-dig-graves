extends Node
## Migração e ida/volta ponta a ponta do save de demo/M0 (GDD §18.5).

const FIXTURE_PATH := "res://tests/fixtures/save_m0_v1.json"
const ROUNDTRIP_PATH := "res://.test_save_compat.json"
var _checks := 0
var _failures := 0


func _ready() -> void:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE_PATH))
	check(raw is Dictionary, "fixture M0 v1 carrega como JSON")
	if not raw is Dictionary:
		_finish()
		return
	var migrated := SaveIO.migrate(raw as Dictionary)
	check_eq(int(migrated.get("version", 0)), 2, "fixture M0 migra para v2")
	check_eq(float((migrated.currencies as Dictionary).get("copper", 0.0)), 45.0, "saldo de Cobre inclui o reembolso integral de E01")
	check_eq(float((migrated.currencies as Dictionary).get("bones", 0.0)), 109.0, "saldo de Ossos inclui o reembolso integral de E03")
	check((migrated.tree as Dictionary).is_empty(), "árvore antiga é zerada após reembolso")
	check((migrated.progress.unrest as Dictionary).is_empty(), "Inquietação antiga é reiniciada")
	check_eq(float(migrated.settings.get("vol_music", 0.0)), 0.42, "opção de áudio é preservada")
	check_eq(str(migrated.settings.get("locale", "")), "en", "idioma é preservado")
	check_eq((migrated.telemetry as Array).size(), 1, "telemetria antiga é preservada")

	Game.apply_save_dict(migrated)
	check_eq(Economy.get_amount(Economy.COPPER), 45.0, "jogo aplica o saldo migrado")
	check_eq(Economy.get_amount(Economy.BONES), 109.0, "jogo aplica o reembolso migrado")
	check(Game.tree.level_of(&"E01") == 0 and Game.tree.level_of(&"E03") == 0, "jogo zera os nós investidos no save antigo")
	check_eq(Game.turns_played, 8, "jogo preserva noites jogadas")
	check_eq(Game.telemetry.size(), 1, "jogo preserva histórico de telemetria")
	check_eq(float(Game.settings.get("vol_music", 0.0)), 0.42, "jogo preserva opções ao carregar")

	var v2 := Game.to_save_dict()
	check(SaveIO.write(ROUNDTRIP_PATH, v2), "estado migrado grava em formato v2")
	var loaded := SaveIO.read(ROUNDTRIP_PATH)
	check_eq(int(loaded.get("version", 0)), 2, "save reaberto continua em v2")
	check_eq(float((loaded.currencies as Dictionary).get("copper", 0.0)), 45.0, "Cobre sobrevive ao round-trip")
	check_eq(float((loaded.currencies as Dictionary).get("bones", 0.0)), 109.0, "Ossos sobrevivem ao round-trip")
	check_eq((loaded.telemetry as Array).size(), 1, "telemetria sobrevive ao round-trip")
	check_eq(float(loaded.settings.get("vol_music", 0.0)), 0.42, "opções sobrevivem ao round-trip")
	SaveIO.delete(ROUNDTRIP_PATH)
	_finish()


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


func _finish() -> void:
	print("\n%d verificações, %d falhas" % [_checks, _failures])
	print("RESULTADO: ", "PASS" if _failures == 0 else "FAIL")
	get_tree().quit(1 if _failures > 0 else 0)
