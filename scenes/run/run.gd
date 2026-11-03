extends Node2D
## Cena do Turno da Noite (GDD §4). Liga o RunState (regra pura) à visualização,
## ao HUD e ao barramento Events.

## Moedas voando ao HUD por golpe (o valor do golpe se divide entre elas).
const MAX_COINS_PER_PULSE := 3
const SUMMARY_DELAY := 0.8
## DA §9.1: hit-stop de 2 frames ao abrir cova.
const HITSTOP_FRAMES := 2
## UI/UX §13.1: 2º anel do Pisão Sísmico.
const STOMP_RING_DELAY := 0.06
## GDD §4.8: "obrigado" da alminha errante em 1 palavra.
const THANKS: Array[String] = ["Obrigado!", "Valeu!", "Brigado!", "Descanso!", "Paz!"]

var state: RunState

@onready var field_view: FieldView = $FieldView
@onready var hud: Hud = $Hud
@onready var backdrop: RunBackdrop = $Backdrop
@onready var front_fx: RunBackdrop = $Front

var _autopilot_t: float = 0.0
var _paused: bool = false
var _leaving: bool = false
var _hitstop: int = 0
## Cobre por tile ainda não mostrado (só números ≥ 1 sobem; o resto acumula).
var _copper_pending: Dictionary = {}
## XP das quebras deste golpe: sobe como 1 número só no centro da área.
var _pulse_xp: float = 0.0
var _stat_sheet: StatSheetPanel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	field_view.process_mode = Node.PROCESS_MODE_PAUSABLE
	var run_stats := Stats.snapshot()
	run_stats["ossuary_layer"] = Game.tree.has_flag(&"ossuary_layer")
	run_stats["auto_stomp_option"] = bool(Game.settings.get("auto_stomp", false))
	run_stats["boss_1_won"] = Game.boss_1_won
	state = RunState.new(Game.area, Game.tool, Game.balance, run_stats, 0, Game.unrest_of(Game.area.id), Game.boss_run, Game.boss_data)
	field_view.position = Vector2.ZERO
	field_view.setup(state.field, Game.area)
	field_view.frame_in(Hud.BOSS_FREE_TOP if Game.boss_run else Hud.FREE_TOP, Hud.FREE_BOTTOM)
	var center_cell := Vector2i(state.field.size >> 1, state.field.size >> 1)
	var center_viewport := field_view.content.get_global_transform_with_canvas() * field_view.cell_center(center_cell)
	get_viewport().warp_mouse(center_viewport)
	field_view.cursor.position = field_view.cell_center(center_cell)
	front_fx.front = true
	var block_bottom := field_view.content.position.y + field_view.block.base_y(field_view.block.split_x)
	front_fx.fog_y = [block_bottom - 32.0, block_bottom - 6.0]
	field_view.attach_run(state)
	_stat_sheet = StatSheetPanel.new()
	add_child(_stat_sheet)
	state.pulse_resolved.connect(_on_pulse_resolved)
	state.layer_broken.connect(_on_layer_broken)
	state.tile_regenerated.connect(_on_tile_regenerated)
	state.field_cleared.connect(_on_field_cleared)
	state.xp_changed.connect(func(xp: float, needed: float, level: int) -> void: Events.run_xp_changed.emit(xp, needed, level))
	state.leveled_up.connect(func(level: int) -> void: Events.run_level_up.emit(level))
	state.grave_opened.connect(_on_grave_opened)
	state.grave_closed.connect(_on_grave_closed)
	state.gold_coin_collected.connect(_on_gold_coin_collected)
	state.wanderer_collected.connect(_on_wanderer_collected)
	state.unrest_changed.connect(func(v: float) -> void: Events.unrest_changed.emit(v))
	state.unrest_filled.connect(func() -> void: Events.unrest_filled.emit(Game.area.id))
	state.wisp_collected.connect(_on_wisp_collected)
	state.oil_drained.connect(_on_oil_drained)
	state.boss_changed.connect(func(hp: float, max_hp: float, _cells: Array[Vector2i]) -> void: hud.update_boss(hp, max_hp))
	state.boss_damaged.connect(func(_amount: float) -> void: hud.boss_hit())
	state.stomp_used.connect(_on_stomp_used)
	state.boss_hopped.connect(_on_boss_hopped)
	state.stomp_ready.connect(func() -> void: Audio.play(&"stomp_ready"))
	state.second_wind_triggered.connect(_on_second_wind)
	state.constellation_started.connect(_on_constellation)
	state.tombstone_effect.connect(func(_grave: Dictionary) -> void: Audio.play(&"tombstone_effect"))
	state.unrest_warned.connect(_on_unrest_warned)
	state.finished.connect(_on_finished)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	hud.refresh(state)
	hud.show_stomp(state)
	hud.options().closed.connect(func() -> void: _set_paused(false))
	# Pausa → "Voltar ao título" (UI/UX §9.4): o progresso já salvo fica; a noite em curso é abandonada.
	hud.options().title_requested.connect(func() -> void:
		_leaving = true  # a cortina despausa o jogo: o turno não pode andar durante a saída
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		Game.goto_title())
	# UI/UX §13.3 / §20: "Abandonar a noite" → Pátio sem os ganhos da noite.
	hud.options().abandon_requested.connect(func() -> void:
		_leaving = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		Game.abandon_night())
	if Game.boss_run:
		var boss_name := Game.boss_data.display_name if Game.boss_data != null else "O Caixão Fujão"
		var icon_id := String(Game.boss_data.icon_id) if Game.boss_data != null else "icon_boss_caixao"
		hud.show_boss(state.boss_hp, state.boss_hp_max, boss_name, icon_id)
		Audio.play_music(&"mus_boss")
	else:
		Audio.play_music(Game.area.music_id)
	Audio.play_ambience(&"amb_night")
	if Game.boss_run:
		await Game.show_dialogue(&"boss_intro")
	elif Game.turns_played == 0:
		await Game.show_dialogue(&"first_turn")
	Events.turn_started.emit()
	if Game.autopilot and OS.get_cmdline_user_args().has("--show-options"):
		_demo_options()


