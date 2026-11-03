extends Control
## Árvore de Raízes aconchegante (GDD §6.1, §15.5; UI/UX §7). Mundo de 640×720 em camadas
## (céu com parallax → subsolo → tronco → grama → copa → raízes/nós → partículas), câmera
## arrastável com inércia, medalhões 32×32 animados, painel de pergaminho e "Cavar ▶".
## O layout dos nós vem dos .tres (SkillNodeData.tree_position, coordenadas do mundo).

const PANEL_H := 58
const PANEL_Y := TreeLayout.PANEL_Y  # = 360 − 6 − PANEL_H
const START_CAM := Vector2(648, 0)
const WHEEL_STEP := 40.0
const DRAG_THRESHOLD := 3.0
const COMBO_RESET := 0.6
## UI/UX §20: autosave a cada 60 s no hub.
const AUTOSAVE_EVERY := 60.0
## UI/UX §18.2: atalhos 1–7 = E, L, S, N, F, C, A (ordem das faixas da esquerda para a direita).
const BRANCH_KEYS: Array[int] = [
	SkillNodeData.Branch.DIG, SkillNodeData.Branch.LANTERN, SkillNodeData.Branch.SOULS,
	SkillNodeData.Branch.CENTER, SkillNodeData.Branch.FORTUNE, SkillNodeData.Branch.CEMETERY,
	SkillNodeData.Branch.HELPERS,
]
const BRANCH_NAMES: Dictionary = {
	SkillNodeData.Branch.DIG: "Escavação", SkillNodeData.Branch.LANTERN: "Lanterna",
	SkillNodeData.Branch.SOULS: "Almas", SkillNodeData.Branch.CENTER: "Centro",
	SkillNodeData.Branch.FORTUNE: "Fortuna", SkillNodeData.Branch.CEMETERY: "Cemitério",
	SkillNodeData.Branch.HELPERS: "Ajudantes",
}
## GDD §6.1: coluna k central de cada faixa (fallback quando o ramo ainda não tem nó revelado).
const BRANCH_K: Dictionary = {
	SkillNodeData.Branch.DIG: -8, SkillNodeData.Branch.LANTERN: -5, SkillNodeData.Branch.SOULS: -2,
	SkillNodeData.Branch.CENTER: 0, SkillNodeData.Branch.FORTUNE: 2, SkillNodeData.Branch.CEMETERY: 5,
	SkillNodeData.Branch.HELPERS: 8,
}
const TreeMinimapScript = preload("res://scenes/tree/tree_minimap.gd")

var _cam := TreeCamera.new(Vector2(640, 360), Rect2(Vector2.ZERO, TreeArt.WORLD))
var _sky: TreeAmbience.SkyLayer
var _world: Control
var _roots: RootLayer
var _fx: TreeFx
var _buttons: Dictionary = {}  # StringName -> SkillNodeButton
var _visible_ids: Dictionary = {}
var _revealed_ids: Dictionary = {}
var _focus_id: StringName = &""
var _wallet_labels: Dictionary = {}  # currency -> Label
var _wallet_icons: Dictionary = {}  # currency -> ResourceIcon
var _wallet_shown: Dictionary = {}  # currency -> valor exibido
var _dig_btn: Button
var _options: OptionsMenu
var _stat_sheet: StatSheetPanel
var _overlay: Control
var _hall: Control
var _hall_toggle: Button
var _boss_btn: Button
var _minimap: Control

var _panel: PanelContainer
var _panel_shown: bool = false
var _info_medallion: SkillNodeButton
var _info_title: Label
var _info_level: Label
var _info_desc: Label
var _info_effect: HBoxContainer
var _info_cost: Label
var _info_icon: ResourceIcon

