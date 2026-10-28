extends Node
## Estado do jogo e fluxo de telas (GDD §15.1, §18.2).
## Inicializa os outros autoloads (Game é o último na ordem de autoload).

const SKILL_NODES_DIR := "res://data/skill_nodes/"
const BALANCE_PATH := "res://data/balance.tres"
const AREA_PATHS: Dictionary = {1: "res://data/stages/stage_1.tres"}
const BOSS_PATH := "res://data/bosses/caixao_fujao.tres"
const TOOL_PATHS: Dictionary = {&"shovel": "res://data/tools/tool_shovel.tres"}

const SCENE_RUN := "res://scenes/run/run.tscn"
const SCENE_SUMMARY := "res://scenes/run/turn_summary.tscn"
const SCENE_TREE := "res://scenes/tree/skill_tree.tscn"
const SCENE_TITLE := "res://scenes/title/title_screen.tscn"
const SCENE_CHAPTER_END := "res://scenes/ui/chapter_end.tscn"

const TELEMETRY_KEEP := 50

var balance: BalanceData
var area: AreaData
var boss_data: BossData
var tool: ToolData
var tree: SkillTreeModel
var turns_played: int = 0
var boss_run: bool = false
var boss_1_won: bool = false
var boss_1_attempts: int = 0
var stage_unlocked: int = 1
var chapter_1_end_seen: bool = false
var dialogue_seen: Dictionary = {}
## GDD §10: Inquietação por área (0–1), persiste entre turnos.
var unrest: Dictionary = {}
var last_result: TurnResult
## GDD §14.3: registro local por turno (duração, Cobre, nós comprados, área).
var telemetry: Array[Dictionary] = []
var nodes_bought_since_turn: int = 0
## Opções e acessibilidade (GDD §16, UI/UX §1.6); padrões e limites em GameSettings.
var settings: Dictionary = GameSettings.sanitize({})
## Nós da árvore já vistos (o "!" de novidade some no primeiro hover, UI/UX §7.3).
var seen_nodes: Dictionary = {}
## `-- --autopilot`: cursor anda sozinho (captura de tela / demonstração), com save próprio.
var autopilot: bool = false
## A abertura do título já tocou nesta sessão: na volta, entra direto no enquadramento final.
var title_intro_seen: bool = false
## `-- --font-test`: mostra a amostra de tipografia (UI/UX §2) por cima da tela.
var font_test: bool = false

var _curtain_layer: CanvasLayer
var _curtain: DirtCurtain
var _changing: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # fade e troca de cena funcionam com o jogo pausado
	autopilot = OS.get_cmdline_user_args().has("--autopilot")
	font_test = OS.get_cmdline_user_args().has("--font-test")
	if autopilot:
		SaveManager.save_path = "user://autopilot_save.json"
		SaveManager.delete_save()
	balance = load(BALANCE_PATH) as BalanceData
	area = load(AREA_PATHS[1]) as AreaData
	boss_data = load(BOSS_PATH) as BossData
	tool = load(TOOL_PATHS[&"shovel"]) as ToolData
	tree = SkillTreeModel.new(SkillTreeModel.load_definitions(SKILL_NODES_DIR))
	Stats.setup(balance)
	get_tree().root.theme = UiTheme.get_theme()
	RenderingServer.set_default_clear_color(Palette.color(Palette.BG))
	_build_curtain()
	get_tree().node_added.connect(_on_node_added)
	load_game()
	TranslationServer.set_locale(str(settings.get("locale", "pt_BR")))
	Audio.apply_settings(settings)
	if font_test:
		var sample := FontSample.new()
		_curtain_layer.add_child(sample)


## UI/UX §6: todo botão do jogo ganha o hover/clique padrão, sem precisar lembrar.
func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		Juice.attach_button(node as BaseButton)


func set_setting(key: String, value: Variant) -> void:
	var merged := settings.duplicate()
	merged[key] = value
	settings = GameSettings.sanitize(merged)
	if key == "locale":
		TranslationServer.set_locale(str(settings.locale))
	Audio.apply_settings(settings)
	Events.settings_changed.emit()


func mark_seen(id: StringName) -> void:
	seen_nodes[id] = true


func dialogue_was_seen(id: StringName) -> bool:
	return bool(dialogue_seen.get(id, false))


func mark_dialogue_seen(id: StringName) -> void:
	dialogue_seen[id] = true
	save_game()


