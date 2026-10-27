"""Pecas do diorama e props da Area 2 · Campo dos Indigentes.

bloco_a2   faces do bloco de terra com os estratos da A2 (grama rala, terra, LAMA 14/27, barro)
cerca_a2   cerca de madeira quebrada (mesmas celulas/pivo de cerca_a1)
tufos_a2   tufos de grama rala com folhas secas (mesmo layout de tufos_a1)
placa_a2   placa de madeira gasta: "INDIGENTES" / em branco (mesmo layout de placa_a1)
cruz       cruz de madeira sem nome 12x20, pivo (6, 19) (DA §5) e lapide_a2 (16x24, pivo (8, 23))
poca_lama  poca de lama 32x24 com o pivo do tile (16, 16)"""
import math
import random

from base import Canvas, DIAMOND, row_span, in_diamond, load, cell, LEG
import tiles_a2 as T

# ====================================================================== bloco do diorama
FACE_H = 24
BLOCK_CELL = (32, 56)


def _y_last_left(x):
    return 16 + x // 2


def _y_last_right(x):
    return 16 + (31 - x) // 2


def _wob(x, amp, ph):
    return int(round(amp * math.sin((x + ph) * 2 * math.pi / 16)))


def face(side, variant, end=False, corner_edge=False):
    """como cena.face (A1), com a faixa de LAMA entre a terra e o barro."""
    c = Canvas(*BLOCK_CELL)
    rnd = random.Random(300 + variant * 7 + (0 if side == 'L' else 50))
    if side == 'L':
        cols = range(0, 16)
        ylast = _y_last_left
        pal = dict(g0=11, g1=10, terra=15, terra_hi=16, terra_lo=14, lama=14, lama_lo=13,
                   barro=14, barro_lo=13, fundo=13, peb=6, peb_lo=5)
    else:
        cols = range(16, 32)
        ylast = _y_last_right
        pal = dict(g0=10, g1=9, terra=14, terra_hi=15, terra_lo=13, lama=13, lama_lo=1,
                   barro=13, barro_lo=13, fundo=13, peb=5, peb_lo=4)
    for x in cols:
        y0 = ylast(x) + 1
        xl = x % 16
        b_grass = 2 + (1 if _wob(xl, 1, 5) > 0 else 0)       # grama rala: 2-3 px
        b_terra = 7 + _wob(xl, 1, 11)
        b_lama = 13 + _wob(xl, 1, 3)
        b_barro = 19 + _wob(xl, 1, 1)
        for t in range(FACE_H):
            y = y0 + t
            if t == FACE_H - 1:
                v = 1
            elif t == 0:
                v = pal['g0']
            elif t < b_grass:
                v = pal['g1']
            elif t < b_terra:
                v = pal['terra']
                if t == b_grass:
                    v = pal['terra_lo']
            elif t < b_lama:
                v = pal['lama']
                if t == b_lama - 1:
                    v = pal['lama_lo']                     # lama escorre por cima do barro
            elif t < b_barro:
                v = pal['barro']
            else:
                v = pal['fundo']
                if t >= FACE_H - 3 and side == 'R':
                    v = 1 if (x + y) % 2 == 0 else pal['fundo']
            c.set(x, y, v)
    # manchas de lama esverdeada 27 dentro da faixa (2 px deitados), pingos 13/01 abaixo
    for i in range(2):
        for _ in range(40):
            x = rnd.choice(list(cols)[1:-2])
            t = rnd.randrange(8, 12)
            y = ylast(x) + 1 + t
            if c.get(x, y) == pal['lama'] and c.get(x + 1, y) == pal['lama']:
                c.set(x, y, 27)
                c.set(x + 1, y, 27)
                break
    for i in range(2):
        x = rnd.choice(list(cols)[1:-1])
        yb = ylast(x) + 1 + 13 + _wob(x % 16, 1, 3)
        if c.get(x, yb) == pal['barro']:
            c.set(x, yb, pal['lama_lo'])                 # escorrido de lama de 1 px sobre o barro
    # falhas da grama rala: 1-2 colunas onde a terra aparece logo abaixo da borda
    for i in range(2):
        x = rnd.choice(list(cols)[2:-2])
        y = ylast(x) + 2
        if c.get(x, y) == pal['g1']:
            c.set(x, y, pal['terra'])
    # pedrinhas no barro/fundo
    placed = tries = 0
    while placed < 3 and tries < 60:
        tries += 1
        x = rnd.choice(list(cols)[1:-2])
        t = rnd.randrange(14, FACE_H - 3)
        y = ylast(x) + 1 + t
        wv = 2 if rnd.random() < 0.6 else 1
        if all(c.get(x + k, y) in (pal['barro'], pal['fundo']) for k in range(wv)):
            for k in range(wv):
                c.set(x + k, y, pal['peb'])
                c.set(x + k, y + 1, pal['peb_lo'] if c.get(x + k, y + 1) not in (0, 1) else 1)
            placed += 1
    if side == 'L':
        for i in range(3):
            x = rnd.choice(list(cols))
            t = rnd.randrange(3, 6)
            y = ylast(x) + 1 + t
            if c.get(x, y) == pal['terra']:
                c.set(x, y, pal['terra_hi'])
    if end:
        x = 0 if side == 'L' else 31
        for y in range(ylast(x) + 1, ylast(x) + FACE_H + 1):
            if c.get(x, y):
                c.set(x, y, 1)
    if corner_edge and side == 'L':
        x = 15
        for t in range(1, FACE_H - 1):
            y = ylast(x) + 1 + t
            v = c.get(x, y)
            up = {15: 16, 14: 15, 13: 14, 10: 11, 27: 27}.get(v)
            if up:
                c.set(x, y, up)
    sh = 2 if side == 'L' else 4
    for x in cols:
        yb = ylast(x) + FACE_H
        for k in range(1, sh + 1):
            if side == 'R' and k >= 3 and (x + yb + k) % 2:
                continue
            c.set(x, yb + k, 1)
    return c


