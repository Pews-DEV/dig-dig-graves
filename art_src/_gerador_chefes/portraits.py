"""Retratos de dialogo 48x48 (busto, fundo transparente, contorno 01, olhos com brilho 23).

Quadros: 0 = boca fechada, 1 = boca aberta, 2 = feliz.
Todos de frente, menos o Tiao (perfil olhando para a DIREITA; espelhar se o retrato
ficar do lado direito do balao). A borda de baixo e um corte reto (busto), sem contorno.
"""
from common import Canvas, outline, ellipse, poly, paint, fill, put, grid, dilate

W = H = 48
OSSO = (21, 22, 23)


# ------------------------------------------------------------------ helpers
def cut_outline(c):
    """contorno 01 na silhueta, mas sem fechar o corte reto da base (linha 47)."""
    o = outline(c)
    return o


def eye(c, cx, cy, mode, rx=3.5, ry=4.0, glint=True, socket=True):
    """olho/orbita: 'open' (preto com brilho 23), 'happy' (arco ^), 'half'."""
    if mode == 'happy':
        x0 = int(cx - rx + 0.5)
        x1 = int(cx + rx - 0.5)
        y = int(cy)
        col = 1 if not hasattr(eye, 'col') else eye.col
        for x in range(x0 + 1, x1):
            c.set(x, y - 1, col)
        for x in range(x0 + 2, x1 - 1):
            c.set(x, y - 2, col)
        for yy in (y, y + 1):
            c.set(x0, yy, col)
            c.set(x1, yy, col)
        c.set(x0 + 1, y, col)
        c.set(x1 - 1, y, col)
        return
    m = ellipse(cx, cy, rx, ry)
    fill(c, m, 1)
    if glint:
        top = min(m, key=lambda p: (p[1], p[0]))
        gx, gy = top[0], top[1] + 1
        c.set(gx, gy, 23)
        if rx >= 3:
            c.set(gx + 1, gy, 23)
            c.set(gx, gy + 1, 23)
            c.set(gx + 1, gy + 1, 23)
            bx = int(cx + rx * 0.4)
            by = int(cy + ry * 0.5)
            c.set(bx, by, 23)


def skull(c, cx=24, top=7, mouth='closed', eyes='open', gold_tooth=False, jaw_w=8.5):
    """cranio fofo de esqueleto (ossos 21/22/23), de frente.
    Devolve o y da base do queixo."""
    open_ = 3 if mouth == 'open' else (2 if mouth == 'grin' else 0)
    cran = ellipse(cx, top + 11, 11.5, 11)
    split = top + 26                      # linha do labio de baixo (o que desce na fala)
    jaw = ellipse(cx, top + 24, jaw_w, 5.5)
    upper = {p for p in (cran | jaw) if p[1] < split}
    lower = {(x, y + open_) for (x, y) in (cran | jaw) if y >= split}
    gap = set()
    if open_:
        for y in range(split, split + open_):
            for x in range(int(cx - 5), int(cx + 5)):
                gap.add((x, y))
    whole = upper | lower | gap
    paint(c, whole, OSSO, dark_w=2, light_w=1)
    # bochecha (osso malar) em 21 e queixo
    # olhos
    ey = top + 13
    eye(c, cx - 4.5, ey, eyes)
    eye(c, cx + 4.5, ey, eyes)
    # nariz (coracao invertido)
    ny = top + 18
    for (x, y) in ((cx - 1, ny), (cx, ny), (cx - 1, ny + 1)):
        c.set(int(x), y, 1)
    c.set(int(cx), ny + 1, 21)
    # boca: sorriso curto (linha 01), dentes 22 com divisoes 21, linha de baixo
    my = split - 3
    x0, x1 = int(cx - 4), int(cx + 4)          # dentes de x0 a x1-1 (8 px)
    for x in range(x0, x1):
        c.set(x, my, 1)
        c.set(x, my + 1, 22)
        c.set(x, my + 2, 22)
        c.set(x, my + 3 + open_, 1)
    c.set(x0 - 1, my - 1, 1)                   # cantinhos do sorriso
    c.set(x1, my - 1, 1)
    c.set(x0 - 1, my + 3 + open_, 21)
    c.set(x1, my + 3 + open_, 21)
    for x in range(x0 + 1, x1, 2):
        c.set(x, my + 1, 21)
        c.set(x, my + 2, 21)
    if gold_tooth:
        c.set(x0 + 4, my + 1, 26)
        c.set(x0 + 4, my + 2, 25)
    for y in range(my + 2 + 1, my + 3 + open_):
        for x in range(x0, x1):
            c.set(x, y, 1)
    if open_:
        for x in range(x0 - 1, x1 + 1):
            c.set(x, my + 3, 1) if x0 <= x < x1 else None
        if open_ >= 2:                         # lingua 20 no fundo da boca
            c.set(int(cx) - 1, my + 2 + open_, 20)
            c.set(int(cx), my + 2 + open_, 20)
    return max(p[1] for p in whole)


