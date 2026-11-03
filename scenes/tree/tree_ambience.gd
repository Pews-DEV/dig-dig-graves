class_name TreeAmbience
extends Node2D
## Vida da Árvore (UI/UX §7.1), em coordenadas do mundo 640×720: pétalas de ipê caindo em
## zigue-zague e pousando na grama, vaga-lumes piscando, poeira subindo no subsolo e bichinhos
## raros (minhoca, besourinho). "Reduzir movimento" corta as partículas ambientes para 25%.

const PETAL_EVERY := 0.55
const PETAL_SPEED := 10.0
const PETAL_SWAY := 6.0
const PETAL_LAND_Y := 110.0
const FIREFLIES := 7
const DUST_EVERY := 0.35
const DUST_SPEED := 3.0
const BUG_MIN := 20.0
const BUG_MAX := 40.0
const FIREFLY_FRAMES: Array[float] = [0.4, 0.15, 0.25]

var _petals: Array[Dictionary] = []
var _flies: Array[Dictionary] = []
var _dust: Array[Dictionary] = []
var _bugs: Array[Dictionary] = []
var _t: float = 0.0
var _petal_acc: float = 0.0
var _dust_acc: float = 0.0
var _bug_in: float = 6.0
var _petal_tex: Texture2D = TreeArt.tex("fx_petals.png")
var _fly_tex: Texture2D = TreeArt.tex("fx_firefly.png")
var _dust_tex: Texture2D = TreeArt.tex("fx_soil_dust.png")
var _worm_tex: Texture2D = TreeArt.tex("fx_worm.png")
var _beetle_tex: Texture2D = TreeArt.tex("fx_beetle.png")


func _ready() -> void:
	var m := Juice.motion()
	for i: int in maxi(1, roundi(FIREFLIES * m)):
		_flies.append({"base": Vector2(randf_range(20, 620), randf_range(96, 108)), "phase": randf() * 10.0, "speed": randf_range(0.2, 0.5)})
	# Algumas pétalas já pousadas para a tela não começar vazia.
	for i: int in roundi(6 * m):
		_petals.append({"pos": Vector2(randf_range(150, 490), PETAL_LAND_Y + randf_range(-1, 1)), "x0": 0.0, "phase": 0.0, "shape": randi() % 4, "landed": randf_range(0.0, 2.0)})


func _process(delta: float) -> void:
	_t += delta
	var m := Juice.motion()
	_petal_acc += delta * m
	while _petal_acc >= PETAL_EVERY:
		_petal_acc -= PETAL_EVERY
		var x := randf_range(140, 500)
		_petals.append({"pos": Vector2(x, randf_range(30, 88)), "x0": x, "phase": randf() * TAU, "shape": randi() % 4, "landed": -1.0, "life": randf_range(3.0, 5.0)})
	for p: Dictionary in _petals:
		if float(p.landed) >= 0.0:
			p.landed = float(p.landed) + delta
			continue
		var pos: Vector2 = p.pos
		pos.y += PETAL_SPEED * delta
		pos.x = float(p.x0) + sin(pos.y * 0.18 + float(p.phase)) * PETAL_SWAY
		p.pos = pos
		if pos.y >= PETAL_LAND_Y:
			p.landed = 0.0
	_petals = _petals.filter(func(p: Dictionary) -> bool: return float(p.landed) < float(p.get("life", 4.0)))

	_dust_acc += delta * m
	while _dust_acc >= DUST_EVERY:
		_dust_acc -= DUST_EVERY
		_dust.append({"pos": Vector2(randf_range(4, 636), randf_range(130, 700)), "age": 0.0, "life": randf_range(2.0, 4.0)})
	for d: Dictionary in _dust:
		d.age = float(d.age) + delta
		d.pos = (d.pos as Vector2) + Vector2(sin(float(d.age) * 2.0) * 0.1, -DUST_SPEED * delta)
	_dust = _dust.filter(func(d: Dictionary) -> bool: return float(d.age) < float(d.life))

	_bug_in -= delta
	if _bug_in <= 0.0:
		_bug_in = randf_range(BUG_MIN, BUG_MAX) / maxf(m, 0.25)
		_spawn_bug()
	for b: Dictionary in _bugs:
		b.age = float(b.age) + delta
		b.pos = (b.pos as Vector2) + Vector2(float(b.dir) * float(b.speed) * delta, 0)
	_bugs = _bugs.filter(func(b: Dictionary) -> bool: return float(b.age) < float(b.life))
	queue_redraw()


## Minhoca (4 px/s) ou besourinho (6 px/s) atravessando um trecho de um estrato e sumindo.
func _spawn_bug() -> void:
	var worm := randf() < 0.6
	var dir := 1 if randf() < 0.5 else -1
	var y := randf_range(150.0, 250.0) if worm else randf_range(270.0, 440.0)
	_bugs.append({"worm": worm, "dir": dir, "pos": Vector2(randf_range(40, 600), roundf(y)), "speed": 4.0 if worm else 6.0, "age": 0.0, "life": randf_range(12.0, 20.0)})


