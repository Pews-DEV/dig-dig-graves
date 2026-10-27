class_name TitleLayers
extends RefCounted
## Camadas da tela-título (UI/UX §9.1, §9.6), em coordenadas da tela no enquadramento final.
## A tela-título move cada camada para baixo durante a descida da câmera (fator de parallax).
## Arte pelo id do manifesto; sem ela, placeholder da paleta (TitleArt).


## 1. Céu (title_sky, 640×600 em y = −240) com estrelas que cintilam e nuvens finas.
class Sky:
	extends Node2D

	const CLOUD_SPEED := 2.0
	var layout: TitleLayoutData
	var _tex: Texture2D
	var _stars_tex: Texture2D = TitleArt.texture_path(TitleArt.STARS_PATH)
	var _clouds_tex: Texture2D = TitleArt.texture_path(TitleArt.CLOUDS_PATH)
	var _stars: Array[Dictionary] = []
	var _t: float = 0.0

	func _init(p_layout: TitleLayoutData) -> void:
		layout = p_layout

	func _ready() -> void:
		_tex = TitleArt.texture(TitleArt.SKY)
		if _tex == null:
			var l := layout
			_tex = TitleArt.generated("title_sky", func() -> Image: return TitleArt.sky_image(l.moon_center, l.moon_radius))
		var rng := RandomNumberGenerator.new()
		rng.seed = 2027
		var tries := 0
		while _stars.size() < layout.star_count and tries < 400:
			tries += 1
			var p := Vector2(rng.randi_range(4, 636), rng.randi_range(-200, layout.star_max_y))
			if p.distance_to(layout.moon_center) < layout.moon_radius + 18.0 or layout.logo_rect.grow(6).has_point(p):
				continue
			_stars.append({"p": p, "big": rng.randf() < 0.2, "phase": rng.randf() * 10.0, "speed": rng.randf_range(0.15, 0.45)})

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		draw_texture(_tex, Vector2(0, layout.sky_y))
		for s: Dictionary in _stars:
			var on := sin(_t * float(s.speed) * TAU + float(s.phase)) > -0.2
			var pos: Vector2 = s.p
			if _stars_tex != null:
				TreeArt.draw_cell(self, _stars_tex, Vector2(5, 5), 0 if on else 1, 1 if bool(s.big) else 0, pos, Vector2(2, 2))
			else:
				draw_rect(Rect2(pos, Vector2.ONE), Palette.color(Palette.STONE_LIGHT if on else Palette.STONE_DARK))
		if _clouds_tex != null:
			var cw := float(_clouds_tex.get_width())
			var drift := fmod(_t * CLOUD_SPEED * Juice.motion(), 640.0 + cw)
			for row: int in mini(3, layout.cloud_rows_y.size()):
				var x := fmod(row * 230.0 + drift, 640.0 + cw) - cw
				draw_texture_rect_region(_clouds_tex, Rect2(Vector2(roundf(x), layout.cloud_rows_y[row]), Vector2(cw, 16)), Rect2(0, row * 16, cw, 16))


