extends "res://tests/test_case.gd"
## A substituição de um save não pode apagar o último arquivo válido.

const SAVE_PATH := "res://.test_save_atomicity.json"
const TEMP_PATH := SAVE_PATH + ".tmp"
const BACKUP_PATH := SAVE_PATH + ".bak"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_remove_file(SAVE_PATH)
	_remove_file(TEMP_PATH)
	_remove_file(BACKUP_PATH)

	check(SaveIO.write(SAVE_PATH, {"marker": 1}), "primeira gravação cria o save")
	check_eq(int(SaveIO.read(SAVE_PATH).get("marker", 0)), 1, "primeiro save pode ser lido")
	check(SaveIO.write(SAVE_PATH, {"marker": 2}), "gravação seguinte substitui o save")
	check_eq(int(SaveIO.read(SAVE_PATH).get("marker", 0)), 2, "novo save é instalado")
	check(not FileAccess.file_exists(BACKUP_PATH), "backup transitório é removido após o commit")

	# Bloqueia o caminho do backup com um diretório para simular falha ao
	# preservar o original. A gravação deve falhar sem tocar no save atual.
	check(SaveIO.write(SAVE_PATH, {"marker": 3}), "prepara save original para falha")
	var backup_absolute := ProjectSettings.globalize_path(BACKUP_PATH)
	check_eq(DirAccess.make_dir_recursive_absolute(backup_absolute), OK, "cria obstáculo no caminho do backup")
	check(not SaveIO.write(SAVE_PATH, {"marker": 4}), "falha ao preservar o original é reportada")
	check_eq(int(SaveIO.read(SAVE_PATH).get("marker", 0)), 3, "falha não apaga nem altera o original")
	check(not FileAccess.file_exists(TEMP_PATH), "temporário incompleto é removido após falha")
	check_eq(DirAccess.remove_absolute(backup_absolute), OK, "remove obstáculo de teste")

	# Simula interrupção logo depois de mover o save para .bak. A próxima leitura
	# recupera o backup, em vez de tratar o progresso como inexistente.
	var interrupted_err := DirAccess.rename_absolute(ProjectSettings.globalize_path(SAVE_PATH), backup_absolute)
	check_eq(interrupted_err, OK, "simula interrupção com backup recuperável")
	var recovered := SaveIO.read(SAVE_PATH)
	check_eq(int(recovered.get("marker", 0)), 3, "leitura recupera conteúdo do backup")
	check(FileAccess.file_exists(SAVE_PATH), "leitura restaura o caminho principal")
	check(not FileAccess.file_exists(BACKUP_PATH), "backup é consumido após recuperação")

	_remove_file(SAVE_PATH)
	_remove_file(TEMP_PATH)
	_remove_file(BACKUP_PATH)
	finish()


func _remove_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