var _dragging: bool = false
var _drag_moved: bool = false
var _drag_start: Vector2
var _drag_vel: Vector2 = Vector2.ZERO
var _combo: int = 0
var _combo_t: float = 0.0
var _autosave_t: float = 0.0
var _branch_label: Label
var _branch_label_t: float = 0.0
var _boss_hint: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	Audio.play_music(&"mus_tree")
	Audio.play_ambience(&"amb_night")

	_sky = TreeAmbience.SkyLayer.new()
	add_child(_sky)
	_world = Control.new()
	_world.size = TreeArt.WORLD
	_world.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_world)
	_build_world()
	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)
	_build_wallet()
	_build_hall()
	_build_hall_toggle()
	_build_minimap()
	_build_info_panel()
	_options = OptionsMenu.new()
	_options.title_text = "Opções"
	_options.show_title_button = true
	add_child(_options)
	_options.title_requested.connect(func() -> void: Game.goto_title())
	_stat_sheet = StatSheetPanel.new()
	add_child(_stat_sheet)
	_branch_label = Label.new()
	_branch_label.theme_type_variation = &"TitleLabel"
	_branch_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_branch_label.position = Vector2(0, 34)
	_branch_label.size = Vector2(640, 18)
	_branch_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_branch_label.visible = false
	_overlay.add_child(_branch_label)

	Events.currency_changed.connect(_on_currency_changed)
	Events.unrest_filled.connect(_on_unrest_filled)
	var n00 := Game.tree.get_node_data(&"N00")
	_cam.pos = _cam.clamp_pos(START_CAM if n00 == null else Vector2(n00.tree_position.x - 320.0, TreeLayout.start_camera_y(n00.tree_position.y)))
	_refresh(false)
	_apply_camera()
	if Game.last_result != null and Game.last_result.boss_victory and not Game.chapter_1_end_seen:
		await _show_chapter_unlock()
		return
	if Game.unrest_of(Game.area.id) >= 1.0 - 0.000001 and not Game.dialogue_was_seen(&"unrest_full"):
		await Game.show_dialogue(&"unrest_full")
	if Game.autopilot:
		_run_autopilot()


# --- Montagem do mundo ---------------------------------------------------------------

func _build_world() -> void:
	var deep_soil := ColorRect.new()
	deep_soil.color = Palette.color(Palette.OUTLINE)
	deep_soil.position = Vector2(0, TreeArt.GRASS_Y)
	deep_soil.size = Vector2(TreeArt.WORLD.x, TreeArt.WORLD.y - TreeArt.GRASS_Y)
	deep_soil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_world.add_child(deep_soil)
	var soil := TreeArt.tex("tree_soil.png")
	if soil != null:
		var x := 0.0
		while x < TreeArt.WORLD.x:
			_add_tex(soil, TreeArt.SOIL_POS + Vector2(x, 0))
			x += soil.get_width()
	else:
		var fallback := _SoilFallback.new()
		_world.add_child(fallback)
	var trunk := TreeArt.tex("tree_trunk.png")
	if trunk != null:
		_add_tex(trunk, TreeArt.TRUNK_POS)
	var grass := TreeArt.tex("tree_grass.png")
	if grass != null:
		var grass_x := 0.0
		while grass_x < TreeArt.WORLD.x:
			_add_tex(grass, TreeArt.GRASS_POS + Vector2(grass_x, 0))
			grass_x += grass.get_width()
	_world.add_child(TreeAmbience.Canopy.new())
	_roots = RootLayer.new()
	_world.add_child(_roots)
	for id: StringName in Game.tree.order:
		var d := Game.tree.get_node_data(id)
		if d.required_area > Game.area.id:
			continue
		var b := SkillNodeButton.new()
		b.node_id = id
		b.position = (d.tree_position - Vector2(SkillNodeButton.HALF, SkillNodeButton.HALF)).round()
		b.buy_requested.connect(_on_buy_requested)
		b.hovered.connect(_on_hovered)
		_world.add_child(b)
		_buttons[id] = b
	_fx = TreeFx.new()
	_world.add_child(_fx)
	_world.add_child(TreeAmbience.new())
	# Hall de navegação sobre o cenário; a árvore continua sendo um destino separado.


## UI/UX §10.4/§15: no retorno da 1ª vitória a Chave é celebrada no Pátio (gira, pousa com pop)
## e as raízes novas brotam; depois entra o Fim do Capítulo (≤ 6 s no total).
func _show_chapter_unlock() -> void:
	var sheet := AsepriteSheet.load_id("icon_key_1_32")
	var key := TextureRect.new()
	key.mouse_filter = Control.MOUSE_FILTER_IGNORE
	key.size = Vector2(32, 32)
	key.pivot_offset = Vector2(16, 16)
	key.position = Vector2(304, 48)
	if sheet != null and sheet.texture != null:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet.texture
		atlas.region = sheet.frames[0]
		key.texture = atlas
		var spin := key.create_tween().set_loops(6)
		for i: int in mini(4, sheet.frames.size()):
			var region: Rect2 = sheet.frames[i]
			spin.tween_callback(func() -> void: atlas.region = region)
			spin.tween_interval(0.125)
	_overlay.add_child(key)
	var caption := Label.new()
	caption.theme_type_variation = &"TitleLabel"
	caption.text = tr("Chave da Cripta I")
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.position = Vector2(0, 84)
	caption.size = Vector2(640, 18)
	caption.add_theme_color_override("font_color", Palette.color(Palette.LANTERN_BRIGHT))
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(caption)
	Juice.slide_in(key, Vector2(0, 24), 0.0, 0.3)
	Audio.play_variant(&"key_get", 1)
	Audio.play(&"stinger_stage_unlock")
	await get_tree().create_timer(0.35).timeout
	Juice.pop(key, 0.2, 0.16)
	await get_tree().create_timer(1.95).timeout
	Game.goto_chapter_end()


