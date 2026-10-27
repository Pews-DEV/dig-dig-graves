"""Fundo do Turno da Area 2 · Campo dos Indigentes (UI/UX §5 rev. 1.1; DA §6).

Mesmo contrato do fundo v2 da Area 1 (art_src/_gerador_fundo_turno/fundo.py, reaproveitado aqui):
tres camadas de 672x392 desenhadas em (-16, -16), mesma zona livre (maior campo 18x18 + bloco),
mesmas plaquetas do HUD, mesma luma baixa. Muda o lugar:
  chao  -> campo aberto de grama rala (09/10), manchas de terra e de lama (13/14, pingos 27),
           faixas de nevoa baixa no chao em xadrez 04/05, trilha de terra batida;
  props -> fileiras de cruzes de madeira sem nome, tortas (18/19), montinhos de cova rasa,
           cerca de madeira quebrada, corvos parados, 2 velas (mesmos centros de halo da A1);
  mata  -> sem floresta: mato baixo escuro nas bordas, faixa de capoeira no topo e arvores secas.
Coordenadas de TELA (a Layer converte)."""
import math
import random

import fundo as F
from fundo import Layer, in_zone, near_hud, field_norm, bayer, stamp, lean, X0, X1, Y0, Y1

FLAME = F.FLAME

# ============================================================================ mata (moldura)
TREES = [
    # topo: capoeira baixa e escura atras das plaquetas (sem tronco)
    dict(c=(150, -30, 46), base=None, seed=61),
    dict(c=(262, -30, 40), base=None, seed=62),
    dict(c=(340, -36, 46), base=None, seed=63),
    dict(c=(420, -30, 42), base=None, seed=64),
    dict(c=(520, -28, 44), base=None, seed=65),
    # cantos de cima: 2 arvores de copa rala com tronco
    dict(c=(-4, 4, 50), base=(30, 86), w=8, bend=-3, seed=66),
    dict(c=(660, 10, 50), base=(628, 90), w=8, bend=4, seed=67),
    # laterais e cantos de baixo: mato baixo (primeiro plano)
    dict(c=(-34, 150, 36), base=None, seed=71, low=True),
    dict(c=(-30, 250, 34), base=None, seed=72, low=True),
    dict(c=(20, 392, 50), base=None, seed=73, low=True),
    dict(c=(674, 160, 32), base=None, seed=74, low=True),
    dict(c=(684, 262, 40), base=None, seed=75, low=True),
    dict(c=(630, 394, 52), base=None, seed=76, low=True),
]
# arvores secas (galhos): base de tela e semente
DEAD = [dict(base=(104, 108), seed=81), dict(base=(548, 96), seed=82), dict(base=(48, 300), seed=83)]


def _with_globals(fn, *a, **k):
    """roda uma funcao do fundo.py com as arvores da A2 nos globais dele."""
    old_t, old_d = F.TREES, F.DEAD
    try:
        F.TREES = TREES
        return fn(*a, **k)
    finally:
        F.TREES, F.DEAD = old_t, old_d


def dead_trees():
    out = {}
    for d in DEAD:
        F.DEAD = d
        for k, v in F.dead_tree_pixels().items():
            out[k] = v
    return out


def mata_frame(sway):
    L = Layer()
    L.crowns = set()
    dead = dead_trees()
    items = [(F._depth(t), 0, t) for t in TREES] + [(99999, 1, None)]
    for _, kind, t in sorted(items, key=lambda a: (a[0], a[1])):
        if kind == 1:
            for (x, y), v in dead.items():
                if not L.g(x, y):
                    L.s(x, y, v)
            continue
        if t['base']:
            for (x, y), v in F.trunk_pixels(t).items():
                if not in_zone(x, y, F.MARGIN):
                    L.s(x, y, v)
        for (x, y), v in F.crown_pixels(t, sway if not t.get('low') else -sway).items():
            L.s(x, y, v)
            L.crowns.add((x, y))
    F.flatten_hud(L)
    return L


def trunk_shadows(mata, chao):
    old_t, old_d = F.TREES, F.DEAD
    try:
        F.TREES = TREES
        for d in DEAD:
            F.DEAD = d
            # fundo.trunk_shadows percorre TREES + DEAD; para nao repetir as arvores com tronco,
            # roda as arvores so na primeira passada
            if d is not DEAD[0]:
                F.TREES = []
            F.trunk_shadows(mata, chao)
    finally:
        F.TREES, F.DEAD = old_t, old_d


