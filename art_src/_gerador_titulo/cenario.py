"""Tela-titulo (docs/03_UI_UX.md §9): ceu 640x600, vila na colina, janelas, muro com portao,
primeiro plano (monte de terra, lapide do Tiao, tronco do ipe) e copa do ipe animada.
Tudo em indices da Lua de Cova 32 (0 = transparente). As camadas sao desenhadas em
coordenadas de TELA do enquadramento final (640x360) e recortadas na posicao da camada."""
import math
import random
from common import Canvas

W, H = 640, 360
SKY_H = 600
SKY_OFF = 240            # o ceu fica em y = -240 no enquadramento final

N4 = ((1, 0), (-1, 0), (0, 1), (0, -1))
N8 = N4 + ((1, 1), (1, -1), (-1, 1), (-1, -1))

# ------------------------------------------------------------------ layout (tela)
MOON_C = (96, 64)
MOON_R = 28
LOGO_BOX = (206, 0, 440, 114)          # area sem estrelas (logo + subtitulo)
BTN_BOX = (372, 168, 476, 308)         # coluna dos botoes (nada de alto contraste atras)

VILLAGE_Y = 140                         # topo da camada title_village na tela
WALL_Y = 200                            # topo da camada title_wall
FG_Y = 160                              # topo da camada title_fg
CANOPY_POS = (476, 96)                  # canto sup. esq. da copa (title_fg_canopy)
CANOPY_W, CANOPY_H = 164, 150

WALL_TOP = 239                          # chapim
WALL_BASE = 262                         # primeira linha de chao na frente do muro
GATE_L = (250, 259)                     # pilar esquerdo do portao (x0, x1)
GATE_R = (291, 300)                     # pilar direito
GATE_OPEN = (260, 290)                  # vao (x0, x1) visto atraves da camada do muro

# trilha das almas: pes das alminhas (tela), da vila ate o portao
TRAIL = [(204, 207), (230, 214), (252, 222), (240, 228), (258, 233), (272, 239), (276, 247), (276, 257)]
SOUL_VANISH = (276, 257)

# primeiro plano
GROUND_FG = 326                         # linha media do topo do chao do primeiro plano
COVEIRO = (96, 303)                     # pivo (16, 31) do coveiro_title = centro do topo plano
PLATEAU = (COVEIRO[0] - 16, COVEIRO[0] + 16)   # topo plano do monte: 1a linha de terra em y = 304
PA_CRAVADA = (COVEIRO[0] - 12, COVEIRO[1])     # pivo (4, 25) da pa_cravada (-12, 0)
LANTERNA = (COVEIRO[0] + 12, COVEIRO[1])       # pivo (6, 15) da lanterna_chao (+12, 0)
TOMB_X0, TOMB_X1 = 156, 171             # face da lapide do Tiao (x0..x1), lado 172..174
TOMB_TOP, TOMB_BASE = 314, 338
TIAO = (164, 312)                       # pivo (8, 15) do tiao: linha logo acima do contorno do topo da lapide
TRUNK_BASE = (604, 340)


def bayer(x, y):
    m = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]
    return m[y % 4][x % 4]


def checker(x, y):
    return (x + y) % 2 == 0


def in_box(x, y, box, pad=0):
    x0, y0, x1, y1 = box
    return x0 - pad <= x <= x1 + pad and y0 - pad <= y <= y1 + pad


def floaters(c):
    """pixels opacos sem nenhum vizinho opaco (8-viz.): proibidos fora do ceu."""
    out = []
    for y in range(c.h):
        for x in range(c.w):
            if c.px[y][x] and not any(c.get(x + dx, y + dy) for dx, dy in N8):
                out.append((x, y))
    return out


# =================================================================== ceu
def sky():
    """640x600 em coordenadas locais (y_tela = y_local - 240). 02 -> 03 -> 04 em dither."""
    c = Canvas(W, SKY_H, 2)
    bands = [(310, 2, 3), (380, 3, 4)]       # inicio local da transicao (5 passos de 3 linhas)
    for y in range(SKY_H):
        col = 2
        for (y0, a, b) in bands:
            if y >= y0 + 15:
                col = b
        for x in range(W):
            v = col
            for (y0, a, b) in bands:
                if y0 <= y < y0 + 15:
                    step = (y - y0) // 3
                    thr = 16 * (step + 1) / 6.0
                    v = b if bayer(x, y) < thr else a
            c.px[y][x] = v
    mx, my = MOON_C[0], MOON_C[1] + SKY_OFF
    R = MOON_R
    # halo em xadrez (fonte emissiva: halo grande = dither de 2 cores)
    for y in range(my - R - 20, my + R + 21):
        for x in range(mx - R - 20, mx + R + 21):
            d = math.hypot(x - mx, y - my)
            if R < d <= R + 5:
                c.set(x, y, 5 if checker(x, y) else 4)
            elif R + 5 < d <= R + 14:
                if checker(x, y):
                    c.set(x, y, 4)
            elif R + 14 < d <= R + 19:
                if x % 2 == 0 and y % 2 == 0 and c.get(x, y) in (2, 3):
                    c.set(x, y, 4)
    # disco 08, mares 07, crateras 06, borda de baixo/direita em 07
    k = R / 25.0
    maria = [(-7, -10, 5), (0, -7, 6), (7, -2, 5), (10, 5, 4), (2, 9, 3), (-11, 3, 3)]
    for y in range(my - R, my + R + 1):
        for x in range(mx - R, mx + R + 1):
            dx, dy = x - mx, y - my
            d = math.hypot(dx, dy)
            if d <= R:
                v = 8
                for (ox, oy, r) in maria:
                    if math.hypot(dx - ox * k, dy - oy * k) <= r * k:
                        v = 7
                if d > R - 2.4 and (dx + dy) > 7:
                    v = 7
                c.set(x, y, v)
    for (ox, oy) in [(-10, -8), (7, 6), (-6, 10), (15, -3), (4, -13), (-15, 8)]:
        c.set(mx + ox, my + oy, 6)
        c.set(mx + ox + 1, my + oy, 7)
    # estrelas fixas: longe da lua, do logo e do horizonte
    rnd = random.Random(31)
    n = 0
    while n < 300:
        x, y = rnd.randrange(3, W - 3), rnd.randrange(3, 390)
        ys = y - SKY_OFF
        if math.hypot(x - mx, y - my) < R + 24:
            continue
        if in_box(x, ys, LOGO_BOX):
            continue
        if any(c.get(x + dx, y + dy) not in (2, 3, 4) for dx, dy in N8):
            continue
        r = rnd.random()
        col = 5 if r < 0.68 else (6 if r < 0.92 else 7)
        if c.get(x, y) == 4 and col == 5:
            col = 6
        c.set(x, y, col)
        n += 1
    for (x, ys) in [(30, -150), (180, -120), (330, -170), (470, -110), (600, -140), (250, -60),
                    (560, -40), (40, 120), (500, 6), (610, 70), (170, 130), (470, 120), (24, 30)]:
        y = ys + SKY_OFF
        c.set(x, y, 7)
        for dx, dy in N4:
            c.set(x + dx, y + dy, 5)
    for (x, ys) in [(150, -90), (420, -200), (590, 16)]:
        y = ys + SKY_OFF
        c.set(x, y, 8)
        for dx, dy in N4:
            c.set(x + dx, y + dy, 6)
            c.set(x + 2 * dx, y + 2 * dy, 5)
    return c


