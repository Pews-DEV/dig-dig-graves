"""UI da tela-titulo: panel_stone (lapide 9-slice), btn_perigo (4 estados como btn_grande)
e scroll_ends (rolos do pergaminho dos Creditos)."""
import math
from common import Canvas

N4 = ((1, 0), (-1, 0), (0, 1), (0, -1))

# ------------------------------------------------------------------ painel de pedra (lapide)
STONE_W, STONE_H = 40, 40
STONE_NINE = (14, 14, 16, 10)      # esq, dir, topo, base
STONE_R = 12                       # raio dos cantos de cima
PLINTH = 5                         # linhas do pedestal


def panel_stone():
    W, H = STONE_W, STONE_H
    c = Canvas(W, H)
    bx0, bx1 = 2, W - 3            # corpo recuado 2 px; o pedestal ocupa a largura toda
    by1 = H - PLINTH - 1           # ultima linha do corpo
    body = set()
    for y in range(0, by1 + 1):
        for x in range(bx0, bx1 + 1):
            if y < STONE_R:
                ccx = bx0 + STONE_R if x < bx0 + STONE_R else (bx1 - STONE_R if x > bx1 - STONE_R else x)
                if math.hypot(x - ccx, y - STONE_R) > STONE_R + 0.35:
                    continue
            body.add((x, y))
    plinth = set()
    for y in range(by1 + 1, H):
        for x in range(0, W):
            if (x in (0, W - 1)) and y in (by1 + 1, H - 1):
                continue
            plinth.add((x, y))
    shape = body | plinth
    # contorno 01 = borda da propria forma (1 px para dentro)
    edge = {p for p in shape if any((p[0] + dx, p[1] + dy) not in shape for dx, dy in N4)}
    for (x, y) in body:
        v = 7
        inner = (x, y) not in edge
        if inner:
            if any((x + dx, y + dy) in edge and (dx < 0 or dy < 0) for dx, dy in N4):
                v = 8                              # luz em cima/esquerda
            elif any((x + dx, y + dy) in edge and (dx > 0) for dx, dy in N4):
                v = 6                              # sombra a direita
        c.set(x, y, v)
    # pedestal: topo 07, face 06, base 05 (mais largo que o corpo)
    for (x, y) in plinth:
        v = 6
        if y == by1 + 1:
            v = 7
        elif y == H - 2:
            v = 5
        if x == 1 and y < H - 2:
            v = 7
        c.set(x, y, v)
    for (x, y) in edge:
        c.set(x, y, 1)
    # linha entre corpo e pedestal: o contorno do corpo continua 1 px (sombra 05 em baixo do corpo)
    for x in range(bx0 + 1, bx1):
        c.set(x, by1, 6)
    # moldura gravada (inset 4): sulco 06 em cima/esq., luz 08 em baixo/dir.
    gi = 4
    gx0, gx1, gy0, gy1 = bx0 + gi, bx1 - gi, gi, by1 - 3
    gr = STONE_R - gi
    groove = set()
    for y in range(gy0, gy1 + 1):
        for x in range(gx0, gx1 + 1):
            on = x in (gx0, gx1) or y in (gy0, gy1)
            if y < gy0 + gr:
                ccx = gx0 + gr if x < gx0 + gr else (gx1 - gr if x > gx1 - gr else None)
                if ccx is not None:
                    d = math.hypot(x - ccx, y - (gy0 + gr))
                    on = abs(d - gr) < 0.5
                    if d > gr + 0.5:
                        on = False
            if on:
                groove.add((x, y))
    for (x, y) in groove:
        c.set(x, y, 6)
        q = (x + 1, y + 1)
        if c.get(*q) == 7 and q not in groove:
            c.set(q[0], q[1], 8)
    # musgo no canto de cima/esquerda (10/11) e uma rachadura no canto direito (06)
    for (x, y, v) in [(4, 5, 10), (5, 4, 10), (6, 3, 11), (4, 6, 10), (5, 5, 11), (3, 7, 10), (7, 3, 10)]:
        if c.get(x, y) in (7, 8):
            c.set(x, y, v)
    for (x, y) in [(31, 9), (32, 10), (32, 11), (33, 12)]:     # dentro do canto (nao repete)
        if c.get(x, y) in (7, 8):
            c.set(x, y, 6)
    return c


# ------------------------------------------------------------------ botao de perigo
STATES = ('normal', 'hover', 'pressionado', 'desabilitado')


def _board(c, x0, y0, w, h, body, hi, lo, ring=None):
    for y in range(y0, y0 + h):
        for x in range(x0, x0 + w):
            edge = x in (x0, x0 + w - 1) or y in (y0, y0 + h - 1)
            if edge:
                v = 1
            elif ring is not None and (x in (x0 + 1, x0 + w - 2) or y in (y0 + 1, y0 + h - 2)):
                v = ring
            elif y == y0 + 1 or x == x0 + 1:
                v = hi
            elif y == y0 + h - 2 or x == x0 + w - 2:
                v = lo
            else:
                v = body
            c.set(x, y, v)
    for (x, y) in ((x0, y0), (x0 + w - 1, y0), (x0, y0 + h - 1), (x0 + w - 1, y0 + h - 1)):
        c.set(x, y, 0)
    for (x, y) in ((x0 + 1, y0 + 1), (x0 + w - 2, y0 + 1), (x0 + 1, y0 + h - 2), (x0 + w - 2, y0 + h - 2)):
        c.set(x, y, 1)


