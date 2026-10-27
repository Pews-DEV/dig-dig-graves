extends Node
## Carteira permanente (GDD §5). Recursos em float; nada se perde ao fim do turno.

const COPPER := &"copper"
const BONES := &"bones"
const SOULS := &"souls"
const LUNAR_SEALS := &"lunar_seals"
const CURRENCIES: Array[StringName] = [COPPER, BONES, SOULS, LUNAR_SEALS]

var balances: Dictionary = {}


func _init() -> void:
	reset()


func reset() -> void:
	for c: StringName in CURRENCIES:
		balances[c] = 0.0


func get_amount(currency: StringName) -> float:
	return float(balances.get(currency, 0.0))


func add(currency: StringName, amount: float) -> void:
	if amount == 0.0:
		return
	balances[currency] = get_amount(currency) + amount
	Events.currency_changed.emit(currency, get_amount(currency))


func can_afford(currency: StringName, amount: float) -> bool:
	return get_amount(currency) >= amount


func spend(currency: StringName, amount: float) -> bool:
	if not can_afford(currency, amount):
		return false
	balances[currency] = get_amount(currency) - amount
	Events.currency_changed.emit(currency, get_amount(currency))
	return true


func to_dict() -> Dictionary:
	var out: Dictionary = {}
	for c: StringName in CURRENCIES:
		out[String(c)] = get_amount(c)
	return out


func from_dict(data: Dictionary) -> void:
	reset()
	for c: StringName in CURRENCIES:
		balances[c] = float(data.get(String(c), 0.0))
