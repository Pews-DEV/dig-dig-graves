class_name Juice
extends RefCounted
## Presets centrais de animação de interface (UI/UX §6). Todo "juice" do jogo passa por aqui,
## então "reduzir movimento" (escala/tremor a 25%) e "reduzir flashes" valem em todo lugar.

const HOVER_TIME := 0.08
const CLICK_DOWN := 0.06
const CLICK_UP := 0.12
const PANEL_OPEN := 0.18
const PANEL_CLOSE := 0.12
const POP_TIME := 0.14
const NUDGE_TIME := 0.12
const COUNT_MAX := 1.2
const SLIDE_TIME := 0.25
const BECKON_EVERY := 2.0
const BECKON_TIME := 0.3


static func motion() -> float:
	return GameSettings.motion_factor(Game.settings)


static func reduce_motion() -> bool:
	return bool(Game.settings.get("reduce_motion", false))


static func reduce_flashes() -> bool:
	return bool(Game.settings.get("reduce_flashes", false))


static func _center_pivot(c: CanvasItem) -> void:
	if c is Control:
		(c as Control).pivot_offset = ((c as Control).size * 0.5).floor()


static func _kill(node: Node, key: StringName) -> void:
	if node.has_meta(key):
		var old: Variant = node.get_meta(key)
		if old is Tween and (old as Tween).is_valid():
			(old as Tween).kill()


static func _track(node: Node, key: StringName, t: Tween) -> Tween:
	node.set_meta(key, t)
	return t


