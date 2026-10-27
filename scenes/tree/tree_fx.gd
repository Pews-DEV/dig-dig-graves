class_name TreeFx
extends Node2D
## Efeitos de compra e revelação da Árvore (UI/UX §7.3), no mundo: explosão de pétalas e
## faíscas (fx_tree_buy_burst) e terrinha de broto (fx_tree_sprout). Placeholder por código.

const BURST_FRAME := Vector2(32, 32)
const BURST_STEP := 0.05
const BURST_FRAMES := 6
const SPROUT_FRAME := Vector2(24, 12)
const SPROUT_STEP := 0.08
const SPROUT_FRAMES := 4
const SPROUT_HOLD := 0.6

var _burst_tex: Texture2D = TreeArt.tex("fx_buy_burst.png")
var _sprout_tex: Texture2D = TreeArt.tex("fx_sprout.png")
var _items: Array[Dictionary] = []
var _sparks: Array[Dictionary] = []


func burst(center: Vector2, small: bool = false) -> void:
	if Juice.reduce_flashes() and small:
		return
	_items.append({"kind": "burst", "pos": center, "age": 0.0})
	var count := roundi((4 if small else 10) * maxf(Juice.motion(), 0.5))
	for i: int in count:
		var a := randf() * TAU
		var v := Vector2(cos(a), sin(a)) * randf_range(30.0, 70.0)
		_sparks.append({"pos": center, "vel": v, "age": 0.0, "life": randf_range(0.3, 0.55),
			"color": [Palette.MOONSHADOW, Palette.STONE_LIGHT, Palette.LANTERN_BRIGHT, Palette.BONE_BRIGHT][randi() % 4]})


## Broto: montinho de terra sob o medalhão enquanto ele cresce (base em centro + (0, 16)).
func sprout(center: Vector2, delay: float = 0.0) -> void:
	_items.append({"kind": "sprout", "pos": center + Vector2(0, 16), "age": -delay})


func _process(delta: float) -> void:
	if _items.is_empty() and _sparks.is_empty():
		return
	for it: Dictionary in _items:
		it.age = float(it.age) + delta
	_items = _items.filter(func(it: Dictionary) -> bool:
		var life := BURST_STEP * BURST_FRAMES if String(it.kind) == "burst" else SPROUT_STEP * SPROUT_FRAMES + SPROUT_HOLD
		return float(it.age) < life)
	for s: Dictionary in _sparks:
		s.age = float(s.age) + delta
		var v: Vector2 = s.vel
		v *= exp(-3.0 * delta)
		v.y += 60.0 * delta
		s.vel = v
		s.pos = (s.pos as Vector2) + v * delta
	_sparks = _sparks.filter(func(s: Dictionary) -> bool: return float(s.age) < float(s.life))
	queue_redraw()


func _draw() -> void:
	for it: Dictionary in _items:
		var age := float(it.age)
		if age < 0.0:
			continue
		var pos: Vector2 = it.pos
		if String(it.kind) == "burst":
			var f := clampi(int(age / BURST_STEP), 0, BURST_FRAMES - 1)
			if _burst_tex != null and not Juice.reduce_flashes():
				TreeArt.draw_cell(self, _burst_tex, BURST_FRAME, f, 0, pos, Vector2(16, 16))
			elif not Juice.reduce_flashes():
				IsoDraw.outline_diamond(self, pos.round(), 8 + f * 4, Palette.color(Palette.BONE_BRIGHT))
		else:
			var f2 := clampi(int(age / SPROUT_STEP), 0, SPROUT_FRAMES - 1)
			if _sprout_tex != null:
				TreeArt.draw_cell(self, _sprout_tex, SPROUT_FRAME, f2, 0, pos, Vector2(12, 11))
			else:
				draw_rect(Rect2(pos + Vector2(-6, -2 - f2), Vector2(12, 2 + f2)), Palette.color(Palette.DIRT))
	for s: Dictionary in _sparks:
		draw_rect(Rect2((s.pos as Vector2).floor(), Vector2.ONE), Palette.color(int(s.color)))
