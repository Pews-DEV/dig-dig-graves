extends Node
## Áudio do jogo (GDD §17, UI/UX §8). Buses Master/Music/SFX/UI/Ambience, pool de players,
## variações `<id>_<n>.ogg` sorteadas, pitch ±6%, máx. 6 vozes por id e crossfade de música.
## Id sem arquivo (ou fora do AUDIO_MANIFEST) = silêncio, sem erro.

const SFX_DIR := "res://assets/sfx/"
const MUSIC_DIR := "res://assets/music/"
const MANIFEST_PATH := "res://assets/AUDIO_MANIFEST.md"
const BUSES: Array[StringName] = [&"Music", &"SFX", &"UI", &"Ambience"]
const POOL_SIZE := 24
const CROSSFADE := 1.2
const SILENT_DB := -60.0
const TICK_ID := &"ui_count_tick"
## AUDIO_MANIFEST: relógio alterna as variações 1/2, sem pitch aleatório.
const SEQUENTIAL: Array[StringName] = [&"oil_tick"]
const JINGLE_FADE := 0.3
const DUCK_DB := -4.0
const DUCK_TIME := 2.0

var bank := AudioBank.new()
var _rng := RandomNumberGenerator.new()
var _pool: Array[AudioStreamPlayer] = []
var _pool_ids: Dictionary = {}  # AudioStreamPlayer -> StringName
var _pool_started: Dictionary = {}  # AudioStreamPlayer -> msec de início
var _streams: Dictionary = {}  # caminho -> AudioStream
var _music_players: Array[AudioStreamPlayer] = []
var _music_current: int = 0
var _music_id: StringName = &""
var _music_tweens: Dictionary = {}
## Camadas de ambiente (0 = noite; 1 = extra, ex.: coro das almas no título).
const AMBIENCE_SLOTS := 2
var _ambience_players: Array[AudioStreamPlayer] = []
var _ambience_ids: Array[StringName] = []
var _tick_limiter := RateLimiter.new(20.0)
var _manifest_text: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # som de UI e música continuam com o jogo pausado
	_rng.randomize()
	_ensure_buses()
	rescan()
	for i: int in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.name = "Voice%d" % i
		add_child(p)
		_pool.append(p)
	for i: int in 2:
		var m := AudioStreamPlayer.new()
		m.name = "Music%d" % i
		m.bus = &"Music"
		m.volume_db = SILENT_DB
		add_child(m)
		_music_players.append(m)
	for i: int in AMBIENCE_SLOTS:
		var a := AudioStreamPlayer.new()
		a.name = "Ambience%d" % i
		a.bus = &"Ambience"
		add_child(a)
		_ambience_players.append(a)
		_ambience_ids.append(&"")


## Relê as pastas de áudio e o manifesto (o sound-designer entrega durante o desenvolvimento).
func rescan() -> void:
	_manifest_text = FileAccess.get_file_as_string(MANIFEST_PATH) if FileAccess.file_exists(MANIFEST_PATH) else ""
	bank = AudioBank.new()
	var files := PackedStringArray()
	for dir: String in [SFX_DIR, MUSIC_DIR]:
		_list_recursive(dir, files)
	# The Markdown manifest is not a Godot resource, so it may be absent from exported PCKs.
	# In that case, accept the packaged audio files instead of silently disabling all audio.
	bank.index_paths(files, func(id: String) -> bool: return _manifest_text.is_empty() or _manifest_text.contains(id))


func _list_recursive(dir: String, out: PackedStringArray) -> void:
	if not DirAccess.dir_exists_absolute(dir):
		return
	for f: String in ResourceLoader.list_directory(dir):
		if f.ends_with("/"):
			_list_recursive(dir.path_join(f.trim_suffix("/")), out)
		else:
			out.append(dir.path_join(f))


func has_sound(id: StringName) -> bool:
	return bank.has(id)


# --- Efeitos -----------------------------------------------------------------------

## Toca um efeito. `pitch` é a base (ex.: compra segurada sobe o tom); a variação ±6% vai por cima.
func play(id: StringName, pitch: float = 1.0, variation: float = AudioBank.PITCH_VARIATION, volume_db: float = 0.0) -> void:
	var path: String
	if SEQUENTIAL.has(id):
		path = bank.pick_next(id)
		variation = 0.0
	else:
		path = bank.pick(id, _rng)
	if path.is_empty():
		return
	var stream := _stream(path)
	if stream == null:
		return
	var player := _voice_for(id)
	player.stop()
	player.stream = stream
	player.bus = AudioBank.bus_for(id)
	player.pitch_scale = AudioBank.random_pitch(_rng, pitch, variation)
	player.volume_db = volume_db
	_pool_ids[player] = id
	_pool_started[player] = Time.get_ticks_msec()
	player.play()


## Compatível com as chamadas antigas (GDD §18.3).
func play_sfx(id: StringName, pitch_variation: float = AudioBank.PITCH_VARIATION) -> void:
	play(id, 1.0, pitch_variation)


## Tique do contador, limitado a 20/s (UI/UX §6).
func play_tick() -> void:
	if _tick_limiter.try_fire(Time.get_ticks_msec() / 1000.0):
		play(TICK_ID, 1.0, 0.03)