## Pop rápido de escala 1 → 1+a → 1 (UI/UX §1.5: nada fica escalado em repouso).
static func pop(c: CanvasItem, amount: float = 0.1, time: float = POP_TIME) -> void:
	if c == null or not c.is_inside_tree():
		return
	_kill(c, &"juice_scale")
	_center_pivot(c)
	var a := amount * motion()
	c.set("scale", Vector2.ONE)
	var t := c.create_tween()
	t.tween_property(c, "scale", Vector2.ONE * (1.0 + a), time * 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(c, "scale", Vector2.ONE, time * 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_track(c, &"juice_scale", t)


## Squash e volta com overshoot (clique, compra, "engolir" ícone).
static func squash(c: CanvasItem, to: Vector2 = Vector2(1.08, 0.88), down: float = CLICK_DOWN, up: float = CLICK_UP) -> void:
	if c == null or not c.is_inside_tree():
		return
	_kill(c, &"juice_scale")
	_center_pivot(c)
	var target := Vector2.ONE.lerp(to, motion())
	var t := c.create_tween()
	t.tween_property(c, "scale", target, down).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(c, "scale", Vector2.ONE, up).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_track(c, &"juice_scale", t)


## Desloca um nó (posição absoluta, fora de containers) e volta. Base guardada em meta.
static func nudge(c: CanvasItem, offset: Vector2, time: float = NUDGE_TIME) -> void:
	if c == null or not c.is_inside_tree():
		return
	_kill(c, &"juice_pos")
	if not c.has_meta(&"juice_base"):
		c.set_meta(&"juice_base", c.get("position"))
	var base: Vector2 = c.get_meta(&"juice_base")
	c.set("position", base)
	var t := c.create_tween()
	t.tween_property(c, "position", base + offset.round(), time * 0.35)
	t.tween_property(c, "position", base, time * 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_track(c, &"juice_pos", t)


## Base de posição de um nó animado por nudge (atualize ao reposicionar).
static func set_base(c: CanvasItem, pos: Vector2) -> void:
	_kill(c, &"juice_pos")
	c.set_meta(&"juice_base", pos)
	c.set("position", pos)


## Entrada deslizando de `offset` (plaquetas do HUD: ±28 px, 250 ms, back-out).
static func slide_in(c: Control, offset: Vector2, delay: float = 0.0, time: float = SLIDE_TIME) -> Tween:
	var base := c.position
	c.position = base + offset
	var t := c.create_tween()
	t.tween_interval(delay)
	t.tween_property(c, "position", base, time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return t


static func slide_out(c: Control, offset: Vector2, delay: float = 0.0, time: float = SLIDE_TIME) -> Tween:
	var t := c.create_tween()
	t.tween_interval(delay)
	t.tween_property(c, "position", c.position + offset, time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	return t


## Abrir painel: escala 0,9 → 1 + fade + desliza 6 px (180 ms, back-out).
static func panel_open(c: Control, slide: Vector2 = Vector2(0, 6), sound: bool = true) -> Tween:
	_kill(c, &"juice_panel")
	c.visible = true
	_center_pivot(c)
	var base: Vector2 = c.get_meta(&"panel_base", c.position)
	c.set_meta(&"panel_base", base)
	var m := motion()
	c.scale = Vector2.ONE * lerpf(1.0, 0.9, m)
	c.modulate.a = 0.0
	c.position = base + (slide * m).round()
	var t := c.create_tween().set_parallel(true)
	t.tween_property(c, "scale", Vector2.ONE, PANEL_OPEN).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(c, "modulate:a", 1.0, PANEL_OPEN)
	t.tween_property(c, "position", base, PANEL_OPEN).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if sound:
		Audio.play(&"ui_panel_open")
	return _track(c, &"juice_panel", t)


## Fechar painel: 1 → 0,95 + fade (120 ms, ease-in); some no fim.
static func panel_close(c: Control, sound: bool = true) -> Tween:
	_kill(c, &"juice_panel")
	_center_pivot(c)
	var t := c.create_tween().set_parallel(true)
	t.tween_property(c, "scale", Vector2.ONE * lerpf(1.0, 0.95, motion()), PANEL_CLOSE).set_ease(Tween.EASE_IN)
	t.tween_property(c, "modulate:a", 0.0, PANEL_CLOSE).set_ease(Tween.EASE_IN)
	t.chain().tween_callback(func() -> void: c.visible = false)
	if sound:
		Audio.play(&"ui_panel_close")
	return _track(c, &"juice_panel", t)


## Contador animado de `from` até `to` (ease-out, máx. 1,2 s), com tique por incremento (≤ 20/s).
static func count(label: Label, from: float, to: float, duration: float = COUNT_MAX, fmt: Callable = NumberFormat.format, tick: bool = true) -> Tween:
	_kill(label, &"juice_count")
	var state := {"last": fmt.call(from)}
	label.text = String(state.last)
	var step := func(v: float) -> void:
		var s: String = fmt.call(v)
		if s != String(state.last):
			state.last = s
			label.text = s
			if tick:
				Audio.play_tick()
	var t := label.create_tween()
	t.tween_method(step, from, to, minf(duration, COUNT_MAX)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return _track(label, &"juice_count", t)


## Duração do contador proporcional ao valor (valores pequenos contam rápido).
static func count_duration(value: float) -> float:
	return clampf(0.25 + absf(value) * 0.02, 0.25, COUNT_MAX)


## Botão "chamando" (ex.: Cavar sem nada para comprar): balanço ±1 px a cada 2 s.
static func beckon(c: Control) -> Tween:
	_kill(c, &"juice_beckon")
	var t := c.create_tween().set_loops()
	t.tween_interval(BECKON_EVERY - BECKON_TIME)
	var step := BECKON_TIME / 4.0
	t.tween_property(c, "rotation", deg_to_rad(2.0) * motion(), step)
	t.tween_property(c, "rotation", -deg_to_rad(2.0) * motion(), step * 2.0)
	t.tween_property(c, "rotation", 0.0, step)
	_center_pivot(c)
	return _track(c, &"juice_beckon", t)


static func stop_beckon(c: Control) -> void:
	_kill(c, &"juice_beckon")
	c.rotation = 0.0


# --- Botões: comportamento padrão de hover e clique (UI/UX §6) -------------------------

## Liga hover (som; o degrau de 1 px e a borda 26 vêm do estilo) e clique (squash + "toc").
static func attach_button(b: BaseButton) -> void:
	if b.has_meta(&"juiced"):
		return
	b.set_meta(&"juiced", true)
	var on_hover := func() -> void:
		if not b.disabled:
			Audio.play(&"ui_hover")
	var on_down := func() -> void:
		if not b.disabled:
			Audio.play(&"ui_click")
			squash(b, Vector2(1.04, 0.9), CLICK_DOWN, 0.001)
	var on_up := func() -> void:
		_kill(b, &"juice_scale")
		_center_pivot(b)
		var t := b.create_tween()
		t.tween_property(b, "scale", Vector2.ONE, CLICK_UP).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_track(b, &"juice_scale", t)
	b.mouse_entered.connect(on_hover)
	b.button_down.connect(on_down)
	b.button_up.connect(on_up)