## 2. Vila na colina (title_village) com janelas (title_windows) que acendem e apagam.
class Village:
	extends Node2D

	var layout: TitleLayoutData
	var _tex: Texture2D
	var _top: float = 0.0
	var _win_tex: Texture2D
	var _win_sheet: AsepriteSheet
	var _lit: Array[bool] = []
	var _next_toggle: float = 1.0

	func _init(p_layout: TitleLayoutData) -> void:
		layout = p_layout

	func _ready() -> void:
		_tex = TitleArt.texture(TitleArt.VILLAGE)
		if _tex != null:
			_top = TitleLayoutData.layer_top(layout.village_y, _tex.get_height())
		else:
			var h := layout.horizon_y
			_tex = TitleArt.generated("title_village", func() -> Image: return TitleArt.village_image(h))
			_top = float(layout.horizon_y - 30)
		_win_sheet = TitleArt.sheet(TitleArt.WINDOWS)
		_win_tex = TitleArt.texture(TitleArt.WINDOWS)
		for i: int in layout.window_points.size():
			_lit.append(randf() < layout.window_lit_chance)

	func _process(delta: float) -> void:
		_next_toggle -= delta
		if _next_toggle <= 0.0 and not _lit.is_empty():
			_next_toggle = randf_range(layout.window_toggle_every.x, layout.window_toggle_every.y)
			var i := randi() % _lit.size()
			_lit[i] = not _lit[i]
			queue_redraw()

	func _draw() -> void:
		draw_texture(_tex, Vector2(0, _top))
		for i: int in layout.window_points.size():
			var p := layout.window_points[i]
			var frame := 1 if _lit[i] else 0
			# MANIFEST title_windows: canto sup. esq. da célula na posição listada.
			if _win_sheet != null:
				_win_sheet.draw_frame(self, mini(frame, _win_sheet.frames.size() - 1), p, Vector2.ZERO)
			elif _win_tex != null:
				# Sem JSON: 2 frames lado a lado (ou empilhados) na célula de window_cell.
				var cell := Vector2(layout.window_cell)
				var src := Rect2(Vector2(frame * cell.x, 0) if _win_tex.get_width() >= _win_tex.get_height() else Vector2(0, frame * cell.y), cell)
				draw_texture_rect_region(_win_tex, Rect2(p.floor(), cell), src)
			else:
				# Janela 2×3: acesa 26 com base 25, apagada 02 (UI/UX §9.1: emissivas 25/26).
				draw_rect(Rect2(p.floor(), Vector2(2, 3)), Palette.color(Palette.LANTERN_BRIGHT if _lit[i] else Palette.BG))
				if _lit[i]:
					draw_rect(Rect2(p.floor() + Vector2(0, 2), Vector2(2, 1)), Palette.color(Palette.LANTERN))


## 3. Fila das almas (alma_fila): andam pela trilha da vila até o portão e somem nele.
## MANIFEST: ficam na profundidade da vila (parallax 0,5), entre title_village e title_wall.
class Souls:
	extends Node2D

	const VANISH := 0.36
	var layout: TitleLayoutData
	## Deslocamento da câmera neste frame (drop × (1 − p)), sem o fator.
	var drop: float = 0.0
	var _sheet: AsepriteSheet = TitleArt.sheet(TitleArt.SOUL)
	var _souls: Array[Dictionary] = []
	var _spawn_in: float = 0.0
	var _length: float = 0.0
	var _t: float = 0.0

	func _init(p_layout: TitleLayoutData) -> void:
		layout = p_layout

	func _ready() -> void:
		var pts := layout.soul_path
		for i: int in range(1, pts.size()):
			_length += pts[i - 1].distance_to(pts[i])
		# A fila já está andando quando a tela abre.
		var s := _length - 4.0
		while s > 0.0:
			_souls.append({"s": s, "age": 0.0, "vanish": -1.0, "phase": randf() * 4.0})
			s -= layout.soul_every * layout.soul_speed
		_spawn_in = layout.soul_every

	func _process(delta: float) -> void:
		_t += delta
		_spawn_in -= delta
		if _spawn_in <= 0.0:
			_spawn_in = layout.soul_every * randf_range(0.8, 1.25)
			_souls.append({"s": 0.0, "age": 0.0, "vanish": -1.0, "phase": randf() * 4.0})
		for soul: Dictionary in _souls:
			soul.age = float(soul.age) + delta
			if float(soul.vanish) >= 0.0:
				soul.vanish = float(soul.vanish) + delta
			else:
				soul.s = float(soul.s) + layout.soul_speed * delta
				if float(soul.s) >= _length:
					soul.s = _length
					soul.vanish = 0.0
		_souls = _souls.filter(func(soul: Dictionary) -> bool: return float(soul.vanish) < _vanish_time())
		queue_redraw()

	func _vanish_time() -> float:
		if _sheet != null and _sheet.has_tag(&"vanish"):
			return _sheet.tag_duration(&"vanish")
		return VANISH

	func point_at(s: float) -> Vector2:
		var pts := layout.soul_path
		var left := s
		for i: int in range(1, pts.size()):
			var seg := pts[i - 1].distance_to(pts[i])
			if left <= seg:
				return pts[i - 1].lerp(pts[i], left / maxf(seg, 0.001))
			left -= seg
		return pts[pts.size() - 1]

	func _heading_left(s: float) -> bool:
		var a := point_at(maxf(s - 1.0, 0.0))
		var b := point_at(minf(s + 1.0, _length))
		return b.x < a.x - 0.1

	func _draw() -> void:
		for soul: Dictionary in _souls:
			var s := float(soul.s)
			var p := (point_at(s) + Vector2(0, roundf(drop * layout.factor_village))).round()
			var vanishing := float(soul.vanish) >= 0.0
			if _sheet != null:
				var fs := _sheet.frame_size()
				var piv := Vector2(floorf(fs.x * 0.5), fs.y - 1.0)
				var frame := _sheet.frame_at(&"vanish", float(soul.vanish), false) if vanishing else _sheet.frame_at(&"walk", float(soul.age) + float(soul.phase), true)
				# MANIFEST alma_fila: anda para a direita; espelha nos trechos que vão para a esquerda.
				_sheet.draw_frame(self, frame, p, piv, _heading_left(s))
				continue
			# Placeholder: gotinha 30/23 de 5×7 flutuando 1 px; some em xadrez no portão.
			var bob := -1.0 if sin((float(soul.age) + float(soul.phase)) * 5.0) > 0.0 and not Juice.reduce_motion() else 0.0
			var q := p + Vector2(0, bob)
			var cut := int(float(soul.vanish) / VANISH * 3.0) if vanishing else -1
			for y: int in 7:
				var half := [0, 1, 1, 2, 2, 2, 1][y] as int
				for x: int in range(-half, half + 1):
					if cut == 1 and (x + y) % 2 == 0:
						continue
					if cut >= 2 and (x + y) % 3 != 0:
						continue
					var idx := Palette.BONE_BRIGHT if (y == 3 and x == -1) else Palette.SOUL
					draw_rect(Rect2(q + Vector2(x, y - 8), Vector2.ONE), Palette.color(idx))