def finish(c):
    o = outline(c)
    # busto: o corte de baixo e reto (sem linha de contorno abaixo de y = 47)
    return o


# ------------------------------------------------------------------ Dona Ceifa
def dona_ceifa(mouth='closed', eyes='open'):
    c = Canvas(W, H)
    # foice atras: cabo 15/16 a direita e lamina 07/08 curvando por cima
    handle = {(x, y) for x in (41, 42) for y in range(9, 48)}
    paint(c, handle, (14, 15, 16), dark_w=1, light_w=1)
    blade = ellipse(36, 10, 11, 7) - ellipse(34, 13, 11, 7)
    blade = {p for p in blade if p[0] >= 27 and p[0] <= 46 and p[1] <= 11}
    paint(c, blade, (6, 7, 8), dark_w=1, light_w=1)
    # manto: ombros largos
    mantle = poly([(4, 48), (8, 33), (17, 28), (31, 28), (40, 33), (44, 48)])
    paint(c, mantle, (2, 3, 5), dark_w=2, light_w=1)
    # capuz com pontinha caida para tras-direita
    hood = ellipse(24, 20, 16, 17) | poly([(26, 5), (36, 1), (35, 8)])
    paint(c, hood, (2, 3, 5), dark_w=2, light_w=1)
    # dobras do manto
    for y in range(36, 48):
        c.set(14 + (y - 36) // 4, y, 2)
        c.set(33 - (y - 36) // 4, y, 2)
    # abertura do capuz (escura), borda 05 por cima-esq.
    opening = ellipse(24, 22, 12, 13.5)
    for p in dilate(opening) - opening:
        if p in hood:
            c.set(p[0], p[1], 5 if p[0] < 24 and p[1] < 22 else 4)
    fill(c, opening, 1)
    # rosto: caveira um pouco menor
    skull(c, cx=24, top=9, mouth=mouth, eyes=eyes, jaw_w=7.5)
    # oculos de leitura 26 (aros redondos) + ponte, por cima das orbitas
    if True:
        for cx in (19.5, 28.5):
            ring = dilate(ellipse(cx, 22.5, 3.5, 3.5)) - ellipse(cx, 22.5, 3.5, 3.5)
            for (x, y) in ring:
                if y >= 21:
                    c.set(x, y, 26 if y < 26 else 25)
        c.set(23, 22, 26)
        c.set(24, 22, 26)
    else:
        for x in (15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32):
            pass
    # prancheta na frente (madeira 15/16/17, papel 22, prendedor 06/07)
    board = {(x, y) for x in range(7, 20) for y in range(37, 48)}
    paint(c, board, (15, 16, 17), dark_w=1, light_w=1)
    paper = {(x, y) for x in range(9, 18) for y in range(39, 48)}
    paint(c, paper, (21, 22, 23), dark_w=1, light_w=1)
    for y in (41, 43, 45):
        for x in range(10, 16 if y != 43 else 14):
            c.set(x, y, 5)
    for x in range(11, 16):
        c.set(x, 37, 7)
        c.set(x, 38, 6)
    c.set(11, 36, 7)
    c.set(15, 36, 7)
    for x in range(12, 15):
        c.set(x, 36, 8)
    # mao ossuda segurando a prancheta (direita da prancheta)
    hand = grid("""
.OOO.
OOOOo
OoOOo
.OOo.
""")
    put(c, hand, 18, 39)
    for (x, y) in ((19, 40), (19, 41), (19, 42)):
        c.set(x, y, 21)
    return finish(c)


# ------------------------------------------------------------------ Madame Ossada
HOOP = grid("""
.Z.
.Z.
ZZZ.
Z..Z
Z..y
.yy.
""".replace('ZZZ.', 'ZZZ'))


def madame_ossada(mouth='closed', eyes='open'):
    c = Canvas(W, H)
    # xale 28 (sombra 27, luz 29) nos ombros
    shawl = poly([(3, 48), (7, 36), (16, 31), (32, 31), (41, 36), (45, 48)])
    paint(c, shawl, (27, 28, 29), dark_w=2, light_w=1)
    for x in range(6, 43, 4):                 # franjinha
        c.set(x, 46, 27)
        c.set(x + 1, 47, 27)
    # broche 26 prendendo o xale
    neck = {(x, y) for x in range(21, 27) for y in range(28, 33)}
    paint(c, neck, OSSO, dark_w=1, light_w=1)
    skull(c, cx=24, top=7, mouth=mouth, eyes=eyes)
    # brincos de argola 26 (sombra 25) pendurados dos dois lados
    for (hx, mir) in ((10, False), (34, True)):
        rows = [r.ljust(4, '.') for r in grid("""
.Z..
.Z..
ZZZ.
Z..Z
Z..y
.yy.
""")]
        if mir:
            rows = [r[::-1] for r in rows]
        put(c, rows, hx, 23)
    # turbante 32 (sombra 31) alto, com voltas diagonais e joia 26 + pena ecto
    turb = ellipse(24, 10, 15, 6.5) | ellipse(24, 5, 11.5, 5.5)
    turb = {p for p in turb if p[1] <= 15}
    paint(c, turb, (31, 32, 32), dark_w=2, light_w=0)
    for k in (-4, 6, 16):                     # voltas do pano: 3 dobras em degraus 2:1
        for i in range(24):
            x, y = 10 + k + i, 14 - i // 2
            if (x, y) in turb and (x + 1, y + 1) in turb and (x - 1, y - 1) in turb:
                c.set(x, y, 31)
    for x in range(8, 41):                    # barra sobre a testa
        if (x, 15) in turb:
            c.set(x, 15, 31)
    put(c, grid("""
.ZZ.
ZWZy
ZZyy
.yy.
"""), 22, 7)
    for i in range(6):
        c.set(26 + i // 2, 7 - i, 29 if i > 2 else 28)
        c.set(27 + i // 2, 7 - i, 28)
    # bola de cristal 30 (sombra 05, brilho 23) na frente, com as maos ossudas
    ball = ellipse(24, 42.5, 6.5, 6)
    paint(c, ball, (5, 30, 23), dark_w=2, light_w=1)
    put(c, grid("""
WW.
W..
"""), 20, 38)
    c.set(27, 45, 23)
    for (hx, mir) in ((14, False), (30, True)):
        hand = grid("""
.OOo
OOOo
OoOo
.Oo.
""")
        if mir:
            hand = [r[::-1] for r in hand]
        put(c, hand, hx, 41)
    return finish(c)


# ------------------------------------------------------------------ Mascate
def mascate(mouth='closed', eyes='open'):
    c = Canvas(W, H)
    # mochila de quinquilharias atras do ombro direito (lona 14/15/16)
    pack = {(x, y) for x in range(27, 44) for y in range(14, 42)}
    paint(c, pack, (14, 15, 16), dark_w=2, light_w=1)
    for y in range(17, 41):                   # costura 14
        c.set(40, y, 14)
    for x in range(28, 43):                   # aba da mochila
        c.set(x, 22, 14)
    c.set(41, 23, 26)                         # fivela
    # cobertor enrolado por cima (03/04/05) com amarras 18
    roll = ellipse(36, 13, 10, 3.5)
    paint(c, roll, (3, 4, 5), dark_w=1, light_w=1)
    for x in (31, 40):
        for y in range(10, 17):
            if (x, y) in roll:
                c.set(x, y, 18)
    # frigideira (06/07, cabo 18) pendurada no lado de fora
    pan = ellipse(44, 29, 4, 4.5)
    paint(c, pan, (5, 6, 7), dark_w=2, light_w=1)
    fill(c, ellipse(44, 29, 2, 2.5), 5)
    for y in range(20, 25):
        c.set(44, y, 18)
    # sininho 25/26 (badalo 01) embaixo da frigideira
    for y in range(34, 36):
        c.set(43, y, 6)
    put(c, grid("""
.ZY.
ZZYy
yyyy
.K..
"""), 41, 36)
    # paleto 03/04/05 com colete e botoes 26
    coat = poly([(6, 48), (9, 36), (17, 32), (31, 32), (39, 36), (42, 48)])
    paint(c, coat, (3, 4, 5), dark_w=2, light_w=1)
    vest = poly([(19, 48), (20, 33), (28, 33), (29, 48)])
    paint(c, vest, (18, 19, 20), dark_w=1, light_w=1)
    shirt = poly([(22, 40), (21, 33), (27, 33), (26, 40)])
    fill(c, shirt, 22)
    for (x, y) in ((24, 41), (24, 44), (24, 47)):
        c.set(x, y, 26)
    # alcas da mochila
    for y in range(34, 48):
        c.set(12 + (y - 34) // 5, y, 14)
        c.set(13 + (y - 34) // 5, y, 15)
        c.set(35 - (y - 34) // 5, y, 14)
        c.set(36 - (y - 34) // 5, y, 15)
    # gravata borboleta 31? nao (31/32 e perigo): lacinho 25
    put(c, grid("""
YY.yy
YYZYy
""")[0:2], 22, 33)
    skull(c, cx=24, top=9, mouth=mouth, eyes=eyes, gold_tooth=True)
    # chapeu de feltro 18/19/20 com fita 25
    crown = poly([(14, 11), (15, 2), (19, 0), (29, 0), (33, 2), (34, 11)])
    paint(c, crown, (18, 19, 20), dark_w=2, light_w=1)
    for x in range(21, 28):
        c.set(x, 1, 18)                    # vinco
    for x in range(14, 35):
        if (x, 9) in crown:
            c.set(x, 9, 25)
            c.set(x, 10, 24)
    brim = ellipse(24, 12, 17, 2.6)
    paint(c, brim, (18, 19, 20), dark_w=1, light_w=1)
    for (x, y) in brim:
        if (x, y + 1) not in brim:
            c.set(x, y, 18)
    return finish(c)


# ------------------------------------------------------------------ Coveiro
def coveiro(mouth='closed', eyes='open'):
    c = Canvas(W, H)
    # cabo da pa no ombro (15/16), atras
    for i in range(18):
        x, y = 44 - i // 3, 47 - i
        for d in (0, 1):
            c.set(x + d, y, 16 if d == 0 else 15)
    blade = poly([(37, 33), (37, 27), (40.5, 22), (44, 27), (44, 33)])
    paint(c, blade, (6, 7, 8), dark_w=1, light_w=1)
    # macacao 04/05 (sombra 03), camisa 21? nao: camisa 03 escura por baixo
    body = poly([(5, 48), (8, 38), (16, 34), (32, 34), (40, 38), (43, 48)])
    paint(c, body, (3, 4, 5), dark_w=2, light_w=1)
    bib = poly([(16, 48), (17, 40), (31, 40), (32, 48)])
    paint(c, bib, (4, 5, 6), dark_w=1, light_w=1)
    for (x, y) in ((18, 41), (29, 41)):
        c.set(x, y, 7)
    for y in range(35, 41):
        c.set(16 + (y - 35) // 3, y, 3)
        c.set(31 - (y - 35) // 3, y, 3)
    # pescoco e rosto (pele 15/16/17)
    neck = {(x, y) for x in range(20, 28) for y in range(31, 36)}
    paint(c, neck, (14, 15, 16), dark_w=1, light_w=0)
    face = ellipse(24, 24, 10.5, 10)
    ears = ellipse(13.5, 25, 2, 2.5) | ellipse(34.5, 25, 2, 2.5)
    paint(c, ears, (15, 16, 17), dark_w=1, light_w=0)
    paint(c, face, (15, 16, 17), dark_w=2, light_w=1)
    # sombra da aba no rosto
    for (x, y) in face:
        if y <= 17:
            c.set(x, y, 15)
    # olhos com brilho
    if eyes == 'happy':
        eye(c, 19.5, 23, 'happy', rx=2.5)
        eye(c, 28.5, 23, 'happy', rx=2.5)
    else:
        for ex in (19, 28):
            for y in range(22, 25):
                c.set(ex, y, 1)
                c.set(ex + 1, y, 1)
            c.set(ex, 22, 23)
    # sobrancelhas 14
    for x in (18, 19, 20):
        c.set(x, 20, 14)
    for x in (28, 29, 30):
        c.set(x, 20, 14)
    # nariz e bochechas
    c.set(24, 26, 15)
    c.set(23, 27, 15)
    c.set(24, 27, 15)
    for (x, y) in ((16, 27), (17, 27), (31, 27), (32, 27)):
        c.set(x, y, 20)
    # boca
    if mouth == 'closed':
        put(c, grid("""
K...K
.KKK.
"""), 22, 29)
    elif mouth == 'open':
        put(c, grid("""
KKKKK
KKKKK
.KrK.
"""), 22, 29)
    else:
        put(c, grid("""
KKKKKK
.KrrK.
..KK..
"""), 21, 29)
    # chapeu de palha largo 17/21 (sombra 16), furo no topo, aba larga
    crown = ellipse(24, 11, 10, 8)
    crown = {p for p in crown if p[1] <= 15}
    paint(c, crown, (16, 17, 21), dark_w=2, light_w=1)
    for x in range(14, 35):                 # fita 15
        if (x, 13) in crown:
            c.set(x, 13, 15)
    put(c, grid("""
KK.
UKK
""")[:2], 26, 5)                             # furo
    c.set(28, 4, 17)
    brim = ellipse(24, 16, 23, 4)
    paint(c, brim, (16, 17, 21), dark_w=2, light_w=1)
    for (x, y) in brim:
        if (x, y + 1) not in brim and x % 3 == 0:
            c.set(x, y + 1, 16)              # palha desfiada
    c.set(1, 17, 0)
    return finish(c)


# ------------------------------------------------------------------ Tiao
def tiao(mouth='closed', eyes='open'):
    """Tiao de perfil olhando para a ESQUERDA (igual ao sprite do titulo; peito estufado
    do lado da lua). Espelhar (flip_h) se o retrato ficar a esquerda do balao."""
    c = Canvas(W, H)
    head = ellipse(23, 19, 12, 11)
    body = ellipse(27, 41, 18, 13)
    neck = poly([(14, 24), (34, 22), (38, 34), (12, 34)])
    whole = head | body | neck
    paint(c, whole, (1, 2, 4), dark_w=3, light_w=2)
    # peito estufado: meia-lua 03 por dentro do filete 04
    chest = ellipse(16, 38, 8, 9) - ellipse(18, 37, 8, 9)
    for p in chest:
        if p in whole and c.get(*p) == 2:
            c.set(p[0], p[1], 3)
    for (x, y) in ((14, 34), (13, 37), (13, 40), (14, 43)):    # penugem do peito
        c.set(x, y, 4)
    # asa a direita: contorno 01 e pontas de pena 03
    wing = ellipse(33, 39, 11, 8)
    for p in dilate(wing) - wing:
        if p in whole and p[1] < 47:
            c.set(p[0], p[1], 1)
    for p in wing:
        if p in whole:
            c.set(p[0], p[1], 3 if (p[0] - 2, p[1] - 2) not in wing else 2)
    for p in wing:
        if (p[0] - 1, p[1] - 1) not in wing and p in whole:
            c.set(p[0], p[1], 4)
    for (x, y) in ((30, 44), (31, 44), (34, 45), (35, 45), (38, 43), (39, 43)):
        c.set(x, y, 1)
    # topete
    put(c, grid("""
N..N..
NN.NN.
NNNNNN
"""), 21, 6)
    # olho
    if eyes == 'happy':
        put(c, grid("""
.VVV.
V...V
V...V
"""), 17, 14)
    else:
        put(c, grid("""
.VVVV.
VKKKKV
VKWKKV
VKKKKV
VKKKKV
.VVVV.
"""), 16, 11)
        c.set(19, 15, 23)
    # bico 17 (luz 21, sombra 16) para a esquerda; moeda presa na ponta de baixo
    op = {'closed': 0, 'open': 4, 'grin': 2}[mouth]
    up = op // 2
    dn = op - up
    upper = poly([(13, 16 - up), (0, 20 - up), (13, 22 - up)])
    lower = poly([(13, 22 + dn), (3, 23 + dn), (13, 26 + dn)])
    if op:
        gap = poly([(13, 21 - up), (2, 22), (13, 23 + dn)])
        fill(c, gap, 1)
        c.set(12, 22, 20)
        c.set(11, 22, 20)
    paint(c, upper, (16, 17, 21), dark_w=1, light_w=1)
    paint(c, lower, (15, 16, 17), dark_w=1, light_w=0)
    cy = 29 + dn
    coin = ellipse(6, cy, 4, 4)
    paint(c, coin, (24, 25, 26), dark_w=1, light_w=1)
    for (x, y) in ((5, cy - 1), (6, cy - 1), (5, cy), (6, cy)):
        c.set(x, y, 1)
    return finish(c)


CHARS = {
    'dona_ceifa': dona_ceifa,
    'tiao': tiao,
    'madame_ossada': madame_ossada,
    'coveiro': coveiro,
    'mascate': mascate,
}


def frames(name):
    f = CHARS[name]
    return [f('closed', 'open'), f('open', 'open'), f('grin', 'happy')]
