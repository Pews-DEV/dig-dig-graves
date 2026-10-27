"""Tileset da Area 2 · Campo dos Indigentes (DA §6, §7).

Atlas tiles_a2 (160x72, celula 32x24, pivo (16, 16)): colunas 0-3 com o MESMO significado da
Area 1 (S0 grama rala, S1 terra, S2 barro raso, S3 buraco) e coluna 4 = Lama (camada nova da A2,
entre a Terra e o Barro: GDD §4.3 "Area 2: Grama/Terra/Lama/Barro").
S2/S3 mantem a estrutura de buraco da Area 1 (DA §7) e partem dos proprios pixels de tiles_a1.
Covas (grave_a2 / grave_open_a2) sao desenhadas por um "raycast" de buraco iso: para cada pixel da
boca da vala o raio desce 1 px de profundidade por linha ate bater numa parede, no caixao ou no fundo."""
import random

from base import Canvas, DIAMOND, row_span, in_diamond, load, cell, LEG

# ---------------------------------------------------------------- utilitarios de desenho
EDGE = 2           # largura (px) da borda do losango em cada ponta de linha


def is_edge(x, y):
    s = row_span(y)
    return s is not None and (x - s[0] < EDGE or s[1] - x < EDGE)


def edge_kind(x, y):
    """'ul', 'ur', 'll', 'lr' para pixels de borda (y <= 16 = metade de cima)."""
    s = row_span(y)
    left = x - s[0] < EDGE
    if y <= 16:
        return 'ul' if left else 'ur'
    return 'll' if left else 'lr'


def base_tile(fill, edges):
    """losango cheio de 'fill' com as 4 bordas coloridas (edges: dict kind -> cor)."""
    c = Canvas(32, 24)
    for (x, y) in DIAMOND:
        v = fill
        if is_edge(x, y):
            v = edges.get(edge_kind(x, y), fill)
        c.set(x, y, v)
    return c


def interior_ok(x, y, margin=0):
    if not in_diamond(x, y) or is_edge(x, y) or y < 10 or y > 22:
        return False
    if margin:
        s = row_span(y)
        return x - s[0] >= EDGE + margin and s[1] - x >= EDGE + margin
    return True


def place(c, rnd, pats, n, used, region=None, tries=400, sep=1):
    """carimba n padroes (mapas de caracteres) em posicoes livres do miolo do losango."""
    placed = 0
    for _ in range(tries):
        if placed >= n:
            break
        rows = rnd.choice(pats)
        w, h = len(rows[0]), len(rows)
        x0, y0 = rnd.randrange(2, 30 - w + 1), rnd.randrange(10, 23 - h + 1)
        cells = [(x0 + i, y0 + j, LEG[ch]) for j, r in enumerate(rows) for i, ch in enumerate(r) if ch != '.']
        if not all(interior_ok(x, y) for (x, y, _) in cells):
            continue
        if region and not all(region(x, y) for (x, y, _) in cells):
            continue
        if any((x + a, y + b) in used for (x, y, _) in cells for a in range(-sep, sep + 1) for b in (-1, 0, 1)):
            continue
        for (x, y, v) in cells:
            c.set(x, y, v)
            used.add((x, y))
        placed += 1
    return placed


def tufts_top(c, rnd, n, stem=11, tip=12, used=None):
    """tufos finos (1 px de largura, 2-3 px de altura) saindo pela aresta de cima do losango,
    na folga superior (y >= 7). Cada tufo tem o pe colado na borda."""
    cand = []
    for x in range(3, 29):
        for y in range(9, 17):
            if in_diamond(x, y) and not in_diamond(x, y - 1):
                cand.append((x, y))
    rnd.shuffle(cand)
    done = 0
    xs = []
    for (x, y) in cand:
        if done >= n:
            break
        if any(abs(x - q) < 6 for q in xs):
            continue
        hgt = rnd.choice((2, 2, 3))
        if y - hgt < 7:
            continue
        for k in range(1, hgt + 1):
            c.set(x, y - k, stem if k < hgt else tip)
        c.set(x, y, stem)              # pe do tufo na borda
        lean = rnd.choice((-1, 1))
        if hgt == 3 and in_diamond(x + lean, y) and not in_diamond(x + lean, y - 1):
            c.set(x + lean, y - 1, stem)   # folhinha lateral (encosta no pe: sem pixel solto)
        xs.append(x)
        done += 1
    return done


