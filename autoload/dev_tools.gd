extends Node
## Modo de desenvolvedor: ferramenta interna para testar mecânicas e gravar o devlog.
## NÃO é feature de jogador. Só existe com `OS.is_debug_build()` (editor) ou com `--dev`
## na linha de comando; fora disso não cria nada nem processa input.
## F1 (`dev_toggle`) abre/fecha o painel; F12 (`dev_screenshot`) captura a tela.
## Toda ação passa pela API dos sistemas donos (Economy, Game, RunState, SaveIO).
## Textos fixos em PT, fora do translations.csv de propósito.

const PANEL_W := 220
## Acima da cortina de terra do Game (layer 100).
const LAYER := 101
const SCREENSHOT_DIR := "user://screenshots"
const SLOT_PATH := "user://dev_slot_%d.json"
const SLOTS := 3
const TIME_SCALES: Array[float] = [0.25, 1.0, 2.0, 4.0]
const CONFIRM_TIME := 3.0
const TOAST_TIME := 3.5
const INFO_INTERVAL := 0.25
const GRAVE_LABELS: Array[String] = ["Oval", "Cruz", "Musgo"]

var enabled: bool = false
## Testes desligam para chamar setup() à mão.
var auto_setup: bool = true

var _layer: CanvasLayer
var _panel: PanelContainer
var _info: Label
var _toast: Label
var _toast_until: float = 0.0
var _info_next: float = 0.0
var _node_field: LineEdit
var _oil_button: Button
var _hud_button: Button
var _pause_button: Button
var _new_game_button: Button
var _confirm_until: float = 0.0
var _grave_buttons: Array[Button] = []
var _infinite_oil: bool = false
var _forced_grave: StringName = &""
var _hud_hidden: bool = false
## Frame do último F1/F12 tratado: o mesmo evento chega por window_input e por _input.
var _hotkey_frame: int = -1


static func should_enable(debug_build: bool, args: PackedStringArray) -> bool:
	return debug_build or args.has("--dev")


## Aceita `game.exe --dev` e `game.exe -- --dev`.
static func launch_args() -> PackedStringArray:
	var args := OS.get_cmdline_args()
	args.append_array(OS.get_cmdline_user_args())
	return args


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)
	set_process_input(false)
	if auto_setup:
		setup(should_enable(OS.is_debug_build(), launch_args()))


func setup(p_enabled: bool) -> void:
	enabled = p_enabled
	set_process(enabled)
	set_process_input(enabled)
	set_process_unhandled_input(false)
	set_process_unhandled_key_input(false)
	set_process_shortcut_input(false)
	if not enabled:
		return
	_build()
	# window_input chega antes do _input das cenas (a abertura do título engole teclas no _input).
	get_tree().root.window_input.connect(_on_window_input)
	get_tree().node_added.connect(_on_node_added)


# --- Input ------------------------------------------------------------------------

func _on_window_input(event: InputEvent) -> void:
	_handle_hotkeys(event)


func _input(event: InputEvent) -> void:
	if _handle_hotkeys(event):
		get_viewport().set_input_as_handled()


## Trata F1/F12 uma vez só por evento (pode chegar por window_input e por _input).
func _handle_hotkeys(event: InputEvent) -> bool:
	if not event is InputEventKey:
		return false
	var is_hotkey := event.is_action_pressed(&"dev_toggle", false, true) or event.is_action_pressed(&"dev_screenshot", false, true)
	if not is_hotkey or Engine.get_process_frames() == _hotkey_frame:
		return is_hotkey
	_hotkey_frame = Engine.get_process_frames()
	if event.is_action_pressed(&"dev_toggle", false, true):
		_set_panel_visible(not _panel.visible)
	else:
		capture(1)
	return true


func _process(_delta: float) -> void:
	var now := _now()
	var s := _run_state()
	if s != null:
		s.dev_infinite_oil = _infinite_oil
		s.dev_forced_grave_type = _forced_grave
	if _panel.visible and Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if _toast.visible and now >= _toast_until:
		_toast.visible = false
	if _confirm_until > 0.0 and now >= _confirm_until:
		_confirm_until = 0.0
		_new_game_button.text = "Novo jogo limpo"
	if _panel.visible and now >= _info_next:
		_info_next = now + INFO_INTERVAL
		_update_info(s)


func _now() -> float:
	return float(Time.get_ticks_msec()) / 1000.0


# --- Montagem ---------------------------------------------------------------------

