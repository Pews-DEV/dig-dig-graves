class_name RunClearing
extends RefCounted
## Fundo do Turno v2 (UI/UX §5 rev. 1.1; MANIFEST "Turno — fundo v2 (mata escura)"): medidas,
## parallax e as pontas das chamas das velas pintadas em bg_a1_props. Puro e testável.

## As 3 camadas medem 672×392 (tela + 16 px por lado) e vão com o canto em (−16, −16).
const V2_ORIGIN := Vector2(-16, -16)
const V2_FRAME := Vector2(672, 392)
const V2_MAX_SHIFT := 16.0
## px de deslocamento por px de mouse a partir do centro (chão < props < mata).
const PARALLAX_GROUND := 0.010
const PARALLAX_PROPS := 0.014
const PARALLAX_WOODS := 0.022
## Centros dos halos das velas pintadas em bg_a1_props (tela).
const CANDLE_CENTERS: Array[Vector2] = [Vector2(473, 81), Vector2(85, 279)]


## round(−(mouse − centro) × fator), em px inteiros, limitado a ±16 px.
static func parallax_offset(mouse_from_center: Vector2, factor: float) -> Vector2:
	var o := (-mouse_from_center * factor).round()
	return o.clamp(Vector2(-V2_MAX_SHIFT, -V2_MAX_SHIFT), Vector2(V2_MAX_SHIFT, V2_MAX_SHIFT))


## Pontas das chamas (cores 23/25/26) perto de cada centro de halo: o px mais alto de cada coluna.
static func flame_tips(props: Texture2D, centers: Array[Vector2]) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if props == null:
		return out
	var img := props.get_image()
	if img == null:
		return out
	if img.is_compressed():
		img.decompress()
	var flame: Array[int] = [Palette.BONE_BRIGHT, Palette.LANTERN, Palette.LANTERN_BRIGHT]
	for c: Vector2 in centers:
		for x: int in range(int(c.x) - 12, int(c.x) + 13):
			for y: int in range(int(c.y) - 12, int(c.y) + 6):
				var px := Vector2i(x, y) - Vector2i(V2_ORIGIN)
				if px.x < 0 or px.y < 0 or px.x >= img.get_width() or px.y >= img.get_height():
					continue
				var col := img.get_pixel(px.x, px.y)
				if col.a > 0.5 and flame.has(Palette.index_of(col)):
					out.append(Vector2i(x, y))
					break
	return out


