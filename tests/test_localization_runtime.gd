extends Node

const EXPECTED: Dictionary = {
	"pt_BR": "Agora",
	"en": "Now",
	"fr": "Maintenant",
	"it": "Ora",
	"de": "Jetzt",
	"es_ES": "Ahora",
	"ja": "今",
	"ko": "지금",
	"ru": "Сейчас",
	"zh_CN": "现在",
}

const HUB_KEYS: Array[String] = [
	"PÁTIO DO BOM DESCANSO",
	"Raízes",
	"Talentos",
	"Próxima Noite",
	"Paróquia · Cavar",
	"Loja",
	"Fazenda",
	"Capítulo 2",
	"Em breve",
	"Enfrentar o Caixão Fujão",
	"Foto oval",
	"Cova normal",
	"Cruz de pedra",
	"+1 Alma × estágio",
	"Lápide com musgo",
	"Caixão 1,5× mais duro · Ossos ×2",
	"FIM DO CAPÍTULO 1",
	"O Cemitério da Paróquia",
	"Noites cavadas",
	"Covas abertas",
	"Nós comprados",
	"Tentativas no chefe",
	"Capítulo 2 · Campo dos Indigentes · Em breve",
	"Continuar cavando",
	"Créditos",
]


func _ready() -> void:
	for locale: String in EXPECTED:
		TranslationServer.set_locale(locale)
		var actual := TranslationServer.translate("Agora")
		assert(actual == EXPECTED[locale], "%s: expected %s, got %s" % [locale, EXPECTED[locale], actual])
		for key: String in HUB_KEYS:
			var translated := TranslationServer.translate(key)
			assert(not translated.is_empty(), "%s: missing translation for %s" % [locale, key])
	var options := OptionsMenu.new()
	add_child(options)
	await get_tree().process_frame
	assert(options._locale_btn.get_item_count() == 10, "language selector should expose ten locales")
	options._on_locale_selected(1)
	assert(Game.settings.locale == "en" and TranslationServer.get_locale() == "en", "selecting English should update the game locale")
	var hud := Hud.new()
	add_child(hud)
	await get_tree().process_frame
	hud.update_grave_tooltip({"type": RunState.GRAVE_TYPE_MOSS}, Vector2(638, 358))
	assert(hud._grave_tooltip.visible, "hovering a grave should show its type tooltip")
	assert(hud._grave_tooltip_title.text == "Mossy gravestone", "grave tooltip title should use the selected locale: %s / %s" % [TranslationServer.get_locale(), hud._grave_tooltip_title.text])
	assert(hud._grave_tooltip_effect.text == "Coffin 1.5× tougher · Bones ×2", "grave tooltip effect should use the selected locale: %s" % hud._grave_tooltip_effect.text)
	assert(hud._grave_tooltip.position.x >= 0 and hud._grave_tooltip.position.y >= 0, "grave tooltip should clamp to the viewport")
	hud.update_grave_tooltip({}, Vector2.ZERO)
	assert(not hud._grave_tooltip.visible, "leaving a grave should hide its tooltip")
	TranslationServer.set_locale("pt_BR")
	Game.set_setting("locale", "pt_BR")
	print("PASS translations loaded for all 10 locales")
	get_tree().quit(0)
