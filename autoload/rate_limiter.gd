class_name RateLimiter
extends RefCounted
## Limita eventos a N por segundo (ex.: tique do contador, UI/UX §6: máx. 20/s).

var per_second: float
var _next_allowed: float = -INF


func _init(p_per_second: float = 20.0) -> void:
	per_second = p_per_second


## `now` em segundos. Retorna true se o evento pode acontecer agora.
func try_fire(now: float) -> bool:
	if now + 0.000001 < _next_allowed:
		return false
	_next_allowed = now + 1.0 / per_second
	return true
