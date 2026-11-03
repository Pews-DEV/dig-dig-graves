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
## UI/UX §13.2: barra do chefe 320 px no topo central, logo abaixo da 1ª fileira.
const BOSS_RECT := Rect2(160, MARGIN + PLAQUE_H + 2, 320, PLAQUE_H)
## Faixa livre para o campo na Noite do Chefe (abaixo da barra do chefe).
const BOSS_FREE_TOP := MARGIN + PLAQUE_H + 2 + PLAQUE_H
const BOSS_GHOST_HOLD := 0.4
const BOSS_GHOST_DRAIN := 0.3
## UI/UX §13.1: "A terra treme…" pisca 3× ao chegar a 100%.
const UNREST_BLINKS := 3
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
var _grave_tooltip: PanelContainer
var _grave_tooltip_title: Label
var _grave_tooltip_effect: Label
var _options: OptionsMenu
var _t: float = 0.0
var _last_oil_second: int = -1
var _level: int = 1
var _boss_bar: PixelBar
var _boss_label: Label
var _boss_hp_label: Label
var _boss_icon: TextureRect
var _boss_plaque: Control
var _boss_ghost_tween: Tween
var _boss_hit_limiter := RateLimiter.new(8.0)
var _unrest_label: Label
var _unrest_blinks: float = 0.0
var _unrest_shown: bool = false
var _oil_frozen: bool = false
var _stomp_button: TextureButton
var _stomp_icon: TextureRect
var _stomp_atlas: Texture2D
var _stomp_pips_atlas: Texture2D
var _stomp_pips: Array[TextureRect] = []
var _stomp_glow: _StompGlow


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
	_build_grave_tooltip()

	_options = OptionsMenu.new()
	_options.show_title_button = true
	_options.show_abandon_button = true
	_options.confirm_title = true
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
	if not Game.tree.has_flag(&"epitaphs"):
		return
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
	_unrest_label = Label.new()
	_unrest_label.text = tr("A terra treme…")
	_unrest_label.theme_type_variation = &"HudNumber"
	_unrest_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_unrest_label.position = Vector2(640 - MARGIN - 140, MARGIN + PLAQUE_H)
	_unrest_label.size = Vector2(136, 14)
	_unrest_label.add_theme_color_override("font_color", Palette.color(Palette.DANGER))
	_unrest_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_unrest_label.visible = false
	_root.add_child(_unrest_label)


func _build_oil() -> void:
	var p := _plaque(Rect2(176, 360 - MARGIN - PLAQUE_H, 288, PLAQUE_H), false)
	_lantern = HudLantern.new()
	_lantern.position = Vector2(4, -2)
	p.add_child(_lantern)
	_oil_bar = _bar(p, Rect2(30, 6, 218, 10), OIL_FILL, Palette.LANTERN, Palette.LANTERN_BRIGHT)
	_oil_label = _number(p, Vector2(248, TEXT_Y), 32)
	_oil_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT


## UI/UX §13.2: plaqueta larga no topo central, abaixo da fileira de cima (no Marco A não há
## medalha de nível; a 1ª fileira já tem recursos e Inquietação).
func show_boss(hp: float, max_hp: float, boss_name: String = "O Caixão Fujão", icon_id: String = "icon_boss_caixao") -> void:
	if _boss_bar != null:
		update_boss(hp, max_hp)
		return
	var plaque := _plaque(Rect2(BOSS_RECT.position, BOSS_RECT.size), true)
	_boss_plaque = plaque
	_boss_icon = TextureRect.new()
	_boss_icon.texture = AssetManifest.texture_by_id(icon_id)
	_boss_icon.position = Vector2(5, 4)
	_boss_icon.size = Vector2(16, 16)
	_boss_icon.pivot_offset = Vector2(8, 8)
	_boss_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	plaque.add_child(_boss_icon)
	_boss_label = Label.new()
	_boss_label.text = boss_name
	_boss_label.position = Vector2(24, TEXT_Y)
	_boss_label.size = Vector2(106, 18)
	plaque.add_child(_boss_label)
	_boss_bar = _bar(plaque, Rect2(132, 7, 146, 10), "", Palette.DANGER_DARK, Palette.DANGER)
	_boss_bar.frame_texture_path = "res://assets/ui/hud/barra_chefe.png"
	_boss_bar.ghost_color = Palette.BONE
	_boss_hp_label = _number(plaque, Vector2(278, TEXT_Y), 38)
	_boss_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	update_boss(hp, max_hp)
	# Entrada: desce de −28 px em 300 ms junto com o stinger.
	Juice.slide_in(plaque, Vector2(0, -ENTER_OFFSET), 0.0, 0.3)
	Audio.play(&"stinger_boss_appear")


