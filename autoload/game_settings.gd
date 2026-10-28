class_name GameSettings
extends RefCounted
## Opções do jogador (GDD §16, UI/UX §1.6): valores padrão, limites e saneamento do save.
## Puro e testável; o dicionário vivo fica em Game.settings.

const BUS_KEYS: Dictionary = {
	&"Master": "vol_master",
	&"Music": "vol_music",
	&"SFX": "vol_sfx",
	&"UI": "vol_ui",
	&"Ambience": "vol_ambience",
}

const LOCALES: Array[Dictionary] = [
	{"code": "pt_BR", "label": "Português (Brasil)"},
	{"code": "en", "label": "English"},
	{"code": "fr", "label": "Français"},
	{"code": "it", "label": "Italiano"},
	{"code": "de", "label": "Deutsch"},
	{"code": "es_ES", "label": "Español (España)"},
	{"code": "ja", "label": "日本語"},
	{"code": "ko", "label": "한국어"},
	{"code": "ru", "label": "Русский"},
	{"code": "zh_CN", "label": "简体中文"},
]

const DEFAULTS: Dictionary = {
	"vol_master": 0.8,
	"vol_music": 0.7,
	"vol_sfx": 0.8,
	"vol_ui": 0.7,
	"vol_ambience": 0.6,
	"shake_intensity": 1.0,
	"reduce_flashes": false,
	"reduce_motion": false,
	"auto_stomp": false,
	"locale": "pt_BR",
	## 1 = tamanho nativo da m6x11; 2 = dobro (múltiplo inteiro, UI/UX §2).
	"float_scale": 1,
}

## UI/UX §1.6: "reduzir movimento" corta escalas, tremores e partículas ambientes para 25%.
const REDUCED_MOTION := 0.25


## Cópia dos padrões com os valores salvos por cima, cada um no tipo e faixa certos.
static func sanitize(saved: Dictionary) -> Dictionary:
	var out: Dictionary = DEFAULTS.duplicate()
	for key: String in DEFAULTS:
		if not saved.has(key):
			continue
		var v: Variant = saved[key]
		match typeof(DEFAULTS[key]):
			TYPE_BOOL:
				out[key] = bool(v)
			TYPE_INT:
				out[key] = clampi(int(v), 1, 2)
			TYPE_FLOAT:
				out[key] = clampf(float(v), 0.0, 1.0)
			TYPE_STRING:
				var candidate := str(v)
				for locale: Dictionary in LOCALES:
					if candidate == str(locale.code):
						out[key] = candidate
						break
	return out


## Volume linear (0–1) → dB do bus. 0 vira mudo.
static func linear_to_bus_db(v: float) -> float:
	if v <= 0.001:
		return -80.0
	return linear_to_db(clampf(v, 0.0, 1.0))


static func motion_factor(settings: Dictionary) -> float:
	return REDUCED_MOTION if bool(settings.get("reduce_motion", false)) else 1.0
