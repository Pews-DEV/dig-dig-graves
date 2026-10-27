class_name UiTheme
extends RefCounted
## Tema único da UI (UI/UX §2–3, DA §10). Fontes de Daniel Linssen em tamanho nativo,
## sem suavização: m5x7 (corpo, 16 = 1 px de fonte por pixel) e m6x11plus (títulos,
## números e botões, 18 = nativo; a m6x11 original não tem acentos PT-BR).

const FONT_BODY_PATH := "res://assets/ui/fonts/m5x7.ttf"
const FONT_TITLE_PATH := "res://assets/ui/fonts/m6x11plus.ttf"
## Painéis 9-slice 24×24, margem 8 (MANIFEST panel_wood / panel_parchment).
const PANEL_WOOD_PATH := "res://assets/ui/panels/panel_wood.png"
const PANEL_PARCHMENT_PATH := "res://assets/ui/panels/panel_parchment.png"
const PANEL_MARGIN := 8

## Tamanhos nativos (múltiplos são permitidos; frações não).
const SIZE_BODY := 16
const SIZE_SMALL := 16
const SIZE_TITLE := 18
const SIZE_FLOAT := 18
## Altura de linha útil (a m5x7 tem ascent sobrando; aperta para 10 px por linha).
const BODY_LINE_SPACING := -3
## Contorno 01 de 1 px (em Godot o outline_size é o diâmetro).
const OUTLINE := 2

static var _theme: Theme
static var _body_font: Font
static var _title_font: Font


static func body_font() -> Font:
	if _body_font == null:
		_body_font = _load_font(FONT_BODY_PATH)
	return _body_font


static func title_font() -> Font:
	if _title_font == null:
		_title_font = _load_font(FONT_TITLE_PATH)
	return _title_font


## Fonte pixel-perfect: sem AA, sem hinting, sem subpixel (UI/UX §2).
static func _load_font(path: String) -> Font:
	if ResourceLoader.exists(path):
		var f := load(path) as FontFile
		if f != null:
			f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
			f.hinting = TextServer.HINTING_NONE
			f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
			f.generate_mipmaps = false
			f.allow_system_fallback = false
			return f
	return ThemeDB.fallback_font


