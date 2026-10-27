class_name TitleArt
extends RefCounted
## Arte da tela-título (UI/UX §9.6). Cada peça é buscada pelo **id** no assets/MANIFEST.md
## (o caminho vem da própria linha do manifesto); sem registro, gera um placeholder liso com
## as cores da paleta (protótipo cinza, DA §12). Tudo em cache por sessão.

## ids do contrato §9.6.
const SKY := "title_sky"
const VILLAGE := "title_village"
const WINDOWS := "title_windows"
const WALL := "title_wall"
const FG := "title_fg"
const FG_CANOPY := "title_fg_canopy"
const LOGO := "title_logo"
const LOGO_SHOVEL := "title_logo_shovel"
const LOGO_DRIP := "title_logo_drip"
const PANEL_STONE := "panel_stone"
const BTN_DANGER := "btn_perigo"
const SCROLL_ENDS := "scroll_ends"
const COVEIRO := "coveiro_title"
const SHOVEL_STUCK := "pa_cravada"
const LANTERN := "lanterna_chao"
const LANTERN_HALO := "lanterna_chao_halo"
const TIAO := "tiao"
const SOUL := "alma_fila"
## Reaproveitados (caminhos já conhecidos do manifesto).
const STARS_PATH := "res://assets/sprites/bg/a1/bg_a1_stars.png"
const CLOUDS_PATH := "res://assets/sprites/bg/a1/bg_a1_clouds.png"
const FOG_PATH := "res://assets/sprites/bg/a1/nevoa_a1.png"
const VIGNETTE_PATH := "res://assets/sprites/bg/a1/vinheta.png"
const WISP_PATH := "res://assets/sprites/fx/fogo_fatuo.png"
const PETALS_PATH := "res://assets/ui/tree/fx_petals.png"
const FIREFLY_PATH := "res://assets/ui/tree/fx_firefly.png"
const DUST_PATH := "res://assets/sprites/fx/dust.png"
const CLODS_PATH := "res://assets/sprites/fx/torroes.png"

## Placeholder da pá do logo: 13×30, ponta da lâmina em (4, 29).
const SHOVEL_SIZE := Vector2i(13, 30)
## Painel de pedra 9-slice (esq., topo, dir., base): placeholder e arte (MANIFEST panel_stone 14/16/14/10).
const STONE_MARGIN := Vector4i(8, 12, 8, 8)
const STONE_ART_MARGIN := Vector4i(14, 16, 14, 10)
## Placeholder dos rolos do pergaminho; a arte (scroll_ends) tem faixas de 32×12, 9-slice 8/8.
const SCROLL_END_SIZE := Vector2i(24, 8)
const SCROLL_ART_MARGIN := 8

static var _tex: Dictionary = {}
static var _sheets: Dictionary = {}


## Textura registrada no manifesto pelo id, ou null.
static func texture(id: String) -> Texture2D:
	var key := "id:" + id
	if not _tex.has(key):
		_tex[key] = AssetManifest.texture_by_id(id)
	return _tex[key] as Texture2D


## Textura por caminho (assets reaproveitados), ou null.
static func texture_path(path: String) -> Texture2D:
	var key := "path:" + path
	if not _tex.has(key):
		_tex[key] = AssetManifest.texture(path)
	return _tex[key] as Texture2D


## Folha animada (PNG + JSON do Aseprite) pelo id, ou null.
static func sheet(id: String) -> AsepriteSheet:
	if not _sheets.has(id):
		_sheets[id] = AsepriteSheet.load_id(id)
	return _sheets[id] as AsepriteSheet


static func sheet_path(path: String) -> AsepriteSheet:
	if not _sheets.has(path):
		_sheets[path] = AsepriteSheet.load_sheet(path)
	return _sheets[path] as AsepriteSheet


## Esquece o cache (o manifesto é relido na próxima busca).
static func clear_cache() -> void:
	_tex.clear()
	_sheets.clear()
	_gen.clear()
	AssetManifest.reload()


# --- Placeholders (só cores da paleta) ------------------------------------------------

static var _gen: Dictionary = {}


static func generated(key: String, maker: Callable) -> ImageTexture:
	if not _gen.has(key):
		_gen[key] = ImageTexture.create_from_image(maker.call() as Image)
	return _gen[key] as ImageTexture