func _add_tex(t: Texture2D, pos: Vector2) -> void:
	var r := TextureRect.new()
	r.texture = t
	r.position = pos
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_world.add_child(r)


## Sem a arte do subsolo: faixas 14/13/01 com transição em xadrez (DA §10.3).
class _SoilFallback:
	extends Node2D

	func _draw() -> void:
		draw_rect(Rect2(0, TreeArt.GRASS_Y, TreeArt.WORLD.x, 146), Palette.color(Palette.DIRT_DARK))
		draw_rect(Rect2(0, TreeArt.GRASS_Y + 146, TreeArt.WORLD.x, 190), Palette.color(Palette.DIRT_BOTTOM))
		draw_rect(Rect2(0, TreeArt.GRASS_Y + 336, TreeArt.WORLD.x, TreeArt.WORLD.y - TreeArt.GRASS_Y - 336), Palette.color(Palette.OUTLINE))
		draw_rect(Rect2(0, TreeArt.GRASS_Y - 4, TreeArt.WORLD.x, 5), Palette.color(Palette.GRASS_DARK))
		draw_rect(Rect2(TreeArt.TRUNK_POS.x + 64, TreeArt.TRUNK_POS.y, 16, 112), Palette.color(Palette.COFFIN_DARK))


# --- Interface fixa ----------------------------------------------------------------------

func _build_wallet() -> void:
	var holder := Control.new()
	holder.position = Vector2(6, 6)
	holder.size = Vector2(150, 24)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(holder)
	var bg := NinePatchRect.new()
	bg.texture = UiKit.plaque_texture()
	var m := UiKit.plaque_margins()
	bg.patch_margin_left = m.x
	bg.patch_margin_top = m.y
	bg.patch_margin_right = m.z
	bg.patch_margin_bottom = m.w
	bg.size = holder.size
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(bg)
	var x := 7.0
	# GDD §5: a carteira mostra sempre as 3 moedas.
	for cur: StringName in [Economy.COPPER, Economy.BONES, Economy.SOULS]:
		var icon := ResourceIcon.new()
		icon.kind = ResourceIcon.kind_for_currency(cur)
		icon.position = Vector2(x, 3)
		holder.add_child(icon)
		var l := Label.new()
		l.theme_type_variation = &"HudNumber"
		l.position = Vector2(x + 18, Hud.TEXT_Y)
		l.size = Vector2(44, 18)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(l)
		_wallet_labels[cur] = l
		_wallet_icons[cur] = icon
		_wallet_shown[cur] = Economy.get_amount(cur)
		l.text = NumberFormat.format(Economy.get_amount(cur))
		x += 66.0
	holder.size.x = x + 4.0
	bg.size.x = holder.size.x
	Juice.slide_in(holder, Vector2(0, -28))


## Hall navega pelos destinos do cemitério; a escavação começa em um clique.
func _build_hall() -> void:
	_hall = Control.new()
	_hall.anchor_left = 0.5
	_hall.anchor_top = 0.5
	_hall.anchor_right = 0.5
	_hall.anchor_bottom = 0.5
	_hall.position = Vector2(-250, -6)
	_hall.size = Vector2(500, 176)
	_hall.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.add_child(_hall)
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"ParchmentPanel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_hall.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	panel.add_child(column)
	var title := Label.new()
	title.text = tr("PÁTIO DO BOM DESCANSO")
	title.theme_type_variation = &"ParchmentTitle"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	column.add_child(row)
	_add_hall_station(row, "Raízes", "Talentos", _open_skill_tree)
	_dig_btn = _add_hall_station(row, "Próxima Noite", "Paróquia · Cavar", Game.goto_run)
	_add_hall_station(row, "Loja", "Capítulo 2", Callable(), true)
	_add_hall_station(row, "Fazenda", "Em breve", Callable(), true)
	var boss_row := HBoxContainer.new()
	boss_row.alignment = BoxContainer.ALIGNMENT_CENTER
	boss_row.add_theme_constant_override("separation", 8)
	column.add_child(boss_row)
	_boss_btn = Button.new()
	_boss_btn.theme_type_variation = &"BigButton"
	_boss_btn.custom_minimum_size = Vector2(220, 28)
	_boss_btn.text = tr("Enfrentar o Caixão Fujão") + " · F"
	_boss_btn.pressed.connect(_face_boss)
	boss_row.add_child(_boss_btn)
	_boss_hint = Label.new()
	_boss_hint.text = tr("A terra treme…")
	_boss_hint.theme_type_variation = &"ParchmentLabel"
	_boss_hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	boss_row.add_child(_boss_hint)
	_set_boss_visible(Game.unrest_of(Game.area.id) >= 1.0 - 0.000001)
	# UI/UX §10.5: opções acessíveis no Pátio (também pelo Esc).
	var options_btn := Button.new()
	options_btn.text = tr("Opções")
	options_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	options_btn.pressed.connect(func() -> void: _options.open())
	column.add_child(options_btn)
	Juice.slide_in(_hall, Vector2(0, 12), 0.06)