# ============================================================================ chao
TRAIL = ([(-20, 214), (20, 220), (58, 230), (96, 238), (136, 236), (176, 228), (214, 222)], 2.6)
MIST = [  # faixas de nevoa baixa no chao: (y central, meia-altura, semente)
    (66, 6, 1), (120, 5, 2), (238, 7, 3), (298, 6, 4), (348, 5, 5)]


def _wisp(x, seed):
    """densidade 0..1 da nevoa ao longo de x: ondas longas, sem periodo curto (fiapos)."""
    r = random.Random(500 + seed)
    ph = [r.uniform(0, 6.28) for _ in range(4)]
    n = (math.sin(x * 0.0113 + ph[0]) + 0.7 * math.sin(x * 0.0271 + ph[1]) +
         0.45 * math.sin(x * 0.0587 + ph[2]) + 0.25 * math.sin(x * 0.131 + ph[3]))
    return max(0.0, min(1.0, 0.45 + 0.42 * n))


def mist_value(x, y, base):
    """nevoa em xadrez sobre o chao (DA §6): miolo xadrez 04/05 so onde a faixa e grossa,
    corpo xadrez 04, borda 25% 04."""
    for (yc, hh, seed) in MIST:
        amt = _wisp(x, seed)
        th = hh * amt * 1.5
        if th < 1.2:
            continue
        cy = yc + 3.0 * math.sin(x / 53.0 + seed) + 1.5 * math.sin(x / 19.0 + 2 * seed)
        d = abs(y + 0.5 - cy) / th
        if y + 0.5 < cy:
            d *= 1.2                                  # topo mais ralo
        if d < 0.3 and amt > 0.82:
            return 5 if (x + y) % 2 == 0 else 4
        if d < 0.65:
            return 4 if (x + y) % 2 == 0 else base
        if d < 1.0:
            return 4 if (x % 2 == 0 and y % 2 == 0) else base
    return base


