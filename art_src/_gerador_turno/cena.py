"""Cena do turno, Area 1: ceu, nuvens, fundo distante, bloco de terra (diorama),
cerquinha, tufos, placa, nevoa e vinheta. Tudo em indices da Lua de Cova 32."""
import math
import random
from common import Canvas

W, H = 640, 360
HORIZON = 150          # linha do horizonte na tela (o fundo distante assenta aqui)


def bayer(x, y):
    """limiar 0..15 (Bayer 4x4)."""
    m = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]
    return m[y % 4][x % 4]


def checker(x, y):
    return (x + y) % 2 == 0


# ------------------------------------------------------------------ ceu
SKY_BANDS = [  # (y_inicio_da_transicao, cor_de_cima, cor_de_baixo)
    (52, 2, 3),
    (104, 3, 4),
]
MOON_C = (74, 58)
MOON_R = 25


def sky():
    c = Canvas(W, H, 2)
    # faixas: transicao em 3 passos (25% / 50% / 75%), 3 linhas cada: xadrez so aqui
    for y in range(H):
        col = 2
        for (y0, a, b) in SKY_BANDS:
            if y >= y0 + 9:
                col = b
        for x in range(W):
            v = col
            for (y0, a, b) in SKY_BANDS:
                if y0 <= y < y0 + 9:
                    step = (y - y0) // 3           # 0, 1, 2
                    if step == 1:
                        v = b if checker(x, y) else a
                    else:
                        thr = 4 if step == 0 else 12  # 25% ou 75% de b
                        v = b if bayer(x, y) < thr else a
            c.px[y][x] = v
    # halo da lua em xadrez: anel interno 05/04, anel externo 04/fundo
    mx, my = MOON_C
    for y in range(my - MOON_R - 16, my + MOON_R + 17):
        for x in range(mx - MOON_R - 16, mx + MOON_R + 17):
            d = math.hypot(x + 0.5 - mx - 0.5, y + 0.5 - my - 0.5)
            if MOON_R < d <= MOON_R + 5:
                c.set(x, y, 5 if checker(x, y) else 4)
            elif MOON_R + 5 < d <= MOON_R + 13:
                if checker(x, y):
                    c.set(x, y, 4)
            elif MOON_R + 13 < d <= MOON_R + 16:
                if x % 2 == 0 and y % 2 == 0:
                    c.set(x, y, 4)
    # lua cheia: disco 08, mares 07, crateras 06; borda da direita/baixo 07 (volume suave)
    rnd = random.Random(7)
    maria = [(-7, -10, 5), (0, -7, 6), (7, -2, 5), (10, 5, 4), (2, 9, 3), (-11, 3, 3)]
    for y in range(my - MOON_R, my + MOON_R + 1):
        for x in range(mx - MOON_R, mx + MOON_R + 1):
            dx, dy = x + 0.5 - mx - 0.5, y + 0.5 - my - 0.5
            d = math.hypot(dx, dy)
            if d <= MOON_R:
                v = 8
                for (ox, oy, r) in maria:
                    if math.hypot(dx - ox, dy - oy) <= r:
                        v = 7
                if d > MOON_R - 2.2 and (dx + dy) > 6:
                    v = 7
                c.set(x, y, v)
    for (ox, oy) in [(-9, -7), (6, 5), (-5, 9), (13, -3), (4, -11)]:
        c.set(mx + ox, my + oy, 6)
        c.set(mx + ox + 1, my + oy, 7)
    # estrelas: maioria 05, algumas 06, poucas 07; nada perto da lua e do horizonte
    stars = []
    for i in range(170):
        x, y = rnd.randrange(4, W - 4), rnd.randrange(3, HORIZON - 30)
        if math.hypot(x - mx, y - my) < MOON_R + 20:
            continue
        r = rnd.random()
        col = 5 if r < 0.7 else (6 if r < 0.93 else 7)
        if c.get(x, y) == 4 and col == 5:
            col = 6
        c.set(x, y, col)
        stars.append((x, y, col))
    for (x, y) in [(212, 30), (402, 18), (548, 46), (300, 64), (606, 22), (150, 92)]:
        c.set(x, y, 7)
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            c.set(x + dx, y + dy, 5)
    return c


