class_name RunBackdrop
extends Node2D
## Ambientação do Turno (UI/UX §5, revisão 1.1). `front = false`: clareira de cemitério na mata
## escura (MANIFEST "Turno — fundo v2": bg_a1_chao < bg_a1_props < bg_a1_mata), com parallax
## pelo mouse e as chamas das velas do fundo tremulando. Sem essa arte, cai no fundo antigo
## (céu bg_a1_sky/estrelas/nuvens/muro) e, sem nenhuma arte, no placeholder por código.
## `front = true`: névoa baixa em faixas de xadrez 04/05 e vinheta em xadrez 01.
## Parallax lento pela posição do mouse; "reduzir movimento" corta para 25%.

const W := 640
const H := 360
const HORIZON := 166
const MOON := Vector2(92, 58)
const MOON_R := 17
const STAR_COUNT := 46
## Fator de parallax por camada (px por px de mouse a partir do centro).
const PARALLAX_MOON := 0.006
const PARALLAX_CLOUDS := 0.012
const PARALLAX_FAR := 0.025
const PARALLAX_FOG := -0.02
const CLOUD_SPEED := 2.0  # UI/UX §5: ~2 px/s
const FOG_SPEED := 4.0

var front: bool = false
## Altura das 2 faixas de névoa (o Run ajusta pela base do bloco).
var fog_y: Array[float] = [246.0, 276.0]

## Arte da cena (MANIFEST bg_a1_*, vinheta). Ausente = placeholder gerado abaixo.
const ART_DIR := "res://assets/sprites/bg/a1/"
const ART_MOON := Vector2(74, 58)
const ART_FAR_POS := Vector2(0, 96)
const CLOUD_ROWS_Y: Array[int] = [40, 84, 66]
var _art_sky: Texture2D = AssetManifest.texture(ART_DIR + "bg_a1_sky.png")
var _art_stars: Texture2D = AssetManifest.texture(ART_DIR + "bg_a1_stars.png")
var _art_clouds: Texture2D = AssetManifest.texture(ART_DIR + "bg_a1_clouds.png")
var _art_far: Texture2D = AssetManifest.texture(ART_DIR + "bg_a1_far.png")
var _art_fog: Texture2D = AssetManifest.texture(ART_DIR + "nevoa_a1.png")
var _art_vignette: Texture2D = AssetManifest.texture(ART_DIR + "vinheta.png")
## Fundo v2: medidas, parallax e chamas em RunClearing (puro, testável).
const CANDLE_FRAMES: Array[float] = [0.125, 0.125, 0.125]  # 8 fps, como o sprite `vela`
var _art_ground: Texture2D = AssetManifest.texture(ART_DIR + "bg_a1_chao.png")
var _art_props: Texture2D = AssetManifest.texture(ART_DIR + "bg_a1_props.png")
var _art_woods: Texture2D = AssetManifest.texture(ART_DIR + "bg_a1_mata.png")
var _woods_sheet: AsepriteSheet = AsepriteSheet.load_sheet(ART_DIR + "bg_a1_mata.png")
## Pontas das chamas das velas do fundo (px da tela no enquadramento sem parallax).
var _flame_tips: Array[Vector2i] = []

var _sky: ImageTexture
var _moon: ImageTexture
var _far: ImageTexture
var _cloud: ImageTexture
var _fog: ImageTexture
var _vignette: ImageTexture
var _stars: Array[Dictionary] = []
var _t: float = 0.0
var _rng := RandomNumberGenerator.new()
var _parallax: Vector2 = Vector2.ZERO


