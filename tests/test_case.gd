extends SceneTree
## Base mínima para testes headless: check() acumula falhas; finish() sai com código ≠ 0.
## Uso: godot --headless --path . -s res://tests/<arquivo>.gd

var _failures: int = 0
var _checks: int = 0


func check(condition: bool, label: String) -> void:
	_checks += 1
	if condition:
		print("PASS  ", label)
	else:
		_failures += 1
		printerr("FAIL  ", label)


func check_eq(actual: Variant, expected: Variant, label: String) -> void:
	var ok: bool = actual == expected
	if typeof(actual) == TYPE_FLOAT or typeof(expected) == TYPE_FLOAT:
		ok = is_equal_approx(float(actual), float(expected))
	check(ok, "%s (esperado %s, obtido %s)" % [label, str(expected), str(actual)])


func finish() -> void:
	print("\n%d verificações, %d falhas" % [_checks, _failures])
	print("RESULTADO: ", "PASS" if _failures == 0 else "FAIL")
	quit(1 if _failures > 0 else 0)


static func load_area() -> AreaData:
	return load("res://data/areas/area_1.tres") as AreaData


static func load_tool() -> ToolData:
	return load("res://data/tools/tool_shovel.tres") as ToolData


static func load_balance() -> BalanceData:
	return load("res://data/balance.tres") as BalanceData


## Balanceamento sem eventos aleatórios (sem rochas nem fogos-fátuos) para testes determinísticos.
static func clean_balance() -> BalanceData:
	var b := load_balance().duplicate() as BalanceData
	b.rocks_min = 0
	b.rocks_max = 0
	b.wisp_interval = 1000000.0
	b.wisp_interval_jitter = 0.0
	return b


static func base_stats(overrides: Dictionary = {}) -> Dictionary:
	var stats := StatSheet.from_balance(load_balance()).snapshot()
	for k: Variant in overrides:
		stats[k] = overrides[k]
	return stats