static func _img(w: int, h: int) -> Image:
	return Image.create_empty(w, h, false, Image.FORMAT_RGBA8)


static func _px(img: Image, x: int, y: int, idx: int) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, Palette.color(idx))


static func _rect(img: Image, x: int, y: int, w: int, h: int, idx: int) -> void:
	var r := Rect2i(x, y, w, h).intersection(Rect2i(0, 0, img.get_width(), img.get_height()))
	if r.size.x > 0 and r.size.y > 0:
		img.fill_rect(r, Palette.color(idx))


static func _checker_row(img: Image, y: int, x0: int, x1: int, idx: int, phase: int = 0) -> void:
	for x: int in range(x0, x1):
		if (x + y + phase) % 2 == 0:
			_px(img, x, y, idx)


## Céu 640×600 (o enquadramento final mostra y = 240–600): 02 → 03 → 04 em xadrez, lua cheia.
static func sky_image(moon: Vector2, radius: int) -> Image:
	var img := _img(640, 600)
	var bands: Array[Vector2i] = [Vector2i(0, Palette.BG), Vector2i(330, Palette.NIGHT), Vector2i(420, Palette.NIGHT_VIOLET)]
	for i: int in bands.size():
		var y0 := bands[i].x
		var y1 := 600 if i == bands.size() - 1 else bands[i + 1].x
		_rect(img, 0, y0, 640, y1 - y0, bands[i].y)
		if i > 0:
			for y: int in range(y0 - 6, y0 + 6):
				_checker_row(img, y, 0, 640, bands[i].y if y < y0 else bands[i - 1].y)
	# Lua no enquadramento final (o céu é desenhado em y = −240).
	var c := Vector2(moon.x, moon.y + 240.0)
	var r := float(radius)
	for y: int in range(int(c.y - r - 14), int(c.y + r + 14)):
		for x: int in range(int(c.x - r - 14), int(c.x + r + 14)):
			var d := Vector2(x, y).distance_to(c)
			if d <= r:
				var idx := Palette.STONE_LIGHT
				if Vector2(x - c.x, y - c.y).dot(Vector2(1, 1).normalized()) > r * 0.5:
					idx = Palette.STONE
				if d > r - 1.0:
					idx = Palette.STONE if x + y < c.x + c.y else Palette.STONE_DARK
				_px(img, x, y, idx)
			elif d <= r + 5.0 and (x + y) % 2 == 0:
				_px(img, x, y, Palette.MOONSHADOW)
			elif d <= r + 12.0 and x % 2 == 0 and y % 2 == 0:
				_px(img, x, y, Palette.NIGHT_VIOLET)
	for m: Vector3 in [Vector3(-8, -6, 6), Vector3(7, 3, 5), Vector3(-2, 10, 4)]:
		for y: int in range(int(-m.z), int(m.z)):
			for x: int in range(int(-m.z), int(m.z)):
				if Vector2(x, y).length() < m.z:
					_px(img, int(c.x + m.x) + x, int(c.y + m.y) + y, Palette.STONE)
	# Estrelas fixas.
	var rng := RandomNumberGenerator.new()
	rng.seed = 91
	for i: int in 160:
		var p := Vector2i(rng.randi_range(2, 637), rng.randi_range(2, 470))
		if Vector2(p).distance_to(c) < r + 16.0:
			continue
		_px(img, p.x, p.y, Palette.MOONSHADOW if rng.randf() < 0.7 else Palette.STONE_DARK)
	return img


