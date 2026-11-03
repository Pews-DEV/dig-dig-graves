extends Control
## Resumo do Turno (GDD §15.4, UI/UX §6): linhas entram uma a uma vindo de −8 px (120 ms de
## defasagem), cada valor conta de 0 com tique, nó mais barato e os 2 botões grandes.

const ROW_STAGGER := 0.12
const ROW_SLIDE := 8.0
const ROW_TIME := 0.16
const PANEL_W := 320
const ROW_H := 16
## UI/UX §15: título cai letra a letra (30 ms) e a Chave sobe girando em 600 ms.
const SPECIAL_LETTER := 0.03
const SPECIAL_KEY_RISE := 0.6
const SPECIAL_ROW_W := 264.0

var _rows: Array[Dictionary] = []  # {holder, inner, label, value}
var _panel: PanelContainer
var _buttons: HBoxContainer
var _special: bool = false
var _special_tweens: Array[Tween] = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var r: TurnResult = Game.last_result
	if r == null:
		r = TurnResult.new()
	Audio.play_jingle(&"jingle_summary")
	Audio.play_ambience(&"amb_night")

	# Mesmo céu do turno, para a noite "acabar" no mesmo lugar.
	var sky := RunBackdrop.new()
	add_child(sky)
	if r.boss_victory and not r.boss_rematch:
		# UI/UX §15: 1ª vitória sobre o chefe = Resumo especial.
		_build_special(r)
		var front := RunBackdrop.new()
		front.front = true
		add_child(front)
		move_child(front, 1)
		return

	_panel = PanelContainer.new()
	_panel.modulate.a = 0.0  # aparece já posicionado (layout leva 1 frame)
	add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	_panel.add_child(box)

	var title := Label.new()
	title.theme_type_variation = &"PanelTitle"
	if r.boss_encounter:
		title.text = _boss_name()
	else:
		title.text = tr("Fim da noite %d") % Game.turns_played
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	if r.boss_encounter and not r.boss_victory:
		# UI/UX §15: derrota = faixa de pedra "fugiu… faltaram X de vida".
		box.add_child(_stone_band(tr("%s fugiu… faltaram %s de vida") % [_boss_name(), NumberFormat.format(r.boss_hp_remaining)]))
	else:
		var reason := Label.new()
		if r.boss_victory:
			reason.text = tr("Revanche vencida")
		else:
			reason.text = tr("O óleo acabou.") if r.end_reason == &"oil" else tr("O sol nasceu.")
		reason.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		reason.add_theme_color_override("font_color", Palette.color(Palette.BONE_SHADOW))
		box.add_child(reason)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 0)
	box.add_child(list)
	_add_row(list, tr("Cobre"), r.copper_mined, ResourceIcon.Kind.COPPER)
	_add_row(list, tr("Ossos"), r.bones, ResourceIcon.Kind.BONES)
	_add_row(list, tr("Almas"), r.souls, ResourceIcon.Kind.SOULS)
	if r.boss_rematch and r.boss_victory:
		_add_row(list, tr("Revanche: Almas"), r.boss_reward_souls, ResourceIcon.Kind.SOULS)
	if r.tremor_souls > 0.0:
		_add_row(list, tr("Tremores: Almas extras"), r.tremor_souls, ResourceIcon.Kind.SOULS)
	if r.boss_encounter:
		_add_row(list, tr("Dano no chefe"), r.boss_damage_dealt)
	_add_row(list, tr("Covas abertas"), r.graves_opened)
	_add_row(list, tr("Camadas quebradas"), r.layers_broken)
	_add_row(list, tr("Maior crítico"), r.max_crit)
	_add_row(list, tr("Bônus do óleo (%d s)") % floori(r.oil_left), r.oil_bonus, ResourceIcon.Kind.COPPER)
	if r.field_clears > 0:
		_add_row(list, tr("Campo Limpo ×%d") % r.field_clears, r.field_clear_bonus, ResourceIcon.Kind.COPPER)
	if r.inheritance_bonus > 0.0:
		_add_row(list, tr("Herança"), r.inheritance_bonus, ResourceIcon.Kind.COPPER)
	var sep := HSeparator.new()
	list.add_child(sep)
	_add_row(list, tr("Total de Cobre"), r.copper_total(), ResourceIcon.Kind.COPPER, true)

	box.add_child(HSeparator.new())
	box.add_child(_build_next_node())

	_buttons = HBoxContainer.new()
	_buttons.add_theme_constant_override("separation", 14)
	_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_buttons.modulate.a = 0.0
	add_child(_buttons)
	var tree_btn := _big_button(tr("Árvore"), Game.goto_tree)
	var again_btn := _big_button(tr("Mais uma noite"), Game.goto_run)
	_buttons.add_child(tree_btn)
	_buttons.add_child(again_btn)
	tree_btn.grab_focus()
	# UI/UX §6: o botão certo "chama" — Árvore se dá para comprar algo; senão, mais uma noite.
	# Derrota na Noite do Chefe: a Árvore fica em foco e chamando (UI/UX §15).
	var info := Game.tree.cheapest_pending(Economy.balances)
	var calling := tree_btn if r.boss_encounter or (not info.is_empty() and bool(info.affordable)) else again_btn

	var vignette := RunBackdrop.new()
	vignette.front = true
	add_child(vignette)
	move_child(vignette, 1)

	await get_tree().process_frame
	_panel.size = Vector2(PANEL_W, 0)
	_panel.position = (Vector2(320 - PANEL_W * 0.5, 14)).floor()
	_buttons.size = Vector2(PANEL_W, 26)
	_buttons.position = Vector2(_panel.position.x, minf(_panel.position.y + _panel.size.y + 8, 360 - 34))
	Juice.panel_open(_panel)
	_buttons.modulate.a = 1.0
	Juice.slide_in(_buttons, Vector2(0, 40), 0.1)
	_animate()
	Juice.beckon(calling)
	if Game.autopilot:
		await get_tree().create_timer(3.5).timeout
		Game.goto_tree()


