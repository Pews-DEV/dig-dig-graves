extends Control
## Árvore de Raízes aconchegante (GDD §6.1, §15.5; UI/UX §7). Mundo de 640×720 em camadas
## (céu com parallax → subsolo → tronco → grama → copa → raízes/nós → partículas), câmera
## arrastável com inércia, medalhões 32×32 animados, painel de pergaminho e "Cavar ▶".
## O layout dos nós vem dos .tres (SkillNodeData.tree_position, coordenadas do mundo).

const PANEL_H := 58
const PANEL_Y := TreeLayout.PANEL_Y  # = 360 − 6 − PANEL_H
const DIG_BUTTON_POS := Vector2(548, 6)
const START_CAM := Vector2(0, 48)
const WHEEL_STEP := 40.0
const DRAG_THRESHOLD := 3.0
const COMBO_RESET := 0.6

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
var _overlay: Control

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
	_build_dig_button()
	_build_info_panel()
	_options = OptionsMenu.new()
	_options.title_text = "Opções"
	_options.show_title_button = true
	add_child(_options)
	_options.title_requested.connect(func() -> void: Game.goto_title())

	Events.currency_changed.connect(_on_currency_changed)
	var n00 := Game.tree.get_node_data(&"N00")
	_cam.pos = _cam.clamp_pos(START_CAM if n00 == null else Vector2(0, TreeLayout.start_camera_y(n00.tree_position.y)))
	_refresh(false)
	_apply_camera()
	if Game.autopilot:
		_run_autopilot()


# --- Montagem do mundo ---------------------------------------------------------------

func _build_world() -> void:
	var soil := TreeArt.tex("tree_soil.png")
	if soil != null:
		_add_tex(soil, Vector2.ZERO)
	else:
		var fallback := _SoilFallback.new()
		_world.add_child(fallback)
	var trunk := TreeArt.tex("tree_trunk.png")
	if trunk != null:
		_add_tex(trunk, TreeArt.TRUNK_POS)
	var grass := TreeArt.tex("tree_grass.png")
	if grass != null:
		_add_tex(grass, TreeArt.GRASS_POS)
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
		draw_rect(Rect2(0, 112, 640, 146), Palette.color(Palette.DIRT_DARK))
		draw_rect(Rect2(0, 258, 640, 190), Palette.color(Palette.DIRT_BOTTOM))
		draw_rect(Rect2(0, 448, 640, 272), Palette.color(Palette.OUTLINE))
		draw_rect(Rect2(0, 108, 640, 5), Palette.color(Palette.GRASS_DARK))
		draw_rect(Rect2(312, 40, 16, 110), Palette.color(Palette.COFFIN_DARK))


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
	for cur: StringName in [Economy.COPPER, Economy.BONES, Economy.SOULS]:
		if cur == Economy.SOULS and Economy.get_amount(cur) <= 0.0:
			continue
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


## "Cavar ▶" (GDD §15.1): fixo no canto, 1 clique para o próximo turno.
func _build_dig_button() -> void:
	_dig_btn = Button.new()
	_dig_btn.theme_type_variation = &"BigButton"
	_dig_btn.text = "Cavar"
	_dig_btn.icon = UiKit.play_icon()
	_dig_btn.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_dig_btn.position = DIG_BUTTON_POS
	_dig_btn.custom_minimum_size = Vector2(86, 0)
	_dig_btn.pressed.connect(Game.goto_run)
	_overlay.add_child(_dig_btn)
	Juice.slide_in(_dig_btn, Vector2(0, -28), 0.04)


func _build_info_panel() -> void:
	_panel = PanelContainer.new()
	_panel.theme_type_variation = &"ParchmentPanel"
	_panel.position = Vector2(6, 360)
	_panel.size = Vector2(628, PANEL_H)
	_panel.custom_minimum_size = Vector2(628, PANEL_H)
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
			_cam.scroll_by(Vector2(0, -WHEEL_STEP))
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_cam.scroll_by(Vector2(0, WHEEL_STEP))
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
	if event.is_action_pressed(&"pause") and not _options.is_open():
		get_viewport().set_input_as_handled()
		_options.open()


func _process(delta: float) -> void:
	_cam.step(delta)
	_apply_camera()
	if _combo > 0:
		_combo_t += delta
		if _combo_t > COMBO_RESET:
			_combo = 0


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
	if Game.tree.is_revealed(id) and not Game.seen_nodes.has(id):
		Game.mark_seen(id)
	_set_focus(id)


func _on_buy_requested(id: StringName) -> void:
	_set_focus(id)
	var b: SkillNodeButton = _buttons[id]
	var d := Game.tree.get_node_data(id)
	var cost := Game.tree.next_cost(id)
	if not Game.buy_node(id):
		return
	var small := b.is_holding()
	_combo = _combo + 1 if small else 0
	_combo_t = 0.0
	b.bought(small)
	_fx.burst(d.tree_position, small)
	# Segurar para comprar: pops menores e pitch subindo (AUDIO_MANIFEST node_buy).
	Audio.play(&"node_buy", 1.0 + 0.04 * mini(_combo, 10))
	_fly_cost(d.tree_position, cost, d.currency)
	if _panel_shown:
		Juice.pop(_panel, 0.03, 0.14)
	_scroll_to_node(id)
	_refresh(true)


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
	if not _panel_shown and Game.tree.is_revealed(id):
		_panel_shown = true
		_panel.visible = true
		_panel.position = Vector2(6, 360)
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
		var vis := revealed or tree.is_hinted(id)
		if vis and not _visible_ids.has(id):
			new_visible.append(id)
		if revealed and not _revealed_ids.has(id):
			new_revealed.append(id)
		b.visible = vis
		b.mouse_filter = Control.MOUSE_FILTER_STOP if revealed else Control.MOUSE_FILTER_IGNORE
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
			out.append({"key": String(id) + ">" + String(child), "from": from,
				"to": to, "bought": tree.is_owned(child)})
	return out


func _refresh_info() -> void:
	var tree := Game.tree
	for c: Node in _info_effect.get_children():
		c.queue_free()
	if _focus_id == &"" or not tree.is_revealed(_focus_id):
		_info_medallion.visible = false
		_info_title.text = "Raízes do Ipê"
		_info_level.text = ""
		_info_desc.text = "Passe o mouse num nó. Clique para comprar; segure para comprar várias vezes."
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
