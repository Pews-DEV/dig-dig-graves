class_name SaveIO
extends RefCounted
## Leitura/escrita pura do save JSON (GDD §18.2): campo `version` + migrações.
## O autoload SaveManager só embrulha isto e avisa o jogo por Events.

const SAVE_VERSION := 2
## Custos da árvore da demo/M0 (base, crescimento, moeda), necessários para a
## devolução integral prescrita na migração v1 → v2.
const LEGACY_NODE_COSTS: Dictionary = {
	"E01": ["copper", 10.0, 1.45], "E02": ["copper", 25.0, 1.55],
	"E03": ["bones", 15.0, 6.0], "E04": ["copper", 60.0, 1.6],
	"E05": ["bones", 20.0, 1.8], "F01": ["copper", 20.0, 1.5],
	"F02": ["copper", 40.0, 1.55], "L01": ["copper", 15.0, 1.5],
	"C02": ["copper", 60.0, 1.6], "C03": ["bones", 30.0, 5.0],
}


static func write(path: String, data: Dictionary) -> bool:
	data["version"] = SAVE_VERSION
	data["saved_at"] = Time.get_unix_time_from_system()
	var tmp_path := path + ".tmp"
	var backup_path := path + ".bak"
	var dir := DirAccess.open(path.get_base_dir())
	if dir == null:
		push_error("SaveIO: não foi possível abrir o diretório de save %s (%s)" % [path.get_base_dir(), error_string(DirAccess.get_open_error())])
		return false
	var save_name := path.get_file()
	var tmp_name := tmp_path.get_file()
	var backup_name := backup_path.get_file()
	# Se uma execução anterior foi interrompida após mover o original, restaura-o
	# antes de iniciar outra gravação. O backup nunca é descartado nessa etapa.
	if not dir.file_exists(save_name) and dir.file_exists(backup_name):
		var recover_err := dir.rename(backup_name, save_name)
		if recover_err != OK:
			push_error("SaveIO: não foi possível recuperar o backup %s (%s)" % [backup_name, error_string(recover_err)])
			return false
	var f := FileAccess.open(tmp_path, FileAccess.WRITE)
	if f == null:
		push_error("SaveIO: não foi possível abrir %s (%s)" % [tmp_path, error_string(FileAccess.get_open_error())])
		return false
	f.store_string(JSON.stringify(data, "\t"))
	f.flush()
	var write_err := f.get_error()
	f.close()
	if write_err != OK:
		dir.remove(tmp_name)
		push_error("SaveIO: escrita do temporário falhou (%s)" % error_string(write_err))
		return false

	# DirAccess.rename não substitui um arquivo existente em todas as plataformas.
	# Preserve o original em .bak antes de instalar o temporário. Se a instalação
	# falhar, restaure o original; se a restauração também falhar, o .bak fica no
	# disco para recuperação na próxima leitura/gravação.
	var had_original := dir.file_exists(save_name)
	if had_original and dir.file_exists(backup_name):
		var cleanup_err := dir.remove(backup_name)
		if cleanup_err != OK:
			dir.remove(tmp_name)
			push_error("SaveIO: não foi possível liberar o backup antigo (%s)" % error_string(cleanup_err))
			return false
	if had_original:
		var backup_err := dir.rename(save_name, backup_name)
		if backup_err != OK:
			dir.remove(tmp_name)
			push_error("SaveIO: não foi possível preservar o save atual (%s)" % error_string(backup_err))
			return false

	var err := dir.rename(tmp_name, save_name)
	if err != OK:
		if had_original:
			var restore_err := dir.rename(backup_name, save_name)
			if restore_err != OK:
				push_error("SaveIO: rename falhou (%s); save original preservado em %s, restauração falhou (%s)" % [error_string(err), backup_name, error_string(restore_err)])
			else:
				push_error("SaveIO: rename falhou (%s); save original restaurado" % error_string(err))
		else:
			push_error("SaveIO: rename falhou (%s)" % error_string(err))
		dir.remove(tmp_name)
		return false
	if had_original and dir.file_exists(backup_name):
		# O novo arquivo já está instalado. Uma falha ao apagar o backup é segura:
		# ele fica como cópia recuperável, sem invalidar o sucesso da gravação.
		dir.remove(backup_name)
	return true


## Retorna {} se não houver save ou se ele estiver corrompido.
static func read(path: String) -> Dictionary:
	_recover_backup(path)
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_warning("SaveIO: save inválido em %s; ignorando." % path)
		return {}
	return migrate(parsed as Dictionary)


static func _recover_backup(path: String) -> void:
	if FileAccess.file_exists(path):
		return
	var dir := DirAccess.open(path.get_base_dir())
	if dir == null:
		return
	var backup_name := path.get_file() + ".bak"
	if not dir.file_exists(backup_name):
		return
	var err := dir.rename(backup_name, path.get_file())
	if err != OK:
		push_warning("SaveIO: save ausente; backup %s continua disponível (%s)." % [backup_name, error_string(err)])


static func delete(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


## "Enterrar" (Novo Jogo, UI/UX §9.4): o save não é apagado de vez, é movido para
## `<nome>_buried.json` (só o último enterro fica guardado), recuperável à mão.
static func bury(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return true
	var backup := buried_path(path)
	if FileAccess.file_exists(backup):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(backup))
	var err := DirAccess.rename_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(backup))
	if err != OK:
		push_error("SaveIO: não foi possível enterrar o save (%s)" % error_string(err))
		return false
	return true


static func buried_path(path: String) -> String:
	return path.get_basename() + "_buried." + path.get_extension()


## Migrações por versão: cada passo leva de v para v+1.
static func migrate(data: Dictionary) -> Dictionary:
	var v := int(data.get("version", 0))
	if v < 1:
		# v0 (sem campo version) → v1: nada a converter ainda.
		v = 1
	while v < SAVE_VERSION:
		if v == 1:
			data = _migrate_v1_to_v2(data)
		v += 1
	data["version"] = SAVE_VERSION
	return data


static func _migrate_v1_to_v2(data: Dictionary) -> Dictionary:
	var currencies: Dictionary = data.get("currencies", {}) as Dictionary
	var old_tree: Dictionary = data.get("tree", {}) as Dictionary
	for node_id: String in LEGACY_NODE_COSTS:
		var level := clampi(int(old_tree.get(node_id, 0)), 0, 100)
		if level <= 0:
			continue
		var cost: Array = LEGACY_NODE_COSTS[node_id]
		var currency := str(cost[0])
		var total := 0.0
		for bought_level: int in level:
			total += ceilf(float(cost[1]) * pow(float(cost[2]), bought_level) - 0.000001)
		currencies[currency] = float(currencies.get(currency, 0.0)) + total
	data["currencies"] = currencies
	data["tree"] = {}
	var progress: Dictionary = data.get("progress", {}) as Dictionary
	progress["unrest"] = {}
	progress["boss_1_won"] = false
	progress["boss_1_attempts"] = 0
	progress["chapter_1_end_seen"] = false
	data["progress"] = progress
	return data