func _add_row(list: VBoxContainer, text: String, value: float, icon: int = -1, total: bool = false, width: float = PANEL_W - 12) -> void:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(width, ROW_H)
	list.add_child(holder)
	var inner := HBoxContainer.new()
	inner.add_theme_constant_override("separation", 3)
	inner.size = Vector2(width, ROW_H)
	inner.modulate.a = 0.0
	holder.add_child(inner)
	if icon >= 0:
		var ic := ResourceIcon.new()
		ic.kind = icon as ResourceIcon.Kind
		inner.add_child(ic)
	else:
		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(16, 16)
		inner.add_child(spacer)
	var name_label := Label.new()
	name_label.text = text
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if total:
		name_label.theme_type_variation = &"PanelTitle"
	inner.add_child(name_label)
	var value_label := Label.new()
	value_label.theme_type_variation = &"PanelTitle"
	value_label.text = "0"
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.custom_minimum_size = Vector2(80, 0)
	value_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if total:
		value_label.add_theme_color_override("font_color", Palette.color(Palette.LANTERN_BRIGHT))
	inner.add_child(value_label)
	_rows.append({"inner": inner, "label": value_label, "value": value})


## Linhas entram uma a uma vindo de −8 px; o valor conta com tique (UI/UX §6).
func _animate(base_delay: float = 0.15) -> void:
	for i: int in _rows.size():
		var row: Dictionary = _rows[i]
		var inner: HBoxContainer = row.inner
		var label: Label = row.label
		var target := float(row.value)
		var delay := base_delay + i * ROW_STAGGER
		inner.position.x = -ROW_SLIDE
		var t := inner.create_tween().set_parallel(true)
		t.tween_property(inner, "position:x", 0.0, ROW_TIME).set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.tween_property(inner, "modulate:a", 1.0, ROW_TIME).set_delay(delay)
		var start_count := func() -> void:
			Audio.play_tick()
			if target > 0.0:
				Juice.count(label, 0.0, target, Juice.count_duration(target))
		t.chain().tween_callback(start_count)
		inner.set_meta(&"tween", t)


