class_name FontSample
extends Control
## Amostra de tipografia (UI/UX §2: "testar ÇÃÕÉÊÍÓÚ ção ções"). Só com `-- --font-test`.

const SAMPLE := "ÇÃÕÉÊÍÓÚ ção ções"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UiTheme.get_theme()  # fica fora da cena atual (camada do Game)
	position = Vector2(6, 92)
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"ParchmentPanel"
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	panel.add_child(box)
	_add(box, &"ParchmentTitle", "m6x11+ 18: " + SAMPLE)
	_add(box, &"ParchmentLabel", "m5x7 16: " + SAMPLE + "  1.234 → 0,94 s")
	var wood := PanelContainer.new()
	box.add_child(wood)
	var inner := VBoxContainer.new()
	wood.add_child(inner)
	_add(inner, &"PanelTitle", "Sobre madeira: " + SAMPLE)
	_add(inner, &"Label", "Corpo sobre madeira: " + SAMPLE)
	_add(box, &"TitleLabel", "Sobre o mundo: " + SAMPLE)
	_add(box, &"HudLabel", "Rótulo com contorno: " + SAMPLE)


func _add(parent: Control, variation: StringName, text: String) -> void:
	var l := Label.new()
	l.theme_type_variation = variation
	l.text = text
	parent.add_child(l)
