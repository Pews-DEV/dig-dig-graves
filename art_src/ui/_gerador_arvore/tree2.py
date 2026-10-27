"""Arvore aconchegante (docs/03_UI_UX.md §7): medalhoes 32, camadas da superficie,
subsolo alto, particulas, efeitos de compra, pips, mock e GIFs."""
import json
import math
import random
from PIL import Image
from common import Canvas, PAL, LEG
import icons as IC
import font5x7 as F

ROOT = r'C:\Users\pedro\Documents\projects\dig-dig-graves'
OUT = ROOT + r'\assets\ui\tree'
PREV = ROOT + r'\art_src\_previews'
SURF = 112          # linha da grama no mundo da Arvore (640 x 720)
WORLD_H = 720

N4 = ((1, 0), (-1, 0), (0, 1), (0, -1))


def outline_set(c, pts, col=1, only_empty=True):
    s = set(pts)
    for x, y in pts:
        for dx, dy in N4:
            q = (x + dx, y + dy)
            if q in s:
                continue
            if only_empty and c.get(*q) not in (0,):
                continue
            c.set(q[0], q[1], col)


# =============================================================== medalhoes 32
BODY_PROFILE = [5, 3, 2, 1, 1]


def body_range(y):
    """faixa x do corpo (2..29) na linha y, ou None."""
    if y < 2 or y > 29:
        return None
    k = y - 2 if y < 16 else 29 - y
    ins = BODY_PROFILE[k] if k < len(BODY_PROFILE) else 0
    return 2 + ins, 29 - ins


def in_body(x, y):
    r = body_range(y)
    return r is not None and r[0] <= x <= r[1]


def body_dist():
    """distancia (4-viz.) ate fora do corpo: 0 = contorno."""
    INF = 99
    d = {}
    frontier = []
    for y in range(32):
        for x in range(32):
            if in_body(x, y):
                if any(not in_body(x + dx, y + dy) for dx, dy in N4):
                    d[(x, y)] = 0
                    frontier.append((x, y))
    k = 0
    while frontier:
        nxt = []
        for x, y in frontier:
            for dx, dy in N4:
                q = (x + dx, y + dy)
                if in_body(*q) and q not in d:
                    d[q] = k + 1
                    nxt.append(q)
        frontier = nxt
        k += 1
    return d


DIST = body_dist()

# raiz que abraca a borda (lado esquerdo; o direito e espelhado)
# a raiz corre POR CIMA do contorno (anel 0), do meio de baixo ate o meio do lado,
# com radicelas que cruzam a face do aro
ROOT_L = [(15, 30), (14, 30), (13, 29), (12, 29), (11, 29), (10, 29), (9, 29), (8, 29),
          (7, 29), (6, 28), (5, 28), (4, 27), (3, 26), (3, 25), (2, 24), (2, 23),
          (2, 22), (2, 21), (2, 20), (2, 19), (1, 18), (1, 17)]
ROOT_THICK = [(15, 31), (14, 31)]   # toco que liga a raiz da arvore (borda de baixo da celula)
ROOTLETS = [(5, 27), (6, 26), (3, 22), (4, 21), (11, 28)]


def frame_roots():
    left = ROOT_L + ROOT_THICK + ROOTLETS
    right = [(31 - x, y) for x, y in left]
    return left, right


def medallion32(B, L, D, mode='normal', root_cols=(20, 19, 18)):
    """B base, L luz, D sombra. mode: normal | lunar | max | hidden"""
    c = Canvas(32, 32)
    for (x, y), d in DIST.items():
        lit = (x + y) < 31
        inner_sq = 7 <= x <= 24 and 7 <= y <= 24
        on_sq_border = inner_sq and (x in (7, 24) or y in (7, 24)) and (x, y) not in ((7, 7), (24, 7), (7, 24), (24, 24))
        if mode == 'hidden':
            v = 1 if d == 0 else 2
        elif d == 0:
            v = 1
        elif on_sq_border:
            v = 24 if mode == 'max' else 1
        elif 8 <= x <= 23 and 8 <= y <= 23:
            v = 3
        else:
            r = min(d, 4)
            if mode == 'lunar':
                # aro de pedra clara 08 com filete de ouro 26 no meio
                v = {1: L if lit else B, 2: D, 3: B, 4: (D if lit else B)}[r]
            else:
                v = {1: (L if lit else B), 2: B, 3: (B if lit else D), 4: (D if lit else L)}[r]
        c.set(x, y, v)
    if mode not in ('hidden', 'max'):
        # cravos (topo, esquerda, direita)
        for sx, sy in ((15, 3), (3, 15), (27, 15)):
            c.set(sx, sy, L)
            c.set(sx + 1, sy, L)
            c.set(sx, sy + 1, L)
            c.set(sx + 1, sy + 1, D)
    # raizes finas abracando a borda
    left, right = frame_roots()
    lc, rc, base = root_cols
    if mode == 'hidden':
        lc = rc = base = 2
    for x, y in left:
        c.set(x, y, lc if y < 29 else base)
    for x, y in right:
        c.set(x, y, rc if y < 29 else base)
    pts = left + right
    s = set(pts)
    for x, y in pts:
        for dx, dy in N4:
            q = (x + dx, y + dy)
            if q not in s and 0 <= q[0] < 32 and 0 <= q[1] < 32:
                if c.get(*q) == 0 or (q in DIST and DIST[q] >= 1 and c.get(*q) not in (1,) and mode != 'hidden' and False):
                    c.set(q[0], q[1], 1)
    return c


