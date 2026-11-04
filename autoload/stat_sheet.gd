class_name StatSheet
extends RefCounted
## Agregador puro de stats (GDD §18.2): valor = clamp((base + Σadd) × Πmul).
## Fontes nomeadas (árvore, relíquias, hub, Epitáfios do turno) somam modificadores.

const DAMAGE := &"damage"
const PULSE_INTERVAL := &"pulse_interval"
const RADIUS := &"radius"
const AREA_STEP := &"area_step"
const EXCESS_CARRIES := &"excess_carries"
const STOMP_ENABLED := &"stomp_enabled"
const STOMP_COOLDOWN := &"stomp_cd"
const STOMP_MULT := &"stomp_mult"
const STOMP_AUTO := &"stomp_auto"
const STOMP_RING := &"stomp_ring"
const DEEP_MULT := &"deep_mult"
const ALL_MULT := &"all_mult"
const SOUL_MULT := &"soul_mult"
const OIL_BURN := &"oil_burn"
const OIL_PER_GRAVE := &"oil_per_grave"
const OIL_GRAVE_CAP := &"oil_grave_cap"
const WISP_RATE := &"wisp_rate"
const WISP_LIFE := &"wisp_life"
const GRAVE_REWARD := &"grave_reward"
const GRAVE_INTEREST := &"grave_interest"
const INHERITANCE := &"inheritance"
const UNREST_MULT := &"unrest_mult"
const DOUBLE_HIT := &"double_hit"
const SECOND_WIND := &"second_wind"
const CONSTELLATION := &"constellation"
const CANDLES := &"candles"
const GOLD_COIN := &"gold_coin"
const WANDERERS := &"wanderers"
const BOSS_DAMAGE := &"boss_damage"
const CRIT_CHANCE := &"crit_chance"
const CRIT_MULT := &"crit_mult"
const OIL_MAX := &"oil_max"
const COPPER_MULT := &"copper_mult"
const BONE_CHANCE := &"bone_chance"
const REGEN_TIME := &"regen_time"
const FIELD_SIZE := &"field_size"
const XP_MULT := &"xp_mult"
const GRAVE_COUNT := &"grave_count"
const WISP_OIL := &"wisp_oil"
const WISP_DECAY := &"wisp_decay"

## Rótulo e formato de exibição de cada stat (painel antes → depois, Ficha do Coveiro).
## A ordem aqui é a ordem da Ficha (GDD §18.2). `radius` é legado (substituído por area_step).
const DISPLAY: Dictionary = {
	&"damage": ["Dano", "num"],
	&"pulse_interval": ["Intervalo do golpe", "sec2"],
	&"area_step": ["Área de escavação", "area_step"],
	&"crit_chance": ["Chance de crítico", "pct"],
	&"crit_mult": ["Mult. de crítico", "mult"],
	&"deep_mult": ["Dano em camadas fundas", "mult"],
	&"excess_carries": ["Cava-Funda", "bool"],
	&"double_hit": ["Golpe duplo", "bool"],
	&"stomp_enabled": ["Pisão", "bool"],
	&"stomp_cd": ["Recarga do Pisão", "sec0"],
	&"stomp_mult": ["Dano do Pisão", "mult"],
	&"stomp_ring": ["Pisão Sísmico", "bool"],
	&"stomp_auto": ["Pisão Ritmado", "bool"],
	&"oil_max": ["Óleo da lanterna", "sec0"],
	&"oil_burn": ["Queima do óleo", "pct"],
	&"wisp_oil": ["Óleo por fogo-fátuo", "sec1"],
	&"wisp_rate": ["Frequência de fogos-fátuos", "pct"],
	&"wisp_life": ["Duração do fogo-fátuo", "sec0"],
	&"wisp_decay": ["Retorno de fogo-fátuo", "pct"],
	&"oil_per_grave": ["Óleo por cova", "sec1"],
	&"oil_grave_cap": ["Teto do óleo de cova", "sec0"],
	&"second_wind": ["Segundo Fôlego", "bool"],
	&"constellation": ["Constelação", "bool"],
	&"copper_mult": ["Cobre", "pct"],
	&"bone_chance": ["Chance de Osso (bônus)", "pp"],
	&"soul_mult": ["Almas", "pct"],
	&"all_mult": ["Cobre, Ossos e Almas", "pct"],
	&"grave_reward": ["Recompensa das covas", "pct"],
	&"grave_interest": ["Juros por cova", "pct"],
	&"inheritance": ["Herança", "pct"],
	&"field_size": ["Campo", "field"],
	&"grave_count": ["Covas simultâneas", "num"],
	&"regen_time": ["Regeneração", "sec1"],
	&"ossuary_layer": ["Camada Ossada", "bool"],
	&"unrest_mult": ["Inquietação por cova", "pct"],
	&"candles": ["Velas de Finados", "num"],
	&"gold_coin": ["Moeda de ouro", "level"],
	&"wanderers": ["Alminhas errantes", "num"],
	&"boss_damage": ["Dano no chefe", "pct"],
	&"xp_mult": ["XP", "pct"],
}
## Stats que só aparecem na Ficha quando estão ativos (0 = nó ainda não comprado).
const HIDE_WHEN_ZERO: Array[StringName] = [
	&"excess_carries", &"double_hit", &"stomp_enabled", &"stomp_ring", &"stomp_auto",
	&"second_wind", &"constellation", &"oil_per_grave", &"oil_grave_cap", &"grave_interest",
	&"inheritance", &"candles", &"gold_coin", &"wanderers", &"ossuary_layer",
]
const STOMP_STATS: Array[StringName] = [&"stomp_cd", &"stomp_mult"]

