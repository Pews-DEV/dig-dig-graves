class_name UiKit
extends RefCounted
## Peças do kit de UI (UI/UX §3). Usa a arte do MANIFEST quando registrada; senão gera
## placeholders pixel a pixel com a paleta (botão em 4 estados, plaqueta, medalha, slider…).
## Tudo em cache: cada textura é gerada uma vez.

## Caminhos esperados do kit (MANIFEST). Ausentes = placeholder por código.
const BUTTON_PATH := "res://assets/ui/kit/btn_grande.png"
const BUTTON_SMALL_PATH := "res://assets/ui/kit/btn_pequeno.png"
const PLAQUE_PATH := "res://assets/ui/kit/plaqueta.png"
const TOOLTIP_PATH := "res://assets/ui/kit/tooltip.png"
const MEDAL_PATH := "res://assets/ui/kit/medalha_nivel.png"
const LANTERN_PATH := "res://assets/ui/kit/lanterna.png"
const SKULL_PATH := "res://assets/ui/kit/icone_inquietacao.png"
## MANIFEST btn_grande: célula 48×24, coluna = estado; 9-slice esq. 6, dir. 6, topo 6, base 8;
## texto de x = 6 até largura − 7 e de y = 3 até altura − 7 (+1 px no pressionado).
const BTN_ART_CELL := Vector2(48, 24)
const BTN_ART_MARGIN := Vector4i(6, 6, 6, 8)
const BTN_STATE_COL: Dictionary = {&"normal": 0, &"hover": 1, &"pressed": 2, &"disabled": 3}
## MANIFEST plaqueta: 9-slice esq. 8, dir. 8, topo 12, base 11; altura padrão 24.
const PLAQUE_ART_MARGIN := Vector4i(8, 12, 8, 11)

static var _cache: Dictionary = {}


static func _img(w: int, h: int) -> Image:
	return Image.create_empty(w, h, false, Image.FORMAT_RGBA8)


static func _rect(img: Image, x: int, y: int, w: int, h: int, idx: int) -> void:
	img.fill_rect(Rect2i(x, y, w, h), Palette.color(idx))


static func _px(img: Image, x: int, y: int, idx: int) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, Palette.color(idx))


static func _tex(key: String, maker: Callable) -> ImageTexture:
	if not _cache.has(key):
		_cache[key] = ImageTexture.create_from_image(maker.call() as Image)
	return _cache[key] as ImageTexture


## Desenha "ASCII art" numa Image: cada caractere da legenda vira um índice da paleta.
static func ascii(rows: Array, legend: Dictionary) -> Image:
	var w := 0
	for r: String in rows:
		w = maxi(w, r.length())
	var img := _img(w, rows.size())
	for y: int in rows.size():
		var row: String = rows[y]
		for x: int in row.length():
			if legend.has(row[x]):
				_px(img, x, y, int(legend[row[x]]))
	return img


# --- Botão (madeira de caixão, UI/UX §3) -------------------------------------------------
## Textura 12×14: caixa de 12 linhas + sombra. Normal: caixa em y 1–12, sombra 13.
## Hover: sobe 1 px (y 0–11) e a sombra cresce. Pressionado: desce 1 px (y 2–13), sem sombra.

const BUTTON_SIZE := Vector2i(12, 14)
const BUTTON_MARGIN := Vector4i(4, 5, 4, 5)  # esquerda, topo, direita, base (9-slice)


static func button_texture(state: StringName) -> ImageTexture:
	return _tex("btn_" + state, func() -> Image: return _button_image(state))


static func _button_image(state: StringName) -> Image:
	var img := _img(BUTTON_SIZE.x, BUTTON_SIZE.y)
	var top := 1
	var fill := Palette.COFFIN
	var light := Palette.COFFIN_LIGHT
	var dark := Palette.COFFIN_DARK
	var border := Palette.OUTLINE
	var shadow := 1
	match state:
		&"hover":
			top = 0
			fill = Palette.COFFIN_LIGHT
			light = Palette.BONE_SHADOW
			dark = Palette.COFFIN
			border = Palette.LANTERN_BRIGHT
			shadow = 2
		&"pressed":
			top = 2
			fill = Palette.COFFIN
			light = Palette.COFFIN_DARK
			dark = Palette.COFFIN_LIGHT
			shadow = 0
		&"disabled":
			fill = Palette.MOONSHADOW
			light = Palette.STONE_DARK
			dark = Palette.NIGHT_VIOLET
	var w := BUTTON_SIZE.x
	var bottom := top + 11
	# Contorno com cantos arredondados (1 px).
	_rect(img, 1, top, w - 2, 1, border)
	_rect(img, 1, bottom, w - 2, 1, border)
	_rect(img, 0, top + 1, 1, 10, border)
	_rect(img, w - 1, top + 1, 1, 10, border)
	_rect(img, 1, top + 1, w - 2, 10, fill)
	_rect(img, 1, top + 1, w - 2, 1, light)
	_rect(img, 1, top + 1, 1, 10, light)
	_rect(img, 1, bottom - 1, w - 2, 1, dark)
	if state != &"disabled":
		for p: Vector2i in [Vector2i(2, top + 2), Vector2i(w - 3, top + 2), Vector2i(2, bottom - 2), Vector2i(w - 3, bottom - 2)]:
			_px(img, p.x, p.y, Palette.LANTERN_BRIGHT)
	for i: int in shadow:
		_rect(img, 1, bottom + 1 + i, w - 2, 1, Palette.OUTLINE)
	return img


