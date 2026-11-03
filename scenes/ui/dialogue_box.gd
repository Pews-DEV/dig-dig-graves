class_name DialogueBox
extends Control
## Conversa bloqueante do capítulo: máquina de escrever, retratos e pulo segurando Esc.

const DIR := "res://data/dialogue/"
const TYPE_SPEED := 40.0
const SKIP_HOLD := 0.5
const PORTRAITS: Dictionary = {
	&"ceifa": &"portrait_dona_ceifa",
	&"tiao": &"portrait_tiao",
	&"coveiro": &"portrait_coveiro",
}
const VOICES: Dictionary = {
	&"ceifa": &"dialog_blip_ceifa",
	&"tiao": &"dialog_blip_tiao",
	&"coveiro": &"dialog_blip",
}

signal finished()

var _panel: NinePatchRect
var _portrait: TextureRect
var _name: Label
var _text: Label
var _advance: Label
var _data: DialogueData
var _line_index: int = 0
var _visible_count: int = 0
var _type_accum: float = 0.0
var _skip_accum: float = 0.0
var _last_voice_count: int = 0
var _portrait_sheet: AsepriteSheet
var _portrait_atlas := AtlasTexture.new()
var _speaker: StringName
var _finished: bool = false
var _previous_pause: bool = false
var _blocks_tree: bool = true
var _tip_remaining: float = 0.0
var _dim: TextureRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	size = Vector2(640, 360)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	# UI/UX §14.3: o fundo escurece 1 degrau em xadrez 01 (paleta fechada, sem alfa).
	var dim := TextureRect.new()
	dim.texture = OptionsMenu._checker()
	dim.stretch_mode = TextureRect.STRETCH_TILE
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	_dim = dim
	_portrait = TextureRect.new()
	_portrait.position = Vector2(28, 282)
	_portrait.size = Vector2(64, 64)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_portrait)
	_panel = NinePatchRect.new()
	_panel.texture = AssetManifest.texture("res://assets/ui/kit/balao.png")
	_panel.position = Vector2(96, 270)
	_panel.size = Vector2(518, 76)
	_panel.patch_margin_left = 4
	_panel.patch_margin_top = 4
	_panel.patch_margin_right = 4
	_panel.patch_margin_bottom = 5
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)
	_name = Label.new()
	_name.theme_type_variation = &"ParchmentTitle"
	_name.position = Vector2(109, 271)
	_name.size = Vector2(480, 14)
	_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_name)
	_text = Label.new()
	_text.theme_type_variation = &"ParchmentLabel"
	_text.position = Vector2(108, 289)
	_text.size = Vector2(484, 42)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.max_lines_visible = 3
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_text)
	_advance = Label.new()
	_advance.text = "▼"
	_advance.position = Vector2(586, 327)
	_advance.size = Vector2(18, 14)
	_advance.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_advance.add_theme_color_override("font_color", Palette.color(Palette.LANTERN_BRIGHT))
	_advance.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_advance)


func play_id(dialogue_id: StringName) -> void:
	var path := DIR + String(dialogue_id) + ".tres"
	if not ResourceLoader.exists(path):
		return
	_data = load(path) as DialogueData
	if _data == null or _data.lines.is_empty():
		return
	_finished = false
	_previous_pause = get_tree().paused
	_blocks_tree = true
	_dim.visible = true
	get_tree().paused = true
	visible = true
	_line_index = 0
	_show_line()
	Juice.slide_in(self, Vector2(0, 64), 0.0, 0.22)
	await finished
	if _blocks_tree:
		get_tree().paused = _previous_pause
	visible = false


func show_tip_id(dialogue_id: StringName) -> void:
	var path := DIR + String(dialogue_id) + ".tres"
	if not ResourceLoader.exists(path):
		return
	_data = load(path) as DialogueData
	if _data == null or _data.lines.is_empty():
		return
	_finished = false
	_blocks_tree = false
	_dim.visible = false  # dica não bloqueia: sem vinheta (UI/UX §14.1)
	visible = true
	var line: Dictionary = _data.lines[0]
	_name.visible = false
	_portrait.visible = false
	_panel.position = Vector2(12, 34)
	_panel.size = Vector2(220, 52)
	_text.position = Vector2(22, 42)
	_text.size = Vector2(198, 36)
	_text.text = str(line.get("text", ""))
	_text.visible_characters = -1
	_advance.visible = false
	_tip_remaining = 3.5
	await finished
	visible = false