def _lip(c, x0, y0, w, rows, col):
    for k in range(rows):
        for x in range(x0, x0 + w):
            c.set(x, y0 + k, 1 if x in (x0, x0 + w - 1) else col)
    for x in range(x0 + 1, x0 + w - 1):
        c.set(x, y0 + rows, 1)


def button_perigo(state, w=48, h=24):
    """mesma geometria do kit.button (btn_grande), em vermelho de perigo (rampa 18-31-32-26)."""
    c = Canvas(w, h)
    fh = h - 3
    if state == 'normal':
        _board(c, 0, 0, w, fh, 31, 32, 18)
        _lip(c, 0, fh, w, 2, 18)
        nc, nl = 26, 24
    elif state == 'hover':
        _board(c, 0, 0, w, fh, 32, 26, 31, ring=26)
        _lip(c, 0, fh, w, 2, 18)
        nc, nl = 26, 24
    elif state == 'pressionado':
        _board(c, 0, 1, w, fh, 31, 18, 31)
        _lip(c, 0, fh + 1, w, 1, 18)
        nc, nl = 25, 24
    else:
        _board(c, 0, 0, w, fh, 6, 6, 5)
        _lip(c, 0, fh, w, 2, 5)
        nc, nl = 5, 5
    oy = 1 if state == 'pressionado' else 0
    m = 3
    for (x, y) in ((m, m), (w - m - 2, m), (m, fh - m - 2), (w - m - 2, fh - m - 2)):
        c.set(x, y + oy, nc)
        c.set(x + 1, y + 1 + oy, nl)
    gcol = {'normal': 18, 'hover': 31, 'pressionado': 18, 'desabilitado': 5}[state]
    for (x, y, n) in ((2, 6, 3), (w - 5, 8, 3), (2, fh - 7, 2)):
        for k in range(n):
            if c.get(x + k, y + oy) not in (1, 0, 26, 24, 25):
                c.set(x + k, y + oy, gcol)
    return c


def btn_perigo_sheet():
    s = Canvas(48 * 4, 24)
    for i, st in enumerate(STATES):
        s.blit(button_perigo(st), i * 48, 0)
    return s


# ------------------------------------------------------------------ rolos do pergaminho
ROLL_W, ROLL_H = 32, 12
ROLL_NINE = (8, 8)       # esq, dir (so estica na horizontal)


def roll(bottom=False):
    """rolo de pergaminho deitado: cilindro 23/22/21 com contorno 01, ponta enrolada (espiral 21)
    e pegador de madeira 19/20/18 dos dois lados. bottom=True: a folha entra por cima."""
    c = Canvas(ROLL_W, ROLL_H)
    x0, x1 = 3, ROLL_W - 4          # cilindro (com contorno)
    shade = {1: 23, 2: 22, 3: 22, 4: 22, 5: 22, 6: 22, 7: 21, 8: 21, 9: 21, 10: 15}
    for y in range(ROLL_H):
        for x in range(x0, x1 + 1):
            if y in (0, ROLL_H - 1) or x in (x0, x1):
                v = 1
            else:
                v = shade[y]
            c.set(x, y, v)
    # pontas do rolo: elipse com espiral (21 com miolo 15)
    for xe in (x0 + 2, x1 - 2):
        for y in range(2, ROLL_H - 2):
            c.set(xe, y, 21)
        c.set(xe, 1, 22)
        c.set(xe, ROLL_H - 2, 15)
        c.set(xe, 5, 15)
        c.set(xe, 6, 15)
    # borda da folha que sai/entra no rolo (linha 21 no meio do cilindro)
    yl = 3 if bottom else 8
    for x in range(x0 + 4, x1 - 3):
        c.set(x, yl, 21 if not bottom else 21)
    if not bottom:
        for x in range(x0 + 4, x1 - 3):
            c.set(x, 9, 22)
    # pegadores (madeira de caixao)
    for (xa, xb) in ((0, 3), (ROLL_W - 4, ROLL_W - 1)):
        for y in range(3, 9):
            for x in range(xa, xb + 1):
                edge = x in (xa, xb) or y in (3, 8)
                v = 1 if edge else (20 if y == 4 else (19 if y < 7 else 18))
                c.set(x, y, v)
        c.set(xa, 3, 0)
        c.set(xb, 3, 0)
        c.set(xa, 8, 0)
        c.set(xb, 8, 0)
    # cantos arredondados do cilindro
    for (x, y) in ((x0, 0), (x1, 0), (x0, ROLL_H - 1), (x1, ROLL_H - 1)):
        c.set(x, y, 0)
    return c


def scroll_ends_sheet():
    s = Canvas(ROLL_W, ROLL_H * 2)
    s.blit(roll(False), 0, 0)
    s.blit(roll(True), 0, ROLL_H)
    return s


def nine(dst, src, x, y, w, h, l, r, t, b):
    sw, sh = src.w, src.h
    for yy in range(h):
        if yy < t:
            sy = yy
        elif yy >= h - b:
            sy = sh - (h - yy)
        else:
            sy = t + (yy - t) % max(1, sh - t - b)
        for xx in range(w):
            if xx < l:
                sx = xx
            elif xx >= w - r:
                sx = sw - (w - xx)
            else:
                sx = l + (xx - l) % max(1, sw - l - r)
            v = src.px[sy][sx]
            if v:
                dst.set(x + xx, y + yy, v)
