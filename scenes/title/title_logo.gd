class_name TitleLogo
extends Node2D
## Logo "DIG DIG GRAVES" (UI/UX §9.2–§9.3): letras de pedra caem uma a uma (40 ms) com squash
## e poeira, a pá crava no G com "tunc" e terrinha; depois, ocioso: de vez em quando uma gota
## de terra cai e a pá balança 1 px. Estado = função do tempo da abertura (pular = ir ao fim).

signal shovel_landed()

const SQUASH := Vector2(1.18, 0.8)
const SHOVEL_DROP := 72.0
const DRIP_EVERY := Vector2(3.0, 7.0)
const DRIP_FALL := 10.0
const DRIP_TIME := 0.4
const DRIP_SOUND_AFTER_THUNK := 0.25
## MANIFEST title_logo_shovel: balanço ocioso = 1 px em x por ~80 ms depois de cada gota.
const WOBBLE_TIME := 0.08
const DRIP_TAG := &"act"
## Pivô da pá placeholder (TitleArt.shovel_image).
const PLACEHOLDER_SHOVEL_TIP := Vector2(4, 29)
const DUST_FRAMES: Array[float] = [0.083, 0.083, 0.084]
const DUST_ROW := 1  # MANIFEST dust: linha 1 = terra
const CLOD_ROW := 1  # MANIFEST torroes: linha 1 = terra

var layout: TitleLayoutData
## Logo ocioso (gotas) só depois da abertura.
var idle: bool = false

var _t: float = -1.0
var _letters_tex: Array[Texture2D] = []
var _letters_src: Array[Rect2] = []
var _rects: Array[Rect2] = []
var _shovel_tex: Texture2D
var _shovel_pos: Vector2
var _drip_sheet: AsepriteSheet
var _dust_tex: Texture2D = TitleArt.texture_path(TitleArt.DUST_PATH)
var _clod_tex: Texture2D = TitleArt.texture_path(TitleArt.CLODS_PATH)
var _fx: Array[Dictionary] = []  # poeira e torrões
var _drip: Dictionary = {}
var _drip_in: float = 4.0
var _wobble_t: float = -1.0
var _thunk_sound_t: float = -1.0
var _subtitle: Label


func setup(p_layout: TitleLayoutData) -> void:
	layout = p_layout


func _ready() -> void:
	var atlas := TitleArt.texture(TitleArt.LOGO)
	var atlas_sheet := TitleArt.sheet(TitleArt.LOGO)
	for i: int in TitleLayoutData.LETTER_COUNT:
		var tex: Texture2D = null
		var src := Rect2()
		if atlas != null and i < layout.letter_cells.size():
			tex = atlas
			src = layout.letter_cells[i]
		elif atlas_sheet != null and atlas_sheet.frames.size() >= TitleLayoutData.LETTER_COUNT:
			tex = atlas_sheet.texture
			src = atlas_sheet.frames[i]
		else:
			tex = TitleArt.letter_texture(i)
			src = Rect2(Vector2.ZERO, tex.get_size())
		_letters_tex.append(tex)
		_letters_src.append(src)
		_rects.append(Rect2(layout.letter_pos(i), src.size))
	_shovel_tex = TitleArt.shovel_texture()
	_shovel_pos = layout.shovel_final(_shovel_tex.get_size())
	_drip_sheet = TitleArt.sheet(TitleArt.LOGO_DRIP)
	_subtitle = Label.new()
	_subtitle.theme = UiTheme.get_theme()  # sob Node2D o tema da janela não propaga
	_subtitle.theme_type_variation = &"HudLabel"
	_subtitle.text = "Cava Cava Covas"
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.position = Vector2(220, layout.subtitle_y)
	_subtitle.size = Vector2(200, 10)  # centrado em x = 320
	_subtitle.add_theme_color_override("font_color", Palette.color(Palette.BONE_SHADOW))
	_subtitle.visible = false
	add_child(_subtitle)


## Avança a abertura até `t` (s). Com `events`, toca sons e solta poeira ao cruzar os marcos.
func update_intro(t: float, events: bool = true) -> void:
	var prev := _t
	_t = t
	if events:
		for i: int in TitleLayoutData.LETTER_COUNT:
			var land := TitleTimeline.letter_land(i)
			if prev < land and t >= land:
				Audio.play(&"logo_land")
				var r := _rects[i]
				_add_dust(Vector2(r.position.x + r.size.x * 0.5, r.end.y))
		var thunk := TitleTimeline.thunk_time()
		if prev < thunk and t >= thunk:
			_on_thunk()
	if t >= TitleTimeline.thunk_time() and not _subtitle.visible:
		_subtitle.visible = true
		_subtitle.modulate.a = 0.0 if events else 1.0
		if events:
			_subtitle.create_tween().tween_property(_subtitle, "modulate:a", 1.0, 0.3)
	queue_redraw()


## Estado final direto (pular a abertura / voltar do jogo): sem sons nem poeira.
func show_final() -> void:
	update_intro(TitleTimeline.thunk_time() + 10.0, false)
	idle = true


func _on_thunk() -> void:
	shovel_landed.emit()
	Audio.play(&"logo_thunk", 1.0, 0.0)
	_thunk_sound_t = DRIP_SOUND_AFTER_THUNK
	var tip := _shovel_tip()
	var n := maxi(2, roundi(9 * Juice.motion()))
	for i: int in n:
		_fx.append({"kind": &"clod", "pos": tip + Vector2(randf_range(-3, 3), 0), "vel": Vector2(randf_range(-30, 30), randf_range(-60, -20)),
			"age": 0.0, "life": 0.7, "size": randi() % 3})
	_add_dust(tip + Vector2(0, 2))