func _show_line() -> void:
	if _line_index >= _data.lines.size():
		_finish()
		return
	var line: Dictionary = _data.lines[_line_index]
	_speaker = StringName(str(line.get("speaker", "coveiro")))
	_name.text = str(line.get("name", ""))
	_text.text = str(line.get("text", ""))
	_text.visible_characters = 0
	_visible_count = 0
	_type_accum = 0.0
	_last_voice_count = 0
	_advance.visible = false
	_portrait_sheet = AsepriteSheet.load_id(String(PORTRAITS.get(_speaker, &"portrait_coveiro")))
	_update_portrait(0.0)


func _process(delta: float) -> void:
	if not visible or _finished:
		return
	if not _blocks_tree:
		_tip_remaining -= delta
		if _tip_remaining <= 0.0:
			_finish()
		return
	if Input.is_action_pressed(&"pause"):
		_skip_accum += delta
		if _skip_accum >= SKIP_HOLD:
			_finish()
			return
	else:
		_skip_accum = 0.0
	queue_redraw()
	if _visible_count < _text.text.length():
		_type_accum += delta * TYPE_SPEED
		var next_count := mini(_text.text.length(), int(_type_accum))
		if next_count > _visible_count:
			_visible_count = next_count
			_text.visible_characters = _visible_count
			_play_voice_blip()
	else:
		_advance.visible = true
		_advance.position.y = 327 + (1 if int(Time.get_ticks_msec() / 180) % 2 == 0 else 0)
	_update_portrait(float(Time.get_ticks_msec()) / 1000.0)


func _update_portrait(time: float) -> void:
	if _portrait_sheet == null or _portrait_sheet.texture == null:
		_portrait.texture = null
		return
	var tag: StringName = &"talk" if _visible_count < _text.text.length() else &"idle"
	var frame := _portrait_sheet.frame_at(tag, time, true)
	_portrait_atlas.atlas = _portrait_sheet.texture
	_portrait_atlas.region = _portrait_sheet.frames[frame]
	_portrait.texture = _portrait_atlas


func _play_voice_blip() -> void:
	var count := _visible_count
	if count <= _last_voice_count:
		return
	var char := _text.text.substr(count - 1, 1)
	if count % 2 == 0 and not char.strip_edges().is_empty() and not ".,!?;:…".contains(char):
		Audio.play(VOICES.get(_speaker, &"dialog_blip"), 1.0, AudioBank.PITCH_VARIATION)
	_last_voice_count = count


func _gui_input(event: InputEvent) -> void:
	if not visible or _finished:
		return
	if event is InputEventMouseButton:
		var click := event as InputEventMouseButton
		if click.button_index == MOUSE_BUTTON_LEFT and click.pressed:
			accept_event()
			if _blocks_tree:
				_advance_dialogue()
			else:
				_finish()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _finished:
		return
	# The run scene also listens for this action to open the pause menu. Consume it
	# here so Esc/B only skips this conversation and cannot open a second overlay.
	if event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"ui_accept"):
		get_viewport().set_input_as_handled()
		_advance_dialogue()


func _advance_dialogue() -> void:
	if _visible_count < _text.text.length():
		_visible_count = _text.text.length()
		_text.visible_characters = -1
		_advance.visible = true
	else:
		_line_index += 1
		_show_line()


func _finish() -> void:
	if _finished:
		return
	_finished = true
	queue_redraw()
	finished.emit()


func _draw() -> void:
	if not _blocks_tree or _skip_accum <= 0.0 or _finished:
		return
	var center := Vector2(595, 334)
	draw_arc(center, 8.0, 0.0, TAU, 24, Palette.color(Palette.BONE_SHADOW), 1.0, true)
	var progress := clampf(_skip_accum / SKIP_HOLD, 0.0, 1.0)
	if progress > 0.0:
		draw_arc(center, 8.0, -PI * 0.5, -PI * 0.5 + TAU * progress, 24, Palette.color(Palette.LANTERN_BRIGHT), 1.0, true)