## 4–5. Camada estática simples (muro, primeiro plano) com textura do manifesto ou placeholder.
class Plate:
	extends Node2D

	var _tex: Texture2D
	var _top: float = 0.0

	func _init(tex: Texture2D, top: float) -> void:
		_tex = tex
		_top = top

	func _draw() -> void:
		if _tex == null:
			return
		# Folha com frames (ex.: copa do ipê com idle) sem JSON: só o primeiro quadro de 640 px.
		var w := minf(640.0, float(_tex.get_width()))
		draw_texture_rect_region(_tex, Rect2(0, _top, w, _tex.get_height()), Rect2(0, 0, w, _tex.get_height()))


## 7. Frente: pétalas do ipê caindo e vaga-lumes (por cima da copa).
class Front:
	extends Node2D

	const PETAL_EVERY := 0.7
	const PETAL_SPEED := 11.0
	const PETAL_SWAY := 6.0
	const FIREFLY_FRAMES: Array[float] = [0.4, 0.15, 0.25]
	var layout: TitleLayoutData
	var _petal_tex: Texture2D = TitleArt.texture_path(TitleArt.PETALS_PATH)
	var _fly_tex: Texture2D = TitleArt.texture_path(TitleArt.FIREFLY_PATH)
	var _petals: Array[Dictionary] = []
	var _flies: Array[Dictionary] = []
	var _petal_acc: float = 0.0
	var _t: float = 0.0

	func _init(p_layout: TitleLayoutData) -> void:
		layout = p_layout

	func _ready() -> void:
		var m := Juice.motion()
		var r := layout.fireflies
		for i: int in maxi(1, roundi(layout.firefly_count * m)):
			_flies.append({"base": Vector2(randf_range(r.position.x, r.end.x), randf_range(r.position.y, r.end.y)), "phase": randf() * 10.0, "speed": randf_range(0.2, 0.5)})

	func _process(delta: float) -> void:
		_t += delta
		_petal_acc += delta * Juice.motion()
		var c := layout.ipe_canopy
		while _petal_acc >= PETAL_EVERY:
			_petal_acc -= PETAL_EVERY
			var x := randf_range(c.position.x, c.end.x)
			_petals.append({"pos": Vector2(x, randf_range(c.position.y + 20, c.end.y)), "x0": x, "phase": randf() * TAU, "shape": randi() % 4, "landed": -1.0, "life": randf_range(2.5, 4.5),
				"land_y": randf_range(layout.petal_land.x, layout.petal_land.y)})
		for p: Dictionary in _petals:
			if float(p.landed) >= 0.0:
				p.landed = float(p.landed) + delta
				continue
			var pos: Vector2 = p.pos
			pos.y += PETAL_SPEED * delta
			pos.x = float(p.x0) - (pos.y - c.position.y) * 0.25 + sin(pos.y * 0.18 + float(p.phase)) * PETAL_SWAY
			p.pos = pos
			if pos.y >= float(p.land_y):
				p.landed = 0.0
		_petals = _petals.filter(func(p: Dictionary) -> bool: return float(p.landed) < float(p.life))
		queue_redraw()

	func _draw() -> void:
		for p: Dictionary in _petals:
			var frame := 0 if float(p.landed) >= 0.0 else int(_t / 0.2 + float(p.phase)) % 2
			var pos: Vector2 = p.pos
			if _petal_tex != null:
				TreeArt.draw_cell(self, _petal_tex, Vector2(3, 3), frame, int(p.shape), pos, Vector2(1, 1))
			else:
				draw_rect(Rect2(pos.round(), Vector2(2, 1)), Palette.color(Palette.MOONSHADOW))
		for f: Dictionary in _flies:
			var a := _t * float(f.speed) + float(f.phase)
			var pos2 := (f.base as Vector2) + Vector2(sin(a) * 18.0, sin(a * 1.7) * 4.0) * Juice.motion()
			var fr := TreeArt.frame_at(_t + float(f.phase), FIREFLY_FRAMES)
			if _fly_tex != null:
				TreeArt.draw_cell(self, _fly_tex, Vector2(3, 3), fr, 0, pos2, Vector2(1, 1))
			else:
				draw_rect(Rect2(pos2.round(), Vector2.ONE), Palette.color(Palette.LANTERN_BRIGHT if fr == 1 else Palette.BONE_BRIGHT))


