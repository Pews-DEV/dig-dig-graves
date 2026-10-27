class_name TileAtlas
extends RefCounted
## Monta o TileSet do campo (GDD §18.2) e reúne as texturas de sobreposição da área.
## Layout (MANIFEST / DA §5): célula 32×24, pivô (16,16) = linha mais larga do losango;
## colunas = estágio S0..S3, linhas = variante. Fonte 0 = atlas normal, 1 = atlas `_lit` (DA §4.2).
## Asset fora do manifesto → protótipo cinza gerado em runtime (DA §12).

const CELL := Vector2i(32, 24)
const PIVOT := Vector2i(16, 16)
const SOURCE_NORMAL := 0
const SOURCE_LIT := 1
## Rochas (MANIFEST rocha): mesma célula 32×24 e pivô do tile; coluna = variante.
const SOURCE_ROCK := 2
const SOURCE_ROCK_LIT := 3
## Covas (MANIFEST grave_a1): 4 colunas (eixo×2 + metade) × 3 linhas (exposto, rachado, aberto).
const SOURCE_GRAVE := 4
const SOURCE_GRAVE_LIT := 5
const GRAVE_COLS := 4
const GRAVE_ROWS := 3
const GRAVE_ROW_EXPOSED := 0
const GRAVE_ROW_CRACKED := 1
const GRAVE_ROW_OPEN := 2
## MANIFEST grave_a1: linha "rachado" quando o HP do caixão < 50%.
const GRAVE_CRACK_RATIO := 0.5
const STAGES := 4
## Desloca a textura 32×24 para que o pivô (16,16) caia no centro da célula.
const TEXTURE_ORIGIN := Vector2i(0, PIVOT.y - (CELL.y >> 1))
## Rachaduras (MANIFEST cracks_a1): célula 16×8 com canto em (8,13) da célula do tile.
const CRACK_CELL := Vector2i(16, 8)
const CRACK_OFFSET := Vector2(8, 13) - Vector2(PIVOT)

var tile_set: TileSet
## Variantes preenchidas (linhas) por coluna S0..S3, detectadas no próprio atlas.
var variants: PackedInt32Array = PackedInt32Array([1, 1, 1, 1])
var using_placeholder: bool = true
var cracks: Texture2D
var cracks_lit: Texture2D
var regen: Texture2D
var regen_lit: Texture2D
var rock_variants: int = 1
var has_grave_art: bool = false
var grave_open: Texture2D
var grave_open_lit: Texture2D


static func build(area: AreaData) -> TileAtlas:
	var atlas := TileAtlas.new()
	var normal := AssetManifest.texture(area.tile_atlas_path)
	var lit: Texture2D = null
	if normal != null:
		var img := _image_of(normal)
		atlas.using_placeholder = false
		atlas.variants = _detect_variants(img)
		lit = AssetManifest.texture(area.tile_atlas_lit_path)
		if lit == null:
			lit = ImageTexture.create_from_image(make_lit(img))
	else:
		var img := make_placeholder()
		normal = ImageTexture.create_from_image(img)
		lit = ImageTexture.create_from_image(make_lit(img))
	var rock := AssetManifest.texture(area.rock_atlas_path)
	var rock_img := _image_of(rock) if rock != null else make_rock_placeholder()
	if rock == null:
		rock = ImageTexture.create_from_image(rock_img)
	atlas.rock_variants = maxi(1, int(rock_img.get_width() / float(CELL.x)))
	var rock_lit := ImageTexture.create_from_image(make_lit(rock_img))
	atlas.tile_set = atlas._make_tileset(normal, lit)
	atlas.tile_set.add_source(atlas._make_row_source(rock, atlas.rock_variants), SOURCE_ROCK)
	atlas.tile_set.add_source(atlas._make_row_source(rock_lit, atlas.rock_variants), SOURCE_ROCK_LIT)
	var grave := AssetManifest.texture(area.grave_atlas_path)
	if grave != null:
		var grave_lit := AssetManifest.texture(area.grave_atlas_lit_path)
		if grave_lit == null:
			grave_lit = ImageTexture.create_from_image(make_lit(_image_of(grave)))
		atlas.has_grave_art = true
		atlas.tile_set.add_source(atlas._make_grid_source(grave, GRAVE_COLS, GRAVE_ROWS), SOURCE_GRAVE)
		atlas.tile_set.add_source(atlas._make_grid_source(grave_lit, GRAVE_COLS, GRAVE_ROWS), SOURCE_GRAVE_LIT)
		atlas.grave_open = AssetManifest.texture(area.grave_open_path)
		atlas.grave_open_lit = AssetManifest.texture(area.grave_open_lit_path)
		if atlas.grave_open_lit == null:
			atlas.grave_open_lit = atlas.grave_open
	atlas.cracks = AssetManifest.texture(area.crack_atlas_path)
	atlas.cracks_lit = AssetManifest.texture(area.crack_atlas_lit_path)
	if atlas.cracks_lit == null:
		atlas.cracks_lit = atlas.cracks
	atlas.regen = AssetManifest.texture(area.regen_atlas_path)
	atlas.regen_lit = AssetManifest.texture(area.regen_atlas_lit_path)
	if atlas.regen_lit == null:
		atlas.regen_lit = atlas.regen
	return atlas