func _ready() -> void:
	_rng.seed = 2026
	if front:
		if _art_fog == null or _art_vignette == null:
			_fog = _cached("fog", _fog_image)
			_vignette = _cached("vignette", _vignette_image)
	elif _art_ground != null:
		_flame_tips = RunClearing.flame_tips(_art_props, RunClearing.CANDLE_CENTERS)
	elif _art_sky == null:
		_sky = _cached("sky", _sky_image)
		_moon = _cached("moon", _moon_image)
		_far = _cached("far", _far_image)
		_cloud = _cached("cloud", _cloud_image)
	if not front and _art_ground == null:
		var moon := ART_MOON if _art_sky != null else MOON
		var max_y := 118 if _art_sky != null else HORIZON - 44
		for i: int in STAR_COUNT:
			var p := Vector2i(_rng.randi_range(4, W - 4), _rng.randi_range(4, max_y))
			if Vector2(p).distance_to(moon) < 46.0:
				continue
			_stars.append({"p": p, "phase": _rng.randf() * 10.0, "speed": _rng.randf_range(0.15, 0.45), "big": _rng.randf() < 0.18})


## Texturas geradas uma vez por sessão (a geração pixel a pixel custa alguns ms).
static var _tex_cache: Dictionary = {}


static func _cached(key: String, maker: Callable) -> ImageTexture:
	if not _tex_cache.has(key):
		_tex_cache[key] = ImageTexture.create_from_image(maker.call() as Image)
	return _tex_cache[key] as ImageTexture


func _process(delta: float) -> void:
	_t += delta
	var m := get_viewport().get_mouse_position() - Vector2(W, H) * 0.5
	_parallax = m * Juice.motion()
	queue_redraw()


func _off(factor: float) -> Vector2:
	return (_parallax * factor).round()


func _draw() -> void:
	if front:
		_draw_front()
		return
	if _art_ground != null:
		_draw_clearing()
		return
	if _art_sky != null:
		_draw_art_back()
		return
	draw_texture(_sky, Vector2.ZERO)
	_draw_stars()
	draw_texture(_moon, (MOON - Vector2(32, 32)).round() + _off(PARALLAX_MOON))
	# Nuvens finas passando na frente da lua, devagar (~2 px/s).
	var cloud_w := _cloud.get_width()
	var drift := fmod(_t * CLOUD_SPEED * Juice.motion(), float(W + cloud_w))
	for c: Vector3 in [Vector3(0, 52, 0), Vector3(260, 34, 1), Vector3(470, 76, 0)]:
		var x := fmod(c.x + drift, float(W + cloud_w)) - cloud_w
		draw_texture(_cloud, Vector2(roundf(x), c.y) + _off(PARALLAX_CLOUDS))
	draw_texture(_far, Vector2(-20, HORIZON - 56) + _off(PARALLAX_FAR))


## Deslocamento do fundo v2: contra o mouse, em px inteiros, limitado a ±16 px (MANIFEST).
func _off_v2(factor: float) -> Vector2:
	return RunClearing.parallax_offset(_parallax, factor)


## Clareira na mata escura: chão < props (+ chamas tremulando) < mata (balanço de 2 frames).
func _draw_clearing() -> void:
	draw_texture(_art_ground, RunClearing.V2_ORIGIN + _off_v2(RunClearing.PARALLAX_GROUND))
	if _art_props != null:
		var po := _off_v2(RunClearing.PARALLAX_PROPS)
		draw_texture(_art_props, RunClearing.V2_ORIGIN + po)
		_draw_flames(po)
	if _art_woods != null:
		var wo := RunClearing.V2_ORIGIN + _off_v2(RunClearing.PARALLAX_WOODS)
		if _woods_sheet != null:
			_woods_sheet.draw_frame(self, _woods_sheet.frame_at(&"idle", _t, true), wo, Vector2.ZERO)
		else:
			draw_texture_rect_region(_art_woods, Rect2(wo, RunClearing.V2_FRAME), Rect2(Vector2.ZERO, RunClearing.V2_FRAME))


