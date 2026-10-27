class_name AssetManifest
extends RefCounted
## Contrato com o pixel-artist (CLAUDE.md): só integra asset registrado em assets/MANIFEST.md.
## Se o asset não estiver listado (ou não existir), quem chama usa o placeholder de código.

const MANIFEST_PATH := "res://assets/MANIFEST.md"

static var _text: String = ""
static var _loaded: bool = false


static func _ensure() -> void:
	if not _loaded:
		_loaded = true
		if FileAccess.file_exists(MANIFEST_PATH):
			_text = FileAccess.get_file_as_string(MANIFEST_PATH)


static func is_listed(path: String) -> bool:
	if path.is_empty():
		return false
	_ensure()
	return _text.contains(path.trim_prefix("res://"))


## Textura listada no manifesto, ou null.
static func texture(path: String) -> Texture2D:
	if is_listed(path) and ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


## Caminho `res://` do PNG registrado na linha do `id` (1ª coluna da tabela), ou "".
static func path_for(id: String) -> String:
	_ensure()
	return path_in(_text, id)


## Versão pura de path_for (testável): procura a linha "| id | `caminho.png` …".
static func path_in(text: String, id: String) -> String:
	for line: String in text.split("\n"):
		var cells := line.split("|")
		if cells.size() < 3 or cells[1].strip_edges() != id:
			continue
		var parts := cells[2].split("`")
		for i: int in range(1, parts.size(), 2):
			if parts[i].ends_with(".png"):
				return "res://" + parts[i].strip_edges().trim_prefix("res://")
	return ""


## Textura do `id` do manifesto, ou null (não registrado ainda / não importado).
static func texture_by_id(id: String) -> Texture2D:
	var path := path_for(id)
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


## Relê o manifesto (os artistas entregam durante o desenvolvimento).
static func reload() -> void:
	_loaded = false
	_text = ""