func _set_boss_visible(on: bool) -> void:
	_boss_btn.visible = on
	_boss_hint.visible = on
	if on:
		Juice.beckon(_boss_btn)


## GDD §4.11 / UI/UX §10.4: "Enfrentar ‹chefe›" (botão ou F) leva à Noite do Chefe.
func _face_boss() -> void:
	if Game.unrest_of(Game.area.id) < 1.0 - 0.000001:
		return
	Audio.play(&"unrest_warning")
	Game.goto_boss()


func _add_hall_station(row: HBoxContainer, name: String, detail: String, action: Callable, locked: bool = false) -> Button:
	var button := Button.new()
	button.theme_type_variation = &"BigButton"
	button.custom_minimum_size = Vector2(112, 78)
	button.text = tr(name) + "\n" + tr(detail)
	button.disabled = locked
	if not locked and action.is_valid():
		button.pressed.connect(action)
	row.add_child(button)
	return button

func _build_hall_toggle() -> void:
	_hall_toggle = Button.new()
	_hall_toggle.theme_type_variation = &"BigButton"
	_hall_toggle.text = tr("Pátio")
	_hall_toggle.position = Vector2(548, 6)
	_hall_toggle.custom_minimum_size = Vector2(86, 0)
	_hall_toggle.visible = false
	_hall_toggle.pressed.connect(_show_hall)
	_overlay.add_child(_hall_toggle)


func _on_unrest_filled(area_id: int) -> void:
	if area_id == Game.area.id:
		_set_boss_visible(true)


func _open_skill_tree() -> void:
	_hall.visible = false
	_hall_toggle.visible = true
	_minimap.visible = true
	_panel.visible = _panel_shown
	_scroll_to_node(&"N00")


func _show_hall() -> void:
	_hall.visible = true
	_hall_toggle.visible = false
	_minimap.visible = false
	_panel.visible = false
	_cam.scroll_to(_home_camera())

func _build_minimap() -> void:
	_minimap = TreeMinimapScript.new()
	_minimap.position = Vector2(6, 306)
	_minimap.setup(Game.tree, TreeArt.WORLD, _cam.view)
	_minimap.visible = false
	_minimap.connect("jump_requested", func(world_point: Vector2) -> void:
		_cam.scroll_to(_cam.center_on(world_point, _cam.view * 0.5))
	)
	_overlay.add_child(_minimap)