func _build() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = LAYER
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = _make_theme()
	_layer.add_child(root)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	_panel.offset_left = -PANEL_W
	_panel.offset_right = 0
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.visible = false
	root.add_child(_panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_panel.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 1)
	scroll.add_child(box)

	_info = Label.new()
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info.custom_minimum_size = Vector2(PANEL_W - 16, 0)
	_info.add_theme_color_override("font_color", Palette.color(Palette.ECTO_BRIGHT))
	box.add_child(_info)

	_build_resources(_section(box, "Recursos", true))
	_build_tree(_section(box, "Árvore"))
	_build_night(_section(box, "Noite"))
	_build_progress(_section(box, "Progresso"))
	_build_time(_section(box, "Tempo"))
	_build_recording(_section(box, "Gravação"))
	_build_saves(_section(box, "Saves"))

	_toast = Label.new()
	_toast.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_toast.offset_left = 4
	_toast.offset_top = -40
	_toast.offset_bottom = -4
	_toast.offset_right = 640 - PANEL_W - 8
	_toast.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_toast.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_toast.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.add_theme_stylebox_override("normal", UiKit.flat_box(Palette.BG, Palette.LANTERN, 3, 1))
	_toast.visible = false
	root.add_child(_toast)


func _make_theme() -> Theme:
	var t := Theme.new()
	t.default_font = UiTheme.body_font()
	t.default_font_size = UiTheme.SIZE_BODY
	var panel_box := UiKit.flat_box(Palette.BG, Palette.OUTLINE, 4, 3)
	panel_box.bg_color.a = 0.94
	t.set_stylebox("panel", "PanelContainer", panel_box)
	t.set_stylebox("normal", "Button", UiKit.flat_box(Palette.NIGHT_VIOLET, Palette.STONE_DARK, 3, 0))
	t.set_stylebox("hover", "Button", UiKit.flat_box(Palette.MOONSHADOW, Palette.STONE, 3, 0))
	t.set_stylebox("pressed", "Button", UiKit.flat_box(Palette.LANTERN_DARK, Palette.LANTERN, 3, 0))
	t.set_stylebox("hover_pressed", "Button", UiKit.flat_box(Palette.LANTERN_DARK, Palette.LANTERN, 3, 0))
	t.set_stylebox("disabled", "Button", UiKit.flat_box(Palette.NIGHT, Palette.STONE_DARK, 3, 0))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_font_size("font_size", "Button", UiTheme.SIZE_BODY)
	t.set_color("font_color", "Button", Palette.color(Palette.BONE))
	t.set_color("font_hover_color", "Button", Palette.color(Palette.BONE_BRIGHT))
	t.set_color("font_pressed_color", "Button", Palette.color(Palette.LANTERN_BRIGHT))
	t.set_color("font_hover_pressed_color", "Button", Palette.color(Palette.LANTERN_BRIGHT))
	t.set_type_variation("DevHeader", "Button")
	t.set_stylebox("normal", "DevHeader", UiKit.flat_box(Palette.COFFIN_DARK, Palette.COFFIN, 3, 0))
	t.set_stylebox("hover", "DevHeader", UiKit.flat_box(Palette.COFFIN, Palette.COFFIN_LIGHT, 3, 0))
	t.set_color("font_color", "DevHeader", Palette.color(Palette.LANTERN_BRIGHT))
	t.set_stylebox("normal", "LineEdit", UiKit.flat_box(Palette.NIGHT, Palette.STONE, 3, 0))
	t.set_stylebox("focus", "LineEdit", UiKit.flat_box(-1, Palette.LANTERN, 3, 0))
	t.set_stylebox("read_only", "LineEdit", UiKit.flat_box(Palette.NIGHT, Palette.STONE_DARK, 3, 0))
	t.set_font_size("font_size", "LineEdit", UiTheme.SIZE_BODY)
	t.set_color("font_color", "LineEdit", Palette.color(Palette.BONE_BRIGHT))
	t.set_color("font_placeholder_color", "LineEdit", Palette.color(Palette.STONE))
	t.set_color("font_color", "Label", Palette.color(Palette.BONE))
	t.set_constant("line_spacing", "Label", UiTheme.BODY_LINE_SPACING)
	return t


## Seção recolhível: o título mostra/esconde o corpo.
func _section(parent: VBoxContainer, title: String, open: bool = false) -> VBoxContainer:
	var header := _button(parent, "", Callable())
	header.theme_type_variation = &"DevHeader"
	header.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 1)
	body.visible = open
	parent.add_child(body)
	header.text = ("- " if open else "+ ") + title
	header.pressed.connect(func() -> void:
		body.visible = not body.visible
		header.text = ("- " if body.visible else "+ ") + title)
	return body


