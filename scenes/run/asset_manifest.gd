class_name AssetManifest
extends RefCounted
## Contrato com o pixel-artist (CLAUDE.md): só integra asset registrado em assets/MANIFEST.md.
## Se o asset não estiver listado (ou não existir), quem chama usa o placeholder de código.

const MANIFEST_PATH := "res://assets/MANIFEST.md"

static var _text: String = ""
static var _loaded: bool = false


static func is_listed(path: String) -> bool:
	if path.is_empty():
		return false
	if not _loaded:
		_loaded = true
		if FileAccess.file_exists(MANIFEST_PATH):
			_text = FileAccess.get_file_as_string(MANIFEST_PATH)
	return _text.contains(path.trim_prefix("res://"))


## Textura listada no manifesto, ou null.
static func texture(path: String) -> Texture2D:
	if is_listed(path) and ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null