## Névoa baixa atravessando (nevoa_a1), entre o muro e o primeiro plano.
class Fog:
	extends Node2D

	const FOG_SPEED := 4.0
	var layout: TitleLayoutData
	var _tex: Texture2D = TitleArt.texture_path(TitleArt.FOG_PATH)
	var _t: float = 0.0

	func _init(p_layout: TitleLayoutData) -> void:
		layout = p_layout

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		if _tex == null:
			return
		var period := float(_tex.get_width())
		for row: int in mini(2, layout.fog_y.size()):
			var dir := 1.0 if row == 0 else -0.7
			var x := fmod(_t * FOG_SPEED * dir * Juice.motion() + row * 120.0, period)
			if x > 0.0:
				x -= period
			var px := roundf(x)
			while px < 640.0:
				draw_texture_rect_region(_tex, Rect2(px, layout.fog_y[row], period, 24), Rect2(0, row * 24, period, 24))
				px += period


## 6. Copa do ipê (title_fg_canopy: 3 frames, pingpong de 400 ms) por cima do primeiro plano.
class Canopy:
	extends Node2D

	var layout: TitleLayoutData
	var _sheet: AsepriteSheet = TitleArt.sheet(TitleArt.FG_CANOPY)
	var _t: float = 0.0

	func _init(p_layout: TitleLayoutData) -> void:
		layout = p_layout

	func _process(delta: float) -> void:
		var before := int(_t / 0.4)
		_t += delta * (0.0 if Juice.reduce_motion() else 1.0)
		if int(_t / 0.4) != before:
			queue_redraw()

	func _draw() -> void:
		if _sheet == null:
			return  # o placeholder da copa já vem no primeiro plano gerado
		var n := _sheet.tag_range(&"idle").y - _sheet.tag_range(&"idle").x + 1
		var f := _sheet.tag_range(&"idle").x + TreeArt.pingpong(_t, n, 0.4)
		_sheet.draw_frame(self, f, layout.canopy_pos, Vector2.ZERO)
