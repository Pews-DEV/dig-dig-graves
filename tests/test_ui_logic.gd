extends "res://tests/test_case.gd"
## Testes da lógica pura de UI/áudio (UI/UX §1.6, §6, §7.1, §8): opções, banco de sons,
## limitador de tiques, câmera da Árvore e tempos de animação.


func _initialize() -> void:
	_test_settings()
	_test_audio_bank()
	_test_rate_limiter()
	_test_tree_camera()
	_test_anim_timing()
	_test_tree_layout()
	finish()


func _test_settings() -> void:
	var d := GameSettings.sanitize({})
	check_eq(d.size(), GameSettings.DEFAULTS.size(), "padrões completos")
	var s := GameSettings.sanitize({"vol_music": 3.0, "vol_sfx": -1.0, "reduce_motion": 1, "float_scale": 9, "lixo": 5})
	check_eq(s.vol_music, 1.0, "volume acima de 1 é limitado")
	check_eq(s.vol_sfx, 0.0, "volume negativo vira 0")
	check_eq(s.reduce_motion, true, "bool convertido")
	check_eq(s.float_scale, 2, "escala dos números limitada a 2 (múltiplo inteiro)")
	check(not s.has("lixo"), "chave desconhecida descartada")
	check_eq(GameSettings.linear_to_bus_db(0.0), -80.0, "volume 0 = mudo")
	check(absf(GameSettings.linear_to_bus_db(1.0)) < 0.001, "volume 1 = 0 dB")
	check_eq(GameSettings.motion_factor({"reduce_motion": true}), 0.25, "reduzir movimento = 25% (UI/UX §1.6)")
	check_eq(GameSettings.motion_factor({}), 1.0, "movimento normal = 100%")
	check_eq(GameSettings.BUS_KEYS.size(), 5, "5 canais de volume")


func _test_audio_bank() -> void:
	var b := AudioBank.new()
	var files := PackedStringArray([
		"res://assets/sfx/dig_dirt_2.ogg", "res://assets/sfx/dig_dirt_1.ogg", "res://assets/sfx/dig_dirt_10.ogg",
		"res://assets/music/mus_tree.ogg", "res://assets/sfx/amb_night_1.ogg",
		"res://assets/sfx/dig_dirt_1.ogg.import", "res://assets/sfx/fora_do_manifesto_1.ogg",
	])
	b.index_paths(files, func(id: String) -> bool: return id != "fora_do_manifesto")
	check(b.has(&"dig_dirt"), "variações <id>_<n> agrupadas no id")
	check_eq(b.variants(&"dig_dirt").size(), 3, "3 variações de dig_dirt (.import ignorado)")
	check_eq(b.variants(&"dig_dirt")[2], "res://assets/sfx/dig_dirt_10.ogg", "ordem numérica das variações")
	check(b.has(&"mus_tree"), "arquivo sem número = id inteiro")
	check(b.has(&"amb_night"), "amb_night_1 vira amb_night")
	check(not b.has(&"fora_do_manifesto"), "id fora do manifesto não entra")
	check_eq(b.pick(&"nao_existe", RandomNumberGenerator.new()), "", "id ausente = silêncio")
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var last := ""
	var repeats := 0
	for i: int in 50:
		var p := b.pick(&"dig_dirt", rng)
		if p == last:
			repeats += 1
		last = p
	check_eq(repeats, 0, "sorteio não repete a variação anterior")
	var seq := [b.pick_next(&"dig_dirt"), b.pick_next(&"dig_dirt"), b.pick_next(&"dig_dirt"), b.pick_next(&"dig_dirt")]
	check(seq[0] != seq[1] and seq[0] == seq[3], "pick_next alterna em sequência (oil_tick tic/tac)")
	check_eq(AudioBank.bus_for(&"mus_area1"), &"Music", "música no bus Music")
	check_eq(AudioBank.bus_for(&"stinger_grave"), &"Music", "stinger no bus Music")
	check_eq(AudioBank.bus_for(&"ui_click"), &"UI", "ui_* no bus UI")
	check_eq(AudioBank.bus_for(&"node_buy"), &"UI", "node_* no bus UI (AUDIO_MANIFEST)")
	check_eq(AudioBank.bus_for(&"root_grow"), &"UI", "root_grow no bus UI")
	check_eq(AudioBank.bus_for(&"amb_night"), &"Ambience", "ambiente no bus Ambience")
	check_eq(AudioBank.bus_for(&"dig_rock"), &"SFX", "golpe no bus SFX")
	check(AudioBank.loops(&"mus_tree") and AudioBank.loops(&"amb_night"), "música e ambiente em loop")
	check(not AudioBank.loops(&"jingle_summary"), "jingle não repete")
	check(AudioBank.voice_available(5) and not AudioBank.voice_available(6), "máx. 6 vozes por id (GDD §17)")
	var ok := true
	for i: int in 200:
		var p := AudioBank.random_pitch(rng)
		if p < 0.94 - 0.0001 or p > 1.06 + 0.0001:
			ok = false
	check(ok, "pitch dentro de ±6%")