## Captura: abre o menu de pausa/opções por um instante (`-- --autopilot --show-options`).
func _demo_options() -> void:
	await get_tree().create_timer(3.0).timeout
	_set_paused(true)
	await get_tree().create_timer(1.5, true).timeout
	hud.options().close()


func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"toggle_stats") and not _paused and not _leaving and not state.ended:
		get_viewport().set_input_as_handled()
		_stat_sheet.toggle()
		return
	if event.is_action_pressed(&"stomp") and not _paused and not _leaving and not state.ended:
		if state.use_stomp():
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"pause") and not state.ended and not _paused:
		get_viewport().set_input_as_handled()
		_set_paused(true)


func _notification(what: int) -> void:
	# GDD §16: pausa automática ao perder o foco da janela.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state != null and not state.ended and not Game.autopilot and not _leaving:
		_set_paused(true)


func _set_paused(value: bool) -> void:
	if value == _paused:
		return
	_paused = value
	get_tree().paused = value
	if value:
		hud.open_options()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if value else Input.MOUSE_MODE_HIDDEN


func _process(delta: float) -> void:
	if _paused or _leaving or get_tree().paused:
		return
	if _hitstop > 0:
		_hitstop -= 1
		if _hitstop == 0:
			field_view.process_mode = Node.PROCESS_MODE_PAUSABLE
		return
	var cell := _cursor_cell(delta)
	state.advance(delta, cell)
	field_view.cursor.position = field_view.cell_center(cell) if Game.autopilot else field_view.mouse_position()
	field_view.outline.set_cells(state.area_cells(cell))
	field_view.refresh(cell, state.light_radius())
	hud.refresh(state)
	var hovered_grave := state.grave_at(cell) if not Game.autopilot else {}
	hud.update_grave_tooltip(hovered_grave, get_viewport().get_mouse_position())


