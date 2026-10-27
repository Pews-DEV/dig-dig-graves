class_name TitleLayoutData
extends Resource
## Coordenadas da tela-título no enquadramento final 640×360 (UI/UX §9.6). Os valores padrão
## são os números-alvo do contrato; quando o pixel-artist registrar as posições reais no
## assets/MANIFEST.md, basta ajustar `data/title/title_layout.tres` (nada no código).

const TEXT := "DIGDIGGRAVES"
const LETTER_COUNT := 12
## Placeholder do logo: glifo 5×7 em blocos de `scale` px, contorno 1 px e sombra (1, 2).
const GLYPH := Vector2i(5, 7)
const LINE_SCALE: Array[int] = [4, 5]
const WORD_GAP := 10

@export_group("Câmera (descida da abertura)")
## A câmera começa este tanto acima; cada camada desce 240 × (1 − p) × fator.
@export var camera_drop: float = 240.0
@export var factor_sky: float = 0.25
@export var factor_village: float = 0.5
@export var factor_wall: float = 0.8
@export var factor_fg: float = 1.0

@export_group("Camadas")
## y do topo de cada camada no enquadramento final (MANIFEST "Tela-título — cenário e logo");
## −1 = base da imagem na base da tela.
@export var sky_y: int = -240
@export var village_y: int = 140
@export var wall_y: int = 200
@export var fg_y: int = 160
@export var moon_center: Vector2 = Vector2(96, 64)
@export var moon_radius: int = 28
## Linha da colina da vila (placeholder) e base do muro.
@export var horizon_y: int = 206
@export var wall_base_y: int = 262
## Vão do portão (x inicial, x final): as almas somem aqui.
@export var gate_span: Vector2 = Vector2(260, 290)
## Estrelas que cintilam (bg_a1_stars) só acima desta linha da tela.
@export var star_max_y: int = 170
@export var star_count: int = 40
## y das 3 nuvens finas (bg_a1_clouds, linhas 0–2).
@export var cloud_rows_y: Array[int] = [30, 78, 56]

@export_group("Vila")
## Canto sup. esq. de cada janela (MANIFEST title_windows, célula 2×3).
@export var window_points: Array[Vector2] = [
	Vector2(188, 166), Vector2(188, 178), Vector2(199, 185), Vector2(205, 185), Vector2(211, 185),
	Vector2(152, 200), Vector2(158, 200), Vector2(218, 203), Vector2(131, 208), Vector2(137, 208),
	Vector2(168, 209), Vector2(243, 211), Vector2(114, 219), Vector2(144, 219), Vector2(150, 219),
	Vector2(203, 217), Vector2(178, 223), Vector2(184, 223), Vector2(216, 225), Vector2(101, 228),
]
## Célula de title_windows se não vier JSON (2 frames: apagada, acesa).
@export var window_cell: Vector2i = Vector2i(2, 3)
@export var window_lit_chance: float = 0.7
## Intervalo entre trocas (uma janela por vez; com 20 janelas, cada uma muda a cada ~4–15 s).
@export var window_toggle_every: Vector2 = Vector2(0.25, 1.0)

@export_group("Fila das almas")
## Trilha (pés das almas, coordenadas da tela final), da porta da vila até o portão (276, 257).
## As almas ficam na profundidade da vila (parallax 0,5).
@export var soul_path: PackedVector2Array = PackedVector2Array([
	Vector2(204, 207), Vector2(230, 214), Vector2(252, 222), Vector2(240, 228),
	Vector2(258, 233), Vector2(272, 239), Vector2(276, 247), Vector2(276, 257),
])
@export var soul_every: float = 3.2
@export var soul_speed: float = 6.0

@export_group("Logo")
@export var logo_rect: Rect2 = Rect2(206, 0, 234, 114)
## Topo-esquerdo final da célula de cada uma das 12 letras (MANIFEST title_logo). Vazio = calculado.
@export var letter_positions: Array[Vector2] = [
	Vector2(244, 23), Vector2(271, 24), Vector2(290, 23), Vector2(323, 22), Vector2(350, 23), Vector2(369, 24),
	Vector2(216, 61), Vector2(251, 60), Vector2(286, 59), Vector2(321, 60), Vector2(356, 61), Vector2(391, 60),
]
## Célula de cada letra no atlas title_logo, se o atlas vier sem JSON. Vazio = usa o JSON.
@export var letter_cells: Array[Rect2] = []
## Índice da letra onde a pá crava (MANIFEST: o 2º G, célula 5, fim de "DIG DIG").
@export var shovel_letter: int = 5
## Topo-esquerdo final de title_logo_shovel; (−1, −1) = calculado sobre a letra.
@export var shovel_pos: Vector2 = Vector2(375, 4)
## Pivô da pá do logo (centro da lâmina na base do montinho): de onde saem os torrões.
@export var shovel_pivot: Vector2 = Vector2(9, 24)
## Pontas de gota (onde nasce title_logo_drip, pivô (1, 0)). Vazio = calculado (1 por letra).
@export var drip_points: Array[Vector2] = [
	Vector2(249, 36), Vector2(280, 37), Vector2(327, 36), Vector2(361, 40), Vector2(256, 78), Vector2(273, 78),
	Vector2(308, 74), Vector2(347, 78), Vector2(328, 73), Vector2(359, 74), Vector2(365, 79),
]
## Topo do subtítulo "Cava Cava Covas" (MANIFEST: texto em y ≈ 107, centrado em x = 320).
@export var subtitle_y: int = 104
## Altura de onde cada letra cai.
@export var letter_drop: float = 64.0

