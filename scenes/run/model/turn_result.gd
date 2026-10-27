class_name TurnResult
extends RefCounted
## Totais de um turno (GDD §15.4). Valores de "minerado" e bônus ficam separados.

var area_id: int = 1
var duration: float = 0.0
var end_reason: StringName = &"oil"  # &"oil" | &"dawn"
var copper_mined: float = 0.0
var field_clear_bonus: float = 0.0
var field_clears: int = 0
var oil_left: float = 0.0
var oil_bonus: float = 0.0
var bones: float = 0.0
var souls: float = 0.0
var graves_opened: int = 0
var layers_broken: int = 0
var max_crit: float = 0.0
var pulses: int = 0
var damage_dealt: float = 0.0
var level: int = 1
var xp_total: float = 0.0
## Golpe (1-based) em que a 1ª cova abriu neste turno; −1 se nenhuma.
var first_grave_pulse: int = -1
var unrest_start: float = 0.0
var unrest_end: float = 0.0
var rocks_placed: int = 0
var rocks_broken: int = 0
var oil_drained: float = 0.0
var wisps_collected: int = 0
var oil_from_wisps: float = 0.0


func copper_total() -> float:
	return copper_mined + field_clear_bonus + oil_bonus


func to_dict() -> Dictionary:
	return {
		"area_id": area_id, "duration": duration, "end_reason": String(end_reason),
		"copper_mined": copper_mined, "field_clear_bonus": field_clear_bonus,
		"field_clears": field_clears, "oil_left": oil_left, "oil_bonus": oil_bonus,
		"bones": bones, "souls": souls, "graves_opened": graves_opened,
		"layers_broken": layers_broken, "max_crit": max_crit, "pulses": pulses,
		"damage_dealt": damage_dealt, "level": level, "xp_total": xp_total,
		"first_grave_pulse": first_grave_pulse, "unrest_start": unrest_start,
		"unrest_end": unrest_end, "rocks_placed": rocks_placed, "rocks_broken": rocks_broken,
		"oil_drained": oil_drained, "wisps_collected": wisps_collected,
		"oil_from_wisps": oil_from_wisps, "copper_total": copper_total(),
	}
