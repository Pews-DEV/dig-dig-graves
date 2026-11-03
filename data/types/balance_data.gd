class_name BalanceData
extends Resource
## Números globais de balanceamento (GDD §4, §5, §14). Ajustáveis sem tocar em código.

## Valores-base dos stats (Pá Velha, GDD §4.4/§4.5/§4.7).
@export var base_stats: Dictionary = {
	&"damage": 1.0,
	&"pulse_interval": 1.0,
	&"radius": 1.0,
	&"area_step": 0.0,
	&"excess_carries": 0.0,
	&"stomp_enabled": 0.0,
	&"stomp_cd": 8.0,
	&"stomp_mult": 4.0,
	&"stomp_auto": 0.0,
	&"stomp_ring": 0.0,
	&"deep_mult": 1.0,
	&"double_hit": 0.0,
	&"all_mult": 1.0,
	&"soul_mult": 1.0,
	&"oil_burn": 1.0,
	&"oil_per_grave": 0.0,
	&"oil_grave_cap": 0.0,
	&"wisp_rate": 1.0,
	&"wisp_life": 5.0,
	&"grave_reward": 1.0,
	&"grave_interest": 0.0,
	&"inheritance": 0.0,
	&"unrest_mult": 1.0,
	&"second_wind": 0.0,
	&"constellation": 0.0,
	&"candles": 0.0,
	&"gold_coin": 0.0,
	&"wanderers": 0.0,
	&"boss_damage": 1.0,
	&"crit_chance": 0.0,
	&"crit_mult": 2.0,
	&"oil_max": 15.0,
	&"copper_mult": 1.0,
	&"bone_chance": 0.0,
	&"regen_time": 18.0,
	&"field_size": 5.0,
	&"xp_mult": 1.0,
	&"grave_count": 1.0,
	&"wisp_oil": 2.0,
	&"wisp_decay": 0.8,
}
## GDD §14.4 / §4.7: limites.
@export var stat_min: Dictionary = {
	&"pulse_interval": 0.15,
	&"radius": 0.0,
	&"area_step": 0.0,
	&"field_size": 5.0,
	&"regen_time": 5.0,
	&"crit_chance": 0.0,
	&"stomp_cd": 4.0,
}
@export var stat_max: Dictionary = {
	&"radius": 4.0,
	&"area_step": 10.0,
	&"excess_carries": 1.0,
	&"stomp_enabled": 1.0,
	&"stomp_auto": 1.0,
	&"stomp_ring": 1.0,
	&"double_hit": 1.0,
	&"second_wind": 1.0,
	&"constellation": 1.0,
	&"crit_chance": 1.0,
	&"field_size": 18.0,
	&"grave_count": 7.0,
	&"wisp_decay": 0.92,
}

@export_group("Turno")
## GDD §4.1: o sol nasce aos 300 s.
@export var turn_cap_seconds: float = 300.0
@export var oil_burn_rate: float = 1.0
## GDD §4.5: cada segundo de óleo restante = 2% do Cobre do turno.
@export var oil_bonus_per_second: float = 0.02
## GDD §4.7: Campo Limpo = +20% do Cobre minerado desde o último Campo Limpo.
@export var field_clear_bonus: float = 0.20

@export_group("Covas (GDD §4.6)")
@export var coffin_hp_mult: float = 2.0
@export var grave_copper: float = 30.0
@export var grave_souls: float = 1.0
@export var grave_bones_min: int = 2
@export var grave_bones_max: int = 5
@export var grave_xp: float = 15.0
## Fração da Inquietação (0–1) somada por cova aberta.
@export var grave_unrest: float = 0.10
@export var graves_for_unrest: float = 900.0
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
## GDD §4.9: XP(n→n+1) = round(base × crescimento^(n−1) × XP do estágio).
@export var xp_base: float = 10.0
@export var xp_growth: float = 1.45
## GDD §4.9 / §14.4: teto de nível por noite.
@export var max_night_level: int = 15

@export_group("Lápides com efeito (GDD §4.6)")
## Cruz de pedra: Almas extras × Almas do estágio.
@export var cross_souls: float = 1.0
## Lápide com musgo: HP do Caixão × moss_coffin_mult e Ossos × moss_bones_mult.
@export var moss_coffin_mult: float = 1.5
@export var moss_bones_mult: float = 2.0

@export_group("Inquietação (GDD §4.11)")
## Tremores: com a Inquietação cheia, covas de noites comuns dão +25% de Almas.
@export var unrest_tremor_souls: float = 0.25
## UI: a caveira treme acima de unrest_alert_at; `unrest_warning` toca ao cruzar unrest_warning_at.
@export var unrest_alert_at: float = 0.8
@export var unrest_warning_at: float = 0.9

@export_group("Ativos (GDD §4.4)")
## Pisão Sísmico (E12a): multiplicador do anel em volta da área.
@export var stomp_ring_mult: float = 2.0
## Pisão Ritmado (E12b): dispara sozinho a cada N golpes normais.
@export var stomp_auto_every: int = 8
## Golpe duplo (EX): fração do dano do 2º golpe.
@export var double_hit_share: float = 0.5

@export_group("Lanterna (GDD §4.5)")
## Segundo Fôlego (L06): óleo devolvido quando zera (1× por noite).
@export var second_wind_oil: float = 5.0
## Constelação (LX): N fogos-fátuos dentro da janela param o óleo por constellation_freeze s.
@export var constellation_wisps: int = 3
@export var constellation_window: float = 6.0
@export var constellation_freeze: float = 8.0

@export_group("Elementos de tabuleiro (GDD §4.8)")
## Vela de Finados (C06).
@export var candle_max: int = 3
@export var candle_radius: float = 1.5
@export var candle_regen_mult: float = 2.0
@export var candle_copper_mult: float = 1.25
## Moeda de ouro (F09): pula a cada gold_coin_interval s (− interval_step por nível acima do 1º).
@export var gold_coin_interval: float = 20.0
@export var gold_coin_interval_step: float = 3.0
@export var gold_coin_min_interval: float = 5.0
@export var gold_coin_life: float = 4.0
## Fração do Cobre da noite paga ao tocar a moeda.
@export var gold_coin_share: float = 0.05
## Alminhas errantes (S04).
@export var wanderer_max: int = 3
@export var wanderer_respawn: float = 15.0
## Segundos para a alminha flutuar até um tile vizinho.
@export var wanderer_move_interval: float = 3.0
## Almas × Almas do estágio por alminha tocada.
@export var wanderer_souls: float = 1.0

@export_group("Árvore (GDD §6.2)")
## Replantar (N03, marco B): custo por uso = este valor × maior estágio liberado (Almas).
## O custo das Raízes-mestras (1.500 × 3ⁿ) fica no .tres de cada nó M (base_cost/cost_growth).
@export var respec_cost_per_stage: float = 5.0

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
