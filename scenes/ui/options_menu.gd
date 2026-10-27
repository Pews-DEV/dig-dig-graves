class_name OptionsMenu
extends Control
## Pausa com opções mínimas (GDD §16, UI/UX §1.6): volume por canal, reduzir movimento,
## reduzir flashes, intensidade do tremor e tamanho dos números flutuantes. Salva ao fechar.

signal closed()

const VOLUME_ROWS: Array[Array] = [
	["Volume geral", "vol_master"],
	["Música", "vol_music"],
	["Efeitos", "vol_sfx"],
	["Interface", "vol_ui"],
	["Ambiente", "vol_ambience"],
]

var title_text: String = "Pausa"
var _panel: PanelContainer
var _float_btn: Button
var _is_open: bool = false


func _ready() -> void:
	size = Vector2(640, 360)
	theme = UiTheme.get_theme()  # sob CanvasLayer o tema da janela nem sempre propaga
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var dim := TextureRect.new()
	dim.texture = _checker()
	dim.stretch_mode = TextureRect.STRETCH_TILE
	dim.size = Vector2(640, 360)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	_panel = PanelContainer.new()
	add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	_panel.add_child(box)
	var title := Label.new()
	title.theme_type_variation = &"PanelTitle"
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 3)
	box.add_child(grid)
	for row: Array in VOLUME_ROWS:
		_slider_row(grid, String(row[0]), String(row[1]))
	_slider_row(grid, "Tremor da tela", "shake_intensity")
	_label(grid, "Números flutuantes")
	_float_btn = Button.new()
	_float_btn.pressed.connect(_toggle_float)
	grid.add_child(_float_btn)
	_update_float_text()

	box.add_child(_check("Reduzir movimento", "reduce_motion"))
	box.add_child(_check("Reduzir flashes", "reduce_flashes"))

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(buttons)
	var resume := Button.new()
	resume.theme_type_variation = &"BigButton"
	resume.text = "Continuar"
	resume.pressed.connect(close)
	buttons.add_child(resume)


func is_open() -> bool:
	return _is_open


func open() -> void:
	_is_open = true
	visible = true
	await get_tree().process_frame
	_panel.position = ((Vector2(640, 360) - _panel.size) * 0.5).floor()
	_panel.set_meta(&"panel_base", _panel.position)
	Juice.panel_open(_panel)


func close() -> void:
	if not _is_open:
		return
	_is_open = false
	Game.save_game()
	await Juice.panel_close(_panel).finished
	visible = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if _is_open and event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		close()


func _label(parent: Control, text: String) -> void:
	var l := Label.new()
	l.text = text
	parent.add_child(l)


func _slider_row(grid: GridContainer, text: String, key: String) -> void:
	_label(grid, text)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.custom_minimum_size = Vector2(120, 11)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.value = float(Game.settings.get(key, 1.0))
	s.value_changed.connect(func(v: float) -> void:
		Game.set_setting(key, v)
		Audio.play_tick())
	grid.add_child(s)


func _check(text: String, key: String) -> CheckBox:
	var c := CheckBox.new()
	c.text = text
	c.button_pressed = bool(Game.settings.get(key, false))
	c.toggled.connect(func(on: bool) -> void: Game.set_setting(key, on))
	return c


func _toggle_float() -> void:
	Game.set_setting("float_scale", 2 if int(Game.settings.get("float_scale", 1)) == 1 else 1)
	_update_float_text()


func _update_float_text() -> void:
	_float_btn.text = "Grande" if int(Game.settings.get("float_scale", 1)) == 2 else "Normal"


## Escurecimento em xadrez 01 (sem alfa: paleta fechada).
static func _checker() -> ImageTexture:
	var img := Image.create_empty(2, 2, false, Image.FORMAT_RGBA8)
	img.set_pixel(0, 0, Palette.color(Palette.OUTLINE))
	img.set_pixel(1, 1, Palette.color(Palette.OUTLINE))
	return ImageTexture.create_from_image(img)