func _cursor_cell(delta: float) -> Vector2i:
	if not Game.autopilot:
		return field_view.mouse_cell()
	# Demonstração/captura: passeia pelo campo e visita as covas.
	_autopilot_t += delta
	if not state.graves.is_empty() and fmod(_autopilot_t, 20.0) < 12.0:
		return state.graves[0].head as Vector2i
	var c := (state.field.size - 1) * 0.5
	return Vector2i(roundi(c + 4.0 * sin(_autopilot_t * 0.45)), roundi(c + 4.0 * cos(_autopilot_t * 0.31)))


func _reduce_flashes() -> bool:
	return bool(Game.settings.get("reduce_flashes", false))


# --- Reações ao modelo (feedback "cavar é gostoso", GDD §2.2 pilar 1) -----------------

func _on_pulse_resolved(report: Dictionary) -> void:
	Events.pulse_resolved.emit(report)
	field_view.outline.flash()
	field_view.cursor.strike(state.pulse_interval())
	if bool(report.get("stomp", false)):
		field_view.shake(2.0, 0.12)
		Audio.play(&"stomp")
	var hits: Array = report.hits
	var limit := Game.balance.max_floating_numbers
	var total_shown := 0.0
	var to_show: Array[Dictionary] = []
	for h: Dictionary in hits:
		var cell: Vector2i = h.cell
		var pos := field_view.cell_center(cell)
		var layer: LayerData = h.layer
		field_view.particles.burst(pos, layer.particle_colors, 2, 0.6, _clod_row(layer))
		# Cobre por tile por golpe; só valores ≥ 1 sobem, o resto acumula no tile.
		var pending := float(_copper_pending.get(cell, 0.0)) + float(h.copper)
		if pending >= 1.0:
			var whole := floorf(pending)
			pending -= whole
			to_show.append({"pos": pos, "value": whole, "crit": bool(h.crit)})
			total_shown += whole
		_copper_pending[cell] = pending
	if to_show.size() > limit:
		# GDD §14.4: acima do limite, agrega num número grande no centro.
		var center := field_view.cell_center(report.center as Vector2i) - Vector2(0, 10)
		field_view.numbers.spawn(center, "+" + NumberFormat.format(total_shown), Palette.LANTERN_BRIGHT, false)
	else:
		for n: Dictionary in to_show:
			var color := Palette.LANTERN_BRIGHT if bool(n.crit) else Palette.BONE
			field_view.numbers.spawn((n.pos as Vector2) - Vector2(0, 6), "+" + NumberFormat.format(float(n.value)), color)
	# UI/UX §4: moedas voam do tile até o ícone de Cobre do HUD.
	if total_shown > 0.0:
		var coins := mini(MAX_COINS_PER_PULSE, to_show.size())
		for i: int in coins:
			hud.fly(ResourceIcon.Kind.COPPER, _to_screen(to_show[i].pos as Vector2), total_shown / coins)
	if _pulse_xp > 0.0:
		var c := field_view.cell_center(report.center as Vector2i) - Vector2(0, 22)
		field_view.numbers.spawn(c, "+%s xp" % NumberFormat.format(_pulse_xp), Palette.SOUL, false)
		_pulse_xp = 0.0
	if bool(report.any_crit):
		field_view.shake(1.0, 0.1)
	# GDD §18.3 passo 5: 1 som por tipo de camada por golpe, não 1 por tile.
	var sounds: Dictionary = {}
	for h: Dictionary in hits:
		sounds[(h.layer as LayerData).sfx_key] = true
	for key: StringName in sounds:
		Audio.play(key)
	if not (report.broken as Dictionary).is_empty():
		Audio.play(&"layer_break")


