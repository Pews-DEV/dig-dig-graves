class_name StatSheetPanel
extends CanvasLayer
## Ficha do Coveiro (GDD §6, nó N01; UI/UX §22): todos os stats calculados, aberta com Tab.
## Pergaminho centralizado com grupos em 2 colunas, faixa de Habilidades e tooltip por linha.

## UI/UX §22 pede ~480×280; 296 de altura deixa a Ficha base inteira sem rolagem.
const PANEL_RECT := Rect2(80, 32, 480, 296)
const COLUMN_GAP := 14
const ROW_HEIGHT := 12
const TOOLTIP_WIDTH := 196
const DIVIDER_COLOR := Palette.DIRT_EDGE  # UI/UX §22: linha fina 17
const ROW_HOVER_COLOR := Palette.BONE_SHADOW
## As fontes pixel têm ascent de sobra (m6x11plus 18: altura 18, ascent 15). Na Ficha as linhas
## usam variações aparadas: as duas fontes ficam com a linha de base em y = 10 e a linha em 12 px.
const BODY_TRIM := Vector2i(-1, -1)  # topo, base (m5x7 16: 13 → 11 px, ascent 10)
const TITLE_TRIM := Vector2i(-5, -1)  # m6x11plus 18: 18 → 12 px, ascent 10

static var _body_tight: FontVariation
static var _title_tight: FontVariation

var _root: Control
var _title: Label
var _abilities_title: Label
var _dim: TextureRect
var _panel: PanelContainer
var _scroll: ScrollContainer
var _left: VBoxContainer
var _right: VBoxContainer
var _abilities: VBoxContainer
var _tags: HFlowContainer
var _tooltip: PanelContainer
var _tip_title: Label
var _tip_desc: Label
var _tip_values: Label
var _tip_anchor: Control
var _rows: Array[Control] = []
var _is_open: bool = false
var _row_normal: StyleBox
var _row_hover: StyleBox


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	_build()


