"""Arvore v2 (ART-A2, DA §13.4 / UI-UX §18.1): molduras por tipo de no, Raizes-mestras 40x40,
selado, raiz em "Y" e fundos largos (mundo 1936 x 1024).

Rodar desta pasta:  py -B tree3.py
(precisa do Pillow; grava PNG em assets/ui/tree, .aseprite em art_src/ui e previas em art_src/_previews)
"""
import math
import os
import random
from common import Canvas, PAL, LEG
from tree2 import (ROOT, OUT, PREV, BAYER, N4, DIST, in_body, BRANCHES, build_medallions32,
                   frame_roots, wave)
import tree as T1
import icons as IC
from ase_writer import write_ase, read_ase

J = os.path.join
SRC = J(ROOT, 'art_src', 'ui')
WORLD_W, WORLD_H = 1936, 1024
SURF = 176                       # linha da grama no mundo v2
N00_X = 968


def lum(i):
    r, g, b = PAL[i - 1]
    return 0.299 * r + 0.587 * g + 0.114 * b


def from_rows(rows, w=None, h=None):
    c = Canvas(w or len(rows[0]), h or len(rows))
    c.rows(0, 0, rows)
    return c


def outline_ext(c, col=1, diag=False):
    """contorno nos pixels transparentes vizinhos ao desenho."""
    nb = list(N4) + ([(1, 1), (1, -1), (-1, 1), (-1, -1)] if diag else [])
    add = []
    for y in range(c.h):
        for x in range(c.w):
            if c.px[y][x]:
                continue
            if any(c.get(x + dx, y + dy) not in (None, 0) for dx, dy in nb):
                add.append((x, y))
    for x, y in add:
        c.set(x, y, col)


# ======================================================== frame_at / r / d (32x32)
# sobreposicoes: so tocam o aro e o lado de fora; o quadrado do icone (8..23) fica livre.
ICON_BOX = (8, 8, 23, 23)


def frame_at():
    """4 raios de luz 26 nas diagonais, saindo do aro para os cantos (efeito, sem contorno)."""
    c = Canvas(32, 32)
    left, right = frame_roots()
    roots = set(left + right)
    blocked = {(x, y) for y in range(32) for x in range(32) if in_body(x, y)} | roots
    # vizinhos do contorno das raizes tambem ficam ocupados pelo contorno 01 delas
    blocked |= {(x + dx, y + dy) for x, y in roots for dx, dy in N4}
    for sx, sy, ddx, ddy in ((0, 0, 1, 1), (31, 0, -1, 1), (0, 31, 1, -1), (31, 31, -1, -1)):
        # anda do canto para o centro ate encostar no medalhao
        path = []
        x, y = sx, sy
        while (x, y) not in blocked:
            path.append((x, y))
            x, y = x + ddx, y + ddy
        ray = path[-4:]          # os 4 px colados no medalhao
        cols = [25, 26, 26, 23]  # ponta -> base (mais forte junto ao aro)
        for (px, py), col in zip(ray, cols[-len(ray):]):
            c.set(px, py, col)
        # raio com 2 px de corpo perto da base (degrau 1-1, sem "dentes")
        # cada pixel do raio ganha o vizinho horizontal rumo ao aro: escada 4-conexa (degrau 1-1)
        for (px, py), col in zip(ray[:-1], cols[-len(ray):-1]):
            q = (px + ddx, py)
            if q not in blocked:
                c.set(q[0], q[1], col)
        bx, by = ray[-1]
        c.set(bx - ddx, by, 26 if (bx - ddx, by) not in blocked else c.get(bx - ddx, by))
        c.set(bx, by - ddy, 26 if (bx, by - ddy) not in blocked else c.get(bx, by - ddy))
        # brilho na face do aro, na mesma diagonal
        gx, gy = x, y
        while DIST.get((gx, gy), 99) < 2:
            gx, gy = gx + ddx, gy + ddy
        c.set(gx, gy, 23)
    return c


RUNE = [(15, 3), (15, 26), (3, 15), (26, 15), (5, 5), (25, 5), (5, 25), (25, 25)]


def frame_r():
    """aro runico: 8 pontos 28 (2x2, sombra 27 no canto SE) com contorno 01, nas 8 direcoes."""
    c = Canvas(32, 32)
    for x0, y0 in RUNE:
        dots = [(x0, y0), (x0 + 1, y0), (x0, y0 + 1), (x0 + 1, y0 + 1)]
        for x, y in dots:
            for dx, dy in N4:
                c.set(x + dx, y + dy, 1)
        for x, y in dots:
            c.set(x, y, 28)
        c.set(x0 + 1, y0 + 1, 27)
    for x in range(ICON_BOX[0], ICON_BOX[2] + 1):
        for y in range(ICON_BOX[1], ICON_BOX[3] + 1):
            assert c.get(x, y) == 0, 'frame_r cobre o icone'
    return c


