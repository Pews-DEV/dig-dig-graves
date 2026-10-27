extends Node
## Stats calculados do jogador (GDD §18.2). Fino invólucro sobre StatSheet;
## fontes: árvore (agora), relíquias/hub/Epitáfios (depois). Cache invalidado por set_source.

var sheet: StatSheet


func setup(balance: BalanceData) -> void:
	sheet = StatSheet.from_balance(balance)


func set_source(source: StringName, mods: Array[StatModifier]) -> void:
	sheet.set_source(source, mods)
	Events.stats_changed.emit()


func get_value(stat: StringName) -> float:
	return sheet.get_value(stat)


func snapshot() -> Dictionary:
	return sheet.snapshot()


## Prévia de um stat se a fonte `source` fosse trocada por `mods`.
func preview(source: StringName, mods: Array[StatModifier], stat: StringName) -> float:
	return sheet.with_source(source, mods).get_value(stat)