## As chamas de bg_a1_props são estáticas: por cima de cada ponta, 1 px que acende e apaga
## em 3 tempos (8 fps, defasado por vela), como o sprite `vela`. "Reduzir movimento" desliga.
func _draw_flames(offset: Vector2) -> void:
	if Juice.reduce_motion():
		return
	for i: int in _flame_tips.size():
		var tip := Vector2(_flame_tips[i]) + offset
		match TreeArt.frame_at(_t + i * 0.15, CANDLE_FRAMES):
			0:
				draw_rect(Rect2(tip + Vector2(0, -1), Vector2.ONE), Palette.color(Palette.LANTERN_BRIGHT))
			1:
				draw_rect(Rect2(tip + Vector2(0, -1), Vector2.ONE), Palette.color(Palette.LANTERN))
				draw_rect(Rect2(tip + Vector2(0, -2), Vector2.ONE), Palette.color(Palette.LANTERN_BRIGHT))


func _draw_art_back() -> void:
	draw_texture(_art_sky, Vector2.ZERO)
	for s: Dictionary in _stars:
		var on := sin(_t * float(s.speed) * TAU + float(s.phase)) > -0.2
		TreeArt.draw_cell(self, _art_stars, Vector2(5, 5), 0 if on else 1, 1 if bool(s.big) else 0, Vector2(s.p as Vector2i) + _off(PARALLAX_MOON), Vector2(2, 2))
	if _art_clouds != null:
		var cw := float(_art_clouds.get_width())
		var drift := fmod(_t * CLOUD_SPEED * Juice.motion(), W + cw)
		for row: int in 3:
			var x := fmod(row * 230.0 + drift, W + cw) - cw
			draw_texture_rect_region(_art_clouds, Rect2(Vector2(roundf(x), CLOUD_ROWS_Y[row]) + _off(PARALLAX_CLOUDS), Vector2(cw, 16)), Rect2(0, row * 16, cw, 16))
	if _art_far != null:
		var o := ART_FAR_POS + Vector2(_off(PARALLAX_FAR).x, 0)
		draw_texture(_art_far, o)
		# Cópias nas bordas cobrem os px que o parallax descobre.
		draw_texture(_art_far, o - Vector2(W, 0))
		draw_texture(_art_far, o + Vector2(W, 0))


func _draw_stars() -> void:
	for s: Dictionary in _stars:
		# 2 frames, troca lenta e aleatória (UI/UX §5).
		var on := sin(_t * float(s.speed) * TAU + float(s.phase)) > 0.55
		var p: Vector2i = s.p
		if bool(s.big):
			draw_rect(Rect2(p, Vector2.ONE), Palette.color(Palette.STONE_LIGHT if on else Palette.STONE))
			if on:
				for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					draw_rect(Rect2(p + d, Vector2.ONE), Palette.color(Palette.MOONSHADOW))
		else:
			draw_rect(Rect2(p, Vector2.ONE), Palette.color(Palette.STONE if on else Palette.STONE_DARK))


func _draw_front() -> void:
	if _art_fog != null:
		var period := float(_art_fog.get_width())
		for row: int in 2:
			var dir := 1.0 if row == 0 else -0.7
			var x := fmod(_t * FOG_SPEED * dir * Juice.motion() + row * 120.0, period)
			if x > 0.0:
				x -= period
			var px := roundf(x) + _off(PARALLAX_FOG).x
			while px < W:
				draw_texture_rect_region(_art_fog, Rect2(px, fog_y[row], period, 24), Rect2(0, row * 24, period, 24))
				px += period
		if _art_vignette != null:
			draw_texture(_art_vignette, Vector2.ZERO)
			return
	if _fog == null:
		return
	# Névoa: 3 faixas atravessando devagar na frente do bloco do campo.
	var fw := float(_fog.get_width())
	var bands: Array[Vector3] = [Vector3(0, 254, 1.0), Vector3(300, 272, -0.7), Vector3(150, 292, 0.5)]
	for b: Vector3 in bands:
		var x := fmod(b.x + _t * FOG_SPEED * b.z * Juice.motion(), W + fw)
		if x < 0.0:
			x += W + fw
		draw_texture(_fog, Vector2(roundf(x - fw), b.y) + _off(PARALLAX_FOG))
	draw_texture(_vignette, Vector2.ZERO)


# --- Geração das texturas (só cores da paleta, transições em xadrez) ---------------------

