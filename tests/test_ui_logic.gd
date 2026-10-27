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
	# Tela-título (AUDIO_MANIFEST): logo_* em SFX, ui_wisp_slide/ui_bury em UI, coro em Ambience.
	check_eq(AudioBank.bus_for(&"mus_title"), &"Music", "mus_title no bus Music")
	check_eq(AudioBank.bus_for(&"logo_land"), &"SFX", "logo_land no bus SFX")
	check_eq(AudioBank.bus_for(&"logo_thunk"), &"SFX", "logo_thunk no bus SFX")
	check_eq(AudioBank.bus_for(&"logo_drip"), &"SFX", "logo_drip no bus SFX")
	check_eq(AudioBank.bus_for(&"ui_wisp_slide"), &"UI", "ui_wisp_slide no bus UI")
	check_eq(AudioBank.bus_for(&"ui_bury"), &"UI", "ui_bury no bus UI")
	check_eq(AudioBank.bus_for(&"amb_souls_choir"), &"Ambience", "amb_souls_choir no bus Ambience")
	check(AudioBank.loops(&"mus_title") and AudioBank.loops(&"amb_souls_choir"), "tema do título e coro em loop")
	check(not AudioBank.loops(&"logo_thunk"), "logo_thunk não repete")
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


## Layout da árvore (.tres + TreeLayout): grade regular, caixas (medalhão + "!" + pips + custo)
## sem sobreposição, raízes que não atravessam custo nem nó, nada escondido atrás do painel/HUD.
func _test_tree_layout() -> void:
	var defs := SkillTreeModel.load_definitions("res://data/skill_nodes/")
	var by_id: Dictionary = {}
	for d: SkillNodeData in defs:
		by_id[d.id] = d
	check(by_id.has(&"N00"), "N00 existe")
	var n00: Vector2 = (by_id[&"N00"] as SkillNodeData).tree_position
	var on_grid := true
	var inside := true
	for d: SkillNodeData in defs:
		var p := d.tree_position
		var col := (p.x - 320.0) / TreeLayout.COLUMN
		var row := (p.y - n00.y) / TreeLayout.ROW
		if not is_equal_approx(col, roundf(col)) or not is_equal_approx(row, roundf(row)):
			on_grid = false
			print("  fora da grade: %s %s" % [d.id, p])
		var r := TreeLayout.node_rect(p)
		if r.position.x < TreeLayout.SIDE_MARGIN or r.end.x > TreeArt.WORLD.x - TreeLayout.SIDE_MARGIN or r.position.y < TreeArt.GRASS_Y + 8 or r.end.y > TreeArt.WORLD.y:
			inside = false
			print("  cortado pela borda do mundo: %s" % d.id)
	check(on_grid, "nós na grade (colunas 320 ± 88k, linhas de 64 px a partir do N00)")
	check(inside, "caixas dos nós dentro do mundo, abaixo da grama")
	# Caixas (medalhão 32 + "!" + pips + custo de até 56 px) não se tocam (2 px de folga).
	var apart := true
	for i: int in defs.size():
		for j: int in range(i + 1, defs.size()):
			var a := TreeLayout.node_rect(defs[i].tree_position).grow(1.0)
			var b := TreeLayout.node_rect(defs[j].tree_position).grow(1.0)
			if a.intersects(b):
				apart = false
				print("  perto demais: %s %s" % [defs[i].id, defs[j].id])
	check(apart, "medalhões, pips e custos sem sobreposição entre nós")
	check(TreeLayout.node_rect(Vector2.ZERO).size.y < TreeLayout.ROW, "uma linha da grade comporta a caixa do nó")
	check(TreeLayout.LABEL_MAX_W < TreeLayout.COLUMN, "uma coluna comporta o custo mais largo")
	# Raízes: do pai até o filho sem passar pelo custo do pai/filho nem pela caixa de outro nó.
	var clean := true
	for d: SkillNodeData in defs:
		for child: StringName in d.children:
			if not by_id.has(child):
				continue
			var to: Vector2 = (by_id[child] as SkillNodeData).tree_position
			for decor: float in [TreeLayout.decor_bottom(true, true), TreeLayout.decor_bottom(true, false), TreeLayout.decor_bottom(false, false)]:
				var from := TreeLayout.root_start(d.tree_position, to, decor)
				var pts: Array = TreeLayout.root_path(from, to)[0]
				for q: Vector2i in pts:
					var pt := Vector2(q)
					var bad := ""
					var own := TreeLayout.label_rect(d.tree_position)
					own.size.y = decor - TreeLayout.PIPS_TOP  # só o que esse estado desenha embaixo
					if own.size.y > 0.0 and own.has_point(pt):
						bad = "custo do pai"
					elif TreeLayout.label_rect(to).has_point(pt):
						bad = "custo do filho"
					else:
						for o: SkillNodeData in defs:
							if o.id != d.id and o.id != child and TreeLayout.node_rect(o.tree_position).has_point(pt):
								bad = "nó " + String(o.id)
					if not bad.is_empty():
						clean = false
						print("  raiz %s>%s passa por %s em %s" % [d.id, child, bad, pt])
						break
	check(clean, "raízes não atravessam custos, pips nem outros nós")
	# Filho logo abaixo: a raiz sai por baixo do custo; na diagonal, pela lateral do medalhão.
	var below := TreeLayout.root_start(Vector2(100, 100), Vector2(100, 164), TreeLayout.decor_bottom(true, true))
	check(below.y > 100 + TreeLayout.decor_bottom(true, true), "raiz vertical sai abaixo do custo")
	var side := TreeLayout.root_start(Vector2(100, 100), Vector2(12, 164), TreeLayout.decor_bottom(true, true))
	check(side.x < 100 - TreeLayout.HALF + 2 and side.y < 100 + TreeLayout.PIPS_TOP, "raiz diagonal sai pela lateral do medalhão")
	# Câmera: nenhum nó fora de alcance e o enquadramento inicial mostra N00 + 2 linhas inteiras.
	var cam := TreeCamera.new(Vector2(640, 360), Rect2(Vector2.ZERO, TreeArt.WORLD))
	var safe := TreeLayout.safe_rect(TreeLayout.PANEL_Y)
	var reachable := true
	var start_y := cam.clamp_pos(Vector2(0, TreeLayout.start_camera_y(n00.y))).y
	var start_ok := true
	for d: SkillNodeData in defs:
		var p := d.tree_position
		if p.y - cam.max_pos().y > safe.end.y or p.x < safe.position.x or p.x > safe.end.x:
			reachable = false
			print("  inalcançável acima do painel: %s" % d.id)
		var depth := roundi((p.y - n00.y) / TreeLayout.ROW)
		if depth <= 2:
			var r := TreeLayout.node_rect(p)
			if r.end.y - start_y > TreeLayout.PANEL_Y or r.position.y - start_y < TreeLayout.TOP_HUD_BOTTOM:
				start_ok = false
				print("  escondido no enquadramento inicial: %s" % d.id)
	check(reachable, "todo nó pode ser rolado para cima do painel de descrição")
	check(start_ok, "enquadramento inicial: N00 e as 2 primeiras linhas inteiras entre o HUD e o painel")
	check(safe.position.y + TreeLayout.BADGE_TOP - 1.0 >= TreeLayout.TOP_HUD_BOTTOM, "faixa segura: o \"!\" não entra embaixo das plaquetas")
	check(safe.end.y + TreeLayout.decor_bottom(true, true) <= TreeLayout.PANEL_Y, "faixa segura: o custo não entra embaixo do painel")
	# Distribuição: a árvore fica centrada no tronco (x = 320).
	var min_x := INF
	var max_x := -INF
	for d: SkillNodeData in defs:
		min_x = minf(min_x, d.tree_position.x)
		max_x = maxf(max_x, d.tree_position.x)
	check(absf((min_x + max_x) * 0.5 - 320.0) <= TreeLayout.COLUMN * 0.5, "ramos distribuídos dos dois lados do tronco")