static func button_style(state: StringName, pad_h: int = 8) -> StyleBoxTexture:
	var art := AssetManifest.texture(BUTTON_PATH)
	if art != null:
		var a := StyleBoxTexture.new()
		a.texture = art
		a.region_rect = Rect2(Vector2(int(BTN_STATE_COL.get(state, 0)) * BTN_ART_CELL.x, 0), BTN_ART_CELL)
		a.texture_margin_left = BTN_ART_MARGIN.x
		a.texture_margin_right = BTN_ART_MARGIN.y
		a.texture_margin_top = BTN_ART_MARGIN.z
		a.texture_margin_bottom = BTN_ART_MARGIN.w
		var down := 1 if state == &"pressed" else 0
		a.content_margin_left = 6 + pad_h - 4
		a.content_margin_right = 7 + pad_h - 4
		a.content_margin_top = 1 + down
		a.content_margin_bottom = 5 - down
		return a
	var s := StyleBoxTexture.new()
	s.texture = button_texture(state)
	s.texture_margin_left = BUTTON_MARGIN.x
	s.texture_margin_top = BUTTON_MARGIN.y
	s.texture_margin_right = BUTTON_MARGIN.z
	s.texture_margin_bottom = BUTTON_MARGIN.w
	s.content_margin_left = pad_h
	s.content_margin_right = pad_h
	# Texto acompanha a caixa: hover sobe 1 px, pressionado desce 1 px.
	var dy := -1 if state == &"hover" else (1 if state == &"pressed" else 0)
	s.content_margin_top = 1 + dy
	s.content_margin_bottom = 3 - dy
	return s


# --- Plaqueta de HUD (tábua 9-slice, 1 prego por ponta) --------------------------------

const PLAQUE_MARGIN := 6


static func plaque_texture() -> Texture2D:
	var art := AssetManifest.texture(PLAQUE_PATH)
	if art != null:
		return art
	return _tex("plaque", _plaque_image)


static func _plaque_image() -> Image:
	var img := _img(16, 16)
	_rect(img, 1, 0, 14, 1, Palette.OUTLINE)
	_rect(img, 1, 15, 14, 1, Palette.OUTLINE)
	_rect(img, 0, 1, 1, 14, Palette.OUTLINE)
	_rect(img, 15, 1, 1, 14, Palette.OUTLINE)
	_rect(img, 1, 1, 14, 14, Palette.COFFIN)
	_rect(img, 1, 1, 14, 1, Palette.COFFIN_LIGHT)
	_rect(img, 1, 14, 14, 1, Palette.COFFIN_DARK)
	_rect(img, 1, 1, 1, 13, Palette.COFFIN_LIGHT)
	# Veio da madeira no miolo (estica sem criar padrão).
	_rect(img, 6, 7, 4, 1, Palette.COFFIN_DARK)
	_px(img, 3, 3, Palette.LANTERN_BRIGHT)
	_px(img, 12, 3, Palette.LANTERN_BRIGHT)
	_px(img, 3, 4, Palette.LANTERN_DARK)
	_px(img, 12, 4, Palette.LANTERN_DARK)
	return img


## Margens 9-slice da plaqueta (esq., topo, dir., base).
static func plaque_margins() -> Vector4i:
	if AssetManifest.texture(PLAQUE_PATH) != null:
		return PLAQUE_ART_MARGIN
	return Vector4i(PLAQUE_MARGIN, PLAQUE_MARGIN, PLAQUE_MARGIN, PLAQUE_MARGIN)


static func plaque_style(pad_h: int = 5, pad_v: int = 3) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = plaque_texture()
	var m := plaque_margins()
	s.texture_margin_left = m.x
	s.texture_margin_top = m.y
	s.texture_margin_right = m.z
	s.texture_margin_bottom = m.w
	s.content_margin_left = pad_h
	s.content_margin_right = pad_h
	s.content_margin_top = pad_v
	s.content_margin_bottom = pad_v
	return s


# --- Medalha de nível (disco 24×24 de cobre) --------------------------------------------