@export_group("Menu")
@export var menu_origin: Vector2 = Vector2(372, 168)
@export var menu_step: int = 28
@export var menu_width: int = 104
@export var menu_height: int = 24
## Fogo-fátuo: centro em relação ao canto superior esquerdo do botão em foco.
@export var wisp_offset: Vector2 = Vector2(-10, 11)

@export_group("Primeiro plano")
@export var ground_y: int = 334
@export var mound_rect: Rect2 = Rect2(40, 296, 112, 38)
## Base (pivô) do Coveiro sentado no topo plano do monte (coveiro_title, pivô (16, 31)).
@export var coveiro_seat: Vector2 = Vector2(96, 303)
## MANIFEST "Tela-título — personagens": posições relativas ao pivô do Coveiro.
@export var shovel_offset: Vector2 = Vector2(-12, 0)
@export var lantern_offset: Vector2 = Vector2(12, 0)
@export var halo_offset: Vector2 = Vector2(12, -5)
## Base do Tião (tiao, pivô (8, 15)) no topo da lápide.
@export var tiao_perch: Vector2 = Vector2(164, 312)
@export var tiao_stone: Rect2 = Rect2(156, 313, 19, 25)
## Copa do ipê (title_fg_canopy, 164×150, pingpong) e região de onde caem as pétalas.
@export var canopy_pos: Vector2 = Vector2(476, 96)
@export var ipe_canopy: Rect2 = Rect2(500, 120, 136, 110)
## Pétalas pousam no chão entre estes y.
@export var petal_land: Vector2 = Vector2(326, 350)
## Névoa entre o muro e o primeiro plano (MANIFEST: muro < névoa < title_fg).
@export var fog_y: Array[float] = [262.0, 286.0]
@export var factor_fog: float = 0.8
@export var fireflies: Rect2 = Rect2(16, 248, 608, 80)
@export var firefly_count: int = 9
## `stand` (MANIFEST): a pá e a lanterna somem a partir do 3º frame da tag; o halo sobe 2 px
## no 4º/último. Sem folha (placeholder), usa a fração do tempo da tag.
@export var stand_pick_frame: int = 3
@export var stand_halo_frame: int = 4
@export var stand_halo_rise: int = 2
@export var stand_pick_at: float = 0.5


## Escala do glifo placeholder da letra i (linha 1 = DIG DIG, linha 2 = GRAVES).
static func letter_scale(i: int) -> int:
	return LINE_SCALE[0] if i < 6 else LINE_SCALE[1]


## Tamanho da imagem placeholder da letra i (glifo + contorno + sombra).
static func letter_size(i: int) -> Vector2i:
	var s := letter_scale(i)
	return Vector2i(GLYPH.x * s + 3, GLYPH.y * s + 4)


func letter_pos(i: int) -> Vector2:
	if i < letter_positions.size():
		return letter_positions[i]
	return default_letter_positions()[i]


## Duas linhas centradas no logo: "DIG DIG" em cima, "GRAVES" embaixo.
func default_letter_positions() -> Array[Vector2]:
	var out: Array[Vector2] = []
	var cx := logo_rect.position.x + logo_rect.size.x * 0.5
	var w1 := letter_size(0).x
	var w2 := letter_size(6).x
	var line1 := 6 * w1 + WORD_GAP
	var line2 := 6 * w2
	var x := floorf(cx - line1 * 0.5)
	for i: int in 6:
		out.append(Vector2(x, logo_rect.position.y + 2))
		x += w1 + (WORD_GAP if i == 2 else 0)
	x = floorf(cx - line2 * 0.5)
	var y2 := logo_rect.position.y + 2 + letter_size(0).y + 4
	for i: int in 6:
		out.append(Vector2(x, y2))
		x += w2
	return out


func letter_rect(i: int) -> Rect2:
	var size := Vector2(letter_size(i))
	if i < letter_cells.size():
		size = letter_cells[i].size
	return Rect2(letter_pos(i), size)


## Topo-esquerdo final da pá do logo (tamanho da pá placeholder: 13×30, ponta em (4, 29)).
func shovel_final(shovel_size: Vector2) -> Vector2:
	if shovel_pos.x >= 0.0:
		return shovel_pos
	var r := letter_rect(clampi(shovel_letter, 0, LETTER_COUNT - 1))
	return (r.position + Vector2(r.size.x * 0.55, 9.0) - Vector2(4.0, shovel_size.y - 1.0)).round()


func drip_list() -> Array[Vector2]:
	if not drip_points.is_empty():
		return drip_points
	var out: Array[Vector2] = []
	for i: int in LETTER_COUNT:
		var r := letter_rect(i)
		out.append((r.position + Vector2(r.size.x * 0.5 + float((i * 7) % 5 - 2), 6.0)).round())
	return out


## Topo da camada: valor fixo ou base da imagem alinhada com a base da tela.
static func layer_top(y: int, texture_height: int) -> float:
	return float(360 - texture_height) if y == -1 else float(y)


func menu_button_pos(index: int) -> Vector2:
	return menu_origin + Vector2(0, index * menu_step)
