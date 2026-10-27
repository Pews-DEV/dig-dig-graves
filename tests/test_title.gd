extends "res://tests/test_case.gd"
## Testes da tela-título (UI/UX §9): regras do menu, confirmação, tempos da abertura, layout
## do contrato §9.6, leitura do manifesto/JSON do Aseprite com fallback, créditos e "Enterrar".
## Uso: godot --headless --path . -s res://tests/test_title.gd

const TEST_SAVE := "user://test_title_save.json"


func _initialize() -> void:
	_test_menu_model()
	_test_confirm()
	_test_timeline()
	_test_layout()
	_test_manifest_lookup()
	_test_aseprite_sheet()
	_test_placeholders()
	_test_credits()
	_test_bury()
	_test_audio_contract()
	finish()


func _test_menu_model() -> void:
	var with_save := TitleMenuModel.entries(true)
	var without := TitleMenuModel.entries(false)
	check(_same(with_save, [&"continue", &"new_game", &"options", &"credits", &"quit"]), "ordem com save: Continuar, Novo Jogo, Opções, Créditos, Sair")
	check(_same(without, [&"new_game", &"options", &"credits", &"quit"]), "sem save não existe Continuar")
	check_eq(TitleMenuModel.initial_focus(true), TitleMenuModel.CONTINUE, "com save, Continuar começa em foco")
	check_eq(TitleMenuModel.initial_focus(false), TitleMenuModel.NEW_GAME, "sem save, Novo Jogo começa em foco")
	check(without.has(TitleMenuModel.initial_focus(false)) and with_save.has(TitleMenuModel.initial_focus(true)), "o foco inicial é sempre um botão existente")
	check_eq(TitleMenuModel.label(&"new_game"), "Novo Jogo", "rótulo de Novo Jogo")
	check_eq(TitleMenuModel.destination(TitleMenuModel.CONTINUE), TitleMenuModel.DEST_TREE, "Continuar leva à Árvore")
	check_eq(TitleMenuModel.destination(TitleMenuModel.NEW_GAME), TitleMenuModel.DEST_RUN, "Novo Jogo leva ao 1º turno")
	check(TitleMenuModel.needs_confirm(TitleMenuModel.NEW_GAME, true), "Novo Jogo com save pede confirmação")
	check(not TitleMenuModel.needs_confirm(TitleMenuModel.NEW_GAME, false), "Novo Jogo sem save começa direto")
	check(not TitleMenuModel.needs_confirm(TitleMenuModel.CONTINUE, true), "Continuar não pede confirmação")
	check_eq(TitleMenuModel.description(TitleMenuModel.CONTINUE, true, 7, 1234.0), "Noite 7 · 1.234", "descrição de Continuar com os dados do save")
	check(TitleMenuModel.shows_copper(TitleMenuModel.CONTINUE) and not TitleMenuModel.shows_copper(TitleMenuModel.QUIT), "só Continuar leva o ícone de Cobre")
	for id: StringName in TitleMenuModel.ORDER:
		check(not TitleMenuModel.description(id, true, 1, 0.0).is_empty(), "descrição de %s" % id)
	check_eq(TitleMenuModel.step(0, -1, 5), 4, "foco dá a volta para cima")
	check_eq(TitleMenuModel.step(4, 1, 5), 0, "foco dá a volta para baixo")


func _test_confirm() -> void:
	check_eq(TitleMenuModel.CONFIRM_FOCUS, TitleMenuModel.BACK, "confirmação começa em Voltar")
	check(_same(TitleMenuModel.CONFIRM_ORDER, [&"bury", &"back"]), "botões Enterrar e Voltar")
	check_eq(TitleMenuModel.CONFIRM_TEXT, "Enterrar o progresso atual?", "texto da lápide")
	check_eq(TitleMenuModel.CONFIRM_LABELS[TitleMenuModel.BURY], "Enterrar", "rótulo Enterrar")