static func medal_texture() -> ImageTexture:
	return _tex("medal", _medal_image)


static func _medal_image() -> Image:
	var img := _img(24, 24)
	var c := Vector2(11.5, 11.5)
	for y: int in 24:
		for x: int in 24:
			var d := Vector2(x, y).distance_to(c)
			if d > 11.6:
				continue
			var idx := Palette.LANTERN
			if d > 10.6:
				idx = Palette.OUTLINE
			elif d > 9.0:
				# Aro: claro em cima à esquerda (luz NO), escuro embaixo à direita.
				idx = Palette.LANTERN_BRIGHT if (x + y) < 21 else Palette.LANTERN_DARK
			elif d > 8.0:
				idx = Palette.LANTERN_DARK
			_px(img, x, y, idx)
	return img


## Faixa de brilho que varre a medalha ao subir de nível (pixels 23 numa diagonal).
static func medal_shine_texture() -> ImageTexture:
	return _tex("medal_shine", func() -> Image:
		var img := _img(24, 24)
		var c := Vector2(11.5, 11.5)
		for y: int in 24:
			for x: int in 24:
				if Vector2(x, y).distance_to(c) <= 10.0 and absi((x - y)) <= 1:
					_px(img, x, y, Palette.BONE_BRIGHT)
		return img)


# --- Ícones pequenos -----------------------------------------------------------------

## Triângulo "▶" (a fonte não tem o glifo) em 22 com contorno 01.
static func play_icon() -> ImageTexture:
	return _tex("play", func() -> Image:
		return ascii([
			"oo....",
			"owo...",
			"owwo..",
			"owwwo.",
			"owwo..",
			"owo...",
			"oo....",
		], {"o": Palette.OUTLINE, "w": Palette.BONE}))


## Caveirinha 16×16 da Inquietação (placeholder até o kit).
static func skull_image() -> Image:
	return ascii([
		"................",
		"....oooooooo....",
		"...owwwwwwwwo...",
		"..owwhhwwwwwso..",
		"..owhwwwwwwwso..",
		"..owwwwwwwwwso..",
		"..owoowwwoowso..",
		"..oo..owo..oso..",
		"..oo..owo..oso..",
		"...owwwowwwso...",
		"....owwwwwso....",
		"....owowowso....",
		"....oooooooo....",
		"................",
	], {"o": Palette.OUTLINE, "w": Palette.BONE, "h": Palette.BONE_BRIGHT, "s": Palette.BONE_SHADOW})


static func skull_texture() -> Texture2D:
	var art := AssetManifest.texture(SKULL_PATH)
	if art != null:
		return art
	return _tex("skull", skull_image)


# --- Controles de opções -----------------------------------------------------------------

static func slider_grabber(highlight: bool) -> ImageTexture:
	return _tex("grab%d" % int(highlight), func() -> Image:
		var b := "c" if highlight else "o"
		return ascii([
			"." + b + b + b + b + b + ".",
			b + "lllll" + b,
			b + "lwwwd" + b,
			b + "lwwwd" + b,
			b + "lwwwd" + b,
			b + "lwwwd" + b,
			b + "lwwwd" + b,
			b + "ddddd" + b,
			"." + b + b + b + b + b + ".",
		], {"o": Palette.OUTLINE, "c": Palette.LANTERN_BRIGHT, "l": Palette.COFFIN_LIGHT, "w": Palette.COFFIN, "d": Palette.COFFIN_DARK}))


static func check_icon(checked: bool) -> ImageTexture:
	return _tex("check%d" % int(checked), func() -> Image:
		if checked:
			return ascii([
				".ooooooooo.",
				"onnnnnnnnco",
				"onnnnnnncco",
				"onnnnnnccno",
				"onccnnccnno",
				"onnccccnnno",
				"onnnccnnnno",
				"onnnnnnnnno",
				".ooooooooo.",
			], {"o": Palette.OUTLINE, "n": Palette.BG, "c": Palette.LANTERN_BRIGHT})
		return ascii([
			".ooooooooo.",
			"onnnnnnnnno",
			"onnnnnnnnno",
			"onnnnnnnnno",
			"onnnnnnnnno",
			"onnnnnnnnno",
			"onnnnnnnnno",
			"onnnnnnnnno",
			".ooooooooo.",
		], {"o": Palette.OUTLINE, "n": Palette.BG}))


static func flat_box(bg: int, border: int, margin_h: int = 4, margin_v: int = 2) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	if bg > 0:
		s.bg_color = Palette.color(bg)
	else:
		s.draw_center = false
	if border > 0:
		s.border_color = Palette.color(border)
		s.set_border_width_all(1)
	s.anti_aliasing = false
	s.content_margin_left = margin_h
	s.content_margin_right = margin_h
	s.content_margin_top = margin_v
	s.content_margin_bottom = margin_v
	return s