## UI/UX §22: grupos da Ficha do Coveiro, na ordem de exibição dentro de cada grupo.
## `stomp_enabled` não aparece como linha: o grupo Pisão só existe com ele comprado.
const GROUP_STRIKE := &"strike"
const GROUP_STOMP := &"stomp"
const GROUP_LANTERN := &"lantern"
const GROUP_FIELD := &"field"
const GROUP_GAINS := &"gains"
const GROUP_ABILITIES := &"abilities"
const GROUPS: Dictionary = {
	&"strike": [&"damage", &"pulse_interval", &"area_step", &"crit_chance", &"crit_mult", &"deep_mult", &"boss_damage"],
	&"stomp": [&"stomp_cd", &"stomp_mult"],
	&"lantern": [&"oil_max", &"oil_burn", &"wisp_oil", &"wisp_rate", &"wisp_life", &"wisp_decay", &"oil_per_grave", &"oil_grave_cap"],
	&"field": [&"field_size", &"grave_count", &"regen_time", &"unrest_mult", &"candles", &"gold_coin", &"wanderers"],
	&"gains": [&"copper_mult", &"bone_chance", &"soul_mult", &"all_mult", &"grave_reward", &"grave_interest", &"inheritance", &"xp_mult"],
	&"abilities": [&"excess_carries", &"double_hit", &"stomp_ring", &"stomp_auto", &"second_wind", &"constellation", &"ossuary_layer"],
}
const GROUP_TITLES: Dictionary = {
	&"strike": "Golpe",
	&"stomp": "Pisão",
	&"lantern": "Lanterna",
	&"field": "Campo",
	&"gains": "Ganhos",
	&"abilities": "Habilidades",
}
const SHEET_LEFT: Array[StringName] = [&"strike", &"stomp"]
const SHEET_RIGHT: Array[StringName] = [&"lantern", &"field", &"gains"]
## Rótulo curto na Ficha (o completo vai no tooltip). Sem entrada = rótulo de DISPLAY.
const SHORT_LABELS: Dictionary = {
	&"deep_mult": "Camadas fundas",
	&"stomp_cd": "Recarga",
	&"stomp_mult": "Dano",
	&"wisp_rate": "Freq. de fogo-fátuo",
	&"field_size": "Tamanho",
}
## Uma frase do que cada stat faz (tooltip da Ficha, UI/UX §22).
const DESCRIPTIONS: Dictionary = {
	&"damage": "Dano de cada golpe da pá em cada tile da área.",
	&"pulse_interval": "Tempo entre um golpe e outro; quanto menor, mais rápido.",
	&"area_step": "Tamanho da área que a pá acerta a cada golpe.",
	&"crit_chance": "Chance de um golpe sair crítico, com o dano multiplicado.",
	&"crit_mult": "Quanto o dano do golpe crítico é multiplicado.",
	&"deep_mult": "Multiplica o dano no Barro e nas camadas abaixo dele.",
	&"boss_damage": "Multiplica o dano que você causa no chefe.",
	&"stomp_cd": "Tempo de espera entre um Pisão e outro.",
	&"stomp_mult": "Quantas vezes o dano do golpe o Pisão causa na área.",
	&"oil_max": "Óleo com que a lanterna começa a noite; quando acaba, a noite termina.",
	&"oil_burn": "Velocidade com que a lanterna gasta o óleo; quanto menor, mais ele dura.",
	&"wisp_oil": "Óleo que cada fogo-fátuo devolve à lanterna.",
	&"wisp_rate": "Com que frequência os fogos-fátuos aparecem no campo.",
	&"wisp_life": "Quanto tempo cada fogo-fátuo fica no campo antes de sumir.",
	&"wisp_decay": "Cada fogo-fátuo da mesma noite vale esta parte do anterior.",
	&"oil_per_grave": "Óleo que cada cova aberta devolve à lanterna.",
	&"oil_grave_cap": "Máximo de óleo que as covas podem devolver por noite.",
	&"field_size": "Quantos tiles tem cada lado do campo.",
	&"grave_count": "Quantas covas podem existir no campo ao mesmo tempo.",
	&"regen_time": "Tempo para um buraco voltar a ter terra.",
	&"unrest_mult": "Quanta Inquietação cada cova aberta soma; mais traz o chefe antes.",
	&"candles": "Velas no campo; os tiles em volta regeneram mais rápido e rendem mais.",
	&"gold_coin": "Nível da moeda de ouro que pula no campo de tempos em tempos.",
	&"wanderers": "Alminhas vagando pelo campo; tocar nelas dá Almas.",
	&"copper_mult": "Multiplica todo o Cobre que você ganha.",
	&"bone_chance": "Chance extra de achar Osso ao quebrar camadas.",
	&"soul_mult": "Multiplica todas as Almas que você ganha.",
	&"all_mult": "Multiplica Cobre, Ossos e Almas ao mesmo tempo.",
	&"grave_reward": "Multiplica a recompensa de cada cova aberta.",
	&"grave_interest": "Cobre extra por cova aberta na noite, acumulando.",
	&"inheritance": "Parte do Cobre da noite que volta como bônus no Resumo.",
	&"xp_mult": "Multiplica a XP ganha ao quebrar camadas.",
	&"excess_carries": "O dano que sobra numa camada continua na camada de baixo.",
	&"double_hit": "Cada golpe bate de novo com metade do dano.",
	&"stomp_ring": "O Pisão também acerta o anel de tiles em volta da área.",
	&"stomp_auto": "O Pisão dispara sozinho a cada 8 golpes.",
	&"second_wind": "Uma vez por noite, quando o óleo acaba, a lanterna volta com 5 s.",
	&"constellation": "Pegar 3 fogos-fátuos em menos de 6 s para o gasto de óleo por 8 s.",
	&"ossuary_layer": "Uma camada Ossada nova no fundo de todos os tiles, rica em Ossos.",
}

