class_name AudioBank
extends RefCounted
## Índice puro de sons por id (UI/UX §8, GDD §17): `<id>.ogg` ou variações `<id>_<n>.ogg`.
## Decide o bus pelo prefixo do id e sorteia a variação sem repetir a anterior.

const MAX_VOICES := 6  # GDD §17: limite de vozes simultâneas por SFX
const PITCH_VARIATION := 0.06  # GDD §17: ±6%
const EXTENSIONS: Array[String] = ["ogg", "wav"]

## id -> Array[String] de caminhos, em ordem de variação.
var sounds: Dictionary = {}
var _last_pick: Dictionary = {}
var _variant_re := RegEx.create_from_string("^(.+)_([0-9]+)$")


## Adiciona arquivos. `allowed` (opcional) filtra ids: só entra o que está no manifesto.
func index_paths(paths: PackedStringArray, allowed: Callable = Callable()) -> void:
	var tmp: Dictionary = {}
	for p: String in paths:
		if not EXTENSIONS.has(p.get_extension().to_lower()):
			continue
		var base := p.get_file().get_basename()
		var id := base
		var order := 0
		var m := _variant_re.search(base)
		if m != null:
			id = m.get_string(1)
			order = int(m.get_string(2))
		if allowed.is_valid() and not bool(allowed.call(id)):
			continue
		if not tmp.has(id):
			tmp[id] = []
		(tmp[id] as Array).append([order, p])
	for id: String in tmp:
		var list: Array = tmp[id]
		list.sort_custom(func(a: Array, b: Array) -> bool: return int(a[0]) < int(b[0]))
		var out: Array[String] = []
		for e: Array in list:
			out.append(String(e[1]))
		sounds[StringName(id)] = out


func has(id: StringName) -> bool:
	return sounds.has(id)


func variants(id: StringName) -> Array[String]:
	var none: Array[String] = []
	return sounds.get(id, none) as Array[String]


## Caminho sorteado, evitando repetir a última variação quando há mais de uma. "" se não existe.
func pick(id: StringName, rng: RandomNumberGenerator) -> String:
	var list := variants(id)
	if list.is_empty():
		return ""
	if list.size() == 1:
		return list[0]
	var last := int(_last_pick.get(id, -1))
	var i := rng.randi_range(0, list.size() - 1)
	if i == last:
		i = (i + 1 + rng.randi_range(0, list.size() - 2)) % list.size()
	_last_pick[id] = i
	return list[i]


## Próxima variação em sequência (ex.: oil_tick alterna 1/2 como relógio). "" se não existe.
func pick_next(id: StringName) -> String:
	var list := variants(id)
	if list.is_empty():
		return ""
	var i := (int(_last_pick.get(id, -1)) + 1) % list.size()
	_last_pick[id] = i
	return list[i]


## Bus pelo prefixo do id (UI/UX §8: Master/Music/SFX/UI/Ambience).
static func bus_for(id: StringName) -> StringName:
	var s := String(id)
	if s.begins_with("mus_") or s.begins_with("jingle_") or s.begins_with("stinger_"):
		return &"Music"
	# AUDIO_MANIFEST: UI = ui_* (inclui ui_wisp_slide e ui_bury do título), node_*, root_grow,
	# level_up, screen_transition. logo_land/logo_thunk/logo_drip ficam no SFX (padrão);
	# mus_title em Music e amb_souls_choir em Ambience pelos prefixos.
	if s.begins_with("ui_") or s.begins_with("node_") or s in ["screen_transition", "root_grow", "level_up"]:
		return &"UI"
	if s.begins_with("amb_"):
		return &"Ambience"
	return &"SFX"


static func loops(id: StringName) -> bool:
	var s := String(id)
	return s.begins_with("mus_") or s.begins_with("amb_")


## Pitch aleatório ±variação em torno de `base`.
static func random_pitch(rng: RandomNumberGenerator, base: float = 1.0, variation: float = PITCH_VARIATION) -> float:
	return base * (1.0 + rng.randf_range(-variation, variation))


## Pode tocar mais uma voz deste id? (as mais antigas são interrompidas se não puder)
static func voice_available(active: int) -> bool:
	return active < MAX_VOICES