PADLOCK = [  # 8x8, cadeado ABERTO (alca solta a direita), ferro 06/07/08, buraco 01
    ".KKKK...",
    "KPMMMK..",
    "KPKKKK..",
    "KPK.....",
    "KPKKKKKK",
    "KPPMMMSK",
    "KMMKMMSK",
    "KKKKKKKK",
]


def frame_d():
    c = Canvas(32, 32)
    c.rows(12, 0, PADLOCK)
    return c


# ============================================================== frame_sealed (32x32)
XMARK = [
    "KK....KK",
    "KKK..KKK",
    ".KKKKKK.",
    "..KKKK..",
    "..KKKK..",
    ".KKKKKK.",
    "KKK..KKK",
    "KK....KK",
]


def frame_sealed():
    from tree2 import medallion32
    c = medallion32(6, 7, 5, 'normal', root_cols=(19, 18, 18))
    # face de pedra no lugar do miolo: 06 com borda iluminada 07 em cima/esquerda
    for y in range(8, 24):
        for x in range(8, 24):
            c.set(x, y, 6 if (x == 8 or y == 8) else 5)
    # rachadura na pedra do aro (lado escuro, SE)
    for x, y in ((24, 20), (25, 21), (25, 22), (26, 23), (27, 23)):
        c.set(x, y, 4)
    # "x" de 8x8 gravado: sulco 01 com o labio claro 08 embaixo/direita
    pts = [(12 + i, 12 + j) for j, r in enumerate(XMARK) for i, ch in enumerate(r) if ch == 'K']
    s = set(pts)
    for x, y in pts:
        for dx, dy in ((1, 0), (0, 1)):
            q = (x + dx, y + dy)
            if q not in s and 8 <= q[0] <= 23 and 8 <= q[1] <= 23:
                c.set(q[0], q[1], 7)
    for x, y in pts:
        c.set(x, y, 1)
    # raizes cortadas: os dois bracos param no meio do lado com a seccao clara 17,
    # e o toco de baixo leva um corte diagonal (fenda 01) com a seccao 17
    left, right = frame_roots()
    for x, y in left + right:
        if y < 24:
            c.set(x, y, 7 if (x + y) < 31 else 5)   # devolve o aro de pedra
    # contorno do corpo onde a raiz foi retirada
    for x, y in left + right:
        if y < 24 and (x, y) in DIST and DIST[(x, y)] == 0:
            c.set(x, y, 1)
    for x, y in left + right:
        if y < 24 and (x, y) not in DIST:
            c.set(x, y, 0)
    for x, y in ((2, 24), (29, 24)):
        c.set(x, y, 17)                  # seccao do corte (miolo claro da madeira)
    for x, y in ((2, 23), (29, 23), (1, 24), (30, 24)):
        if c.get(x, y) in (0, 18, 19):
            c.set(x, y, 1 if (x, y) not in DIST else c.get(x, y))
    # toco de baixo: fenda diagonal
    for x, v in zip(range(14, 18), (20, 17, 17, 19)):
        c.set(x, 30, 1)          # corte: fenda de 1 px separando o toco
        c.set(x, 31, v)          # seccao clara da madeira cortada
    # limpa sobras de contorno solto fora do corpo
    for y in range(32):
        for x in range(32):
            if c.get(x, y) == 1 and (x, y) not in DIST:
                if not any(c.get(x + dx, y + dy) not in (None, 0, 1) for dx, dy in N4):
                    c.set(x, y, 0)
    return c


# ======================================================== frame_master (40x40)
M_PROFILE = [6, 4, 3, 2, 1, 1]
M_LO, M_HI = 3, 36


def m_range(y):
    if y < M_LO or y > M_HI:
        return None
    k = y - M_LO if y < 20 else M_HI - y
    ins = M_PROFILE[k] if k < len(M_PROFILE) else 0
    return M_LO + ins, M_HI - ins


def m_in(x, y):
    r = m_range(y)
    return r is not None and r[0] <= x <= r[1]


def m_dist():
    d, frontier = {}, []
    for y in range(40):
        for x in range(40):
            if m_in(x, y) and any(not m_in(x + dx, y + dy) for dx, dy in N4):
                d[(x, y)] = 0
                frontier.append((x, y))
    k = 0
    while frontier:
        nxt = []
        for x, y in frontier:
            for dx, dy in N4:
                q = (x + dx, y + dy)
                if m_in(*q) and q not in d:
                    d[q] = k + 1
                    nxt.append(q)
        frontier = nxt
        k += 1
    return d