## Vila na colina (640×(360 − horizonte + 30)), desenhada a partir de y = horizonte − 30.
static func village_image(horizon: int) -> Image:
	var top := horizon - 30
	var img := _img(640, 360 - top)
	for x: int in 640:
		var hill := horizon + int(roundf(6.0 * sin(x * 0.012) + 4.0 * sin(x * 0.031 + 1.3))) - top
		_rect(img, x, hill, 1, img.get_height() - hill, Palette.NIGHT)
		if (x % 2) == 0:
			_px(img, x, hill, Palette.NIGHT_VIOLET)
	# Casinhas (03/04) e a torre da igreja.
	for h: Vector4i in [Vector4i(116, 12, 18, 11), Vector4i(136, 8, 14, 9), Vector4i(156, 14, 16, 12), Vector4i(178, 6, 16, 14),
			Vector4i(194, 16, 14, 10), Vector4i(210, 10, 12, 11), Vector4i(446, 12, 18, 10), Vector4i(470, 6, 14, 12), Vector4i(494, 14, 16, 9),
			Vector4i(322, 18, 16, 8)]:
		var base := horizon - top + h.y
		_rect(img, h.x, base - h.w, h.z, h.w, Palette.NIGHT)
		for k: int in range(0, (h.z >> 1) + 1):
			_rect(img, h.x + k, base - h.w - k, h.z - 2 * k, 1, Palette.NIGHT_VIOLET)
	var tower := Vector2i(258, horizon - top - 2)
	_rect(img, tower.x, tower.y - 34, 10, 34, Palette.NIGHT)
	_rect(img, tower.x + 2, tower.y - 46, 6, 12, Palette.NIGHT_VIOLET)
	_rect(img, tower.x + 4, tower.y - 54, 2, 8, Palette.NIGHT_VIOLET)
	_rect(img, tower.x + 2, tower.y - 51, 6, 2, Palette.NIGHT_VIOLET)
	return img


## Muro caiado com portão de ferro, cruzes e lápides (640×(360 − base + 40)).
static func wall_image(base: int, gate: Vector2) -> Image:
	var top := base - 40
	var img := _img(640, 360 - top)
	var wall_top := 12
	var wall_bottom := base - top
	_rect(img, 0, wall_top, 640, wall_bottom - wall_top, Palette.NIGHT_VIOLET)
	_rect(img, 0, wall_top, 640, 2, Palette.MOONSHADOW)
	_rect(img, 0, wall_bottom - 2, 640, 2, Palette.NIGHT)
	for x: int in range(8, 640, 40):
		_rect(img, x, wall_top - 4, 8, wall_bottom - wall_top + 4, Palette.MOONSHADOW)
		_rect(img, x + 6, wall_top - 2, 2, wall_bottom - wall_top + 2, Palette.NIGHT_VIOLET)
	# Vão do portão (transparente entre as barras: as almas passam por ele).
	var gx0 := int(gate.x)
	var gx1 := int(gate.y)
	img.fill_rect(Rect2i(gx0, 0, gx1 - gx0, wall_bottom), Color(0, 0, 0, 0))
	_rect(img, gx0 - 6, wall_top - 14, 6, wall_bottom - wall_top + 14, Palette.MOONSHADOW)
	_rect(img, gx1, wall_top - 14, 6, wall_bottom - wall_top + 14, Palette.MOONSHADOW)
	for x: int in range(gx0 + 3, gx1, 5):
		_rect(img, x, wall_top - 2, 1, wall_bottom - wall_top + 2, Palette.OUTLINE)
	for x: int in range(gx0, gx1):
		var arc := int(roundf(6.0 * sin(PI * float(x - gx0) / float(gx1 - gx0))))
		_px(img, x, wall_top - 2 - arc, Palette.OUTLINE)
		_px(img, x, wall_top + 6, Palette.OUTLINE)
	# Chão e lápides entre o muro e o primeiro plano.
	_rect(img, 0, wall_bottom, 640, img.get_height() - wall_bottom, Palette.BG)
	for x: int in range(0, 640, 2):
		_px(img, x, wall_bottom, Palette.NIGHT)
	for s: Vector3i in [Vector3i(210, 10, 0), Vector3i(330, 12, 1), Vector3i(372, 8, 0), Vector3i(430, 11, 1), Vector3i(196, 7, 1), Vector3i(512, 9, 0)]:
		var y := wall_bottom + 10
		if s.z == 0:
			_rect(img, s.x, y - s.y, 8, s.y, Palette.NIGHT_VIOLET)
			_rect(img, s.x + 1, y - s.y - 1, 6, 1, Palette.NIGHT_VIOLET)
			_rect(img, s.x + 1, y - s.y + 1, 2, s.y - 2, Palette.MOONSHADOW)
		else:
			_rect(img, s.x + 3, y - s.y, 2, s.y, Palette.NIGHT_VIOLET)
			_rect(img, s.x, y - s.y + 3, 8, 2, Palette.NIGHT_VIOLET)
	return img