## GDD §15.4 / pilar 2: "Faltam 34 ◉ para Lâmina Afiada Nv 4".
func _build_next_node() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	var info := Game.tree.cheapest_pending(Economy.balances)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 3)
	box.add_child(line)
	if info.is_empty():
		var done := Label.new()
		done.text = "Todos os nós revelados estão no máximo."
		line.add_child(done)
		return box
	var d := Game.tree.get_node_data(info.id as StringName)
	var currency: StringName = info.currency
	var have := Economy.get_amount(currency)
	var icon := ResourceIcon.new()
	icon.kind = ResourceIcon.kind_for_currency(currency)
	var pre := Label.new()
	var post := Label.new()
	for l: Label in [pre, post]:
		l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if bool(info.affordable):
		pre.text = "Dá para comprar: %s Nv %d por %s" % [d.display_name, int(info.level), NumberFormat.format(float(info.cost))]
	else:
		pre.text = "Faltam %s" % NumberFormat.format(ceilf(float(info.missing)))
		post.text = "para %s Nv %d" % [d.display_name, int(info.level)]
	line.add_child(pre)
	line.add_child(icon)
	line.add_child(post)
	var bar := PixelBar.new()
	bar.custom_minimum_size = Vector2(PANEL_W - 12, PixelBar.ART_HEIGHT if PixelBar.uses_art() else 7)
	bar.fill_texture_path = "res://assets/ui/hud/barra_oleo.png"
	bar.fill_color = Palette.LANTERN
	bar.highlight_color = Palette.LANTERN_BRIGHT
	bar.value = 0.0
	box.add_child(bar)
	var target := clampf(have / maxf(float(info.cost), 1.0), 0.0, 1.0)
	var t := bar.create_tween()
	t.tween_property(bar, "value", target, 0.8).set_delay(0.3 + _rows.size() * ROW_STAGGER).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return box


func _big_button(text: String, action: Callable) -> Button:
	var b := Button.new()
	b.theme_type_variation = &"BigButton"
	b.text = text
	b.custom_minimum_size = Vector2(130, 0)
	b.pressed.connect(action)
	return b


func _boss_name() -> String:
	return Game.boss_data.display_name if Game.boss_data != null else tr("O Caixão Fujão")


## Faixa de pedra (panel_stone) com texto escuro, como a lápide de confirmação.
func _stone_band(text: String) -> Control:
	var band := PanelContainer.new()
	band.add_theme_stylebox_override("panel", TitleArt.stone_style())
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(PANEL_W - 40, 0)
	l.add_theme_color_override("font_color", Palette.color(Palette.OUTLINE))
	band.add_child(l)
	return band


# --- Resumo especial pós-chefe (UI/UX §15) -------------------------------------------

## Título letra a letra → Chave sobe girando e pousa (key_get_1) → prêmios contam →
## "O que se abriu" linha a linha → "Ver o cemitério ▶" chama. Clique acelera para o fim.
func _build_special(r: TurnResult) -> void:
	_special = true
	var title := Label.new()
	title.theme_type_variation = &"TitleLabel"
	title.text = tr("%s DESCANSOU!") % _boss_name().to_upper()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 12)
	title.size = Vector2(640, 18)
	title.visible_characters = 0
	title.add_theme_color_override("font_color", Palette.color(Palette.LANTERN_BRIGHT))
	add_child(title)
	_special_tweens.append(_typewrite(title, SPECIAL_LETTER))

	var key := _KeyBurst.new()
	key.position = Vector2(320, 62)
	add_child(key)
	var key_delay := title.text.length() * SPECIAL_LETTER
	var key_t := key.create_tween()
	key_t.tween_interval(key_delay)
	key_t.tween_method(key.set_rise, 0.0, 1.0, SPECIAL_KEY_RISE)
	key_t.tween_callback(func() -> void:
		key.land()
		Audio.play_variant(&"key_get", 1))
	_special_tweens.append(key_t)

	var rewards := _special_panel(Vector2(28, 100), tr("PRÊMIOS"))
	var reward_box: VBoxContainer = rewards.get_meta(&"box")
	_add_row(reward_box, tr("Almas"), r.boss_reward_souls, ResourceIcon.Kind.SOULS, false, SPECIAL_ROW_W)
	_add_row(reward_box, tr("Ossos"), r.boss_reward_bones, ResourceIcon.Kind.BONES, false, SPECIAL_ROW_W)
	_add_row(reward_box, tr("Chave da Cripta I"), 1.0, ResourceIcon.Kind.KEY, false, SPECIAL_ROW_W)
	_add_row(reward_box, tr("Cobre da noite"), r.copper_total(), ResourceIcon.Kind.COPPER, false, SPECIAL_ROW_W)
	var note := Label.new()
	note.theme_type_variation = &"ParchmentLabel"
	note.text = tr("(+ ganhos normais da noite)")
	reward_box.add_child(note)

	var opened := _special_panel(Vector2(328, 100), tr("O QUE SE ABRIU"))
	var opened_box: VBoxContainer = opened.get_meta(&"box")
	var lines: Array[Array] = [
		[ResourceIcon.Kind.KEY, tr("Chave da Cripta I")],
		[ResourceIcon.Kind.LANTERN, tr("Campo dos Indigentes · Capítulo 2")],
		[ResourceIcon.Kind.SOULS, tr("Mascate e Pátio · Capítulo 2")],
	]
	var line_delay := key_delay + SPECIAL_KEY_RISE + 0.3
	for i: int in lines.size():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		row.modulate.a = 0.0
		var icon := ResourceIcon.new()
		icon.kind = lines[i][0] as ResourceIcon.Kind
		row.add_child(icon)
		var l := Label.new()
		l.theme_type_variation = &"ParchmentLabel"
		l.text = String(lines[i][1])
		l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(l)
		opened_box.add_child(row)
		var t := row.create_tween().set_parallel(true)
		t.tween_property(row, "modulate:a", 1.0, ROW_TIME).set_delay(line_delay + i * ROW_STAGGER)
		t.tween_property(row, "position:x", 0.0, ROW_TIME).from(-ROW_SLIDE).set_delay(line_delay + i * ROW_STAGGER)
		_special_tweens.append(t)

	_buttons = HBoxContainer.new()
	_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_buttons.position = Vector2(170, 320)
	_buttons.size = Vector2(300, 26)
	add_child(_buttons)
	var go := _big_button(tr("Ver o cemitério") + " ▶", Game.goto_tree)
	_buttons.add_child(go)
	go.grab_focus()
	await get_tree().process_frame
	for p: Control in [rewards, opened]:
		Juice.panel_open(p, Vector2(0, 6), false)
	_animate(key_delay + SPECIAL_KEY_RISE)
	Juice.slide_in(_buttons, Vector2(0, 40), line_delay)
	var beckon_t := create_tween()
	beckon_t.tween_interval(line_delay + lines.size() * ROW_STAGGER)
	beckon_t.tween_callback(func() -> void: Juice.beckon(go))
	if Game.autopilot:
		await get_tree().create_timer(4.0).timeout
		Game.goto_tree()