func show_dialogue(id: StringName) -> void:
	var path := "res://data/dialogue/" + String(id) + ".tres"
	if not ResourceLoader.exists(path):
		return
	var data := load(path) as DialogueData
	if data == null or (data.once and dialogue_was_seen(id)):
		return
	var box := DialogueBox.new()
	get_tree().root.add_child.call_deferred(box)
	await get_tree().process_frame
	await box.play_id(id)
	box.queue_free()
	if data.once:
		mark_dialogue_seen(id)


func show_tip(id: StringName) -> void:
	var path := "res://data/dialogue/" + String(id) + ".tres"
	if not ResourceLoader.exists(path):
		return
	var data := load(path) as DialogueData
	if data == null or (data.once and dialogue_was_seen(id)):
		return
	var box := DialogueBox.new()
	get_tree().root.add_child.call_deferred(box)
	await get_tree().process_frame
	await box.show_tip_id(id)
	box.queue_free()
	if data.once:
		mark_dialogue_seen(id)


func unrest_of(area_id: int) -> float:
	return float(unrest.get(area_id, 0.0))


func refresh_stats() -> void:
	Stats.set_source(SkillTreeModel.TREE_SOURCE, tree.collect_modifiers())


# --- Compras -----------------------------------------------------------------

func buy_node(id: StringName) -> bool:
	if not tree.can_buy(id, Economy.balances):
		return false
	var d := tree.get_node_data(id)
	if not Economy.spend(d.currency, tree.next_cost(id)):
		return false
	var revealed := tree.add_level(id)
	nodes_bought_since_turn += 1
	refresh_stats()
	Events.skill_node_bought.emit(id, tree.level_of(id))
	for r: StringName in revealed:
		Events.skill_node_revealed.emit(r)
	save_game()  # pedido do M0: autosave ao comprar
	return true


# --- Turno -------------------------------------------------------------------

## Credita o turno, registra telemetria e salva (GDD §4.10, §18.2).
func finish_turn(result: TurnResult) -> void:
	last_result = result
	turns_played += 1
	if result.boss_encounter:
		boss_1_attempts += 1
		boss_run = false
		if result.boss_victory:
			boss_1_won = true
			if boss_data.unlocks.has(&"stage_2"):
				stage_unlocked = maxi(stage_unlocked, 2)
			tree.set_trigger(&"boss_1")
	if turns_played >= 2:
		tree.set_trigger(&"turn_2")
	if result.souls > 0.0:
		tree.set_trigger(&"first_soul")
	Economy.add(Economy.COPPER, result.copper_total())
	Economy.add(Economy.BONES, result.bones)
	Economy.add(Economy.SOULS, result.souls)
	unrest[result.area_id] = 0.0 if result.boss_encounter and result.boss_victory else result.unrest_end
	telemetry.append({
		"turn": turns_played, "area": result.area_id, "duration": snappedf(result.duration, 0.01),
		"copper": snappedf(result.copper_total(), 0.01), "nodes_bought": nodes_bought_since_turn,
		"graves_opened": result.graves_opened,
	})
	while telemetry.size() > TELEMETRY_KEEP:
		telemetry.pop_front()
	_check_dry_streak()
	nodes_bought_since_turn = 0
	save_game()


## GDD §14.3: >5 turnos seguidos sem comprar nada = bug de balanceamento.
func _check_dry_streak() -> void:
	var streak := 0
	for i: int in range(telemetry.size() - 1, -1, -1):
		if int(telemetry[i].get("nodes_bought", 0)) > 0:
			break
		streak += 1
	if streak > 5:
		push_warning("Balanceamento: %d turnos seguidos sem compra (GDD §14.3)." % streak)


# --- Fluxo de telas ----------------------------------------------------------

func goto_run() -> void:
	boss_run = false
	_change_scene(SCENE_RUN)


func goto_boss() -> void:
	if unrest_of(area.id) < 1.0 - 0.000001:
		return
	boss_run = true
	_change_scene(SCENE_RUN)


func goto_summary() -> void:
	_change_scene(SCENE_SUMMARY)


func goto_tree() -> void:
	_change_scene(SCENE_TREE)


func goto_chapter_end() -> void:
	chapter_1_end_seen = true
	save_game()
	_change_scene(SCENE_CHAPTER_END)


## Tela-título (UI/UX §9). `curtain = false` no boot: a própria abertura sai do preto.
func goto_title(curtain: bool = true) -> void:
	if curtain:
		_change_scene(SCENE_TITLE)
	else:
		get_tree().paused = false
		get_tree().change_scene_to_file(SCENE_TITLE)


## Atalho sem título (autopilot/captura): 1º jogo vai direto ao turno; depois, à árvore.
func goto_start() -> void:
	if turns_played == 0:
		goto_run()
	else:
		goto_tree()