func _button(parent: Control, text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.set_meta(&"juiced", true)  # sem o hover/clique com som do jogo (Game._on_node_added)
	b.focus_mode = Control.FOCUS_NONE  # Espaço/Enter do jogo não re-disparam o botão
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.clip_text = true
	if action.is_valid():
		b.pressed.connect(action)
	parent.add_child(b)
	return b


func _row(parent: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 1)
	parent.add_child(row)
	return row


func _label(parent: Control, text: String) -> Label:
	var l := Label.new()
	l.text = text
	parent.add_child(l)
	return l


func _build_resources(body: VBoxContainer) -> void:
	var names: Dictionary = {Economy.COPPER: "Cobre", Economy.BONES: "Ossos", Economy.SOULS: "Almas"}
	for currency: StringName in [Economy.COPPER, Economy.BONES, Economy.SOULS]:
		var row := _row(body)
		var label := str(names[currency])
		for amount: float in [100.0, 10000.0]:
			_button(row, "%s +%s" % [label, NumberFormat.format(amount)], func() -> void:
				Economy.add(currency, amount))
	_button(body, "Zerar carteira", func() -> void:
		Economy.dev_clear()
		Game.save_game()
		toast("Carteira zerada."))


func _build_tree(body: VBoxContainer) -> void:
	_button(body, "Comprar todos (lado A)", func() -> void:
		var n: int = Game.dev_grant_all()
		toast("Árvore: +%d níveis de graça." % n)
		_refresh_tree_scene())
	_button(body, "Resetar com devolução", func() -> void:
		var totals: Dictionary = Game.dev_reset_tree_refund()
		var parts: Array[String] = []
		for currency: StringName in totals:
			parts.append("%s %s" % [String(currency), NumberFormat.format(float(totals[currency]))])
		toast("Árvore resetada. Devolvido: " + (", ".join(parts) if not parts.is_empty() else "nada"))
		_refresh_tree_scene())
	var row := _row(body)
	_node_field = LineEdit.new()
	_node_field.placeholder_text = "id (ex.: E05)"
	_node_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_node_field.text_submitted.connect(func(_t: String) -> void: _grant_path())
	row.add_child(_node_field)
	var go := _button(row, "Ir até", _grant_path)
	go.size_flags_horizontal = Control.SIZE_SHRINK_END


func _grant_path() -> void:
	var raw := _node_field.text.strip_edges()
	_node_field.release_focus()
	if raw.is_empty():
		return
	var id := StringName(raw)
	if Game.tree.get_node_data(id) == null:
		for other: StringName in Game.tree.order:  # tolera caixa: "e05" → "E05"
			if String(other).to_lower() == raw.to_lower():
				id = other
	var n: int = Game.dev_grant_path(id)
	if n < 0:
		toast("Nó \"%s\" não existe ou está selado." % raw)
	else:
		toast("%s: +%d níveis de graça." % [String(id), n])
		_refresh_tree_scene()


func _build_night(body: VBoxContainer) -> void:
	_button(body, "Encher o óleo", func() -> void:
		var s := _night_state()
		if s != null:
			s.dev_fill_oil())
	_oil_button = _button(body, "", func() -> void:
		_infinite_oil = not _infinite_oil
		_update_toggles())
	_button(body, "Terminar a noite agora", func() -> void:
		var s := _night_state()
		if s != null:
			s.dev_end_night())
	_button(body, "Recarregar o Pisão", func() -> void:
		var s := _night_state()
		if s != null:
			s.dev_recharge_stomp())
	var row := _row(body)
	_button(row, "Fogo-fátuo", func() -> void: _spawn(&"wisp"))
	_button(row, "Vela", func() -> void: _spawn(&"candle"))
	row = _row(body)
	_button(row, "Moeda ouro", func() -> void: _spawn(&"gold"))
	_button(row, "Alminha", func() -> void: _spawn(&"wanderer"))
	_label(body, "Próximas lápides:")
	row = _row(body)
	for i: int in GRAVE_LABELS.size():
		var grave_type := RunState.GRAVE_TYPES[i]
		_grave_buttons.append(_button(row, "", func() -> void:
			_forced_grave = grave_type
			_update_toggles()))
	_grave_buttons.append(_button(row, "", func() -> void:
		_forced_grave = &""
		_update_toggles()))
	_update_toggles()


func _spawn(kind: StringName) -> void:
	var s := _night_state()
	if s == null:
		return
	var ok := false
	match kind:
		&"wisp":
			ok = s.dev_spawn_wisp()
		&"candle":
			ok = s.dev_spawn_candle()
		&"gold":
			ok = s.dev_spawn_gold_coin()
		&"wanderer":
			ok = s.dev_spawn_wanderer()
	if not ok:
		toast("Sem tile livre (ou limite de velas).")


func _build_progress(body: VBoxContainer) -> void:
	_label(body, "Inquietação:")
	var row := _row(body)
	for value: float in [0.0, 0.9, 1.0]:
		_button(row, "%d%%" % roundi(value * 100.0), func() -> void: _set_unrest(value))
	_button(body, "Ir à Noite do Chefe", func() -> void:
		_leave_run()
		Game.dev_set_unrest(1.0, false)
		Game.goto_boss())
	row = _row(body)
	_button(row, "Vencer chefe", func() -> void:
		var s := _run_state()
		if s == null or not s.dev_win_boss():
			toast("Só durante a Noite do Chefe."))
	_button(row, "Perder chefe", func() -> void:
		var s := _run_state()
		if s == null or not s.dev_lose_boss():
			toast("Só durante a Noite do Chefe."))
	_button(body, "Abrir Fim do Capítulo 1", func() -> void:
		_leave_run()
		Game.goto_chapter_end())
	_button(body, "Zerar chapter_end_seen", func() -> void:
		Game.dev_reset_chapter_end()
		toast("chapter_end_seen = falso."))


func _set_unrest(value: float) -> void:
	var s := _run_state()
	if s != null and not s.ended:
		s.dev_set_unrest(value)  # o Run repassa ao Events
		Game.dev_set_unrest(value, false)
	else:
		Game.dev_set_unrest(value)
	toast("Inquietação = %d%%" % roundi(value * 100.0))


func _build_time(body: VBoxContainer) -> void:
	var row := _row(body)
	for scale: float in TIME_SCALES:
		_button(row, "%s×" % String.num(scale).replace(".", ","), func() -> void:
			Engine.time_scale = scale)
	row = _row(body)
	_pause_button = _button(row, "Pausar", func() -> void:
		get_tree().paused = not get_tree().paused
		_update_toggles())
	_button(row, "+1 frame", _step_frame)


func _step_frame() -> void:
	if not get_tree().paused:
		toast("Pause primeiro.")
		return
	get_tree().paused = false
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().paused = true


func _build_recording(body: VBoxContainer) -> void:
	_hud_button = _button(body, "", func() -> void:
		_hud_hidden = not _hud_hidden
		_apply_hud_visibility(get_tree().root)
		_update_toggles())
	_button(body, "Esconder painel (F1 volta)", func() -> void: _set_panel_visible(false))
	var row := _row(body)
	_button(row, "PNG 1×", func() -> void: capture(1))
	_button(row, "PNG 3×", func() -> void: capture(3))
	_button(body, "Abrir pasta das capturas", func() -> void:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SCREENSHOT_DIR))
		OS.shell_open(ProjectSettings.globalize_path(SCREENSHOT_DIR)))
	_update_toggles()


