extends Node
## Cena principal (sem tela-título no M0): 1º jogo → Turno; depois → Árvore.


func _ready() -> void:
	Game.goto_start.call_deferred()
