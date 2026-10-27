class_name TitleConfirm
extends Control
## Confirmação de "Novo Jogo" com save (UI/UX §9.4): painel de pedra em lápide
## ("panel_stone"), "Enterrar o progresso atual?", botões "Enterrar" (btn_perigo, 31/32) e
## "Voltar". O foco começa em "Voltar"; Esc/B também volta.

signal buried()
signal cancelled()

var _panel: PanelContainer
var _buttons: Dictionary = {}  # StringName -> Button
var _open: bool = false


func _ready() -> void:
	size = Vector2(640, 360)
	theme = UiTheme.get_theme()
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var dim := TextureRect.new()
	dim.texture = TitleArt.dim_texture()
	dim.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dim.stretch_mode = TextureRect.STRETCH_TILE
	dim.size = Vector2(640, 360)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", TitleArt.stone_style())
	add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	_panel.add_child(box)
	var title := Label.new()
	title.theme_type_variation = &"PanelTitle"
	title.text = TitleMenuModel.CONFIRM_TEXT
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Palette.color(Palette.OUTLINE))
	box.add_child(title)
	var note := Label.new()
	note.text = "As noites, o cobre e as raízes vão para debaixo da terra."
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_color_override("font_color", Palette.color(Palette.BG))
	box.add_child(note)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)
	for id: StringName in TitleMenuModel.CONFIRM_ORDER:
		var b := Button.new()
		b.text = String(TitleMenuModel.CONFIRM_LABELS[id])
		b.theme_type_variation = &"BigButton"
		b.custom_minimum_size = Vector2(84, 0)
		# AUDIO_MANIFEST: no título o foco toca ui_wisp_slide (sem ui_hover); "Enterrar" toca ui_bury.
		b.set_meta(&"quiet_hover", true)
		if id == TitleMenuModel.BURY:
			b.set_meta(&"quiet_click", true)
			for state: StringName in [&"normal", &"hover", &"pressed", &"disabled"]:
				b.add_theme_stylebox_override(String(state), TitleArt.danger_style(state))
			b.add_theme_stylebox_override("hover_pressed", TitleArt.danger_style(&"pressed"))
			b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		b.focus_entered.connect(_on_focus.bind(b))
		b.mouse_entered.connect(func() -> void:
			if _open:
				b.grab_focus())
		row.add_child(b)
		_buttons[id] = b
	(_buttons[TitleMenuModel.BURY] as Button).pressed.connect(_on_bury)
	(_buttons[TitleMenuModel.BACK] as Button).pressed.connect(close)


func is_open() -> bool:
	return _open


func button(id: StringName) -> Button:
	return _buttons.get(id) as Button


func open() -> void:
	_open = true
	visible = true
	for b: Button in _buttons.values():
		b.focus_mode = Control.FOCUS_ALL
		b.disabled = false
	await get_tree().process_frame
	_panel.position = ((Vector2(640, 360) - _panel.size) * 0.5).floor()
	_panel.set_meta(&"panel_base", _panel.position)
	Juice.panel_open(_panel)
	(_buttons[TitleMenuModel.CONFIRM_FOCUS] as Button).grab_focus()


func close() -> void:
	if not _open:
		return
	_open = false
	_release_focus()
	await Juice.panel_close(_panel).finished
	visible = false
	cancelled.emit()


func _on_bury() -> void:
	if not _open:
		return
	_open = false
	Audio.play(&"ui_bury", 1.0, 0.0)
	_release_focus()
	await Juice.panel_close(_panel, false).finished
	visible = false
	buried.emit()


func _release_focus() -> void:
	for b: Button in _buttons.values():
		b.focus_mode = Control.FOCUS_NONE
		if b.has_focus():
			b.release_focus()


## Botão em foco ganha o calor da lanterna (estilo de hover, borda 26); o resto, normal.
func _on_focus(b: Button) -> void:
	if not _open:
		return
	Audio.play(&"ui_wisp_slide")
	for other: Button in _buttons.values():
		var focused := other == b
		var danger: bool = other == _buttons[TitleMenuModel.BURY]
		if focused:
			other.add_theme_stylebox_override("normal", TitleArt.danger_style(&"hover") if danger else UiKit.button_style(&"hover", 10))
		elif danger:
			other.add_theme_stylebox_override("normal", TitleArt.danger_style(&"normal"))
		else:
			other.remove_theme_stylebox_override("normal")


func _unhandled_input(event: InputEvent) -> void:
	if _open and (event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"pause")):
		get_viewport().set_input_as_handled()
		close()