static func _checker(img: Image, x: int, y: int, idx: int) -> void:
	if (x + y) % 2 == 0 and x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, Palette.color(idx))


func _sky_image() -> Image:
	var img := Image.create_empty(W, H, false, Image.FORMAT_RGBA8)
	img.fill_rect(Rect2i(0, 0, W, 64), Palette.color(Palette.BG))
	img.fill_rect(Rect2i(0, 64, W, HORIZON - 64), Palette.color(Palette.NIGHT))
	img.fill_rect(Rect2i(0, HORIZON, W, H - HORIZON), Palette.color(Palette.BG))
	img.fill_rect(Rect2i(0, 300, W, H - 300), Palette.color(Palette.OUTLINE))
	for x: int in W:
		for y: int in range(60, 68):
			_checker(img, x, y, Palette.BG if y < 64 else Palette.NIGHT)
		# Faixa mais clara (04) perto do horizonte, em xadrez.
		for y: int in range(HORIZON - 26, HORIZON - 18):
			_checker(img, x, y, Palette.NIGHT_VIOLET)
		for y: int in range(HORIZON - 18, HORIZON):
			if y % 2 == 0 or (x + y) % 2 == 0:
				img.set_pixel(x, y, Palette.color(Palette.NIGHT_VIOLET))
		for y: int in range(296, 304):
			_checker(img, x, y, Palette.OUTLINE if y >= 300 else Palette.BG)
	return img


func _moon_image() -> Image:
	var img := Image.create_empty(64, 64, false, Image.FORMAT_RGBA8)
	var c := Vector2(32, 32)
	for y: int in 64:
		for x: int in 64:
			var d := Vector2(x, y).distance_to(c)
			if d <= MOON_R:
				var idx := Palette.STONE_LIGHT
				# Luz vinda do NO: borda de baixo/direita mais escura; manchas (mares) em 07.
				if Vector2(x - 32, y - 32).dot(Vector2(1, 1).normalized()) > MOON_R * 0.55:
					idx = Palette.STONE
				if d > MOON_R - 1.0:
					idx = Palette.STONE if x + y < 64 else Palette.STONE_DARK
				img.set_pixel(x, y, Palette.color(idx))
			elif d <= MOON_R + 4.0:
				_checker(img, x, y, Palette.MOONSHADOW)
			elif d <= MOON_R + 9.0 and (x % 2 == 0 and y % 2 == 0):
				img.set_pixel(x, y, Palette.color(Palette.NIGHT_VIOLET))
	for m: Vector3i in [Vector3i(26, 27, 3), Vector3i(36, 34, 2), Vector3i(30, 38, 2)]:
		for y: int in range(m.y - m.z, m.y + m.z):
			for x: int in range(m.x - m.z, m.x + m.z):
				if Vector2(x, y).distance_to(Vector2(m.x, m.y)) < m.z:
					img.set_pixel(x, y, Palette.color(Palette.STONE))
	return img


func _cloud_image() -> Image:
	var img := Image.create_empty(90, 5, false, Image.FORMAT_RGBA8)
	for x: int in 90:
		var edge := mini(x, 89 - x)
		for y: int in 5:
			var dense := edge > 12 and y >= 1 and y <= 3
			if dense or (edge > 4 and y == 2):
				_checker(img, x, y, Palette.MOONSHADOW if y < 2 else Palette.NIGHT_VIOLET)
	return img


