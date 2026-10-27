"""Fundo do Turno v2 (docs/03_UI_UX.md §5, revisao 1.1): clareira de cemiterio na mata escura.

Tres camadas de 672x392 (640x360 + 16 px de folga por lado), desenhadas em (-16, -16):
  chao  -> cor-base escura lisa, textura minima, trilhas de terra batida que somem no centro;
  props -> cerquinha, lapides/cruzes, tumulo com cercadinho, velas, arbustos, crisantemos;
  mata  -> moldura de copas e troncos (2 frames de balanco) + 1 arvore seca.
Tudo em indices da Lua de Cova 32 (0 = transparente). Todas as coordenadas daqui sao de TELA
(o canvas da camada comeca em (-16, -16)); a classe Layer faz a conversao."""
import math
import random

from common import Canvas, LEG

PAD = 16
W, H = 640 + 2 * PAD, 360 + 2 * PAD
X0, Y0, X1, Y1 = -PAD, -PAD, 640 + PAD, 360 + PAD      # faixa de tela coberta pelas camadas

# --------------------------------------------------------------------------- zona livre
# Maior campo (18x18 tiles de 32x16) centrado em (320, 180): losango de semi-eixos 288 x 144,
# mais o bloco de terra (24 px) pendurado nas duas arestas de baixo.
FIELD_C = (320, 180)
FIELD_A, FIELD_B, BLOCK_H = 288, 144, 24

# Plaquetas do HUD (mock do Turno): (x0, y0, x1, y1) de tela.
HUD = [(6, 6, 176, 30), (232, 6, 414, 30), (494, 6, 634, 30), (174, 328, 464, 354), (514, 330, 634, 354)]


def field_norm(x, y):
    """norma de losango do maior campo, com o bloco: <= 1 = dentro."""
    dx = abs(x - FIELD_C[0]) / FIELD_A
    dy = y - FIELD_C[1]
    if dy > 0:
        dy = max(0.0, dy - BLOCK_H)            # o bloco estica a metade de baixo
    return dx + abs(dy) / FIELD_B


def in_zone(x, y, margin=0):
    """dentro do maior campo + bloco, com margem (px) para fora."""
    dx = abs(x - FIELD_C[0])
    dy = y - FIELD_C[1]
    if dy > 0:
        dy = max(0, dy - BLOCK_H)
    return dx / (FIELD_A + 2 * margin) + abs(dy) / (FIELD_B + margin) <= 1.0


def near_hud(x, y, pad=4):
    return any(x0 - pad <= x <= x1 + pad and y0 - pad <= y <= y1 + pad for (x0, y0, x1, y1) in HUD)


def bayer(x, y):
    m = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]
    return m[y % 4][x % 4]


class Layer(Canvas):
    """Canvas 672x392 enderecado em coordenadas de tela."""

    def __init__(self):
        super().__init__(W, H)
        self.hgt = {}            # (x, y) de tela -> altura acima do chao (para a sombra projetada)

    def g(self, x, y):
        return self.get(x + PAD, y + PAD)

    def s(self, x, y, v, h=None):
        self.set(x + PAD, y + PAD, v)
        if h is not None:
            self.hgt[(x, y)] = h

    def screen_rows(self, x0, y0, rows, base_y=None):
        """carimba um mapa de caracteres (legenda do common) com o canto em (x0, y0) de tela;
        base_y = linha do chao (para registrar a altura de cada pixel)."""
        for j, row in enumerate(rows):
            for i, ch in enumerate(row):
                v = LEG[ch]
                if v:
                    self.s(x0 + i, y0 + j, v, None if base_y is None else base_y - (y0 + j))


# --------------------------------------------------------------------------- mata: arvores
LIGHT = (-0.55, -0.62, 0.56)        # direcao da lua (NO, do alto), normalizada aprox.

# copas: c = (cx, cy, r) (elipse r x 0,85r); base = pe do tronco (None = so folhagem);
# w = largura do tronco na base; bend = tortura; low = mato baixo do primeiro plano (mais escuro)
TREES = [
    # canto de cima, esquerda (o mais denso)
    dict(c=(182, -22, 40), base=(192, 20), w=6, bend=2, seed=13),
    dict(c=(96, -16, 54), base=(114, 50), w=9, bend=4, seed=12),
    dict(c=(-8, 14, 60), base=(24, 96), w=10, bend=-4, seed=11),
    dict(c=(54, 62, 30), base=(64, 106), w=6, bend=3, seed=15),
    dict(c=(-34, 112, 44), base=(-2, 164), w=8, bend=4, seed=14),
    # faixa do topo (atras da plaqueta do meio): massa baixa, sem tronco
    dict(c=(262, -26, 40), base=None, seed=21),
    dict(c=(336, -32, 46), base=None, seed=22),
    dict(c=(410, -26, 42), base=None, seed=23),
    # canto de cima, direita
    dict(c=(474, -26, 36), base=None, seed=34),
    dict(c=(554, -18, 46), base=(544, 40), w=7, bend=-3, seed=31),
    dict(c=(654, 16, 62), base=(628, 96), w=10, bend=5, seed=32),
    dict(c=(606, 80, 26), base=(598, 118), w=6, bend=-2, seed=35),
    dict(c=(692, 120, 46), base=(664, 186), w=8, bend=-4, seed=33),
    # laterais e cantos de baixo: mato baixo (primeiro plano, sem tronco)
    dict(c=(-30, 222, 30), base=None, seed=45, low=True),
    dict(c=(-26, 300, 46), base=None, seed=41, low=True),
    dict(c=(36, 388, 54), base=None, seed=42, low=True),
    dict(c=(676, 222, 26), base=None, seed=46, low=True),
    dict(c=(688, 292, 46), base=None, seed=43, low=True),
    dict(c=(618, 392, 58), base=None, seed=44, low=True),
]
DEAD = dict(base=(500, 104), seed=51)      # arvore seca (galhos) no canto de cima, direita
MARGIN = 6                                  # folga entre a mata e o maior campo


