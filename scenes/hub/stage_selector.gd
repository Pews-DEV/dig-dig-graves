class_name StageSelector
extends Control
## Seletor compacto de estágios na superfície da árvore (Marco A: só o estágio 1).

signal stage_selected(stage_id: int)

const STAGES: Array[String] = [
	"Paróquia", "Indigentes", "Catacumbas", "Necrópole", "Jardim",
]

var unlocked: int = 1
var selected: int = 1
var unrest_full: bool = false
var face_button: Button
var _lanterns: Array[Button] = []
var _stage_labels: Array[Label] = []
var _title: Label


func setup(p_unlocked: int, p_selected: int, p_unrest_full: bool) -> void:
	unlocked = clampi(p_unlocked, 1, STAGES.size())
	selected = clampi(p_selected, 1, unlocked)
	unrest_full = p_unrest_full


func _ready() -> void:
	size = Vector2(320, 112)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"ParchmentPanel"
	panel.position = Vector2.ZERO
	panel.size = size
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	panel.add_child(column)
	_title = Label.new()
	_title.theme_type_variation = &"ParchmentTitle"
	_title.text = "CEMITÉRIO DO BOM DESCANSO"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_title)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	column.add_child(row)
	for i: int in STAGES.size():
		var stage := i + 1
		var button := Button.new()
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(48, 36)
		button.disabled = stage > unlocked
		button.tooltip_text = STAGES[i] if stage <= unlocked else tr("Capítulo %d: em breve") % stage
		button.pressed.connect(_select.bind(stage))
		row.add_child(button)
		var lantern := HudLantern.new()
		lantern.position = Vector2(12, -1)
		lantern.alert = stage > unlocked
		lantern.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(lantern)
		var label := Label.new()
		label.position = Vector2(0, 21)
		label.size = Vector2(48, 12)
		label.text = str(stage) if stage <= unlocked else "·"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.theme_type_variation = &"ParchmentLabel"
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(label)
		_lanterns.append(button)
		_stage_labels.append(label)
	face_button = Button.new()
	face_button.theme_type_variation = &"BigButton"
	face_button.text = "Enfrentar o Caixão Fujão"
	face_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	face_button.visible = unrest_full
	face_button.pressed.connect(Game.goto_boss)
	column.add_child(face_button)
	_update_selection()


func reveal_after_boss() -> void:
	if _lanterns.size() < 2:
		return
	_stage_labels[1].text = "II"
	_lanterns[1].tooltip_text = "Chave I recebida · Capítulo 2: em breve"
	_lanterns[1].modulate = Palette.color(Palette.BONE_BRIGHT)


func _select(stage_id: int) -> void:
	if stage_id > unlocked:
		return
	selected = stage_id
	_update_selection()
	stage_selected.emit(stage_id)
	Audio.play(&"stage_select")


func _update_selection() -> void:
	for i: int in _lanterns.size():
		var button := _lanterns[i]
		button.button_pressed = i + 1 == selected
		button.tooltip_text = STAGES[i] if i + 1 <= unlocked else tr("Capítulo %d: em breve") % (i + 1)