static func _image_of(tex: Texture2D) -> Image:
	var img := tex.get_image()
	if img.is_compressed():
		img.decompress()
	return img


## Linhas preenchidas por coluna (célula com algum pixel opaco = variante existente).
static func _detect_variants(img: Image) -> PackedInt32Array:
	var out := PackedInt32Array()
	var rows := maxi(1, int(img.get_height() / float(CELL.y)))
	for col: int in STAGES:
		var count := 0
		for row: int in rows:
			var region := img.get_region(Rect2i(col * CELL.x, row * CELL.y, CELL.x, CELL.y))
			if not region.is_invisible():
				count = row + 1
		out.append(maxi(count, 1))
	return out


## Variante determinística por célula (não "pisca" ao trocar de estágio ou de luz).
func variant_for(column: int, cell: Vector2i) -> int:
	var n := maxi(1, variants[column] if column < variants.size() else 1)
	var h := absi((cell.x * 73856093) ^ (cell.y * 19349663))
	return h % n


func rock_variant_for(cell: Vector2i) -> int:
	return absi((cell.x * 83492791) ^ (cell.y * 2654435761)) % rock_variants


func _make_grid_source(tex: Texture2D, cols: int, rows: int) -> TileSetAtlasSource:
	var src := TileSetAtlasSource.new()
	src.texture = tex
	src.texture_region_size = CELL
	for row: int in rows:
		for col: int in cols:
			var coords := Vector2i(col, row)
			src.create_tile(coords)
			src.get_tile_data(coords, 0).texture_origin = TEXTURE_ORIGIN
	return src


## Fonte com `count` células numa linha (coluna = variante).
func _make_row_source(tex: Texture2D, count: int) -> TileSetAtlasSource:
	var src := TileSetAtlasSource.new()
	src.texture = tex
	src.texture_region_size = CELL
	for col: int in count:
		var coords := Vector2i(col, 0)
		src.create_tile(coords)
		src.get_tile_data(coords, 0).texture_origin = TEXTURE_ORIGIN
	return src


func _make_tileset(normal: Texture2D, lit: Texture2D) -> TileSet:
	var ts := TileSet.new()
	ts.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	ts.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
	ts.tile_size = Vector2i(IsoDraw.TILE_W, IsoDraw.TILE_H)
	ts.add_source(_make_source(normal), SOURCE_NORMAL)
	ts.add_source(_make_source(lit), SOURCE_LIT)
	return ts


func _make_source(tex: Texture2D) -> TileSetAtlasSource:
	var src := TileSetAtlasSource.new()
	src.texture = tex
	src.texture_region_size = CELL
	for col: int in STAGES:
		for row: int in variants[col]:
			var coords := Vector2i(col, row)
			src.create_tile(coords)
			src.get_tile_data(coords, 0).texture_origin = TEXTURE_ORIGIN
	return src


## Região da rachadura (nível 0: HP < 66%, nível 1: HP < 33%) para o estágio S0..S2.
static func crack_region(stage: int, level: int) -> Rect2:
	return Rect2(Vector2(level * CRACK_CELL.x, stage * CRACK_CELL.y), Vector2(CRACK_CELL))


# --- Protótipo cinza (DA §7 / §12) ---------------------------------------------
# Valor do centro do tile desce a cada estágio: grama 11 → terra 15 → barro 14 → buraco 13.