func _build() -> void:
	_row_normal = UiKit.flat_box(-1, -1, 1, 0)
	_row_hover = UiKit.flat_box(ROW_HOVER_COLOR, -1, 1, 0)
	_root = Control.new()
	_root.size = Vector2(640, 360)
	_root.theme = UiTheme.get_theme()  # o CanvasLayer corta a herança do tema da janela
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.visible = false
	_root.gui_input.connect(_on_root_input)
	add_child(_root)
	_dim = TextureRect.new()
	_dim.texture = OptionsMenu._checker()
	_dim.stretch_mode = TextureRect.STRETCH_TILE
	_dim.size = Vector2(640, 360)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_dim)

	_panel = PanelContainer.new()
	_panel.theme_type_variation = &"ParchmentPanel"
	_panel.position = PANEL_RECT.position
	_panel.size = PANEL_RECT.size
	_panel.custom_minimum_size = PANEL_RECT.size
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP  # clique dentro não fecha
	_root.add_child(_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	_panel.add_child(column)

	var header := HBoxContainer.new()
	column.add_child(header)
	_title = Label.new()
	_title.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_title.theme_type_variation = &"ParchmentTitle"
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(_title)
	var close := Button.new()
	close.text = "×"
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(close_panel)
	header.add_child(close)
	column.add_child(_divider())

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED  # UI/UX §22: nunca horizontal
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	column.add_child(_scroll)
	var pad := MarginContainer.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_theme_constant_override("margin_right", 4)  # folga para a barra vertical
	_scroll.add_child(pad)
	var cols := HBoxContainer.new()
	cols.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation", COLUMN_GAP)
	pad.add_child(cols)
	_left = _column()
	cols.add_child(_left)
	_right = _column()
	cols.add_child(_right)

	_abilities = VBoxContainer.new()
	_abilities.add_theme_constant_override("separation", 2)
	column.add_child(_abilities)
	_abilities_title = _group_title(StatSheet.GROUP_ABILITIES)
	_abilities.add_child(_abilities_title)
	_abilities.add_child(_divider())
	_tags = HFlowContainer.new()
	_tags.add_theme_constant_override("h_separation", 4)
	_tags.add_theme_constant_override("v_separation", 2)
	_abilities.add_child(_tags)

	_build_tooltip()
	_refresh_rows()


func _build_tooltip() -> void:
	_tooltip = PanelContainer.new()
	_tooltip.add_theme_stylebox_override("panel", UiTheme.get_theme().get_stylebox("panel", "TooltipPanel"))
	_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip.visible = false
	_root.add_child(_tooltip)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip.add_child(box)
	_tip_title = _tip_label(&"ParchmentTitle", false)
	box.add_child(_tip_title)
	_tip_desc = _tip_label(&"ParchmentLabel", true)
	box.add_child(_tip_desc)
	_tip_values = _tip_label(&"ParchmentLabel", false)
	_tip_values.add_theme_color_override("font_color", UiTheme.parchment_accent())
	box.add_child(_tip_values)


func _tip_label(variation: StringName, wrap: bool) -> Label:
	var l := Label.new()
	l.theme_type_variation = variation
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(TOOLTIP_WIDTH, 0)
		l.size = Vector2(TOOLTIP_WIDTH, 0)
	return l


static func _tight(base: Font, trim: Vector2i) -> FontVariation:
	var f := FontVariation.new()
	f.base_font = base
	f.spacing_top = trim.x
	f.spacing_bottom = trim.y
	return f


static func body_tight() -> FontVariation:
	if _body_tight == null:
		_body_tight = _tight(UiTheme.body_font(), BODY_TRIM)
	return _body_tight


static func title_tight() -> FontVariation:
	if _title_tight == null:
		_title_tight = _tight(UiTheme.title_font(), TITLE_TRIM)
	return _title_tight


func _column() -> VBoxContainer:
	var c := VBoxContainer.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.size_flags_stretch_ratio = 1.0
	c.add_theme_constant_override("separation", 4)
	return c


func _divider() -> ColorRect:
	var line := ColorRect.new()
	line.color = Palette.color(DIVIDER_COLOR)
	line.custom_minimum_size = Vector2(0, 1)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line


func _group_title(group: StringName) -> Label:
	var l := Label.new()
	l.text = tr(StatSheet.group_title(group))
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	l.theme_type_variation = &"ParchmentTitle"
	l.add_theme_font_override("font", title_tight())
	l.add_theme_color_override("font_color", UiTheme.parchment_accent())
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func toggle() -> void:
	if not Game.tree.has_flag(&"stat_sheet"):
		Audio.play(&"shop_deny")
		return
	if _is_open:
		close_panel()
	else:
		open()


func open() -> void:
	_is_open = true
	_refresh_rows()
	_root.visible = true
	_scroll.scroll_vertical = 0
	_panel.position = PANEL_RECT.position
	_panel.set_meta(&"panel_base", PANEL_RECT.position)
	Juice.panel_open(_panel)  # já toca ui_panel_open
	_dim.modulate.a = 0.0
	_dim.create_tween().tween_property(_dim, "modulate:a", 1.0, Juice.PANEL_OPEN)


func close_panel() -> void:
	if not _is_open:
		return
	_is_open = false
	_hide_tooltip()
	var focused := _root.get_viewport().gui_get_focus_owner()
	if focused != null and _root.is_ancestor_of(focused):
		focused.release_focus()
	_dim.create_tween().tween_property(_dim, "modulate:a", 0.0, Juice.PANEL_CLOSE)
	await Juice.panel_close(_panel).finished
	if not _is_open:
		_root.visible = false


func is_open() -> bool:
	return _is_open


func _refresh_rows() -> void:
	if _left == null:
		return
	_hide_tooltip()
	_rows.clear()
	# Textos fixos também, para seguir uma troca de idioma nas Opções.
	_title.text = tr("FICHA DO COVEIRO")
	_abilities_title.text = tr(StatSheet.group_title(StatSheet.GROUP_ABILITIES))
	var parents: Array[Control] = [_left, _right, _tags]
	for parent: Control in parents:
		for child: Node in parent.get_children():
			parent.remove_child(child)
			child.queue_free()
	# GDD §18.2 / UI/UX §22: só stats com rótulo; regras/ativos aparecem ao comprar.
	var stomp_on := Stats.get_value(StatSheet.STOMP_ENABLED) > 0.0
	for group: StringName in StatSheet.SHEET_LEFT:
		_add_group(_left, group, stomp_on)
	for group: StringName in StatSheet.SHEET_RIGHT:
		_add_group(_right, group, stomp_on)
	var abilities: Array = StatSheet.GROUPS[StatSheet.GROUP_ABILITIES]
	for stat_id: StringName in abilities:
		if Stats.get_value(stat_id) > 0.0:
			_tags.add_child(_tag(stat_id))
	_abilities.visible = _tags.get_child_count() > 0


func _add_group(parent: VBoxContainer, group: StringName, stomp_on: bool) -> void:
	var stats: Array = StatSheet.GROUPS[group]
	var rows: Array[Control] = []
	for stat_id: StringName in stats:
		var v := Stats.get_value(stat_id)
		if not StatSheet.is_visible_on_sheet(stat_id, v, stomp_on):
			continue
		rows.append(_row(stat_id, v))
	if rows.is_empty():
		return
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(box)
	box.add_child(_group_title(group))
	var line := _divider()
	box.add_child(line)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 1)
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(gap)
	for r: Control in rows:
		box.add_child(r)
		_rows.append(r)


