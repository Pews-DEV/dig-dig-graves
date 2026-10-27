extends Control
## Tela-título e menu principal (UI/UX §9). Cena em camadas com parallax na descida da
## câmera (céu → vila → almas → muro → névoa → primeiro plano → copa → frente → logo → UI → vinheta), logo que
## se monta letra a letra, menu com cursor fogo-fátuo, confirmação de "Novo Jogo", Opções e
## Créditos. Coordenadas em data/title/title_layout.tres (contrato §9.6).

const LAYOUT_PATH := "res://data/title/title_layout.tres"
## AUDIO_MANIFEST: ao começar/continuar, mus_title e o coro saem em ~0,4 s.
const START_FADE_OUT := 0.4
const LEAVE_PAUSE := 0.15
const DESC_GAP := 3

var layout: TitleLayoutData

var _world: Node2D
var _layer_factor: Dictionary = {}  # Node2D -> fator de parallax
var _souls: TitleLayers.Souls
var _coveiro: TitleCoveiro
var _tiao: TitleTiao
var _shovel: TitleProps.StuckShovel
var _lantern: TitleProps.GroundLantern
var _halo: TitleProps.LanternHalo
var _logo: TitleLogo

var _menu: Control
var _entries: Array[StringName] = []
var _buttons: Dictionary = {}  # StringName -> Button
var _shown: Dictionary = {}  # StringName -> true quando o botão já entrou
var _wisp: TitleWisp
var _desc_box: HBoxContainer
var _desc_label: Label
var _desc_coin: TextureRect
var _fade: TitleFade
var _confirm: TitleConfirm
var _credits: TitleCredits
var _options: OptionsMenu

var _has_save: bool = false
var _t: float = 0.0
var _intro: bool = false
var _busy: bool = false
var _silent_focus: bool = false
var _shake_t: float = 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout = load(LAYOUT_PATH) as TitleLayoutData if ResourceLoader.exists(LAYOUT_PATH) else null
	if layout == null:
		layout = TitleLayoutData.new()
	_has_save = Game.has_progress()
	_entries = TitleMenuModel.entries(_has_save)
	_build_world()
	_build_menu()
	_build_overlays()
	# AUDIO_MANIFEST: mus_title, amb_night e o coro começam juntos sob o fade de 0,6 s.
	Audio.play_music(&"mus_title", TitleTimeline.FADE)
	Audio.play_ambience(&"amb_night", 0, TitleTimeline.FADE)
	Audio.play_ambience(&"amb_souls_choir", 1, TitleTimeline.FADE)
	if Game.title_intro_seen:
		# Volta do jogo: enquadramento final, logo montado, sem os logo_*.
		_fade.level = 0.0
		_skip_intro()
	else:
		Game.title_intro_seen = true
		_intro = true
		_t = 0.0
		_apply_timeline(0.0, false)


func _exit_tree() -> void:
	Audio.stop_ambience(1, START_FADE_OUT)


# --- Montagem -----------------------------------------------------------------------------