func update_boss(hp: float, max_hp: float) -> void:
	if _boss_bar == null:
		return
	var ratio := clampf(hp / maxf(1.0, max_hp), 0.0, 1.0)
	if ratio < _boss_bar.value - 0.000001:
		# Dano atrasado: o "fantasma" 22 fica 400 ms e escorre até o valor real.
		if _boss_bar.ghost < _boss_bar.value:
			_boss_bar.ghost = _boss_bar.value
		if _boss_ghost_tween != null:
			_boss_ghost_tween.kill()
		_boss_ghost_tween = _boss_bar.create_tween()
		_boss_ghost_tween.tween_interval(BOSS_GHOST_HOLD)
		_boss_ghost_tween.tween_property(_boss_bar, "ghost", ratio, BOSS_GHOST_DRAIN)
	_boss_bar.value = ratio
	_boss_hp_label.text = NumberFormat.format(hp)


## Cada golpe que acerta o chefe: pop de 1 px no ícone e `boss_hit`, limitados a 8/s.
func boss_hit() -> void:
	if _boss_icon == null or not _boss_hit_limiter.try_fire(_t):
		return
	Audio.play(&"boss_hit")
	if not Juice.reduce_motion():
		Juice.pop(_boss_icon, 0.12, 0.1)


## Fuga (óleo acabou): a barra se enche ao contrário enquanto o chefe some.
func boss_fled() -> void:
	if _boss_bar == null:
		return
	_boss_bar.ghost = -1.0
	var t := _boss_bar.create_tween()
	t.tween_property(_boss_bar, "value", 1.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## Vitória: a barra estoura em faíscas 26/23.
func boss_defeated() -> void:
	if _boss_plaque == null:
		return
	_boss_bar.ghost = -1.0
	_boss_bar.value = 0.0
	if Juice.reduce_flashes():
		return
	var sparks := _Sparks.new()
	sparks.position = _boss_plaque.position + Vector2(205, 12)
	_root.add_child(sparks)


func show_stomp(state: RunState) -> void:
	if _stomp_button != null or state.stat(StatSheet.STOMP_ENABLED) <= 0.0:
		return
	_stomp_atlas = AssetManifest.texture_by_id("hud_stomp")
	_stomp_pips_atlas = AssetManifest.texture_by_id("hud_pips")
	_stomp_button = TextureButton.new()
	_stomp_button.ignore_texture_size = true
	_stomp_button.stretch_mode = TextureButton.STRETCH_SCALE
	_stomp_button.texture_normal = AssetManifest.texture_by_id("hud_active_frame")
	_stomp_button.texture_hover = _stomp_button.texture_normal
	_stomp_button.texture_pressed = _stomp_button.texture_normal
	_stomp_button.texture_disabled = _stomp_button.texture_normal
	_stomp_button.position = Vector2(606, 320)
	_stomp_button.custom_minimum_size = Vector2(28, 28)
	_stomp_button.size = Vector2(28, 28)
	_stomp_button.tooltip_text = "Pisão · Q"
	_stomp_button.pressed.connect(func() -> void: state.use_stomp())
	_root.add_child(_stomp_button)
	_stomp_icon = TextureRect.new()
	_stomp_icon.position = Vector2(4, 4)
	_stomp_icon.size = Vector2(20, 20)
	_stomp_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_stomp_icon.stretch_mode = TextureRect.STRETCH_SCALE
	_stomp_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stomp_button.add_child(_stomp_icon)
	# UI/UX §13.1: tecla em m5x7 no topo da moldura.
	var key := Label.new()
	key.text = "Q"
	key.theme_type_variation = &"HudNumber"
	key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key.position = Vector2(0, -12)
	key.size = Vector2(28, 12)
	key.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stomp_button.add_child(key)
	_stomp_glow = _StompGlow.new()
	_stomp_glow.size = Vector2(28, 28)
	_stomp_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stomp_button.add_child(_stomp_glow)
	state.stomp_used.connect(func(_cells: Array[Vector2i]) -> void: _on_stomp_used())
	for i: int in 4:
		var pip := TextureRect.new()
		pip.position = Vector2(610 + i * 5, 350)
		pip.size = Vector2(4, 4)
		pip.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pip.stretch_mode = TextureRect.STRETCH_SCALE
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_root.add_child(pip)
		_stomp_pips.append(pip)
	refresh(state)


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


func _atlas_region(atlas: Texture2D, region: Rect2) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = atlas
	texture.region = region
	return texture


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
	if _medal != null and _xp_bar != null:
		_medal.level = state.level
		_xp_bar.value = state.xp / state.xp_needed(state.level)
	_unrest_bar.value = state.unrest
	var full := state.unrest >= 1.0 - 0.000001
	if full and not _unrest_shown:
		_unrest_label.visible = true
		# Chegou a 100%: o rótulo pisca 3× e depois fica aceso.
		_unrest_shown = true
		_unrest_blinks = float(UNREST_BLINKS)
	_oil_frozen = state.oil_frozen()
	if _stomp_button != null:
		var stomp_ready := state.stomp_cooldown_left <= 0.000001
		_stomp_button.disabled = not stomp_ready
		_stomp_icon.texture = _atlas_region(_stomp_atlas, Rect2(0 if stomp_ready else 20, 0, 20, 20))
		_stomp_glow.lit = stomp_ready
		var cooldown := maxf(0.001, state.stomp_cooldown())
		var charge := clampf(1.0 - state.stomp_cooldown_left / cooldown, 0.0, 1.0)
		for i: int in _stomp_pips.size():
			var before := float(i) / float(_stomp_pips.size())
			var after := float(i + 1) / float(_stomp_pips.size())
			var pip_state := 1 if charge >= after else (2 if charge > before else 0)
			if stomp_ready and i == _stomp_pips.size() - 1:
				pip_state = 2
			_stomp_pips[i].texture = _atlas_region(_stomp_pips_atlas, Rect2(pip_state * 4, 0, 4, 4))
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
	if _oil_frozen and not Juice.reduce_flashes():
		# LX: óleo parado pela Constelação — a barra pisca em ecto.
		_oil_bar.override_color = Palette.ECTO_BRIGHT if int(_t * 4.0) % 2 == 1 else Palette.ECTO
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


func update_grave_tooltip(grave: Dictionary, screen_position: Vector2) -> void:
	if grave.is_empty():
		_grave_tooltip.visible = false
		return
	var title_key: String
	var effect_key: String
	match StringName(grave.get("type", RunState.GRAVE_TYPE_OVAL)):
		RunState.GRAVE_TYPE_CROSS:
			title_key = "Cruz de pedra"
			effect_key = "+1 Alma × estágio"
		RunState.GRAVE_TYPE_MOSS:
			title_key = "Lápide com musgo"
			effect_key = "Caixão 1,5× mais duro · Ossos ×2"
		_:
			title_key = "Foto oval"
			effect_key = "Cova normal"
	_grave_tooltip_title.text = tr(title_key)
	_grave_tooltip_effect.text = tr(effect_key)
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var pos := screen_position.floor() + Vector2(12, 14)
	if pos.x + _grave_tooltip.size.x > viewport_size.x - 4.0:
		pos.x = screen_position.x - _grave_tooltip.size.x - 12.0
	if pos.y + _grave_tooltip.size.y > viewport_size.y - 4.0:
		pos.y = screen_position.y - _grave_tooltip.size.y - 12.0
	_grave_tooltip.position = pos.floor().clamp(Vector2(4, 4), viewport_size - _grave_tooltip.size - Vector2(4, 4))
	_grave_tooltip.visible = true


func _build_grave_tooltip() -> void:
	_grave_tooltip = PanelContainer.new()
	_grave_tooltip.theme_type_variation = &"TooltipPanel"
	_grave_tooltip.custom_minimum_size = Vector2(220, 48)
	_grave_tooltip.size = _grave_tooltip.custom_minimum_size
	_grave_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grave_tooltip.visible = false
	_root.add_child(_grave_tooltip)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 1)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grave_tooltip.add_child(column)
	_grave_tooltip_title = Label.new()
	_grave_tooltip_title.theme_type_variation = &"TooltipLabel"
	_grave_tooltip_title.custom_minimum_size = Vector2(208, 12)
	_grave_tooltip_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_grave_tooltip_title)
	_grave_tooltip_effect = Label.new()
	_grave_tooltip_effect.theme_type_variation = &"TooltipLabel"
	_grave_tooltip_effect.custom_minimum_size = Vector2(208, 22)
	_grave_tooltip_effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_grave_tooltip_effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_grave_tooltip_effect)


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
	# UI/UX §4/§13.1: Inquietação > 80% pulsa a 1 Hz e a caveira treme 1 px; em 100% a barra
	# fica cheia com brilho 32 varrendo.
	var alert := _unrest_bar.value >= Game.balance.unrest_alert_at
	var full := _unrest_bar.value >= 1.0 - 0.000001
	_unrest_bar.override_color = Palette.ECTO_BRIGHT if alert and not full and fmod(_t, 1.0) < 0.5 and not Juice.reduce_flashes() else 0
	_unrest_bar.sweep_color = Palette.DANGER
	_unrest_bar.sweep = fmod(_t, 1.5) / 1.5 if full and not Juice.reduce_flashes() else -1.0
	if _unrest_blinks > 0.0:
		_unrest_blinks -= delta * 2.0
		_unrest_label.visible = int(_unrest_blinks * 2.0) % 2 == 0 or Juice.reduce_flashes()
	elif full:
		_unrest_label.visible = true
	if alert and not Juice.reduce_motion():
		_skull.position = _skull_base + Vector2(randi_range(-1, 1), 0) if int(_t * 12.0) % 2 == 0 else _skull_base
	else:
		_skull.position = _skull_base


