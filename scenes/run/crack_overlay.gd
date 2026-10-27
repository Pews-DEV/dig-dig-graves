class_name CrackOverlay
extends Node2D
## Rachaduras de dano parcial (DA §7): HP < 66% e < 33% da camada atual.
## Só desenha se `cracks_a1` estiver no manifesto (não há placeholder: é detalhe de M1).

const LEVEL_THRESHOLDS: Array[float] = [0.66, 0.33]

var tiles: TileMapLayer
var atlas: TileAtlas
var model: FieldModel
var lit_flags: PackedByteArray


func _draw() -> void:
	if atlas == null or atlas.cracks == null or model == null:
		return
	for i: int in model.tile_count():
		var cell := model.cell_of(i)
		var stage := model.stage_column(cell)
		if stage >= FieldModel.HOLE_COLUMN:  # Buraco, Caixão e Rocha não têm rachadura
			continue
		if model.top_layer(cell) == null:
			continue  # lápide (bloqueado) e buracos não racham
		var ratio := model.hp_ratio(cell)
		var level := -1
		for l: int in LEVEL_THRESHOLDS.size():
			if ratio < LEVEL_THRESHOLDS[l]:
				level = l
		if level < 0:
			continue
		var lit := i < lit_flags.size() and lit_flags[i] == 1
		var tex := atlas.cracks_lit if lit else atlas.cracks
		var pos := tiles.map_to_local(cell) + TileAtlas.CRACK_OFFSET
		draw_texture_rect_region(tex, Rect2(pos, Vector2(TileAtlas.CRACK_CELL)), TileAtlas.crack_region(stage, level))