## Muro caiado com portão, cruzes e o ipê-roxo, em 03/04/05 (luma ≤ 105).
func _far_image() -> Image:
	var w := W + 40
	var img := Image.create_empty(w, 64, false, Image.FORMAT_RGBA8)
	var wall_top := 40
	img.fill_rect(Rect2i(0, wall_top, w, 64 - wall_top), Palette.color(Palette.NIGHT_VIOLET))
	img.fill_rect(Rect2i(0, wall_top, w, 1), Palette.color(Palette.MOONSHADOW))
	img.fill_rect(Rect2i(0, 63, w, 1), Palette.color(Palette.NIGHT))
	for x: int in range(0, w, 24):
		img.fill_rect(Rect2i(x, wall_top - 2, 4, 2), Palette.color(Palette.NIGHT_VIOLET))
		img.fill_rect(Rect2i(x, wall_top - 2, 4, 1), Palette.color(Palette.MOONSHADOW))
	# Portão em arco.
	var gx := 520
	img.fill_rect(Rect2i(gx - 2, wall_top - 14, 32, 24), Palette.color(Palette.NIGHT_VIOLET))
	img.fill_rect(Rect2i(gx + 4, wall_top - 8, 20, 32), Palette.color(Palette.NIGHT))
	for x: int in range(gx + 5, gx + 24, 3):
		img.fill_rect(Rect2i(x, wall_top - 6, 1, 30), Palette.color(Palette.BG))
	img.fill_rect(Rect2i(gx + 12, wall_top - 22, 4, 8), Palette.color(Palette.NIGHT_VIOLET))
	img.fill_rect(Rect2i(gx + 10, wall_top - 20, 8, 2), Palette.color(Palette.NIGHT_VIOLET))
	# Cruzes atrás do muro.
	for cx: int in [70, 250, 330, 420, 610]:
		var h := 10 + (cx % 7)
		img.fill_rect(Rect2i(cx, wall_top - h, 2, h), Palette.color(Palette.NIGHT))
		img.fill_rect(Rect2i(cx - 2, wall_top - h + 3, 6, 2), Palette.color(Palette.NIGHT))
	# Ipê-roxo: tronco 03 e copa 04 com flores 05.
	var tx := 170
	img.fill_rect(Rect2i(tx, 14, 4, wall_top - 14), Palette.color(Palette.NIGHT))
	img.fill_rect(Rect2i(tx - 6, 20, 6, 2), Palette.color(Palette.NIGHT))
	img.fill_rect(Rect2i(tx + 4, 17, 7, 2), Palette.color(Palette.NIGHT))
	for blob: Vector3i in [Vector3i(tx + 2, 12, 12), Vector3i(tx - 10, 17, 8), Vector3i(tx + 15, 15, 9), Vector3i(tx + 4, 4, 8)]:
		for y: int in range(blob.y - blob.z, blob.y + blob.z):
			for x: int in range(blob.x - blob.z - 4, blob.x + blob.z + 4):
				var d := Vector2((x - blob.x) * 0.75, y - blob.y).length()
				if d < blob.z and y >= 0 and x >= 0 and x < w:
					var idx := Palette.MOONSHADOW if (y < blob.y - 2 and (x * 7 + y * 3) % 5 == 0) else Palette.NIGHT_VIOLET
					if d > blob.z - 1.5 and (x + y) % 2 == 1:
						continue
					img.set_pixel(x, y, Palette.color(idx))
	return img


func _fog_image() -> Image:
	var w := 220
	var img := Image.create_empty(w, 6, false, Image.FORMAT_RGBA8)
	for x: int in w:
		var edge := mini(x, w - 1 - x)
		for y: int in 6:
			var core := absi(y - 2) <= 1
			if edge < 30 and (x / 2 + y) % 3 != 0:
				continue
			if not core and (x % 4 != y % 4):
				continue
			_checker(img, x, y, Palette.MOONSHADOW if y < 3 else Palette.NIGHT_VIOLET)
	return img


## Vinheta: cantos escurecidos em xadrez 01 (sprite dither, sem alfa).
func _vignette_image() -> Image:
	var img := Image.create_empty(W, H, false, Image.FORMAT_RGBA8)
	var c := Vector2(W, H) * 0.5
	for y: int in H:
		for x: int in W:
			var d := Vector2((x - c.x) / c.x, (y - c.y) / c.y).length()
			if d > 1.22:
				img.set_pixel(x, y, Palette.color(Palette.OUTLINE))
			elif d > 1.08:
				_checker(img, x, y, Palette.OUTLINE)
			elif d > 0.98 and x % 2 == 0 and y % 2 == 0:
				img.set_pixel(x, y, Palette.color(Palette.OUTLINE))
	return img