func _test_timeline() -> void:
	check_eq(TitleTimeline.FADE, 0.6, "fade do preto em 0,6 s")
	check_eq(TitleTimeline.DESCENT, 2.0, "descida de 2,0 s")
	check_eq(TitleTimeline.fade_alpha(0.0), 1.0, "começa no preto")
	check_eq(TitleTimeline.fade_alpha(0.6), 0.0, "fade termina em 0,6 s")
	check_eq(TitleTimeline.layer_offset(0.0, 1.0), 240.0, "primeiro plano começa 240 px abaixo")
	check_eq(TitleTimeline.layer_offset(0.0, 0.25), 60.0, "céu começa 60 px abaixo (fator 0,25)")
	check_eq(TitleTimeline.layer_offset(TitleTimeline.descent_start() + TitleTimeline.DESCENT, 1.0), 0.0, "descida termina no enquadramento final")
	var mid := TitleTimeline.descent_start() + TitleTimeline.DESCENT * 0.5
	check_eq(TitleTimeline.layer_offset(mid, 1.0), 120.0, "ease-in-out: metade do caminho na metade do tempo")
	check(TitleTimeline.ease_in_out(0.1) < 0.1 and TitleTimeline.ease_in_out(0.9) > 0.9, "ease-in-out acelera e freia")
	var monotonic := true
	for i: int in 100:
		if TitleTimeline.ease_in_out(i / 100.0) > TitleTimeline.ease_in_out((i + 1) / 100.0):
			monotonic = false
	check(monotonic, "descida nunca volta")
	check_eq(TitleTimeline.letters_start(), 2.6, "letras começam depois da descida")
	check(is_equal_approx(TitleTimeline.letter_start(1) - TitleTimeline.letter_start(0), 0.04), "40 ms entre letras")
	check(TitleTimeline.shovel_start() >= TitleTimeline.letter_land(11), "a pá cai depois da última letra pousar")
	var gap := TitleTimeline.thunk_time() - TitleTimeline.letter_land(11)
	check(gap >= 0.059 and gap <= 0.101, "tunc 60–100 ms depois da última letra (AUDIO_MANIFEST) (%.2f s)" % gap)
	check(TitleTimeline.button_start(0) > TitleTimeline.thunk_time(), "botões entram depois do tunc")
	check(is_equal_approx(TitleTimeline.button_start(3) - TitleTimeline.button_start(2), 0.06), "botões escalonados em 60 ms")
	check(TitleTimeline.total(5) > TitleTimeline.button_start(4), "abertura termina depois do último botão")
	check(TitleTimeline.total(5) < 5.0, "abertura curta (< 5 s)")
	check_eq(TitleTimeline.fall_remaining(0.0, 0.0, 0.2), 1.0, "letra começa no alto")
	check_eq(TitleTimeline.fall_remaining(0.2, 0.0, 0.2), 0.0, "letra pousa no fim da queda")


func _test_layout() -> void:
	var l := load("res://data/title/title_layout.tres") as TitleLayoutData
	check(l != null, "title_layout.tres carrega")
	if l == null:
		l = TitleLayoutData.new()
	check_eq(l.camera_drop, 240.0, "câmera começa 240 px acima")
	check_eq([l.factor_sky, l.factor_village, l.factor_wall, l.factor_fg], [0.25, 0.5, 0.8, 1.0], "fatores de parallax do §9.6")
	check_eq(l.letter_positions.size(), 12, "posição final das 12 letras")
	var logo_ok := true
	for i: int in 12:
		var r := Rect2(l.letter_pos(i), Vector2(36, 46))
		if r.position.x < 200 or r.end.x > 440 or r.position.y < 0 or r.end.y > 114:
			logo_ok = false
	check(logo_ok, "letras no terço superior, ~1/3 da largura")
	check_eq(l.menu_button_pos(0), Vector2(372, 168), "1º botão em (372, 168)")
	check_eq(l.menu_button_pos(4).y - l.menu_button_pos(3).y, 28.0, "passo de 28 px entre botões")
	check_eq(l.menu_width, 104, "botões com 104 px")
	var col := Rect2(l.menu_origin, Vector2(l.menu_width, l.menu_step * 5))
	check(not col.intersects(Rect2(l.coveiro_seat - Vector2(16, 31), Vector2(32, 32))), "menu não cobre o Coveiro")
	var logo_hit := false
	for i: int in 12:
		if col.intersects(Rect2(l.letter_pos(i), Vector2(36, 46))):
			logo_hit = true
	check(not logo_hit, "menu não cobre o logo")
	var path := l.soul_path
	check(path.size() >= 2, "trilha das almas")
	var end := path[path.size() - 1]
	check(end.x >= l.gate_span.x and end.x <= l.gate_span.y, "as almas somem no vão do portão")
	check_eq(l.shovel_final(Vector2(30, 26)), Vector2(375, 4), "pá do logo: canto em (375, 4) (pivô (9, 24) em (384, 28))")
	check_eq(l.drip_list().size(), 11, "11 pontas de gota")
	check_eq(l.coveiro_seat + l.shovel_offset, Vector2(84, 303), "pá cravada em (84, 303)")
	check_eq(l.coveiro_seat + l.lantern_offset, Vector2(108, 303), "lanterna em (108, 303)")
	check_eq(l.coveiro_seat + l.halo_offset, Vector2(108, 298), "halo em (108, 298)")
	check_eq(TitleLayoutData.layer_top(-1, 200), 160.0, "camada sem y fixo: base na base da tela")
	check_eq(TitleLayoutData.layer_top(140, 220), 140.0, "camada com y do manifesto")
	var defaults := TitleLayoutData.new()
	defaults.letter_positions = []
	check_eq(defaults.default_letter_positions().size(), 12, "posições calculadas das letras placeholder")