QMARK32 = [".LLLL.",
           "LLLLLL",
           "LL..LL",
           "....LL",
           "...LL.",
           "..LL..",
           "..LL..",
           "......",
           "..LL..",
           "..LL.."]

STAR32 = ["...Z...",
          "..ZWZ..",
          "ZZZWZZZ",
          ".ZZZZZ.",
          ".ZZ.ZZ.",
          ".Z...Z."]


def put_star(c, rows, x0=13, y0=0):
    pts = []
    for j, r in enumerate(rows):
        for i, ch in enumerate(r):
            if ch != '.':
                pts.append((x0 + i, y0 + j, LEG[ch]))
    s = {(x, y) for x, y, _ in pts}
    for x, y, _ in pts:
        for dx, dy in N4:
            q = (x + dx, y + dy)
            if q not in s:
                c.set(q[0], q[1], 1)
    for x, y, v in pts:
        c.set(x, y, v)


def med_hidden32():
    c = medallion32(2, 2, 2, 'hidden')
    c.rows(13, 11, QMARK32)
    return c


def med_max32(frame=0):
    c = medallion32(26, 23, 24, 'max', root_cols=(26, 25, 25))
    # brilho extra no aro (canto NO)
    if frame == 0:
        put_star(c, STAR32)
    elif frame == 1:
        put_star(c, [r.replace('Z', 'W') for r in STAR32])
    else:
        put_star(c, STAR32)
        for x, y in ((10, 1), (22, 1), (10, 6), (22, 6)):
            c.set(x, y, 23)
    return c


BRANCHES = [  # nome, base, luz, sombra
    ('escavacao', 16, 17, 15),
    ('lanterna', 25, 26, 24),
    ('fortuna', 26, 23, 25),
    ('cemiterio', 11, 12, 10),
    ('ajudantes', 5, 6, 4),
    ('almas', 30, 23, 5),
    ('lunar', 8, 26, 7),
]


def halo(c, col):
    """anel externo em xadrez (fora do corpo, ate 2 px) + brilhinho 23 no aro."""
    h = Canvas(32, 32)
    h.blit(c, 0, 0)
    for y in range(32):
        for x in range(32):
            if c.px[y][x]:
                continue
            near = any(in_body(x + dx, y + dy) for dx in range(-2, 3) for dy in range(-2, 3))
            if near and (x + y) % 2 == 0:
                h.set(x, y, col)
    # cintilar no aro (cruzinha 23 no canto NO)
    for x, y in ((7, 3), (6, 4), (7, 4), (8, 4), (7, 5)):
        h.set(x, y, 23)
    return h


def build_medallions32():
    base = []
    for name, B, L, D in BRANCHES:
        base.append(medallion32(B, L, D, 'lunar' if name == 'lunar' else 'normal'))
    halos = [halo(base[i], BRANCHES[i][2] if BRANCHES[i][0] != 'lunar' else 26) for i in range(7)]
    row0 = base + [med_hidden32(), med_max32(0)]
    row1 = halos + [med_max32(1), med_max32(2)]
    atlas = Canvas(32 * 9, 64)
    for i, c in enumerate(row0):
        atlas.blit(c, 32 * i, 0)
    for i, c in enumerate(row1):
        atlas.blit(c, 32 * i, 32)
    return atlas, row0, row1


# ======================================================================= pips
def pips():
    c = Canvas(12, 4)
    for i in range(3):
        x0 = i * 4
        for y in range(4):
            for x in range(4):
                if (x in (0, 3) and y in (0, 3)):
                    continue
                c.set(x0 + x, y, 1)
        inner = [[4, 4], [3, 3]] if i == 0 else ([[26, 26], [25, 25]] if i == 1 else [[23, 23], [26, 26]])
        for y in range(2):
            for x in range(2):
                c.set(x0 + 1 + x, 1 + y, inner[y][x])
    return c


