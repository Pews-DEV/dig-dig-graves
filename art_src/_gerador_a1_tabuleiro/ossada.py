"""Camada Ossada do estagio 1 (GDD §4.3: sempre a ultima camada, depois do Barro).

Leitura de profundidade (DA §1.1, §7): a Ossada e mais funda que o Barro (S2) e ainda nao e o
Buraco vazio (S3). Por isso parte da ESTRUTURA do S3 (boca, paredes, labio 17, sem tocar nas
paredes) e troca so o fundo: em vez do fundo vazio 13/01, um chao de terra socada "tipo S1"
(a textura do S1 descida 2 degraus na rampa da Terra: 15->13, 16->14, 17->15) cheio de
ossinhos de desenho 21/22 (<= 15% do losango) e com rachaduras 01.
Valor do miolo fica entre o do Barro (~51) e o do Buraco (~30)."""
import random

from base1 import Canvas, load, cell, DIAMOND, in_diamond, LUMA

A1 = 'assets/tiles/a1/tiles_a1.png'
SHIFT2 = {15: 13, 16: 14, 17: 15, 14: 13, 13: 13, 10: 13, 11: 13, 12: 14}

# ossinhos de desenho (pontas em bolinha, DA §1.1): O = 22 (luz), o = 21 (sombra), K = 01 (sombra
# de contato embaixo/direita, deixa o osso "pousado" no chao)
BONES = [
    # osso deitado: pontas em bolinha (o "osso de cachorro" de desenho)
    ["O...O",
     ".OOO.",
     "O...o"],
    # osso em pe
    ["O.O",
     ".O.",
     ".O.",
     "o.o"],
    # osso na diagonal (desce para a direita)
    ["OO...",
     "OOo..",
     "..oOo",
     "...oo"],
    # cranio de desenho, fofo (orbitas grandes 01), meio enterrado: so a calota e os olhos
    [".OOO.",
     "OKOKo",
     ".ooo."],
    # ossinho curto
    ["O..O",
     ".OO.",
     "o..o"],
]


def floor_mask(s3):
    return {(x, y) for (x, y) in DIAMOND if s3.px[y][x] in (13, 1)}


def ossada(v):
    a1 = load(A1)
    s3 = cell(a1, 3, v % 2)
    s1 = cell(a1, 1, v)
    c = Canvas(32, 24)
    for y in range(24):
        c.px[y] = list(s3.px[y])
    fl = floor_mask(s3)
    for (x, y) in fl:
        c.set(x, y, SHIFT2.get(s1.px[y][x], 13))
    # ossos sorteados (semente fixa por variante) so onde cabem inteiros no fundo, sem encostar uns
    # nos outros, e com no maximo CENTER_BUDGET px no miolo do tile (losango interno de meia escala):
    # assim o valor do centro fica entre o do Barro e o do Buraco (DA §7, brief do ART-A1)
    rnd = random.Random(4100 + 37 * v)
    budget = CENTER_BUDGET
    used = set()
    for k in PLANS[v]:
        pat = BONES[k]
        w, h = len(pat[0]), len(pat)
        for _ in range(4000):
            x0, y0 = rnd.randrange(3, 30 - w), rnd.randrange(12, 24 - h)
            pts = [(x0 + i, y0 + j, ch) for j, r in enumerate(pat) for i, ch in enumerate(r) if ch != '.']
            if not all((x, y) in fl for (x, y, _) in pts):
                continue
            mine = {(x, y) for (x, y, _) in pts}
            # a sombra de contato (1 px abaixo) tambem precisa cair no fundo
            if any((x, max(py for (px, py) in mine if px == x) + 1) not in fl for x in {p[0] for p in mine}):
                continue
            if any((x + a, y + b) in used for (x, y) in mine for a in (-1, 0, 1) for b in (-1, 0, 1, 2)):
                continue
            inc = sum(1 for (x, y) in mine if center(x, y))
            if inc > budget:
                continue
            budget -= inc
            for (x, y, ch) in pts:
                c.set(x, y, {'O': 22, 'o': 21, 'K': 1}[ch])
            for x in {p[0] for p in mine}:
                y = max(py for (px, py) in mine if px == x) + 1
                c.set(x, y, 1)
                used.add((x, y))
            used |= mine
            break
    # ponta de osso 21 saindo da parede da esquerda (enterrado na terra 14)
    for (x, y) in WALL_BONE[v]:
        assert s3.px[y][x] == 14, (v, x, y, s3.px[y][x])
        c.set(x, y, 21)
    # rachaduras 01 em zigue-zague (degraus de 2) no chao, longe dos ossos
    for _ in range(2):
        for _t in range(2000):
            x0, y0, d = rnd.randrange(6, 26), rnd.randrange(13, 22), rnd.choice((-1, 1))
            pts = [(x0, y0), (x0 + d, y0), (x0 + 2 * d, y0 + 1), (x0 + 3 * d, y0 + 1)]
            if all((x, y) in fl for (x, y) in pts) and not any(
                    (x + a, y + b) in used for (x, y) in pts for a in (-1, 0, 1) for b in (-1, 0, 1)):
                for (x, y) in pts:
                    c.set(x, y, 1)
                    used.add((x, y))
                break
    return c


def center(x, y):
    """miolo do tile: losango interno de meia escala (a mesma medida do teste de valor)."""
    return abs(x + 0.5 - 16) / 16 + abs(y + 0.5 - 16) / 8 <= 0.5


CENTER_BUDGET = 3
PLANS = [[3, 0, 2, 4, 1, 4, 0], [2, 3, 0, 4, 1, 0, 4], [0, 3, 4, 2, 1, 4, 0]]


def bone_share(c):
    return sum(1 for (x, y) in DIAMOND if c.px[y][x] in (21, 22)) / 256.0


# ponta de osso 21 saindo da parede da esquerda (terra 14), por variante
WALL_BONE = [[(4, 16), (5, 16)], [(8, 14), (9, 14)], [(6, 15), (7, 15)]]
