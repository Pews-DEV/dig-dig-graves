class_name AsepriteSheet
extends RefCounted
## Folha de animação exportada pelo Aseprite (PNG + JSON "Array" ou "Hash", com frameTags).
## O layout vem do JSON, nunca adivinhado (CLAUDE.md). Sem JSON ou sem PNG no manifesto = null,
## e quem usa desenha o placeholder.

var texture: Texture2D
var frames: Array[Rect2] = []
## Duração de cada frame em segundos.
var durations: Array[float] = []
## tag -> Vector2i(from, to)
var tags: Dictionary = {}


## Lê o JSON do Aseprite (puro, testável). Retorna null se não houver frames.
static func from_json_text(text: String) -> AsepriteSheet:
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		return null
	var data: Dictionary = parsed
	var raw: Variant = data.get("frames", [])
	var list: Array = []
	if raw is Array:
		list = raw
	elif raw is Dictionary:
		list = (raw as Dictionary).values()
	if list.is_empty():
		return null
	var sheet := AsepriteSheet.new()
	for f: Variant in list:
		if not f is Dictionary:
			continue
		var r: Dictionary = (f as Dictionary).get("frame", {})
		sheet.frames.append(Rect2(float(r.get("x", 0)), float(r.get("y", 0)), float(r.get("w", 0)), float(r.get("h", 0))))
		sheet.durations.append(maxf(0.001, float((f as Dictionary).get("duration", 100)) / 1000.0))
	var meta: Dictionary = data.get("meta", {})
	for tag: Variant in meta.get("frameTags", []):
		if tag is Dictionary:
			var td: Dictionary = tag
			var from := clampi(int(td.get("from", 0)), 0, sheet.frames.size() - 1)
			var to := clampi(int(td.get("to", from)), from, sheet.frames.size() - 1)
			sheet.tags[StringName(str(td.get("name", "")))] = Vector2i(from, to)
	return sheet


## PNG do manifesto + JSON de mesmo nome. Null se faltar qualquer um.
static func load_sheet(png_path: String) -> AsepriteSheet:
	if png_path.is_empty():
		return null
	var tex := AssetManifest.texture(png_path)
	if tex == null:
		return null
	var json_path := png_path.get_basename() + ".json"
	if not FileAccess.file_exists(json_path):
		return null
	var sheet := from_json_text(FileAccess.get_file_as_string(json_path))
	if sheet != null:
		sheet.texture = tex
	return sheet


## Folha pelo id do manifesto (ex.: "coveiro_title"), ou null.
static func load_id(id: String) -> AsepriteSheet:
	return load_sheet(AssetManifest.path_for(id))


func has_tag(tag: StringName) -> bool:
	return tags.has(tag)


func frame_size() -> Vector2:
	return frames[0].size if not frames.is_empty() else Vector2.ZERO


## Intervalo de frames da tag (a folha inteira se a tag não existir).
func tag_range(tag: StringName) -> Vector2i:
	if tags.has(tag):
		return tags[tag] as Vector2i
	return Vector2i(0, frames.size() - 1)


func tag_duration(tag: StringName) -> float:
	var r := tag_range(tag)
	var total := 0.0
	for i: int in range(r.x, r.y + 1):
		total += durations[i]
	return total


## Frame absoluto da tag no tempo `t` (s). Sem loop, segura o último frame.
func frame_at(tag: StringName, t: float, loop: bool = true) -> int:
	var r := tag_range(tag)
	var total := tag_duration(tag)
	var x := fmod(maxf(t, 0.0), total) if loop else minf(maxf(t, 0.0), total - 0.0001)
	for i: int in range(r.x, r.y + 1):
		if x < durations[i]:
			return i
		x -= durations[i]
	return r.y


## Desenha o frame com o pivô em `pos` (pixels inteiros).
func draw_frame(ci: CanvasItem, index: int, pos: Vector2, pivot: Vector2, flip: bool = false) -> void:
	if texture == null or index < 0 or index >= frames.size():
		return
	var src := frames[index]
	if flip:
		ci.draw_set_transform(pos.round(), 0.0, Vector2(-1, 1))
		ci.draw_texture_rect_region(texture, Rect2(-pivot, src.size), src)
		ci.draw_set_transform(Vector2.ZERO)
	else:
		ci.draw_texture_rect_region(texture, Rect2((pos - pivot).round(), src.size), src)