# =================================================================== vila
def far_ridge(x):
    return round(205 + 4 * math.sin(x / 61.0 + 1.0) + 2.5 * math.sin(x / 23.0))


def near_hill(x):
    return round(238 - 46 * math.exp(-((x - 180) / 80.0) ** 2) + 1.2 * math.sin(x / 31.0))


def iso_roof(c, x0, x1, ytop_eave, col, edge=None):
    """telhado de duas aguas em degraus 2-2-2: linha da beirada de x0 a x1 em ytop_eave,
    cada linha acima entra 2 px de cada lado. Retorna o y do cume."""
    y = ytop_eave
    a, b = x0, x1
    while b - a >= 1:
        for x in range(a, b + 1):
            c.set(x, y, col)
        if edge is not None:
            c.set(a, y, edge)
            c.set(a + 1, y, edge)
        a += 2
        b -= 2
        y -= 1
    return y + 1


WINDOWS = []        # (x, y) canto sup. esq. de cada janela 2x3 (tela)


def house(c, x, base, w, hw, wins=(), door=None, side=2):
    """casinha: fachada 04, lateral direita 03, telhado 03 com beiral 02, porta 02, janelas 02."""
    top = base - hw
    for y in range(top, base):
        for xx in range(x, x + w):
            c.set(xx, y, 4)
        for xx in range(x + w, x + w + side):
            c.set(xx, y, 3)
    for xx in range(x, x + w + side):
        c.set(xx, top, 2 if xx >= x + w else 3)        # sombra do beiral
    iso_roof(c, x - 1, x + w + side, top - 1, 3)
    # cumeeira com luar (1 px a esquerda do cume)
    if door is not None:
        for y in range(base - 4, base):
            c.set(x + door, y, 2)
            c.set(x + door + 1, y, 2)
    for (wx, wy) in wins:
        for dy in range(3):
            for dx in range(2):
                c.set(x + wx + dx, top + wy + dy, 2)
        WINDOWS.append((x + wx, top + wy))


