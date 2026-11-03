class_name StudioSplash
extends Control
## Splash do Briba Studio (UI/UX §21): fundo 01, `briba_logo_anim` 1× com canto em (268, 114).
## Preto 0,2 s → fade-in 0,3 s com a tag `intro` (0,8 s) e `splash_briba` no 1º frame → `idle`
## até 1,8 s → fade para preto 0,3 s → título. Qualquer tecla, clique ou botão pula.

signal finished()

const LOGO_ID := "briba_logo_anim"
const LOGO_TOPLEFT := Vector2(268, 114)
const BLACK_HOLD := 0.2
const FADE_IN := 0.3
const TOTAL := 1.8
const FADE_OUT := 0.3

var _sheet: AsepriteSheet
var _logo: _Logo
var _fade: TitleFade
var _t: float = 0.0
var _sound_played: bool = false
var _done: bool = false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Palette.color(Palette.OUTLINE)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	_sheet = AsepriteSheet.load_id(LOGO_ID)
	_logo = _Logo.new()
	_logo.sheet = _sheet
	_logo.position = LOGO_TOPLEFT
	add_child(_logo)
	_fade = TitleFade.new()
	add_child(_fade)
	_fade.level = 1.0
	if _sheet == null or _sheet.texture == null:
		# Sem a arte no manifesto não há o que mostrar: segue direto para o título.
		_finish.call_deferred()


func _process(delta: float) -> void:
	if _done:
		return
	_t += delta
	var logo_t := _t - BLACK_HOLD
	if logo_t >= 0.0 and not _sound_played:
		_sound_played = true
		Audio.play(&"splash_briba", 1.0, 0.0)
	_logo.anim_time = maxf(0.0, logo_t)
	if _t < BLACK_HOLD:
		_fade.level = 1.0
	elif _t < BLACK_HOLD + FADE_IN:
		_fade.level = 1.0 - (_t - BLACK_HOLD) / FADE_IN
	elif _t < TOTAL:
		_fade.level = 0.0
	elif _t < TOTAL + FADE_OUT:
		_fade.level = (_t - TOTAL) / FADE_OUT
	else:
		_finish()


func _input(event: InputEvent) -> void:
	if _done:
		return
	var skip := (event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo) \
		or (event is InputEventMouseButton and (event as InputEventMouseButton).pressed) \
		or (event is InputEventJoypadButton and (event as InputEventJoypadButton).pressed)
	if skip:
		get_viewport().set_input_as_handled()
		_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	finished.emit()


## O logo animado: `intro` uma vez (para no último frame) e depois `idle` em loop.
class _Logo:
	extends Node2D

	var sheet: AsepriteSheet
	var anim_time: float = 0.0:
		set(v):
			anim_time = v
			queue_redraw()

	func _draw() -> void:
		if sheet == null or sheet.texture == null:
			return
		var intro := sheet.tag_duration(&"intro")
		var frame: int
		if anim_time < intro or not sheet.has_tag(&"idle"):
			frame = sheet.frame_at(&"intro", anim_time, false)
		else:
			frame = sheet.frame_at(&"idle", anim_time - intro, true)
		sheet.draw_frame(self, frame, Vector2.ZERO, Vector2.ZERO)