def star_sheet():
    """celulas 5x5; linha 0 = estrela pequena, linha 1 = estrela grande; coluna = frame."""
    c = Canvas(10, 10)
    small = [["..", "..", ".", "", ""]]
    # pequena: f0 = ponto 07 + cruz 05 ; f1 = ponto 06
    c.set(2, 2, 7)
    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        c.set(2 + dx, 2 + dy, 5)
    c.set(7, 2, 6)
    # grande: f0 = centro 08, bracos 06/05 ; f1 = centro 07, bracos 05 curtos
    c.set(2, 7, 8)
    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        c.set(2 + dx, 7 + dy, 6)
        c.set(2 + 2 * dx, 7 + 2 * dy, 5)
    c.set(7, 7, 7)
    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        c.set(7 + dx, 7 + dy, 5)
    return c


# ------------------------------------------------------------------ nuvens
def cloud(w, h, seed, lumps):
    """nuvem fina: corpo 04, borda de cima 05 (luar), base 03; sem contorno."""
    c = Canvas(w, h)
    rnd = random.Random(seed)
    base = h - 3
    tops = []
    for x in range(w):
        t = 0.0
        for (cx, r, a) in lumps:
            if abs(x - cx) < r:
                t = max(t, a * math.cos((x - cx) / r * math.pi / 2) ** 0.8)
        tops.append(t)
    for x in range(w):
        th = int(round(tops[x]))
        if th <= 0:
            continue
        y0 = base - th
        for y in range(y0, base + 1):
            v = 4
            if y == y0:
                v = 5
            elif y == base:
                v = 3
            c.set(x, y, v)
    # fiapos soltos nas pontas (1 px de altura) a direita e esquerda
    xs = [x for x in range(w) if tops[x] >= 1]
    if xs:
        x0, x1 = min(xs), max(xs)
        for (a, b, yy, col) in [(x0 - 14, x0 - 2, base - 1, 4), (x1 + 3, x1 + 20, base, 4),
                                (x0 - 26, x0 - 18, base, 3)]:
            for x in range(max(0, a), min(w, b)):
                c.set(x, yy, col)
    return c


def clouds():
    """atlas 160x16 por nuvem, empilhadas na vertical (3 celulas)."""
    a = Canvas(160, 48)
    a.blit(cloud(160, 16, 1, [(60, 30, 4), (92, 22, 6), (118, 18, 3)]), 0, 0)
    a.blit(cloud(160, 16, 2, [(70, 40, 3), (100, 16, 4)]), 0, 16)
    a.blit(cloud(160, 16, 3, [(50, 18, 3), (78, 26, 5), (108, 14, 2)]), 0, 32)
    return a


# ------------------------------------------------------------------ fundo distante
FAR_Y = 96             # posicao do topo de bg_a1_far na tela
FAR_H = H - FAR_Y      # 264