func _test_rate_limiter() -> void:
	var r := RateLimiter.new(20.0)
	var fired := 0
	for i: int in 100:  # 1 s em passos de 10 ms
		if r.try_fire(i * 0.01):
			fired += 1
	check_eq(fired, 20, "tique limitado a 20/s (UI/UX §6)")
	check(r.try_fire(5.0), "volta a tocar depois de uma pausa")


func _test_tree_camera() -> void:
	var cam := TreeCamera.new(Vector2(640, 360), Rect2(0, 0, 640, 720))
	check_eq(cam.max_pos(), Vector2(0, 360), "limite inferior = altura do mundo − vista")
	cam.drag(Vector2(0, 100))
	check_eq(cam.pos, Vector2.ZERO, "arrastar para baixo no topo não passa do limite")
	cam.drag(Vector2(0, -100))
	check_eq(cam.pos, Vector2(0, 100), "arrastar para cima desce a câmera")
	cam.release(Vector2(0, -400))
	var before := cam.pos.y
	cam.step(0.1)
	check(cam.pos.y > before, "inércia continua o movimento depois de soltar")
	for i: int in 200:
		cam.step(0.016)
	check(cam.vel == Vector2.ZERO, "inércia para sozinha")
	check(cam.pos.y <= 360.0, "inércia respeita o limite")
	cam.pos = Vector2.ZERO
	cam.release(Vector2(0, -100000))
	for i: int in 30:
		cam.step(0.016)
	check_eq(cam.pos.y, 360.0, "inércia forte para no limite")
	cam.pos = Vector2.ZERO
	var target := cam.focus_for(Vector2(320, 500), Rect2(24, 44, 592, 200))
	check_eq(target.y, 256.0, "focus_for move o mínimo para o ponto entrar na faixa segura")
	check_eq(cam.focus_for(Vector2(320, 100), Rect2(24, 44, 592, 200)).y, 0.0, "ponto já visível não move")
	cam.scroll_to(Vector2(0, 9999))
	check_eq(cam.target.y, 360.0, "alvo da rolagem é limitado")
	for i: int in 300:
		cam.step(0.016)
	check_eq(cam.pos.y, 360.0, "rolagem suave chega ao alvo")
	check(not cam.has_target, "rolagem termina")


func _test_anim_timing() -> void:
	var frames: Array[float] = [0.4, 0.15, 0.25]
	check_eq(TreeArt.frame_at(0.0, frames), 0, "frame_at início")
	check_eq(TreeArt.frame_at(0.45, frames), 1, "frame_at meio")
	check_eq(TreeArt.frame_at(0.8 + 0.1, frames), 0, "frame_at em loop")
	var seq: Array[int] = []
	for i: int in 6:
		seq.append(TreeArt.pingpong(i * 0.4 + 0.01, 3, 0.4))
	check_eq(seq, [0, 1, 2, 1, 0, 1], "copa em ping-pong (MANIFEST tree_canopy)")


## Layout da árvore (.tres): nós de 32 px não se sobrepõem e ficam dentro do mundo 640×720.
func _test_tree_layout() -> void:
	var defs := SkillTreeModel.load_definitions("res://data/skill_nodes/")
	var ok := true
	var inside := true
	for i: int in defs.size():
		var a := defs[i].tree_position
		if a.x < 20 or a.x > 620 or a.y < TreeArt.GRASS_Y + 40 or a.y > 700:
			inside = false
		for j: int in range(i + 1, defs.size()):
			var b := defs[j].tree_position
			# 32 px de medalhão + custo embaixo: pelo menos 44 px entre centros.
			if a.distance_to(b) < 44.0:
				ok = false
				print("  perto demais: %s %s" % [defs[i].id, defs[j].id])
	check(ok, "medalhões de 32 px sem sobreposição")
	check(inside, "nós dentro do mundo, abaixo da grama")