# ========================================================================= ceu
BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]
MOON = (92, 50, 17)


def sky():
    rnd = random.Random(11)
    H = 128
    c = Canvas(640, H)
    bands = [(0, 2), (44, 3), (88, 4)]
    for y in range(H):
        for x in range(640):
            v = 2
            for (y0, col), (y1, col1) in zip(bands, bands[1:]):
                pass
            if y < 40:
                v = 2
            elif y < 48:
                t = (y - 40 + 0.5) / 8
                v = 3 if BAYER[y % 4][x % 4] < t * 16 else 2
            elif y < 84:
                v = 3
            elif y < 92:
                t = (y - 84 + 0.5) / 8
                v = 4 if BAYER[y % 4][x % 4] < t * 16 else 3
            else:
                v = 4
            c.set(x, y, v)
    # halo da lua em xadrez (05 perto, 04 longe)
    mx, my, mr = MOON
    for y in range(H):
        for x in range(640):
            d = math.hypot(x - mx, y - my)
            if mr < d <= mr + 4 and (x + y) % 2 == 0:
                c.set(x, y, 5)
            elif mr + 4 < d <= mr + 9 and (x + y) % 2 == 0 and (x // 2 + y // 2) % 2 == 0:
                c.set(x, y, 5 if c.get(x, y) == 4 else 4)
    # estrelas estaticas (as que cintilam o codigo poe com tree_stars)
    for _ in range(70):
        x, y = rnd.randrange(0, 640), rnd.randrange(2, 96)
        if math.hypot(x - mx, y - my) < mr + 12:
            continue
        r = rnd.random()
        c.set(x, y, 7 if r < 0.15 else (6 if r < 0.5 else 5))
    # lua cheia: 08 com sombra 07 a direita/baixo e crateras 07/06
    for y in range(my - mr, my + mr + 1):
        for x in range(mx - mr, mx + mr + 1):
            dx, dy = x - mx, y - my
            d = math.hypot(dx, dy)
            if d <= mr + 0.3:
                v = 8
                if dx + dy > mr * 0.55 and d > mr * 0.55:
                    v = 7
                c.set(x, y, v)
    for cx, cy, r in ((-5, -4, 3), (4, 3, 2), (-2, 7, 2), (7, -6, 1.5), (-8, 4, 1.5)):
        for y in range(-4, 5):
            for x in range(-4, 5):
                if math.hypot(x, y) <= r:
                    px, py = mx + cx + x, my + cy + y
                    if c.get(px, py) in (7, 8):
                        c.set(px, py, 7 if c.get(px, py) == 8 else 6)
    # nuvem fina passando na frente da lua (04/05)
    for x in range(mx - 30, mx + 34):
        y = my + 9 + round(1.2 * math.sin(x / 6.0))
        c.set(x, y, 5 if c.get(x, y) in (7, 8) else 4)
        if (x // 3) % 2 == 0:
            c.set(x, y + 1, 4)
    return c


def stars_sheet():
    # 2 tipos (linhas) x 2 frames (colunas), celula 5x5, centro (2,2)
    c = Canvas(10, 10)
    c.set(2, 2, 6)                       # tipo 0, frame 0: ponto fraco
    c.set(7, 2, 8)                       # tipo 0, frame 1: ponto forte
    for x, y in ((6, 2), (8, 2), (7, 1), (7, 3)):
        c.set(x, y, 5)
    c.set(2, 7, 7)                       # tipo 1, frame 0
    for x, y in ((1, 7), (3, 7), (2, 6), (2, 8)):
        c.set(x, y, 5)
    c.set(7, 7, 8)                       # tipo 1, frame 1: cruz longa
    for x, y in ((6, 7), (8, 7), (7, 6), (7, 8)):
        c.set(x, y, 7)
    for x, y in ((5, 7), (9, 7), (7, 5), (7, 9)):
        c.set(x, y, 5)
    return c


# ============================================================ copa (3 frames)
CANOPY_X, CANOPY_Y, CANOPY_W, CANOPY_H = 112, 0, 416, 100


def canopy_frames():
    rnd = random.Random(5)
    blobs = []
    for _ in range(120):
        x = rnd.uniform(130, 510)
        dist = abs(x - 320) / 200.0
        y = rnd.uniform(-10, 14 + 50 * (1 - dist ** 2))
        r = rnd.uniform(7, 12) * (1.2 - 0.45 * dist)
        blobs.append((x, y, r, rnd.random()))
    blobs.sort(key=lambda b: b[1])
    specks = [(rnd.random(), rnd.random()) for _ in range(500)]
    holes = [(rnd.random(), rnd.random()) for _ in range(160)]
    branches = [((312, 52), (258, 20)), ((328, 50), (390, 18)), ((306, 58), (214, 34)), ((336, 58), (430, 34)),
                ((300, 62), (250, 56)), ((342, 62), (396, 54))]
    frames = []
    for f, sway in enumerate((-1, 0, 1)):
        c = Canvas(CANOPY_W, CANOPY_H)
        # galhos (18) atras das flores
        for (x0, y0), (x1, y1) in branches:
            n = max(abs(x1 - x0), abs(y1 - y0))
            for i in range(n + 1):
                t = i / n
                x = round(x0 + (x1 - x0) * t + sway * t)
                y = round(y0 + (y1 - y0) * t)
                for w in (0, 1):
                    c.set(x - CANOPY_X, y + w, 18)
                c.set(x - CANOPY_X, y + 2, 1)
        canopy = {}
        for bx, by, r, ph in blobs:
            # deslocamento: copa externa e baixa balanca mais; fase por cacho
            dist = abs(bx - 320) / 200.0
            amp = 0.6 + 1.2 * dist + 0.02 * max(0, by)
            off = round(sway * amp * (0.7 + 0.6 * ph))
            for y in range(int(by - r - 1), int(by + r + 2)):
                for x in range(int(bx - r - 1), int(bx + r + 2)):
                    d = math.hypot(x - bx, (y - by) * 1.25)
                    if d <= r:
                        lit = ((x - bx) + (y - by) * 1.25) < -r * 0.35
                        canopy[(x + off, y)] = 5 if lit else 4
        for (x, y), v in canopy.items():
            c.set(x - CANOPY_X, y - CANOPY_Y, v)
        keys = sorted(canopy)
        rr = random.Random(99)   # mesma borda nos 3 frames (so o balanco muda)
        for (x, y) in keys:
            edge = any((x + dx, y + dy) not in canopy for dx, dy in N4)
            if edge:
                q = rr.random()
                if q < 0.28:
                    c.set(x - CANOPY_X, y - CANOPY_Y, 0)
                elif q < 0.42 and (x, y + 1) not in canopy:
                    c.set(x - CANOPY_X, y + 1 - CANOPY_Y, 4)
        for u, v in specks:
            x, y = keys[int(u * len(keys))]
            if c.get(x - CANOPY_X, y) == 4:
                c.set(x - CANOPY_X, y, 5)
                if c.get(x - CANOPY_X + 1, y) == 4:
                    c.set(x - CANOPY_X + 1, y, 5)
        for u, v in holes:
            x, y = keys[int(u * len(keys))]
            if c.get(x - CANOPY_X, y) in (4, 5) and c.get(x - CANOPY_X + 1, y + 1) in (4, 5):
                c.set(x - CANOPY_X + 1, y + 1, 3)
        # algumas flores claras 08 (pouquinhas: cachos sob a lua)
        for u, v in specks[:40]:
            x, y = keys[int(u * len(keys))]
            if c.get(x - CANOPY_X, y) == 5 and x < 300:
                c.set(x - CANOPY_X, y, 8 if v < 0.3 else 5)
        frames.append(c)
    return frames


# ============================================================ tronco + base
TRUNK_X, TRUNK_Y, TRUNK_W, TRUNK_H = 248, 36, 144, 132


def trunk():
    c = Canvas(TRUNK_W, TRUNK_H)
    ox, oy = TRUNK_X, TRUNK_Y

    def S(x, y, v):
        c.set(x - ox, y - oy, v)

    def G(x, y):
        return c.get(x - ox, y - oy)
    for y in range(oy, SURF + 2):
        t = (y - oy) / (SURF - oy)
        hw = 14 + round(11 * t ** 3)
        sway = round(1.5 * math.sin(y / 11.0))
        x0, x1 = 320 - hw + sway, 320 + hw + sway
        for x in range(x0, x1 + 1):
            u = (x - x0) / max(1, x1 - x0)
            S(x, y, 20 if u < 0.14 else (19 if u < 0.62 else 18))
        S(x0 - 1, y, 1)
        S(x1 + 1, y, 1)
    for (bx, y0, y1) in [(-6, 36, 70), (1, 44, 96), (7, 36, 62), (-2, 70, 110), (10, 74, 112), (-9, 86, 113), (4, 96, 113)]:
        for y in range(y0, y1):
            sway = round(1.5 * math.sin(y / 11.0))
            x = 320 + bx + sway + (1 if (y // 7) % 2 else 0)
            if G(x, y) in (19, 20):
                S(x, y, 18)
    for j, r in enumerate([".cc.", "cKKc", "cKKc", ".cC."]):
        for i, ch in enumerate(r):
            if ch != '.':
                S(325 + i, 74 + j, LEG[ch])

    def flare(pts, w0):
        for i, ((xa, ya), (xb, yb)) in enumerate(zip(pts, pts[1:])):
            n = int(max(abs(xb - xa), abs(yb - ya))) * 2 + 1
            for k in range(n + 1):
                t = k / n
                x = xa + (xb - xa) * t
                y = ya + (yb - ya) * t
                frac = (i + t) / (len(pts) - 1)
                w = max(1, round(w0 * (1 - frac) + 1 * frac))
                for dx in range(-w, w + 1):
                    xx = round(x) + dx
                    u = (dx + w) / (2 * w + 0.001)
                    v = 20 if u < 0.2 else (19 if u < 0.6 else 18)
                    S(xx, round(y), v)
                    S(xx, round(y) + 1, 18 if v != 20 else 19)
    flare([(304, SURF), (290, SURF + 9), (272, SURF + 15), (256, SURF + 19)], 4)
    flare([(336, SURF), (350, SURF + 8), (368, SURF + 13), (384, SURF + 16)], 4)
    flare([(320, SURF), (321, SURF + 14), (320, SURF + 26), (320, SURF + 36)], 5)
    flare([(310, SURF + 2), (305, SURF + 16), (296, SURF + 26)], 2)
    flare([(331, SURF + 2), (337, SURF + 18), (346, SURF + 28)], 2)
    pts = [(x, y) for y in range(TRUNK_H) for x in range(TRUNK_W) if c.px[y][x]]
    s = set(pts)
    for x, y in pts:
        for dx, dy in N4:
            q = (x + dx, y + dy)
            if q not in s and 0 <= q[0] < TRUNK_W and 0 <= q[1] < TRUNK_H and c.px[q[1]][q[0]] == 0:
                c.px[q[1]][q[0]] = 1
    return c


# ================================================================== grama
def grass():
    rnd = random.Random(3)
    c = Canvas(640, 16)        # posicao no mundo: (0, SURF - 8); linha da grama em y = 8
    for x in range(640):
        g = 8 + round(0.7 * math.sin(x / 23.0) + 0.5 * math.sin(x / 7.3))
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
    # tufos maiores (3-5 px) espalhados
    TUFT = [["..h..", ".hGh.", "hGGGh"], [".h.h.", "hGhGh", "GGGGG"], ["h...h", ".hGh.", ".GGG."]]
    for _ in range(26):
        x = rnd.randrange(4, 630)
        if abs(x - 320) < 34:
            continue
        g = 8 + round(0.7 * math.sin(x / 23.0) + 0.5 * math.sin(x / 7.3))
        rows = rnd.choice(TUFT)
        c.rows(x - 2, g - 1 - len(rows) + 1, rows)
    # lapides e cruzes ao longe e petalas caidas
    TOMB = [".VVV.", "VLVVV", "VLVVV", "VLVVV", "VLVVV"]
    CROSS = [".c.", "cCc", ".C.", ".C.", ".C."]
    for x, kind in [(40, TOMB), (78, CROSS), (150, TOMB), (500, TOMB), (552, CROSS), (600, TOMB)]:
        g = 8 + round(0.7 * math.sin(x / 23.0) + 0.5 * math.sin(x / 7.3))
        c.rows(x, g - 1 - len(kind), kind)
    for _ in range(40):
        x = round(rnd.gauss(320, 110))
        if abs(x - 320) < 28 or not 0 <= x < 640:
            continue
        g = 8 + round(0.7 * math.sin(x / 23.0) + 0.5 * math.sin(x / 7.3))
        c.set(x, g - 1, 5 if rnd.random() < 0.7 else 8)
    return c


# =========================================================== subsolo alto
B1, B2 = 262, 452
TRANS = 8


def wave(x, seed, amp=2.0):
    return amp * math.sin(x / 37.0 + seed) + 0.8 * math.sin(x / 13.0 + seed * 2.1)


def soil():
    rnd = random.Random(7)
    c = Canvas(640, WORLD_H)
    for x in range(640):
        g = SURF + round(0.7 * math.sin(x / 23.0) + 0.5 * math.sin(x / 7.3))
        b1 = B1 + round(wave(x, 1.0, 3))
        b2 = B2 + round(wave(x, 4.0, 3))
        for y in range(g - 1, WORLD_H):
            if y < b1 - TRANS // 2:
                v = 14
            elif y < b1 + TRANS // 2:
                t = (y - (b1 - TRANS // 2) + 0.5) / TRANS
                v = 13 if BAYER[y % 4][x % 4] < t * 16 else 14
            elif y < b2 - TRANS // 2:
                v = 13
            elif y < b2 + TRANS // 2:
                t = (y - (b2 - TRANS // 2) + 0.5) / TRANS
                v = 1 if BAYER[y % 4][x % 4] < t * 16 else 13
            else:
                v = 1
            c.set(x, y, v)

    def streaks(y0, y1, col, base, n):
        for _ in range(n):
            x = rnd.randrange(0, 620)
            y = rnd.randrange(y0, y1)
            L = rnd.randrange(6, 26)
            for i in range(L):
                if c.get(x + i, y) == base:
                    c.set(x + i, y, col)
    streaks(SURF + 10, B1 - 8, 13, 14, 70)
    streaks(B1 + 8, B2 - 8, 14, 13, 50)
    streaks(B1 + 8, B2 - 8, 1, 13, 14)
    streaks(B2 + 8, WORLD_H - 4, 13, 1, 50)
    # raizes finas decorativas (13 na faixa 14, 14 na faixa 13, 13 na faixa 01)
    for _ in range(46):
        x = rnd.uniform(10, 630)
        y = rnd.uniform(SURF + 30, WORLD_H - 40)
        ang = rnd.uniform(math.pi * 0.3, math.pi * 0.7)
        L = rnd.randrange(18, 60)
        for i in range(L):
            ang += rnd.uniform(-0.25, 0.25)
            ang = min(max(ang, 0.2), math.pi - 0.2)
            x += math.cos(ang) * 0.9
            y += math.sin(ang) * 0.9
            px, py = round(x), round(y)
            base = c.get(px, py)
            col = {14: 13, 13: 14, 1: 13}.get(base)
            if col:
                c.set(px, py, col)
            if rnd.random() < 0.04:   # radicela
                for k in range(1, rnd.randrange(3, 6)):
                    qx, qy = px + k * rnd.choice((-1, 1)) // 1, py + k
                    b2_ = c.get(qx, qy)
                    if b2_ in (14, 13, 1):
                        c.set(qx, qy, {14: 13, 13: 14, 1: 13}[b2_])
    PEB = {
        'p3': ["SV", "VI"],
        'p4': [".SV.", "SVVI", ".II."],
        'p5': [".SVV.", "SVVVI", ".VII."],
        'p6': ["..VVV.", ".SSVVV", "SVVVVI", ".VVIII", "..II.."],
    }
    occupied = []

    def pebbles(y0, y1, kinds, n, base):
        k = tries = 0
        while k < n and tries < n * 40:
            tries += 1
            x, y = rnd.randrange(4, 630), rnd.randrange(y0, y1)
            if abs(x - 320) < 50 and y < SURF + 50:
                continue
            if not all(abs(x - a) > 14 or abs(y - b) > 14 for a, b in occupied):
                continue
            rows = PEB[rnd.choice(kinds)]
            if any(c.get(x + i, y + j) not in base for j, r in enumerate(rows) for i, ch in enumerate(r) if ch != '.'):
                continue
            c.rows(x, y, rows)
            occupied.append((x, y))
            k += 1
    pebbles(SURF + 8, B1 - 6, ['p5', 'p6', 'p4'], 30, (13, 14))
    pebbles(B1 + 6, B2 - 6, ['p4', 'p5', 'p3'], 26, (13, 14, 1))
    pebbles(B2 + 6, WORLD_H - 6, ['p3', 'p4'], 20, (1, 13))
    return c


# ================================================================ particulas
def sheet(cells, cw, ch, cols):
    rows = math.ceil(len(cells) / cols)
    c = Canvas(cw * cols, ch * rows)
    for i, cell in enumerate(cells):
        c.blit(cell, (i % cols) * cw, (i // cols) * ch)
    return c


def cell_rows(w, h, rows, x0=0, y0=0):
    c = Canvas(w, h)
    c.rows(x0, y0, rows)
    return c


PETALS = [  # 4 formas x 2 frames (girando), celula 3x3
    (["LP.", "...", "..."], ["L..", "P..", "..."]),
    (["LL.", ".V.", "..."], [".L.", "LV.", "..."]),
    (["P..", ".L.", "..."], [".P.", ".L.", "..."]),
    ([".L.", "LV.", "..."], ["LV.", ".L.", "..."]),
]


def petals():
    cells = []
    for a, b in PETALS:
        cells += [cell_rows(3, 3, a), cell_rows(3, 3, b)]
    return sheet(cells, 3, 3, 2)


def firefly():
    f0 = cell_rows(3, 3, ["...", ".Z.", "..."])
    f1 = cell_rows(3, 3, [".Z.", "ZWZ", ".Z."])
    f2 = cell_rows(3, 3, ["...", ".W.", "..."])
    return sheet([f0, f1, f2], 3, 3, 3)


def soil_dust():
    return sheet([cell_rows(1, 1, ["U"]), cell_rows(1, 1, ["T"])], 1, 1, 2)


def worm():
    # 12x5, rastejando para a direita; corpo 2 px (20 em cima, 19 em baixo), cinta 19/18, cabeca a direita
    def body(xs, hump):
        c = Canvas(12, 5)
        pts = []
        for x in xs:
            y = 2 - (1 if x in hump else 0)
            top = 20 if x < xs[-1] else 20
            band = x in (xs[-1] - 3, xs[-1] - 2)
            pts.append((x, y, 19 if band else 20))
            pts.append((x, y + 1, 18 if band else 19))
        s = {(x, y) for x, y, _ in pts}
        for x, y, v in pts:
            c.set(x, y, v)
        for x, y, v in pts:
            for dx, dy in N4:
                q = (x + dx, y + dy)
                if q not in s and 0 <= q[0] < 12 and 0 <= q[1] < 5:
                    c.set(q[0], q[1], 1)
        return c
    f0 = body(list(range(1, 11)), [])
    f1 = body(list(range(2, 11)), [6, 7])
    f2 = body(list(range(3, 11)), [5, 6, 7, 8])
    f3 = body(list(range(3, 11)), [7])
    return sheet([f0, f1, f2, f3], 12, 5, 4)


def beetle():
    a = cell_rows(6, 5, [".KKK..", "KLSLK.", "KVVVKK", ".KKKK.", ".K.K.K"])
    b = cell_rows(6, 5, [".KKK..", "KLSLK.", "KVVVKK", ".KKKK.", "K.K.K."])
    return sheet([a, b], 6, 5, 2)


def sap():
    # 8x2, movendo para a direita; cabeca 2x2 (23/26) a direita, rastro 25/24 a esquerda
    f0 = cell_rows(8, 2, ["...y.YWZ", "..y..YZY"])
    f1 = cell_rows(8, 2, ["..y.Y.WZ", ".y..Y.ZY"])
    f2 = cell_rows(8, 2, [".y.y.YWW", "..y.YYWZ"])
    return sheet([f0, f1, f2], 8, 2, 3)


# ================================================================== efeitos
def burst():
    frames = []
    rnd = random.Random(4)
    parts = []
    for i in range(18):
        ang = i * math.pi * 2 / 18 + rnd.uniform(-0.15, 0.15)
        kind = 'spark' if i % 3 == 0 else 'petal'
        parts.append((ang, kind, rnd.uniform(0.85, 1.15), rnd.choice(((5, 8), (5, 4), (8, 5)))))
    radii = [0, 5, 9, 12, 14, 15]
    for f in range(6):
        c = Canvas(32, 32)
        cx = cy = 16
        if f == 0:
            for x, y in ((16, 14), (15, 15), (16, 15), (17, 15), (14, 16), (15, 16), (16, 16), (17, 16), (18, 16),
                         (15, 17), (16, 17), (17, 17), (16, 18)):
                c.set(x, y, 23)
            for x, y in ((16, 12), (16, 13), (12, 16), (13, 16), (19, 16), (20, 16), (16, 19), (16, 20)):
                c.set(x, y, 26)
        elif f == 1:
            for x, y in ((15, 15), (16, 15), (15, 16), (16, 16)):
                c.set(x, y, 26)
        for ang, kind, k, cols in parts:
            if f == 0:
                break
            r = radii[f] * k
            fall = max(0, f - 2) * 1.5 if kind == 'petal' else 0
            x = round(cx + math.cos(ang) * r)
            y = round(cy + math.sin(ang) * r + fall)
            if kind == 'spark':
                if f <= 2:
                    c.set(x, y, 23)
                    c.set(x - round(math.cos(ang)), y - round(math.sin(ang)), 26)
                elif f <= 4:
                    c.set(x, y, 26 if f == 3 else 25)
            else:
                a, b = cols
                if f <= 4:
                    c.set(x, y, a)
                    c.set(x + (1 if (f % 2) else 0), y + (0 if (f % 2) else 1), b)
                    if f <= 3:
                        c.set(x - (1 if (f % 2) else 0), y - (0 if (f % 2) else 1), 4)
                else:
                    c.set(x, y, 4)
        frames.append(c)
    return frames


def sprout():
    # 24x12, terrinha subindo e assentando + broto; sem contorno (efeito)
    F_ = []
    rows0 = ["........................"] * 9 + ["..........ubbu..........", ".........uUUUUu.........", "........tTTTTTTt........"]
    f0 = cell_rows(24, 12, rows0)
    for x, y, v in ((9, 6, 17), (14, 5, 16), (11, 4, 17), (13, 7, 15)):
        f0.set(x, y, v)
    f1 = cell_rows(24, 12, ["........................"] * 8 + ["...........HH...........", "..........uHbu..........",
                                                                 ".........uUUUUu.........", "........tTTTTTTt........"])
    for x, y, v in ((6, 3, 17), (17, 2, 16), (8, 1, 17), (15, 4, 15), (4, 6, 16), (19, 6, 17)):
        f1.set(x, y, v)
    f2 = cell_rows(24, 12, ["........................"] * 6 + ["..........H..H..........", "..........HhhH..........",
                                                                 "...........hh...........", "..........uhbu..........",
                                                                 ".........uUUUUu.........", "........tTTTTTTt........"])
    for x, y, v in ((4, 4, 17), (19, 3, 16), (6, 6, 16), (17, 7, 15), (2, 9, 17), (21, 9, 16)):
        f2.set(x, y, v)
    f3 = cell_rows(24, 12, ["........................"] * 6 + [".........HH..HH.........", "..........HhhH..........",
                                                                 "...........hh...........", "..........uhbu..........",
                                                                 "...b.....uUUUUu....u....", "..uUt...tTTTTTTt..bUt..."])
    return [f0, f1, f2, f3]


def bang():
    a = cell_rows(8, 10, ["..KKKK..", "..KZWK..", "..KZWK..", "..KZWK..", "..KZZK..", "..KYZK..", "..KKKK..",
                          "..KZZK..", "..KYYK..", "..KKKK.."])
    b = cell_rows(8, 10, ["..KKKK..", "..KWWK..", "..KWWK..", "..KZWK..", "..KZWK..", "..KZZK..", "..KKKK..",
                          "..KWZK..", "..KZZK..", "..KKKK.."])
    # frame 1 sobe 1 px (o '!' quica)
    b2 = Canvas(8, 10)
    for y in range(1, 10):
        for x in range(8):
            b2.px[y - 1][x] = b.px[y][x]
    return [a, b2]


# ========================================================== JSON (Aseprite Array)
def write_json(path, image_name, sheet_w, sheet_h, frames, tags):
    """frames: lista de (nome, x, y, w, h, dur)"""
    data = {
        'frames': [{
            'filename': n, 'frame': {'x': x, 'y': y, 'w': w, 'h': h}, 'rotated': False, 'trimmed': False,
            'spriteSourceSize': {'x': 0, 'y': 0, 'w': w, 'h': h}, 'sourceSize': {'w': w, 'h': h}, 'duration': d}
            for n, x, y, w, h, d in frames],
        'meta': {'app': 'https://www.aseprite.org/', 'version': '1.3', 'image': image_name, 'format': 'I8',
                 'size': {'w': sheet_w, 'h': sheet_h}, 'scale': '1',
                 'frameTags': [{'name': n, 'from': a, 'to': b, 'direction': d, 'color': '#000000ff'} for n, a, b, d in tags],
                 'layers': [], 'slices': []}}
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=1, ensure_ascii=False)


def grid_frames(prefix, cw, ch, cols, n, durs):
    out = []
    for i in range(n):
        out.append(('%s %d' % (prefix, i), (i % cols) * cw, (i // cols) * ch, cw, ch, durs[i % len(durs)]))
    return out


# ===================================================================== GIFs
def gif(frames, durs, path, scale=4, bg=2, pad=2):
    w, h = frames[0].w + 2 * pad, frames[0].h + 2 * pad
    ims = []
    for fr in frames:
        c = Canvas(w, h, bg)
        c.blit(fr, pad, pad)
        ims.append(c.to_rgba(scale).convert('RGB').convert('P', palette=Image.ADAPTIVE))
    ims[0].save(path, save_all=True, append_images=ims[1:], duration=durs, loop=0, disposal=2)
