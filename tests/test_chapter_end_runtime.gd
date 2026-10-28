extends Node
## Fluxo visível de vitória do chefe até o cartão do Capítulo 1.


func _ready() -> void:
	Game.dialogue_seen[&"chapter_end"] = true
	var screen := ChapterEnd.new()
	add_child(screen)
	await get_tree().process_frame
	await get_tree().process_frame
	assert(screen._credits != null, "chapter end should initialize its credits panel before connecting the button")
	var panels := screen.find_children("*", "PanelContainer", true, false)
	assert(not panels.is_empty(), "chapter end card should have a panel")
	var card := panels[0] as PanelContainer
	var card_style := card.get_theme_stylebox("panel") as StyleBoxTexture
	assert(card_style != null and card_style.texture != null and card_style.texture.get_size() == Vector2(48, 48), "chapter end should use the delivered 9-slice card art")
	assert(is_equal_approx(card.size.x, 360.0) and is_equal_approx(card.size.y, 220.0), "chapter end card should match the 360x220 UI spec")
	var buttons: Array[Button] = []
	_collect_buttons(screen, buttons)
	var continue_button: Button
	var credits_button: Button
	for button: Button in buttons:
		if button.text == tr("Continuar cavando"):
			continue_button = button
		elif button.text == tr("Créditos"):
			credits_button = button
	assert(continue_button != null, "chapter end should offer Continue Digging")
	assert(credits_button != null, "chapter end should offer Credits")
	credits_button.pressed.emit()
	await get_tree().process_frame
	assert(screen._credits.visible, "Credits button should open the credits panel")
	print("PASS chapter end card, Continue Digging, and Credits flow")
	get_tree().quit(0)


func _collect_buttons(node: Node, result: Array[Button]) -> void:
	if node is Button:
		result.append(node as Button)
	for child: Node in node.get_children():
		_collect_buttons(child, result)