func _build_saves(body: VBoxContainer) -> void:
	for n: int in range(1, SLOTS + 1):
		var row := _row(body)
		_button(row, "Salvar %d" % n, func() -> void: _save_slot(n))
		_button(row, "Carregar %d" % n, func() -> void: _load_slot(n))
	_new_game_button = _button(body, "Novo jogo limpo", _new_game)


func _update_toggles() -> void:
	if _oil_button != null:
		_oil_button.text = "Óleo infinito: " + ("SIM" if _infinite_oil else "não")
	if _hud_button != null:
		_hud_button.text = "Esconder HUD: " + ("SIM" if _hud_hidden else "não")
	if _pause_button != null:
		_pause_button.text = "Despausar" if get_tree().paused else "Pausar"
	for i: int in _grave_buttons.size():
		var grave_type: StringName = RunState.GRAVE_TYPES[i] if i < GRAVE_LABELS.size() else &""
		var text: String = GRAVE_LABELS[i] if i < GRAVE_LABELS.size() else "Aleat."
		_grave_buttons[i].text = ("[%s]" % text) if grave_type == _forced_grave else text


func _update_info(s: RunState) -> void:
	var scene := get_tree().current_scene
	var scene_name := scene.scene_file_path.get_file().get_basename() if scene != null else "-"
	var line := "%s · %d FPS · %s×" % [scene_name, roundi(Engine.get_frames_per_second()), String.num(Engine.time_scale).replace(".", ",")]
	if s != null:
		line += "\nnoite %d · semente %d" % [Game.turns_played + (0 if s.ended else 1), s.rng.seed]
		if s.boss_active:
			line += " · CHEFE"
	else:
		line += "\nnoites jogadas %d" % Game.turns_played
	if get_tree().paused:
		line += " · PAUSA"
	_info.text = line
	if _pause_button != null:
		_pause_button.text = "Despausar" if get_tree().paused else "Pausar"