## UI/UX §22: rótulo m5x7 à esquerda, valor m6x11plus à direita; acima do base em 26.
func _row(stat_id: StringName, v: float) -> PanelContainer:
	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", _row_normal)
	row.custom_minimum_size = Vector2(0, ROW_HEIGHT)
	row.focus_mode = Control.FOCUS_ALL
	row.mouse_filter = Control.MOUSE_FILTER_PASS  # a roda do mouse ainda rola a lista
	row.set_meta(&"stat", stat_id)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 4)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(h)
	var label := Label.new()
	label.text = tr(StatSheet.short_label_of(stat_id))
	label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	label.theme_type_variation = &"ParchmentLabel"
	label.add_theme_font_override("font", body_tight())
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN  # linhas de base alinhadas (BODY/TITLE_TRIM)
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS  # nunca quebra; o completo vai no tooltip
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(label)
	var value := Label.new()
	value.text = tr(StatSheet.format_value(stat_id, v))
	value.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.size_flags_horizontal = Control.SIZE_SHRINK_END
	value.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _is_upgraded(stat_id, v):
		# Mesmo estilo do valor novo do "antes → depois" da Árvore: 26 com contorno 01.
		value.theme_type_variation = &"HudNumber"
		value.add_theme_color_override("font_color", Palette.color(Palette.LANTERN_BRIGHT))
	else:
		value.theme_type_variation = &"ParchmentTitle"
	value.add_theme_font_override("font", title_tight())
	h.add_child(value)
	_wire_hover(row, stat_id)
	return row


func _tag(stat_id: StringName) -> PanelContainer:
	var tag := PanelContainer.new()
	tag.add_theme_stylebox_override("panel", UiKit.flat_box(Palette.BONE_SHADOW, DIVIDER_COLOR, 3, 1))
	tag.focus_mode = Control.FOCUS_ALL
	tag.mouse_filter = Control.MOUSE_FILTER_STOP
	var l := Label.new()
	l.text = tr(StatSheet.label_of(stat_id))
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	l.theme_type_variation = &"ParchmentLabel"
	l.add_theme_font_override("font", body_tight())
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.add_child(l)
	_wire_hover(tag, stat_id, false)
	_rows.append(tag)
	return tag


func _wire_hover(c: Control, stat_id: StringName, highlight: bool = true) -> void:
	var on := func() -> void:
		if highlight:
			c.add_theme_stylebox_override("panel", _row_hover)
		_show_tooltip(c, stat_id)
	var off := func() -> void:
		if highlight and not c.has_focus():
			c.add_theme_stylebox_override("panel", _row_normal)
		if _tip_anchor == c and not c.has_focus():
			_hide_tooltip()
	var focus_off := func() -> void:
		if highlight:
			c.add_theme_stylebox_override("panel", _row_normal)
		if _tip_anchor == c:
			_hide_tooltip()
	c.mouse_entered.connect(on)
	c.focus_entered.connect(on)
	c.mouse_exited.connect(off)
	c.focus_exited.connect(focus_off)


## Valor diferente do base = melhorado por alguma fonte (todo nó da Árvore melhora o stat,
## inclusive os que reduzem: intervalo, recarga, queima, regeneração).
func _is_upgraded(stat_id: StringName, v: float) -> bool:
	if Stats.sheet == null:
		return false
	return absf(v - Stats.sheet.base_value(stat_id)) > 0.000001


func _base_of(stat_id: StringName) -> float:
	return Stats.sheet.base_value(stat_id) if Stats.sheet != null else 0.0


func _show_tooltip(anchor: Control, stat_id: StringName) -> void:
	var v := Stats.get_value(stat_id)
	_tip_title.text = tr(StatSheet.label_of(stat_id))
	var desc := StatSheet.description_of(stat_id)
	_tip_desc.text = tr(desc) if not desc.is_empty() else ""
	_tip_desc.visible = not desc.is_empty()
	_tip_values.text = tr("Base %s → atual %s") % [tr(StatSheet.format_value(stat_id, _base_of(stat_id))), tr(StatSheet.format_value(stat_id, v))]
	_tip_anchor = anchor
	_tooltip.visible = true
	_tooltip.reset_size()
	_place_tooltip()


func _hide_tooltip() -> void:
	_tip_anchor = null
	if _tooltip != null:
		_tooltip.visible = false


## Embaixo da linha, alinhado à esquerda; sobe se não couber e fica dentro dos 640×360.
func _place_tooltip() -> void:
	if _tip_anchor == null or not is_instance_valid(_tip_anchor):
		return
	var r := _tip_anchor.get_global_rect()
	var s := _tooltip.get_combined_minimum_size()
	_tooltip.size = s
	var pos := Vector2(r.position.x, r.end.y + 2)
	if pos.y + s.y > 358.0:
		pos.y = r.position.y - s.y - 2
	pos.x = clampf(pos.x, 2.0, 638.0 - s.x)
	pos.y = clampf(pos.y, 2.0, 358.0 - s.y)
	_tooltip.position = pos.floor()


func _process(_delta: float) -> void:
	if _tooltip != null and _tooltip.visible:
		_place_tooltip()


## Clique fora do pergaminho fecha (o painel para os cliques de dentro).
func _on_root_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if _is_open and mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		_root.accept_event()
		close_panel()


func _input(event: InputEvent) -> void:
	if not _is_open:
		return
	# Antes da GUI: com uma linha em foco, Tab viraria navegação de foco.
	if event.is_action_pressed(&"toggle_stats") or event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		close_panel()
		return
	var nav := event.is_action_pressed(&"ui_down") or event.is_action_pressed(&"ui_up")
	if nav and not _rows.is_empty():
		var focused := get_viewport().gui_get_focus_owner()
		if focused == null or not _root.is_ancestor_of(focused):
			get_viewport().set_input_as_handled()
			_rows[0].grab_focus()
