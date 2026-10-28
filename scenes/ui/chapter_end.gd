class_name ChapterEnd
extends Control
## Cartão do fim do Capítulo 1 (GDD §19.1 / UI/UX §15).

const CARD_PATH := "res://assets/ui/panels/chapter_card.png"
const CARD_SLICE := 8

var _credits: TitleCredits


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UiTheme.get_theme()
	await Game.show_dialogue(&"chapter_end")
	Audio.play_jingle(&"jingle_chapter_end")
	Audio.play_ambience(&"amb_night")
	_credits = TitleCredits.new()
	_credits.closed.connect(func() -> void: pass)
	_build_card()
	add_child(_credits)


func _build_card() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Palette.color(Palette.NIGHT)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var canopy := TreeAmbience.Canopy.new()
	canopy.position = Vector2.ZERO
	add_child(canopy)
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"ParchmentPanel"
	panel.position = Vector2(140, 70)
	panel.size = Vector2(360, 220)
	panel.custom_minimum_size = panel.size
	var card_texture := AssetManifest.texture(CARD_PATH)
	if card_texture != null:
		var card_style := StyleBoxTexture.new()
		card_style.texture = card_texture
		card_style.set_texture_margin_all(CARD_SLICE)
		card_style.content_margin_left = 14
		card_style.content_margin_right = 14
		card_style.content_margin_top = 8
		card_style.content_margin_bottom = 10
		panel.add_theme_stylebox_override("panel", card_style)
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	panel.add_child(box)
	var title := Label.new()
	title.text = tr("FIM DO CAPÍTULO 1")
	title.theme_type_variation = &"PanelTitle"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var subtitle := Label.new()
	subtitle.text = tr("O Cemitério da Paróquia")
	subtitle.theme_type_variation = &"ParchmentTitle"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(subtitle)
	box.add_child(HSeparator.new())
	_add_stat(box, tr("Noites cavadas"), str(Game.turns_played))
	_add_stat(box, tr("Covas abertas"), str(_total_stat("graves_opened")))
	_add_stat(box, tr("Nós comprados"), str(_total_nodes()))
	_add_stat(box, tr("Tentativas no chefe"), str(Game.boss_1_attempts))
	var future := Label.new()
	future.text = tr("Capítulo 2 · Campo dos Indigentes · Em breve")
	future.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	future.add_theme_color_override("font_color", Palette.color(Palette.BONE_SHADOW))
	box.add_child(future)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 12)
	box.add_child(actions)
	var continue_btn := Button.new()
	continue_btn.theme_type_variation = &"BigButton"
	continue_btn.text = tr("Continuar cavando")
	continue_btn.pressed.connect(Game.goto_tree)
	actions.add_child(continue_btn)
	var credits_btn := Button.new()
	credits_btn.theme_type_variation = &"BigButton"
	credits_btn.text = tr("Créditos")
	credits_btn.pressed.connect(_credits.open)
	actions.add_child(credits_btn)
	continue_btn.grab_focus()
	Juice.panel_open(panel)


func _add_stat(parent: VBoxContainer, label_text: String, value_text: String) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var value := Label.new()
	value.text = value_text
	value.theme_type_variation = &"PanelTitle"
	row.add_child(value)
	parent.add_child(row)


func _total_stat(key: String) -> int:
	var total := 0
	for entry: Dictionary in Game.telemetry:
		total += int(entry.get(key, 0))
	return total


func _total_nodes() -> int:
	var total := 0
	for id: StringName in Game.tree.order:
		if not Game.tree.get_node_data(id).starts_owned:
			total += Game.tree.level_of(id)
	return total