## Transição "cortina de terra" (UI/UX §6): cobre, troca a cena e revela.
func _change_scene(path: String) -> void:
	if _changing:
		return
	_changing = true
	get_tree().paused = false
	await _curtain.cover().finished
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await _curtain.reveal().finished
	_changing = false


func is_changing_scene() -> bool:
	return _changing


func _build_curtain() -> void:
	_curtain_layer = CanvasLayer.new()
	_curtain_layer.layer = 100
	_curtain_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_curtain_layer)
	_curtain = DirtCurtain.new()
	_curtain_layer.add_child(_curtain)


# --- Save --------------------------------------------------------------------

func to_save_dict() -> Dictionary:
	return {
		"currencies": Economy.to_dict(),
		"tree": tree.to_save(),
		"progress": {"turns_played": turns_played, "area": area.id, "stage_unlocked": stage_unlocked, "unrest": _unrest_to_save(), "seen_nodes": seen_nodes.keys().map(func(k: StringName) -> String: return String(k)), "boss_1_won": boss_1_won, "boss_1_attempts": boss_1_attempts, "chapter_1_end_seen": chapter_1_end_seen, "dialogue_seen": dialogue_seen.keys().map(func(k: StringName) -> String: return String(k))},
		"settings": settings.duplicate(),
		"telemetry": telemetry.duplicate(true),
	}


func apply_save_dict(data: Dictionary) -> void:
	Economy.from_dict(data.get("currencies", {}) as Dictionary)
	tree.load_save(data.get("tree", {}) as Dictionary)
	var progress: Dictionary = data.get("progress", {})
	turns_played = int(progress.get("turns_played", 0))
	boss_1_won = bool(progress.get("boss_1_won", false))
	boss_1_attempts = int(progress.get("boss_1_attempts", 0))
	stage_unlocked = maxi(1, int(progress.get("stage_unlocked", 1)))
	chapter_1_end_seen = bool(progress.get("chapter_1_end_seen", false))
	dialogue_seen.clear()
	for dialogue_id: Variant in progress.get("dialogue_seen", []):
		dialogue_seen[StringName(str(dialogue_id))] = true
	if turns_played >= 2:
		tree.set_trigger(&"turn_2")
	if boss_1_won:
		tree.set_trigger(&"boss_1")
	unrest.clear()
	var saved_unrest: Dictionary = progress.get("unrest", {})
	for k: Variant in saved_unrest:
		unrest[int(str(k))] = clampf(float(saved_unrest[k]), 0.0, 1.0)
	settings = GameSettings.sanitize(data.get("settings", {}) as Dictionary)
	if Economy.get_amount(Economy.SOULS) > 0.0:
		tree.set_trigger(&"first_soul")
	seen_nodes.clear()
	for id: Variant in progress.get("seen_nodes", []):
		seen_nodes[StringName(str(id))] = true
	if not progress.has("seen_nodes"):
		for id: StringName in tree.order:  # save antigo: nada aparece como novidade
			if tree.is_revealed(id):
				seen_nodes[id] = true
	telemetry.clear()
	for entry: Variant in data.get("telemetry", []):
		if entry is Dictionary:
			telemetry.append(entry as Dictionary)
	refresh_stats()


func _unrest_to_save() -> Dictionary:
	var out: Dictionary = {}
	for k: int in unrest:
		out[str(k)] = unrest[k]
	return out


func save_game() -> void:
	SaveManager.write(to_save_dict())


func load_game() -> void:
	var data := SaveManager.read()
	if data.is_empty():
		_reset_progress()
	else:
		apply_save_dict(data)


func _reset_progress() -> void:
	Economy.reset()
	tree.reset()
	turns_played = 0
	boss_run = false
	boss_1_won = false
	boss_1_attempts = 0
	stage_unlocked = 1
	chapter_1_end_seen = false
	dialogue_seen.clear()
	unrest.clear()
	seen_nodes.clear()
	telemetry.clear()
	nodes_bought_since_turn = 0
	last_result = null
	refresh_stats()


## Há progresso para "Continuar"? (um save só com opções, gravado pelo menu, não conta)
func has_progress() -> bool:
	return SaveManager.has_save() and (turns_played > 0 or Economy.get_amount(Economy.COPPER) > 0.0)


## Novo Jogo (UI/UX §9.4): enterra o save atual pelo SaveManager e recomeça do zero.
## As opções do jogador (volume, acessibilidade) são mantidas.
func new_game() -> void:
	if SaveManager.has_save():
		SaveManager.bury_save()
	_reset_progress()
	save_game()
