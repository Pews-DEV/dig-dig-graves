class_name LayerData
extends Resource
## Camada de solo (GDD §4.3). Valores-base; a área aplica os multiplicadores (§14.2).

@export var id: StringName
@export var display_name: String
@export var hp: float = 1.0
@export var copper: float = 0.0
@export var xp: float = 0.0
## GDD §4.3: camadas Barro e mais fundas recebem o multiplicador profundo.
@export var deep: bool = false
@export_range(0.0, 1.0) var bone_chance: float = 0.0
## Coluna do atlas mostrada enquanto esta camada é o topo: 0..2 = S0..S2,
## 3 = buraco (Caixão: S3 + tampa por cima), 4 = rocha, 5 = Ossada.
@export var stage_column: int = 0
## Índices da paleta para torrões/poeira desta camada (claro → escuro).
@export var particle_colors: PackedInt32Array = PackedInt32Array()
## Chave de SFX do golpe (GDD §17).
@export var sfx_key: StringName
