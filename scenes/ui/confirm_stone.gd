class_name ConfirmStone
extends Control
## Confirmação em lápide (`panel_stone`, UI/UX §13.3/§16): título, aviso, botão de perigo
## (`btn_perigo`, 31/32) e "Voltar" com o foco. Esc/B também volta. Funciona com o jogo pausado.

signal confirmed()
signal cancelled()

var title_text: String = "Abandonar a noite?"
var note_text: String = "Os ganhos desta noite serão perdidos."
var confirm_text: String = "Abandonar"
var back_text: String = "Voltar"

var _panel: PanelContainer
var _title: Label
var _note: Label
var _confirm: Button
var _back: Button
var _open: bool = false


func _ready() -> void:
	size = Vector2(640, 360)
	theme = UiTheme.get_theme()
	process_mode = Node.PROCESS_MODE_ALWAYS
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
	_title = Label.new()
	_title.theme_type_variation = &"PanelTitle"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_color_override("font_color", Palette.color(Palette.OUTLINE))
	box.add_child(_title)
	_note = Label.new()
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_note.add_theme_color_override("font_color", Palette.color(Palette.BG))
	box.add_child(_note)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)
	_confirm = Button.new()
	_confirm.theme_type_variation = &"BigButton"
	_confirm.custom_minimum_size = Vector2(84, 0)
	for state: StringName in [&"normal", &"hover", &"pressed", &"disabled"]:
		_confirm.add_theme_stylebox_override(String(state), TitleArt.danger_style(state))
	_confirm.add_theme_stylebox_override("hover_pressed", TitleArt.danger_style(&"pressed"))
	_confirm.pressed.connect(_on_confirm)
	row.add_child(_confirm)
	_back = Button.new()
	_back.theme_type_variation = &"BigButton"
	_back.custom_minimum_size = Vector2(84, 0)
	_back.pressed.connect(close)
	row.add_child(_back)


func is_open() -> bool:
	return _open


func open() -> void:
	_title.text = tr(title_text)
	_note.text = tr(note_text)
	_confirm.text = tr(confirm_text)
	_back.text = tr(back_text)
	_open = true
	visible = true
	await get_tree().process_frame
	_panel.position = ((Vector2(640, 360) - _panel.size) * 0.5).floor()
	_panel.set_meta(&"panel_base", _panel.position)
	Juice.panel_open(_panel)
	_back.grab_focus()


func close() -> void:
	if not _open:
		return
	_open = false
	await Juice.panel_close(_panel).finished
	visible = false
	cancelled.emit()


func _on_confirm() -> void:
	if not _open:
		return
	_open = false
	await Juice.panel_close(_panel, false).finished
	visible = false
	confirmed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if _open and (event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"pause")):
		get_viewport().set_input_as_handled()
		close()
