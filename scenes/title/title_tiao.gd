class_name TitleTiao
extends TitleActor
## Tião, o Corvo, na lápide (tiao, 16×16, pivô (8, 15)), com a moeda de cobre no bico:
## `idle` (piscar) e, de vez em quando, `tilt` (inclina a cabeça), `hop` (pulinho) ou `caw` (grasna).

const TILT := &"tilt"
const HOP := &"hop"
const CAW := &"caw"
const ACTIONS: Array[StringName] = [TILT, HOP, CAW, TILT]
const ACTION_EVERY := Vector2(3.0, 7.0)

var _next_action: float = 0.0


func _ready() -> void:
	fallback_lengths = {IDLE: 3.0, TILT: 0.9, HOP: 0.4, CAW: 0.5}
	setup(TitleArt.sheet(TitleArt.TIAO))
	play(IDLE, true)
	_next_action = randf_range(ACTION_EVERY.x, ACTION_EVERY.y)
	animation_finished.connect(func(_t2: StringName) -> void: play(IDLE, true))


func _process(delta: float) -> void:
	super._process(delta)
	if tag != IDLE:
		return
	_next_action -= delta
	if _next_action <= 0.0:
		_next_action = randf_range(ACTION_EVERY.x, ACTION_EVERY.y)
		play(ACTIONS[randi() % ACTIONS.size()])


## MANIFEST tiao: virado para a esquerda (olha para o Coveiro); o placeholder é espelhado igual.
func _draw_placeholder() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1, 1))
	_draw_crow()
	draw_set_transform(Vector2.ZERO)


func _draw_crow() -> void:
	var dy := 0
	var head_dx := 0
	if tag == HOP:
		var p := progress()
		dy = -int(roundf(4.0 * sin(PI * p) * Juice.motion()))
	elif tag == TILT:
		head_dx = 1
	var blink := tag == IDLE and fmod(_t, 3.0) > 2.85
	# Corpo 02 com asa 03, pernas 01, cabeça e bico 25/26 com a moeda.
	_r(-1, -2, 1, 2, Palette.OUTLINE)
	_r(1, -2, 1, 2, Palette.OUTLINE)
	_r(-5, -9 + dy, 9, 7, Palette.BG)
	_r(-4, -8 + dy, 5, 3, Palette.NIGHT)
	_r(-7, -6 + dy, 3, 2, Palette.BG)
	_r(1 + head_dx, -13 + dy, 5, 5, Palette.BG)
	_r(3 + head_dx, -12 + dy, 1, 1, Palette.OUTLINE if blink else Palette.BONE_BRIGHT)
	var open := 1 if tag == CAW and int(_t * 10.0) % 2 == 0 else 0
	_r(6 + head_dx, -11 + dy - open, 3, 1, Palette.LANTERN_DARK)
	_r(6 + head_dx, -10 + dy + open, 3, 1, Palette.LANTERN_DARK)
	if open == 0:
		_r(8 + head_dx, -11 + dy, 2, 2, Palette.LANTERN_BRIGHT)
