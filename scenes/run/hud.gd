class_name Hud
extends CanvasLayer
## HUD do turno redesenhado (UI/UX §4, GDD §15.2): tudo em plaquetas de madeira, margem 6 px.
## Topo: recursos do turno · medalha de nível + XP · Inquietação. Base: lanterna + óleo.
## Recursos chegam voando do campo; o número só sobe quando o ícone chega.

const MARGIN := 6
## MANIFEST plaqueta: altura padrão 24; área útil y = 3 até altura − 6.
const PLAQUE_H := 24
const TEXT_Y := 1
## Faixa livre para a grade entre as plaquetas (UI/UX §5 "Enquadramento").
const FREE_TOP := MARGIN + PLAQUE_H
const FREE_BOTTOM := 360 - MARGIN - PLAQUE_H
const OIL_DANGER := 0.25  # DA §3.2 / UI/UX §4: alerta < 25%
const UNREST_ALERT := 0.8
const OIL_FILL := "res://assets/ui/hud/barra_oleo.png"
const OIL_FILL_DANGER := "res://assets/ui/hud/barra_oleo_alerta.png"
const ENTER_OFFSET := 28.0
const ENTER_STAGGER := 0.04
const FLY_MIN := 0.4
const FLY_MAX := 0.6
const MAX_FLYING := 24
const PICKUP_SFX: Dictionary = {
	ResourceIcon.Kind.COPPER: &"pickup_copper",
	ResourceIcon.Kind.BONES: &"pickup_bone",
	ResourceIcon.Kind.SOULS: &"pickup_soul",
}

var _root: Control
var _top_plaques: Array[Control] = []
var _bottom_plaques: Array[Control] = []
var _icons: Dictionary = {}  # Kind -> ResourceIcon
var _numbers: Dictionary = {}  # Kind -> Label
var _real: Dictionary = {}  # Kind -> valor do turno
var _flight: Dictionary = {}  # Kind -> valor ainda voando
var _shown_text: Dictionary = {}
var _flash_t: Dictionary = {}
var _flying: int = 0
var _medal: HudMedal
var _xp_bar: PixelBar
var _unrest_bar: PixelBar
var _skull: TextureRect
var _skull_base: Vector2
var _lantern: HudLantern
var _oil_bar: PixelBar
var _oil_label: Label
var _toast: Label
var _toast_time: float = 0.0
var _options: OptionsMenu
var _t: float = 0.0
var _last_oil_second: int = -1
var _level: int = 1


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = UiTheme.get_theme()
	add_child(_root)
	_build_resources()
	_build_level()
	_build_unrest()
	_build_oil()

	_toast = Label.new()
	_toast.theme_type_variation = &"TitleLabel"
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.position = Vector2(0, 36)
	_toast.size = Vector2(640, 20)
	_toast.visible = false
	_root.add_child(_toast)

	_options = OptionsMenu.new()
	_options.show_title_button = true
	add_child(_options)

	Events.field_cleared.connect(_on_field_cleared)
	Events.run_level_up.connect(_on_level_up)
	play_enter()


# --- Montagem -----------------------------------------------------------------------

func _plaque(rect: Rect2, top: bool) -> Control:
	var holder := Control.new()
	holder.position = rect.position
	holder.size = rect.size
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := NinePatchRect.new()
	bg.texture = UiKit.plaque_texture()
	var m := UiKit.plaque_margins()
	bg.patch_margin_left = m.x
	bg.patch_margin_top = m.y
	bg.patch_margin_right = m.z
	bg.patch_margin_bottom = m.w
	bg.size = rect.size
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(bg)
	_root.add_child(holder)
	(_top_plaques if top else _bottom_plaques).append(holder)
	return holder


func _number(parent: Control, pos: Vector2, width: float) -> Label:
	var l := Label.new()
	l.theme_type_variation = &"HudNumber"
	l.position = pos
	l.size = Vector2(width, 18)
	l.text = "0"
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


func _build_resources() -> void:
	var p := _plaque(Rect2(MARGIN, MARGIN, 180, PLAQUE_H), true)
	var kinds: Array[ResourceIcon.Kind] = [ResourceIcon.Kind.COPPER, ResourceIcon.Kind.BONES, ResourceIcon.Kind.SOULS]
	var widths: Array[float] = [64.0, 54.0, 48.0]
	var x := 7.0
	for i: int in kinds.size():
		var k := kinds[i]
		var icon := ResourceIcon.new()
		icon.kind = k
		icon.position = Vector2(x, 3)
		p.add_child(icon)
		_icons[k] = icon
		_numbers[k] = _number(p, Vector2(x + 18, TEXT_Y), widths[i] - 20.0)
		_real[k] = 0.0
		_flight[k] = 0.0
		x += widths[i]


