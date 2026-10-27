class_name BalanceData
extends Resource
## Números globais de balanceamento (GDD §4, §5, §14). Ajustáveis sem tocar em código.

## Valores-base dos stats (Pá Velha, GDD §4.4/§4.5/§4.7).
@export var base_stats: Dictionary = {
	&"damage": 1.0,
	&"pulse_interval": 1.0,
	&"radius": 1.0,
	&"crit_chance": 0.0,
	&"crit_mult": 2.0,
	&"oil_max": 15.0,
	&"copper_mult": 1.0,
	&"bone_chance": 0.0,
	&"regen_time": 25.0,
	&"field_size": 12.0,
	&"xp_mult": 1.0,
	&"grave_count": 2.0,
	&"wisp_oil": 2.0,
}
## GDD §14.4 / §4.7: limites.
@export var stat_min: Dictionary = {
	&"pulse_interval": 0.15,
	&"radius": 0.0,
	&"regen_time": 6.0,
	&"crit_chance": 0.0,
}
@export var stat_max: Dictionary = {
	&"radius": 4.0,
	&"crit_chance": 1.0,
	&"field_size": 18.0,
	&"grave_count": 7.0,
}

@export_group("Turno")
## GDD §4.1: o sol nasce aos 300 s.
@export var turn_cap_seconds: float = 300.0
@export var oil_burn_rate: float = 1.0
## GDD §4.5: cada segundo de óleo restante = 2% do Cobre do turno.
@export var oil_bonus_per_second: float = 0.02
## GDD §4.7: Campo Limpo = +20% do Cobre do turno.
@export var field_clear_bonus: float = 0.20

@export_group("Covas (GDD §4.6)")
@export var coffin_hp_mult: float = 2.0
@export var grave_copper: float = 25.0
@export var grave_souls: float = 1.0
@export var grave_bones_min: int = 2
@export var grave_bones_max: int = 5
@export var grave_xp: float = 15.0
## Fração da Inquietação (0–1) somada por cova aberta.
@export var grave_unrest: float = 0.10
## Segundos que a Cova Aberta fica visível antes de fechar.
@export var grave_open_time: float = 3.0

@export_group("Rochas (GDD §4.8)")
@export var rock_hp_mult: float = 30.0
## Rochas sorteadas por campo no início do turno (Área 1: raras).
@export var rocks_min: int = 0
@export var rocks_max: int = 2
## Óleo drenado por rocha dentro da área, por golpe (GDD §4.5).
@export var rock_oil_drain: float = 0.5

@export_group("Fogos-fátuos (GDD §4.5)")
@export var wisp_interval: float = 12.0
## Variação aleatória (±) do intervalo entre fogos-fátuos.
@export var wisp_interval_jitter: float = 3.0
@export var wisp_lifetime: float = 5.0

@export_group("XP")
## GDD §4.9: XP(n→n+1) = round(base × crescimento^(n−1)).
@export var xp_base: float = 10.0
@export var xp_growth: float = 1.35

@export_group("Luz")
## GDD §4.5 / DA §4.2: raio de luz por fração de óleo restante.
## light_radii[i] vale enquanto fração > light_thresholds[i]; o último é o mínimo.
@export var light_thresholds: PackedFloat32Array = PackedFloat32Array([0.75, 0.5, 0.25])
@export var light_radii: PackedInt32Array = PackedInt32Array([4, 3, 2, 1])

@export_group("Feedback")
## GDD §14.4: máximo de números flutuantes por pulso.
@export var max_floating_numbers: int = 40
## DA §9.3: tremor máximo em px.
@export var max_shake_px: float = 2.0