def far():
    """muro caiado com portao, cruzes, lapides e o ipe-roxo em 02/03/04 (luma <= 87)."""
    c = Canvas(W, FAR_H)
    hz = HORIZON - FAR_Y          # horizonte em coordenada local (54)
    rnd = random.Random(11)
    # chao: 03 junto ao horizonte, transicao para 02 em xadrez, 02 ate o fim
    for y in range(hz, FAR_H):
        for x in range(W):
            t = y - hz
            if t < 6:
                v = 3
            elif t < 12:
                v = 2 if (bayer(x, y) < (t - 6) * 2.7) else 3
            else:
                v = 2
            c.px[y][x] = v
    # muro caiado: corpo 05 (cal pegando luar), chapim 05 com sombra 04 embaixo,
    # rodape 03; pilastras com lado esquerdo 05 e direito 04; reboco caido em 04
    wall_top = hz - 14
    for x in range(W):
        for y in range(wall_top, hz + 1):
            v = 5
            if y == wall_top + 1:
                v = 4
            elif y >= hz - 1:
                v = 3
            c.set(x, y, v)
    for px in range(18, W, 84):
        for y in range(wall_top - 3, hz + 1):
            for x in range(px, px + 6):
                v = 5 if x < px + 4 else 4
                if y >= hz - 1:
                    v = 3
                c.set(x, y, v)
        for x in range(px - 1, px + 7):
            c.set(x, wall_top - 4, 5 if x < px + 5 else 4)
    for i in range(46):
        x = rnd.randrange(0, W - 6)
        y = rnd.randrange(wall_top + 3, hz - 3)
        wv = rnd.randrange(2, 6)
        for k in range(wv):
            if c.get(x + k, y) == 5:
                c.set(x + k, y, 4)
        if rnd.random() < 0.5 and c.get(x + 1, y + 1) == 5:
            c.set(x + 1, y + 1, 4)
    # portao de ferro (x 70..118): dois pilares altos, grade 02 com arco e pontas 04
    gx0, gx1 = 74, 116
    for y in range(wall_top - 1, hz + 1):
        for x in range(gx0 + 6, gx1 - 5):
            c.set(x, y, 0)       # vao do portao: ve o ceu atras (transparente)
    for (px0) in (gx0, gx1 - 6):
        for y in range(wall_top - 12, hz + 1):
            for x in range(px0, px0 + 6):
                v = 5 if x < px0 + 4 else 4
                if y >= hz - 1:
                    v = 3
                c.set(x, y, v)
        for x in range(px0 - 1, px0 + 7):
            c.set(x, wall_top - 13, 5 if x < px0 + 5 else 4)
            c.set(x, wall_top - 12, 4)
        c.rows(px0 + 1, wall_top - 17, [".LL.", "LLLV", ".LV.", "..."[:0] or "...."])
    gw0, gw1 = gx0 + 6, gx1 - 6
    mid = (gw0 + gw1) / 2
    for x in range(gw0, gw1):
        # arco: mais alto no meio
        k = abs(x + 0.5 - mid) / ((gw1 - gw0) / 2)
        top = int(round(wall_top - 9 + 6 * k * k))
        if (x - gw0) % 3 == 1:
            for y in range(top, hz + 1):
                c.set(x, y, 2)
            c.set(x, top - 1, 4)
        c.set(x, top, 2)
        c.set(x, top + 4, 2)
        c.set(x, hz - 6, 2)
    # arabescos: dois "S" pequenos no meio do portao
    for (ax, ay) in ((int(mid) - 5, wall_top - 2), (int(mid) + 2, wall_top - 2)):
        for (dx, dy) in ((1, 0), (2, 0), (0, 1), (1, 2), (2, 3), (0, 4), (1, 4)):
            c.set(ax + dx, ay + dy, 2)
    # cruzes e lapides atras do muro (so as pontas aparecem) e na frente (no chao)
    def cross(x, y, h=9, col=3, lit=4):
        for yy in range(y, y + h):
            c.set(x, yy, lit)
            c.set(x + 1, yy, col)
        for xx in range(x - 2, x + 4):
            c.set(xx, y + 2, lit if xx < x + 1 else col)
    def stone(x, y, w=6, h=7, col=3, lit=4):
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                if yy == y and xx in (x, x + w - 1):
                    continue
                c.set(xx, yy, lit if (xx == x or yy == y) else col)
    for (x, h) in [(150, 10), (196, 8), (232, 9), (452, 9), (498, 10), (604, 8), (40, 9), (136, 7)]:
        cross(x, wall_top - h + 3, h, 2, 3)
    for (x, y) in [(30, hz + 4), (128, hz + 6), (520, hz + 3), (612, hz + 6), (166, hz + 2)]:
        stone(x, y)
    for (x, y) in [(10, hz + 8), (150, hz + 10), (624, hz + 4), (476, hz + 7)]:
        cross(x, y, 10, 3, 4)
    # ipe-roxo (x ~ 556): silhueta 02 contra o ceu 03/04, aro de luar 03 no alto/esquerda,
    # cachos de flor 04 com ponto 05 do lado da lua
    tx = 556
    for y in range(hz - 36, hz + 2):
        wv = 3 if y < hz - 8 else (4 if y < hz - 2 else 6)
        x0 = tx - wv // 2
        for x in range(x0, x0 + wv):
            c.set(x, y, 3 if x == x0 else 2)
    for (x0, y0, dx, n) in [(tx - 1, hz - 26, -1, 18), (tx + 1, hz - 22, 1, 20), (tx, hz - 34, -1, 8),
                            (tx + 1, hz - 33, 1, 10)]:
        x, y = x0, y0
        for k in range(n):
            c.set(x, y, 2)
            c.set(x, y + 1, 2 if k < n * 0.6 else 0) if k < n * 0.6 else None
            x += dx
            if k % 2:
                y -= 1
    blobs = [(tx - 22, hz - 36, 12, 8), (tx - 12, hz - 50, 14, 10), (tx + 8, hz - 56, 15, 10),
             (tx + 24, hz - 44, 13, 9), (tx, hz - 40, 20, 11), (tx + 14, hz - 32, 10, 6),
             (tx - 26, hz - 46, 8, 6)]
    canopy = set()
    for y in range(hz - 74, hz - 22):
        for x in range(tx - 50, tx + 50):
            for (bx, by, rx, ry) in blobs:
                dx, dy = (x + 0.5 - bx) / rx, (y + 0.5 - by) / ry
                wob = 0.15 * math.sin(x * 1.3) * math.cos(y * 0.9)
                if dx * dx + dy * dy <= 1 + wob:
                    canopy.add((x, y))
                    break
    # corpo 03; borda de baixo/direita 02 (sombra); borda de cima/esquerda 04
    for (x, y) in canopy:
        up = (x, y - 1) not in canopy
        left = (x - 1, y) not in canopy
        down = (x, y + 1) not in canopy or (x, y + 2) not in canopy
        right = (x + 1, y) not in canopy
        v = 3
        if down or right:
            v = 2
        if up or left:
            v = 4
        c.set(x, y, v)
    # cachos de flor 04 (com 05 do lado da lua), densos no alto-esquerda
    pts = sorted(canopy)
    for k in range(260):
        (x, y) = rnd.choice(pts)
        if not all((x + dx, y + dy) in canopy for dx in range(-1, 3) for dy in range(-1, 3)):
            continue
        lit = (x - tx) * 0.5 + (y - (hz - 54)) < 8
        if not lit and rnd.random() < 0.5:
            continue
        for dx, dy in ((0, 0), (1, 0), (0, 1), (1, 1), (-1, 1)):
            c.set(x + dx, y + dy, 4)
        if lit:
            c.set(x, y, 5)
            if rnd.random() < 0.4:
                c.set(x + 1, y, 5)
    # tumulos no chao, mais perto da camera (maiores quanto mais baixos), so nas laterais
    for (x, y, k) in [(22, hz + 60, 1), (70, hz + 92, 2), (16, hz + 128, 3), (118, hz + 140, 2),
                      (604, hz + 70, 1), (560, hz + 108, 2), (614, hz + 150, 3), (520, hz + 168, 1)]:
        s_ = 1 + k // 2
        if k % 2:
            # cruz de madeira torta: 02 com aresta 03
            hh = 8 + 3 * k
            for yy in range(y - hh, y):
                for t in range(s_):
                    c.set(x + t, yy, 3 if t == 0 else 2)
            for xx in range(x - 2 - k, x + s_ + 2 + k):
                for t in range(s_):
                    c.set(xx, y - hh + 2 + k + t, 3 if t == 0 else 2)
        else:
            # lapide arredondada: 02 com topo/esquerda 03
            ww, hh = 6 + 2 * k, 7 + 3 * k
            for yy in range(y - hh, y):
                for xx in range(x, x + ww):
                    r = yy - (y - hh)
                    if r < 2 and (xx - x < 2 - r or x + ww - 1 - xx < 2 - r):
                        continue
                    c.set(xx, yy, 3 if (xx == x or r == 0 or (r == 1 and (xx - x) < 2)) else 2)
        for xx in range(x - 3, x + 4 + 2 * k):
            c.set(xx, y, 1)
            if (xx + y) % 2 == 0:
                c.set(xx + 1, y + 1, 1)
        c.set(x - 2, y - 1, 9)
        c.set(x - 1, y - 2, 9)
        c.set(x + 2 * k + 3, y - 1, 9)
    # petalas caidas no chao sob o ipe
    for i in range(18):
        x = tx + rnd.randrange(-36, 40)
        y = hz + rnd.randrange(1, 10)
        c.set(x, y, 4)
    # tufos de grama escura no chao, perto do horizonte
    for i in range(70):
        x = rnd.randrange(0, W)
        y = hz + rnd.randrange(2, 30)
        col = 9 if y > hz + 6 else 3
        if c.get(x, y) in (2, 3):
            c.set(x, y, 9)
            c.set(x + 1, y - 1, 9)
            c.set(x + 2, y, 9)
    return c