func _on_layer_broken(cell: Vector2i, layer: LayerData, bone: bool, xp: float, crit: bool) -> void:
	Events.layer_broken.emit(cell, layer, bone, xp, crit)
	var pos := field_view.cell_center(cell)
	field_view.particles.burst(pos, layer.particle_colors, 6, 1.0, _clod_row(layer))
	if not layer.particle_colors.is_empty():
		field_view.particles.dust(pos, layer.particle_colors[0], mini(layer.stage_column, 2))
	if not _reduce_flashes():
		field_view.particles.flash(pos)
	# A quebra ganha destaque pelo flash, pelo XP agregado do golpe e pelo Osso.
	_pulse_xp += xp
	if bone:
		var bones := state.bone_value()
		field_view.numbers.spawn(pos - Vector2(0, 22), tr("+%s osso" if bones < 1.5 else "+%s ossos") % NumberFormat.format(bones), Palette.BONE_SHADOW, false)
		hud.fly(ResourceIcon.Kind.BONES, _to_screen(pos), bones)


## Linha de material dos torrões/poeira: só camadas de solo da área (Rocha/Caixão usam cores).
func _clod_row(layer: LayerData) -> int:
	return layer.stage_column if layer.stage_column <= 2 and Game.area.layers.has(layer) else -1


func _on_tile_regenerated(cell: Vector2i) -> void:
	Events.tile_regenerated.emit(cell)
	field_view.play_regen(cell)


func _on_field_cleared(bonus: float) -> void:
	Events.field_cleared.emit(bonus)
	field_view.shake(2.0, 0.25)
	for i: int in state.field.tile_count():
		field_view.play_regen(state.field.cell_of(i))


func _on_grave_opened(grave: Dictionary, rewards: Dictionary) -> void:
	Events.grave_opened.emit(grave, rewards)
	Game.show_tip(&"first_grave")
	var cells: Array = grave.cells
	var mid := (field_view.cell_center(cells[0] as Vector2i) + field_view.cell_center(cells[1] as Vector2i)) * 0.5
	field_view.numbers.spawn(mid - Vector2(0, 30), "+%s" % NumberFormat.format(float(rewards.copper)), Palette.LANTERN_BRIGHT, false)
	var souls := float(rewards.get("souls", 0.0))
	field_view.numbers.spawn(mid - Vector2(0, 20), tr("+%s alma" if souls < 1.5 else "+%s almas") % NumberFormat.format(souls) + "  " + tr("+%s ossos") % NumberFormat.format(float(rewards.bones)), Palette.SOUL, false)
	field_view.shake(2.0, 0.2)
	hud.show_toast("COVA ABERTA!", 1.2)
	Audio.play(&"grave_open")
	Audio.play(&"stinger_grave")
	Audio.duck()
	var from := _to_screen(mid)
	var copper := float(rewards.copper)
	for i: int in 4:
		hud.fly(ResourceIcon.Kind.COPPER, from + Vector2(randf_range(-8, 8), randf_range(-4, 4)), copper / 4.0)
	for i: int in int(rewards.bones):
		hud.fly(ResourceIcon.Kind.BONES, from + Vector2(randf_range(-8, 8), 0), 1.0)
	hud.fly(ResourceIcon.Kind.SOULS, from - Vector2(0, 24), float(rewards.get("souls", 1.0)))
	if not _reduce_flashes():
		_hitstop = HITSTOP_FRAMES
		field_view.process_mode = Node.PROCESS_MODE_DISABLED


func _on_grave_closed(grave: Dictionary) -> void:
	for c: Vector2i in grave.cells:
		_copper_pending.erase(c)


func _on_wisp_collected(wisp: Dictionary, oil: float) -> void:
	Events.wisp_collected.emit(oil)
	Audio.play(&"wisp_collect")
	field_view.numbers.spawn(field_view.cell_center(wisp.cell as Vector2i) - Vector2(0, 16), "+%d s" % roundi(oil), Palette.ECTO_BRIGHT, false)


func _on_gold_coin_collected(coin: Dictionary, copper: float) -> void:
	var pos := field_view.cell_center(coin.cell as Vector2i)
	Audio.play(&"coin_gold")
	field_view.numbers.spawn(pos - Vector2(0, 18), "+%s" % NumberFormat.format(copper), Palette.LANTERN_BRIGHT, false)
	hud.fly(ResourceIcon.Kind.COPPER, _to_screen(pos), copper)


