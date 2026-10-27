extends Node
## Cena principal: abre a tela-título (UI/UX §9). O autopilot (captura) pula o título.


func _ready() -> void:
	if Game.autopilot:
		Game.goto_start.call_deferred()
	else:
		Game.goto_title.call_deferred(false)