func _test_manifest_lookup() -> void:
	var sample := "| id | arquivo | x |\n|---|---|---|\n| foo | `assets/a/foo.png` (8×8) + `foo.json` | 1 |\n| foo_bar | `assets/a/foo_bar.png` | 2 |\n"
	check_eq(AssetManifest.path_in(sample, "foo"), "res://assets/a/foo.png", "caminho pelo id na 1ª coluna")
	check_eq(AssetManifest.path_in(sample, "foo_bar"), "res://assets/a/foo_bar.png", "id parecido não confunde")
	check_eq(AssetManifest.path_in(sample, "nao_existe"), "", "id ausente = vazio (placeholder)")
	check_eq(AssetManifest.path_for(TitleArt.SKY), "res://assets/sprites/bg/title/title_sky.png", "title_sky registrado no manifesto")
	check_eq(AssetManifest.path_for(TitleArt.COVEIRO), "res://assets/sprites/chars/title/coveiro_title.png", "coveiro_title registrado no manifesto")
	check(TitleArt.texture("id_que_nao_existe") == null, "asset ausente = null (quem desenha usa placeholder)")
	check(TitleArt.sheet("id_que_nao_existe") == null, "folha ausente = null")


func _test_aseprite_sheet() -> void:
	check(AsepriteSheet.from_json_text("lixo") == null, "JSON inválido = null")
	check(AsepriteSheet.from_json_text("{\"frames\": []}") == null, "sem frames = null")
	var path := "res://assets/sprites/chars/title/coveiro_title.json"
	check(FileAccess.file_exists(path), "coveiro_title.json existe")
	var s := AsepriteSheet.from_json_text(FileAccess.get_file_as_string(path))
	check(s != null, "lê o JSON do Coveiro")
	if s == null:
		return
	check_eq(s.frames.size(), 25, "25 frames")
	check_eq(s.frame_size(), Vector2(32, 32), "frame 32×32")
	for t: StringName in [&"idle", &"scratch", &"yawn", &"stand"]:
		check(s.has_tag(t), "tag %s" % t)
	check_eq(s.tag_range(&"stand"), Vector2i(20, 24), "stand = 20–24")
	check_eq(s.frame_at(&"stand", 99.0, false), 24, "stand segura o último frame")
	check_eq(s.frame_at(&"idle", s.tag_duration(&"idle") + 0.01, true), 0, "idle em loop")
	check(is_equal_approx(s.tag_duration(&"idle"), 1.002), "idle dura ~1 s (6 × 167 ms)")
	check_eq(s.frame_at(&"stand", 0.167 + 0.083 + 0.083 + 0.01, false) - 20, 3, "3º frame do stand (pá e lanterna somem)")
	var hash_fmt := "{\"frames\": {\"a\": {\"frame\": {\"x\": 0, \"y\": 0, \"w\": 4, \"h\": 4}, \"duration\": 100}}, \"meta\": {}}"
	var h := AsepriteSheet.from_json_text(hash_fmt)
	check(h != null and h.frames.size() == 1, "formato Hash também é lido")