# ------------------------------------------------------------------ bloco de terra
FACE_H = 24
BLOCK_CELL = (32, 56)   # pivo (16, 16), igual ao tile


def _y_last_left(x):      # ultima linha do losango na coluna x (metade esquerda)
    return 16 + x // 2


def _y_last_right(x):
    return 16 + (31 - x) // 2


# perfis das camadas (t = linhas abaixo da borda), periodicos em 16 colunas
def _wob(x, amp, ph):
    return int(round(amp * math.sin((x + ph) * 2 * math.pi / 16)))


def face(side, variant, end=False, corner_edge=False):
    """side 'L' (frente-esquerda, iluminada) ou 'R' (frente-direita, sombra).
    Retorna Canvas 32x56 com so a metade correspondente desenhada."""
    c = Canvas(*BLOCK_CELL)
    rnd = random.Random(100 + variant * 7 + (0 if side == 'L' else 50))
    if side == 'L':
        cols = range(0, 16)
        ylast = _y_last_left
        pal = dict(g0=11, g1=10, g2=9, terra=15, terra_hi=16, terra_lo=14, barro=14,
                   barro_lo=13, fundo=13, fundo_lo=1, peb=6, peb_lo=5)
    else:
        cols = range(16, 32)
        ylast = _y_last_right
        pal = dict(g0=10, g1=9, g2=9, terra=14, terra_hi=15, terra_lo=13, barro=13,
                   barro_lo=1, fundo=13, fundo_lo=1, peb=5, peb_lo=4)
    for x in cols:
        y0 = ylast(x) + 1
        xl = x % 16
        b_grass = 3 + (1 if _wob(xl, 1, 3) > 0 else 0)
        b_terra = 10 + _wob(xl, 1, 9)
        b_barro = 18 + _wob(xl, 1, 1)
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
                    v = pal['terra_lo']          # sombra sob a grama
            elif t < b_barro:
                v = pal['barro']
                if t == b_terra:
                    v = pal['terra_lo'] if side == 'L' else pal['barro_lo']
            else:
                v = pal['fundo']
                if t >= FACE_H - 3 and side == 'R':
                    v = 1 if (x + y) % 2 == 0 else pal['fundo']
            c.set(x, y, v)
    # raizinhas/pingos de grama descendo (variante)
    for i in range(3):
        x = rnd.choice(list(cols))
        y = ylast(x) + 1 + 3
        if c.get(x, y) in (pal['terra'], pal['terra_lo']):
            c.set(x, y, pal['g1'])
            if rnd.random() < 0.5:
                c.set(x, y + 1, pal['g2'] if side == 'L' else 13)
    # pedrinhas: 2-3 por peca, 2x1 ou 1x1, com sombra embaixo
    placed = 0
    tries = 0
    while placed < 3 and tries < 50:
        tries += 1
        x = rnd.choice(list(cols)[1:-2])
        t = rnd.randrange(6, FACE_H - 3)
        y = ylast(x) + 1 + t
        wv = 2 if rnd.random() < 0.6 else 1
        if all(c.get(x + k, y) not in (0, 1, pal['g0'], pal['g1']) for k in range(wv)):
            for k in range(wv):
                c.set(x + k, y, pal['peb'])
                c.set(x + k, y + 1, pal['peb_lo'] if c.get(x + k, y + 1) not in (0, 1) else 1)
            placed += 1
    # especks de terra clara no lado iluminado
    if side == 'L':
        for i in range(4):
            x = rnd.choice(list(cols))
            t = rnd.randrange(4, 10)
            y = ylast(x) + 1 + t
            if c.get(x, y) == pal['terra']:
                c.set(x, y, pal['terra_hi'])
    if end:
        # ponta: aresta vertical de fora em 01
        x = 0 if side == 'L' else 31
        for y in range(ylast(x) + 1, ylast(x) + FACE_H + 1):
            if c.get(x, y):
                c.set(x, y, 1)
    if corner_edge and side == 'L':
        # quina da frente: coluna 15 (aresta) 1 degrau mais clara na terra/barro
        x = 15
        for t in range(1, FACE_H - 1):
            y = ylast(x) + 1 + t
            v = c.get(x, y)
            up = {15: 16, 14: 15, 13: 14, 10: 11}.get(v)
            if up:
                c.set(x, y, up)
    # sombra de contato no chao: 2 px (esq.) / 4 px (dir.) em 01, logo abaixo
    sh = 2 if side == 'L' else 4
    for x in cols:
        yb = ylast(x) + FACE_H
        for k in range(1, sh + 1):
            if side == 'R' and k >= 3 and (x + yb + k) % 2:
                continue
            c.set(x, yb + k, 1)
    return c