# --- Painel, HUD e toast ----------------------------------------------------------

func _set_panel_visible(value: bool) -> void:
	_panel.visible = value
	if value:
		_info_next = 0.0
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_update_toggles()
		return
	var focused := _panel.get_viewport().gui_get_focus_owner()
	if focused != null and _panel.is_ancestor_of(focused):
		focused.release_focus()
	# Devolve o ponteiro escondido do turno (run.gd o esconde enquanto se cava).
	var s := _run_state()
	if s != null and not s.ended and not get_tree().paused:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN


func toast(text: String) -> void:
	if _toast == null:
		return
	_toast.text = text
	_toast.visible = true
	_toast_until = _now() + TOAST_TIME
	print("[DevTools] ", text)


func _on_node_added(node: Node) -> void:
	if _hud_hidden and node is Hud:
		(node as CanvasLayer).set_deferred(&"visible", false)


func _apply_hud_visibility(node: Node) -> void:
	if node is Hud:
		(node as CanvasLayer).visible = not _hud_hidden
	for child: Node in node.get_children():
		_apply_hud_visibility(child)


# --- Captura (devlog) -------------------------------------------------------------

## PNG da viewport (640×360 × escala, Nearest) em user://screenshots/, sem o painel.
func capture(scale: int = 1) -> void:
	var panel_was := _panel.visible
	_panel.visible = false
	_toast.visible = false
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	_panel.visible = panel_was
	if img == null or img.is_empty():
		toast("Captura falhou (sem imagem da viewport).")
		return
	if scale > 1:
		img.resize(img.get_width() * scale, img.get_height() * scale, Image.INTERPOLATE_NEAREST)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SCREENSHOT_DIR))
	var stamp := Time.get_datetime_string_from_system(false, true).replace(":", "-").replace(" ", "_")
	var path := "%s/ddg_%s_%03d%s.png" % [SCREENSHOT_DIR, stamp, Time.get_ticks_msec() % 1000, "" if scale == 1 else "_x%d" % scale]
	var err := img.save_png(path)
	if err != OK:
		toast("Captura falhou: %s" % error_string(err))
	else:
		toast("Captura: " + ProjectSettings.globalize_path(path))


# --- Saves ------------------------------------------------------------------------

func _save_slot(n: int) -> void:
	# O estado em memória é o mesmo do save (a noite em curso só credita ao terminar).
	if SaveIO.write(SLOT_PATH % n, Game.to_save_dict()):
		toast("Estado salvo no slot %d." % n)
	else:
		toast("Falha ao salvar o slot %d." % n)


func _load_slot(n: int) -> void:
	var path := SLOT_PATH % n
	if not FileAccess.file_exists(path):
		toast("Slot %d vazio." % n)
		return
	var data: Dictionary = SaveIO.read(path)
	if data.is_empty():
		toast("Slot %d inválido." % n)
		return
	_leave_run()
	Game.dev_load_save_dict(data)
	Game.goto_tree()
	toast("Slot %d carregado." % n)


func _new_game() -> void:
	if _confirm_until <= 0.0:
		_confirm_until = _now() + CONFIRM_TIME
		_new_game_button.text = "Confirmar? (clique de novo)"
		return
	_confirm_until = 0.0
	_new_game_button.text = "Novo jogo limpo"
	_leave_run()
	Game.new_game()
	Game.goto_title()
	toast("Novo jogo (o save anterior foi enterrado em save_buried.json).")


# --- Acesso ao turno --------------------------------------------------------------

## O RunState da cena atual (run.gd expõe `state`), ou null fora de uma noite.
func _run_state() -> RunState:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	var value: Variant = scene.get(&"state")
	if value is RunState:
		return value as RunState
	return null


func _night_state() -> RunState:
	var s := _run_state()
	if s == null or s.ended:
		toast("Só durante uma noite.")
		return null
	return s


## Para o turno sem creditar nada antes de trocar de cena por aqui.
func _leave_run() -> void:
	var s := _run_state()
	if s != null:
		s.dev_halt()


func _refresh_tree_scene() -> void:
	var scene := get_tree().current_scene
	if scene != null and scene.scene_file_path == Game.SCENE_TREE and not Game.is_changing_scene():
		get_tree().reload_current_scene()