func _build_world() -> void:
	_world = Node2D.new()
	add_child(_world)
	_add_layer(TitleLayers.Sky.new(layout), layout.factor_sky)
	_add_layer(TitleLayers.Village.new(layout), layout.factor_village)
	_souls = TitleLayers.Souls.new(layout)
	_world.add_child(_souls)
	var wall_tex := TitleArt.texture(TitleArt.WALL)
	var wall_top := 0.0
	if wall_tex != null:
		wall_top = TitleLayoutData.layer_top(layout.wall_y, wall_tex.get_height())
	else:
		var l := layout
		wall_tex = TitleArt.generated("title_wall", func() -> Image: return TitleArt.wall_image(l.wall_base_y, l.gate_span))
		wall_top = float(layout.wall_base_y - 40)
	_add_layer(TitleLayers.Plate.new(wall_tex, wall_top), layout.factor_wall)
	_add_layer(TitleLayers.Fog.new(layout), layout.factor_fog)
	var fg_tex := TitleArt.texture(TitleArt.FG)
	var fg_top := 0.0
	if fg_tex != null:
		fg_top = TitleLayoutData.layer_top(layout.fg_y, fg_tex.get_height())
	else:
		var l2 := layout
		fg_tex = TitleArt.generated("title_fg", func() -> Image: return TitleArt.fg_image(l2))
	var fg := TitleLayers.Plate.new(fg_tex, fg_top)
	_add_layer(fg, layout.factor_fg)
	# MANIFEST: ordem halo < pá < Coveiro < lanterna, tudo relativo ao pivô do Coveiro.
	var seat := layout.coveiro_seat
	_halo = TitleProps.LanternHalo.new()
	_halo.position = seat + layout.halo_offset
	fg.add_child(_halo)
	_shovel = TitleProps.StuckShovel.new()
	_shovel.position = seat + layout.shovel_offset
	fg.add_child(_shovel)
	_coveiro = TitleCoveiro.new()
	_coveiro.position = seat
	fg.add_child(_coveiro)
	_lantern = TitleProps.GroundLantern.new()
	_lantern.position = seat + layout.lantern_offset
	fg.add_child(_lantern)
	_tiao = TitleTiao.new()
	_tiao.position = layout.tiao_perch
	fg.add_child(_tiao)
	# MANIFEST: … < personagens < title_fg_canopy < pétalas e vaga-lumes < logo < UI < vinheta.
	fg.add_child(TitleLayers.Canopy.new(layout))
	fg.add_child(TitleLayers.Front.new(layout))
	_logo = TitleLogo.new()
	_logo.setup(layout)
	_logo.shovel_landed.connect(_on_shovel_landed)
	_world.add_child(_logo)


func _add_layer(layer: Node2D, factor: float) -> void:
	_world.add_child(layer)
	_layer_factor[layer] = factor


func _build_menu() -> void:
	_menu = Control.new()
	_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_menu)
	for i: int in _entries.size():
		var id := _entries[i]
		var b := Button.new()
		b.theme_type_variation = &"BigButton"
		b.text = TitleMenuModel.label(id)
		b.position = layout.menu_button_pos(i)
		b.custom_minimum_size = Vector2(layout.menu_width, layout.menu_height)
		b.size = b.custom_minimum_size
		b.visible = false
		b.focus_mode = Control.FOCUS_ALL
		# AUDIO_MANIFEST: no menu do título o foco toca ui_wisp_slide no lugar do ui_hover.
		b.set_meta(&"quiet_hover", true)
		b.pressed.connect(_on_pressed.bind(id))
		b.focus_entered.connect(_on_focus.bind(id))
		b.mouse_entered.connect(func() -> void:
			if _menu_active():
				b.grab_focus())
		_menu.add_child(b)
		_buttons[id] = b
	# Foco circular para cima/baixo; esquerda/direita não saem do menu.
	for i: int in _entries.size():
		var b: Button = _buttons[_entries[i]]
		var up: Button = _buttons[_entries[TitleMenuModel.step(i, -1, _entries.size())]]
		var down: Button = _buttons[_entries[TitleMenuModel.step(i, 1, _entries.size())]]
		b.focus_neighbor_top = b.get_path_to(up)
		b.focus_neighbor_bottom = b.get_path_to(down)
		b.focus_neighbor_left = b.get_path_to(b)
		b.focus_neighbor_right = b.get_path_to(b)
	_wisp = TitleWisp.new()
	_wisp.visible = false
	_menu.add_child(_wisp)
	_desc_box = HBoxContainer.new()
	_desc_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_desc_box.add_theme_constant_override("separation", 3)
	_desc_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var desc_w := float(layout.menu_width + 80)
	_desc_box.position = Vector2(layout.menu_origin.x + layout.menu_width * 0.5 - desc_w * 0.5, layout.menu_button_pos(_entries.size()).y + DESC_GAP - (layout.menu_step - layout.menu_height)).round()
	_desc_box.size = Vector2(desc_w, 10)
	_desc_box.visible = false
	_menu.add_child(_desc_box)
	_desc_label = Label.new()
	_desc_label.theme_type_variation = &"HudLabel"
	_desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_desc_box.add_child(_desc_label)
	_desc_coin = TextureRect.new()
	_desc_coin.texture = TitleArt.copper_glyph()
	_desc_coin.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	_desc_coin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_desc_coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_desc_box.add_child(_desc_coin)
	# Rodapé: versão em m5x7, cor 05, canto inferior direito.
	var version := Label.new()
	version.theme_type_variation = &"HudLabel"
	version.text = version_text()
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	version.add_theme_color_override("font_color", Palette.color(Palette.MOONSHADOW))
	version.position = Vector2(334, 344)
	version.size = Vector2(300, 12)
	version.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu.add_child(version)


