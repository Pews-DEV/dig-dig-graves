class_name ChapterEnd
extends Control
## Cartão "Fim do Capítulo 1" (GDD §13.2, UI/UX §19.1): diálogo de Dona Ceifa → cartão de
## pergaminho 360×220 sobre o céu da Árvore com o título letra a letra, estatísticas contando,
## os estágios seguintes em silhueta e os botões Continuar cavando (foco) e Créditos.

const CARD_PATH := "res://assets/ui/panels/chapter_card.png"
const CARD_SLICE := 8
const LETTER := 0.03
const STAT_STAGGER := 0.12
## Depois do jingle, `mus_tree` volta baixinho.
const MUSIC_AFTER := 8.0

var _credits: TitleCredits


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UiTheme.get_theme()
	var backdrop := ColorRect.new()
	backdrop.color = Palette.color(Palette.NIGHT)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	add_child(TreeAmbience.SkyLayer.new())
	await Game.show_dialogue(&"chapter_end")
	Audio.play_jingle(&"jingle_chapter_end")
	Audio.play_ambience(&"amb_night")
	get_tree().create_timer(MUSIC_AFTER).timeout.connect(func() -> void:
		if is_inside_tree():
			Audio.play_music(&"mus_tree"))
	_credits = TitleCredits.new()
	_build_card()
	add_child(_credits)


func _build_card() -> void:
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
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	var title := Label.new()
	title.text = tr("FIM DO CAPÍTULO 1")
	title.theme_type_variation = &"PanelTitle"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.visible_characters = 0
	box.add_child(title)
	var typing := title.create_tween()
	typing.tween_property(title, "visible_characters", title.text.length(), LETTER * title.text.length())
	var subtitle := Label.new()
	subtitle.text = tr("O Cemitério da Paróquia")
	subtitle.theme_type_variation = &"ParchmentTitle"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(subtitle)
	box.add_child(HSeparator.new())
	var start := LETTER * title.text.length() + 0.2
	var stats: Array[Array] = [
		[tr("Tempo de jogo"), Game.lifetime_value("play_time"), "time"],
		[tr("Noites cavadas"), float(Game.turns_played), "num"],
		[tr("Covas abertas"), maxf(Game.lifetime_value("graves"), float(_telemetry_graves())), "num"],
		[tr("Nós comprados"), float(_total_nodes()), "num"],
		[tr("Chefe vencido em (tentativas)"), float(maxi(1, Game.boss_1_attempts)), "num"],
	]
	for i: int in stats.size():
		_add_stat(box, String(stats[i][0]), float(stats[i][1]), String(stats[i][2]), start + i * STAT_STAGGER)
	var future := HBoxContainer.new()
	future.alignment = BoxContainer.ALIGNMENT_CENTER
	future.add_theme_constant_override("separation", 6)
	box.add_child(future)
	# GDD §13.2: os estágios seguintes em silhueta, "Em breve".
	for chapter: String in [tr("Capítulo 2"), tr("Capítulo 3"), tr("Capítulo 4"), tr("Capítulo 5")]:
		var l := Label.new()
		l.text = chapter
		l.add_theme_color_override("font_color", Palette.color(Palette.MOONSHADOW))
		future.add_child(l)
	var soon := Label.new()
	soon.text = tr("Em breve")
	soon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	soon.add_theme_color_override("font_color", Palette.color(Palette.BONE_SHADOW))
	box.add_child(soon)
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
	# Ao fechar os créditos, o foco volta para Continuar cavando (nenhuma tela sem volta).
	_credits.closed.connect(func() -> void: continue_btn.grab_focus())
	continue_btn.grab_focus()
	Juice.panel_open(panel)
	Juice.beckon(continue_btn)


func _add_stat(parent: VBoxContainer, label_text: String, target: float, fmt: String, delay: float) -> void:
	var row := HBoxContainer.new()
	row.modulate.a = 0.0
	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var value := Label.new()
	value.text = _format(0.0, fmt)
	value.theme_type_variation = &"PanelTitle"
	row.add_child(value)
	parent.add_child(row)
	var t := row.create_tween()
	t.tween_interval(delay)
	t.tween_property(row, "modulate:a", 1.0, 0.16)
	t.tween_callback(func() -> void:
		var formatter := func(v: float) -> String: return _format(v, fmt)
		Juice.count(value, 0.0, target, Juice.count_duration(target), formatter))


static func _format(v: float, fmt: String) -> String:
	if fmt == "time":
		var total := roundi(v)
		@warning_ignore("integer_division")
		var hours := total / 3600
		@warning_ignore("integer_division")
		var minutes := (total % 3600) / 60
		return "%dh%02d" % [hours, minutes] if hours > 0 else "%d min" % maxi(minutes, 0)
	return NumberFormat.format(roundf(v))


## Saves antigos (sem `lifetime`): soma o que a telemetria guardou.
func _telemetry_graves() -> int:
	var total := 0
	for entry: Dictionary in Game.telemetry:
		total += int(entry.get("graves_opened", 0))
	return total


func _total_nodes() -> int:
	var total := 0
	for id: StringName in Game.tree.order:
		if not Game.tree.get_node_data(id).starts_owned:
			total += Game.tree.level_of(id)
	return total