## Primeiro plano 640×360: chão, monte de terra (sem pá), lápide do Tião e o ipê-roxo.
static func fg_image(layout: TitleLayoutData) -> Image:
	var img := _img(640, 360)
	var g := layout.ground_y
	_rect(img, 0, g, 640, 360 - g, Palette.OUTLINE)
	_rect(img, 0, g - 2, 640, 3, Palette.GRASS_DEEP)
	for x: int in range(0, 640, 3):
		_px(img, x, g - 3 - (x * 7) % 3, Palette.GRASS_DARK)
	_checker_row(img, g + 1, 0, 640, Palette.GRASS_DEEP)
	# Monte de terra recém-cavada (luz NO: lado esquerdo mais claro).
	var m := layout.mound_rect
	var cx := m.position.x + m.size.x * 0.5
	for x: int in range(int(m.position.x), int(m.end.x)):
		var u := (float(x) - cx) / (m.size.x * 0.5)
		var h := int(roundf(m.size.y * (1.0 - u * u)))
		# MANIFEST: topo plano logo abaixo do pivô do Coveiro (ele, a pá e a lanterna se apoiam ali).
		h = mini(h, g - int(layout.coveiro_seat.y) - 1)
		if h <= 0:
			continue
		var top := g - h
		_rect(img, x, top, 1, h, Palette.DIRT)
		_rect(img, x, top, 1, 2, Palette.DIRT_LIGHT if u < 0.2 else Palette.DIRT)
		if u > 0.35:
			_rect(img, x, top + 2, 1, h - 2, Palette.DIRT_DARK)
		_px(img, x, top - 1, Palette.OUTLINE)
		if (x * 13) % 7 == 0:
			_px(img, x, top + 4 + (x % 5), Palette.DIRT_EDGE)
	# Lápide do Tião (06/07/08, contorno 01, topo arredondado).
	var s := layout.tiao_stone
	var sx := int(s.position.x)
	var sy := int(s.position.y)
	var sw := int(s.size.x)
	var sh := int(s.size.y)
	_rect(img, sx, sy + 3, sw, sh - 3, Palette.OUTLINE)
	_rect(img, sx + 2, sy, sw - 4, 3, Palette.OUTLINE)
	_rect(img, sx + 1, sy + 1, sw - 2, sh - 1, Palette.STONE)
	_rect(img, sx + 3, sy + 1, sw - 6, 1, Palette.STONE_LIGHT)
	_rect(img, sx + 1, sy + 2, 2, sh - 3, Palette.STONE_LIGHT)
	_rect(img, sx + sw - 3, sy + 2, 2, sh - 3, Palette.STONE_DARK)
	_rect(img, sx + (sw >> 1) - 1, sy + 7, 2, 9, Palette.STONE_DARK)
	_rect(img, sx + (sw >> 1) - 4, sy + 10, 8, 2, Palette.STONE_DARK)
	# Ipê-roxo: tronco 18/19 e copa 04/05/08, saindo pela borda direita.
	var c := layout.ipe_canopy
	var tx := int(c.position.x + c.size.x * 0.5)
	_rect(img, tx - 6, int(c.end.y) - 30, 13, g - int(c.end.y) + 30, Palette.COFFIN_DARK)
	_rect(img, tx - 6, int(c.end.y) - 30, 3, g - int(c.end.y) + 30, Palette.COFFIN)
	_rect(img, tx - 22, int(c.end.y) - 20, 16, 3, Palette.COFFIN_DARK)
	_rect(img, tx + 6, int(c.end.y) - 34, 22, 3, Palette.COFFIN_DARK)
	var rng := RandomNumberGenerator.new()
	rng.seed = 47
	for i: int in 9:
		var center := Vector2(rng.randf_range(c.position.x + 10, c.end.x + 10), rng.randf_range(c.position.y + 16, c.end.y - 26))
		var rad := rng.randf_range(16, 28)
		for y: int in range(int(center.y - rad), int(center.y + rad)):
			for x: int in range(int(center.x - rad * 1.3), int(center.x + rad * 1.3)):
				var d := Vector2((x - center.x) / 1.3, y - center.y).length()
				if d > rad or (d > rad - 2.0 and (x + y) % 2 == 1):
					continue
				var idx := Palette.NIGHT_VIOLET
				if y < center.y - rad * 0.3 and (x * 5 + y * 3) % 4 == 0:
					idx = Palette.MOONSHADOW
				if x < center.x - rad * 0.4 and y < center.y and (x + y * 2) % 7 == 0:
					idx = Palette.STONE_LIGHT
				_px(img, x, y, idx)
	return img