def block_atlas():
    """9 celulas 32x56 numa linha: 0-2 face esq. v1-v3, 3 ponta esq., 4-6 face dir. v1-v3,
    7 ponta dir., 8 quina da frente."""
    a = Canvas(32 * 9, 56)
    cells = []
    for v in range(3):
        cells.append(face('L', v))
    cells.append(face('L', 3, end=True))
    for v in range(3):
        cells.append(face('R', v))
    cells.append(face('R', 3, end=True))
    q = face('L', 4, corner_edge=True)
    q.blit(face('R', 4), 0, 0)
    cells.append(q)
    for i, cc in enumerate(cells):
        a.blit(cc, i * 32, 0)
    return a, cells


# ------------------------------------------------------------------ cerquinha
FENCE_CELL = (32, 32)   # pivo do tile em (16, 24)


def fence(kind):
    """kind 'NO' (borda de tras-esquerda, sobe para a direita) ou 'NE' (desce para a
    direita). Base 1 px acima da aresta de tras do losango do tile."""
    c = Canvas(*FENCE_CELL)
    if kind == 'NO':
        cols = list(range(0, 16))
        base = lambda x: 24 - x // 2 - 1          # linha logo acima da aresta
    else:
        cols = list(range(16, 32))
        base = lambda x: 24 - (31 - x) // 2 - 1
    # trilhos: 2 trilhos seguindo a diagonal (degraus 2-2-2)
    for x in cols:
        b = base(x)
        c.set(x, b - 2, 3)          # trilho de baixo
        c.set(x, b - 6, 4)          # trilho de cima (pega luar)
        c.set(x, b - 5, 2)
    # barras a cada 4 px, com ponta de lanca
    for x in cols:
        if (x % 4) == (1 if kind == 'NO' else 2):
            b = base(x)
            for y in range(b - 8, b + 1):
                c.set(x, y, 2)
            c.set(x, b - 9, 5)       # ponta de lanca iluminada
            c.set(x - 1, b - 8, 4)
            c.set(x + 1, b - 8, 2)
    return c