def _rxry(t):
    cx, cy, r = t['c']
    return cx, cy, r, r * (0.85 if not t.get('low') else 0.7)


def crown_blobs(t):
    cx, cy, rx, ry = _rxry(t)
    rnd = random.Random(t['seed'])
    blobs = []
    tries = 0
    n = int(rx * ry / 13)
    while len(blobs) < n and tries < 8000:
        tries += 1
        x = rnd.uniform(cx - rx, cx + rx)
        y = rnd.uniform(cy - ry, cy + ry)
        e = ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2
        if e > 1.0:
            continue
        r = rnd.uniform(5.0, 9.0) * (1.1 - 0.35 * e)
        if t.get('low'):
            r *= 0.8
        bad = False
        for k in range(12):
            a = 2 * math.pi * k / 12
            if in_zone(x + r * math.cos(a), y + r * math.sin(a) / 1.2, MARGIN):
                bad = True
                break
        if bad:
            continue
        blobs.append((x, y, r, rnd.random()))
    blobs.sort(key=lambda b: (b[1] + b[2], b[0]))
    return blobs


def trunk_pixels(t):
    """tronco torto da base ate o meio da copa: {(x, y): cor}. Luar 03 no lado NO, 02, sombra 01."""
    bx, by = t['base']
    cx, cy, rx, ry = _rxry(t)
    top = int(cy + ry * 0.3)
    w0 = t['w']
    out = {}
    if top >= by - 4:
        top = by - 6
    n = by - top
    for y in range(top, by + 1):
        s = (by - y) / n                      # 0 na base, 1 no topo
        xc = bx + (cx - bx) * s ** 1.5 + t['bend'] * math.sin(math.pi * s)
        hw = (w0 / 2) * (1 - 0.35 * s) + 2.2 * max(0.0, 1 - s * 6) ** 2    # alarga na raiz
        xa, xb = round(xc - hw), round(xc + hw) - 1
        for x in range(xa, xb + 1):
            v = 2
            if x == xa:
                v = 3                          # recorte de luar (lado NO)
            elif x >= xb - (1 if w0 >= 7 else 0):
                v = 1                          # lado da sombra
            out[(x, y)] = v
    # casca: estrias verticais 01 curtas
    rnd = random.Random(t['seed'] * 7)
    keys = sorted(k for k, v in out.items() if v == 2)
    for k in range(len(keys) // 16):
        x, y = keys[rnd.randrange(len(keys))]
        for d in range(rnd.choice((2, 3, 3, 4))):
            if out.get((x, y + d)) == 2:
                out[(x, y + d)] = 1
    # raizes: dedos saindo pelo chao (02, luar 03 do lado esq.)
    row = [x for (x, y) in out if y == by]
    for side, ln in ((-1, 4 + w0 // 4), (1, 3 + w0 // 4)):
        xs = min(row) if side < 0 else max(row)
        for k in range(1, ln):
            x = xs + side * k
            y = by - 1 + (k + 1) // 2 if side > 0 else by - 1 + (k + 1) // 3
            out[(x, y)] = (3 if side < 0 else 2) if k < ln - 2 else 1
            if k < ln // 2:
                out[(x, y + 1)] = 2 if side < 0 else 1
    return out


def dead_tree_pixels():
    """arvore seca: tronco fino torto e galhos em forquilha (02, luar 03/04 por cima/esq., 01 por baixo)."""
    bx, by = DEAD['base']
    rnd = random.Random(DEAD['seed'])
    pts = set()

    def thick_line(x0, y0, x1, y1, w):
        n = max(int(round(max(abs(x1 - x0), abs(y1 - y0)))), 1)
        for i in range(n + 1):
            t = i / n
            x = x0 + (x1 - x0) * t
            y = y0 + (y1 - y0) * t
            ww = max(1, round(w))
            for k in range(ww):
                pts.add((round(x - ww / 2 + 0.5 + k), round(y)))

    def branch(x, y, ang, length, w, depth):
        x1 = x + math.cos(ang) * length
        y1 = y - math.sin(ang) * length
        mx = (x + x1) / 2 + rnd.uniform(-1.5, 1.5)
        my = (y + y1) / 2 + rnd.uniform(-1, 1)
        thick_line(x, y, mx, my, w)
        thick_line(mx, my, x1, y1, max(1, w - 0.6))
        if depth == 0 or length < 5:
            return
        k = 2 if depth < 3 else rnd.choice((2, 2, 3))
        for i in range(k):
            a = ang + (-0.5 + 1.0 * i / max(1, k - 1)) * rnd.uniform(0.75, 1.1)
            branch(x1, y1, a, length * rnd.uniform(0.6, 0.75), max(1, w * 0.6), depth - 1)

    thick_line(bx, by, bx - 2, by - 22, 4)
    thick_line(bx - 2, by - 22, bx + 2, by - 40, 3)
    branch(bx + 2, by - 40, math.radians(80), 16, 2.6, 4)
    branch(bx - 1, by - 28, math.radians(125), 18, 2, 3)
    branch(bx, by - 18, math.radians(30), 18, 2, 3)
    for k in range(1, 6):
        pts.add((bx - 2 - k, by - (1 if k < 3 else 0)))
        pts.add((bx + 1 + k, by + (k // 3)))
    out = {}
    for (x, y) in pts:
        if in_zone(x, y, MARGIN):
            continue
        up = (x, y - 1) in pts
        left = (x - 1, y) in pts
        down = (x, y + 1) in pts
        right = (x + 1, y) in pts
        v = 2
        if not up and not left:
            v = 4
        elif not up or not left:
            v = 3
        elif not down and not right:
            v = 1
        out[(x, y)] = v
    return out


def crown_pixels(t, sway):
    """cachos de folhagem: luz global da copa (lado NO) + relevo de cada cacho.
    01 fundo, 02 sombra, 09 corpo, 10 recorte de luar. Balanco: cachos da borda andam 1 px."""
    cx, cy, rx, ry = _rxry(t)
    blobs = crown_blobs(t)
    lum = {}
    for bx, by, r, ph in blobs:
        e = math.hypot((bx - cx) / rx, (by - cy) / ry)
        off = sway if (sway and e > 0.5 and ph > 0.3) else 0
        for y in range(int(by - r - 1), int(by + r + 2)):
            for x in range(int(bx - r - 1), int(bx + r + 2)):
                dx, dy = (x - bx) / r, (y - by) * 1.2 / r
                q = dx * dx + dy * dy
                if q > 1.0:
                    continue
                nz = math.sqrt(1 - q)
                local = dx * LIGHT[0] + dy * LIGHT[1] + nz * LIGHT[2]
                gx, gy = (x - cx) / rx, (y - cy) / ry
                glob = -(gx * 0.6 + gy * 0.55) + 0.12
                lum[(x + off, y)] = 0.5 * local + 0.5 * glob - (0.3 if t.get('low') else 0.0)
    out = {}
    for (x, y), lv in lum.items():
        if lv > 0.5:
            v = 10
        elif lv > 0.0:
            v = 9
        elif lv > -0.45:
            v = 2
        else:
            v = 1
        if (x, y + 1) not in lum and v in (9, 10):
            v = 2                              # pe do cacho na sombra
        out[(x, y)] = v
    # furos escuros no miolo
    rr = random.Random(t['seed'] * 13)
    keys = sorted(out)
    for k in range(len(keys) // 160):
        x, y = keys[rr.randrange(len(keys))]
        if out[(x, y)] == 2 and all((x + a, y + b) in out for a, b in ((1, 0), (-1, 0), (0, 1), (0, -1), (2, 0))):
            out[(x, y)] = 1
            out[(x + 1, y)] = 1
    return {k: v for k, v in out.items() if not in_zone(k[0], k[1], MARGIN)}


def flatten_hud(layer):
    """atras e em volta das plaquetas do HUD so tons de massa (sem recorte claro)."""
    down = {10: 9, 4: 3, 5: 4, 19: 18}
    for y in range(Y0, Y1):
        for x in range(X0, X1):
            v = layer.g(x, y)
            if v and v in down and near_hud(x, y, 4):
                layer.s(x, y, down[v])


def _depth(t):
    return t['base'][1] if t['base'] else _rxry(t)[1] + _rxry(t)[3]


def mata_frame(sway):
    L = Layer()
    L.crowns = set()
    dead = dead_tree_pixels()
    items = [(_depth(t), 0, t) for t in TREES] + [(DEAD['base'][1], 1, None)]
    for _, kind, t in sorted(items, key=lambda a: (a[0], a[1])):
        if kind == 1:
            for (x, y), v in dead.items():
                L.s(x, y, v)
            continue
        if t['base']:
            for (x, y), v in trunk_pixels(t).items():
                if not in_zone(x, y, MARGIN):
                    L.s(x, y, v)
        for (x, y), v in crown_pixels(t, sway if not t.get('low') else -sway).items():
            L.s(x, y, v)
            L.crowns.add((x, y))
    flatten_hud(L)
    return L


def trunk_shadows(mata, chao):
    """sombra projetada curta dos troncos (lua NO -> para SE, degraus 2-2-2), na camada da mata
    para andar junto com o tronco no parallax. So sobre o chao claro (09), em 02; na sombra da
    mata ela ja se perde e nao e desenhada."""
    for t in TREES + [dict(base=DEAD['base'], w=4, dead=True)]:
        if not t.get('base'):
            continue
        bx, by = t['base']
        ln = 16 if not t.get('dead') else 20
        wd = max(2, t['w'] // 3 + 1)
        for k in range(ln):
            x = bx + 3 + k
            y = by + 1 + k // 2
            thin = wd - (1 if k > ln * 0.55 else 0)
            for j in range(thin):
                yy = y + j - thin // 2 + 1
                if mata.g(x, yy) or in_zone(x, yy, 2):
                    continue
                mata.s(x, yy, 2)               # sobre a sombra 02 da mata ela some sozinha


# --------------------------------------------------------------------------- chao
TRAILS = [
    # (pontos de controle, meia-largura) -- trilhas de terra batida que somem embaixo do diorama
    # 1) entra pela falha da cerquinha (canto de cima/esq.) e desce para o centro
    ([(30, 96), (56, 116), (70, 132), (96, 146), (132, 156), (168, 170), (210, 180), (250, 186)], 3.2),
    # 2) vem da borda direita, serpenteando por baixo da lapide quebrada
    ([(664, 150), (634, 158), (604, 170), (572, 172), (540, 168), (506, 174), (470, 184), (430, 190)], 2.8),
]


def catmull(pts, step=0.5):
    out = []
    P = [pts[0]] + pts + [pts[-1]]
    for i in range(1, len(P) - 2):
        p0, p1, p2, p3 = P[i - 1], P[i], P[i + 1], P[i + 2]
        n = int(math.hypot(p2[0] - p1[0], p2[1] - p1[1]) / step) + 1
        for k in range(n):
            t = k / n
            t2, t3 = t * t, t * t * t
            x = 0.5 * (2 * p1[0] + (-p0[0] + p2[0]) * t + (2 * p0[0] - 5 * p1[0] + 4 * p2[0] - p3[0]) * t2 + (-p0[0] + 3 * p1[0] - 3 * p2[0] + p3[0]) * t3)
            y = 0.5 * (2 * p1[1] + (-p0[1] + p2[1]) * t + (2 * p0[1] - 5 * p1[1] + 4 * p2[1] - p3[1]) * t2 + (-p0[1] + 3 * p1[1] - 3 * p2[1] + p3[1]) * t3)
            out.append((x, y))
    out.append(pts[-1])
    return out


def noise1(t, seed):
    r = random.Random(seed)
    return sum(math.sin(t * r.uniform(0.05, 0.25) + r.uniform(0, 6.28)) / (k + 1) for k in range(4)) / 2.1


def forest_shade(mata):
    """sombra da mata no chao: mascara das copas/troncos deslocada para SE (lua NO),
    medida por distancia euclidiana -> 0 (sem sombra) .. 1."""
    import numpy as np
    from scipy import ndimage
    m = np.zeros((H, W), dtype=bool)
    for (x, y) in mata.crowns:
        if X0 <= x < X1 and Y0 <= y < Y1:
            m[y + PAD, x + PAD] = True
    sh = np.zeros_like(m)
    dx, dy = 10, 7
    sh[dy:, dx:] = m[:-dy, :-dx]
    sh |= m
    dist = ndimage.distance_transform_edt(~sh)
    return dist


def chao(mata):
    L = Layer()
    rnd = random.Random(7)
    dist = forest_shade(mata)
    # 1) base 09; sombra da mata 02 colada nas copas, com transicao em xadrez (fundo grande)
    for y in range(Y0, Y1):
        for x in range(X0, X1):
            d = dist[y + PAD, x + PAD] + 3.0 * noise1(x * 0.7 + y * 1.3, 5)
            ex = (x - 320) / 360
            ey = (y - 180) / 215
            edge = math.hypot(ex, ey)                 # bordas da tela um pouco mais escuras
            d -= max(0.0, (edge - 0.9)) * 60
            if d < 9:
                v = 2
            elif d < 15:
                v = 2 if (x + y) % 2 == 0 else 9
            elif d < 21:
                v = 2 if (x % 2 == 0 and y % 2 == 0) else 9
            else:
                v = 9
            L.s(x, y, v)
    # 2) trilhas de terra batida (concavas: lado NO na sombra 13, borda SE pega luar 14);
    #    somem em dither embaixo do diorama
    for ti, (pts, hw) in enumerate(TRAILS):
        curve = catmull(pts)
        cells = {}
        for k, (cx, cy) in enumerate(curve):
            w = hw + 1.1 * noise1(k * 0.5, 30 + ti)
            for yy in range(int(cy - w - 2), int(cy + w + 3)):
                for xx in range(int(cx - 2 * w - 3), int(cx + 2 * w + 4)):
                    # trilha deitada no chao iso: elipse 2:1
                    d = math.hypot((xx + 0.5 - cx) / 2.0, yy + 0.5 - cy)
                    if d <= w:
                        cells[(xx, yy)] = min(cells.get((xx, yy), 99), d / w)
        for (x, y), q in cells.items():
            fn = field_norm(x, y)
            fade = (fn - 0.44) / (0.78 - 0.44)
            if fade <= 0:
                continue
            if fade < 1 and bayer(x + 16, y + 16) / 16.0 >= fade:
                continue
            base = L.g(x, y)
            if base is None:
                continue
            se = (x + 1, y + 1) not in cells or (x, y + 1) not in cells
            if base == 2:
                v = 13 if not se else 14
            else:
                v = 13
                if se:
                    v = 14
            L.s(x, y, v)
        # pedrinhas e marcas de pe (14 claro / 01 sombra) dentro da trilha
        for k in range(len(curve) // 70):
            cx, cy = curve[rnd.randrange(len(curve))]
            x, y = round(cx + rnd.randint(-2, 2)), round(cy + rnd.randint(-1, 1))
            if L.g(x, y) == 13 and L.g(x + 1, y) == 13 and L.g(x, y + 1) == 13 and field_norm(x, y) > 0.8:
                L.s(x, y, 14)
                L.s(x + 1, y + 1, 1) if L.g(x + 1, y + 1) == 13 else None
    # 3) textura minima: tufos 10, folhas 18/14, manchas de terra 13/14
    placed = 0
    tries = 0
    while placed < 170 and tries < 30000:
        tries += 1
        x, y = rnd.randrange(X0 + 2, X1 - 3), rnd.randrange(Y0 + 3, Y1 - 2)
        fn = field_norm(x, y)
        if fn < 0.5 and rnd.random() < 0.8:
            continue                                # miolo quase liso
        base = L.g(x, y)
        if base not in (9, 2) or any(L.g(x + a, y + b) != base for a in (-1, 0, 1, 2, 3) for b in (-2, -1, 0, 1)):
            continue
        hi = 10 if base == 9 else 9
        k = rnd.randrange(3)
        if k == 0:
            L.s(x, y, hi)
            L.s(x + 1, y, hi)                        # tufo baixo de 2 px
        elif k == 1:
            L.s(x, y, hi)
            L.s(x + 1, y - 1, hi)                    # tufo inclinado
        else:
            L.s(x, y, hi)
            L.s(x + 1, y - 1, hi)
            L.s(x + 2, y, hi)                        # tufo em V
        placed += 1
    for k in range(90):
        x, y = rnd.randrange(X0, X1), rnd.randrange(Y0, Y1)
        if L.g(x, y) in (9, 2) and L.g(x + 1, y) in (9, 2) and field_norm(x, y) > 0.55:
            c = rnd.choice((18, 18, 14))
            L.s(x, y, c)
            L.s(x + 1, y, c)                         # folha de 2 px deitada
    return L


# --------------------------------------------------------------------------- props
LAPIDE_ARCO = [            # 13x16: arredondada com foto oval; luz 05 em cima/esq., lado 03
    "....LLLL.....",
    "..LLVVVVLI...",
    ".LVVVVVVVVI..",
    ".LVVVNNNVVII.",
    "LVVVNIIINVVII",
    "LVVVNILINVVII",
    "LVVVVNNNVVVII",
    "LVVVVVVVVVVII",
    "LVVNNNNNNVVII",
    "LVVVVVVVVVVII",
    "LVVNNNNNVVVII",
    "LVVVVVVVVVVII",
    "LVVVVVVVVVVII",
    "LVVVVVVVVVVII",
    "IVVVVVVVVVVIN",
    "NNNNNNNNNNNNK",
]
LAPIDE_QUEBRADA = [        # 12x13: quadrada com ombro, canto de cima/dir. quebrado
    ".LLLLL......",
    "LVVVVVLL....",
    "LVVVVVVVL...",
    "LVVVVVVVVLI.",
    "LVVNNNNVVVII",
    "LVVVVVVVVVII",
    "LVVNNNVVVVII",
    "LVVVVVVVVVII",
    "LVVVVVVVVVII",
    "LVVVVVVVVVII",
    "LVVVVVVVVVII",
    "IVVVVVVVVVIN",
    "NNNNNNNNNNNK",
]
CRUZ_PEDRA = [             # 11x18: cruz de pedra num pedestal
    "....LL.....",
    "...LVVI....",
    "...LVVI....",
    ".LLLVVLLL..",
    "LVVVVVVVVI.",
    "IIIIVVVIIII",
    "...LVVII...",
    "...LVVII...",
    "...LVVII...",
    "...LVVII...",
    "...LVVII...",
    "...LVVII...",
    "..LVVVVII..",
    ".LLLLLLLLI.",
    ".LVVVVVVVII",
    ".LVVVVVVVII",
    ".IVVVVVVVIN",
    ".NNNNNNNNNK",
]
CRUZ_MADEIRA = [           # 9x17: cruz de madeira 18/19 com fitinha 31
    "...Cc....",
    "...Cc....",
    "...Cc....",
    "CCCCcccc.",
    "cccxcccK.",
    "...Cc....",
    "...Cc....",
    "...Cc....",
    "...Cc....",
    "...Cc....",
    "...Cc....",
    "...Cc....",
    "...Cc....",
    "...Cc....",
    "...CcK...",
    "...CcK...",
    "..NNNNK..",
]
CRUZ_PEQUENA = [           # 7x12: cruzinha torta de ripa
    "..Cc...",
    "..Cc...",
    "CCCccc.",
    "ccccccK",
    "..Cc...",
    "..Cc...",
    "..Cc...",
    "..Cc...",
    "..Cc...",
    "..Cc...",
    "..CcK..",
    ".NNNK..",
]
CRISANTEMO = [             # 9x7: crisantemos murchos (cabecas 31 caidas, 18 secas)
    "..x......",
    ".xcx..x..",
    "..c..xcx.",
    "..G...c..",
    ".G.g.G...",
    "GgG.GgGg.",
    ".gggggg..",
]
CRISANTEMO_2 = [           # 7x6
    "....x..",
    ".c.xcx.",
    "..G.c..",
    ".Gg.G..",
    "GgGgGg.",
    ".ggggg.",
]
SECO = [                   # 8x5: ramo seco de flores (18/19) caido no chao
    "......c.",
    ".C...cC.",
    "cCc.c...",
    ".ccCc...",
    "..cc....",
]


def lean(rows, top_rows, dx):
    """inclina o sprite: as 'top_rows' linhas de cima andam dx px (1 degrau limpo)."""
    out = []
    w = len(rows[0]) + abs(dx)
    for j, r in enumerate(rows):
        sh = dx if j < top_rows else 0
        pad_l = sh - min(0, dx)
        line = '.' * pad_l + r
        out.append(line + '.' * (w - len(line)))
    return out


def stamp(L, rows, bx, by, ax=None):
    """bx, by = ponto de apoio (base); ax = coluna do apoio dentro do sprite."""
    h = len(rows)
    w = len(rows[0])
    for r in rows:
        assert len(r) == w, rows
    ax = w // 2 if ax is None else ax
    x0, y0 = bx - ax, by - (h - 1)
    L.screen_rows(x0, y0, rows, base_y=by)
    return (x0, y0, w, h)


# ---- caixa iso (laje do tumulo)
def iso_box(L, ox, oy, U, V, Hh, top=4, lip=5, left=3, right=2, hbase=0):
    """caixa iso: P(u, v, h) = (ox + 2u - 2v, oy + u + v - h). Topo 04 com lábio 05 nas arestas
    de tras (lado da lua), face SO 03, face SE 02."""
    def inside_top(x, y):
        X, Y = x + 0.5 - ox, y + 0.5 - oy + Hh
        u = (X / 2 + Y) / 2
        v = (Y - X / 2) / 2
        return 0 <= u < U and 0 <= v < V, u, v
    xs = range(ox - 2 * V - 1, ox + 2 * U + 2)
    for x in xs:
        for y in range(oy - Hh - 1, oy + U + V + 2):
            ok, u, v = inside_top(x, y)
            if ok:
                c = top
                if u < 0.75 or v < 0.75:
                    c = lip
                L.s(x, y, c, hbase + Hh)
                continue
            # faces: o ponto do topo correspondente esta Hh px acima
            for dh in range(1, Hh + 1):
                X, Y = x + 0.5 - ox, y + 0.5 - oy + Hh - dh
                u = (X / 2 + Y) / 2
                v = (Y - X / 2) / 2
                if 0 <= u < U and 0 <= v < V and (u >= U - 0.5 or v >= V - 0.5):
                    face_left = x + 0.5 < ox + 2 * U - 2 * V
                    L.s(x, y, left if face_left else right, hbase + Hh - dh)
                    break


def iso_pt(ox, oy, u, v, h=0):
    return (int(round(ox + 2 * u - 2 * v)), int(round(oy + u + v - h)))


def fence_line(L, x0, y0, n_steps, direction, post_every=6, hpost=8, broken=()):
    """cerquinha em diagonal iso, em degraus 2-2-2.
    direction: +1 = desce para a direita (paralela a aresta SO/NE do campo), -1 = sobe para a direita.
    n_steps = comprimento em px de x. Trilhos 03 (cima) e 02 (baixo), postes 02 com luar 03,
    pontas de lanca 04; base no chao."""
    for i in range(n_steps):
        x = x0 + i
        y = y0 + direction * (i // 2)
        if any(a <= i < b for (a, b) in broken):
            continue
        L.s(x, y - hpost + 2, 3, hpost - 2)
        L.s(x, y - 3, 2, 3)
    for i in range(0, n_steps, post_every):
        x = x0 + i
        y = y0 + direction * (i // 2)
        if any(a <= i < b for (a, b) in broken):
            continue
        for h in range(0, hpost):
            L.s(x, y - h, 2 if h < hpost - 1 else 3, h)
        L.s(x, y - hpost, 4, hpost)
        if i % (post_every * 2) == 0:
            L.s(x, y - hpost - 1, 4, hpost + 1)          # lanca mais alta a cada 2 postes


# ---- velas (as unicas luzes quentes do fundo)
def candle(L, x, by, hgt, glass=False):
    """vela 2 px: cera 05 (luz) / 04; pavio 01; chama 23 (base) 26 25 (ponta)."""
    if glass:
        # vela de sete dias num pote de vidro: vidro 04/03, brilho interno 24
        for y in range(by - 4, by + 1):
            L.s(x - 1, y, 4, by - y)
            L.s(x + 2, y, 3, by - y)
            L.s(x, y, 24, by - y)
            L.s(x + 1, y, 24 if y > by - 3 else 25, by - y)
        L.s(x, by - 4, 4, 4)
        L.s(x + 1, by - 5, 26, 5)
        L.s(x + 1, by - 6, 25, 6)
        return
    for y in range(by - hgt + 1, by + 1):
        L.s(x, y, 5, by - y)
        L.s(x + 1, y, 4, by - y)
    top = by - hgt + 1
    L.s(x, top - 1, 1, hgt + 1)               # pavio
    L.s(x, top - 2, 23, hgt + 2)
    L.s(x, top - 3, 26, hgt + 3)
    L.s(x, top - 4, 25, hgt + 4)
    L.s(x + 1, top, 5, hgt)                   # escorrido de cera


def candle_halo(L, chao, cx, cy, rx=11, ry=5):
    """halo em xadrez discreto no chao: anel externo sobe 1 degrau (§4.2), miolo 19."""
    up = {9: 10, 2: 3, 1: 2, 14: 15, 13: 14, 10: 11, 18: 19}
    for y in range(cy - ry, cy + ry + 1):
        for x in range(cx - rx, cx + rx + 1):
            d = ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2
            if d > 1 or L.g(x, y):
                continue
            g = chao.g(x, y)
            if d < 0.28 and (x + y) % 2 == 0:
                L.s(x, y, 19)
            elif d < 0.62 and (x + y) % 2 == 0 and g in up:
                L.s(x, y, up[g])
            elif (x % 2 == 0 and y % 2 == 0) and g in up:
                L.s(x, y, up[g])


def candles_group(L, chao, x, by, kind):
    candle_halo(L, chao, x + 3, by - 1, 12, 5)
    if kind == 0:
        candle(L, x, by, 5)
        candle(L, x + 3, by + 1, 3)
        candle(L, x + 6, by, 4)
    else:
        candle(L, x, by, 3)
        candle(L, x + 4, by - 1, 0, glass=True)
        candle(L, x + 7, by + 1, 4)


# ---- arbustos baixos
def bush(L, cx, cy, rx, ry, seed):
    rnd = random.Random(seed)
    blobs = []
    for k in range(int(rx * ry / 6) + 3):
        x = rnd.uniform(cx - rx, cx + rx)
        y = rnd.uniform(cy - ry, cy + ry * 0.4)
        if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 > 1:
            continue
        blobs.append((x, y, rnd.uniform(2.6, 4.4)))
    blobs.sort(key=lambda b: b[1])
    lum = {}
    for bx, by, r in blobs:
        for y in range(int(by - r - 1), int(by + r + 2)):
            for x in range(int(bx - r - 1), int(bx + r + 2)):
                dx, dy = (x - bx) / r, (y - by) * 1.25 / r
                q = dx * dx + dy * dy
                if q > 1:
                    continue
                nz = math.sqrt(1 - q)
                local = dx * LIGHT[0] + dy * LIGHT[1] + nz * LIGHT[2]
                glob = -((x - cx) / rx * 0.6 + (y - cy) / ry * 0.8)
                lum[(x, y)] = 0.5 * local + 0.5 * glob
    base = max(y for (x, y) in lum)
    for (x, y), lv in lum.items():
        v = 10 if lv > 0.55 else (9 if lv > 0.0 else 2)
        if (x, y + 1) not in lum:
            v = 2 if v != 10 else 9
        L.s(x, y, v, max(0, (base - y) // 3))     # mato baixo: sombra curta
    return base


# ---- sombra projetada (solida, 02 sobre 09 / 01 sobre 02), para SE
def cast_shadows(L, chao, a=0.32):
    """cada pixel a altura h acima do chao projeta em (x + 2ah, chao + ah): lua NO -> sombra para SE
    no plano iso. Meio passo de altura extra para nao deixar furos."""
    shadow = set()
    for (x, y), h in L.hgt.items():
        gy = y + h
        if h <= 0:
            shadow.add((x + 1, gy))               # contato com o chao
            continue
        for hh in (h - 0.5, h):
            shadow.add((round(x + 2 * a * hh), round(gy + a * hh)))
    for (x, y) in shadow:
        if L.g(x, y):
            continue
        if in_zone(x, y, 2):
            continue
        g = chao.g(x, y)
        L.s(x, y, 1 if g in (1, 2, 3, 13) else 2)


# posicoes dos props (tela). Tudo fora do maior campo e longe das plaquetas.
PROPS = dict(
    fence=dict(x0=10, y0=158, n=128, dir=-1, broken=((54, 62),)),     # canto de cima/esq., sobe p/ direita
    tumulo=dict(ox=420, oy=60, U=5, V=9),                             # tumulo com cercadinho (cima/dir.)
    lap_arco=(98, 132),
    lap_quebrada=(566, 150),
    cruz_pedra=(572, 278),
    cruz_madeira=(62, 268),
    cruz_pequena=(116, 300),
    velas=[(470, 82, 0), (82, 280, 1)],
    bushes=[(160, 96, 12, 6, 1), (24, 214, 11, 7, 2), (600, 236, 13, 7, 3), (40, 318, 12, 6, 4), (548, 300, 10, 5, 5)],
    cris=[(112, 136, 0), (586, 282, 1), (74, 270, 0), (440, 86, 1)],
    seco=[(124, 122), (584, 156)],
)


def props(chao):
    L = Layer()
    P = PROPS
    # cerquinha de ferro em diagonal iso, cortando o canto de cima/esq. (degraus 2-2-2)
    f = P['fence']
    fence_line(L, f['x0'], f['y0'], f['n'], f['dir'], broken=f['broken'])
    # tumulo com cercadinho: grade de tras, laje, lapide, grade da frente
    t = P['tumulo']
    ox, oy, U, V = t['ox'], t['oy'], t['U'], t['V']
    g = 1.5                                   # folga da grade em volta da laje (unidades iso)

    def run(pa, pb, posts=True):
        (u0, v0), (u1, v1) = pa, pb
        x0, y0 = iso_pt(ox, oy, u0, v0)
        x1, y1 = iso_pt(ox, oy, u1, v1)
        n = abs(x1 - x0)
        sx = 1 if x1 > x0 else -1
        sy = 1 if y1 > y0 else -1
        for i in range(n + 1):
            x = x0 + sx * i
            y = y0 + sy * (i // 2)
            L.s(x, y - 5, 3, 5)
            L.s(x, y - 2, 2, 2)
            if posts and i % 4 == 0:
                for h in range(0, 6):
                    L.s(x, y - h, 2, h)
                L.s(x, y - 6, 4, 6)
    # grade de tras (arestas NO e NE)
    run((-g, V + g), (-g, -g))
    run((-g, -g), (U + g, -g))
    # laje e lapide da cabeceira
    iso_box(L, ox, oy, U, V, 3)
    hx, hy = iso_pt(ox, oy, U / 2, 0.8, 3)
    stamp(L, lean(LAPIDE_QUEBRADA, 5, 1), hx, hy, 6)
    # grade da frente (arestas SO e SE), com um trecho caido
    run((-g, V + g), (U + g, V + g))
    run((U + g, -g), (U + g, V + g))
    # lapides e cruzes tortas (tipos variados)
    stamp(L, lean(LAPIDE_ARCO, 6, 1), *P['lap_arco'])
    stamp(L, lean(LAPIDE_QUEBRADA, 4, -1), *P['lap_quebrada'])
    stamp(L, lean(CRUZ_PEDRA, 7, 1), *P['cruz_pedra'])
    stamp(L, lean(lean(CRUZ_MADEIRA, 10, -1), 4, -1), *P['cruz_madeira'])
    stamp(L, lean(CRUZ_PEQUENA, 6, 1), *P['cruz_pequena'])
    # arbustos
    for (x, y, rx, ry, s) in P['bushes']:
        bush(L, x, y, rx, ry, s)
    # crisantemos murchos e ramos secos
    for (x, y, k) in P['cris']:
        stamp(L, CRISANTEMO if k == 0 else CRISANTEMO_2, x, y)
    for (x, y) in P['seco']:
        stamp(L, SECO, x, y)
    # sombras projetadas antes das velas (as chamas nao fazem sombra; o halo entra por cima)
    cast_shadows(L, chao)
    for (x, y, k) in P['velas']:
        candles_group(L, chao, x, y, k)
    flatten_hud(L)
    return L


FLAME = {22, 23, 25, 26}