# ---------------------------------------------------------------- S0 · grama rala
S0_DARK = [[".GG", "GG."], ["..GG", "GGG."], ["GG"]]
S0_LIGHT = [["HH"], [".H", "hH"]]
S0_BALD = [["Tu", "uu"], ["Tuu", ".uu"]]


def s0(v):
    rnd = random.Random(2100 + v * 17)
    c = base_tile(11, {'ul': 12, 'ur': 11, 'll': 10, 'lr': 9})
    # aresta de cima/dir. com falhas 10 (grama rala, lado sem luz)
    for (x, y) in DIAMOND:
        if is_edge(x, y) and edge_kind(x, y) == 'ur' and (x // 2 + v) % 3 == 0:
            c.set(x, y, 10)
    used = set()
    place(c, rnd, S0_BALD, 1 + (v == 2), used, sep=2)
    place(c, rnd, S0_DARK, 8, used, sep=2)
    place(c, rnd, S0_LIGHT, 3, used, region=lambda x, y: x + 2 * y < 58)
    tufts_top(c, rnd, 2 + (v == 1))
    return c


# ---------------------------------------------------------------- S1 · terra
S1_CLOD = [["bU", "TT"], ["UbU", ".TT"]]
S1_FURROW = [["UU", ".TT"], ["UUU", "TT."]]
S1_DAMP = [["TT"], ["tT"]]
S1_GRASS = [["hG"], ["Gh"]]


def s1(v):
    rnd = random.Random(2200 + v * 31)
    c = base_tile(15, {'ul': 16, 'ur': 15, 'll': 14, 'lr': 14})
    used = set()
    place(c, rnd, S1_CLOD, 2 + (v == 2), used, sep=2)
    place(c, rnd, S1_FURROW, 3, used)
    place(c, rnd, S1_DAMP, 3, used)
    # restos de grama rala so na borda (1-2 tufinhos 10/11 colados na aresta)
    spots = [(x, y) for (x, y) in DIAMOND if is_edge(x, y) and edge_kind(x, y) in ('ul', 'll', 'lr')
             and 11 <= y <= 21 and (x % 2 == (0 if x < 16 else 1))]
    rnd.shuffle(spots)
    k = 0
    for (x, y) in spots:
        if k >= 1 + (v != 1):
            break
        nb = x + (1 if x < 16 else -1)
        if not in_diamond(nb, y):
            continue
        c.set(x, y, 10)
        c.set(nb, y, 11)
        k += 1
    return c


# ---------------------------------------------------------------- Lama (coluna 4)
# poça de lama esverdeada (27) com margem de tras na sombra (13) e da frente pegando luar (15)
LAMA_POCA = [["tee.", ".eeu"], ["teee.", ".eeeu"], [".te.", "teeu"]]
LAMA_POCA_G = [["..eee...", ".eeeeeu.", "teeeeeu.", ".eeeuU.."],
               [".teee...", "eeeeeeu.", ".eeeeuU.", "...eu..."],
               ["...eee..", ".eeeeeu.", "teeeeuU.", ".eeu...."]]
LAMA_RIDGE = [["uu", "Tt"], ["uuu", ".Tt"], ["Uu", "uT"]]
LAMA_PRINT = [["tt"], ["t.t"]]


def basin(x, y, k):
    """True se o pixel cai na bacia rebaixada (losango interno de escala k, centrado no pivo)."""
    sx, sy = x + 0.5 - 16, y + 0.5 - 16
    return abs(sx) / 16 + abs(sy) / 8 <= k


def lama(v):
    """Lama: a terra amoleceu e afundou um pouco. Anel de terra 15 (como o S1) em volta de uma
    bacia rasa de lama 14, com a margem de tras na sombra (13) e sem o labio 17 dos buracos de
    verdade (S2/S3). Dentro: pocas esverdeadas 27, cristas 15/13 e marcas de bota 13."""
    rnd = random.Random(2400 + v * 13)
    c = base_tile(15, {'ul': 16, 'ur': 15, 'll': 14, 'lr': 14})
    k = 0.70
    for (x, y) in DIAMOND:
        if basin(x, y, k):
            v_ = 14
            if not basin(x, y - 1, k):
                v_ = 13                      # margem de tras na sombra (concavidade, DA §7)
                if x >= 16:
                    v_ = 15                  # ... e a de tras/dir. pegando luar (15)
            elif not basin(x - 1, y, k) and y <= 16:
                v_ = 13
            c.set(x, y, v_)
    inner = lambda x, y: basin(x, y, k - 0.14) and basin(x, y - 1, k - 0.14)
    center = lambda x, y: basin(x, y, 0.56)
    used = set()
    pg = LAMA_POCA_G[v]
    ox, oy = 12 + (v == 1) * 2 - (v == 2), 14 + (v == 2)
    for j, r in enumerate(pg):
        for i, ch in enumerate(r):
            if ch != '.':
                c.set(ox + i, oy + j, LEG[ch])
                used.add((ox + i, oy + j))
    place(c, rnd, LAMA_POCA, 1, used, region=inner, sep=2)
    place(c, rnd, LAMA_RIDGE, 3, used, region=center)
    place(c, rnd, LAMA_RIDGE, 1, used, region=inner)
    place(c, rnd, LAMA_PRINT, 1 + (v != 2), used, region=inner)
    # terra respingada no anel (1 crista curta fora da bacia, do lado iluminado)
    place(c, rnd, [["Uu"]], 1, used, region=lambda x, y: not basin(x, y, k + 0.06) and y <= 15)
    return c


# ---------------------------------------------------------------- S2 / S3 (estrutura da Area 1)
def s2(v):
    """buraco raso da Area 1 + uma pocinha de lama 27 no fundo (perto da frente)."""
    c = cell(load('assets/tiles/a1/tiles_a1.png'), 2, v)
    spot = [(18, 19), (19, 19)] if v == 0 else [(13, 18), (14, 18)]
    for (x, y) in spot:
        assert c.get(x, y) in (13, 14), (v, x, y, c.get(x, y))
        c.set(x, y, 27)
    return c


def s3(v):
    """buraco fundo da Area 1 + 1 escorrido de lama 27 na parede iluminada (tras-direita)."""
    c = cell(load('assets/tiles/a1/tiles_a1.png'), 3, v)
    for (x, y) in ((21, 12), (21, 13)):
        assert c.get(x, y) == 15, (x, y, c.get(x, y))
        c.set(x, y, 27)
    return c


def tiles_atlas():
    """dict (col, row) -> Canvas."""
    t = {}
    for v in range(3):
        t[(0, v)] = s0(v)
        t[(1, v)] = s1(v)
        t[(4, v)] = lama(v)
    for v in range(2):
        t[(2, v)] = s2(v)
        t[(3, v)] = s3(v)
    t[(2, 2)] = None
    t[(3, 2)] = None
    return t


# ---------------------------------------------------------------- rachaduras (dano parcial)
def cracks_atlas():
    """32x40, celula 16x8. Coluna = nivel (0: HP < 66%, 1: HP < 33%). Linha = COLUNA do tile no
    atlas: 0 S0 grama (09 + 12), 1 S1 terra (13 + 16), 2 S2 barro (01 + 15), 3 vazia (S3 nao racha),
    4 Lama (01 + 15: 13 some sobre 14, como no Barro). Formas iguais as de cracks_a1."""
    a1 = load('assets/tiles/a1/cracks_a1.png')
    a = Canvas(32, 40)
    a.blit(a1, 0, 0)
    a.blit(a1.crop(0, 16, 32, 8), 0, 32)
    return a


# ---------------------------------------------------------------- regeneracao (4 frames)
def regen_frames():
    """0-1: terra fechando (iguais aos da A1: a terra e a mesma); 2: grama rala fechando sobre o
    remendo de terra; 3: igual ao S0 v1 da A2 (sem salto ao trocar para o tile)."""
    a1 = load('assets/tiles/a1/regen_a1.png')
    f0, f1, f2 = (a1.crop(i * 32, 0, 32, 24) for i in range(3))
    g = s0(0)
    # remendo de terra do frame 2 da A1 sobre a grama rala
    for (x, y) in DIAMOND:
        v = f2.get(x, y)
        if v and 13 <= v <= 17 and not is_edge(x, y):
            g.set(x, y, v)
    return [f0, f1, g, s0(0)]