# --- Logo placeholder: letras de pedra com terra escorrendo (UI/UX §9.2) -----------------

const GLYPHS: Dictionary = {
	"D": ["####.", "#...#", "#...#", "#...#", "#...#", "#...#", "####."],
	"I": [".###.", "..#..", "..#..", "..#..", "..#..", "..#..", ".###."],
	"G": [".###.", "#...#", "#....", "#.###", "#...#", "#...#", ".###."],
	"R": ["####.", "#...#", "#...#", "####.", "#.#..", "#..#.", "#...#"],
	"A": [".###.", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
	"V": ["#...#", "#...#", "#...#", "#...#", "#...#", ".#.#.", "..#.."],
	"E": ["#####", "#....", "#....", "####.", "#....", "#....", "#####"],
	"S": [".####", "#....", "#....", ".###.", "....#", "....#", "####."],
}


static func letter_image(ch: String, scale: int, seed_value: int) -> Image:
	var rows: Array = GLYPHS.get(ch, GLYPHS["D"])
	var size := Vector2i(TitleLayoutData.GLYPH.x * scale + 3, TitleLayoutData.GLYPH.y * scale + 4)
	var img := _img(size.x, size.y)
	var solid := func(gx: int, gy: int) -> bool:
		if gy < 0 or gy >= rows.size() or gx < 0 or gx >= 5:
			return false
		return String(rows[gy])[gx] == "#"
	# Máscara em pixels (glifo em (1, 1)).
	var mask: Dictionary = {}
	for gy: int in 7:
		for gx: int in 5:
			if solid.call(gx, gy):
				for y: int in scale:
					for x: int in scale:
						mask[Vector2i(1 + gx * scale + x, 1 + gy * scale + y)] = true
	# Sombra (05/06) deslocada (1, 2), contorno 01, face 07 com luz 08 e sombra 06.
	for p: Vector2i in mask:
		for d: Vector2i in [Vector2i(1, 1), Vector2i(1, 2)]:
			if not mask.has(p + d):
				_px(img, p.x + d.x, p.y + d.y, Palette.MOONSHADOW if d.y == 2 else Palette.STONE_DARK)
	for p: Vector2i in mask:
		for d: Vector2i in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
			if not mask.has(p + d):
				_px(img, p.x + d.x, p.y + d.y, Palette.OUTLINE)
	for p: Vector2i in mask:
		var idx := Palette.STONE
		if not mask.has(p + Vector2i(0, -1)) or not mask.has(p + Vector2i(-1, 0)):
			idx = Palette.STONE_LIGHT
		elif not mask.has(p + Vector2i(0, 1)) or not mask.has(p + Vector2i(1, 0)):
			idx = Palette.STONE_DARK
		_px(img, p.x, p.y, idx)
	# Terra (15/16) por cima das partes de cima, escorrendo em alguns pontos.
	for p: Vector2i in mask:
		if mask.has(p + Vector2i(0, -1)):
			continue
		_px(img, p.x, p.y, Palette.DIRT_LIGHT)
		_px(img, p.x, p.y + 1, Palette.DIRT)
		if (p.x * 7 + seed_value * 3) % 9 == 0:
			for k: int in range(2, 2 + (p.x + seed_value) % 4 + 1):
				if mask.has(p + Vector2i(0, k)):
					_px(img, p.x, p.y + k, Palette.DIRT)
	return img


static func letter_texture(i: int) -> ImageTexture:
	var ch := TitleLayoutData.TEXT[clampi(i, 0, TitleLayoutData.LETTER_COUNT - 1)]
	return generated("letter%d" % i, func() -> Image: return letter_image(ch, TitleLayoutData.letter_scale(i), i))


## Pá do logo: cabo 15/17 com alça em D, lâmina 05–08 (só a parte de fora da terra).
static func shovel_image() -> Image:
	return UiKit.ascii([
		"...ooooo.....",
		"..o.....o....",
		"..oooxooo....",
		".....xo......",
		".....xo......",
		".....xo......",
		".....xo......",
		"....xo.......",
		"....xo.......",
		"....xo.......",
		"....xo.......",
		"....xo.......",
		"....xo.......",
		"...xo........",
		"...xo........",
		"...xo........",
		"...xo........",
		"...xo........",
		"..ooooo......",
		".oppmmso.....",
		".opmmmso.....",
		".opmmmso.....",
		".opmmmso.....",
		".opmmsso.....",
		".odddddo.....",
		".uuuuuuu.....",
		"uuuuuuuuu....",
		".uu.u.uu.....",
		"..u...u......",
		".............",
	], {"o": Palette.OUTLINE, "x": Palette.DIRT_EDGE, "p": Palette.STONE_LIGHT, "m": Palette.STONE,
		"s": Palette.STONE_DARK, "d": Palette.MOONSHADOW, "u": Palette.DIRT})


static func shovel_texture() -> Texture2D:
	var art := texture(LOGO_SHOVEL)
	return art if art != null else generated("logo_shovel", shovel_image)


# --- Kit: painel de pedra, botão de perigo, rolos do pergaminho ------------------------

## Lápide 24×28 em 06/07/08, contorno 01, topo arredondado (9-slice STONE_MARGIN).
static func stone_image() -> Image:
	var img := _img(24, 28)
	_rect(img, 0, 6, 24, 22, Palette.OUTLINE)
	_rect(img, 2, 2, 20, 4, Palette.OUTLINE)
	_rect(img, 4, 1, 16, 1, Palette.OUTLINE)
	_rect(img, 6, 0, 12, 1, Palette.OUTLINE)
	_rect(img, 1, 6, 22, 20, Palette.STONE)
	_rect(img, 3, 3, 18, 3, Palette.STONE)
	_rect(img, 5, 2, 14, 1, Palette.STONE)
	_rect(img, 7, 1, 10, 1, Palette.STONE_LIGHT)
	_rect(img, 5, 2, 4, 1, Palette.STONE_LIGHT)
	_rect(img, 1, 6, 2, 19, Palette.STONE_LIGHT)
	_rect(img, 21, 6, 2, 19, Palette.STONE_DARK)
	_rect(img, 1, 25, 22, 1, Palette.STONE_DARK)
	_rect(img, 1, 26, 22, 1, Palette.MOONSHADOW)
	return img


static func stone_style() -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	var art := texture(PANEL_STONE)
	var m := STONE_MARGIN
	if art != null:
		s.texture = art
		m = STONE_ART_MARGIN
	else:
		s.texture = generated("panel_stone", stone_image)
	s.texture_margin_left = m.x
	s.texture_margin_top = m.y
	s.texture_margin_right = m.z
	s.texture_margin_bottom = m.w
	# MANIFEST: área útil de (8, 12) até (largura − 9, altura − 13); + folga para o texto.
	s.content_margin_left = 14
	s.content_margin_right = 15
	s.content_margin_top = 14
	s.content_margin_bottom = 15
	return s


## Botão de perigo (31/32) nos 4 estados, mesma geometria do botão de madeira placeholder.
static func danger_image(state: StringName) -> Image:
	var img := _img(UiKit.BUTTON_SIZE.x, UiKit.BUTTON_SIZE.y)
	var top := 1
	var fill := Palette.DANGER_DARK
	var light := Palette.DANGER
	var border := Palette.OUTLINE
	var shadow := 1
	match state:
		&"hover":
			top = 0
			fill = Palette.DANGER
			light = Palette.DANGER
			border = Palette.LANTERN_BRIGHT
			shadow = 2
		&"pressed":
			top = 2
			shadow = 0
		&"disabled":
			fill = Palette.MOONSHADOW
			light = Palette.STONE_DARK
	var w := UiKit.BUTTON_SIZE.x
	var bottom := top + 11
	_rect(img, 1, top, w - 2, 1, border)
	_rect(img, 1, bottom, w - 2, 1, border)
	_rect(img, 0, top + 1, 1, 10, border)
	_rect(img, w - 1, top + 1, 1, 10, border)
	_rect(img, 1, top + 1, w - 2, 10, fill)
	_rect(img, 1, top + 1, w - 2, 1, light)
	_rect(img, 1, bottom - 1, w - 2, 1, Palette.COFFIN_DARK)
	for i: int in shadow:
		_rect(img, 1, bottom + 1 + i, w - 2, 1, Palette.OUTLINE)
	return img


## Estilo de `btn_perigo`: arte do manifesto (MANIFEST: mesmas células 48×24 e 9-slice do
## btn_grande, então reaproveita o estilo dele trocando a textura) ou placeholder.
static func danger_style(state: StringName) -> StyleBox:
	var art := texture(BTN_DANGER)
	var wood_art := AssetManifest.texture(UiKit.BUTTON_PATH) != null
	if art != null and wood_art and art.get_width() == int(UiKit.BTN_ART_CELL.x) * 4:
		var base := UiKit.button_style(state, 10) as StyleBoxTexture
		if base != null:
			var a := base.duplicate() as StyleBoxTexture
			a.texture = art
			return a
	var s := StyleBoxTexture.new()
	s.texture = generated("danger_" + String(state), func() -> Image: return danger_image(state))
	s.texture_margin_left = UiKit.BUTTON_MARGIN.x
	s.texture_margin_top = UiKit.BUTTON_MARGIN.y
	s.texture_margin_right = UiKit.BUTTON_MARGIN.z
	s.texture_margin_bottom = UiKit.BUTTON_MARGIN.w
	s.content_margin_left = 10
	s.content_margin_right = 10
	var dy := -1 if state == &"hover" else (1 if state == &"pressed" else 0)
	s.content_margin_top = 1 + dy
	s.content_margin_bottom = 3 - dy
	return s


## Rolo de pergaminho 24×8 (madeira 18/19/20 com papel 21/22 enrolado), estica na horizontal.
static func scroll_end_image() -> Image:
	return UiKit.ascii([
		"oooooooooooooooooooooooo",
		"oeffffffffffffffffffffeo",
		"oewwwwwwwwwwwwwwwwwwwwdo",
		"oessssssssssssssssssssdo",
		"oeddddddddddddddddddddeo",
		"oooooooooooooooooooooooo",
		".o....................o.",
		"........................",
	], {"o": Palette.OUTLINE, "e": Palette.COFFIN_LIGHT, "d": Palette.COFFIN_DARK, "f": Palette.BONE_BRIGHT,
		"w": Palette.BONE, "s": Palette.BONE_SHADOW})


## Ícone de Cobre do tamanho do texto m5x7 (◉ não existe na fonte).
static func copper_glyph() -> ImageTexture:
	return generated("copper_glyph", func() -> Image:
		return UiKit.ascii([
			".ooooo.",
			"obcccbo",
			"ocbbbao",
			"ocbobao",
			"ocbbbao",
			"obaaaao",
			".ooooo.",
		], {"o": Palette.OUTLINE, "a": Palette.LANTERN_DARK, "b": Palette.LANTERN, "c": Palette.LANTERN_BRIGHT}))


## Xadrez 01 para escurecer o fundo dos painéis (sem alfa: paleta fechada).
static func dim_texture() -> ImageTexture:
	return generated("dim", func() -> Image:
		var img := _img(2, 2)
		_px(img, 0, 0, Palette.OUTLINE)
		_px(img, 1, 1, Palette.OUTLINE)
		return img)


## Níveis de dither (Bayer 4×4) do fade do preto: 0 = transparente, 16 = preto cheio.
const BAYER: Array[int] = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]


static func fade_texture(level: int) -> ImageTexture:
	var lv := clampi(level, 0, 16)
	return generated("fade%d" % lv, func() -> Image:
		var img := _img(4, 4)
		for y: int in 4:
			for x: int in 4:
				if BAYER[y * 4 + x] < lv:
					_px(img, x, y, Palette.OUTLINE)
		return img)