def church(c):
    """igreja na crista: torre e nave em silhueta 03 com aresta de luar 04."""
    tx, tw = 184, 10
    base = near_hill(189) + 2
    ttop = 160
    for y in range(ttop, base):
        for x in range(tx, tx + tw):
            v = 3
            if x == tx:
                v = 4
            elif x == tx + tw - 1:
                v = 2
            c.set(x, y, v)
    for x in range(tx - 1, tx + tw + 1):         # cornija
        c.set(x, ttop, 4 if x < tx + 3 else 3)
        c.set(x, ttop + 1, 2)
    # coruchéu (degraus 1 px por linha, pontudo)
    a, b, y = tx, tx + tw - 1, ttop - 1
    while a <= b:
        for x in range(a, b + 1):
            c.set(x, y, 2 if x > (tx + tx + tw - 1) // 2 else 3)
        c.set(a, y, 4)
        a += 1
        b -= 1
        y -= 1
        if b - a < 0:
            break
        for x in range(a, b + 1):
            c.set(x, y, 2 if x > (tx + tx + tw - 1) // 2 else 3)
        c.set(a, y, 4)
        y -= 1
    cx = tx + tw // 2
    ytip = y + 1
    for yy in range(ytip - 6, ytip):
        c.set(cx, yy, 3)
    c.set(cx - 1, ytip - 4, 3)
    c.set(cx + 1, ytip - 4, 3)
    # janelas da torre (sino e janela de baixo)
    for (wx, wy) in ((tx + 4, ttop + 6), (tx + 4, ttop + 18)):
        for dy in range(3):
            for dx in range(2):
                c.set(wx + dx, wy + dy, 2)
        WINDOWS.append((wx, wy))
    # nave a direita da torre
    nx0, nx1 = tx + tw, tx + tw + 26
    ntop = 180
    for y in range(ntop, base + 2):
        for x in range(nx0, nx1):
            c.set(x, y, 4 if x < nx0 + 22 else 3)
    for x in range(nx0, nx1):
        c.set(x, ntop, 3)
    iso_roof(c, nx0 - 1, nx1, ntop - 1, 3)
    for k, wx in enumerate((nx0 + 5, nx0 + 11, nx0 + 17)):
        for dy in range(4):
            for dx in range(2):
                c.set(wx + dx, ntop + 5 + dy, 2)
        WINDOWS.append((wx, ntop + 5))
    for y in range(base - 5, base + 2):        # porta da igreja (sai a trilha)
        for x in range(nx0 + 9, nx0 + 13):
            c.set(x, y, 2)


def trail_points(step=1.0):
    """pontos inteiros ao longo da polilinha TRAIL."""
    pts = []
    for (x0, y0), (x1, y1) in zip(TRAIL, TRAIL[1:]):
        n = int(max(abs(x1 - x0), abs(y1 - y0)) / step)
        for i in range(n):
            t = i / n
            pts.append((round(x0 + (x1 - x0) * t), round(y0 + (y1 - y0) * t)))
    pts.append(TRAIL[-1])
    return pts


def village():
    WINDOWS.clear()
    c = Canvas(W, H)
    rnd = random.Random(5)
    # serra ao longe (03) com aro de luar 04 no topo
    for x in range(W):
        r = far_ridge(x)
        for y in range(r, H):
            c.set(x, y, 3)
        c.set(x, r, 4 if (x // 3) % 4 != 3 else 3)
    # arvores redondas na serra (silhueta 02) longe do logo/botoes
    for (tx, r) in [(22, 6), (54, 5), (326, 5), (612, 6), (585, 4)]:
        gy = far_ridge(tx)
        for y in range(gy - 2 * r - 2, gy + 1):
            for x in range(tx - r - 1, tx + r + 2):
                if math.hypot(x - tx, (y - (gy - r - 1)) * 1.1) <= r:
                    c.set(x, y, 2)
        for y in range(gy - 2, gy + 1):
            c.set(tx, y, 2)
    # colina da vila (02) com aro de luar 03 (2 px na encosta da esquerda)
    for x in range(W):
        h = near_hill(x)
        for y in range(h, H):
            c.set(x, y, 2)
        lit = near_hill(x - 1) >= h        # sobe para a direita: encosta virada para a lua
        c.set(x, h, 3)
        if lit and x < 200:
            c.set(x, h + 1, 3)
    # casinhas (de tras para a frente)
    houses = [
        # x, base, w, hw, janelas (relativas ao topo), porta
        (150, 205, 12, 8, [(2, 3), (8, 3)], None),
        (216, 208, 12, 7, [(2, 2)], 7),
        (128, 213, 14, 8, [(3, 3), (9, 3)], None),
        (166, 214, 10, 7, [(2, 2)], 6),
        (236, 216, 12, 7, [(7, 2)], 2),
        (112, 224, 12, 8, [(2, 3)], 7),
        (142, 224, 14, 8, [(2, 3), (8, 3)], None),
        (198, 222, 10, 7, [(5, 2)], 1),
        (176, 228, 12, 7, [(2, 2), (8, 2)], None),
        (214, 230, 12, 7, [(2, 2)], 7),
        (96, 232, 10, 6, [(5, 2)], 1),
    ]
    church(c)
    for (x, base, w, hw, wins, door) in houses:
        house(c, x, base, w, hw, wins, door)
    # muros baixos e arbustos entre as casas (02/03), sem ruido solto
    for (x, y, w) in [(124, 226, 10), (190, 230, 8), (160, 216, 4), (228, 218, 6)]:
        for xx in range(x, x + w):
            c.set(xx, y, 3)
            c.set(xx, y + 1, 2)
    # trilha: centro 04, bordas 03 (largura 3)
    pts = trail_points(0.5)
    for (x, y) in pts:
        for dx in (-1, 0, 1):
            if c.get(x + dx, y) == 2:
                c.set(x + dx, y, 3)
        c.set(x, y + 1, 3) if c.get(x, y + 1) == 2 else None
    for (x, y) in pts:
        c.set(x, y, 4)
    # pedrinhas 05 na beira iluminada da trilha
    for i, (x, y) in enumerate(pts[::17]):
        if c.get(x - 2, y) == 2:
            c.set(x - 2, y, 3)
    return c


def windows_sheet():
    """celula 2x3, frame 0 = apagada (02), frame 1 = acesa (26 em cima, 25 embaixo)."""
    c = Canvas(4, 3)
    for y in range(3):
        for x in range(2):
            c.set(x, y, 2)
            c.set(2 + x, y, 26 if y == 0 else 25)
    c.set(2, 0, 23)      # nucleo 1 px (fonte emissiva)
    return c


# =================================================================== muro
def wall():
    c = Canvas(W, H)
    rnd = random.Random(12)
    # chao do meio (09) com faixa de sombra 02 ao pe do muro
    for y in range(WALL_BASE, H):
        for x in range(W):
            c.set(x, y, 9)
    # sombra ao pe do muro: 02 e depois xadrez 75/50/25% ate o 09
    for x in range(W):
        c.set(x, WALL_BASE, 2)
        for k, thr in enumerate((12, 8, 4)):
            for j in range(2):
                y = WALL_BASE + 1 + 2 * k + j
                if bayer(x, y) < thr:
                    c.set(x, y, 2)
    # trilha de terra saindo do portao (14, bordas 13, pedrinhas 15)
    for y in range(WALL_BASE, H):
        t = (y - WALL_BASE) / (H - WALL_BASE)
        cx = 275 + round(10 * t * t + 2 * math.sin(y / 9.0))
        hw = 9 + round(26 * t)
        for x in range(cx - hw, cx + hw + 1):
            e = x in (cx - hw, cx + hw)
            c.set(x, y, 13 if e else 14)
    for i in range(40):
        y = rnd.randrange(WALL_BASE + 3, H - 2)
        t = (y - WALL_BASE) / (H - WALL_BASE)
        cx = 275 + round(10 * t * t + 2 * math.sin(y / 9.0))
        hw = 9 + round(26 * t)
        x = rnd.randrange(cx - hw + 2, cx + hw - 2)
        c.set(x, y, 15)
        c.set(x + 1, y, 15)
        c.set(x + 1, y + 1, 13)
    # tufos de grama 10 (com ponta 11 rara) no chao do meio
    for i in range(170):
        x, y = rnd.randrange(0, W), rnd.randrange(WALL_BASE + 3, H)
        if c.get(x, y) != 9 or c.get(x + 2, y) != 9:
            continue
        hgt = 1 + (y - WALL_BASE) // 30
        for k in range(hgt):
            c.set(x, y - k, 10)
        c.set(x + 1, y, 10)
        if rnd.random() < 0.3 and hgt > 1:
            c.set(x, y - hgt + 1, 11)
    # ---- muro caiado: chapim, corpo 05, rodape 03
    for x in range(W):
        c.set(x, WALL_TOP, 5)
        c.set(x, WALL_TOP + 1, 5)
        c.set(x, WALL_TOP + 2, 4)
        for y in range(WALL_TOP + 3, WALL_BASE - 3):
            c.set(x, y, 5)
        for y in range(WALL_BASE - 3, WALL_BASE):
            c.set(x, y, 3)
        c.set(x, WALL_BASE - 3, 4)
    # manchas de umidade escorrendo do chapim (04)
    for i in range(16):
        x = rnd.randrange(0, W - 2)
        n = rnd.randrange(2, 7)
        for k in range(n):
            if c.get(x, WALL_TOP + 3 + k) == 5:
                c.set(x, WALL_TOP + 3 + k, 4)
        if c.get(x + 1, WALL_TOP + 3) == 5:
            c.set(x + 1, WALL_TOP + 3, 4)
    # reboco descascado com tijolinho (19/18) e borda 04
    for (x, y, w, h) in [(28, 247, 9, 5), (140, 250, 7, 4), (214, 245, 6, 5), (330, 249, 8, 4),
                         (520, 246, 9, 5), (600, 251, 6, 4), (430, 252, 6, 3)]:
        for yy in range(y - 1, y + h + 1):
            for xx in range(x - 1, x + w + 1):
                if c.get(xx, yy) == 5:
                    c.set(xx, yy, 4)
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                brick = 19 if ((xx + (3 if (yy // 2) % 2 else 0)) % 6 != 0 and yy % 2 == 0) else 18
                c.set(xx, yy, brick)
    # pilastras (lado esquerdo 05, direito 04), chapeu 1 px mais largo
    for px in list(range(14, 240, 88)) + list(range(320, W, 88)):
        for y in range(WALL_TOP - 5, WALL_BASE):
            for x in range(px, px + 7):
                v = 5 if x < px + 5 else 4
                if y >= WALL_BASE - 3:
                    v = 3
                c.set(x, y, v)
        for x in range(px - 1, px + 8):
            c.set(x, WALL_TOP - 6, 5 if x < px + 6 else 4)
            c.set(x, WALL_TOP - 5, 4)
    # ---- portao: vao transparente, pilares altos com bola, arco de ferro, folhas abertas
    for y in range(0, WALL_BASE):
        for x in range(GATE_OPEN[0], GATE_OPEN[1] + 1):
            c.set(x, y, 0)
    for (x0, x1) in (GATE_L, GATE_R):
        for y in range(220, WALL_BASE):
            for x in range(x0, x1 + 1):
                v = 5 if x < x1 - 2 else 4
                if x == x0:
                    v = 5
                if y >= WALL_BASE - 3:
                    v = 3
                c.set(x, y, v)
        for x in range(x0 - 1, x1 + 2):          # capitel
            c.set(x, 218, 5 if x < x1 else 4)
            c.set(x, 219, 4)
        # almofadas em baixo relevo
        for y in range(226, 252):
            c.set(x0 + 2, y, 4)
        for x in range(x0 + 2, x1 - 2):
            c.set(x, 226, 4)
        # bola
        bx = (x0 + x1) // 2
        for (dx, dy, v) in [(-1, -5, 5), (0, -5, 5), (1, -5, 4), (-2, -4, 5), (-1, -4, 5), (0, -4, 5),
                            (1, -4, 5), (2, -4, 4), (-2, -3, 5), (-1, -3, 5), (0, -3, 5), (1, -3, 4),
                            (2, -3, 4), (-1, -2, 4), (0, -2, 4), (1, -2, 4), (0, -1, 4)]:
            c.set(bx + dx, 218 + dy, v)
    # arco de ferro (01 com brilho 04 em cima/esquerda): duas curvas e cruz no topo
    gx0, gx1 = GATE_OPEN
    mid = (gx0 + gx1) / 2.0
    half = (gx1 - gx0) / 2.0
    arc_top = {}
    for x in range(gx0, gx1 + 1):
        k = abs(x - mid) / half
        yt = round(223 + 7 * k * k)
        arc_top[x] = yt
        c.set(x, yt, 1)
        c.set(x, yt + 5, 1)
        if x < mid:
            c.set(x, yt - 1, 4) if c.get(x, yt - 1) == 0 else None
    # volutas (arabescos) entre as duas curvas
    for (ax, flip) in ((int(mid) - 8, 1), (int(mid) + 3, -1)):
        pat = [(0, 1), (1, 1), (2, 2), (2, 3), (1, 4), (0, 3)]
        for (dx, dy) in pat:
            xx = ax + (dx if flip > 0 else 4 - dx)
            c.set(xx, arc_top[min(max(xx, gx0), gx1)] + dy, 1)
    for y in range(arc_top[int(mid)] - 8, arc_top[int(mid)]):
        c.set(int(mid), y, 1)
    for x in range(int(mid) - 2, int(mid) + 3):
        c.set(x, arc_top[int(mid)] - 6, 1)
    c.set(int(mid) - 1, arc_top[int(mid)] - 7, 4)
    c.set(int(mid) - 1, arc_top[int(mid)] - 9, 4)
    c.set(int(mid), arc_top[int(mid)] - 9, 1)
    # folhas do portao abertas para dentro (estreitas, junto dos pilares)
    for side in (0, 1):
        xs = [gx0 + 1, gx0 + 3, gx0 + 5] if side == 0 else [gx1 - 1, gx1 - 3, gx1 - 5]
        for x in xs:
            for y in range(232, WALL_BASE - 2):
                c.set(x, y, 1)
            c.set(x, 231, 1)
            c.set(x, 230, 4)              # ponta de lanca com luar
        for y in (234, 245, 256):
            for x in range(min(xs), max(xs) + 1):
                c.set(x, y, 1)
        lit = xs[0] if side == 0 else xs[2]
        for y in range(233, WALL_BASE - 3, 4):
            c.set(lit, y, 4) if side == 0 else None
    # soleira (04 em cima, 03 embaixo)
    for x in range(GATE_L[0] + 6, GATE_R[1] - 5):
        c.set(x, WALL_BASE - 2, 4)
        c.set(x, WALL_BASE - 1, 3)
    # moitas encostadas no muro (09, topo 10, base 02)
    for (bx, r) in [(22, 9), (122, 7), (206, 11), (334, 8), (512, 10), (612, 7), (232, 6)]:
        for y in range(WALL_BASE - r, WALL_BASE + 2):
            for x in range(bx - r - 3, bx + r + 4):
                u, v = (x - bx) / (r + 3.0), (y - WALL_BASE - 1) / float(r)
                q = u * u + v * v
                if q > 1.0:
                    continue
                s = u * 0.7 + v * 0.7
                c.set(x, y, 10 if s < -0.45 else (9 if s < 0.35 else 2))
    # ---- tumulos entre o muro e o primeiro plano
    graves = [
        ('lap', 34, 280, 7, 9), ('cruz', 70, 271, 7, 11), ('lap', 118, 276, 6, 8), ('tumulo', 168, 288, 18, 7),
        ('cruz', 214, 280, 7, 12), ('lap', 236, 296, 8, 11), ('cerca', 8, 300, 22, 6),
        ('lap', 322, 286, 7, 9), ('cruz', 350, 272, 6, 10), ('lap', 394, 280, 7, 9), ('cruz', 446, 292, 8, 13),
        ('tumulo', 404, 304, 20, 8), ('lap', 492, 274, 6, 8), ('cruz', 520, 300, 8, 14), ('lap', 556, 284, 7, 10),
        ('lap', 632, 296, 8, 11), ('cruz', 196, 312, 9, 16), ('lap', 352, 316, 9, 12), ('lap', 470, 318, 9, 12),
    ]
    for kind, x, base, w, h in graves:
        grave(c, kind, x, base, w, h, rnd)
    return c


def grave(c, kind, x, base, w, h, rnd):
    """props do meio do quadro: pedra 04/05 (aresta lit 05, lado 03), madeira 18/19, ferro 01."""
    far = base < 300
    if kind == 'lap':
        # sombra no chao, para baixo/direita
        for xx in range(x + 1, x + w + 3):
            c.set(xx, base, 2)
        for y in range(base - h, base):
            for xx in range(x, x + w):
                r = 2 if w >= 8 else 1
                top = base - h
                if y - top < r and (xx - x < r - (y - top) or (x + w - 1 - xx) < r - (y - top)):
                    continue
                v = 4
                if xx == x or y == top or (y - top < r and xx - x <= r - (y - top)):
                    v = 5
                if xx == x + w - 1:
                    v = 3
                c.set(xx, y, v)
            c.set(x + w, y, 3) if y > base - h + 1 else None
        # inscricao (2 risquinhos 03)
        for k in range(2):
            for xx in range(x + 2, x + w - 2):
                c.set(xx, base - h + 3 + 2 * k, 3)
        if rnd.random() < 0.5 and not far:
            c.set(x - 1, base - 1, 31)
            c.set(x - 2, base - 2, 31)
            c.set(x - 1, base - 2, 10)
    elif kind == 'cruz':
        for xx in range(x + w // 2 - 1 + 1, x + w // 2 + 4):
            c.set(xx, base, 2)
        cx = x + w // 2
        for y in range(base - h, base):
            c.set(cx - 1, y, 19)
            c.set(cx, y, 18)
        ay = base - h + 2 + (1 if h > 12 else 0)
        for xx in range(x, x + w):
            c.set(xx, ay, 19 if xx < cx else 18)
            if h > 12:
                c.set(xx, ay + 1, 18)
        c.set(cx - 1, base - h, 20) if not far else None
    elif kind == 'tumulo':
        # laje baixa com cruzinha: tampa 05, frente 04, lado 03
        for y in range(base - h, base):
            for xx in range(x, x + w):
                v = 4
                if y == base - h:
                    v = 5
                elif y == base - h + 1:
                    v = 4
                if xx == x + w - 1:
                    v = 3
                c.set(xx, y, v)
        for xx in range(x + 2, x + w + 2):
            c.set(xx, base, 2)
        cx = x + w // 2
        for y in range(base - h - 6, base - h):
            c.set(cx, y, 4)
        for xx in range(cx - 2, cx + 3):
            c.set(xx, base - h - 4, 4)
        c.set(cx - 2, base - h - 4, 5)
        c.set(x + 3, base - h - 1, 31)
        c.set(x + 4, base - h - 1, 31)
        c.set(x + 3, base - h - 2, 10)
    elif kind == 'cerca':
        for xx in range(x, x + w):
            c.set(xx, base - h + 1, 1)
        for xx in range(x, x + w, 3):
            for y in range(base - h, base + 1):
                c.set(xx, y, 1)
            c.set(xx, base - h - 1, 3)
        for xx in range(x + 2, x + w - 2):
            c.set(xx, base - 2, 15 if xx % 3 else 14)
            c.set(xx, base - 1, 14)


# =================================================================== primeiro plano
def ground_y(x):
    return GROUND_FG + round(1.4 * math.sin(x / 17.0) + 0.9 * math.sin(x / 7.1 + 1.0))


MOUND_LUMPS = [  # (cx, cy, rx, ry) de tras para a frente; o monte e uma soma de domos
    (96, 336, 58, 33), (74, 318, 20, 19), (104, 314, 20, 11), (128, 326, 22, 12),
    (60, 328, 20, 10), (112, 334, 26, 9), (80, 334, 24, 8),
]
LIGHT = (-0.55, -0.62, 0.56)       # luar do alto a esquerda, vindo um pouco da frente


def mound_shade():
    """{(x, y): (indice_lump, valor de luz)}; o domo mais a frente ganha o pixel."""
    out = {}
    for i, (cx, cy, rx, ry) in enumerate(MOUND_LUMPS):
        for y in range(cy - ry, min(cy + 1, 335)):
            for x in range(cx - rx, cx + rx + 1):
                u, v = (x - cx) / rx, (y - cy) / ry
                q = u * u + v * v
                if q > 1.0:
                    continue
                nz = math.sqrt(max(0.0, 1 - q))
                lv = u * LIGHT[0] + v * LIGHT[1] + nz * LIGHT[2]
                out[(x, y)] = (i, lv)
    return out


def mound_pixels():
    """{(x, y): cor} do monte: domos grandes + torroes pequenos na superficie (terra fofa)."""
    sh = mound_shade()
    out = {}
    for (x, y), (i, lv) in sh.items():
        lv += 0.08 * math.sin(x * 0.7 + y * 1.3)
        out[(x, y)] = lv
    rnd = random.Random(19)
    tops = {}
    for (x, y) in out:
        tops[x] = min(tops.get(x, 999), y)
    clods = []
    for k in range(95):
        x = rnd.randrange(42, 151)
        r = rnd.uniform(2.2, 4.8)
        y = tops[x] + rnd.uniform(-0.5, 1.0) * r + (rnd.random() ** 2) * 22
        clods.append((x, y, r))
    clods.sort(key=lambda b: b[1])
    for (cx, cy, r) in clods:
        for y in range(int(cy - r - 1), int(cy + r + 2)):
            for x in range(int(cx - r - 1), int(cx + r + 2)):
                if y > 333:
                    continue
                u, v = (x - cx) / r, (y - cy) * 1.15 / r
                q = u * u + v * v
                if q > 1.0:
                    continue
                if (x, y) not in out and q > 0.75:
                    continue          # na silhueta o torrao fica mais redondo (sem bico)
                nz = math.sqrt(1 - q)
                gl = out.get((x, y), 0.3)
                out[(x, y)] = 0.65 * (u * LIGHT[0] + v * LIGHT[1] + nz * LIGHT[2]) + 0.35 * gl
    res = {}
    for (x, y), lv in out.items():
        v = 16 if lv > 0.78 else (15 if lv > 0.4 else (14 if lv > 0.0 else 13))
        if y >= 332:
            v = 13 if y == 334 else min(v, 14)
        res[(x, y)] = v
    # topo PLANO onde o Coveiro senta (pa, bunda, botas e lanterna apoiam na linha do pivo):
    # de x = pivo-16 a pivo+16 a primeira linha de terra e y = pivo+1, sem nada acima
    y0 = COVEIRO[1] + 1
    for x in range(PLATEAU[0] - 1, PLATEAU[1] + 2):
        for y in range(y0 - 12, y0):
            res.pop((x, y), None)
        for y in range(y0, 335):
            if (x, y) not in res:
                res[(x, y)] = 14
    for x in range(PLATEAU[0], PLATEAU[1] + 1):
        res[(x, y0)] = 16
        if res.get((x, y0 + 1)) in (13, 14):
            res[(x, y0 + 1)] = 15
    # sem pixels soltos na silhueta
    for (x, y) in list(res):
        if not any((x + dx, y + dy) in res for dx, dy in N4):
            del res[(x, y)]
    return res


MOUND = mound_pixels()


def mound_top(x):
    ys = [y for (xx, y) in MOUND if xx == x]
    return min(ys) if ys else None


def fg():
    c = Canvas(W, H)
    rnd = random.Random(23)
    # ---- chao do primeiro plano: borda 11/10, corpo 10 com fiapos 09, fundo 09
    for x in range(W):
        g = ground_y(x)
        for y in range(g, H):
            d = y - g
            v = 10 if d < 9 else 9
            if 9 <= d < 13 and bayer(x, y) < (13 - d) * 3:
                v = 10
            c.set(x, y, v)
        c.set(x, g, 11 if (x * 7 + 3) % 11 < 6 else 10)
    for i in range(500):
        x, y = rnd.randrange(0, W), rnd.randrange(GROUND_FG + 3, H)
        if c.get(x, y) == 10 and c.get(x, y + 1) == 10:
            c.set(x, y, 9)
            c.set(x, y + 1, 9)
        elif c.get(x, y) == 9 and c.get(x, y - 1) == 9 and rnd.random() < 0.4:
            c.set(x, y, 10)
            c.set(x, y - 1, 10)
    # tufos acima da borda
    TUFTS = [["..h..", ".hGh.", "hGGGG"], [".h.h.", "hGhGh", "GGGGG"], ["h...h", ".hGh.", ".GGG."],
             ["..G..", ".GgG.", "GGgGG"]]
    for i in range(60):
        x = rnd.randrange(2, W - 6)
        if 36 <= x <= 156:
            continue
        g = ground_y(x + 2)
        rows = rnd.choice(TUFTS)
        c.rows(x, g - len(rows) + 1, rows)
    # ---- ipe: tronco (18/19/20), contorno 01 so no lado da sombra; raizes
    trunk(c)
    # sombra projetada do monte e da lapide (09 sobre o chao, para a direita)
    for x in range(118, 160):
        for y in range(332, 338):
            if c.get(x, y) == 10 and (x - 118) * 0.25 + (y - 332) < 6:
                c.set(x, y, 9)
    # ---- monte de terra recem-cavada
    mound(c, rnd)
    # ---- lapide do Tiao
    tomb(c)
    # petalas caidas sob o ipe (04/05/08)
    for i in range(46):
        x = round(rnd.gauss(568, 34))
        if not 500 <= x < W:
            continue
        y = rnd.randrange(ground_y(x) + 1, H - 2)
        if c.get(x, y) in (9, 10) and c.get(x + 1, y) in (9, 10):
            r = rnd.random()
            c.set(x, y, 5 if r < 0.6 else (4 if r < 0.85 else 8))
            c.set(x + 1, y, 4)
    return c


def mound(c, rnd):
    for (x, y), v in MOUND.items():
        c.set(x, y, v)
    # pe do monte se espalhando na grama (13/14, borda recortada)
    for x in range(34, 160):
        if (x, 334) in MOUND or abs(x - 96) < 60:
            c.set(x, 335, 13 if x % 5 else 14)
            if 40 < x < 150 and x % 7:
                c.set(x, 336, 13)
    # torroes soltos na grama (16 em cima/esq., 14 embaixo)
    CLOD = [["UU.", "UuT"], [".U", "Uu", "uT"], ["UUu", "uuT", ".T."], ["Uu", "uT"]]
    LG = {'U': 16, 'u': 15, 'T': 14}
    for (x, y, k) in [(26, 336, 0), (160, 341, 2), (18, 340, 3), (122, 340, 0), (66, 340, 3),
                      (178, 344, 3), (36, 344, 3), (100, 342, 0)]:
        for j, row in enumerate(CLOD[k]):
            for i, ch in enumerate(row):
                if ch != '.':
                    c.set(x + i, y + j, LG[ch])
    # raizinhas (18) e uma pedrinha (06/05) na terra revirada
    for (x, y, n) in [(96, 318, 4), (64, 312, 3), (124, 326, 3)]:
        for k in range(n):
            if (x + k, y + k // 2) in MOUND:
                c.set(x + k, y + (k // 2), 18)
    for (x, y) in [(108, 320), (52, 328)]:
        c.set(x, y, 6)
        c.set(x + 1, y, 5)
    # tufos de grama arrancados (folha 10/11, raiz 14)
    for x in (120, 54):
        t = mound_top(x + 1)
        c.rows(x, t + 1, ["h.h", "GhG", ".T."])


def tomb(c):
    x0, x1 = TOMB_X0, TOMB_X1
    top, base = TOMB_TOP, TOMB_BASE
    r = 5
    cx = (x0 + x1) / 2.0
    face = set()
    for y in range(top, base):
        for x in range(x0, x1 + 1):
            if y < top + r:
                # cantos arredondados (circulo de raio r)
                ccx = x0 + r if x < x0 + r else (x1 - r if x > x1 - r else x)
                if math.hypot(x - ccx, y - (top + r)) > r + 0.3:
                    continue
            face.add((x, y))
    # lateral (espessura) a direita: 3 px de 04, acompanha a curva 1 linha abaixo
    side = set()
    for (x, y) in face:
        if (x + 1, y) not in face:
            for k in range(1, 4):
                if (x + k, y + 1) not in face:
                    side.add((x + k, y + 1))
    for (x, y) in side:
        c.set(x, y, 4 if (x, y - 1) in side or (x - 1, y - 1) in face else 5)
    for (x, y) in face:
        v = 5
        if (x - 1, y) not in face or (x, y - 1) not in face:
            v = 6                       # aresta lit (luar NO)
        if (x + 1, y) not in face:
            v = 4
        c.set(x, y, v)
    # cruz gravada (04 com luz 06 embaixo/direita) e foto oval (06 com aro 04)
    mx = int(cx)
    for y in range(top + 3, top + 10):
        c.set(mx, y, 4)
        c.set(mx + 1, y, 6) if y > top + 4 else None
    for x in range(mx - 2, mx + 3):
        c.set(x, top + 5, 4)
        c.set(x, top + 6, 6) if x != mx else None
    for (dx, dy, v) in [(0, 0, 4), (1, 0, 4), (-1, 1, 4), (0, 1, 6), (1, 1, 6), (2, 1, 4),
                        (-1, 2, 4), (0, 2, 6), (1, 2, 5), (2, 2, 4), (0, 3, 4), (1, 3, 4)]:
        c.set(mx + dx, top + 12 + dy, v)
    for x in range(x0 + 3, x1 - 2):
        c.set(x, top + 18, 4)
    # contorno seletivo: 01 na direita/base e no topo; 04 no lado iluminado
    allp = face | side
    edge = set()
    for (x, y) in allp:
        for dx, dy in N4:
            q = (x + dx, y + dy)
            if q not in allp:
                edge.add(q)
    for (x, y) in edge:
        if y >= base:
            continue                    # a base entra no chao
        lit = x < cx - 1 and y > top + 2
        c.set(x, y, 3 if lit else 1)
    # pe da lapide: base escura e grama na frente
    for x in range(x0 - 1, x1 + 5):
        c.set(x, base, 9)
    c.rows(x0 - 2, base - 2, ["h.h", "GhG"])
    c.rows(x1 + 2, base - 1, ["hGh"])
    # crisantemo vermelho ao pe (32/31, folha 10)
    c.rows(x1 + 4, base - 5, [".X.", "XxX", ".x.", "GhG"])


def trunk(c):
    bx, by = TRUNK_BASE
    pts = set()
    cols = {}
    for y in range(222, by + 1):
        t = (by - y) / (by - 222)            # 0 na base, 1 em cima
        cxf = bx - 16 * t ** 1.3 + 1.5 * math.sin(y / 13.0)
        hw = 8 - 3 * t + (6 * (1 - t) ** 6)
        x0, x1 = round(cxf - hw), round(cxf + hw)
        for x in range(x0, x1 + 1):
            u = (x - x0) / max(1, x1 - x0)
            v = 20 if u < 0.14 else (19 if u < 0.5 else 18)
            cols[(x, y)] = v
    # raizes na grama
    for (dx, n, s) in [(-1, 16, -1), (1, 14, 1), (0, 8, 1)]:
        for k in range(n):
            x = bx + s * (8 + k) if dx else bx + 4 + k
            y = by - 2 + k // 5
            if dx == 0:
                y = by - 1 + k // 4
            for w in range(0, 3 - k // 6):
                cols[(x, y - w)] = 19 if w == 2 - k // 6 else 18
    # casca: estrias 18
    for (x, y), v in list(cols.items()):
        if v == 19 and (y // 6 + x) % 5 == 0 and (x, y - 1) in cols:
            cols[(x, y)] = 18
    for (x, y), v in cols.items():
        c.set(x, y, v)
    # oco (01) e contorno 01 so do lado direito/baixo
    for (dx, dy) in [(0, 0), (1, 0), (0, 1), (1, 1), (0, 2)]:
        c.set(593 + dx, 286 + dy, 1)
    c.set(592, 285, 18)
    for (x, y) in cols:
        if (x + 1, y) not in cols and c.get(x + 1, y) not in (None,):
            if (x + 1, y) not in cols:
                c.set(x + 1, y, 1)


# =================================================================== copa do ipe
CROWN = (584, 172, 92, 62)      # elipse da copa (cx, cy, rx, ry), sai pela borda direita


def canopy_frames():
    """copa: muitos cachos pequenos sombreados como uma massa so (luz global da copa +
    relevo de cada cacho): 05 (alto/esq.), 04, 03 (baixo/dir.), furos 02, pontos 08 do lado
    da lua, galhos 18/19 com sombra 01. 3 frames de balanco (pingpong)."""
    ox, oy = CANOPY_POS
    gcx, gcy, grx, gry = CROWN
    rnd = random.Random(8)
    blobs = []
    while len(blobs) < 190:
        x = rnd.uniform(gcx - grx, gcx + grx)
        y = rnd.uniform(gcy - gry, gcy + gry)
        e = ((x - gcx) / grx) ** 2 + ((y - gcy) / gry) ** 2
        if e > 1.0 or x < 500:
            continue
        # base da copa mais recolhida (forma de guarda-chuva)
        if y > gcy + 20 and abs(x - gcx) > 70 - (y - gcy - 20) * 1.4:
            continue
        r = rnd.uniform(5, 10) * (1.15 - 0.35 * e)
        blobs.append((x, y, r, rnd.random()))
    blobs.sort(key=lambda b: (b[1] + b[2], b[0]))
    branches = [((588, 244), (566, 200)), ((590, 240), (614, 196)), ((574, 216), (532, 186)),
                ((568, 206), (570, 160)), ((566, 200), (548, 214))]
    frames = []
    for f, sway in enumerate((-1, 0, 1)):
        c = Canvas(CANOPY_W, CANOPY_H)

        def S(x, y, v):
            c.set(x - ox, y - oy, v)
        for (x0, y0), (x1, y1) in branches:
            n = max(abs(x1 - x0), abs(y1 - y0))
            for i in range(n + 1):
                t = i / n
                x = round(x0 + (x1 - x0) * t + sway * t)
                y = round(y0 + (y1 - y0) * t)
                S(x, y, 19)
                S(x + 1, y, 18)
                S(x + 2, y, 1)
        lum = {}
        for bx, by, r, ph in blobs:
            dist = abs(bx - gcx) / grx
            amp = 0.4 + 1.1 * dist + 0.015 * max(0, by - gcy)
            off = round(sway * amp * (0.7 + 0.6 * ph))
            for y in range(int(by - r - 1), int(by + r + 2)):
                for x in range(int(bx - r - 1), int(bx + r + 2)):
                    dx, dy = (x - bx) / r, (y - by) * 1.25 / r
                    q = dx * dx + dy * dy
                    if q > 1.0:
                        continue
                    nz = math.sqrt(1 - q)
                    local = dx * LIGHT[0] + dy * LIGHT[1] + nz * LIGHT[2]
                    gx, gy = (x - gcx) / grx, (y - gcy) / gry
                    glob = -(gx * 0.55 + gy * 0.9)
                    lum[(x + off, y)] = 0.45 * local + 0.55 * glob
        keys = sorted(lum)
        for (x, y) in keys:
            lv = lum[(x, y)]
            v = 5 if lv > 0.42 else (4 if lv > 0.02 else 3)
            if (x, y + 1) not in lum and v != 5:
                v = 2 if lv < 0.2 else 3
            S(x, y, v)
        rr = random.Random(77)
        for k in range(150):
            x, y = keys[rr.randrange(len(keys))]
            if all((x + dx, y + dy) in lum for dx, dy in N8) and lum[(x, y)] < 0.15:
                S(x, y, 2)
                if (x + 2, y) in lum and (x + 1, y + 1) in lum:
                    S(x + 1, y, 2)
        for k in range(160):
            x, y = keys[rr.randrange(len(keys))]
            if lum[(x, y)] > 0.5 and all((x + dx, y + dy) in lum for dx, dy in N4):
                S(x, y, 8 if rr.random() < 0.45 else 5)
        frames.append(c)
    for c in frames:
        for (x, y) in floaters(c):
            c.set(x, y, 0)
    return frames


def layer_crop(c, y0):
    return c.crop(0, y0, W, H - y0)
