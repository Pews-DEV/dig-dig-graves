class_name TreeCamera
extends RefCounted
## Câmera da Árvore (UI/UX §7.1), pura e testável: arrastar com inércia, limites e rolagem
## suave até um ponto. `pos` = canto superior esquerdo da vista, em coordenadas do mundo.

const FRICTION := 5.0  # decaimento exponencial da inércia (1/s)
const FOLLOW := 7.0  # rapidez da rolagem até o alvo (1/s)
const STOP_SPEED := 4.0  # px/s abaixo disso a inércia para

var pos: Vector2 = Vector2.ZERO
var vel: Vector2 = Vector2.ZERO
var view: Vector2 = Vector2(640, 360)
var bounds: Rect2 = Rect2(0, 0, 640, 720)  # retângulo do mundo que pode aparecer
var has_target: bool = false
var target: Vector2 = Vector2.ZERO


func _init(p_view: Vector2 = Vector2(640, 360), p_bounds: Rect2 = Rect2(0, 0, 640, 720)) -> void:
	view = p_view
	bounds = p_bounds


func min_pos() -> Vector2:
	return bounds.position


func max_pos() -> Vector2:
	return Vector2(maxf(bounds.position.x, bounds.end.x - view.x), maxf(bounds.position.y, bounds.end.y - view.y))


func clamp_pos(p: Vector2) -> Vector2:
	var lo := min_pos()
	var hi := max_pos()
	return Vector2(clampf(p.x, lo.x, hi.x), clampf(p.y, lo.y, hi.y))


## Arrasto: o mundo acompanha o mouse (mover o mouse para baixo mostra o que está acima).
func drag(mouse_delta: Vector2) -> void:
	has_target = false
	vel = Vector2.ZERO
	pos = clamp_pos(pos - mouse_delta)


## Soltou o arrasto com a velocidade do mouse (px/s): a câmera continua no sentido do arrasto.
func release(mouse_velocity: Vector2) -> void:
	vel = -mouse_velocity


func scroll_by(delta: Vector2) -> void:
	scroll_to(pos + delta)


func scroll_to(p: Vector2) -> void:
	has_target = true
	target = clamp_pos(p)
	vel = Vector2.ZERO


## Posição de câmera que deixa `world_point` dentro de `safe` (retângulo na tela), movendo o mínimo.
func focus_for(world_point: Vector2, safe: Rect2) -> Vector2:
	var p := pos
	var screen := world_point - pos
	if screen.x < safe.position.x:
		p.x -= safe.position.x - screen.x
	elif screen.x > safe.end.x:
		p.x += screen.x - safe.end.x
	if screen.y < safe.position.y:
		p.y -= safe.position.y - screen.y
	elif screen.y > safe.end.y:
		p.y += screen.y - safe.end.y
	return clamp_pos(p)


## Centraliza um ponto do mundo na vista (respeitando os limites).
func center_on(world_point: Vector2, screen_anchor: Vector2) -> Vector2:
	return clamp_pos(world_point - screen_anchor)


func step(dt: float) -> void:
	if has_target:
		pos = pos.lerp(target, 1.0 - exp(-FOLLOW * dt))
		if pos.distance_to(target) < 0.5:
			pos = target
			has_target = false
		return
	if vel.length() < STOP_SPEED:
		vel = Vector2.ZERO
		return
	var next := pos + vel * dt
	var clamped := clamp_pos(next)
	if clamped.x != next.x:
		vel.x = 0.0
	if clamped.y != next.y:
		vel.y = 0.0
	pos = clamped
	vel *= exp(-FRICTION * dt)


## Posição da câmera arredondada para pixels inteiros (UI/UX §1.5).
func pixel_pos() -> Vector2:
	return pos.round()