def block_atlas():
    a = Canvas(32 * 9, 56)
    cells = [face('L', v) for v in range(3)] + [face('L', 3, end=True)]
    cells += [face('R', v) for v in range(3)] + [face('R', 3, end=True)]
    q = face('L', 4, corner_edge=True)
    q.blit(face('R', 4), 0, 0)
    cells.append(q)
    for i, cc in enumerate(cells):
        a.blit(cc, i * 32, 0)
    return a, cells


# ====================================================================== cerca de madeira quebrada
def _base_no(x):
    return 23 - x // 2


def _base_ne(x):
    return 23 - (31 - x) // 2


def fence(kind):
    """cerca de estacas e 2 ripas, quebrada. kind 'NO' (x 0-15) ou 'NE' (x 16-31).
    Madeira 18 (corpo), 19 (lado/topo do luar), sombra 01/02; luma <= 65 (decoracao)."""
    c = Canvas(32, 32)
    if kind == 'NO':
        cols, base = range(0, 16), _base_no
        posts = [(1, 10, 'ok'), (7, 9, 'ok'), (12, 6, 'broken')]
        rail_gap = (9, 12)        # ripa de cima quebrada entre x 9 e 11
    else:
        cols, base = range(16, 32), _base_ne
        posts = [(18, 10, 'lean'), (24, 9, 'ok'), (29, 6, 'broken')]
        rail_gap = (20, 23)
    # ripas (atras das estacas): de cima 2 px (19 luar / 18), de baixo 1 px (18)
    for x in cols:
        b = base(x)
        if not (rail_gap[0] <= x < rail_gap[1]):
            c.set(x, b - 7, 19)
            c.set(x, b - 6, 18)
        c.set(x, b - 3, 19)
        c.set(x, b - 2, 18)
    # pedaco da ripa quebrada pendurado (cai em diagonal mais inclinada)
    gx = rail_gap[0]
    for k in range(3):
        c.set(gx + k, base(gx) - 6 + k, 18 if k else 19)
    # estacas: 2 px (19 lado do luar / 18), topo cortado em ponta, pe com sombra 01
    for (x, h, st) in posts:
        b = base(x)
        if st == 'lean':
            # estaca torta: o topo anda 1 px para a esquerda (1 degrau limpo)
            for y in range(b - h, b + 1):
                dx = -1 if y < b - h // 2 else 0
                c.set(x + dx, y, 19)
                c.set(x + 1 + dx, y, 18)
            c.set(x - 1, b - h - 1, 19)
        else:
            for y in range(b - h, b + 1):
                c.set(x, y, 19)
                c.set(x + 1, y, 18)
            if st == 'broken':
                c.set(x + 1, b - h, 0)                  # topo lascado
                c.set(x, b - h - 1, 0)
            else:
                c.set(x, b - h - 1, 19)                 # ponta
        c.set(x + 2, b, 1)                              # sombra de contato (SE)
    return c


def fence_post():
    """poste de quina de madeira 6x14 (pivo (3, 13) = base): mourao 3 px com topo chanfrado."""
    rows = ["..C...",
            ".Crc..",
            ".Crcc.",
            ".Crcc.",
            ".Crcc.",
            ".Crcc.",
            ".CrcK.",
            ".Crcc.",
            ".Crcc.",
            ".Crcc.",
            ".CrcK.",
            ".Crcc.",
            ".Crcc.",
            ".KKKKK"]
    c = Canvas(6, 14)
    c.rows(0, 0, rows)
    return c


def fence_atlas():
    a = Canvas(96, 32)
    a.blit(fence('NO'), 0, 0)
    a.blit(fence('NE'), 32, 0)
    a.blit(fence_post(), 64 + 13, 18)
    return a


