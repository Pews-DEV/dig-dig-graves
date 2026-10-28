extends Node


func _ready() -> void:
	var dialogue := DialogueBox.new()
	add_child(dialogue)
	await get_tree().process_frame
	var sheet := AsepriteSheet.load_id("portrait_coveiro")
	assert(sheet != null and sheet.texture != null, "Coveiro portrait sheet should load")
	dialogue._portrait_sheet = sheet
	dialogue._visible_count = 0
	dialogue._text.text = "Teste"
	dialogue._update_portrait(0.0)
	assert(dialogue._portrait.texture is AtlasTexture, "portrait should use an AtlasTexture")
	assert((dialogue._portrait.texture as AtlasTexture).region == sheet.frames[0], "portrait region should use current frame")
	await _test_blocking_dialogue_mouse_input(dialogue)
	await _test_tip_mouse_dismissal(dialogue)
	await _test_game_dialogue_attachment()
	print("PASS diálogo runtime: retrato, interação, dicas, skip e fluxo do Game")
	get_tree().quit(0)


func _test_blocking_dialogue_mouse_input(dialogue: DialogueBox) -> void:
	dialogue.play_id(&"first_grave")
	await get_tree().process_frame
	assert(get_tree().paused, "blocking dialogue should pause the game")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = Vector2(300, 310)
	get_viewport().push_input(click)
	await get_tree().process_frame
	assert(dialogue._visible_count == dialogue._text.text.length(), "first click should finish the typewriter line")
	click = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = Vector2(300, 310)
	get_viewport().push_input(click)
	await get_tree().process_frame
	assert(not dialogue.visible, "click on the final line should close the dialogue")
	assert(not get_tree().paused, "closing the dialogue should restore the previous pause state")
	await _test_skip_does_not_bubble_to_pause_menu(dialogue)


func _test_tip_mouse_dismissal(dialogue: DialogueBox) -> void:
	dialogue.show_tip_id(&"first_grave")
	await get_tree().process_frame
	assert(not get_tree().paused, "tip should not pause the game")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = Vector2(40, 50)
	get_viewport().push_input(click)
	await get_tree().process_frame
	assert(not dialogue.visible, "click should dismiss a non-blocking tip")


func _test_game_dialogue_attachment() -> void:
	# Exercise the production path used by ChapterEnd._ready while its parent is
	# being initialized. Keep this repeatable without writing dialogue_seen to disk.
	var data := load("res://data/dialogue/chapter_end.tres") as DialogueData
	assert(data != null, "chapter-end dialogue resource should load")
	data.once = false
	Game.dialogue_seen.clear()
	Game.turns_played = 1
	var run_scene: Node = load("res://scenes/run/run.tscn").instantiate()
	add_child(run_scene)
	await get_tree().process_frame
	var run_state := run_scene.get("state") as RunState
	assert(run_state != null, "run scene should initialize a live state")
	_game_dialogue_done = false
	call_deferred("_run_game_dialogue")
	var dialogue: DialogueBox
	for _frame: int in 5:
		await get_tree().process_frame
		dialogue = _find_dialogue_box(get_tree().root)
		if dialogue != null and dialogue.visible:
			break
	assert(dialogue != null and dialogue.visible, "Game should attach and open a blocking dialogue on the root")
	assert(get_tree().paused, "Game dialogue path should pause gameplay")
	var paused_elapsed := run_state.elapsed if run_state != null else 0.0
	var paused_oil := run_state.oil if run_state != null else 0.0
	for _frame: int in 30:
		await get_tree().process_frame
	if run_state != null:
		assert(is_equal_approx(run_state.elapsed, paused_elapsed), "dialogue should freeze the night timer")
		assert(is_equal_approx(run_state.oil, paused_oil), "dialogue should freeze oil consumption")
	if dialogue != null:
		dialogue._finish()
	for _frame: int in 5:
		if _game_dialogue_done:
			break
		await get_tree().process_frame
	assert(_game_dialogue_done, "Game dialogue coroutine should finish after the dialogue closes")
	assert(not get_tree().paused, "Game dialogue path should restore the previous pause state")
	await _test_game_tip_attachment(run_state)
	run_scene.queue_free()
	await get_tree().process_frame


func _find_dialogue_box(node: Node) -> DialogueBox:
	if node is DialogueBox and (node as DialogueBox).visible:
		return node as DialogueBox
	for child: Node in node.get_children():
		var found := _find_dialogue_box(child)
		if found != null:
			return found
	return null


var _game_dialogue_done: bool = false


func _run_game_dialogue() -> void:
	await Game.show_dialogue(&"chapter_end")
	_game_dialogue_done = true


func _test_game_tip_attachment(run_state: RunState) -> void:
	var data := load("res://data/dialogue/first_grave.tres") as DialogueData
	assert(data != null, "first-grave tip resource should load")
	data.once = false
	Game.dialogue_seen.clear()
	_game_tip_done = false
	call_deferred("_run_game_tip")
	var tip: DialogueBox
	for _frame: int in 5:
		await get_tree().process_frame
		tip = _find_dialogue_box(get_tree().root)
		if tip != null:
			break
	assert(tip != null, "Game should attach and show a non-blocking tip")
	assert(not get_tree().paused, "non-blocking tip should not pause gameplay")
	var elapsed_before := run_state.elapsed
	await get_tree().process_frame
	await get_tree().process_frame
	assert(run_state.elapsed > elapsed_before, "night timer should continue during a non-blocking tip")
	if tip != null:
		tip._finish()
	for _frame: int in 5:
		if _game_tip_done:
			break
		await get_tree().process_frame
	assert(_game_tip_done, "Game tip coroutine should finish after dismissal")
	assert(not get_tree().paused, "dismissing a tip should leave gameplay unpaused")


var _game_tip_done: bool = false


func _run_game_tip() -> void:
	await Game.show_tip(&"first_grave")
	_game_tip_done = true


func _test_skip_does_not_bubble_to_pause_menu(dialogue: DialogueBox) -> void:
	dialogue.play_id(&"first_grave")
	await get_tree().process_frame
	var skip_event := InputEventAction.new()
	skip_event.action = &"pause"
	skip_event.pressed = true
	dialogue._unhandled_input(skip_event)
	assert(get_viewport().is_input_handled(), "dialogue should consume Esc/B instead of bubbling to run pause")
	Input.action_press(&"pause")
	dialogue._process(DialogueBox.SKIP_HOLD)
	Input.action_release(&"pause")
	await get_tree().process_frame
	assert(not dialogue.visible, "holding Esc/B for 0.5 s should skip and close the dialogue")
	assert(not get_tree().paused, "skipping should restore the previous pause state")
