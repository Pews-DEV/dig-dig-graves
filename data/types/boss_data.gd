class_name BossData
extends Resource
## Definição data-driven de chefe (GDD §10.2).

@export var id: StringName
@export var display_name: String
@export var cells: Vector2i = Vector2i(2, 2)
@export var hp: float = 35000.0
@export_enum("HOP", "TRAIL", "BULBS", "PHASES", "CYCLE") var behavior: String = "HOP"
@export var hop_interval: float = 4.0
@export var hop_invulnerability: float = 0.6
@export var first_victory_souls: float = 25.0
@export var first_victory_bones: float = 60.0
@export var rematch_souls: float = 5.0
@export var sprite_id: StringName = &"boss_caixao_fujao"
@export var icon_id: StringName = &"icon_boss_caixao"
@export var unlocks: Array[StringName] = [&"stage_2", &"hub", &"respec", &"tita"]