# ====================================================================== tufos de grama rala
TUFT_ROWS = [
    (["............",
      "............",
      "...h......c.",
      "...Gh..h..c.",
      "..hG...G.Gc.",
      "..GG.hGG.G..",
      ".gGGGGGGGGg.",
      "..gggggggg.."],
     ["............",
      "............",
      "....h.....c.",
      "...hG..h.c..",
      "..hG...Gh...",
      "..GG.GhG.G..",
      ".gGGGGGGGGg.",
      "..gggggggg.."]),
    (["............",
      "....c.......",
      "....c...h...",
      "...c..h.G...",
      "...c..G.G...",
      "..GGh.GhG...",
      "..gGGGGGGg..",
      "...gggggg..."],
     ["............",
      "...c........",
      "...c.....h..",
      "...c...h.G..",
      "...c..G.G...",
      "..GGh.GhG...",
      "..gGGGGGGg..",
      "...gggggg..."]),
    (["............",
      "............",
      "............",
      "..h......h..",
      "..G.h..c.G..",
      ".hG.G.c.hG..",
      ".gGGGGGGGGg.",
      "..gggggggg.."],
     ["............",
      "............",
      "............",
      "...h.....h..",
      "...G.h..cG..",
      ".hG.G..c.Gh.",
      ".gGGGGGGGGg.",
      "..gggggggg.."]),
]


def tufts():
    a = Canvas(24, 24)
    for r, (f0, f1) in enumerate(TUFT_ROWS):
        a.rows(0, r * 8, f0)
        a.rows(12, r * 8, f1)
    return a


# ====================================================================== placa
# fonte estreita 7 px de altura so para a placa (entalhada em 18)
NARROW = {
    'I': ["1", "1", "1", "1", "1", "1", "1"],
    'N': ["1001", "1101", "1101", "1011", "1011", "1001", "1001"],
    'D': ["1110", "1001", "1001", "1001", "1001", "1001", "1110"],
    'G': ["0111", "1000", "1000", "1011", "1001", "1001", "0111"],
    'E': ["111", "100", "100", "110", "100", "100", "111"],
    'T': ["111", "010", "010", "010", "010", "010", "010"],
    'S': ["0111", "1000", "1000", "0110", "0001", "0001", "1110"],
}


def text_width(s):
    return sum(len(NARROW[ch][0]) for ch in s) + len(s) - 1


def sign_blank():
    """parte da placa_a1 em branco: mesma silhueta/area util; madeira gasta (lasca no canto de
    cima/dir., racha 18 no meio, 1 prego caiu)."""
    c = cell(load('assets/sprites/bg/a1/placa_a1.png'), 1, 0, 56, 26)
    # lasca no canto de cima/dir. (degrau 2-2-2 limpo, contorno refeito em 01)
    for (x, y) in ((52, 2), (53, 2), (51, 2), (52, 3), (53, 3), (54, 3)):
        c.set(x, y, 0)
    for (x, y) in ((49, 2), (50, 2), (51, 3), (52, 4), (53, 4), (54, 4)):
        c.set(x, y, 1)
    for (x, y) in ((50, 3), (51, 4)):
        c.set(x, y, 20)
    # prego da direita caiu: furo 18
    for y in range(3, 16):
        for x in range(2, 54):
            if c.get(x, y) == 5 and x > 40:
                c.set(x, y, 18)
    # racha vertical curta a partir da borda de baixo
    for (x, y) in ((40, 14), (40, 13), (41, 12), (41, 11)):
        if c.get(x, y) in (19, 20):
            c.set(x, y, 18)
    return c


def sign_with_text(text='INDIGENTES'):
    c = sign_blank()
    # tira o veio da madeira de baixo do letreiro (area util da placa)
    for y in range(5, 14):
        for x in range(4, 52):
            if c.get(x, y) == 18:
                c.set(x, y, 19)
    w = text_width(text)
    x = 28 - w // 2
    y = 6
    for ch in text:
        g = NARROW[ch]
        for j, row in enumerate(g):
            for i, b in enumerate(row):
                if b == '1':
                    c.set(x + i, y + j, 18)
        x += len(g[0]) + 1
    return c


def sign_atlas():
    a = Canvas(112, 26)
    a.blit(sign_with_text(), 0, 0)
    a.blit(sign_blank(), 56, 0)
    return a


