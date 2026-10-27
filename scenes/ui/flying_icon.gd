class_name FlyingIcon
extends ResourceIcon
## Ícone de recurso voando do mundo até o HUD (DA §9.2, UI/UX §4/§6): curva, 400–600 ms.

signal arrived(icon: FlyingIcon)

var value: float = 0.0
var _from: Vector2
var _to: Vector2
var _ctrl: Vector2


func launch(from: Vector2, to: Vector2, time: float) -> void:
	_from = from - Vector2(8, 8)
	_to = to - Vector2(8, 8)
	# Sobe primeiro e depois mergulha no ícone: controle acima do ponto médio, puxado para fora.
	var mid := (_from + _to) * 0.5
	_ctrl = Vector2(lerpf(_from.x, mid.x, 0.4) + randf_range(-30.0, 30.0), minf(_from.y, _to.y) - randf_range(20.0, 50.0))
	position = _from.round()
	var t := create_tween()
	t.tween_method(_step, 0.0, 1.0, time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.tween_callback(func() -> void:
		arrived.emit(self)
		queue_free())


func _step(t: float) -> void:
	var p := _from.lerp(_ctrl, t).lerp(_ctrl.lerp(_to, t), t)
	position = p.round()
