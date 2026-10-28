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
const DISPLAY: Dictionary = {
	&"damage": ["Dano", "num"],
	&"pulse_interval": ["Intervalo do golpe", "sec2"],
	&"radius": ["Área", "area"],
	&"area_step": ["Área de escavação", "area_step"],
	&"excess_carries": ["Cava-Funda", "bool"],
	&"stomp_enabled": ["Pisão", "bool"],
	&"stomp_cd": ["Recarga do Pisão", "sec0"],
	&"stomp_mult": ["Dano do Pisão", "mult"],
	&"stomp_auto": ["Pisão automático", "bool"],
	&"stomp_ring": ["Anel do Pisão", "bool"],
	&"deep_mult": ["Dano em camadas fundas", "mult"],
	&"double_hit": ["Golpe duplo", "bool"],
	&"crit_chance": ["Chance de crítico", "pct"],
	&"crit_mult": ["Mult. de crítico", "mult"],
	&"oil_max": ["Óleo da lanterna", "sec0"],
	&"copper_mult": ["Cobre", "pct"],
	&"bone_chance": ["Chance de Osso (bônus)", "pp"],
	&"regen_time": ["Regeneração", "sec1"],
	&"field_size": ["Campo", "field"],
	&"xp_mult": ["XP", "pct"],
	&"grave_count": ["Covas simultâneas", "num"],
	&"wisp_oil": ["Óleo por fogo-fátuo", "sec0"],
	&"wisp_decay": ["Retorno de fogo-fátuo", "pct"],
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


static func label_of(stat: StringName) -> String:
	var d: Array = DISPLAY.get(stat, [String(stat), "num"])
	return String(d[0])


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
		"field":
			return "%d×%d" % [roundi(v), roundi(v)]
	return NumberFormat.format(v)
