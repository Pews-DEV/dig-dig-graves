class_name AreaData
extends Resource
## Área jogável (GDD §10, §14.2). Camadas em ordem topo → fundo (§4.3).

@export var id: int = 1
@export var display_name: String
@export var layers: Array[LayerData] = []
## GDD §4.6: camada extra no fundo dos tiles de cova (HP = BalanceData.coffin_hp_mult × camada mais dura).
@export var coffin_layer: LayerData
## GDD §4.8: camada única da Rocha (HP = BalanceData.rock_hp_mult × HP da camada do topo).
@export var rock_layer: LayerData
@export var hp_mult: float = 1.0
@export var reward_mult: float = 1.0
@export var xp_mult: float = 1.0
@export var base_field_size: int = 12
@export var max_field_size: int = 18
## Atlas de tiles (Direção de Arte §11.4). Só usado se registrado em assets/MANIFEST.md.
@export_file("*.png") var tile_atlas_path: String
@export_file("*.png") var tile_atlas_lit_path: String
## Rachaduras de dano parcial (DA §7): célula 16×8; coluna = nível, linha = estágio.
@export_file("*.png") var crack_atlas_path: String
@export_file("*.png") var crack_atlas_lit_path: String
## Regeneração (DA §9.2): frames 32×24 na horizontal.
@export_file("*.png") var regen_atlas_path: String
@export_file("*.png") var regen_atlas_lit_path: String
## Lápide (MANIFEST lapide: células 16×24, coluna = variante, pivô (8,23)).
@export_file("*.png") var tombstone_path: String
## Covas (MANIFEST grave_a1): célula 32×24; coluna = eixo/metade, linha = estado.
@export_file("*.png") var grave_atlas_path: String
@export_file("*.png") var grave_atlas_lit_path: String
## Abertura da cova (MANIFEST grave_open_a1): coluna = frame, linha = eixo/metade.
@export_file("*.png") var grave_open_path: String
@export_file("*.png") var grave_open_lit_path: String
## Rochas (MANIFEST rocha: células 32×24, coluna = variante, pivô (16,16)).
@export_file("*.png") var rock_atlas_path: String