def fence_post():
    """poste de quina 6x14 (pivo (3, 13) = base). Pedra 03/04 com bola 05."""
    c = Canvas(6, 14)
    for y in range(3, 14):
        for x in range(1, 5):
            c.set(x, y, 4 if x == 1 else (2 if x == 4 else 3))
    for x in range(0, 6):
        c.set(x, 3, 4 if x < 4 else 3)
    c.rows(1, 0, [".LV.", "LVVI", ".II."])
    return c


def fence_atlas():
    a = Canvas(32 * 2 + 8, 32)
    a.blit(fence('NO'), 0, 0)
    a.blit(fence('NE'), 32, 0)
    a.blit(fence_post(), 64, 18)
    return a


# ------------------------------------------------------------------ tufos
TUFT_ROWS = [
    # 3 variantes x 2 frames, celula 12x8, base em y=7
    (["............",
      "....h.......",
      "...hG..h....",
      "h..GG.hG..h.",
      "Gh.GG.GG.hG.",
      "GG.GGhGG.GG.",
      "gGGGGGGGGGGg",
      ".gggggggggg."],
     ["............",
      ".....h......",
      "....Gh..h...",
      ".h..GG.Gh.h.",
      ".GhGG..GG.G.",
      "GG.GGhGG.GG.",
      "gGGGGGGGGGGg",
      ".gggggggggg."]),
    (["............",
      "......h.....",
      ".....hG.....",
      "..h..GG..h..",
      "..Gh.GG.hG..",
      "..GG.GGhGG..",
      ".gGGGGGGGGg.",
      "..gggggggg.."],
     ["............",
      ".......h....",
      "......Gh....",
      "...h..GG.h..",
      "...Gh.GGhG..",
      "..GG.GGhGG..",
      ".gGGGGGGGGg.",
      "..gggggggg.."]),
    (["............",
      "............",
      "..h......h..",
      "..Gh..h.hG..",
      ".hGG.hG.GG..",
      ".GGG.GGhGGh.",
      "gGGGGGGGGGGg",
      ".gggggggggg."],
     ["............",
      "............",
      "...h......h.",
      "...Gh.h..hG.",
      ".hGG..GhGG..",
      ".GGGhGG.GGh.",
      "gGGGGGGGGGGg",
      ".gggggggggg."]),
]


def tufts():
    a = Canvas(24, 24)
    for r, (f0, f1) in enumerate(TUFT_ROWS):
        a.rows(0, r * 8, f0)
        a.rows(12, r * 8, f1)
    return a