static func version_text() -> String:
	var v := str(ProjectSettings.get_setting("application/config/version", ""))
	return ("v" + v) if not v.is_empty() else ""


func _build_overlays() -> void:
	var vignette := TitleArt.texture_path(TitleArt.VIGNETTE_PATH)
	if vignette != null:
		var v := TextureRect.new()
		v.texture = vignette
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(v)
	_confirm = TitleConfirm.new()
	_confirm.buried.connect(_on_buried)
	_confirm.cancelled.connect(func() -> void: _reopen_menu(TitleMenuModel.NEW_GAME))
	add_child(_confirm)
	_credits = TitleCredits.new()
	_credits.closed.connect(func() -> void: _reopen_menu(TitleMenuModel.CREDITS))
	add_child(_credits)
	_options = OptionsMenu.new()
	_options.title_text = "Opções"
	_options.closed.connect(func() -> void: _reopen_menu(TitleMenuModel.OPTIONS))
	add_child(_options)
	_fade = TitleFade.new()
	add_child(_fade)


# --- Abertura (UI/UX §9.3) -------------------------------------------------------------------

func _process(delta: float) -> void:
	if _intro:
		_t += delta
		_apply_timeline(_t, true)
		if _t >= TitleTimeline.total(_entries.size()):
			_finish_intro()
	_update_shake(delta)
	_update_props()


## Estado da cena no tempo `t` da abertura. Com `events`, toca sons e anima a entrada.
func _apply_timeline(t: float, events: bool) -> void:
	_fade.level = TitleTimeline.fade_alpha(t)
	for layer: Node2D in _layer_factor:
		layer.position.y = TitleTimeline.layer_offset(t, float(_layer_factor[layer]), layout.camera_drop)
	_souls.drop = layout.camera_drop * (1.0 - TitleTimeline.descent_progress(t))
	_logo.update_intro(t, events)
	for i: int in _entries.size():
		var id := _entries[i]
		if t >= TitleTimeline.button_start(i) and not _shown.has(id):
			_show_button(id, events)


func _show_button(id: StringName, animate: bool) -> void:
	_shown[id] = true
	var b: Button = _buttons[id]
	b.visible = true
	if animate:
		b.modulate.a = 0.0
		b.create_tween().tween_property(b, "modulate:a", 1.0, TitleTimeline.BUTTON_TIME * 0.5)
		Juice.slide_in(b, Vector2(0, 12), 0.0, TitleTimeline.BUTTON_TIME)


func _finish_intro() -> void:
	_intro = false
	_logo.idle = true
	for id: StringName in _entries:
		if not _shown.has(id):
			_show_button(id, false)
	_focus_initial()


## Qualquer tecla/clique pula para o estado final (idêntico ao fim da abertura).
func _skip_intro() -> void:
	_intro = false
	_t = TitleTimeline.total(_entries.size())
	_apply_timeline(_t, false)
	_logo.show_final()
	for id: StringName in _entries:
		var b: Button = _buttons[id]
		b.modulate.a = 1.0
		b.position = layout.menu_button_pos(_entries.find(id))
	_focus_initial()


func _input(event: InputEvent) -> void:
	if not _intro or event.is_echo() or not event.is_pressed():
		return
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton:
		get_viewport().set_input_as_handled()
		_skip_intro()


func _on_shovel_landed() -> void:
	_shake_t = TitleTimeline.THUNK_SHAKE


## Tremor de 1 px na pá (UI/UX §9.3), escalado pela intensidade e por "reduzir movimento".
func _update_shake(delta: float) -> void:
	if _shake_t <= 0.0:
		return
	_shake_t -= delta
	var amp := float(Game.settings.get("shake_intensity", 1.0)) * Juice.motion()
	if _shake_t > 0.0 and amp >= 0.5:
		_world.position = Vector2(randi_range(-1, 1), randi_range(-1, 1))
	else:
		_world.position = Vector2.ZERO