func _on_wanderer_collected(wanderer: Dictionary, souls: float) -> void:
	var pos := field_view.cell_center(wanderer.cell as Vector2i)
	Audio.play(&"soul_wander")
	field_view.numbers.spawn(pos - Vector2(0, 18), tr("+%s alma" if souls < 1.5 else "+%s almas") % NumberFormat.format(souls), Palette.SOUL, false)
	# GDD §4.8: a alminha agradece em 1 palavra.
	field_view.numbers.spawn(pos - Vector2(0, 28), tr(String(THANKS[randi() % THANKS.size()])), Palette.BONE_BRIGHT, false)
	hud.fly(ResourceIcon.Kind.SOULS, _to_screen(pos), souls)


## Pisão (UI/UX §13.1): anel na área; com o Pisão Sísmico um 2º anel 1 tile maior 60 ms depois.
func _on_stomp_used(cells: Array[Vector2i]) -> void:
	var base := state.area_cells(state.cursor_cell)
	field_view.play_stomp(base)
	if cells.size() > base.size():
		get_tree().create_timer(STOMP_RING_DELAY).timeout.connect(func() -> void:
			if is_instance_valid(field_view):
				field_view.play_stomp(cells))


func _on_boss_hopped(_old_cells: Array[Vector2i], _new_cells: Array[Vector2i]) -> void:
	Audio.play(&"boss_sink")
	get_tree().create_timer(Game.boss_data.hop_invulnerability if Game.boss_data != null else 0.6).timeout.connect(func() -> void:
		Audio.play(&"boss_emerge"))


## L06 (GDD §4.5): a lanterna volta com 5 s.
func _on_second_wind(oil: float) -> void:
	Audio.play(&"second_wind")
	hud.show_toast(tr("SEGUNDO FÔLEGO!") + "  +%d s" % roundi(oil), 1.6)
	field_view.shake(1.0, 0.15)


## LX (GDD §4.5): Constelação para o óleo.
func _on_constellation(duration: float) -> void:
	Audio.play(&"constellation")
	hud.show_toast(tr("CONSTELAÇÃO!") + "  " + tr("óleo parado por %d s") % roundi(duration), 1.8)


## GDD §4.11: a Inquietação cruzou 90% — a terra treme.
func _on_unrest_warned() -> void:
	Audio.play(&"unrest_warning")
	field_view.shake(2.0, 0.4)


func _on_oil_drained(cells: Array[Vector2i], amount: float) -> void:
	var each := amount / maxf(1.0, cells.size())
	for c: Vector2i in cells:
		field_view.numbers.spawn(field_view.cell_center(c) - Vector2(0, 16), "-%s s" % String.num(each, 1).replace(".", ","), Palette.DANGER, false)


func _on_finished(result: TurnResult) -> void:
	Events.turn_ended.emit(result)
	Game.finish_turn(result)
	hud.refresh(state)
	if result.end_reason == &"oil":
		Audio.play(&"oil_out")
	if result.boss_encounter and result.boss_victory:
		# UI/UX §13.2: a barra estoura, hit-stop de 2 frames, boss_defeat → jingle_boss_win.
		hud.boss_defeated()
		if not _reduce_flashes():
			_hitstop = HITSTOP_FRAMES
			field_view.process_mode = Node.PROCESS_MODE_DISABLED
		Audio.play(&"boss_defeat")
		Audio.play_jingle(&"jingle_boss_win")
		await get_tree().create_timer(0.6).timeout
		await Game.show_dialogue(&"boss_victory")
	elif result.boss_encounter:
		hud.boss_fled()
		Audio.play(&"boss_flee")
	var finish_text := "CHEFE VENCIDO!" if result.boss_victory else ("O ÓLEO ACABOU" if result.end_reason == &"oil" else "O SOL NASCEU")
	hud.show_toast(finish_text, 2.0)
	await get_tree().create_timer(SUMMARY_DELAY).timeout
	hud.settle()
	await hud.play_exit().finished
	Game.goto_summary()


## Posição na tela (coordenadas do HUD) de um ponto do conteúdo do campo.
func _to_screen(p: Vector2) -> Vector2:
	return field_view.content.get_global_transform_with_canvas() * p
