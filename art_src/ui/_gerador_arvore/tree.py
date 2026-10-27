import math
import random
from PIL import Image
from common import Canvas, PAL
import icons as IC
import font5x7 as F

ROOT = r'C:\Users\pedro\Documents\projects\dig-dig-graves'
OUT = ROOT + r'\assets\ui\tree'
PREV = ROOT + r'\art_src\_previews'

# ---------------------------------------------------------------- medalhoes
PROFILE = [4, 2, 1, 1]


def med_mask(x, y):
    if y < 4:
        ins = PROFILE[y]
    elif y > 19:
        ins = PROFILE[23 - y]
    else:
        ins = 0
    return ins <= x <= 23 - ins


STUDS = [(11, 1), (12, 1), (11, 2), (12, 2), (11, 21), (12, 21), (11, 22), (12, 22),
         (1, 11), (1, 12), (2, 11), (2, 12), (21, 11), (21, 12), (22, 11), (22, 12)]


def medallion(base, acc, mode='normal'):
    """Moldura 24x24: contorno 01, aro de 2 px (base + acento no lado iluminado),
    filete interno 01 e espaco 16x16 (4..19) em 03 para o icone."""
    c = Canvas(24, 24)
    inside = lambda x, y: 0 <= x < 24 and 0 <= y < 24 and med_mask(x, y)
    ring0 = set()
    for y in range(24):
        for x in range(24):
            if inside(x, y) and any(not inside(x + dx, y + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                ring0.add((x, y))
    ring3 = set()
    for t in range(3, 21):
        for p in ((t, 3), (t, 20), (3, t), (20, t)):
            ring3.add(p)
    for p in ((3, 3), (20, 3), (3, 20), (20, 20)):
        ring3.discard(p)
    for y in range(24):
        for x in range(24):
            if not inside(x, y):
                continue
            if (x, y) in ring0:
                c.set(x, y, 1)
            elif (x, y) in ring3:
                c.set(x, y, 24 if mode == 'max' else 1)
            elif 4 <= x <= 19 and 4 <= y <= 19:
                c.set(x, y, 3)
            else:
                outer = any((x + dx, y + dy) in ring0 for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
                lit = (x + y) < 23
                if mode == 'lunar':
                    v = base if outer else acc
                elif mode == 'max':
                    v = 23 if (outer and lit and (x + y) < 10) else base
                else:
                    v = acc if (outer and lit) else base
                c.set(x, y, v)
    if mode != 'max':
        for x, y in STUDS:
            c.set(x, y, acc)
    return c


STAR = ["..Z..",
        "ZZWZZ",
        ".ZZZ.",
        ".Z.Z."]


def med_max():
    c = medallion(26, 26, 'max')
    # estrela no topo, centrada (x 10..14 / y 0..3) com contorno 01
    star = Canvas(24, 24)
    star.rows(10, 0, STAR)
    pts = [(x, y) for y in range(24) for x in range(24) if star.px[y][x]]
    s = set(pts)
    for x, y in pts:
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            q = (x + dx, y + dy)
            if q not in s:
                c.set(q[0], q[1], 1)
    for x, y in pts:
        c.set(x, y, star.px[y][x])
    return c


QMARK = [".LLLL.",
         "LL..LL",
         "....LL",
         "...LL.",
         "..LL..",
         "..LL..",
         "......",
         "..LL.."]


def med_hidden():
    c = Canvas(24, 24)
    for y in range(24):
        for x in range(24):
            if med_mask(x, y):
                edge = any(not (0 <= x + dx < 24 and 0 <= y + dy < 24 and med_mask(x + dx, y + dy))
                           for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
                c.set(x, y, 1 if edge else 2)
    c.rows(9, 8, QMARK)
    return c


BRANCHES = [('escavacao', 16, 17), ('lanterna', 25, 26), ('fortuna', 26, 23), ('cemiterio', 11, 12),
            ('ajudantes', 5, 6), ('almas', 30, 23), ('lunar', 8, 26)]


def build_medallions():
    cells = [medallion(b, a, 'lunar' if n == 'lunar' else 'normal') for n, b, a in BRANCHES]
    cells += [med_hidden(), med_max()]
    atlas = Canvas(24 * len(cells), 24)
    for i, c in enumerate(cells):
        atlas.blit(c, 24 * i, 0)
    return atlas, cells


# ------------------------------------------------------------------- raizes
ROOT_SPEC = {  # (brilho, miolo, sombra)
    'off': (19, 18, 1),
    'on': (17, 20, 19),
}


def root_strip(state):
    hi, mid, sh = ROOT_SPEC[state]
    c = Canvas(8, 4)
    for x in range(8):
        c.set(x, 0, hi)
        c.set(x, 1, mid)
        c.set(x, 2, mid)
        c.set(x, 3, sh)
    c.set(5, 1, hi)   # veio claro da casca
    c.set(1, 2, sh)   # fenda escura
    return c


def draw_root(cv, pts, state):
    """pts: polilinha (centro). Pinta sombra, brilho e miolo de 2 px."""
    hi, mid, sh = ROOT_SPEC[state]
    path = []
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        n = int(max(abs(x1 - x0), abs(y1 - y0))) * 2 + 1
        for i in range(n + 1):
            t = i / n
            path.append((round(x0 + (x1 - x0) * t), round(y0 + (y1 - y0) * t), abs(x1 - x0) >= abs(y1 - y0)))
    layers = {'sh': [], 'hi': [], 'mid': []}
    for x, y, shallow in path:
        if shallow:
            layers['mid'] += [(x, y), (x, y + 1)]
            layers['hi'].append((x, y - 1))
            layers['sh'].append((x, y + 2))
        else:
            layers['mid'] += [(x, y), (x + 1, y)]
            layers['hi'].append((x - 1, y))
            layers['sh'].append((x + 2, y))
    mids = set(layers['mid'])
    for p in layers['sh']:
        if p not in mids:
            cv.set(p[0], p[1], sh)
    for p in layers['hi']:
        if p not in mids:
            cv.set(p[0], p[1], hi)
    for p in layers['mid']:
        cv.set(p[0], p[1], mid)


def curve(a, b, bend=0.15, steps=6):
    (x0, y0), (x1, y1) = a, b
    mx, my = (x0 + x1) / 2, (y0 + y1) / 2
    dx, dy = x1 - x0, y1 - y0
    cx, cy = mx - dy * bend, my + dx * bend
    pts = []
    for i in range(steps + 1):
        t = i / steps
        x = (1 - t) ** 2 * x0 + 2 * (1 - t) * t * cx + t * t * x1
        y = (1 - t) ** 2 * y0 + 2 * (1 - t) * t * cy + t * t * y1
        pts.append((x, y))
    return pts


# -------------------------------------------------------------------- fundo
BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]
SURF = 50          # topo do solo (linha da grama)
B1 = 142           # 14 -> 13
B2 = 246           # 13 -> 01
TRANS = 8          # altura da faixa de dithering


def wave(x, seed, amp=2.0):
    return amp * math.sin(x / 37.0 + seed) + 0.8 * math.sin(x / 13.0 + seed * 2.1)


def background():
    rnd = random.Random(7)
    c = Canvas(640, 360, 2)
    # --- solo em faixas
    for x in range(640):
        g = SURF + round(0.7 * math.sin(x / 23.0) + 0.5 * math.sin(x / 7.3))
        b1 = B1 + round(wave(x, 1.0, 3))
        b2 = B2 + round(wave(x, 4.0, 3))
        for y in range(g, 360):
            if y < b1 - TRANS // 2:
                v = 14
            elif y < b1 + TRANS // 2:
                t = (y - (b1 - TRANS // 2) + 0.5) / TRANS  # 0..1 -> mais escuro
                v = 13 if BAYER[y % 4][x % 4] < t * 16 else 14
            elif y < b2 - TRANS // 2:
                v = 13
            elif y < b2 + TRANS // 2:
                t = (y - (b2 - TRANS // 2) + 0.5) / TRANS
                v = 1 if BAYER[y % 4][x % 4] < t * 16 else 13
            else:
                v = 1
            c.set(x, y, v)
    # --- estratos (tracos horizontais de 1 px, cor da faixa de baixo)
    def streaks(y0, y1, col, base, n):
        for _ in range(n):
            x = rnd.randrange(0, 620)
            y = rnd.randrange(y0, y1)
            L = rnd.randrange(6, 26)
            for i in range(L):
                if c.get(x + i, y) == base:
                    c.set(x + i, y, col)
    streaks(SURF + 8, B1 - 8, 13, 14, 45)
    streaks(B1 + 8, B2 - 8, 14, 13, 30)
    streaks(B1 + 8, B2 - 8, 1, 13, 8)
    streaks(B2 + 8, 356, 13, 1, 25)
    # --- pedrinhas (06 com sombra 05/04), menores e mais raras para baixo
    PEB = {
        'p3': ["SV", "VI"],
        'p4': [".SV.", "SVVI", ".II."],
        'p5': [".SVV.", "SVVVI", ".VII."],
        'p2': ["S", "V"],
        'p6': ["..VVV.", ".SSVVV", "SVVVVI", ".VVIII", "..II.."],
    }
    occupied = []

    def free(x, y, r=14):
        return all(abs(x - a) > r or abs(y - b) > r for a, b in occupied)

    def pebbles(y0, y1, kinds, n, base):
        k = 0
        tries = 0
        while k < n and tries < n * 30:
            tries += 1
            x = rnd.randrange(4, 630)
            y = rnd.randrange(y0, y1)
            if abs(x - 320) < 40 and y < 70:
                continue
            if not free(x, y):
                continue
            rows = PEB[rnd.choice(kinds)]
            if any(c.get(x + i, y + j) not in base for j, r in enumerate(rows) for i, ch in enumerate(r) if ch != '.'):
                continue
            c.rows(x, y, rows)
            occupied.append((x, y))
            k += 1
    pebbles(SURF + 6, B1 - 6, ['p5', 'p6', 'p5'], 16, (13, 14))
    pebbles(B1 + 6, B2 - 6, ['p4', 'p5', 'p3'], 13, (13, 1))
    pebbles(B2 + 6, 356, ['p3', 'p4'], 9, (1, 13))
    # --- grama da superficie
    for x in range(640):
        g = SURF + round(0.7 * math.sin(x / 23.0) + 0.5 * math.sin(x / 7.3))
        c.set(x, g - 1, 10)
        c.set(x, g, 10)
        c.set(x, g + 1, 9)
        if rnd.random() < 0.18:
            c.set(x, g + 2, 9)
        r = rnd.random()
        if r < 0.22:
            c.set(x, g - 2, 10)
            if r < 0.07:
                c.set(x, g - 3, 11)
            else:
                c.set(x, g - 2, 11)
        elif r < 0.30:
            c.set(x, g - 2, 10)
    # --- ceu: estrelinhas discretas (05) e lapides ao longe (04/05)
    for _ in range(28):
        x, y = rnd.randrange(0, 640), rnd.randrange(2, SURF - 8)
        if 150 < x < 490 and y < 26:
            continue
        c.set(x, y, 5 if rnd.random() < 0.4 else 4)
    TOMB = [".VVV.", "VLVVV", "VLVVV", "VLVVV", "VLVVV"]
    CROSS = [".c.", "cCc", ".C.", ".C.", ".C."]
    for (x, kind) in [(58, TOMB), (92, CROSS), (126, TOMB), (520, TOMB), (556, CROSS), (590, TOMB)]:
        rows = kind
        g = SURF + round(0.7 * math.sin(x / 23.0) + 0.5 * math.sin(x / 7.3))
        c.rows(x, g - 1 - len(rows), rows)
    # --- tronco do ipe-roxo velho (18/19/20), saindo da superficie
    def trunk_half(y):
        # meia largura: 14 no topo da tela, alarga na base
        t = y / SURF
        return 13 + round(10 * t ** 3)
    for y in range(0, SURF + 2):
        hw = trunk_half(y)
        sway = round(1.5 * math.sin(y / 9.0))
        x0, x1 = 320 - hw + sway, 320 + hw + sway
        for x in range(x0, x1 + 1):
            u = (x - x0) / max(1, x1 - x0)
            if u < 0.12:
                v = 20
            elif u < 0.62:
                v = 19
            else:
                v = 18
            c.set(x, y, v)
        c.set(x0 - 1, y, 1)
        c.set(x1 + 1, y, 1)
    # veios da casca
    for (bx, y0, y1) in [(-6, 0, 30), (1, 6, 42), (7, 0, 22), (-2, 26, 48), (10, 28, 50), (-9, 36, 51), (4, 44, 51)]:
        for y in range(y0, y1):
            sway = round(1.5 * math.sin(y / 9.0))
            x = 320 + bx + sway + (1 if (y // 7) % 2 else 0)
            if c.get(x, y) in (19, 20):
                c.set(x, y, 18)
    # oco / no na casca
    c.rows(325, 20, [".cc.", "cKKc", "cKKc", ".cC."])
    # raizes grossas da base entrando no solo (afinando)
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
                    c.set(xx, round(y), v)
                    c.set(xx, round(y) + 1, 18 if v != 20 else 19)
    flare([(304, SURF), (292, SURF + 8), (276, SURF + 13), (262, SURF + 16)], 4)
    flare([(336, SURF), (348, SURF + 7), (364, SURF + 12), (378, SURF + 14)], 4)
    flare([(320, SURF), (321, SURF + 12), (320, SURF + 24), (320, SURF + 30)], 5)
    flare([(310, SURF + 2), (306, SURF + 14), (300, SURF + 20)], 2)
    # contorno 01 nas raizes grossas sobre o solo
    soil = (13, 14, 1)
    add = []
    for y in range(SURF - 1, SURF + 40):
        for x in range(240, 400):
            if c.get(x, y) in (18, 19, 20):
                for dx, dy in ((0, 1), (1, 0), (-1, 0)):
                    if c.get(x + dx, y + dy) in (13, 14, 9, 10):
                        add.append((x + dx, y + dy))
    for x, y in add:
        c.set(x, y, 1)
    # --- copa: galhos (18) + cachos de flor do ipe-roxo (04/05)
    def branch(x0, y0, x1, y1):
        n = max(abs(x1 - x0), abs(y1 - y0))
        for i in range(n + 1):
            t = i / max(1, n)
            x = round(x0 + (x1 - x0) * t)
            y = round(y0 + (y1 - y0) * t)
            c.set(x, y, 18)
            c.set(x, y + 1, 18)
    branch(312, 10, 262, 0)
    branch(330, 8, 384, 0)
    branch(304, 16, 220, 4)
    branch(338, 15, 424, 3)
    branch(296, 22, 250, 14)
    branch(346, 20, 396, 12)
    # copa: massa de cachos (uniao de discos), 05 no lado NO de cada cacho, 04 no resto,
    # bordas recortadas em florzinhas; buracos 03 deixam ver o ceu/galhos
    blobs = []
    for _ in range(110):
        x = rnd.uniform(110, 530)
        dist = abs(x - 320) / 210.0
        y = rnd.uniform(-10, 4 + 22 * (1 - dist ** 2))
        r = rnd.uniform(6, 11) * (1.2 - 0.5 * dist)
        blobs.append((x, y, r))
    blobs.sort(key=lambda b: b[1])
    canopy = {}
    for bx, by, r in blobs:
        for y in range(int(by - r - 1), int(by + r + 2)):
            for x in range(int(bx - r - 1), int(bx + r + 2)):
                d = math.hypot(x - bx, (y - by) * 1.25)
                if d <= r:
                    lit = ((x - bx) + (y - by) * 1.25) < -r * 0.35
                    canopy[(x, y)] = 5 if lit else 4
    for (x, y), v in canopy.items():
        if 0 <= y < SURF - 4:
            c.set(x, y, v)
    # recorte da borda: pontinhas de flor e falhas
    for (x, y), v in list(canopy.items()):
        if not (0 <= y < SURF - 4):
            continue
        edge = any((x + dx, y + dy) not in canopy for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
        if edge:
            r = rnd.random()
            if r < 0.30:
                c.set(x, y, 2)            # falha
            elif r < 0.42 and (x, y + 1) not in canopy:
                c.set(x, y + 1, 4)        # florzinha pendente
    # cachos claros (05) e miolos escuros (03) espalhados dentro da copa
    keys = [k for k in canopy if 0 <= k[1] < SURF - 4]
    for _ in range(320):
        x, y = rnd.choice(keys)
        if c.get(x, y) == 4:
            c.set(x, y, 5)
            if c.get(x + 1, y) == 4:
                c.set(x + 1, y, 5)
    for _ in range(120):
        x, y = rnd.choice(keys)
        if c.get(x, y) in (4, 5) and c.get(x + 1, y + 1) in (4, 5):
            c.set(x + 1, y + 1, 3)
    # sombra 03 sob a copa em alguns pontos e flores caidas na grama
    for _ in range(26):
        x = round(rnd.gauss(320, 90))
        if abs(x - 320) < 30:
            continue
        g = SURF + round(0.7 * math.sin(x / 23.0) + 0.5 * math.sin(x / 7.3))
        c.set(x, g - 1, 5)
        if rnd.random() < 0.4:
            c.set(x + 1, g - 1, 4)
    return c


# --------------------------------------------------------------------- mock
def nine_slice(cv, src, x, y, w, h, m=8):
    sw, sh = src.size
    def px(sx, sy):
        return src.getpixel((sx, sy))
    for yy in range(h):
        if yy < m:
            sy = yy
        elif yy >= h - m:
            sy = sh - (h - yy)
        else:
            sy = m + (yy - m) % (sh - 2 * m)
        for xx in range(w):
            if xx < m:
                sx = xx
            elif xx >= w - m:
                sx = sw - (w - xx)
            else:
                sx = m + (xx - m) % (sw - 2 * m)
            v = px(sx, sy)
            if v:
                cv.set(x + xx, y + yy, v)


def mock(bg, cells, icons):
    cv = Canvas(640, 360)
    cv.blit(bg, 0, 0)
    BR = {name: i for i, (name, _, _) in enumerate(BRANCHES)}
    MAXC, HIDC = 8, 7
    nodes = {
        'N00': ((320, 96), 'max', 'escavacao'),
        'N02': ((320, 148), 'max', 'escavacao'),
        'E01': ((246, 132), 'part', 'escavacao', 3, 10),
        'L01': ((394, 132), 'part', 'lanterna', 4, 10),
        'E02': ((182, 170), 'avail', 'escavacao', 25),
        'L02': ((458, 170), 'poor', 'lanterna', 80),
        'N01': ((320, 200), 'avail', 'escavacao', 50),
        'C01': ((256, 242), 'avail', 'cemiterio', 30),
        'F01': ((384, 242), 'avail', 'fortuna', 20),
        'H1': ((132, 220), 'hidden', None),
        'H2': ((508, 220), 'hidden', None),
    }
    edges = [('N00', 'E01', 'on', .12), ('N00', 'L01', 'on', -.12), ('N00', 'N02', 'on', .05),
             ('E01', 'E02', 'off', .1), ('L01', 'L02', 'off', -.1), ('N02', 'N01', 'off', -.08),
             ('N01', 'C01', 'off', .12), ('N01', 'F01', 'off', -.12),
             ('E02', 'H1', 'off', .15), ('L02', 'H2', 'off', -.15)]
    # raiz principal do tronco ate a Pa Velha
    draw_root(cv, [(319, SURF + 28), (319, 90)], 'on')
    for a, b, st, bend in edges:
        draw_root(cv, curve(nodes[a][0], nodes[b][0], bend), st)
    for nid, info in nodes.items():
        (x, y), st, br = info[0], info[1], info[2]
        x0, y0 = x - 12, y - 12
        if st == 'hidden':
            cv.blit(cells[HIDC], x0, y0)
            continue
        cv.blit(cells[MAXC] if st == 'max' else cells[BR[br]], x0, y0)
        cv.blit(icons[nid], x0 + 4, y0 + 4)
        if st == 'part':
            lv, mx = info[3], info[4]
            bw = 2
            total = mx * (bw + 1) - 1
            bx = x - total // 2
            cv.rect(bx - 1, y + 13, total + 2, 5, 1)
            for i in range(mx):
                cv.rect(bx + i * (bw + 1), y + 14, bw, 3, 26 if i < lv else 4)
        if st in ('avail', 'poor'):
            txt = str(info[3])
            w = F.width(txt)
            F.draw(cv, x - w // 2, y + 14, txt, 22 if st == 'avail' else 32, outline=1)
    # foco no E02 (cursor de selecao em 26)
    fx, fy = nodes['E02'][0]
    for (cx, cy, dx, dy) in [(fx - 14, fy - 14, 1, 1), (fx + 13, fy - 14, -1, 1),
                             (fx - 14, fy + 13, 1, -1), (fx + 13, fy + 13, -1, -1)]:
        for k in range(3):
            cv.set(cx + dx * k, cy, 26)
            cv.set(cx, cy + dy * k, 26)
    # painel inferior (pergaminho)
    parch = Image.open(ROOT + r'\assets\ui\panels\panel_parchment.png')
    wood = Image.open(ROOT + r'\assets\ui\panels\panel_wood.png')
    px, py, pw, ph = 8, 296, 624, 56
    nine_slice(cv, parch, px, py, pw, ph)
    # icone do no em foco dentro do painel
    cv.blit(cells[BR['escavacao']], px + 10, py + 10)
    cv.blit(icons['E02'], px + 14, py + 14)
    F.draw(cv, px + 42, py + 11, 'BRAÇO FIRME', 1)
    F.draw(cv, px + 42 + F.width('BRAÇO FIRME') + 10, py + 11, 'NV 0/8', 14)
    F.draw(cv, px + 42, py + 23, '-6% NO INTERVALO DO GOLPE', 14)
    F.draw(cv, px + 42, py + 35, 'INTERVALO: 1,00S ~ 0,94S', 1)
    # custo a direita
    res = Image.open(ROOT + r'\assets\ui\icons\icons_res.png')
    coin = Canvas(16, 16)
    for yy in range(16):
        for xx in range(16):
            coin.px[yy][xx] = res.getpixel((xx, yy))
    cw = F.width('CUSTO 25')
    F.draw(cv, px + pw - 30 - cw, py + 22, 'CUSTO 25', 1)
    cv.blit(coin, px + pw - 26, py + 18)
    # botao Cavar
    bx, by, bw_, bh = 548, 8, 84, 24
    nine_slice(cv, wood, bx, by, bw_, bh)
    tw = F.width('CAVAR >')
    F.draw(cv, bx + (bw_ - tw) // 2, by + 9, 'CAVAR >', 22, outline=1)
    # recursos no canto esquerdo
    cv.blit(coin, 8, 8)
    F.draw(cv, 28, 13, '1.234', 22, outline=1)
    bone = Canvas(16, 16)
    for yy in range(16):
        for xx in range(16):
            bone.px[yy][xx] = res.getpixel((16 + xx, yy))
    cv.blit(bone, 66, 8)
    F.draw(cv, 86, 13, '56', 22, outline=1)
    return cv


def grey(im):
    return im.convert('L').convert('RGB')


if __name__ == '__main__':
    import os
    os.makedirs(OUT, exist_ok=True)
    icons = IC.build_all()
    # atlas de icones: 8 colunas x 4 linhas (25 usados)
    atlas = Canvas(16 * 8, 16 * 4)
    for i, k in enumerate(IC.ORDER):
        atlas.blit(icons[k], (i % 8) * 16, (i // 8) * 16)
    atlas.save(OUT + r'\node_icons.png')
    med, cells = build_medallions()
    med.save(OUT + r'\medallions.png')
    roots = Canvas(8, 8)
    roots.blit(root_strip('off'), 0, 0)
    roots.blit(root_strip('on'), 0, 4)
    roots.save(OUT + r'\roots.png')
    root_strip('off').save(OUT + r'\roots_off.png')
    root_strip('on').save(OUT + r'\roots_on.png')
    bg = background()
    bg.save(OUT + r'\tree_bg.png')
    m = mock(bg, cells, icons)
    m.to_rgba(1).save(PREV + r'\tree_mock_640x360.png')
    m.to_rgba(2).save(PREV + r'\tree_mock_2x.png')
    grey(m.to_rgba(2)).save(PREV + r'\tree_mock_cinza_2x.png')
    # folha 4x: icones coloridos (linha de cima) e silhuetas 01 sobre 03
    cols = 9
    rows_ = math.ceil(len(IC.ORDER) / cols)
    sheet = Canvas(cols * 20 + 2, rows_ * 2 * 20 + 2, 3)
    for i, k in enumerate(IC.ORDER):
        x = 2 + (i % cols) * 20
        y = 2 + (i // cols) * 40
        sheet.blit(icons[k], x, y)
        sil = Canvas(16, 16)
        for yy in range(16):
            for xx in range(16):
                sil.px[yy][xx] = 1 if icons[k].px[yy][xx] else 0
        sheet.blit(sil, x, y + 20)
    sheet.to_rgba(4).save(PREV + r'\tree_icons_4x.png')
    # icones dentro dos medalhoes do ramo, 1x e 4x
    BR = {'N': 0, 'E': 0, 'L': 1, 'F': 2, 'C': 3, 'A': 4, 'S': 5}
    ms = Canvas(len(IC.ORDER) * 26 + 2, 28, 2)
    for i, k in enumerate(IC.ORDER):
        ms.blit(cells[BR[k[0]]], 2 + i * 26, 2)
        ms.blit(icons[k], 6 + i * 26, 6)
    ms.to_rgba(1).save(PREV + r'\tree_medalhoes_icones_1x.png')
    ms.to_rgba(3).save(PREV + r'\tree_medalhoes_icones_3x.png')
    # pecas: medalhoes + raizes a 6x
    pc = Canvas(9 * 26 + 2, 50, 2)
    for i, cc in enumerate(cells):
        pc.blit(cc, 2 + i * 26, 2)
    draw_root(pc, [(4, 36), (60, 36)], 'off')
    draw_root(pc, [(70, 32), (110, 46)], 'off')
    draw_root(pc, [(120, 36), (176, 36)], 'on')
    draw_root(pc, [(186, 30), (200, 46)], 'on')
    pc.blit(root_strip('off'), 214, 34)
    pc.blit(root_strip('on'), 224, 34)
    pc.to_rgba(6).save(PREV + r'\tree_pecas_6x.png')
    print('ok')
