extends Node
## Cena principal: splash do Briba Studio (UI/UX §21) e depois a tela-título (UI/UX §9).
## O splash só aparece ao abrir o jogo (nunca em "Voltar ao título"); o autopilot pula tudo.


func _ready() -> void:
	if Game.autopilot:
		Game.goto_start.call_deferred()
		return
	var splash := StudioSplash.new()
	add_child(splash)
	await splash.finished
	Game.goto_title(false)