func _draw() -> void:
	for d: Dictionary in _dust:
		var p := (d.pos as Vector2).round()
		var col := 0 if p.y < 258 else 1
		if _dust_tex != null:
			draw_texture_rect_region(_dust_tex, Rect2(p, Vector2.ONE), Rect2(col, 0, 1, 1))
		else:
			draw_rect(Rect2(p, Vector2.ONE), Palette.color(Palette.DIRT_LIGHT if col == 0 else Palette.DIRT_DARK))
	for b: Dictionary in _bugs:
		var flip := int(b.dir) < 0
		var pos: Vector2 = (b.pos as Vector2).round()
		if bool(b.worm):
			var f := int(float(b.age) / 0.18) % 4
			TreeArt.draw_cell(self, _worm_tex, Vector2(12, 5), f, 0, pos, Vector2(6, 4), flip)
		else:
			var f2 := int(float(b.age) / 0.15) % 2
			TreeArt.draw_cell(self, _beetle_tex, Vector2(6, 5), f2, 0, pos, Vector2(3, 4), flip)
	for p: Dictionary in _petals:
		var frame := 0 if float(p.landed) >= 0.0 else int(_t / 0.2 + float(p.phase)) % 2
		var pos2: Vector2 = p.pos
		if _petal_tex != null:
			TreeArt.draw_cell(self, _petal_tex, Vector2(3, 3), frame, int(p.shape), pos2, Vector2(1, 1))
		else:
			draw_rect(Rect2(pos2.round(), Vector2(2, 1)), Palette.color(Palette.MOONSHADOW))
	for f: Dictionary in _flies:
		var a := _t * float(f.speed) + float(f.phase)
		var pos3 := (f.base as Vector2) + Vector2(sin(a) * 18.0, sin(a * 1.7) * 3.0) * Juice.motion()
		var fr := TreeArt.frame_at(_t + float(f.phase), FIREFLY_FRAMES)
		if _fly_tex != null:
			TreeArt.draw_cell(self, _fly_tex, Vector2(3, 3), fr, 0, pos3, Vector2(1, 1))
		else:
			draw_rect(Rect2(pos3.round(), Vector2.ONE), Palette.color(Palette.LANTERN_BRIGHT if fr == 1 else Palette.BONE_BRIGHT))


## Céu com parallax (MANIFEST tree_sky) e estrelas cintilando (tree_stars) espalhadas por código.
class SkyLayer:
	extends Node2D

	const MOON := Vector2(92, 50)
	## Estrelas que cintilam por cima do céu largo (o tree_sky_wide já traz as fixas).
	const WIDE_TWINKLES := 48
	var _stars: Array[Dictionary] = []
	var _t: float = 0.0
	## ART-A2: tree_sky_wide (1936×176, parallax 0,5 nos dois eixos); sem ele, o tree_sky antigo.
	var _sky_wide: Texture2D = TreeArt.tex(TreeArt.SKY_WIDE_FILE)
	var _sky: Texture2D = TreeArt.tex("tree_sky.png")
	var _star_tex: Texture2D = TreeArt.tex("tree_stars.png")
	var wide: bool = _sky_wide != null

	func _ready() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 33
		if wide:
			while _stars.size() < WIDE_TWINKLES:
				var q := Vector2(rng.randi_range(6, int(TreeArt.SKY_WIDE_SIZE.x) - 6), rng.randi_range(6, 120))
				if q.distance_to(TreeArt.SKY_WIDE_MOON) < 34.0:
					continue  # longe da lua
				_stars.append({"p": q, "row": 1 if rng.randf() < 0.25 else 0, "phase": rng.randf() * 10.0, "speed": rng.randf_range(0.12, 0.35)})
			return
		while _stars.size() < 26:
			var p := Vector2(rng.randi_range(6, 634), rng.randi_range(6, 92))
			if p.distance_to(MOON) < 34.0 or (p.x > 150 and p.x < 490 and p.y > 20):
				continue  # longe da lua e da copa
			_stars.append({"p": p, "row": 1 if rng.randf() < 0.25 else 0, "phase": rng.randf() * 10.0, "speed": rng.randf_range(0.12, 0.35)})

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		if wide:
			draw_texture(_sky_wide, Vector2.ZERO)
		elif _sky != null:
			draw_texture(_sky, Vector2.ZERO)
		else:
			draw_rect(Rect2(0, 0, 640, 128), Palette.color(Palette.BG))
		for s: Dictionary in _stars:
			var frame := 1 if sin(_t * float(s.speed) * TAU + float(s.phase)) > 0.4 else 0
			if _star_tex != null:
				TreeArt.draw_cell(self, _star_tex, Vector2(5, 5), frame, int(s.row), s.p as Vector2, Vector2(2, 2))
			else:
				draw_rect(Rect2(s.p as Vector2, Vector2.ONE), Palette.color(Palette.STONE_LIGHT if frame == 1 else Palette.STONE_DARK))


## Copa do ipê em ping-pong (MANIFEST tree_canopy: 3 frames de 400 ms), por cima do tronco.
class Canopy:
	extends Node2D

	var _t: float = 0.0
	var _tex: Texture2D = TreeArt.tex("tree_canopy.png")

	func _process(delta: float) -> void:
		var before := int(_t / 0.4)
		_t += delta * (0.0 if Juice.reduce_motion() else 1.0)
		if int(_t / 0.4) != before:
			queue_redraw()

	func _draw() -> void:
		var f := TreeArt.pingpong(_t, 3, 0.4)
		TreeArt.draw_cell(self, _tex, TreeArt.CANOPY_FRAME, f, 0, TreeArt.CANOPY_POS)
