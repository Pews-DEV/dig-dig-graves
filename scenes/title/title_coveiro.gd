class_name TitleCoveiro
extends TitleActor
## O Coveiro sentado no monte (coveiro_title, 32×32, pivô (16, 31)): `idle` respirando, às vezes
## `scratch` (coça a cabeça) ou `yawn` (boceja); `stand` levanta, pega a pá e a lanterna e segura
## o último frame (UI/UX §9.4).

const SCRATCH := &"scratch"
const YAWN := &"yawn"
const STAND := &"stand"
const ACTION_EVERY := Vector2(6.0, 12.0)

var standing: bool = false
var _next_action: float = 0.0


func _ready() -> void:
	fallback_lengths = {IDLE: 1.2, SCRATCH: 1.0, YAWN: 1.2, STAND: 0.7}
	setup(TitleArt.sheet(TitleArt.COVEIRO))
	play(IDLE, true)
	_next_action = randf_range(ACTION_EVERY.x * 0.5, ACTION_EVERY.y * 0.5)
	animation_finished.connect(_on_finished)


func _process(delta: float) -> void:
	super._process(delta)
	if standing or tag != IDLE:
		return
	_next_action -= delta
	if _next_action <= 0.0:
		_next_action = randf_range(ACTION_EVERY.x, ACTION_EVERY.y)
		play(SCRATCH if randf() < 0.55 else YAWN)


func _on_finished(t: StringName) -> void:
	if t != STAND:
		play(IDLE, true)


## Levanta (pega a pá e a lanterna). Aguarde `animation_finished` ou `stand_time()`.
func stand() -> void:
	standing = true
	if not play(STAND):
		# Folha sem `stand`: segura o idle (o placeholder sempre tem).
		play(IDLE, true)


## Quadro local (0 = 1º) da tag atual na folha; −1 sem folha.
func local_frame() -> int:
	if sheet == null:
		return -1
	return sheet.frame_at(tag, _t, looping) - sheet.tag_range(tag).x


## Já pegou a pá e a lanterna? (MANIFEST: a partir do 3º frame do `stand`)
func has_picked_up(layout: TitleLayoutData) -> bool:
	if not standing:
		return false
	if sheet != null and sheet.has_tag(STAND):
		return local_frame() >= layout.stand_pick_frame
	return progress() >= layout.stand_pick_at


## O halo sobe com a lanterna no último frame do `stand`.
func halo_raised(layout: TitleLayoutData) -> bool:
	if not standing:
		return false
	if sheet != null and sheet.has_tag(STAND):
		return local_frame() >= layout.stand_halo_frame
	return progress() >= 0.9


func stand_time() -> float:
	return tag_length(STAND) if (sheet == null or sheet.has_tag(STAND)) else 0.3


func _draw_placeholder() -> void:
	var breathe := 1 if tag == IDLE and sin(_t * TAU / 1.2) > 0.0 and not Juice.reduce_motion() else 0
	if tag == STAND:
		var p := progress()
		var rise := int(roundf(8.0 * p))
		_draw_body(-rise, p > 0.6)
		return
	_draw_body(-breathe, false)
	if tag == SCRATCH:
		var up := int(_t * 8.0) % 2
		_r(4, -27 - up, 2, 9, Palette.DIRT_EDGE)
	elif tag == YAWN and progress() > 0.2 and progress() < 0.8:
		_r(-2, -20, 3, 2, Palette.OUTLINE)


## Corpo placeholder: chapéu de palha furado (21/22), rosto 17, poncho 18/19, calça 14.
func _draw_body(dy: int, holding: bool) -> void:
	var legs_h := 4 if not standing else 4 + int(roundf(8.0 * progress()))
	_r(-6, -legs_h, 5, legs_h, Palette.DIRT_DARK)
	_r(1, -legs_h, 5, legs_h, Palette.DIRT_DARK)
	if not standing:
		_r(-6, -4, 14, 4, Palette.DIRT_DARK)
		_r(7, -3, 4, 3, Palette.DIRT_BOTTOM)
	_r(-7, -18 + dy - (legs_h - 4), 14, 14, Palette.COFFIN)
	_r(-7, -18 + dy - (legs_h - 4), 2, 14, Palette.COFFIN_LIGHT)
	_r(5, -18 + dy - (legs_h - 4), 2, 14, Palette.COFFIN_DARK)
	var head := -25 + dy - (legs_h - 4)
	_r(-4, head, 8, 7, Palette.DIRT_EDGE)
	_r(1, head + 3, 1, 1, Palette.OUTLINE)
	_r(-9, head - 1, 18, 2, Palette.BONE)
	_r(-5, head - 5, 10, 4, Palette.BONE_SHADOW)
	_r(2, head - 4, 1, 1, Palette.OUTLINE)
	if holding:
		_r(9, head - 4, 2, 26, Palette.DIRT_EDGE)
		_r(8, head + 20, 4, 5, Palette.STONE)
		_r(-12, head + 12, 5, 6, Palette.LANTERN_DARK)
		_r(-11, head + 13, 3, 4, Palette.LANTERN_BRIGHT)