# ------------------------------------------------------------------ placa
def sign():
    """placa de madeira 56x26 num poste; area de texto 48x9 em (4, 5). Pivo (28, 25)."""
    c = Canvas(56, 26)
    # poste
    for y in range(14, 26):
        c.set(27, y, 19)
        c.set(28, y, 18)
        c.set(26, y, 1)
        c.set(29, y, 1)
    # tabua
    x0, y0, w, h = 1, 2, 54, 14
    for y in range(y0, y0 + h):
        for x in range(x0, x0 + w):
            edge = x in (x0, x0 + w - 1) or y in (y0, y0 + h - 1)
            v = 1 if edge else 19
            if not edge and (y == y0 + 1 or x == x0 + 1):
                v = 20
            if not edge and (y == y0 + h - 2):
                v = 18
            c.set(x, y, v)
    for (x, y) in ((x0, y0), (x0 + w - 1, y0), (x0, y0 + h - 1), (x0 + w - 1, y0 + h - 1)):
        c.set(x, y, 0)
    # veio da madeira
    for x in range(x0 + 4, x0 + 14):
        c.set(x, y0 + 9, 18)
    for x in range(x0 + 34, x0 + 46):
        c.set(x, y0 + 11, 18)
    # pregos (05: decoracao, sem cor de recompensa)
    for (x, y) in ((x0 + 2, y0 + 2), (x0 + w - 3, y0 + 2)):
        c.set(x, y, 5)
    # texto entalhado "N 1" nao: deixa so a area; prevista em (5,5) 30x8
    return c


def sign_with_text(text='PARÓQUIA'):
    import font5x7 as F
    c = sign()
    w = F.width(text)
    x = 28 - w // 2
    F.draw(c, x, 6, text, 18)
    return c


# ------------------------------------------------------------------ nevoa
def mist(w, h, seed, dens=1.0):
    """faixa de nevoa que repete na horizontal (periodo = w). Densidade = ruido suave
    periodico em x vezes um perfil vertical; 3 niveis de xadrez."""
    c = Canvas(w, h)
    rnd = random.Random(seed)
    harm = [(rnd.uniform(0, 6.28), k, rnd.uniform(0.5, 1.0)) for k in (1, 2, 3, 4, 6, 9)]
    def n1(x):
        return sum(a * math.sin(2 * math.pi * k * x / w + ph) / k ** 0.6 for (ph, k, a) in harm)
    for x in range(w):
        amt = 0.28 + 0.5 * n1(x)                 # quanto de nevoa nesta coluna (com falhas)
        cy = h * 0.58 + 2.5 * math.sin(2 * math.pi * 3 * x / w + harm[1][0])
        th = h * 0.42 * max(0.0, amt) * dens
        for y in range(h):
            if th <= 0.5:
                continue
            d = abs(y + 0.5 - cy) / th
            if y + 0.5 < cy:
                d *= 1.25                         # topo mais ralo
            if d < 0.3 and amt > 0.8:
                v = 5 if (x + y) % 2 == 0 else 4      # miolo denso: 05/04
            elif d < 0.7:
                v = 4 if (x + y) % 2 == 0 else 0      # xadrez 04/transparente
            elif d < 1.0:
                v = 4 if (x % 2 == 0 and y % 2 == 0) else 0
            else:
                v = 0
            if v:
                c.set(x, y, v)
    return c


def mist_atlas():
    a = Canvas(320, 48)
    a.blit(mist(320, 24, 3, 1.0), 0, 0)
    a.blit(mist(320, 24, 9, 0.8), 0, 24)
    return a


# ------------------------------------------------------------------ vinheta
def vignette():
    """cantos escuros: 01 solido, xadrez 01/02, xadrez 02/transp., 25% 02; meio transparente."""
    c = Canvas(W, H)
    for y in range(H):
        for x in range(W):
            nx = (x + 0.5 - W / 2) / (W / 2)
            ny = (y + 0.5 - H / 2) / (H / 2)
            d = (nx * nx + ny * ny) ** 0.5
            if d > 1.32:
                v = 1
            elif d > 1.25:
                v = 1 if (x + y) % 2 == 0 else 2
            elif d > 1.17:
                v = 2 if (x + y) % 2 == 0 else 0
            elif d > 1.10:
                v = 2 if (x % 2 == 0 and y % 2 == 0) else 0
            else:
                v = 0
            if v:
                c.px[y][x] = v
    return c