func _shovel_tip() -> Vector2:
	var art := TitleArt.texture(TitleArt.LOGO_SHOVEL) != null
	return _shovel_pos + (layout.shovel_pivot if art else PLACEHOLDER_SHOVEL_TIP)


func _add_dust(pos: Vector2) -> void:
	_fx.append({"kind": &"dust", "pos": pos, "age": 0.0, "life": 0.25})


func _process(delta: float) -> void:
	if _thunk_sound_t > 0.0:
		_thunk_sound_t -= delta
		if _thunk_sound_t <= 0.0:
			Audio.play(&"logo_drip")
	for f: Dictionary in _fx:
		f.age = float(f.age) + delta
		if f.kind == &"clod":
			var v: Vector2 = f.vel
			v.y += 260.0 * delta
			f.vel = v
			f.pos = (f.pos as Vector2) + v * delta
	_fx = _fx.filter(func(f: Dictionary) -> bool: return float(f.age) < float(f.life))
	if idle:
		_process_idle(delta)
	queue_redraw()


## Logo ocioso: 1 gota de terra cai e some; a pá balança 1 px logo depois.
func _process_idle(delta: float) -> void:
	if _wobble_t >= 0.0:
		_wobble_t += delta
		if _wobble_t > WOBBLE_TIME:
			_wobble_t = -1.0
	if not _drip.is_empty():
		_drip.age = float(_drip.age) + delta
		if float(_drip.age) >= _drip_length():
			_drip = {}
			Audio.play(&"logo_drip")
			_wobble_t = 0.0
		return
	_drip_in -= delta
	if _drip_in <= 0.0:
		_drip_in = randf_range(DRIP_EVERY.x, DRIP_EVERY.y)
		var points := layout.drip_list()
		if not points.is_empty():
			_drip = {"pos": points[randi() % points.size()], "age": 0.0}


func _drip_length() -> float:
	return _drip_sheet.tag_duration(DRIP_TAG) if _drip_sheet != null else DRIP_TIME


func _draw() -> void:
	if _t < 0.0:
		return
	var m := Juice.motion()
	for i: int in TitleLayoutData.LETTER_COUNT:
		var start := TitleTimeline.letter_start(i)
		if _t < start:
			continue
		var r := _rects[i]
		var dy := -roundf(layout.letter_drop * TitleTimeline.fall_remaining(_t, start, TitleTimeline.LETTER_FALL))
		var sq := Vector2.ONE
		var since := _t - TitleTimeline.letter_land(i)
		if since >= 0.0 and since < TitleTimeline.LETTER_SQUASH:
			var k := 1.0 - since / TitleTimeline.LETTER_SQUASH
			sq = Vector2.ONE.lerp(SQUASH, k * m)
		var base := Vector2(roundf(r.position.x + r.size.x * 0.5), r.end.y + dy)
		draw_set_transform(base, 0.0, sq)
		draw_texture_rect_region(_letters_tex[i], Rect2(Vector2(-roundf(r.size.x * 0.5), -r.size.y), r.size), _letters_src[i])
		draw_set_transform(Vector2.ZERO)
	var s_start := TitleTimeline.shovel_start()
	if _t >= s_start:
		var sdy := -roundf(SHOVEL_DROP * TitleTimeline.fall_remaining(_t, s_start, TitleTimeline.SHOVEL_FALL))
		var wob := 0.0
		if _wobble_t >= 0.0 and not Juice.reduce_motion():
			wob = 1.0
		draw_texture(_shovel_tex, _shovel_pos + Vector2(wob, sdy))
	_draw_drip()
	_draw_fx()


func _draw_drip() -> void:
	if _drip.is_empty():
		return
	var p: Vector2 = _drip.pos
	var age := float(_drip.age)
	if _drip_sheet != null:
		# MANIFEST title_logo_drip: pivô (1, 0) encaixa na ponta de gota.
		_drip_sheet.draw_frame(self, _drip_sheet.frame_at(DRIP_TAG, age, false), p, Vector2(1, 0))
		return
	# Gota 1×2 (15 com brilho 16) escorrendo e caindo.
	var q := clampf(age / DRIP_TIME, 0.0, 1.0)
	var y := roundf(DRIP_FALL * q * q)
	draw_rect(Rect2(p + Vector2(0, y), Vector2(1, 2)), Palette.color(Palette.DIRT))
	draw_rect(Rect2(p + Vector2(0, y), Vector2(1, 1)), Palette.color(Palette.DIRT_LIGHT))


func _draw_fx() -> void:
	for f: Dictionary in _fx:
		var pos: Vector2 = f.pos
		if f.kind == &"dust":
			var frame := TreeArt.frame_at(float(f.age), DUST_FRAMES)
			if _dust_tex != null:
				TreeArt.draw_cell(self, _dust_tex, Vector2(16, 16), frame, DUST_ROW, pos, Vector2(8, 14))
			else:
				for k: int in 3:
					draw_rect(Rect2(pos + Vector2(-6 + k * 5 - frame, -2 - frame), Vector2(2, 1)), Palette.color(Palette.DIRT_LIGHT))
		else:
			var size := int(f.size)
			if _clod_tex != null:
				TreeArt.draw_cell(self, _clod_tex, Vector2(3, 3), size, CLOD_ROW, pos, Vector2(1, 1))
			else:
				draw_rect(Rect2(pos.round(), Vector2(size + 1, size + 1)), Palette.color(Palette.DIRT))


## Retângulos finais das letras (testes e layout).
func letter_rects() -> Array[Rect2]:
	return _rects
