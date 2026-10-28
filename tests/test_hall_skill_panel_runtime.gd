extends Node
## O painel de detalhes das skills só aparece enquanto o jogador está nas Raízes.

const SkillTreeScreenScript = preload("res://scenes/tree/skill_tree_screen.gd")


func _ready() -> void:
	Game.unrest[Game.area.id] = 0.0
	Game.dialogue_seen[&"unrest_full"] = true
	var screen := SkillTreeScreenScript.new() as Control
	add_child(screen)
	await get_tree().process_frame
	await get_tree().process_frame
	assert(screen._hall.visible, "Pátio aparece ao entrar na tela da Árvore")
	assert(not screen._panel.visible, "detalhes das skills ficam ocultos no Pátio")
	screen._on_hovered(&"N00")
	assert(not screen._panel.visible, "hover residual na árvore não reabre detalhes no Pátio")
	screen._set_focus(&"N00")
	assert(not screen._panel.visible, "foco residual não abre detalhes no Pátio")
	screen._open_skill_tree()
	assert(not screen._hall.visible, "Raízes fecha o painel do Pátio")
	screen._on_hovered(&"N00")
	assert(screen._panel.visible, "detalhes aparecem ao selecionar uma skill nas Raízes")
	screen._show_hall()
	assert(screen._hall.visible, "botão Pátio retorna às estações")
	assert(not screen._panel.visible, "retorno ao Pátio esconde os detalhes da skill")
	screen._open_skill_tree()
	assert(not screen._hall.visible, "Raízes fecha o painel do Pátio")
	assert(screen._panel.visible, "detalhes da skill voltam nas Raízes")
	print("PASS painel de skills oculto no Pátio e restaurado nas Raízes")
	get_tree().quit(0)
