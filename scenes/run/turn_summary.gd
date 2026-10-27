extends Control
## Resumo do Turno (GDD §15.4, UI/UX §6): linhas entram uma a uma vindo de −8 px (120 ms de
## defasagem), cada valor conta de 0 com tique, nó mais barato e os 2 botões grandes.

const ROW_STAGGER := 0.12
const ROW_SLIDE := 8.0
const ROW_TIME := 0.16
const PANEL_W := 320
const ROW_H := 16

var _rows: Array[Dictionary] = []  # {holder, inner, label, value}
var _panel: PanelContainer
var _buttons: HBoxContainer


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

	_panel = PanelContainer.new()
	_panel.modulate.a = 0.0  # aparece já posicionado (layout leva 1 frame)
	add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	_panel.add_child(box)

	var title := Label.new()
	title.theme_type_variation = &"PanelTitle"
	title.text = "Fim da noite %d" % Game.turns_played
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var reason := Label.new()
	reason.text = "O óleo acabou." if r.end_reason == &"oil" else "O sol nasceu."
	reason.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reason.add_theme_color_override("font_color", Palette.color(Palette.BONE_SHADOW))
	box.add_child(reason)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 0)
	box.add_child(list)
	_add_row(list, "Cobre", r.copper_mined, ResourceIcon.Kind.COPPER)
	_add_row(list, "Ossos", r.bones, ResourceIcon.Kind.BONES)
	_add_row(list, "Almas", r.souls, ResourceIcon.Kind.SOULS)
	_add_row(list, "Covas abertas", r.graves_opened)
	_add_row(list, "Camadas quebradas", r.layers_broken)
	_add_row(list, "Maior crítico", r.max_crit)
	_add_row(list, "Bônus do óleo (%d s)" % floori(r.oil_left), r.oil_bonus, ResourceIcon.Kind.COPPER)
	if r.field_clears > 0:
		_add_row(list, "Campo Limpo ×%d" % r.field_clears, r.field_clear_bonus, ResourceIcon.Kind.COPPER)
	var sep := HSeparator.new()
	list.add_child(sep)
	_add_row(list, "Total de Cobre", r.copper_total(), ResourceIcon.Kind.COPPER, true)

	box.add_child(HSeparator.new())
	box.add_child(_build_next_node())

	_buttons = HBoxContainer.new()
	_buttons.add_theme_constant_override("separation", 14)
	_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_buttons.modulate.a = 0.0
	add_child(_buttons)
	var tree_btn := _big_button("Árvore", Game.goto_tree)
	var again_btn := _big_button("Mais uma noite", Game.goto_run)
	_buttons.add_child(tree_btn)
	_buttons.add_child(again_btn)
	tree_btn.grab_focus()
	# UI/UX §6: o botão certo "chama" — Árvore se dá para comprar algo; senão, mais uma noite.
	var info := Game.tree.cheapest_pending(Economy.balances)
	var calling := tree_btn if (not info.is_empty() and bool(info.affordable)) else again_btn

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


func _add_row(list: VBoxContainer, text: String, value: float, icon: int = -1, total: bool = false) -> void:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(PANEL_W - 12, ROW_H)
	list.add_child(holder)
	var inner := HBoxContainer.new()
	inner.add_theme_constant_override("separation", 3)
	inner.size = Vector2(PANEL_W - 12, ROW_H)
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
func _animate() -> void:
	for i: int in _rows.size():
		var row: Dictionary = _rows[i]
		var inner: HBoxContainer = row.inner
		var label: Label = row.label
		var target := float(row.value)
		var delay := 0.15 + i * ROW_STAGGER
		inner.position.x = -ROW_SLIDE
		var t := inner.create_tween().set_parallel(true)
		t.tween_property(inner, "position:x", 0.0, ROW_TIME).set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.tween_property(inner, "modulate:a", 1.0, ROW_TIME).set_delay(delay)
		var start_count := func() -> void:
			Audio.play_tick()
			if target > 0.0:
				Juice.count(label, 0.0, target, Juice.count_duration(target))
		t.chain().tween_callback(start_count)


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