def chao(mata):
    L = Layer()
    rnd = random.Random(17)
    dist = F.forest_shade(mata)
    # 1) base 09 com a sombra do mato 02 nas bordas (xadrez de transicao)
    for y in range(Y0, Y1):
        for x in range(X0, X1):
            d = dist[y + F.PAD, x + F.PAD] + 3.0 * F.noise1(x * 0.7 + y * 1.3, 15)
            edge = math.hypot((x - 320) / 360, (y - 180) / 215)
            d -= max(0.0, (edge - 0.86)) * 70
            if d < 8:
                v = 2
            elif d < 14:
                v = 2 if (x + y) % 2 == 0 else 9
            elif d < 20:
                v = 2 if (x % 2 == 0 and y % 2 == 0) else 9
            else:
                v = 9
            L.s(x, y, v)
    # 2) manchas de terra nua (grama rala): elipses iso 13 com borda SE 14, fora do miolo
    patches = []
    for _ in range(400):
        if len(patches) >= 16:
            break
        x, y = rnd.randrange(X0 + 10, X1 - 10), rnd.randrange(Y0 + 10, Y1 - 10)
        if field_norm(x, y) < 0.62 or near_hud(x, y, 6):
            continue
        if any(math.hypot(x - a, (y - b) * 2) < 40 for (a, b, _, _) in patches):
            continue
        patches.append((x, y, rnd.uniform(6, 13), rnd.random() < 0.35))
    for (px, py, r, wet) in patches:
        for y in range(int(py - r / 2) - 2, int(py + r / 2) + 3):
            for x in range(int(px - r) - 2, int(px + r) + 3):
                q = math.hypot((x + 0.5 - px) / r, (y + 0.5 - py) / (r / 2))
                q += 0.18 * F.noise1(x * 1.7 + y * 3.1, int(px))
                if q > 1.0:
                    continue
                base = L.g(x, y)
                if base not in (9, 2):
                    continue
                v = 13
                if q > 0.72 and (bayer(x, y) / 16.0) < (q - 0.72) / 0.28:
                    v = base                      # borda rala em dither ordenado
                elif q < 0.45 and wet:
                    v = 14                        # lama: miolo 14 ...
                L.s(x, y, v)
        if wet:
            # ... com 1 pocinha esverdeada 27 de 2-3 px
            n = 3 if r > 9 else 2
            for k in range(n):
                L.s(int(px) - 1 + k, int(py), 27)
            L.s(int(px) - 2, int(py), 13)
    # 3) trilha de terra batida (sai pela esquerda e some embaixo do diorama)
    pts, hw = TRAIL
    curve = F.catmull(pts)
    cells = {}
    for k, (cx, cy) in enumerate(curve):
        w = hw + 0.9 * F.noise1(k * 0.5, 44)
        for yy in range(int(cy - w - 2), int(cy + w + 3)):
            for xx in range(int(cx - 2 * w - 3), int(cx + 2 * w + 4)):
                d = math.hypot((xx + 0.5 - cx) / 2.0, yy + 0.5 - cy)
                if d <= w:
                    cells[(xx, yy)] = 1
    for (x, y) in cells:
        fn = field_norm(x, y)
        fade = (fn - 0.44) / (0.78 - 0.44)
        if fade <= 0 or (fade < 1 and bayer(x + 16, y + 16) / 16.0 >= fade):
            continue
        se = (x + 1, y + 1) not in cells or (x, y + 1) not in cells
        L.s(x, y, 14 if se else 13)
    # 4) tufos ralos 10 e folhas secas 18 (textura minima)
    placed = tries = 0
    while placed < 120 and tries < 30000:
        tries += 1
        x, y = rnd.randrange(X0 + 2, X1 - 3), rnd.randrange(Y0 + 3, Y1 - 2)
        if field_norm(x, y) < 0.5 and rnd.random() < 0.85:
            continue
        base = L.g(x, y)
        if base not in (9, 2) or any(L.g(x + a, y + b) != base for a in (-1, 0, 1, 2, 3) for b in (-2, -1, 0, 1)):
            continue
        hi = 10 if base == 9 else 9
        if rnd.random() < 0.5:
            L.s(x, y, hi)
            L.s(x + 1, y - 1, hi)
        else:
            L.s(x, y, hi)
            L.s(x + 1, y - 1, hi)
            L.s(x + 2, y, hi)
        placed += 1
    for k in range(60):
        x, y = rnd.randrange(X0, X1), rnd.randrange(Y0, Y1)
        if L.g(x, y) in (9, 2) and L.g(x + 1, y) in (9, 2) and field_norm(x, y) > 0.55:
            L.s(x, y, 18)
            L.s(x + 1, y, 18)
    # 5) nevoa baixa no chao (faixas em xadrez 04/05, DA §6)
    for y in range(Y0, Y1):
        for x in range(X0, X1):
            base = L.g(x, y)
            v = mist_value(x, y, base)
            if v != base:
                L.s(x, y, v)
    return L


# ============================================================================ props
CROW = [                 # corvo parado, virado para a esquerda; 9x7, pes na ultima linha
    "..VL.....",            # luar 04/05 no alto da cabeca e nas costas (lado NO)
    ".VNNV....",
    "INKNNVVL.",            # bico 03, olho 01
    "..NNNNNNV",
    "..NNNNNNK",
    "...NNNK..",
    "...K.K...",
]
CROW_R = [r[::-1] for r in CROW]


def small_cross(h, arm, seed=0):
    """cruzinha de ripa sem nome: haste 2 px (19 luar / 18), braco de 2 linhas (19 / 18)."""
    w = 2 * arm + 2
    rows = []
    for j in range(h):
        line = ['.'] * w
        line[arm] = 'C'
        line[arm + 1] = 'c'
        if j == 2:
            line = ['C'] * (arm + 1) + ['c'] * (arm + 1)
        elif j == 3:
            line = ['c'] * w
        rows.append(''.join(line))
    return rows


CROSS_ROWS = [
    # fileiras de cruzes de indigente seguindo a diagonal iso (degraus 2-2-2 entre elas)
    # (x0, y0, n, dx, dy, escala) -- dy/dx = 1/2 (fileira paralela a aresta NE/SO do campo)
    (14, 140, 4, 22, -11, 1), (40, 172, 3, 22, -11, 0),
    (560, 128, 4, 22, 11, 1), (500, 70, 3, 20, 10, 0),
    (520, 268, 3, -22, 11, 1), (14, 330, 4, 24, -12, 0),
]
MOUNDS = True


