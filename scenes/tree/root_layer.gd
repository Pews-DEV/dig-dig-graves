class_name RootLayer
extends Node2D
## Raízes da Árvore desenhadas por código (UI/UX §7.2, MANIFEST tree_roots: miolo 2 px, brilho
## acima/à esquerda e sombra abaixo/à direita, luz NO). Não compradas 18/19 paradas; compradas
## 17/20 com seiva luminosa viajando da mãe para o filho. Ao revelar, a raiz cresce (350 ms).
## Também desenha o halo âmbar em xadrez (24, raio 17–23) dos nós comprados.

const GROW_TIME := 0.35
const SAP_EVERY := 1.5
const SAP_SPEED := 46.0  # px/s ao longo da raiz
const HALO_IN := 17.0
const HALO_OUT := 23.0
## [brilho, miolo, sombra]
const COLORS_OFF: Array[int] = [Palette.COFFIN, Palette.COFFIN_DARK, Palette.OUTLINE]
const COLORS_ON: Array[int] = [Palette.DIRT_EDGE, Palette.COFFIN_LIGHT, Palette.COFFIN]

## key -> {points: Array[Vector2i], steep: Array[bool], bought: bool, grow: float}
var roots: Dictionary = {}
var halos: Array[Vector2] = []
var _sap: SapLayer
var _bits: Array[Dictionary] = []


func _ready() -> void:
	_sap = SapLayer.new()
	_sap.layer = self
	add_child(_sap)


## Redefine as raízes. `list` = [{key, from, to, bought}]. Mantém o crescimento em curso.
func set_roots(list: Array[Dictionary]) -> void:
	var next: Dictionary = {}
	for r: Dictionary in list:
		var key: String = r.key
		var old: Dictionary = roots.get(key, {})
		var path := _path(r.from as Vector2, r.to as Vector2)
		next[key] = {
			"points": path[0], "steep": path[1], "bought": bool(r.bought),
			"grow": float(old.get("grow", 1.0)),
			"sap_t": float(old.get("sap_t", randf() * SAP_EVERY)),
		}
	roots = next
	queue_redraw()


func set_halos(points: Array[Vector2]) -> void:
	halos = points
	queue_redraw()


## Começa o crescimento da raiz `key` (da origem até o filho, ease-out).
func grow(key: String) -> void:
	if not roots.has(key):
		return
	var r: Dictionary = roots[key]
	r.grow = 0.0
	var step := func(v: float) -> void:
		r.grow = v
		_dirt_at_tip(r)
		queue_redraw()
	var t := create_tween()
	t.tween_method(step, 0.0, 1.0, GROW_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _dirt_at_tip(r: Dictionary) -> void:
	if randf() > 0.5 * Juice.motion() + 0.1:
		return
	var pts: Array = r.points
	var i := clampi(int(pts.size() * float(r.grow)) - 1, 0, pts.size() - 1)
	var p: Vector2i = pts[i]
	_bits.append({"pos": Vector2(p), "vel": Vector2(randf_range(-30, 30), randf_range(-50, -20)), "age": 0.0,
		"color": [Palette.DIRT, Palette.DIRT_LIGHT, Palette.DIRT_DARK][randi() % 3]})


## Caminho em pixels inteiros (TreeLayout.root_path, testável sem cena).
static func _path(a: Vector2, b: Vector2) -> Array:
	return TreeLayout.root_path(a, b)


func _process(delta: float) -> void:
	if _bits.is_empty():
		return
	for b: Dictionary in _bits:
		b.age = float(b.age) + delta
		var v: Vector2 = b.vel
		v.y += 220.0 * delta
		b.vel = v
		b.pos = (b.pos as Vector2) + v * delta
	_bits = _bits.filter(func(b: Dictionary) -> bool: return float(b.age) < 0.45)
	queue_redraw()


func _draw() -> void:
	_draw_halos()
	for key: String in roots:
		_draw_root(roots[key] as Dictionary, true)
	for key: String in roots:
		_draw_root(roots[key] as Dictionary, false)
	for b: Dictionary in _bits:
		draw_rect(Rect2((b.pos as Vector2).floor(), Vector2.ONE), Palette.color(int(b.color)))


func _draw_root(r: Dictionary, edges: bool) -> void:
	var pts: Array = r.points
	var steep: Array = r.steep
	var colors: Array[int] = COLORS_ON if bool(r.bought) else COLORS_OFF
	var n := int(ceilf(pts.size() * float(r.grow)))
	for i: int in n:
		var p: Vector2i = pts[i]
		var s: bool = steep[i]
		if edges:
			if s:
				draw_rect(Rect2(p.x - 2, p.y, 1, 1), Palette.color(colors[0]))
				draw_rect(Rect2(p.x + 1, p.y, 1, 1), Palette.color(colors[2]))
			else:
				draw_rect(Rect2(p.x, p.y - 2, 1, 1), Palette.color(colors[0]))
				draw_rect(Rect2(p.x, p.y + 1, 1, 1), Palette.color(colors[2]))
		else:
			if s:
				draw_rect(Rect2(p.x - 1, p.y, 2, 1), Palette.color(colors[1]))
			else:
				draw_rect(Rect2(p.x, p.y - 1, 1, 2), Palette.color(colors[1]))


## Halo âmbar em xadrez em volta dos nós comprados (mais ralo para fora).
func _draw_halos() -> void:
	var c := Palette.color(Palette.LANTERN_DARK)
	for h: Vector2 in halos:
		var cx := int(h.x)
		var cy := int(h.y)
		var r := int(HALO_OUT)
		for y: int in range(-r, r + 1):
			for x: int in range(-r, r + 1):
				var d := Vector2(x, y).length()
				if d < HALO_IN or d > HALO_OUT:
					continue
				if (x + y) % 2 != 0:
					continue
				if d > 20.0 and (x % 4 != 0 or y % 2 != 0) and (x + 2) % 4 != 0:
					continue
				draw_rect(Rect2(cx + x, cy + y, 1, 1), c)


## Seiva luminosa: pontos 2×2 (23/26) com rastro 25/24 viajando nas raízes compradas.
class SapLayer:
	extends Node2D

	var layer: RootLayer
	var _t: float = 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		if layer == null:
			return
		for key: String in layer.roots:
			var r: Dictionary = layer.roots[key]
			if not bool(r.bought) or float(r.grow) < 1.0:
				continue
			var pts: Array = r.points
			var travel := pts.size() / RootLayer.SAP_SPEED
			var period := maxf(RootLayer.SAP_EVERY, travel)
			var local := fmod(_t + float(r.sap_t), period)
			if local > travel:
				continue
			var i := int(local * RootLayer.SAP_SPEED)
			for k: int in [3, 2, 1]:
				var j := i - k * 2
				if j >= 0 and j < pts.size():
					var c := Palette.LANTERN if k == 1 else Palette.LANTERN_DARK
					draw_rect(Rect2(Vector2(pts[j] as Vector2i), Vector2.ONE), Palette.color(c))
			if i < pts.size():
				var p: Vector2i = pts[i]
				draw_rect(Rect2(p.x, p.y - 1, 2, 2), Palette.color(Palette.LANTERN_BRIGHT))
				draw_rect(Rect2(p.x, p.y - 1, 1, 1), Palette.color(Palette.BONE_BRIGHT))