func _build_info_panel() -> void:
	_panel = PanelContainer.new()
	_panel.theme_type_variation = &"ParchmentPanel"
	_panel.position = Vector2(108, 360)
	_panel.size = Vector2(526, PANEL_H)
	_panel.custom_minimum_size = Vector2(526, PANEL_H)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.visible = false
	_overlay.add_child(_panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_panel.add_child(row)
	var medal_box := CenterContainer.new()
	medal_box.custom_minimum_size = Vector2(34, 0)
	row.add_child(medal_box)
	_info_medallion = SkillNodeButton.new()
	_info_medallion.preview_only = true
	_info_medallion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	medal_box.add_child(_info_medallion)
	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", -2)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	text.add_child(title_row)
	_info_title = Label.new()
	_info_title.theme_type_variation = &"ParchmentTitle"
	title_row.add_child(_info_title)
	_info_level = Label.new()
	_info_level.theme_type_variation = &"ParchmentLabel"
	_info_level.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_info_level.add_theme_color_override("font_color", UiTheme.parchment_accent())
	title_row.add_child(_info_level)
	_info_desc = Label.new()
	_info_desc.theme_type_variation = &"ParchmentLabel"
	text.add_child(_info_desc)
	_info_effect = HBoxContainer.new()
	_info_effect.add_theme_constant_override("separation", 2)
	text.add_child(_info_effect)
	var cost_line := HBoxContainer.new()
	cost_line.add_theme_constant_override("separation", 3)
	cost_line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(cost_line)
	_info_cost = Label.new()
	_info_cost.theme_type_variation = &"ParchmentTitle"
	cost_line.add_child(_info_cost)
	_info_icon = ResourceIcon.new()
	cost_line.add_child(_info_icon)


# --- Entrada: arrastar, rolar, Esc ------------------------------------------------------

func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null:
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_dragging = true
				_drag_moved = false
				_drag_start = mb.position
				_drag_vel = Vector2.ZERO
			elif _dragging:
				_dragging = false
				if _drag_moved:
					_cam.release(_drag_vel)
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_cam.scroll_by(Vector2(-WHEEL_STEP if mb.shift_pressed else 0, -WHEEL_STEP if not mb.shift_pressed else 0))
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_cam.scroll_by(Vector2(WHEEL_STEP if mb.shift_pressed else 0, WHEEL_STEP if not mb.shift_pressed else 0))
		accept_event()
		return
	var mm := event as InputEventMouseMotion
	if mm != null and _dragging:
		if not _drag_moved and mm.position.distance_to(_drag_start) < DRAG_THRESHOLD:
			return
		_drag_moved = true
		_cam.drag(mm.relative)
		_drag_vel = mm.velocity
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"toggle_stats"):
		get_viewport().set_input_as_handled()
		_stat_sheet.toggle()
		return
	if event.is_action_pressed(&"pause") and not _options.is_open():
		get_viewport().set_input_as_handled()
		_options.open()
		return
	if _options.is_open() or _stat_sheet.is_open():
		return
	if event.is_action_pressed(&"face_boss") and Game.unrest_of(Game.area.id) >= 1.0 - 0.000001:
		get_viewport().set_input_as_handled()
		_face_boss()
		return
	# GDD §15: um turno novo sempre a 1 clique ou tecla (Cavar ▶ = Espaço).
	if event.is_action_pressed(&"dig_start"):
		get_viewport().set_input_as_handled()
		Game.goto_run()
		return
	if event.is_action_pressed(&"tree_home"):
		get_viewport().set_input_as_handled()
		_cam.scroll_to(_home_camera())
		return
	if _hall.visible:
		return
	for i: int in BRANCH_KEYS.size():
		if event.is_action_pressed(StringName("tree_branch_%d" % (i + 1))):
			get_viewport().set_input_as_handled()
			_focus_branch(BRANCH_KEYS[i])
			return


## UI/UX §10.1/§18.2: Home volta ao enquadramento inicial (ipê, Pátio e o N00 embaixo).
func _home_camera() -> Vector2:
	var n00 := Game.tree.get_node_data(&"N00")
	if n00 == null:
		return _cam.clamp_pos(START_CAM)
	return _cam.clamp_pos(Vector2(n00.tree_position.x - 320.0, TreeLayout.start_camera_y(n00.tree_position.y)))


## UI/UX §18.2: rola até o topo do ramo e mostra o nome dele por 1 s.
func _focus_branch(branch_id: int) -> void:
	var candidate: StringName = &""
	var candidate_y := INF
	for id: StringName in Game.tree.order:
		var data := Game.tree.get_node_data(id)
		if int(data.branch) == branch_id and Game.tree.is_revealed(id) and data.tree_position.y < candidate_y:
			candidate = id
			candidate_y = data.tree_position.y
	if candidate != &"":
		_scroll_to_node(candidate)
	else:
		var k := int(BRANCH_K.get(branch_id, 0))
		var top := Vector2(TreeArt.WORLD.x * 0.5 + TreeLayout.COLUMN * k, TreeArt.GRASS_Y + 128.0)
		_cam.scroll_to(_cam.focus_for(top, TreeLayout.safe_rect(PANEL_Y)))
	_branch_label.text = tr(String(BRANCH_NAMES.get(branch_id, "")))
	_branch_label.visible = true
	_branch_label_t = 1.0
	Juice.pop(_branch_label, 0.1, 0.14)


