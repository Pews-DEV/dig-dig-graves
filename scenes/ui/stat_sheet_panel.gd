class_name StatSheetPanel
extends CanvasLayer
## Ficha do Coveiro (GDD §6, nó N01): todos os stats calculados, abertos com Tab.

var _panel: PanelContainer
var _rows: VBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	_build()


func _build() -> void:
	_panel = PanelContainer.new()
	_panel.theme_type_variation = &"ParchmentPanel"
	_panel.position = Vector2(402, 34)
	_panel.size = Vector2(220, 292)
	_panel.custom_minimum_size = _panel.size
	_panel.visible = false
	add_child(_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	_panel.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var title := Label.new()
	title.text = "FICHA DO COVEIRO"
	title.theme_type_variation = &"PanelTitle"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close := Button.new()
	close.text = "×"
	close.pressed.connect(close_panel)
	header.add_child(close)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	_rows = VBoxContainer.new()
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_rows)
	_refresh_rows()


func toggle() -> void:
	if not Game.tree.has_flag(&"stat_sheet"):
		Audio.play(&"shop_deny")
		return
	_panel.visible = not _panel.visible
	if _panel.visible:
		_refresh_rows()
		_panel.set_meta(&"panel_base", _panel.position)
		Juice.panel_open(_panel)
		Audio.play(&"ui_panel_open")
	else:
		Audio.play(&"ui_panel_close")


func close_panel() -> void:
	if _panel != null:
		_panel.visible = false


func is_open() -> bool:
	return _panel != null and _panel.visible


func _refresh_rows() -> void:
	if _rows == null:
		return
	for child: Node in _rows.get_children():
		child.queue_free()
	# GDD §18.2: só stats com rótulo, na ordem da Ficha; regras/ativos aparecem ao comprar.
	var stomp_on := Stats.get_value(StatSheet.STOMP_ENABLED) > 0.0
	for stat_id: StringName in StatSheet.DISPLAY.keys():
		var v := Stats.get_value(stat_id)
		if StatSheet.HIDE_WHEN_ZERO.has(stat_id) and v <= 0.0:
			continue
		if StatSheet.STOMP_STATS.has(stat_id) and not stomp_on:
			continue
		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = StatSheet.label_of(stat_id)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var value := Label.new()
		value.text = StatSheet.format_value(stat_id, Stats.get_value(stat_id))
		value.theme_type_variation = &"ParchmentTitle"
		row.add_child(value)
		_rows.add_child(row)


func _unhandled_input(event: InputEvent) -> void:
	if is_open() and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		close_panel()