func _special_panel(pos: Vector2, heading: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.theme_type_variation = &"ParchmentPanel"
	p.position = pos
	p.custom_minimum_size = Vector2(284, 150)
	add_child(p)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	p.add_child(box)
	var h := Label.new()
	h.theme_type_variation = &"ParchmentTitle"
	h.text = heading
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(h)
	p.set_meta(&"box", box)
	return p


func _typewrite(label: Label, per_char: float) -> Tween:
	var t := label.create_tween()
	t.tween_property(label, "visible_characters", label.text.length(), per_char * label.text.length())
	return t


## Qualquer clique no Resumo especial acelera tudo para o fim (UI/UX §15).
func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if _special and mb != null and mb.pressed:
		for t: Tween in _special_tweens:
			if t != null and t.is_valid():
				t.custom_step(60.0)
		for row: Dictionary in _rows:
			var tw := (row.inner as Control).get_meta(&"tween", null) as Tween
			if tw != null and tw.is_valid():
				tw.custom_step(60.0)


## Chave da Cripta 32×32 (MANIFEST icon_key_1_32, tag `spin`) subindo girando com raios
## 26/23 em xadrez girando devagar atrás (sem raios com "reduzir movimento").
class _KeyBurst:
	extends Node2D

	const RISE_PX := 20.0
	var _sheet: AsepriteSheet = AsepriteSheet.load_id("icon_key_1_32")
	var _rise: float = 0.0
	var _landed: bool = false
	var _t: float = 0.0

	func set_rise(v: float) -> void:
		_rise = v

	func land() -> void:
		_landed = true
		Juice.pop(self, 0.2, 0.16)

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		if _rise <= 0.0:
			return
		if _landed and not Juice.reduce_motion():
			for i: int in 8:
				var a := _t * 0.6 + TAU * float(i) / 8.0
				for k: int in range(18, 34, 2):
					var p := (Vector2(cos(a), sin(a)) * float(k)).floor()
					draw_rect(Rect2(p, Vector2.ONE), Palette.color(Palette.LANTERN_BRIGHT if (k >> 1) % 2 == 0 else Palette.BONE_BRIGHT))
		var pos := Vector2(0, roundf(RISE_PX * (1.0 - _rise)))
		if _sheet != null and _sheet.texture != null:
			var frame := 0 if _landed else _sheet.frame_at(&"spin", _t, true)
			_sheet.draw_frame(self, frame, pos, Vector2(16, 16))
		else:
			draw_rect(Rect2(pos - Vector2(6, 10), Vector2(12, 20)), Palette.color(Palette.STONE))