MD = m_dist()
# raizes de caixao abracando: (x, y, espessura). Esquerda sobe ate o topo e cruza a face;
# a direita sobe menos e enrola no lado (assimetria de coisa viva).
M_ROOT_L = [(19, 37, 3), (14, 36, 3), (9, 34, 3), (6, 31, 3), (4, 27, 3), (3, 22, 3), (3, 17, 3),
            (4, 12, 2), (6, 8, 2), (9, 5, 2), (13, 3, 2), (17, 3, 1), (20, 4, 1)]
M_ROOT_R = [(20, 37, 3), (25, 36, 3), (30, 34, 3), (33, 31, 3), (35, 27, 3), (36, 22, 3), (36, 18, 2),
            (35, 14, 2), (33, 12, 1), (31, 12, 1)]
# radicelas 1 px que cruzam a face do aro ate o filete (as "maos" da raiz)
M_ROOTLETS = [[(5, 25), (6, 25), (7, 24), (8, 24), (9, 24)], [(9, 33), (10, 32), (10, 31)],
              [(29, 33), (29, 32), (30, 31)], [(34, 23), (33, 23), (32, 22)], [(5, 14), (6, 14), (7, 13)]]


def _stamp(pts):
    """rasteriza a polilinha com espessura variavel (quadrado t x t centrado)."""
    s = set()
    for (x0, y0, t0), (x1, y1, t1) in zip(pts, pts[1:]):
        n = int(max(abs(x1 - x0), abs(y1 - y0))) * 2 + 1
        for i in range(n + 1):
            u = i / n
            x, y = x0 + (x1 - x0) * u, y0 + (y1 - y0) * u
            t = t0 if u < 0.5 else t1
            ox = -(t // 2)
            for dy in range(t):
                for dx in range(t):
                    s.add((round(x) + ox + dx, round(y) + ox + dy))
    return s


def frame_master(B, L, D, shadow=False):
    c = Canvas(40, 40)
    for (x, y), d in MD.items():
        lit = (x + y) < 39
        on_sq = 11 <= x <= 28 and 11 <= y <= 28
        sq_border = on_sq and (x in (11, 28) or y in (11, 28)) and (x, y) not in ((11, 11), (28, 11), (11, 28), (28, 28))
        if d == 0 or sq_border:
            v = 1
        elif 12 <= x <= 27 and 12 <= y <= 27:
            v = 3
        else:
            r = min(d, 7)
            v = {1: L if lit else B, 2: L if lit else B, 3: B, 4: B if lit else D,
                 5: B, 6: D if lit else L, 7: D if lit else L}[r]
        if shadow and v != 1:
            v = 2
        c.set(x, y, v)
    if not shadow:
        # cravos nas 4 direcoes, na faixa externa do aro
        for sx, sy in ((19, 5), (5, 19), (33, 19), (19, 33)):
            c.set(sx, sy, L)
            c.set(sx + 1, sy, L)
            c.set(sx, sy + 1, L)
            c.set(sx + 1, sy + 1, D)
    # raizes
    R = _stamp(M_ROOT_L) | _stamp(M_ROOT_R)
    R = {(x, y) for x, y in R if 0 <= x < 40 and 0 <= y < 40}
    # toco de 4 px na borda de baixo (liga a raiz do codigo em (20, 39))
    stub = {(x, y) for x in range(18, 22) for y in range(36, 40)}
    R |= stub
    for x, y in R:
        for dx, dy in N4:
            q = (x + dx, y + dy)
            if q not in R and 0 <= q[0] < 40 and 0 <= q[1] < 40:
                if not (12 <= q[0] <= 27 and 12 <= q[1] <= 27):
                    c.set(q[0], q[1], 1)
    for x, y in R:
        if (x, y) in stub:
            v = {18: 17, 19: 20, 20: 20, 21: 19}[x]
        elif (x - 1, y) not in R or (x, y - 1) not in R:
            v = 17 if (x * 3 + y) % 5 == 0 else 20
        elif (x + 1, y) not in R or (x, y + 1) not in R:
            v = 18
        else:
            v = 19
        if shadow:
            v = 2
        c.set(x, y, v)
    # o toco nao leva contorno embaixo (emenda com a raiz); laterais sim
    for x in range(18, 22):
        c.set(x, 39, 2 if shadow else {18: 17, 19: 20, 20: 20, 21: 19}[x])
    for x, y in ((17, 39), (22, 39), (17, 38), (22, 38)):
        c.set(x, y, 1)
    # radicelas 1 px cruzando a face do aro (19; no lado escuro 18)
    for rl in M_ROOTLETS:
        for x, y in rl:
            if (x, y) in MD and MD[(x, y)] >= 1 and not (11 <= x <= 28 and 11 <= y <= 28):
                c.set(x, y, 2 if shadow else (20 if x + y < 39 else 19))
    if shadow:
        # "?" 05 no miolo, como o oculto 32
        from tree2 import QMARK32
        c.rows(17, 15, QMARK32)
    return c


MASTER_ORDER = ['escavacao', 'lanterna', 'fortuna', 'cemiterio', 'ajudantes', 'almas']


def build_masters():
    cells = []
    bd = {n: (b, l, d) for n, b, l, d in BRANCHES}
    for n in MASTER_ORDER:
        cells.append(frame_master(*bd[n]))
    cells.append(frame_master(2, 2, 2, shadow=True))
    atlas = Canvas(40 * len(cells), 40)
    for i, cc in enumerate(cells):
        atlas.blit(cc, 40 * i, 0)
    return atlas, cells


# ===================================================================== root_y
ROOT_SPEC = T1.ROOT_SPEC   # state -> (brilho, miolo, sombra)


def root_y_piece(state, parent):
    """juncao em "Y" de 4 px de espessura. parent: 'up','down' (barra horizontal 8x4) ou
    'left','right' (barra vertical 4x8). Luz NO: horizontal = brilho em cima; vertical = brilho a
    esquerda. A raiz-mae entra no meio (x/y = 2..5) e abre 1 px para cada lado na emenda (forquilha)."""
    hi, mid, sh = ROOT_SPEC[state]
    rows = [[hi] * 8, [mid] * 8, [mid] * 8, [sh] * 8]
    if parent in ('up', 'left'):
        rows[0] = [hi, hi, mid, mid, mid, mid, sh, hi]
        rows[2][6] = sh            # fenda
    else:
        rows[3] = [sh, hi, mid, mid, mid, mid, sh, sh]
        rows[1][6] = hi            # veio claro
    if parent in ('up', 'down'):
        c = Canvas(8, 4)
        for y in range(4):
            for x in range(8):
                c.set(x, y, rows[y][x])
        return c
    # vertical: transposta (linha <-> coluna); brilho fica a esquerda e a sombra a direita
    c = Canvas(4, 8)
    for y in range(4):
        for x in range(8):
            c.set(y, x, rows[y][x])
    return c


Y_ORDER = ['up', 'down', 'left', 'right']


def build_root_y():
    atlas = Canvas(32, 16)
    for r, state in enumerate(('off', 'on')):
        for i, p in enumerate(Y_ORDER):
            pc = root_y_piece(state, p)
            ox = 8 * i + (0 if pc.w == 8 else 2)
            oy = 8 * r + (2 if pc.h == 4 else 0)
            atlas.blit(pc, ox, oy)
    return atlas


# ========================================================= fundos largos
SKY_H = 176
MOON = (416, 58, 17)    # na abertura (camera x = 648, parallax 0,5 -> ceu visivel de x = 324)


def grass_y(x):
    return round(0.7 * math.sin(x / 23.0) + 0.5 * math.sin(x / 7.3))


def sky_wide():
    rnd = random.Random(111)
    c = Canvas(WORLD_W, SKY_H)
    for y in range(SKY_H):
        for x in range(WORLD_W):
            if y < 56:
                v = 2
            elif y < 64:
                t = (y - 56 + 0.5) / 8
                v = 3 if BAYER[y % 4][x % 4] < t * 16 else 2
            elif y < 116:
                v = 3
            elif y < 124:
                t = (y - 116 + 0.5) / 8
                v = 4 if BAYER[y % 4][x % 4] < t * 16 else 3
            else:
                v = 4
            c.set(x, y, v)
    mx, my, mr = MOON
    for y in range(SKY_H):
        for x in range(mx - 40, mx + 41):
            d = math.hypot(x - mx, y - my)
            if mr < d <= mr + 4 and (x + y) % 2 == 0:
                c.set(x, y, 5)
            elif mr + 4 < d <= mr + 9 and (x + y) % 2 == 0 and (x // 2 + y // 2) % 2 == 0:
                c.set(x, y, 5 if c.get(x, y) == 4 else 4)
    n_st = 0
    while n_st < 220:
        x, y = rnd.randrange(0, WORLD_W), rnd.randrange(2, 128)
        if math.hypot(x - mx, y - my) < mr + 12:
            continue
        if any(c.get(x + dx, y + dy) in (5, 6, 7) for dx in (-2, -1, 0, 1, 2) for dy in (-2, -1, 0, 1, 2)):
            continue
        r = rnd.random()
        c.set(x, y, 7 if r < 0.12 else (6 if r < 0.5 else 5))
        n_st += 1
    for y in range(my - mr, my + mr + 1):
        for x in range(mx - mr, mx + mr + 1):
            dx, dy = x - mx, y - my
            d = math.hypot(dx, dy)
            if d <= mr + 0.3:
                c.set(x, y, 7 if (dx + dy > mr * 0.55 and d > mr * 0.55) else 8)
    for cx, cy, r in ((-5, -4, 3), (4, 3, 2), (-2, 7, 2), (7, -6, 1.5), (-8, 4, 1.5)):
        for y in range(-4, 5):
            for x in range(-4, 5):
                if math.hypot(x, y) <= r:
                    px, py = mx + cx + x, my + cy + y
                    if c.get(px, py) in (7, 8):
                        c.set(px, py, 7 if c.get(px, py) == 8 else 6)
    for x in range(mx - 30, mx + 34):
        y = my + 9 + round(1.2 * math.sin(x / 6.0))
        c.set(x, y, 5 if c.get(x, y) in (7, 8) else 4)
        if (x // 3) % 2 == 0:
            c.set(x, y + 1, 4)
    # nuvens finas espalhadas no ceu largo (04 com topo 05), sem contorno
    for cx0, cy0, L in ((120, 30, 70), (760, 22, 90), (1130, 44, 60), (1500, 28, 80), (1820, 50, 54), (980, 90, 66)):
        for x in range(cx0, cx0 + L):
            u = (x - cx0) / L
            th = round(2.2 * math.sin(u * math.pi))
            for k in range(th):
                yy = cy0 + round(1.2 * math.sin(x / 9.0)) - k
                if c.get(x, yy) is not None:
                    c.set(x, yy, 5 if k == th - 1 and (x // 2) % 2 == 0 else 4)
    return c


# construcoes do patio (UI/UX §10.2): nada de lapide distante atras delas
BUILD_X = [150, 290, 430, 580, 760, 1120, 1260, 1390, 1530, 1680, 1820]


def grass_wide():
    rnd = random.Random(33)
    c = Canvas(WORLD_W, 16)    # posicao no mundo (0, 168); grama em y = 8
    for x in range(WORLD_W):
        g = 8 + grass_y(x)
        c.set(x, g - 1, 10)
        c.set(x, g, 10)
        c.set(x, g + 1, 9)
        c.set(x, g + 2, 9 if rnd.random() < 0.6 else 0)
        r = rnd.random()
        if r < 0.22:
            c.set(x, g - 2, 10)
            c.set(x, g - 3 if r < 0.07 else g - 2, 11)
        elif r < 0.30:
            c.set(x, g - 2, 10)
    TUFT = [["..h..", ".hGh.", "hGGGh"], [".h.h.", "hGhGh", "GGGGG"], ["h...h", ".hGh.", ".GGG."]]
    for _ in range(80):
        x = rnd.randrange(4, WORLD_W - 6)
        if abs(x - N00_X) < 34:
            continue
        g = 8 + grass_y(x)
        rows = rnd.choice(TUFT)
        c.rows(x - 2, g - len(rows), rows)
    TOMB = [".VVV.", "VLVVV", "VLVVV", "VLVVV", "VLVVV"]
    CROSS = [".c.", "cCc", ".C.", ".C.", ".C."]
    for x, kind in [(40, TOMB), (78, CROSS), (220, TOMB), (360, CROSS), (505, TOMB), (668, CROSS),
                    (845, TOMB), (1190, CROSS), (1325, TOMB), (1460, CROSS), (1605, TOMB), (1752, CROSS),
                    (1890, TOMB)]:
        assert all(abs(x - b) > 30 for b in BUILD_X), x
        g = 8 + grass_y(x)
        c.rows(x, g - 1 - len(kind), kind)
    for _ in range(90):
        x = round(rnd.gauss(N00_X, 160))
        if abs(x - N00_X) < 28 or not 0 <= x < WORLD_W:
            continue
        g = 8 + grass_y(x)
        c.set(x, g - 1, 5 if rnd.random() < 0.7 else 8)
    return c


SOIL_H = WORLD_H - SURF      # 848; posicao no mundo (0, 176)
SB1, SB2 = 250, 720          # 14 -> 13 -> 01 (y local); mundo 426 e 896 (abaixo da ultima linha de nos, y = 880)
VEINS = [N00_X + 88 * k for k in (-6.5, -3.5, -0.5, 0.5, 3.5, 6.5)]   # fronteiras das faixas dos ramos
VEIN_W = 4                   # meia largura do miolo do veio


def vein_x(base, y, seed):
    return base + 5.0 * math.sin(y / 71.0 + seed) + 2.0 * math.sin(y / 23.0 + seed * 1.7)


def soil_wide():
    rnd = random.Random(77)
    W, H = WORLD_W, SOIL_H
    c = Canvas(W, H)
    b1s = [SB1 + round(wave(x, 1.0, 3)) for x in range(W)]
    b2s = [SB2 + round(wave(x, 4.0, 3)) for x in range(W)]
    for x in range(W):
        b1, b2 = b1s[x], b2s[x]
        for y in range(H):
            if y < b1 - 4:
                v = 14
            elif y < b1 + 4:
                v = 13 if BAYER[y % 4][x % 4] < ((y - (b1 - 4) + 0.5) / 8) * 16 else 14
            elif y < b2 - 4:
                v = 13
            elif y < b2 + 4:
                v = 1 if BAYER[y % 4][x % 4] < ((y - (b2 - 4) + 0.5) / 8) * 16 else 13
            else:
                v = 1
            c.set(x, y, v)
    # veios verticais: um degrau mais escuro (14->13, 13->01); miolo cheio, bordas em Bayer 50%/25%.
    # Na faixa 01 o veio vira "terra limpa" (sem estrias claras) e as bordas ganham estrias 13.
    vein_mask = {}
    for vi, vx in enumerate(VEINS):
        for y in range(H):
            cx = vein_x(vx, y, vi * 2.3)
            # o veio afina e some perto da grama (comeca 24 px abaixo dela)
            fade = min(1.0, max(0.0, (y - 24) / 40.0))
            hw = VEIN_W * fade * (0.55 + 0.45 * math.sin(y / 47.0 + vi * 1.3))
            for x in range(int(cx - hw - 10), int(cx + hw + 11)):
                d = abs(x + 0.5 - cx)
                if d <= hw:
                    k = 2
                elif d <= hw + 4:
                    k = 1 if BAYER[y % 4][x % 4] < 8 else 0
                elif d <= hw + 9:
                    k = 1 if BAYER[y % 4][x % 4] < 4 else 0
                else:
                    k = 0
                if k and 0 <= x < W:
                    vein_mask[(x, y)] = max(vein_mask.get((x, y), 0), k)
    for (x, y), k in vein_mask.items():
        v = c.get(x, y)
        c.set(x, y, {14: 13, 13: 1}.get(v, v))

    def free(x, y):
        return (x, y) not in vein_mask

    def streaks(y0, y1, col, base, n):
        for _ in range(n):
            x, y = rnd.randrange(0, W - 20), rnd.randrange(y0, y1)
            L = rnd.randrange(6, 26)
            for i in range(L):
                if c.get(x + i, y) == base and free(x + i, y):
                    c.set(x + i, y, col)
    streaks(10, SB1 - 8, 13, 14, 230)
    streaks(SB1 + 8, SB2 - 8, 14, 13, 190)
    streaks(SB1 + 8, SB2 - 8, 1, 13, 50)
    streaks(SB2 + 8, H - 4, 13, 1, 230)
    # raizes finas decorativas (um degrau de valor so)
    for _ in range(150):
        x = rnd.uniform(10, W - 10)
        y = rnd.uniform(30, H - 40)
        ang = rnd.uniform(math.pi * 0.3, math.pi * 0.7)
        L = rnd.randrange(18, 60)
        for i in range(L):
            ang += rnd.uniform(-0.25, 0.25)
            ang = min(max(ang, 0.2), math.pi - 0.2)
            x += math.cos(ang) * 0.9
            y += math.sin(ang) * 0.9
            px, py = round(x), round(y)
            if not free(px, py):
                break
            col = {14: 13, 13: 14, 1: 13}.get(c.get(px, py))
            if col:
                c.set(px, py, col)
    PEB = {
        'p3': ["SV", "VI"],
        'p4': [".SV.", "SVVI", ".II."],
        'p5': [".SVV.", "SVVVI", ".VII."],
        'p6': ["..VVV.", ".SSVVV", "SVVVVI", ".VVIII", "..II.."],
    }
    occupied = []

    def pebbles(y0, y1, kinds, n, base):
        k = tries = 0
        while k < n and tries < n * 60:
            tries += 1
            x, y = rnd.randrange(4, W - 10), rnd.randrange(y0, y1)
            if abs(x - N00_X) < 50 and y < 50:
                continue
            if not all(abs(x - a) > 14 or abs(y - b) > 14 for a, b in occupied):
                continue
            rows = PEB[rnd.choice(kinds)]
            cells = [(x + i, y + j) for j, r in enumerate(rows) for i, ch in enumerate(r) if ch != '.']
            if any(c.get(*p) not in base or not free(*p) for p in cells):
                continue
            c.rows(x, y, rows)
            occupied.append((x, y))
            k += 1
    pebbles(8, SB1 - 6, ['p5', 'p6', 'p4'], 95, (13, 14))
    pebbles(SB1 + 6, SB2 - 6, ['p4', 'p5', 'p3'], 85, (13, 14, 1))
    pebbles(SB2 + 6, H - 6, ['p3', 'p4'], 70, (1, 13))
    return c, vein_mask


# ===================================================================== checks
def check_palette(name, c):
    for row in c.px:
        for v in row:
            assert 0 <= v <= 32, (name, v)


def loose_pixels(c):
    """pixel opaco sem nenhum vizinho opaco (4-viz.)."""
    out = []
    for y in range(c.h):
        for x in range(c.w):
            if c.px[y][x] and not any(c.get(x + dx, y + dy) not in (None, 0) for dx, dy in N4):
                out.append((x, y))
    return out


def colors(c):
    s = {}
    for row in c.px:
        for v in row:
            if v:
                s[v] = s.get(v, 0) + 1
    return s


def gray(cv, scale):
    im = cv.to_rgba(scale)
    from PIL import Image
    g = im.convert('L')
    bg = Image.new('L', g.size, 0)
    bg.paste(g, mask=im.split()[3])
    return bg


# ======================================================================= main
if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    report = []
    icons = IC.build_all()
    _, row0, row1 = build_medallions32()

    fa, fr_, fd, fs = frame_at(), frame_r(), frame_d(), frame_sealed()
    masters, mcells = build_masters()
    ry = build_root_y()
    sky = sky_wide()
    grass = grass_wide()
    soil, vmask = soil_wide()

    singles = [('frame_at', fa, 'ui_tree_frame_at'), ('frame_r', fr_, 'ui_tree_frame_r'),
               ('frame_d', fd, 'ui_tree_frame_d'), ('frame_sealed', fs, 'ui_tree_frame_sealed'),
               ('frame_masters', masters, 'ui_tree_frame_masters'), ('root_y', ry, 'ui_tree_root_y'),
               ('tree_sky_wide', sky, 'ui_tree_ceu_wide'), ('tree_grass_wide', grass, 'ui_tree_grama_wide'),
               ('tree_soil_wide', soil, 'ui_tree_subsolo_wide')]
    for name, cv, src in singles:
        check_palette(name, cv)
        cv.save(J(OUT, name + '.png'))
        ase = J(SRC, src + '.aseprite')
        if name == 'frame_masters':
            write_ase(ase, mcells)          # 1 frame por celula (frames 1-7 = colunas 0-6)
            w, h, frs = read_ase(ase)
            assert all(frs[i] == mcells[i].px for i in range(len(mcells)))
        else:
            write_ase(ase, [cv])
            w, h, frs = read_ase(ase)
            assert (w, h) == (cv.w, cv.h) and frs[0] == cv.px, name
        lp = loose_pixels(cv) if cv.w <= 320 else []
        report.append('%-16s %4dx%-4d cores=%s soltos=%d' % (name, cv.w, cv.h, sorted(colors(cv)), len(lp)))
        if lp:
            report.append('   soltos: %s' % lp[:12])

    # emendas
    for x in range(WORLD_W):
        g = SURF + grass_y(x)
        assert g + 1 >= SURF, 'buraco entre grama e subsolo'
    # dentro do veio, nada mais claro que o entorno
    # ---------------------------------------------------------- previas
    from PIL import Image
    BG = 14

    def sheet_prev(items, cell=36, bg=BG):
        cv = Canvas(cell * len(items), cell, bg)
        for i, it in enumerate(items):
            cv.blit(it, i * cell + (cell - it.w) // 2, (cell - it.h) // 2)
        return cv

    # sobreposicoes em cima de medalhoes reais (com icone), normal e respirando
    combos = []
    ico = ['E03', 'L02', 'F02', 'C02', 'A01', 'S01', 'N01']
    for r, rows_ in ((0, row0), (1, row1)):
        for kind, ov in (('P', None), ('At', fa), ('R', fr_), ('D', fd)):
            for b in range(7):
                m = Canvas(32, 32)
                m.blit(rows_[b], 0, 0)
                m.blit(icons[ico[b]], 8, 8)
                if ov:
                    m.blit(ov, 0, 0)
                combos.append(m)
    cell = 40
    cvp = Canvas(cell * 7, cell * 8, BG)
    for i, m in enumerate(combos):
        cvp.blit(m, (i % 7) * cell + 4, (i // 7) * cell + 4)
    cvp.to_rgba(4).save(J(PREV, 'tree3_molduras_tipo_4x.png'))
    cvp.to_rgba(1).save(J(PREV, 'tree3_molduras_tipo_1x.png'))
    gray(cvp, 4).save(J(PREV, 'tree3_molduras_tipo_cinza_4x.png'))

    # encruzilhada: mae, Y, dois lados (um comprado, outro selado) e mestres ao lado dos 32
    sc = Canvas(320, 150, BG)
    T1.draw_root(sc, [(60, 10), (60, 60)], 'on')
    T1.draw_root(sc, [(18, 64), (102, 64)], 'on')
    sc.blit(root_y_piece('on', 'up'), 56, 63 - 0)
    T1.draw_root(sc, [(18, 64), (18, 90)], 'on')
    T1.draw_root(sc, [(102, 64), (102, 90)], 'off')
    m = Canvas(32, 32)
    m.blit(row0[0], 0, 0)
    m.blit(icons['E03'], 8, 8)
    sc.blit(m, 2, 90)
    sc.blit(fs, 86, 90)
    sc.blit(row0[0], 140, 20)
    sc.blit(icons['E01'], 148, 28)
    for i, mc in enumerate(mcells):
        x0 = 140 + (i % 4) * 44
        y0 = 58 + (i // 4) * 44 if i < 4 else 58 + 44
        if i >= 4:
            x0 = 184 + (i - 4) * 44
        sc.blit(mc, x0, y0)
    mm = Canvas(40, 40)
    mm.blit(mcells[0], 0, 0)
    mm.blit(icons['E10'], 12, 12)
    sc.blit(mm, 184, 14)
    sc.to_rgba(4).save(J(PREV, 'tree3_encruzilhada_mestres_4x.png'))
    sc.to_rgba(1).save(J(PREV, 'tree3_encruzilhada_mestres_1x.png'))
    gray(sc, 4).save(J(PREV, 'tree3_encruzilhada_mestres_cinza_4x.png'))
    # silhueta (sombra chinesa) das pecas
    sil = Canvas(5 * 44, 44, 22)
    for i, it in enumerate([fa, fr_, fd, fs, mcells[0]]):
        for y in range(it.h):
            for x in range(it.w):
                if it.px[y][x]:
                    sil.set(i * 44 + 2 + x, 2 + y, 1)
    sil.to_rgba(4).save(J(PREV, 'tree3_silhuetas_4x.png'))
    # root_y a 8x com as raizes de verdade emendando nas 4 rotacoes
    yy = Canvas(4 * 30, 2 * 30, BG)
    for r, st in enumerate(('off', 'on')):
        for i, p in enumerate(Y_ORDER):
            pc = root_y_piece(st, p)
            px, py = i * 30 + 11, r * 30 + 11
            if p in ('up', 'down'):
                if p == 'up':
                    T1.draw_root(yy, [(px + 3, py - 10), (px + 3, py - 1)], st)
                else:
                    T1.draw_root(yy, [(px + 3, py + 4), (px + 3, py + 13)], st)
                T1.draw_root(yy, [(px - 10, py + 1), (px - 1, py + 1)], st)
                T1.draw_root(yy, [(px + 8, py + 1), (px + 17, py + 1)], st)
            else:
                if p == 'left':
                    T1.draw_root(yy, [(px - 10, py + 3), (px - 1, py + 3)], st)
                else:
                    T1.draw_root(yy, [(px + 4, py + 3), (px + 13, py + 3)], st)
                T1.draw_root(yy, [(px + 1, py - 10), (px + 1, py - 1)], st)
                T1.draw_root(yy, [(px + 1, py + 8), (px + 1, py + 17)], st)
            yy.blit(pc, px, py)
    yy.to_rgba(8).save(J(PREV, 'tree3_root_y_8x.png'))
    # mundo largo montado (1x e um recorte da abertura a 2x)
    world = Canvas(WORLD_W, WORLD_H, 2)
    world.blit(sky, 0, 0)
    world.blit(soil, 0, SURF)
    tr = Image.open(J(OUT, 'tree_trunk.png'))
    trunk = Canvas(tr.width, tr.height)
    for y in range(tr.height):
        for x in range(tr.width):
            trunk.px[y][x] = tr.getpixel((x, y))
    world.blit(trunk, N00_X - 72, SURF - 76)
    world.blit(grass, 0, SURF - 8)
    world.to_rgba(1).save(J(PREV, 'tree3_mundo_largo_1x.png'))
    # vista da abertura com parallax 0,5 no ceu (camera (648, 0))
    view = Canvas(640, 360, 2)
    view.blit(sky, -324, 0)
    view.blit(soil, -648, SURF)
    view.blit(trunk, N00_X - 72 - 648, SURF - 76)
    view.blit(grass, -648, SURF - 8)
    view.to_rgba(2).save(J(PREV, 'tree3_abertura_2x.png'))
    gray(view, 2).save(J(PREV, 'tree3_abertura_cinza_2x.png'))
    # recorte fundo (camera (260, 560)): veios separando faixas na parte escura
    deep = Canvas(640, 360, 2)
    deep.blit(soil, -260, SURF - 560)
    deep.to_rgba(2).save(J(PREV, 'tree3_subsolo_fundo_2x.png'))
    print('\n'.join(report))
    print('ok')