func _build_level() -> void:
	var p := _plaque(Rect2(232, MARGIN, 180, PLAQUE_H), true)
	_medal = HudMedal.new()
	_medal.position = Vector2(3, 0)
	p.add_child(_medal)
	_xp_bar = _bar(p, Rect2(32, 6, 120, 10), "res://assets/ui/hud/barra_xp.png", Palette.SOUL, Palette.BONE_BRIGHT)
	var xp := _number(p, Vector2(155, TEXT_Y), 20)
	xp.text = "XP"


func _build_unrest() -> void:
	var p := _plaque(Rect2(640 - MARGIN - 140, MARGIN, 140, PLAQUE_H), true)
	_skull = TextureRect.new()
	_skull.texture = UiKit.skull_texture()
	_skull.position = Vector2(7, 3)
	_skull.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_skull_base = _skull.position
	p.add_child(_skull)
	_unrest_bar = _bar(p, Rect2(26, 6, 106, 10), "res://assets/ui/hud/barra_inquietacao.png", Palette.ECTO, Palette.ECTO_BRIGHT)


func _build_oil() -> void:
	var p := _plaque(Rect2(176, 360 - MARGIN - PLAQUE_H, 288, PLAQUE_H), false)
	_lantern = HudLantern.new()
	_lantern.position = Vector2(4, -2)
	p.add_child(_lantern)
	_oil_bar = _bar(p, Rect2(30, 6, 218, 10), OIL_FILL, Palette.LANTERN, Palette.LANTERN_BRIGHT)
	_oil_label = _number(p, Vector2(248, TEXT_Y), 32)
	_oil_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT


func _bar(parent: Control, rect: Rect2, tex: String, fill: int, highlight: int) -> PixelBar:
	var b := PixelBar.new()
	b.position = rect.position
	b.size = rect.size
	b.fill_color = fill
	b.highlight_color = highlight
	b.fill_texture_path = tex
	b.value = 0.0
	parent.add_child(b)
	return b


# --- Entrada e saída (UI/UX §4) -------------------------------------------------------

func play_enter() -> void:
	var i := 0
	for p: Control in _top_plaques:
		Juice.slide_in(p, Vector2(0, -ENTER_OFFSET), i * ENTER_STAGGER)
		i += 1
	for p: Control in _bottom_plaques:
		Juice.slide_in(p, Vector2(0, ENTER_OFFSET), i * ENTER_STAGGER)
		i += 1


## O inverso da entrada. Retorna o último tween (aguarde `finished`).
func play_exit() -> Tween:
	var last: Tween
	var i := 0
	for p: Control in _top_plaques:
		last = Juice.slide_out(p, Vector2(0, -ENTER_OFFSET - 8), i * ENTER_STAGGER)
		i += 1
	for p: Control in _bottom_plaques:
		last = Juice.slide_out(p, Vector2(0, ENTER_OFFSET + 8), i * ENTER_STAGGER)
		i += 1
	return last


# --- Valores ------------------------------------------------------------------------

## Atualiza valores contínuos a partir do estado do turno (chamado pela cena Run).
func refresh(state: RunState) -> void:
	var r := state.result
	_real[ResourceIcon.Kind.COPPER] = r.copper_mined + r.field_clear_bonus
	_real[ResourceIcon.Kind.BONES] = r.bones
	_real[ResourceIcon.Kind.SOULS] = r.souls
	for k: int in _numbers:
		_update_number(k)
	_level = state.level
	_medal.level = state.level
	_xp_bar.value = state.xp / state.xp_needed(state.level)
	_unrest_bar.value = state.unrest
	var frac := state.oil_fraction()
	_oil_bar.value = frac
	var danger := frac < OIL_DANGER and not state.ended
	_lantern.alert = danger
	var fill := OIL_FILL_DANGER if danger else OIL_FILL
	if _oil_bar.fill_texture_path != fill:
		_oil_bar.fill_texture_path = fill
	_oil_bar.fill_color = Palette.DANGER if danger else Palette.LANTERN
	# UI/UX §4: abaixo de 25% a barra alterna 31/32 a 2 Hz e os segundos ficam em 32.
	_oil_bar.override_color = Palette.DANGER_DARK if danger and int(_t * 4.0) % 2 == 1 else 0
	_oil_label.add_theme_color_override("font_color", Palette.color(Palette.DANGER if danger else Palette.BONE))
	var secs := ceili(state.oil - 0.0001)
	_oil_label.text = "%d s" % secs
	# Tique por segundo nos últimos 3 s.
	if secs != _last_oil_second:
		if _last_oil_second > 0 and secs <= 3 and secs > 0 and not state.ended:
			Audio.play(&"oil_tick")
		_last_oil_second = secs


func _display_value(k: int) -> float:
	return maxf(0.0, float(_real[k]) - float(_flight[k]))