static func get_theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font = body_font()
	t.default_font_size = SIZE_BODY

	var text := Palette.color(Palette.BONE)
	var outline := Palette.color(Palette.OUTLINE)

	t.set_color("font_color", "Label", text)
	t.set_color("font_outline_color", "Label", outline)
	t.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0))
	t.set_constant("outline_size", "Label", 0)
	t.set_constant("line_spacing", "Label", BODY_LINE_SPACING)

	# Texto sobre o mundo: sempre com contorno 01 (UI/UX §2).
	t.add_type("HudLabel")
	t.set_type_variation("HudLabel", "Label")
	t.set_constant("outline_size", "HudLabel", OUTLINE)

	# Números do HUD em m6x11 com contorno.
	t.add_type("HudNumber")
	t.set_type_variation("HudNumber", "Label")
	t.set_font("font", "HudNumber", title_font())
	t.set_font_size("font_size", "HudNumber", SIZE_TITLE)
	t.set_constant("outline_size", "HudNumber", OUTLINE)
	t.set_constant("line_spacing", "HudNumber", 0)

	t.add_type("TitleLabel")
	t.set_type_variation("TitleLabel", "Label")
	t.set_font("font", "TitleLabel", title_font())
	t.set_font_size("font_size", "TitleLabel", SIZE_TITLE)
	t.set_constant("outline_size", "TitleLabel", OUTLINE)
	t.set_constant("line_spacing", "TitleLabel", 0)

	# Título sobre madeira/pergaminho (sem contorno).
	t.add_type("PanelTitle")
	t.set_type_variation("PanelTitle", "Label")
	t.set_font("font", "PanelTitle", title_font())
	t.set_font_size("font_size", "PanelTitle", SIZE_TITLE)
	t.set_constant("line_spacing", "PanelTitle", 0)

	# Botões: madeira de caixão em 4 estados (UI/UX §3), texto m6x11.
	for type: String in ["Button", "BigButton"]:
		if type != "Button":
			t.add_type(type)
			t.set_type_variation(type, "Button")
		var pad := 10 if type == "BigButton" else 6
		t.set_stylebox("normal", type, UiKit.button_style(&"normal", pad))
		t.set_stylebox("hover", type, UiKit.button_style(&"hover", pad))
		t.set_stylebox("hover_pressed", type, UiKit.button_style(&"pressed", pad))
		t.set_stylebox("pressed", type, UiKit.button_style(&"pressed", pad))
		t.set_stylebox("disabled", type, UiKit.button_style(&"disabled", pad))
		t.set_stylebox("focus", type, StyleBoxEmpty.new())
		t.set_font("font", type, title_font())
		t.set_font_size("font_size", type, SIZE_TITLE)
		t.set_color("font_color", type, text)
		t.set_color("font_hover_color", type, Palette.color(Palette.BONE_BRIGHT))
		t.set_color("font_pressed_color", type, text)
		t.set_color("font_hover_pressed_color", type, text)
		t.set_color("font_focus_color", type, text)
		t.set_color("font_disabled_color", type, Palette.color(Palette.MOONSHADOW))
		t.set_color("font_outline_color", type, outline)
		t.set_constant("outline_size", type, 0)
		t.set_constant("h_separation", type, 4)

	# Plaqueta de HUD (tábua 9-slice).
	t.add_type("Plaque")
	t.set_type_variation("Plaque", "PanelContainer")
	t.set_stylebox("panel", "Plaque", UiKit.plaque_style())

	var wood: StyleBox = _panel(PANEL_WOOD_PATH)
	if wood == null:
		wood = UiKit.flat_box(Palette.COFFIN, Palette.OUTLINE, 6, 4)
	t.set_stylebox("panel", "PanelContainer", wood)
	t.set_stylebox("panel", "Panel", wood)
	# Pergaminho para descrições (DA §10.1): texto 01.
	t.add_type("ParchmentPanel")
	t.set_type_variation("ParchmentPanel", "PanelContainer")
	var parchment: StyleBox = _panel(PANEL_PARCHMENT_PATH)
	if parchment == null:
		parchment = UiKit.flat_box(Palette.BONE, Palette.OUTLINE, 6, 4)
	t.set_stylebox("panel", "ParchmentPanel", parchment)
	t.add_type("ParchmentLabel")
	t.set_type_variation("ParchmentLabel", "Label")
	t.set_color("font_color", "ParchmentLabel", parchment_text())
	t.add_type("ParchmentTitle")
	t.set_type_variation("ParchmentTitle", "Label")
	t.set_font("font", "ParchmentTitle", title_font())
	t.set_font_size("font_size", "ParchmentTitle", SIZE_TITLE)
	t.set_constant("line_spacing", "ParchmentTitle", 0)
	t.set_color("font_color", "ParchmentTitle", parchment_text())

	# Tooltip: pergaminho pequeno (UI/UX §3).
	var tip: StyleBoxTexture = null
	var tip_art := AssetManifest.texture(UiKit.TOOLTIP_PATH)
	if tip_art != null:
		# MANIFEST tooltip: 9-slice 3/3/3/4.
		tip = StyleBoxTexture.new()
		tip.texture = tip_art
		tip.texture_margin_left = 3
		tip.texture_margin_right = 3
		tip.texture_margin_top = 3
		tip.texture_margin_bottom = 4
		tip.content_margin_left = 4
		tip.content_margin_right = 4
		tip.content_margin_top = 2
		tip.content_margin_bottom = 4
	else:
		tip = _panel(PANEL_PARCHMENT_PATH)
		if tip != null:
			tip.set_content_margin_all(4)
	t.set_stylebox("panel", "TooltipPanel", tip if tip != null else UiKit.flat_box(Palette.BONE, Palette.OUTLINE, 4, 2))
	t.set_color("font_color", "TooltipLabel", parchment_text())
	t.set_font("font", "TooltipLabel", body_font())
	t.set_font_size("font_size", "TooltipLabel", SIZE_BODY)

	# Opções: slider de madeira, caixa de seleção 01/26.
	var track := UiKit.flat_box(Palette.BG, Palette.OUTLINE, 0, 2)
	t.set_stylebox("slider", "HSlider", track)
	t.set_stylebox("grabber_area", "HSlider", UiKit.flat_box(Palette.LANTERN, Palette.OUTLINE, 0, 2))
	t.set_stylebox("grabber_area_highlight", "HSlider", UiKit.flat_box(Palette.LANTERN_BRIGHT, Palette.OUTLINE, 0, 2))
	t.set_icon("grabber", "HSlider", UiKit.slider_grabber(false))
	t.set_icon("grabber_highlight", "HSlider", UiKit.slider_grabber(true))
	t.set_icon("grabber_disabled", "HSlider", UiKit.slider_grabber(false))
	t.set_stylebox("focus", "HSlider", StyleBoxEmpty.new())
	for type: String in ["CheckBox", "CheckButton"]:
		t.set_icon("checked", type, UiKit.check_icon(true))
		t.set_icon("unchecked", type, UiKit.check_icon(false))
		t.set_icon("checked_disabled", type, UiKit.check_icon(true))
		t.set_icon("unchecked_disabled", type, UiKit.check_icon(false))
		for s: String in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
			t.set_stylebox(s, type, UiKit.flat_box(-1, -1, 1, 1))
		t.set_font("font", type, body_font())
		t.set_font_size("font_size", type, SIZE_BODY)
		t.set_color("font_color", type, text)
		t.set_color("font_hover_color", type, Palette.color(Palette.BONE_BRIGHT))
		t.set_color("font_pressed_color", type, text)
		t.set_color("font_hover_pressed_color", type, Palette.color(Palette.BONE_BRIGHT))
		t.set_color("font_focus_color", type, text)
		t.set_constant("h_separation", type, 4)
	t.set_stylebox("separator", "HSeparator", UiKit.flat_box(Palette.COFFIN_DARK, -1, 0, 0))
	t.set_constant("separation", "HSeparator", 3)
	_theme = t
	return t


static func has_parchment_art() -> bool:
	return AssetManifest.is_listed(PANEL_PARCHMENT_PATH) and ResourceLoader.exists(PANEL_PARCHMENT_PATH)


## Texto sobre pergaminho: 01 (UI/UX §2).
static func parchment_text() -> Color:
	return Palette.color(Palette.OUTLINE)


## Destaque sobre pergaminho (ex.: "antes"): 18 (UI/UX §2: 01/18 sobre pergaminho).
static func parchment_accent() -> Color:
	return Palette.color(Palette.COFFIN_DARK)


static func _panel(path: String) -> StyleBoxTexture:
	var tex := AssetManifest.texture(path)
	if tex == null:
		return null
	var s := StyleBoxTexture.new()
	s.texture = tex
	s.set_texture_margin_all(PANEL_MARGIN)
	s.set_content_margin_all(PANEL_MARGIN - 2)
	return s


## Desenha texto com contorno 01 num CanvasItem (sobre o mundo).
static func draw_outlined(ci: CanvasItem, font: Font, pos: Vector2, text: String, size: int, color: Color) -> void:
	ci.draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, OUTLINE, Palette.color(Palette.OUTLINE))
	ci.draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
