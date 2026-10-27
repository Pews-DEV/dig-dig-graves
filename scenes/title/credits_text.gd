class_name CreditsText
extends RefCounted
## Converte CREDITS.md e assets/AUDIO_CREDITS.md em linhas para o pergaminho dos Créditos
## (UI/UX §9.4). Puro e testável. Cada linha: {"kind": &"title" | &"body" | &"gap", "text": String}.

const CREDITS_PATH := "res://CREDITS.md"
const AUDIO_CREDITS_PATH := "res://assets/AUDIO_CREDITS.md"
const TITLE := &"title"
const BODY := &"body"
const GAP := &"gap"

## Ferramentas gerais (as de áudio vêm do AUDIO_CREDITS.md).
const TOOLS: Array[String] = [
	"Godot Engine 4.7 (MIT)",
	"Aseprite (pixel art)",
	"Python + Pillow (geradores de arte)",
]
## Usado só se o CREDITS.md não tiver uma seção "Equipe".
const TEAM_FALLBACK: Array[String] = ["Equipe Dig Dig Graves"]


static func load_lines() -> Array[Dictionary]:
	var credits := FileAccess.get_file_as_string(CREDITS_PATH) if FileAccess.file_exists(CREDITS_PATH) else ""
	var audio := FileAccess.get_file_as_string(AUDIO_CREDITS_PATH) if FileAccess.file_exists(AUDIO_CREDITS_PATH) else ""
	return build(credits, audio)


## Abertura → Equipe → CREDITS.md (fontes, engine…) → AUDIO_CREDITS.md → Ferramentas → fim.
static func build(credits_md: String, audio_md: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	_add(out, TITLE, "DIG DIG GRAVES")
	_add(out, BODY, "Cava Cava Covas")
	_add(out, GAP, "")
	var credits := markdown_to_lines(credits_md)
	if not _has_title(credits, "Equipe"):
		_add(out, TITLE, "Equipe")
		for t: String in TEAM_FALLBACK:
			_add(out, BODY, t)
		_add(out, GAP, "")
	for l: Dictionary in credits:
		if l.kind == TITLE and String(l.text).begins_with("Créditos"):
			continue  # o título do arquivo vira a abertura acima
		out.append(l)
	_add(out, GAP, "")
	for l: Dictionary in markdown_to_lines(audio_md):
		if l.kind == TITLE and String(l.text).begins_with("Créditos de Áudio"):
			_add(out, TITLE, "Áudio")
			continue
		out.append(l)
	_add(out, GAP, "")
	_add(out, TITLE, "Ferramentas")
	for t: String in TOOLS:
		_add(out, BODY, t)
	_add(out, GAP, "")
	_add(out, BODY, "Obrigado por cavar!")
	return _collapse_gaps(out)


## Markdown simples → linhas: títulos (#), itens (-), tabelas (células unidas por " · "),
## parágrafos. Remove negrito, crases e links (fica o texto do link).
static func markdown_to_lines(md: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var link := RegEx.create_from_string("\\[([^\\]]+)\\]\\(([^)]+)\\)")
	var rows := md.replace("\r", "").split("\n")
	for i: int in rows.size():
		var raw := rows[i]
		var line := raw.strip_edges()
		if line.is_empty():
			_add(out, GAP, "")
			continue
		line = link.sub(line, "$1", true)
		line = line.replace("**", "").replace("`", "").replace("__", "")
		if line.begins_with("#"):
			_add(out, TITLE, line.lstrip("#").strip_edges())
		elif line.begins_with("|"):
			if _is_separator(line):
				continue
			# Cabeçalho da tabela (a linha seguinte é o separador) não aparece.
			if i + 1 < rows.size() and _is_separator(rows[i + 1].strip_edges()):
				continue
			var cells := PackedStringArray()
			for c: String in line.split("|"):
				var cell := c.strip_edges()
				if not cell.is_empty():
					cells.append(cell)
			_add(out, BODY, " · ".join(cells))
		elif line.begins_with("- ") or line.begins_with("* "):
			var indent := raw.length() - raw.lstrip(" ").length()
			_add(out, BODY, ("  " if indent > 0 else "") + line.substr(2).strip_edges())
		else:
			_add(out, BODY, line)
	return out


static func _is_separator(line: String) -> bool:
	if not line.begins_with("|"):
		return false
	for ch: String in line:
		if not (ch in ["|", "-", ":", " "]):
			return false
	return true


static func _has_title(lines: Array[Dictionary], text: String) -> bool:
	for l: Dictionary in lines:
		if l.kind == TITLE and String(l.text) == text:
			return true
	return false


static func _add(out: Array[Dictionary], kind: StringName, text: String) -> void:
	out.append({"kind": kind, "text": text})


## Sem lacunas duplicadas nem no começo/fim.
static func _collapse_gaps(lines: Array[Dictionary]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for l: Dictionary in lines:
		if l.kind == GAP and (out.is_empty() or out[out.size() - 1].kind == GAP):
			continue
		out.append(l)
	while not out.is_empty() and out[out.size() - 1].kind == GAP:
		out.pop_back()
	return out