var base: Dictionary = {}
var min_values: Dictionary = {}
var max_values: Dictionary = {}
var _sources: Dictionary = {}  # StringName -> Array[StatModifier]
var _cache: Dictionary = {}
var _dirty: bool = true


func _init(p_base: Dictionary = {}, p_min: Dictionary = {}, p_max: Dictionary = {}) -> void:
	base = p_base.duplicate()
	min_values = p_min.duplicate()
	max_values = p_max.duplicate()


static func from_balance(balance: BalanceData) -> StatSheet:
	return StatSheet.new(balance.base_stats, balance.stat_min, balance.stat_max)


func set_source(source: StringName, mods: Array[StatModifier]) -> void:
	_sources[source] = mods.duplicate()
	_dirty = true


func clear_source(source: StringName) -> void:
	_sources.erase(source)
	_dirty = true


func get_value(stat: StringName) -> float:
	if _dirty:
		_recompute()
	return float(_cache.get(stat, base.get(stat, 0.0)))


func snapshot() -> Dictionary:
	if _dirty:
		_recompute()
	return _cache.duplicate()


## Cópia com uma fonte substituída (usada para prévia "antes → depois").
func with_source(source: StringName, mods: Array[StatModifier]) -> StatSheet:
	var copy := StatSheet.new(base, min_values, max_values)
	for key: StringName in _sources:
		copy._sources[key] = _sources[key]
	copy.set_source(source, mods)
	return copy