def mound(L, cx, by, w):
    """montinho de cova rasa: elipse iso 13/14, lado NO 15 (luar), sombra para SE pelo cast."""
    for y in range(by - 3, by + 1):
        for x in range(cx - w, cx + w + 1):
            q = ((x + 0.5 - cx) / (w + 0.5)) ** 2 + ((y + 0.5 - (by - 0.5)) / 2.6) ** 2
            if q > 1.0:
                continue
            v = 14
            if y == by - 3 or (x < cx - w // 2 and y == by - 2):
                v = 15
            if x > cx + w // 2 and y >= by - 1:
                v = 13
            L.s(x, y, v, max(0, by - y))


def crow(L, x, by, right=False):
    stamp(L, CROW_R if right else CROW, x, by, 4)


BIG_CROSS = [r.replace('x', 'c') for r in F.CRUZ_MADEIRA]      # sem a fitinha: cruz sem nome
MID_CROSS = F.CRUZ_PEQUENA
BIG = [  # (x, y da base, qual, inclinacao) -- cruzes maiores, mais perto da camera (cantos)
    (66, 270, 0, -1), (118, 300, 1, 1), (588, 282, 0, 1), (612, 150, 1, -1),
    (176, 98, 1, 1), (458, 52, 1, -1), (16, 208, 1, 1)]


def props(chao):
    L = Layer()
    rnd = random.Random(23)
    perches = []
    # fileiras de cruzes sem nome, tortas, com montinho de terra na frente
    for (x0, y0, n, dx, dy, sc) in CROSS_ROWS:
        for k in range(n):
            bx, by = x0 + k * dx, y0 + k * dy
            if in_zone(bx, by, 14) or near_hud(bx, by, 14):
                continue
            h = (12 if sc else 9) + rnd.randrange(-1, 2)
            arm = 3 if sc else 2
            rows = small_cross(h, arm, k)
            tilt = rnd.choice((-1, 0, 1, 1))
            if tilt:
                rows = lean(rows, h // 2, tilt)
            if MOUNDS:
                mound(L, bx + 2, by + 2, 4 if sc else 3)
            stamp(L, rows, bx, by, arm)
            perches.append((bx, by - h + 2, sc))
    # cruzes maiores, tortas (sem nome)
    for (bx, by, k, tilt) in BIG:
        rows = BIG_CROSS if k == 0 else MID_CROSS
        rows = lean(rows, len(rows) // 2, tilt)
        if MOUNDS:
            mound(L, bx + 1, by + 2, 4)
        stamp(L, rows, bx, by)
        perches.append((bx, by - len(rows) + 4, 2))
    # cerca de madeira quebrada (diagonal iso, canto de cima/dir.), trechos faltando
    fence_wood(L, 388, 58, 116, 1, broken=((30, 44), (80, 88)))
    # corvos parados: 2 em bracos de cruz, 1 no chao, 1 na cerca
    big = [p for p in perches if p[2] == 2]
    for (bx, by, _) in (big[0], big[3]):
        crow(L, bx + 1, by - 1, right=bx > 320)
    crow(L, 150, 304)
    crow(L, 520, 116, right=True)
    crow(L, 40, 120)
    # sombras projetadas (lua NO -> SE), velas por cima (mesmos centros de halo da A1)
    F.cast_shadows(L, chao)
    F.candles_group(L, chao, 470, 82, 1)
    F.candles_group(L, chao, 82, 280, 0)
    F.flatten_hud(L)
    return L


def fence_wood(L, x0, y0, n, direction, broken=()):
    """cerca de estacas de madeira (18/19) e 2 ripas, quebrada, em degraus 2-2-2."""
    for i in range(n):
        x = x0 + i
        y = y0 + direction * (i // 2)
        if any(a <= i < b for (a, b) in broken):
            continue
        L.s(x, y - 6, 19, 6)
        L.s(x, y - 5, 18, 5)
        L.s(x, y - 2, 18, 2)
    for i in range(0, n, 7):
        x = x0 + i
        y = y0 + direction * (i // 2)
        if any(a <= i < b for (a, b) in broken):
            # estaca caida no chao (deitada na diagonal)
            for k in range(5):
                L.s(x + k, y + 1 + (k // 2) * direction, 18 if k else 19, 0)
            continue
        hh = 8 if (i // 7) % 3 else 6
        for h in range(0, hh):
            L.s(x, y - h, 19, h)
            L.s(x + 1, y - h, 18, h)
        L.s(x, y - hh, 19, hh)