func _update_number(k: int) -> void:
	var text := NumberFormat.format(_display_value(k))
	if _shown_text.get(k, "") == text:
		return
	var grew := _shown_text.has(k)
	_shown_text[k] = text
	var label: Label = _numbers[k]
	label.text = text
	if grew:
		Juice.nudge(label, Vector2(0, -2))
		if not Juice.reduce_flashes():
			label.add_theme_color_override("font_color", Palette.color(Palette.LANTERN_BRIGHT))
			_flash_t[k] = 0.05


## Recurso voando de um ponto da tela até o ícone do HUD (DA §9.2: curva, 400–600 ms).
## `value` só aparece no número quando o ícone chega.
func fly(kind: ResourceIcon.Kind, from_screen: Vector2, value: float) -> void:
	if not _icons.has(kind) or value <= 0.0:
		return
	if _flying >= MAX_FLYING:
		return  # acima do limite o número já sobe direto (não entra em _flight)
	var icon: ResourceIcon = _icons[kind]
	var f := FlyingIcon.new()
	f.kind = kind
	f.value = value
	_root.add_child(f)
	_flight[kind] = float(_flight[kind]) + value
	_flying += 1
	f.arrived.connect(_on_icon_arrived)
	f.launch(from_screen, icon.get_global_rect().get_center(), randf_range(FLY_MIN, FLY_MAX))


func _on_icon_arrived(f: FlyingIcon) -> void:
	_flying -= 1
	_flight[f.kind] = maxf(0.0, float(_flight[f.kind]) - f.value)
	_update_number(f.kind)
	var icon: ResourceIcon = _icons[f.kind]
	Juice.squash(icon, Vector2(1.25, 0.75), 0.05, 0.14)
	Audio.play(PICKUP_SFX.get(f.kind, &"pickup_copper"))


## Fim do turno: nada pode ficar "no ar".
func settle() -> void:
	for k: int in _flight:
		_flight[k] = 0.0
		_update_number(k)


# --- Pausa e avisos -------------------------------------------------------------------

func open_options() -> void:
	_options.open()


func options() -> OptionsMenu:
	return _options


func show_toast(text: String, duration: float = 1.4) -> void:
	_toast.text = text
	_toast.visible = true
	_toast_time = duration
	Juice.pop(_toast, 0.2, 0.2)


func _process(delta: float) -> void:
	_t += delta
	if _toast_time > 0.0:
		_toast_time -= delta
		if _toast_time <= 0.0:
			_toast.visible = false
	for k: int in _flash_t.keys():
		_flash_t[k] = float(_flash_t[k]) - delta
		if float(_flash_t[k]) <= 0.0:
			_flash_t.erase(k)
			(_numbers[k] as Label).remove_theme_color_override("font_color")
	# UI/UX §4: Inquietação > 80% pulsa a 1 Hz e a caveira treme 1 px.
	var alert := _unrest_bar.value >= UNREST_ALERT
	_unrest_bar.override_color = Palette.ECTO_BRIGHT if alert and fmod(_t, 1.0) < 0.5 and not Juice.reduce_flashes() else 0
	if alert and not Juice.reduce_motion():
		_skull.position = _skull_base + Vector2(randi_range(-1, 1), 0) if int(_t * 12.0) % 2 == 0 else _skull_base
	else:
		_skull.position = _skull_base


func _on_field_cleared(bonus: float) -> void:
	show_toast("CAMPO LIMPO!  +%s" % NumberFormat.format(bonus), 1.8)


func _on_level_up(level: int) -> void:
	_medal.level = level
	_medal.jump()
	Audio.play(&"level_up")
	Audio.play(&"stinger_level")
	if not Juice.reduce_flashes():
		var t := create_tween()
		t.tween_property(_xp_bar, "sweep", 1.0, 0.6).from(0.0)
		t.tween_callback(func() -> void: _xp_bar.sweep = -1.0)
	_rising_text("NÍVEL %d!" % level, _medal.get_global_rect().get_center() + Vector2(0, 30))


## Texto que sobe e some em 2 passos de cor (paleta fechada, sem alfa).
func _rising_text(text: String, from: Vector2) -> void:
	var l := Label.new()
	l.theme_type_variation = &"TitleLabel"
	l.text = text
	l.add_theme_color_override("font_color", Palette.color(Palette.LANTERN_BRIGHT))
	_root.add_child(l)
	l.position = (from - Vector2(l.get_minimum_size().x * 0.5, 0)).round()
	var t := l.create_tween()
	t.tween_property(l, "position:y", l.position.y - 10.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_callback(func() -> void: l.add_theme_color_override("font_color", Palette.color(Palette.LANTERN))).set_delay(0.4)
	t.tween_callback(l.queue_free)