static func make_placeholder() -> Image:
	var img := Image.create_empty(CELL.x * STAGES, CELL.y, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_draw_s0(img, 0)
	_draw_s1(img, CELL.x)
	_draw_s2(img, CELL.x * 2)
	_draw_s3(img, CELL.x * 3)
	return img


static func _c(i: int) -> Color:
	return Palette.color(i)


static func _draw_s0(img: Image, ox: int) -> void:
	var cx := ox + PIVOT.x
	IsoDraw.fill_diamond_image(img, cx, PIVOT.y, 32, _c(Palette.GRASS))
	IsoDraw.edge_diamond_image(img, cx, PIVOT.y, 32, &"ul", _c(Palette.GRASS_LIGHT))
	IsoDraw.edge_diamond_image(img, cx, PIVOT.y, 32, &"ll", _c(Palette.GRASS_DARK))
	IsoDraw.edge_diamond_image(img, cx, PIVOT.y, 32, &"lr", _c(Palette.GRASS_DEEP))
	for p: Vector2i in [Vector2i(9, 10), Vector2i(9, 11), Vector2i(15, 8), Vector2i(22, 10), Vector2i(22, 11)]:
		img.set_pixel(ox + p.x, p.y, _c(Palette.GRASS_LIGHT))


static func _draw_s1(img: Image, ox: int) -> void:
	var cx := ox + PIVOT.x
	IsoDraw.fill_diamond_image(img, cx, PIVOT.y, 32, _c(Palette.DIRT))
	IsoDraw.edge_diamond_image(img, cx, PIVOT.y, 32, &"ul", _c(Palette.GRASS_DARK))
	IsoDraw.edge_diamond_image(img, cx, PIVOT.y, 32, &"ur", _c(Palette.DIRT_LIGHT))
	IsoDraw.edge_diamond_image(img, cx, PIVOT.y, 32, &"lr", _c(Palette.DIRT_DARK))
	for p: Vector2i in [Vector2i(12, 15), Vector2i(13, 15), Vector2i(19, 18), Vector2i(20, 18)]:
		img.set_pixel(ox + p.x, p.y, _c(Palette.DIRT_LIGHT))


static func _draw_s2(img: Image, ox: int) -> void:
	var cx := ox + PIVOT.x
	IsoDraw.fill_diamond_image(img, cx, PIVOT.y, 32, _c(Palette.DIRT))
	IsoDraw.edge_diamond_image(img, cx, PIVOT.y, 32, &"ul", _c(Palette.DIRT_LIGHT))
	IsoDraw.edge_diamond_image(img, cx, PIVOT.y, 32, &"lr", _c(Palette.DIRT_DARK))
	IsoDraw.fill_diamond_image(img, cx, PIVOT.y, 20, _c(Palette.DIRT_DARK))
	IsoDraw.edge_diamond_image(img, cx, PIVOT.y, 20, &"ul", _c(Palette.DIRT_EDGE))


static func _draw_s3(img: Image, ox: int) -> void:
	var cx := ox + PIVOT.x
	IsoDraw.fill_diamond_image(img, cx, PIVOT.y, 32, _c(Palette.DIRT_DARK))
	IsoDraw.edge_diamond_image(img, cx, PIVOT.y, 32, &"ul", _c(Palette.DIRT_EDGE))
	IsoDraw.fill_diamond_image(img, cx, PIVOT.y, 28, _c(Palette.DIRT_BOTTOM))
	IsoDraw.edge_diamond_image(img, cx, PIVOT.y, 28, &"ul", _c(Palette.DIRT))
	for p: Vector2i in [Vector2i(18, 20), Vector2i(19, 20), Vector2i(17, 21)]:
		img.set_pixel(ox + p.x, p.y, _c(Palette.OUTLINE))


## Rocha placeholder (2 variantes): domo de pedra 06/07/08 sobre o losango, contorno 01.
static func make_rock_placeholder() -> Image:
	var img := Image.create_empty(CELL.x * 2, CELL.y, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for v: int in 2:
		var ox := v * CELL.x
		var cx := ox + PIVOT.x
		IsoDraw.fill_diamond_image(img, cx, PIVOT.y, 28, _c(Palette.NIGHT_VIOLET))
		var half_max := 11 - v * 2
		for y: int in range(5, 20):
			var t := (y - 5) / 14.0
			var half := roundi(half_max * sqrt(clampf(1.0 - pow(1.0 - t, 2.0), 0.0, 1.0)))
			for x: int in range(cx - half - 1, cx + half + 1):
				var c := Palette.STONE
				if x <= cx - half:
					c = Palette.OUTLINE
				elif x >= cx + half:
					c = Palette.OUTLINE
				elif x < cx - half + 3:
					c = Palette.STONE_LIGHT
				elif x > cx + half - 4:
					c = Palette.STONE_DARK
				img.set_pixel(x, y, _c(c))
		for x: int in range(cx - 2, cx + 2):
			img.set_pixel(x, 4, _c(Palette.OUTLINE))
		if v == 1:
			IsoDraw.fill_diamond_image(img, ox + 25, 19, 8, _c(Palette.STONE_DARK))
	return img


## DA §4.2: variante iluminada = cada cor 1 degrau acima na rampa (paleta fechada).
static func make_lit(src: Image) -> Image:
	var img := src.duplicate() as Image
	img.convert(Image.FORMAT_RGBA8)
	for y: int in img.get_height():
		for x: int in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a < 0.5:
				continue
			var idx := Palette.index_of(c)
			if idx > 0:
				img.set_pixel(x, y, Palette.color(Palette.lit_index(idx)))
	return img