## Player livre; se o id já tem 6 vozes, reaproveita a mais antiga dele; senão a mais antiga do pool.
func _voice_for(id: StringName) -> AudioStreamPlayer:
	var same: Array[AudioStreamPlayer] = []
	var free: AudioStreamPlayer = null
	var oldest: AudioStreamPlayer = _pool[0]
	for p: AudioStreamPlayer in _pool:
		if not p.playing:
			if free == null:
				free = p
			continue
		if _pool_ids.get(p, &"") == id:
			same.append(p)
		if int(_pool_started.get(p, 0)) < int(_pool_started.get(oldest, 0)) or not oldest.playing:
			oldest = p
	if not AudioBank.voice_available(same.size()):
		var steal := same[0]
		for p: AudioStreamPlayer in same:
			if int(_pool_started.get(p, 0)) < int(_pool_started.get(steal, 0)):
				steal = p
		return steal
	return free if free != null else oldest


func _stream(path: String) -> AudioStream:
	if _streams.has(path):
		return _streams[path] as AudioStream
	var s: AudioStream = null
	if ResourceLoader.exists(path):
		s = load(path) as AudioStream
	_streams[path] = s
	return s


# --- Música e ambiente ----------------------------------------------------------------

## Troca a música com crossfade. Id ausente = a atual some (silêncio).
func play_music(id: StringName, fade: float = CROSSFADE) -> void:
	if id == _music_id and _music_players[_music_current].playing:
		return
	_music_id = id
	var old := _music_players[_music_current]
	_fade(old, SILENT_DB, fade, true)
	var path := bank.pick(id, _rng)
	if path.is_empty():
		return
	var stream := _stream(path)
	if stream == null:
		return
	_set_loop(stream, AudioBank.loops(id))
	_music_current = 1 - _music_current
	var p := _music_players[_music_current]
	p.stream = stream
	p.volume_db = SILENT_DB
	p.play()
	_fade(p, 0.0, fade, false)


## Jingle (ex.: Resumo do Turno): a música atual sai rápido e o jingle toca uma vez no bus Music.
func play_jingle(id: StringName) -> void:
	_music_id = &""
	var was_playing := false
	for p: AudioStreamPlayer in _music_players:
		was_playing = was_playing or p.playing
		_fade(p, SILENT_DB, JINGLE_FADE, true)
	# AUDIO_MANIFEST: fade curto (~0,3 s) da música do turno antes do jingle.
	if was_playing:
		await get_tree().create_timer(JINGLE_FADE, true).timeout
	play(id, 1.0, 0.0)


## Ducking da música (ex.: −4 dB por 2 s durante o stinger de cova).
func duck(db: float = DUCK_DB, time: float = DUCK_TIME) -> void:
	var p := _music_players[_music_current]
	if not p.playing or _music_id == &"":
		return
	_fade(p, db, 0.15, false)
	var t: Tween = _music_tweens[p]
	t.tween_interval(time)
	t.tween_property(p, "volume_db", 0.0, 0.6)


func stop_music(fade: float = CROSSFADE) -> void:
	_music_id = &""
	for p: AudioStreamPlayer in _music_players:
		_fade(p, SILENT_DB, fade, true)


## Ambiente em loop (UI/UX §7.5). Mesmo id continua sem reiniciar. `slot` 1 = camada extra
## por cima da noite (ex.: `amb_souls_choir` na tela-título).
func play_ambience(id: StringName, slot: int = 0, fade: float = CROSSFADE) -> void:
	var player := _ambience_players[clampi(slot, 0, AMBIENCE_SLOTS - 1)]
	var i := _ambience_players.find(player)
	if id == _ambience_ids[i] and player.playing:
		return
	_ambience_ids[i] = id
	var path := bank.pick(id, _rng)
	if path.is_empty():
		player.stop()
		return
	var stream := _stream(path)
	if stream == null:
		return
	_set_loop(stream, true)
	player.stream = stream
	player.volume_db = SILENT_DB
	player.play()
	_fade(player, 0.0, fade, false)


## Para o ambiente de um slot (−1 = todos).
func stop_ambience(slot: int = -1, fade: float = 0.6) -> void:
	for i: int in AMBIENCE_SLOTS:
		if slot == -1 or slot == i:
			_ambience_ids[i] = &""
			_fade(_ambience_players[i], SILENT_DB, fade, true)


func _fade(p: AudioStreamPlayer, to_db: float, time: float, stop_at_end: bool) -> void:
	if _music_tweens.has(p):
		var old: Tween = _music_tweens[p]
		if old != null and old.is_valid():
			old.kill()
	if not p.playing:
		return
	var t := create_tween()
	t.tween_property(p, "volume_db", to_db, time)
	if stop_at_end:
		t.tween_callback(p.stop)
	_music_tweens[p] = t


static func _set_loop(stream: AudioStream, value: bool) -> void:
	if "loop" in stream:
		stream.set("loop", value)


# --- Buses e volumes ------------------------------------------------------------------

func _ensure_buses() -> void:
	for b: StringName in BUSES:
		if AudioServer.get_bus_index(b) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, b)
			AudioServer.set_bus_send(i, &"Master")


## Aplica os volumes salvos (GameSettings.BUS_KEYS) em cada bus.
func apply_settings(settings: Dictionary) -> void:
	for bus: StringName in GameSettings.BUS_KEYS:
		var i := AudioServer.get_bus_index(bus)
		if i == -1:
			continue
		var v := float(settings.get(GameSettings.BUS_KEYS[bus], 1.0))
		AudioServer.set_bus_volume_db(i, GameSettings.linear_to_bus_db(v))
		AudioServer.set_bus_mute(i, v <= 0.001)


## Fecha tudo ao sair (evita playbacks vazando no encerramento).
func _exit_tree() -> void:
	var all: Array[AudioStreamPlayer] = []
	all.append_array(_pool)
	all.append_array(_music_players)
	all.append_array(_ambience_players)
	for p: AudioStreamPlayer in all:
		if p != null:
			p.stop()
			p.stream = null
	_streams.clear()