# ====================================================================== cruz de madeira sem nome
# 12x20, pivo (6, 19). Madeira 18/19 (DA §6), luz 20 so na aresta NO, contorno seletivo 01,
# montinho de terra 14/15 na base e sombra projetada 02 para baixo/dir. (como a lapide).
CRUZ = [
    # 0: reta, ripa simples pregada
    ["............",
     ".....KK.....",
     "....KrcK....",
     "....KrcK....",
     ".KKKKrcKKKK.",
     "KrrrrrrrrrcK",
     "KCCCCCCCCCcK",
     ".KKKKrcKKKK.",
     "....KrcK....",
     "....KrcK....",
     "....KrcK....",
     "....KrcK....",
     "....KCcK....",
     "....KCcK....",
     "....KCcK....",
     "....KCcK....",
     "...KuCcTK...",
     "..KuUuuTTK..",
     "..KKKKKKKKNN",
     "....NNNNNNN."],
    # 1: torta para a esquerda (o topo anda 1 px), travessa mais curta
    ["............",
     "....KK......",
     "...KrcK.....",
     "...KrcK.....",
     ".KKKrcKKK...",
     "KrrrrrrrcK..",
     "KCCCCCCCcK..",
     ".KKKrcKKK...",
     "...KrcK.....",
     "...KrcK.....",
     "....KrcK....",
     "....KrcK....",
     "....KCcK....",
     "....KCcK....",
     "....KCcK....",
     "....KCcK....",
     "...KuCcTK...",
     "..KuUuuTTK..",
     "..KKKKKKKKNN",
     "....NNNNNNN."],
    # 2: braco direito quebrado e plaquinha de lata sem nada escrito (06/04)
    ["............",
     ".....KK.....",
     "....KrcK....",
     "....KrcK....",
     ".KKKKrcKK...",
     "KrrrrrrrcK..",
     "KCCCCCCCcK..",
     ".KKKKrcKK...",
     "...KKKKKK...",
     "...KSSSVK...",
     "...KSVVVK...",
     "...KKKKKK...",
     "....KCcK....",
     "....KCcK....",
     "....KCcK....",
     "....KCcK....",
     "...KuCcTK...",
     "..KuUuuTTK..",
     "..KKKKKKKKNN",
     "....NNNNNNN."],
]


def cross(v):
    c = Canvas(12, 20)
    c.rows(0, 0, CRUZ[v])
    return c


def cross_atlas():
    a = Canvas(36, 20)
    for v in range(3):
        a.blit(cross(v), v * 12, 0)
    return a


def lapide_compat():
    """as 3 cruzes em celulas 16x24 com pivo (8, 23), no layout de lapide.png (para trocar so o caminho)."""
    a = Canvas(48, 24)
    for v in range(3):
        a.blit(cross(v), v * 16 + 2, 4)
    return a


# ====================================================================== poca de lama
def puddle(v):
    """tile inteiro (32x24, pivo (16, 16)): grama rala na borda e uma poca de lama no meio.
    Concava (DA §7): margem de tras na sombra (13), margem da frente pegando luar (15/16);
    agua de lama 14 com miolo esverdeado 27 (<= 15% do tile)."""
    c = T.s0(v)
    rnd = random.Random(2600 + v)
    # limpa os tufos do miolo: so o anel externo continua grama
    cx, cy = (16, 16) if v == 0 else (14, 16)
    ru, rv = (0.36, 0.30) if v == 0 else (0.30, 0.34)

    def uv(x, y):
        sx, sy = x + 0.5 - cx, y + 0.5 - cy
        return sx / 32 + sy / 16, sy / 16 - sx / 32

    inside = {}
    for (x, y) in DIAMOND:
        u, w = uv(x, y)
        q = (u / ru) ** 2 + (w / rv) ** 2 + 0.08 * math.sin(3 * math.atan2(w, u) + v)
        inside[(x, y)] = q
    for (x, y), q in inside.items():
        if q > 1.0:
            continue
        val = 14
        if q < 0.42:
            val = 27
        # margem: pixel de tras (de cima) fora da poca -> sombra 13; da frente -> 15
        if inside.get((x, y - 1), 9) > 1.0:
            val = 13
        elif inside.get((x, y + 1), 9) > 1.0:
            val = 15
        c.set(x, y, val)
    # lama respingada na grama em volta (pares 14 colados a margem, sem pixel solto)
    for (x, y), q in sorted(inside.items()):
        if 1.0 < q < 1.25 and c.get(x, y) in (11, 10) and rnd.random() < 0.18:
            nb = (x + 1, y)
            if inside.get(nb, 9) > 1.0 and c.get(*nb) in (11, 10) and not T.is_edge(*nb):
                c.set(x, y, 14)
                c.set(*nb, 14)
    # brilho do luar na lama (2 px 16 na margem da frente/dir.)
    front = [(x, y) for (x, y), q in inside.items() if q <= 1.0 and c.get(x, y) == 15]
    front.sort(key=lambda p: -(p[0] + 2 * p[1]))
    if front:
        x, y = front[len(front) // 3]
        c.set(x, y, 16)
    return c


def puddle_atlas():
    a = Canvas(64, 24)
    for v in range(2):
        a.blit(puddle(v), v * 32, 0)
    return a
