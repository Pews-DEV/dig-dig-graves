extends Node
## Vitória do chefe → Resumo especial → revelação → Fim do Capítulo → nova noite.

const TEST_SAVE_PATH := "res://.test_chapter_end_flow_save.json"

var _failures: Array[String] = []


func _ready() -> void:
	# Nunca grave esta integração no save do usuário.
	SaveIO.delete(TEST_SAVE_PATH)
	SaveManager.save_path = TEST_SAVE_PATH
	Game.turns_played = 1
	Game.boss_1_attempts = 0
	Game.boss_1_won = false
	Game.boss_run = true
	Game.chapter_1_end_seen = false
	Game.dialogue_seen.clear()
	Game.dialogue_seen[&"boss_intro"] = true
	Game.dialogue_seen[&"boss_victory"] = true
	Game.dialogue_seen[&"chapter_end"] = true
	var result := TurnResult.new()
	result.boss_encounter = true
	result.boss_victory = true
	result.end_reason = &"boss_victory"
	var run_scene: Node = load("res://scenes/run/run.tscn").instantiate()
	get_tree().root.call_deferred("add_child", run_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().current_scene = null
	var run_state := run_scene.get("state") as RunState
	_check(run_state != null, "vitória é emitida por uma noite real do chefe")
	if run_state == null:
		await _finish(1)
		return
	run_state.ended = true
	run_state.finished.emit(result)
	var summary := await _wait_for_scene("res://scenes/run/turn_summary.tscn", 50)
	_check(summary != null, "vitória do chefe abre o Resumo especial")
	if summary == null:
		await _finish(1)
		return
	run_scene.queue_free()
	await get_tree().process_frame
	var reveal_button := _find_button(summary, "Ver o cemitério")
	_check(reveal_button != null, "Resumo da primeira vitória oferece Ver o cemitério")
	if reveal_button == null:
		await _finish(1)
		return
	# Trocar cena mantendo este runner vivo para verificar as cenas subsequentes.
	reveal_button.pressed.emit()
	var tree_scene := await _wait_for_scene("res://scenes/tree/skill_tree.tscn", 50)
	_check(tree_scene != null, "Ver o cemitério abre o Pátio após a vitória")
	if tree_scene == null:
		await _finish(1)
		return
	# The designed key reveal lasts 2.3 s; wait in wall time rather than spinning frames.
	await get_tree().create_timer(2.6).timeout
	var chapter_scene := await _wait_for_scene("res://scenes/ui/chapter_end.tscn", 50)
	_check(chapter_scene != null, "revelação da Chave leva ao Fim do Capítulo 1")
	_check(Game.chapter_1_end_seen, "marco do capítulo é salvo ao abrir o cartão")
	var saved := SaveIO.read(TEST_SAVE_PATH)
	var progress: Dictionary = saved.get("progress", {})
	_check(bool(progress.get("chapter_1_end_seen", false)), "save v2 registra Fim do Capítulo")
	if chapter_scene == null:
		await _finish(1)
		return
	var continue_button := _find_button(chapter_scene, "Continuar cavando")
	_check(continue_button != null, "Fim do Capítulo oferece Continuar cavando")
	if continue_button == null:
		await _finish(1)
		return
	continue_button.pressed.emit()
	var patio_scene := await _wait_for_scene("res://scenes/tree/skill_tree.tscn", 50)
	_check(patio_scene != null, "Continuar cavando retorna ao Pátio")
	if patio_scene == null:
		await _finish(1)
		return
	var dig_button := _find_button(patio_scene, "Próxima Noite")
	_check(dig_button != null, "Pátio oferece Próxima Noite após o capítulo")
	if dig_button == null:
		await _finish(1)
		return
	dig_button.pressed.emit()
	var next_run_scene := await _wait_for_scene("res://scenes/run/run.tscn", 50)
	_check(next_run_scene != null, "Próxima Noite inicia nova escavação")
	await _finish(0 if _failures.is_empty() else 1)


func _wait_for_scene(path: String, max_checks: int) -> Node:
	for _check_index: int in max_checks:
		var scene := get_tree().current_scene
		if scene != null and scene.scene_file_path == path and not Game.is_changing_scene():
			return scene
		await get_tree().create_timer(0.1).timeout
	var scene := get_tree().current_scene
	return scene if scene != null and scene.scene_file_path == path and not Game.is_changing_scene() else null


func _finish(exit_code: int) -> void:
	for failure: String in _failures:
		printerr("FAIL ", failure)
	if exit_code == 0 and _failures.is_empty():
		print("PASS vitória do chefe → Resumo especial → capítulo → continuar cavando")
	else:
		print("FAIL integração da vitória até a próxima noite")
	var active_scene := get_tree().current_scene
	get_tree().current_scene = null
	if active_scene != null:
		active_scene.queue_free()
	SaveIO.delete(TEST_SAVE_PATH)
	await get_tree().process_frame
	get_tree().quit(exit_code if not _failures.is_empty() else 0)


func _check(condition: bool, label: String) -> void:
	if not condition:
		_failures.append(label)


func _find_button(node: Node, expected_text: String) -> Button:
	if node is Button and (node as Button).text.begins_with(expected_text):
		return node as Button
	for child: Node in node.get_children():
		var found := _find_button(child, expected_text)
		if found != null:
			return found
	return null