func _process(delta: float) -> void:
	_cam.step(delta)
	_apply_camera()
	if _minimap != null and _minimap.visible:
		_minimap.call("set_camera_pos", _cam.pos)
	if _combo > 0:
		_combo_t += delta
		if _combo_t > COMBO_RESET:
			_combo = 0
	if _branch_label_t > 0.0:
		_branch_label_t -= delta
		if _branch_label_t <= 0.0:
			_branch_label.visible = false
	_autosave_t += delta
	if _autosave_t >= AUTOSAVE_EVERY:
		_autosave_t = 0.0
		Game.save_game()


func _apply_camera() -> void:
	var p := _cam.pixel_pos()
	_world.position = -p
	_sky.position = Vector2(-p.x, -roundf(p.y * TreeArt.SKY_PARALLAX))


func _scroll_to_node(id: StringName) -> void:
	var d := Game.tree.get_node_data(id)
	if d == null:
		return
	# A caixa inteira do nó (com o custo) fica entre as plaquetas de cima e o painel.
	_cam.scroll_to(_cam.focus_for(d.tree_position, TreeLayout.safe_rect(PANEL_Y)))


# --- Compra e foco ---------------------------------------------------------------------

func _on_hovered(id: StringName) -> void:
	# O mundo da árvore continua sob o Pátio; não permita que um nó sob o cursor
	# reabra o painel de detalhes enquanto o jogador está no hall.
	if _hall.visible:
		return
	if Game.tree.is_revealed(id) and not Game.seen_nodes.has(id):
		Game.mark_seen(id)
	_set_focus(id)


func _on_buy_requested(id: StringName) -> void:
	_set_focus(id)
	var b: SkillNodeButton = _buttons[id]
	var d := Game.tree.get_node_data(id)
	var cost := Game.tree.next_cost(id)
	if not Game.buy_node(id):
		# Selado ou sem dinheiro: recusa audível (AUDIO_MANIFEST shop_deny), sem repetir ao segurar.
		if not b.is_holding():
			Audio.play(&"shop_deny")
		return
	var small := b.is_holding()
	_combo = _combo + 1 if small else 0
	_combo_t = 0.0
	if Game.tree.is_master(id):
		# UI/UX §18.1: Raiz-mestra = pop maior, tremor de 1 px e `seal` + `node_buy`.
		Juice.pop(b, 0.25, 0.2)
		_fx.burst(d.tree_position, false)
		Audio.play(&"seal")
	else:
		b.bought(small)
	_fx.burst(d.tree_position, small)
	# GDD §6.2: comprar um lado da encruzilhada sela o outro.
	for sealed_id: StringName in Game.tree.sealed_by(id):
		Audio.play(&"seal")
		if _buttons.has(sealed_id):
			Juice.squash(_buttons[sealed_id] as Control, Vector2(1.15, 0.85), 0.06, 0.16)
	# Segurar para comprar: pops menores e pitch subindo (AUDIO_MANIFEST node_buy).
	Audio.play(&"node_buy", 1.0 + 0.04 * mini(_combo, 10))
	_fly_cost(d.tree_position, cost, d.currency)
	if _panel_shown:
		Juice.pop(_panel, 0.03, 0.14)
	_scroll_to_node(id)
	_refresh(true)
	if not Game.dialogue_was_seen(&"first_node"):
		await Game.show_dialogue(&"first_node")


