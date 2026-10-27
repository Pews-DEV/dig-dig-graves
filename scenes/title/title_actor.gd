class_name TitleActor
extends Node2D
## Personagem/prop animado da tela-título. Com a folha do manifesto (PNG + JSON do Aseprite)
## toca as tags do contrato (UI/UX §9.6); sem ela, desenha o placeholder da subclasse.
## A posição do nó é o pivô (base) do sprite.

signal animation_finished(tag: StringName)

const IDLE := &"idle"

var sheet: AsepriteSheet
var pivot: Vector2 = Vector2.ZERO
var tag: StringName = IDLE
var looping: bool = true
## Duração das tags no placeholder (s).
var fallback_lengths: Dictionary = {}
var _t: float = 0.0
var _done: bool = false


func setup(p_sheet: AsepriteSheet, default_pivot: Vector2 = Vector2(-1, -1)) -> void:
	sheet = p_sheet
	if default_pivot.x >= 0.0:
		pivot = default_pivot
	elif sheet != null:
		# Contrato: pivô na base, centro horizontal (ex.: 32×32 → (16, 31)).
		var fs := sheet.frame_size()
		pivot = Vector2(floorf(fs.x * 0.5), fs.y - 1.0)


## Toca uma tag. Retorna false se a folha não tem a tag (o ator continua no que estava).
func play(new_tag: StringName, loop: bool = false) -> bool:
	if sheet != null and not sheet.has_tag(new_tag) and new_tag != IDLE:
		return false
	tag = new_tag
	looping = loop
	_t = 0.0
	_done = false
	queue_redraw()
	return true


func tag_length(t: StringName) -> float:
	if sheet != null:
		return sheet.tag_duration(t)
	return float(fallback_lengths.get(t, 0.6))


## Progresso 0→1 da tag atual (1 se em loop há mais de um ciclo).
func progress() -> float:
	var length_s := tag_length(tag)
	return clampf(_t / length_s, 0.0, 1.0) if length_s > 0.0 else 1.0


func _process(delta: float) -> void:
	_t += delta
	if not looping and not _done and _t >= tag_length(tag):
		_done = true
		animation_finished.emit(tag)
	queue_redraw()


func _draw() -> void:
	if sheet != null:
		sheet.draw_frame(self, sheet.frame_at(tag, _t, looping), Vector2.ZERO, pivot)
	else:
		_draw_placeholder()


## Subclasses desenham aqui (origem = pivô na base).
func _draw_placeholder() -> void:
	pass


func _r(x: int, y: int, w: int, h: int, idx: int) -> void:
	draw_rect(Rect2(x, y, w, h), Palette.color(idx))
