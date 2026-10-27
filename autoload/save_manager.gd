extends Node
## Save do jogo em user://save.json (GDD §18.2). Lógica de arquivo em SaveIO.

var save_path: String = "user://save.json"


func has_save() -> bool:
	return FileAccess.file_exists(save_path)


func write(data: Dictionary) -> bool:
	var ok := SaveIO.write(save_path, data)
	if ok:
		Events.game_saved.emit()
	return ok


func read() -> Dictionary:
	return SaveIO.read(save_path)


func delete_save() -> void:
	SaveIO.delete(save_path)


## Novo Jogo com save existente: guarda uma cópia enterrada e libera o save.
func bury_save() -> bool:
	return SaveIO.bury(save_path)
