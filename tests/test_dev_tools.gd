extends Node
## Modo de desenvolvedor: ativação (debug ou --dev), custo zero sem a flag e os ganchos dev_*.
## Cena (precisa dos autoloads): godot --headless --path . res://tests/test_dev_tools.tscn

const DevToolsScript := preload("res://autoload/dev_tools.gd")
const TC := preload("res://tests/test_case.gd")

var _failures: int = 0
var _checks: int = 0


func _ready() -> void:
	_test_activation()
	_test_disabled_creates_nothing()
	_test_enabled_builds_panel()
	_test_run_state_hooks()
	_test_tree_hooks()
	print("\n%d verificações, %d falhas" % [_checks, _failures])
	print("RESULTADO: ", "PASS" if _failures == 0 else "FAIL")
	get_tree().quit(1 if _failures > 0 else 0)


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


func _test_activation() -> void:
	check(not DevToolsScript.should_enable(false, PackedStringArray()), "release sem --dev: desligado")
	check(DevToolsScript.should_enable(false, PackedStringArray(["--dev"])), "release com --dev: ligado")
	check(DevToolsScript.should_enable(false, PackedStringArray(["--", "--dev"])), "release com -- --dev: ligado")
	check(not DevToolsScript.should_enable(false, PackedStringArray(["--developer"])), "outro argumento não liga")
	check(DevToolsScript.should_enable(true, PackedStringArray()), "build de debug: ligado")


func _test_disabled_creates_nothing() -> void:
	var dev: Node = DevToolsScript.new()
	dev.set(&"auto_setup", false)
	add_child(dev)
	dev.call(&"setup", false)
	check_eq(dev.get_child_count(), 0, "desligado: nenhum nó criado")
	check(not dev.is_processing(), "desligado: sem _process")
	check(not dev.is_processing_input(), "desligado: sem _input")
	dev.free()


func _test_enabled_builds_panel() -> void:
	var dev: Node = DevToolsScript.new()
	dev.set(&"auto_setup", false)
	add_child(dev)
	dev.call(&"setup", true)
	check(dev.get_child_count() == 1 and dev.get_child(0) is CanvasLayer, "ligado: 1 CanvasLayer")
	var panel: PanelContainer = dev.get(&"_panel")
	check(panel != null and not panel.visible, "painel começa fechado")
	dev.call(&"_set_panel_visible", true)
	dev.call(&"_update_info", null)
	check(panel.visible and not (dev.get(&"_info") as Label).text.is_empty(), "painel abre com a linha de info")
	dev.call(&"_set_panel_visible", false)
	check(not panel.visible, "painel fecha")
	dev.free()


func _test_run_state_hooks() -> void:
	var o := {StatSheet.GRAVE_COUNT: 0.0, StatSheet.OIL_MAX: 10.0}
	var s := RunState.new(TC.load_area(), TC.load_tool(), TC.clean_balance(), TC.base_stats(o), 5)
	s.dev_infinite_oil = true
	s.advance(3.0, Vector2i(-50, -50))
	check_eq(s.oil, 10.0, "óleo infinito não queima")
	s.dev_infinite_oil = false
	s.advance(1.0, Vector2i(-50, -50))
	check(s.oil < 10.0, "sem a flag o óleo volta a queimar")
	s.dev_fill_oil()
	check_eq(s.oil, s.oil_start, "encher o óleo")
	s.dev_forced_grave_type = RunState.GRAVE_TYPE_MOSS
	var forced := true
	for i: int in 5:
		forced = forced and s._roll_grave_type() == RunState.GRAVE_TYPE_MOSS
	check(forced, "tipo de lápide forçado")
	check(s.dev_spawn_wisp() and s.wisps.size() == 1, "spawn de fogo-fátuo")
	check(s.dev_spawn_gold_coin() and not s.gold_coin.is_empty(), "spawn de moeda de ouro")
	check(s.dev_spawn_wanderer() and not s.wanderers.is_empty(), "spawn de alminha")
	var candles_before := s.candles.size()
	check(s.dev_spawn_candle() and s.candles.size() == candles_before + 1, "spawn de vela")
	check(not s.dev_win_boss(), "vencer chefe fora da Noite do Chefe: nada")
	var ended := [false]
	s.finished.connect(func(_r: TurnResult) -> void: ended[0] = true)
	s.dev_end_night()
	check(s.ended and bool(ended[0]), "terminar a noite emite finished")


func _test_tree_hooks() -> void:
	var tree := SkillTreeModel.new(SkillTreeModel.load_definitions("res://data/skill_nodes/"))
	check(tree.dev_is_side_a(&"E12a") and not tree.dev_is_side_a(&"E12b"), "lado A da encruzilhada E12")
	check(tree.dev_spent_totals().is_empty(), "árvore inicial: nada gasto")
	var first := StringName()
	for id: StringName in tree.order:
		var d := tree.get_node_data(id)
		if not d.starts_owned and d.kind != &"M" and d.base_cost > 0.0 and d.max_level >= 2:
			first = id
			break
	var data := tree.get_node_data(first)
	tree.add_level(first)
	tree.add_level(first)
	var totals := tree.dev_spent_totals()
	check_eq(float(totals.get(data.currency, 0.0)), data.cost_at(0) + data.cost_at(1), "devolução soma os níveis pagos de %s" % String(first))