func _test_placeholders() -> void:
	var img := TitleArt.letter_image("G", 5, 6)
	check_eq(Vector2i(img.get_width(), img.get_height()), TitleLayoutData.letter_size(6), "letra placeholder no tamanho previsto")
	var used := 0
	for y: int in img.get_height():
		for x: int in img.get_width():
			if img.get_pixel(x, y).a > 0.0:
				used += 1
				if Palette.index_of(img.get_pixel(x, y)) == 0:
					used = -100000
	check(used > 0, "letra placeholder desenhada só com cores da paleta")
	var sky := TitleArt.sky_image(Vector2(96, 64), 28)
	check_eq(Vector2i(sky.get_width(), sky.get_height()), Vector2i(640, 600), "céu placeholder 640×600")
	check_eq(Palette.index_of(sky.get_pixel(96, 304)), Palette.STONE_LIGHT, "lua no centro (96, 64) do enquadramento final")
	var full := TitleArt.fade_texture(16).get_image()
	var empty := TitleArt.fade_texture(0).get_image()
	var half := TitleArt.fade_texture(8).get_image()
	check_eq(_opaque(full), 16, "fade cheio = preto em todos os px")
	check_eq(_opaque(empty), 0, "fade 0 = transparente")
	check_eq(_opaque(half), 8, "fade 50% = metade dos px (Bayer)")
	check(TitleArt.stone_style() != null, "painel de pedra (arte ou placeholder)")
	check(TitleArt.danger_style(&"normal") != null and TitleArt.danger_style(&"hover") != null, "botão de perigo nos estados")
	check_eq(Palette.index_of(TitleArt.danger_image(&"normal").get_pixel(5, 5)), Palette.DANGER_DARK, "botão de perigo placeholder em 31")
	check(TitleArt.shovel_texture() != null, "pá do logo (arte ou placeholder)")


## Mesmos elementos na mesma ordem (Array tipado × literal).
func _same(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for i: int in a.size():
		if a[i] != b[i]:
			return false
	return true


func _opaque(img: Image) -> int:
	var n := 0
	for y: int in img.get_height():
		for x: int in img.get_width():
			if img.get_pixel(x, y).a > 0.0:
				n += 1
	return n


func _test_credits() -> void:
	var md := "# Créditos — X\n\n## Fontes\n- **m5x7** por [Daniel Linssen](https://managore.itch.io)\n\n| Item | Origem |\n|---|---|\n| Sons | Síntese |\n"
	var lines := CreditsText.markdown_to_lines(md)
	var texts: Array[String] = []
	for l: Dictionary in lines:
		texts.append(String(l.text))
	check(texts.has("Fontes"), "título vira linha de título")
	check(texts.has("m5x7 por Daniel Linssen"), "negrito e link removidos")
	check(texts.has("Sons · Síntese"), "linha de tabela unida por ·")
	check(not texts.has("Item · Origem"), "cabeçalho da tabela não aparece")
	var all := CreditsText.load_lines()
	var joined := ""
	for l: Dictionary in all:
		joined += String(l.text) + "\n"
	check(joined.contains("Daniel Linssen"), "créditos citam Daniel Linssen (m5x7/m6x11)")
	check(joined.contains("Ferramentas"), "créditos listam as ferramentas")
	check(joined.contains("Áudio"), "créditos incluem o AUDIO_CREDITS.md")
	check(all[0].kind == CreditsText.TITLE and all[all.size() - 1].kind != CreditsText.GAP, "abre com título e não termina em lacuna")


func _test_bury() -> void:
	SaveIO.write(TEST_SAVE, {"progress": {"turns_played": 3}})
	check(FileAccess.file_exists(TEST_SAVE), "save de teste escrito")
	check(SaveIO.bury(TEST_SAVE), "enterrar retorna ok")
	check(not FileAccess.file_exists(TEST_SAVE), "save some depois de enterrar")
	var buried := SaveIO.buried_path(TEST_SAVE)
	check_eq(buried, "user://test_title_save_buried.json", "cópia enterrada ao lado")
	check_eq(int((SaveIO.read(buried).get("progress", {}) as Dictionary).get("turns_played", 0)), 3, "cópia enterrada guarda o progresso")
	check(SaveIO.bury(TEST_SAVE), "enterrar sem save não falha")
	SaveIO.delete(buried)


func _test_audio_contract() -> void:
	var manifest := FileAccess.get_file_as_string("res://assets/AUDIO_MANIFEST.md")
	for id: String in ["mus_title", "logo_land", "logo_thunk", "logo_drip", "amb_souls_choir", "ui_wisp_slide", "ui_bury"]:
		check(manifest.contains(id), "%s no AUDIO_MANIFEST" % id)
	check(FileAccess.file_exists("res://assets/music/mus_title.ogg"), "mus_title.ogg entregue")
	check(FileAccess.file_exists("res://assets/sfx/logo_land_1.ogg"), "logo_land_1.ogg entregue")
	var b := AudioBank.new()
	b.index_paths(PackedStringArray(["res://assets/sfx/logo_land_1.ogg", "res://assets/sfx/logo_land_2.ogg", "res://assets/sfx/amb_souls_choir_1.ogg"]))
	check_eq(b.variants(&"logo_land").size(), 2, "variações de logo_land agrupadas")
	check(b.has(&"amb_souls_choir"), "amb_souls_choir_1 vira amb_souls_choir")
