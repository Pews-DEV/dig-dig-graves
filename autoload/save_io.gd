class_name SaveIO
extends RefCounted
## Leitura/escrita pura do save JSON (GDD §18.2): campo `version` + migrações.
## O autoload SaveManager só embrulha isto e avisa o jogo por Events.

const SAVE_VERSION := 1


static func write(path: String, data: Dictionary) -> bool:
	data["version"] = SAVE_VERSION
	data["saved_at"] = Time.get_unix_time_from_system()
	var tmp_path := path + ".tmp"
	var f := FileAccess.open(tmp_path, FileAccess.WRITE)
	if f == null:
		push_error("SaveIO: não foi possível abrir %s (%s)" % [tmp_path, error_string(FileAccess.get_open_error())])
		return false
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	# Escreve num temporário e renomeia: um crash no meio não corrompe o save.
	var dir := DirAccess.open(path.get_base_dir())
	if dir == null:
		return false
	if dir.file_exists(path.get_file()):
		dir.remove(path.get_file())
	var err := dir.rename(tmp_path.get_file(), path.get_file())
	if err != OK:
		push_error("SaveIO: rename falhou (%s)" % error_string(err))
		return false
	return true


## Retorna {} se não houver save ou se ele estiver corrompido.
static func read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_warning("SaveIO: save inválido em %s; ignorando." % path)
		return {}
	return migrate(parsed as Dictionary)


static func delete(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


## Migrações por versão: cada passo leva de v para v+1.
static func migrate(data: Dictionary) -> Dictionary:
	var v := int(data.get("version", 0))
	if v < 1:
		# v0 (sem campo version) → v1: nada a converter ainda.
		v = 1
	data["version"] = v
	return data
