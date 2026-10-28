extends Node
## Arte e estado do Pisão e da barra do chefe (DA §11.2, UI/UX §13.1–13.2).

var _failures: Array[String] = []


func _ready() -> void:
	var hud := Hud.new()
	add_child(hud)
	await get_tree().process_frame
	var stats := Stats.snapshot()
	stats[StatSheet.STOMP_ENABLED] = 1.0
	var state := RunState.new(Game.area, Game.tool, Game.balance, stats, 831)
	hud.show_stomp(state)
	_check(hud._stomp_button != null, "habilidade disponível cria botão do Pisão")
	_check(hud._stomp_button.texture_normal != null, "plaqueta usa o frame Aseprite")
	_check(hud._stomp_icon.texture is AtlasTexture, "ícone do Pisão vem do atlas Aseprite")
	_check(hud._stomp_pips.size() == 4, "recarga mostra quatro pips")
	_check(hud._stomp_icon.texture.region.position.x == 0.0, "Pisão pronto usa o ícone claro")

	state.stomp_cooldown_left = 2.0
	hud.refresh(state)
	_check(hud._stomp_button.disabled, "Pisão fica desabilitado durante a recarga")
	_check(hud._stomp_icon.texture.region.position.x == 20.0, "recarga usa o ícone apagado")
	_check(hud._stomp_pips[0].texture.region.position.x == 4.0, "pips acompanham a recarga")

	hud.show_boss(100.0, 200.0)
	_check(hud._boss_bar.frame_texture_path.ends_with("barra_chefe.png"), "chefe usa moldura própria")
	_check(hud._boss_bar.fill_texture_path.is_empty(), "vida do chefe usa preenchimento de Perigo")
	var fx_texture := AssetManifest.texture_by_id("fx_stomp")
	_check(fx_texture != null, "anel do Pisão está integrado no manifesto")
	var effect := StompFx.new()
	effect.setup(fx_texture, Vector2(64, 32))
	add_child(effect)
	var effect_ref: WeakRef = weakref(effect)
	_check(is_equal_approx(effect.scale.x, 64.0 / 24.0), "anel se adapta à largura da área atingida")
	await get_tree().create_timer(0.1).timeout
	var current_effect: StompFx = effect_ref.get_ref() as StompFx
	_check(current_effect != null and current_effect.texture.region.position.x >= 24.0, "anel anima pelos quadros do sprite Aseprite")
	await get_tree().create_timer(0.3).timeout
	_check(effect_ref.get_ref() == null, "anel termina sem ficar preso na tela")
	_finish()


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS ", label)
	else:
		_failures.append(label)


func _finish() -> void:
	for failure: String in _failures:
		printerr("FAIL ", failure)
	if _failures.is_empty():
		print("PASS HUD de Pisão e chefe com assets Aseprite")
	get_tree().quit(1 if not _failures.is_empty() else 0)