func _recompute() -> void:
	var adds: Dictionary = {}
	var muls: Dictionary = {}
	for source: StringName in _sources:
		for m: StatModifier in _sources[source]:
			if m.op == StatModifier.Op.ADD:
				adds[m.stat] = float(adds.get(m.stat, 0.0)) + m.value
			else:
				muls[m.stat] = float(muls.get(m.stat, 1.0)) * m.value
	_cache.clear()
	var keys: Dictionary = {}
	for k: StringName in base:
		keys[k] = true
	for k: StringName in adds:
		keys[k] = true
	for k: StringName in muls:
		keys[k] = true
	for stat: StringName in keys:
		var v: float = (float(base.get(stat, 0.0)) + float(adds.get(stat, 0.0))) * float(muls.get(stat, 1.0))
		if min_values.has(stat):
			v = maxf(v, float(min_values[stat]))
		if max_values.has(stat):
			v = minf(v, float(max_values[stat]))
		_cache[stat] = v
	_dirty = false


## Valor sem nenhuma fonte (base da Pá Velha, já com min/max), para comparar na Ficha.
func base_value(stat: StringName) -> float:
	var v: float = float(base.get(stat, 0.0))
	if min_values.has(stat):
		v = maxf(v, float(min_values[stat]))
	if max_values.has(stat):
		v = minf(v, float(max_values[stat]))
	return v


static func label_of(stat: StringName) -> String:
	var d: Array = DISPLAY.get(stat, [String(stat), "num"])
	return String(d[0])


## Rótulo da Ficha: curto se houver (SHORT_LABELS), senão o de DISPLAY. Sem tradução.
static func short_label_of(stat: StringName) -> String:
	if SHORT_LABELS.has(stat):
		return String(SHORT_LABELS[stat])
	return label_of(stat)


static func description_of(stat: StringName) -> String:
	return String(DESCRIPTIONS.get(stat, ""))


static func group_title(group: StringName) -> String:
	return String(GROUP_TITLES.get(group, String(group)))


static func group_of(stat: StringName) -> StringName:
	for g: StringName in GROUPS:
		var stats: Array = GROUPS[g]
		if stats.has(stat):
			return g
	return &""


## Mesma regra da Ficha (GDD §18.2): esconde nós não comprados e o Pisão sem o Pisão.
static func is_visible_on_sheet(stat: StringName, value: float, stomp_on: bool) -> bool:
	if HIDE_WHEN_ZERO.has(stat) and value <= 0.0:
		return false
	if STOMP_STATS.has(stat) and not stomp_on:
		return false
	return true


static func format_value(stat: StringName, v: float) -> String:
	var d: Array = DISPLAY.get(stat, [String(stat), "num"])
	match String(d[1]):
		"sec0":
			return "%d s" % roundi(v)
		"sec1":
			return ("%.1f s" % v).replace(".", ",")
		"sec2":
			return ("%.2f s" % v).replace(".", ",")
		"pct":
			return "%d%%" % roundi(v * 100.0)
		"pp":
			return TranslationServer.translate("+%d p.p.") % roundi(v * 100.0)
		"mult":
			return ("×%.1f" % v).replace(".", ",")
		"area":
			var side := roundi(v) * 2 + 1
			return "%d×%d" % [side, side]
		"area_step":
			var step := clampi(roundi(v), 0, 10)
			var width := int(ceil(float(step + 1) / 2.0))
			var height := int(floor(float(step + 1) / 2.0)) + 1
			return "%d×%d" % [width, height]
		"bool":
			return "Sim" if v > 0.0 else "Não"
		"level":
			return TranslationServer.translate("Nv %d") % roundi(v) if v > 0.0 else "Não"
		"field":
			return "%d×%d" % [roundi(v), roundi(v)]
	return NumberFormat.format(v)