func _on_field_cleared(bonus: float) -> void:
	show_toast("CAMPO LIMPO!  +%s" % NumberFormat.format(bonus), 1.8)


func _on_level_up(level: int) -> void:
	if _medal == null or _xp_bar == null:
		return
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


## UI/UX §13.1 "Usado": o ícone afunda 1 px e pisca 23 por 1 frame (sem flash com "reduzir flashes").
func _on_stomp_used() -> void:
	if _stomp_icon == null:
		return
	_stomp_icon.position = Vector2(4, 5)
	var t := _stomp_icon.create_tween()
	t.tween_interval(0.12)
	t.tween_callback(func() -> void: _stomp_icon.position = Vector2(4, 4))
	if not Juice.reduce_flashes():
		_stomp_glow.flash()


## Borda 26 do Pisão pronto com um brilho varrendo a cada 1,5 s; flash 23 ao usar.
class _StompGlow:
	extends Control

	const SWEEP_EVERY := 1.5
	const SWEEP_TIME := 0.3
	var lit: bool = false
	var _t: float = 0.0
	var _flash: int = 0

	func flash() -> void:
		_flash = 2

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		if _flash > 0:
			_flash -= 1
			draw_rect(Rect2(4, 4, 20, 20), Palette.color(Palette.BONE_BRIGHT))
			return
		if not lit:
			return
		var c := Palette.color(Palette.LANTERN_BRIGHT)
		draw_rect(Rect2(1, 1, 26, 1), c)
		draw_rect(Rect2(1, 26, 26, 1), c)
		draw_rect(Rect2(1, 1, 1, 26), c)
		draw_rect(Rect2(26, 1, 1, 26), c)
		var phase := fmod(_t, SWEEP_EVERY)
		if phase < SWEEP_TIME and not Juice.reduce_flashes():
			var x := 1.0 + floorf(phase / SWEEP_TIME * 26.0)
			draw_rect(Rect2(x, 1, 2, 1), Palette.color(Palette.BONE_BRIGHT))
			draw_rect(Rect2(28.0 - x, 26, 2, 1), Palette.color(Palette.BONE_BRIGHT))


## Faíscas 26/23 da barra do chefe estourando (UI/UX §13.2, vitória).
class _Sparks:
	extends Node2D

	const LIFE := 0.5
	var _t: float = 0.0
	var _dirs: Array[Vector2] = []

	func _ready() -> void:
		for i: int in 14:
			var a := TAU * float(i) / 14.0 + randf_range(-0.2, 0.2)
			_dirs.append(Vector2(cos(a), sin(a) * 0.6) * randf_range(30.0, 70.0))

	func _process(delta: float) -> void:
		_t += delta
		if _t >= LIFE:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var k := _t / LIFE
		for i: int in _dirs.size():
			var p := (_dirs[i] * k).floor()
			var c := Palette.LANTERN_BRIGHT if (i + int(k * 6.0)) % 2 == 0 else Palette.BONE_BRIGHT
			draw_rect(Rect2(p, Vector2(2, 2) if k < 0.5 else Vector2.ONE), Palette.color(c))
