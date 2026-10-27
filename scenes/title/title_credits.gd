class_name TitleCredits
extends Control
## Créditos (UI/UX §9.4): pergaminho (panel_parchment) com rolos em cima e embaixo
## (scroll_ends) rolando devagar o CREDITS.md e o AUDIO_CREDITS.md. Fecha com Esc/B/clique.

signal closed()

const PANEL_RECT := Rect2(176, 44, 288, 268)
const SCROLL_SPEED := 14.0
const START_PAUSE := 1.0
const TEXT_WIDTH := 256.0

var _panel: PanelContainer
var _clip: Control
var _content: VBoxContainer
var _ends: Array[NinePatchRect] = []
var _open: bool = false
var _scroll_y: float = 0.0
var _pause: float = 0.0


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
	_panel.theme_type_variation = &"ParchmentPanel"
	_panel.position = PANEL_RECT.position
	_panel.size = PANEL_RECT.size
	_panel.custom_minimum_size = PANEL_RECT.size
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)
	_clip = Control.new()
	_clip.clip_contents = true
	_clip.custom_minimum_size = PANEL_RECT.size - Vector2(16, 16)
	_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_clip)
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 0)
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clip.add_child(_content)
	for line: Dictionary in CreditsText.load_lines():
		_content.add_child(_line(line))
	for top: bool in [true, false]:
		var e := _scroll_end(top)
		add_child(e)  # fora do PanelContainer (ele esticaria os rolos); acompanham a opacidade do painel
		_ends.append(e)


func _line(line: Dictionary) -> Control:
	if line.kind == CreditsText.GAP:
		var gap := Control.new()
		gap.custom_minimum_size = Vector2(TEXT_WIDTH, 8)
		gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return gap
	var l := Label.new()
	l.text = String(line.text)
	l.theme_type_variation = &"ParchmentTitle" if line.kind == CreditsText.TITLE else &"ParchmentLabel"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(TEXT_WIDTH, 0)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Rolo de madeira em cima/embaixo do pergaminho. MANIFEST scroll_ends: linha 0 (y 0–11) = topo,
## linha 1 (y 12–23) = base; 9-slice só na horizontal (8/8); em (px − 4, py − 6) e (px − 4, py + ph − 6).
func _scroll_end(top: bool) -> NinePatchRect:
	var n := NinePatchRect.new()
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sheet := TitleArt.sheet(TitleArt.SCROLL_ENDS)
	var tex := TitleArt.texture(TitleArt.SCROLL_ENDS)
	var h := float(TitleArt.SCROLL_END_SIZE.y)
	if sheet != null and sheet.frames.size() >= 2:
		n.texture = sheet.texture
		n.region_rect = sheet.frames[0 if top else 1]
	elif tex != null:
		var half := floorf(tex.get_height() * 0.5)
		n.texture = tex
		n.region_rect = Rect2(0, 0 if top else half, tex.get_width(), half)
	else:
		n.texture = TitleArt.generated("scroll_end", TitleArt.scroll_end_image)
		n.region_rect = Rect2(Vector2.ZERO, Vector2(TitleArt.SCROLL_END_SIZE))
	h = n.region_rect.size.y
	var margin := TitleArt.SCROLL_ART_MARGIN if tex != null else 4
	n.patch_margin_left = margin
	n.patch_margin_right = margin
	n.size = Vector2(PANEL_RECT.size.x + 8, h)
	n.set_meta(&"top", top)
	return n


func is_open() -> bool:
	return _open


func open() -> void:
	_open = true
	visible = true
	_scroll_y = 0.0
	_pause = START_PAUSE
	_content.position = Vector2(floorf((_clip.size.x - TEXT_WIDTH) * 0.5), 0)
	_panel.set_meta(&"panel_base", PANEL_RECT.position)
	Juice.panel_open(_panel)
	_place_ends()


func close() -> void:
	if not _open:
		return
	_open = false
	await Juice.panel_close(_panel).finished
	visible = false
	closed.emit()


func _place_ends() -> void:
	for e: NinePatchRect in _ends:
		var top := bool(e.get_meta(&"top"))
		var y := -6.0 if top else PANEL_RECT.size.y - 6.0
		e.position = PANEL_RECT.position + Vector2(-4, y)


func _process(delta: float) -> void:
	for e: NinePatchRect in _ends:
		e.modulate = _panel.modulate
	if not _open:
		return
	if _pause > 0.0:
		_pause -= delta
		return
	_scroll_y += SCROLL_SPEED * delta
	var h := _content.size.y
	if _scroll_y > h:
		_scroll_y = -_clip.size.y  # recomeça entrando por baixo
	_content.position.y = -roundf(_scroll_y)


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if _open and mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		close()


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"pause") or event.is_action_pressed(&"ui_accept"):
		get_viewport().set_input_as_handled()
		close()