## `stand`: a pá e a lanterna somem quando o Coveiro as pega; o halo sobe com a lanterna.
func _update_props() -> void:
	if not _coveiro.standing:
		return
	if _coveiro.has_picked_up(layout):
		_shovel.visible = false
		_lantern.visible = false
	var rise := layout.stand_halo_rise if _coveiro.halo_raised(layout) else 0
	_halo.position = layout.coveiro_seat + layout.halo_offset - Vector2(0, rise)


# --- Menu (UI/UX §9.4) -------------------------------------------------------------------------

func _menu_active() -> bool:
	return not _intro and not _busy and not _confirm.is_open() and not _credits.is_open() and not _options.is_open()


func _focus_initial() -> void:
	_wisp.visible = false
	_desc_box.visible = true
	_silent_focus = true
	var id := TitleMenuModel.initial_focus(_has_save)
	(_buttons[id] as Button).grab_focus()
	_silent_focus = false
	_wisp.visible = true


func _on_focus(id: StringName) -> void:
	var b: Button = _buttons[id]
	for other: StringName in _buttons:
		var ob: Button = _buttons[other]
		if other == id:
			# Botão em foco: calor da lanterna (estilo de hover, borda 26).
			ob.add_theme_stylebox_override("normal", UiKit.button_style(&"hover", 10))
			ob.add_theme_color_override("font_color", Palette.color(Palette.BONE_BRIGHT))
		else:
			ob.remove_theme_stylebox_override("normal")
			ob.remove_theme_color_override("font_color")
	_wisp.move_to(layout.menu_button_pos(_entries.find(id)) + layout.wisp_offset, not _wisp.visible)
	if not _silent_focus:
		Audio.play(&"ui_wisp_slide")
	_desc_label.text = TitleMenuModel.description(id, _has_save, Game.turns_played, Economy.get_amount(Economy.COPPER))
	_desc_coin.visible = TitleMenuModel.shows_copper(id)
	if b.has_focus():
		_desc_box.visible = true


func _set_menu_enabled(on: bool) -> void:
	for id: StringName in _buttons:
		var b: Button = _buttons[id]
		b.focus_mode = Control.FOCUS_ALL if on else Control.FOCUS_NONE
		b.mouse_filter = Control.MOUSE_FILTER_STOP if on else Control.MOUSE_FILTER_IGNORE
		if not on and b.has_focus():
			b.release_focus()


func _reopen_menu(focus_id: StringName) -> void:
	if _busy:
		return
	_set_menu_enabled(true)
	if _buttons.has(focus_id):
		_silent_focus = true
		(_buttons[focus_id] as Button).grab_focus()
		_silent_focus = false


func _on_pressed(id: StringName) -> void:
	if not _menu_active():
		return
	if id == TitleMenuModel.CONTINUE:
		_start(TitleMenuModel.DEST_TREE)
	elif id == TitleMenuModel.NEW_GAME:
		if TitleMenuModel.needs_confirm(id, _has_save):
			_set_menu_enabled(false)
			_confirm.open()
		else:
			Game.new_game()
			_start(TitleMenuModel.DEST_RUN)
	elif id == TitleMenuModel.OPTIONS:
		_set_menu_enabled(false)
		_options.open()
	elif id == TitleMenuModel.CREDITS:
		_set_menu_enabled(false)
		_credits.open()
	elif id == TitleMenuModel.QUIT:
		_busy = true
		Audio.stop_music(START_FADE_OUT)
		await get_tree().create_timer(START_FADE_OUT * 0.5).timeout
		get_tree().quit()


## "Enterrar": o SaveManager guarda o save antigo enterrado e o jogo recomeça do zero.
func _on_buried() -> void:
	Game.new_game()
	_has_save = false
	_start(TitleMenuModel.DEST_RUN)


## Coveiro levanta (pega a pá e a lanterna) e a cortina de terra leva ao jogo.
func _start(dest: StringName) -> void:
	_busy = true
	_set_menu_enabled(false)
	Audio.stop_music(START_FADE_OUT)
	Audio.stop_ambience(1, START_FADE_OUT)
	_coveiro.stand()
	await get_tree().create_timer(_coveiro.stand_time() + LEAVE_PAUSE).timeout
	if dest == TitleMenuModel.DEST_TREE:
		Game.goto_tree()
	else:
		Game.goto_run()