## O custo "voa" do nó até o contador da carteira (que conta para baixo).
func _fly_cost(world_pos: Vector2, cost: float, currency: StringName) -> void:
	if not _wallet_icons.has(currency):
		return
	var l := Label.new()
	l.theme_type_variation = &"TitleLabel"
	l.text = "-" + NumberFormat.format(cost)
	l.add_theme_color_override("font_color", Palette.color(Palette.LANTERN_BRIGHT))
	_overlay.add_child(l)
	var from := (world_pos - _cam.pixel_pos() + Vector2(-10, -24)).round()
	l.position = from
	var icon: ResourceIcon = _wallet_icons[currency]
	var to := icon.get_global_rect().get_center() + Vector2(4, -8)
	var t := l.create_tween()
	t.tween_property(l, "position", to, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.tween_callback(func() -> void:
		Juice.squash(icon, Vector2(1.25, 0.75), 0.05, 0.14)
		l.queue_free())


func _on_currency_changed(currency: StringName, amount: float) -> void:
	if not _wallet_labels.has(currency):
		return
	var from := float(_wallet_shown.get(currency, amount))
	_wallet_shown[currency] = amount
	Juice.count(_wallet_labels[currency] as Label, from, amount, 0.45)
	_refresh_buttons_affordability()


func _set_focus(id: StringName) -> void:
	_focus_id = id
	for other: StringName in _buttons:
		(_buttons[other] as SkillNodeButton).focused = other == id
	_refresh_info()
	if _hall.visible:
		_panel.visible = false
		return
	if not _panel_shown and (Game.tree.is_revealed(id) or Game.tree.is_master(id)):
		_panel_shown = true
		_panel.visible = true
		_panel.position = Vector2(108, 360)
		Audio.play(&"ui_panel_open")
		var t := _panel.create_tween()
		t.tween_property(_panel, "position:y", float(PANEL_Y), Juice.PANEL_OPEN).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# --- Atualização -----------------------------------------------------------------------

## Visibilidade, raízes, halos e animações de nós novos (raiz cresce, nó brota, "!").
func _refresh(animate: bool) -> void:
	var tree := Game.tree
	var new_visible: Array[StringName] = []
	var new_revealed: Array[StringName] = []
	for id: StringName in _buttons:
		var b: SkillNodeButton = _buttons[id]
		var revealed := tree.is_revealed(id)
		# GDD §6.1: Raízes-mestras aparecem desde o início como silhueta (nome e custo no hover).
		var vis := revealed or tree.is_hinted(id) or tree.is_master(id)
		if vis and not _visible_ids.has(id):
			new_visible.append(id)
		if revealed and not _revealed_ids.has(id):
			new_revealed.append(id)
		b.visible = vis
		b.mouse_filter = Control.MOUSE_FILTER_STOP if revealed or tree.is_master(id) else Control.MOUSE_FILTER_IGNORE
		if vis:
			_visible_ids[id] = true
		if revealed:
			_revealed_ids[id] = true
	var old_keys := _roots.roots.duplicate()
	_roots.set_roots(_root_list())
	var halos: Array[Vector2] = []
	for id: StringName in _buttons:
		if tree.is_owned(id):
			halos.append(tree.get_node_data(id).tree_position)
	_roots.set_halos(halos)
	if animate:
		var any := false
		for key: String in _roots.roots:
			if not old_keys.has(key):
				_roots.grow(key)
				any = true
		if any:
			Audio.play(&"root_grow")
		var fresh: Array[StringName] = []
		for id: StringName in new_revealed + new_visible:
			if not fresh.has(id):
				fresh.append(id)
		for id: StringName in fresh:
			(_buttons[id] as SkillNodeButton).sprout(RootLayer.GROW_TIME)
			_fx.sprout(tree.get_node_data(id).tree_position, RootLayer.GROW_TIME)
		if not fresh.is_empty():
			get_tree().create_timer(RootLayer.GROW_TIME).timeout.connect(func() -> void: Audio.play(&"node_reveal"))
			_scroll_to_node(fresh[0])
	_refresh_buttons_affordability()
	_refresh_info()
	if _minimap != null:
		_minimap.queue_redraw()

func _refresh_buttons_affordability() -> void:
	var info := Game.tree.cheapest_pending(Economy.balances)
	var can := not info.is_empty() and bool(info.affordable)
	if can:
		Juice.stop_beckon(_dig_btn)
	elif not _dig_btn.has_meta(&"beckoning") or not bool(_dig_btn.get_meta(&"beckoning")):
		Juice.beckon(_dig_btn)
	_dig_btn.set_meta(&"beckoning", not can)


func _root_list() -> Array[Dictionary]:
	var tree := Game.tree
	var out: Array[Dictionary] = []
	for id: StringName in _buttons:
		var d := tree.get_node_data(id)
		if d.starts_owned:
			out.append({"key": "trunk>" + String(id), "from": TreeArt.TRUNK_ROOT, "to": d.tree_position, "bought": true})
		if not tree.is_revealed(id):
			continue
		for child: StringName in d.children:
			if not _buttons.has(child) or not (tree.is_revealed(child) or tree.is_hinted(child)):
				continue
			var to := tree.get_node_data(child).tree_position
			var from := TreeLayout.root_start(d.tree_position, to, TreeLayout.decor_bottom_for(tree, id))
			var blockers: Array[Rect2] = []
			for other: StringName in _buttons:
				if other == id or other == child:
					continue
				if tree.is_revealed(other):
					var other_pos: Vector2 = tree.get_node_data(other).tree_position
					blockers.append(TreeLayout.node_rect(other_pos))
					blockers.append(TreeLayout.label_rect(other_pos))
			blockers.append(TreeLayout.label_rect(d.tree_position))
			blockers.append(TreeLayout.label_rect(to))
			out.append({"key": String(id) + ">" + String(child), "from": from,
				"to": to, "bought": tree.is_owned(child), "obstacles": blockers})
	return out


func _refresh_info() -> void:
	var tree := Game.tree
	for c: Node in _info_effect.get_children():
		c.queue_free()
	if _focus_id != &"" and not tree.is_revealed(_focus_id) and tree.is_master(_focus_id):
		# Silhueta da Raiz-mestra: nome e custo, sem revelar o efeito (UI/UX §18.1).
		var md := tree.get_node_data(_focus_id)
		_info_medallion.visible = false
		_info_title.text = md.display_name
		_info_level.text = tr("Raiz-mestra")
		_info_desc.text = tr("O objetivo distante deste ramo. A próxima Raiz-mestra custará ×3.")
		_info_cost.text = tr("Custo %s") % NumberFormat.format(tree.next_cost(_focus_id))
		_info_icon.kind = ResourceIcon.kind_for_currency(md.currency)
		_info_icon.visible = true
		return
	if _focus_id == &"" or not tree.is_revealed(_focus_id):
		_info_medallion.visible = false
		_info_title.text = tr("Raízes do Ipê")
		_info_level.text = ""
		_info_desc.text = tr("Passe o mouse num nó. Clique para comprar; segure para comprar várias vezes.")
		_info_cost.text = ""
		_info_icon.visible = false
		return
	var d := tree.get_node_data(_focus_id)
	var lvl := tree.level_of(_focus_id)
	_info_medallion.visible = true
	_info_medallion.node_id = _focus_id
	_info_medallion.queue_redraw()
	_info_title.text = d.display_name
	_info_level.text = "Nv %d/%d" % [lvl, d.max_level]
	_info_desc.text = d.description
	if tree.is_sealed(_focus_id):
		_info_desc.text = tr("Escolhida a outra raiz. Duas Raízes libera esta.")
		_info_cost.text = tr("Selada")
		_info_icon.visible = false
		return
	if tree.is_master(_focus_id) and not tree.is_maxed(_focus_id):
		_info_desc.text = d.description + "\n" + tr("A próxima Raiz-mestra custará ×3.")
	_build_effect_line(d, lvl)
	if tree.is_maxed(_focus_id):
		_info_cost.text = "Máximo" if d.base_cost > 0.0 else ""
		_info_icon.visible = false
	else:
		_info_cost.text = "Custo %s" % NumberFormat.format(tree.next_cost(_focus_id))
		_info_icon.kind = ResourceIcon.kind_for_currency(d.currency)
		_info_icon.visible = true


## GDD §6.1 / UI/UX §7.4: "antes → depois" com a seta andando e o valor novo em 26.
func _build_effect_line(d: SkillNodeData, lvl: int) -> void:
	if d.modifiers_per_level.is_empty():
		return
	var next_mods := Game.tree.collect_modifiers(d.id, mini(lvl + 1, d.max_level))
	var first := true
	for m: StatModifier in d.modifiers_per_level:
		var before := Stats.get_value(m.stat)
		var after := Stats.preview(SkillTreeModel.TREE_SOURCE, next_mods, m.stat)
		var lbl := Label.new()
		lbl.theme_type_variation = &"ParchmentLabel"
		lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		lbl.text = ("" if first else "   ") + "%s: %s" % [StatSheet.label_of(m.stat), StatSheet.format_value(m.stat, before)]
		_info_effect.add_child(lbl)
		first = false
		if Game.tree.is_maxed(d.id):
			continue
		var arrow := ArrowGlyph.new()
		arrow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_info_effect.add_child(arrow)
		var new_val := Label.new()
		new_val.theme_type_variation = &"HudNumber"
		new_val.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		new_val.text = StatSheet.format_value(m.stat, after)
		new_val.add_theme_color_override("font_color", Palette.color(Palette.LANTERN_BRIGHT))
		_info_effect.add_child(new_val)


# --- Demonstração --------------------------------------------------------------------------

## `-- --autopilot`: passeia a câmera, foca e compra o nó mais barato e volta a cavar.
func _run_autopilot() -> void:
	await get_tree().create_timer(1.2).timeout
	var info := Game.tree.cheapest_pending(Economy.balances)
	if not info.is_empty():
		_on_hovered(info.id as StringName)
		await get_tree().create_timer(0.6).timeout
		if bool(info.affordable):
			_on_buy_requested(info.id as StringName)
	await get_tree().create_timer(2.0).timeout
	_cam.scroll_by(Vector2(0, 90))
	await get_tree().create_timer(1.4).timeout
	_cam.scroll_to(START_CAM)
	await get_tree().create_timer(1.2).timeout
	Game.goto_run()
