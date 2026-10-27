"""Kit de UI (UI/UX §3): botoes 9-slice, botao pequeno, plaqueta, tooltip + rabicho,
medalha de nivel, lanterna animada e caveirinha da Inquietacao."""
import math
from common import Canvas, check_rows


# ------------------------------------------------------------------ botoes
def _board(c, x0, y0, w, h, body, hi, lo, ring=None, nails=26, nail_lo=24):
    """face de madeira com contorno 01 e cantos chanfrados de 1 px."""
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
    # cantos internos (fecham o chanfro)
    for (x, y) in ((x0 + 1, y0 + 1), (x0 + w - 2, y0 + 1), (x0 + 1, y0 + h - 2), (x0 + w - 2, y0 + h - 2)):
        c.set(x, y, 1)


def _lip(c, x0, y0, w, rows, col):
    """espessura da tabua sob a face (rows linhas de col + 01 embaixo)."""
    for k in range(rows):
        y = y0 + k
        for x in range(x0, x0 + w):
            c.set(x, y, 1 if x in (x0, x0 + w - 1) else col)
    for x in range(x0 + 1, x0 + w - 1):
        c.set(x, y0 + rows, 1)


def _nail(c, x, y, col=26, lo=24):
    c.set(x, y, col)
    c.set(x + 1, y + 1, lo)


STATES = ('normal', 'hover', 'pressionado', 'desabilitado')


def button(w, h, state, nails=True, grain=True):
    """botao de madeira de caixao. Face ocupa h-3 linhas; 2 linhas de espessura + 01."""
    c = Canvas(w, h)
    fh = h - 3
    if state == 'normal':
        _board(c, 0, 0, w, fh, 19, 20, 18)
        _lip(c, 0, fh, w, 2, 18)
        nc, nl = 26, 24
    elif state == 'hover':
        _board(c, 0, 0, w, fh, 20, 17, 19, ring=26)
        _lip(c, 0, fh, w, 2, 18)
        nc, nl = 26, 24
    elif state == 'pressionado':
        _board(c, 0, 1, w, fh, 19, 18, 19)
        _lip(c, 0, fh + 1, w, 1, 18)
        nc, nl = 25, 24
    else:  # desabilitado
        _board(c, 0, 0, w, fh, 6, 6, 5)
        _lip(c, 0, fh, w, 2, 5)
        nc, nl = 5, 5
    oy = 1 if state == 'pressionado' else 0
    if nails:
        m = 3 if w >= 24 else 2
        for (x, y) in ((m, m), (w - m - 2, m), (m, fh - m - 2), (w - m - 2, fh - m - 2)):
            _nail(c, x, y + oy, nc, nl)
    if grain and w >= 24:
        gcol = {'normal': 18, 'hover': 19, 'pressionado': 18, 'desabilitado': 5}[state]
        # veios curtos so nas fatias de borda (nao repetem no miolo)
        for (x, y, n) in ((2, 6, 3), (w - 5, 8, 3), (2, fh - 7, 2)):
            for k in range(n):
                if c.get(x + k, y + oy) not in (1, 0, 26, 24, 25):
                    c.set(x + k, y + oy, gcol)
    return c


def button_sheet(w, h, **kw):
    s = Canvas(w * 4, h)
    for i, st in enumerate(STATES):
        s.blit(button(w, h, st, **kw), i * w, 0)
    return s


# ------------------------------------------------------------------ plaqueta
def plaque(w=32, h=24):
    """tabua do HUD: cantos arredondados (2 px), 1 prego por ponta, veio no miolo."""
    c = Canvas(w, h)
    fh = h - 1
    inside = set()
    for y in range(fh):
        for x in range(w):
            cut = 0
            if y in (0, fh - 1):
                cut = 2
            elif y in (1, fh - 2):
                cut = 1
            if cut <= x < w - cut:
                inside.add((x, y))
    for (x, y) in inside:
        edge = any((x + dx, y + dy) not in inside for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
        if edge:
            v = 1
        elif (x, y - 1) not in inside or (x, y - 2) not in inside and y <= 2:
            v = 20
        elif y == fh - 2 or (x, y + 1) not in inside or (x + 1, y) not in inside:
            v = 18
        elif x == 1 or (x - 1, y) not in inside:
            v = 20
        else:
            v = 19
        c.set(x, y, v)
    # sombra de 1 px embaixo (descola a tabua do cenario)
    for x in range(2, w - 2):
        c.set(x, h - 1, 1)
    # veio: linhas 18 no miolo, periodo 16 na horizontal (repete sem emenda)
    for x in range(w):
        if (x % 16) in range(3, 9):
            if c.get(x, 7) == 19:
                c.set(x, 7, 18)
        if (x % 16) in range(10, 15):
            if c.get(x, 15) == 19:
                c.set(x, 15, 18)
    # pregos: um em cada ponta, no meio da altura
    _nail(c, 3, 10)
    _nail(c, w - 5, 10)
    return c


# ------------------------------------------------------------------ tooltip
def tooltip(w=16, h=16):
    c = Canvas(w, h)
    _board(c, 0, 0, w, h - 1, 22, 23, 21)
    for x in range(1, w - 1):
        c.set(x, h - 1, 1)       # sombra de 1 px
    return c


TAIL_DOWN = ["KOOOOOK",
             ".KOOoK.",
             "..KoK..",
             "...K..."]


def tails():
    """4 rabichos em celulas 8x8: 0 = baixo, 1 = cima, 2 = esquerda, 3 = direita."""
    a = Canvas(32, 8)
    base = Canvas(8, 8)
    base.rows(0, 0, TAIL_DOWN)
    # baixo
    a.blit(base, 0, 0)
    # cima (espelha na vertical, a sombra 21 vai para a esquerda)
    up = ["...K...",
          "..KOK..",
          ".KOOoK.",
          "KOOOOOK"]
    a.rows(8, 4, up)
    left = ["...K",
            "..KO",
            ".KOO",
            "KOOO",
            ".KoO",
            "..Ko",
            "...K"]
    a.rows(16, 0, left)
    right = ["K...",
             "OK..",
             "OOK.",
             "OOOK",
             "OoK.",
             "oK..",
             "K..."]
    a.rows(24 + 4, 0, right)
    return a


# ------------------------------------------------------------------ medalha
def medal(sweep=None):
    """disco 24x24 de cobre: contorno 01, aro 25 (26 no alto-esquerda, 24 embaixo-direita),
    filete 01 e miolo 24 de 14 px de diametro para o numero. sweep = posicao da faixa de
    brilho (x + y) ou None."""
    c = Canvas(24, 24)
    cx = cy = 12.0
    for y in range(24):
        for x in range(24):
            d = math.hypot(x + 0.5 - cx, y + 0.5 - cy)
            if d > 11.6:
                continue
            lit = (x + y) < 21
            dark = (x + y) > 26
            if d > 10.6:
                v = 1
            elif d > 8.6:
                v = 25
                if lit and d > 9.6:
                    v = 26
                if dark and d > 9.6:
                    v = 24
            elif d > 7.6:
                v = 1 if not lit else 24
                if dark:
                    v = 1
            else:
                v = 24
                if (x + y) > 27 and d > 6.4:
                    v = 18
                if (x + y) < 18 and d > 6.4:
                    v = 25
            c.set(x, y, v)
    # cravos do aro (4 pontos cardeais)
    for (x, y) in ((11, 1), (12, 1), (1, 11), (1, 12)):
        c.set(x, y, 23)
    for (x, y) in ((11, 22), (12, 22), (22, 11), (22, 12)):
        c.set(x, y, 26)
    if sweep is not None:
        for y in range(24):
            for x in range(24):
                v = c.get(x, y)
                if not v or v == 1:
                    continue
                k = x - y * 0 + y          # faixa diagonal (x + y)
                if sweep <= x + y <= sweep + 2:
                    c.set(x, y, 23 if v in (25, 26, 23) else 26)
                elif x + y == sweep + 3 and v in (24, 18):
                    c.set(x, y, 25)
    return c


def medal_sheet():
    """5 frames 24x24: 0 = normal (idle), 1-4 = brilho varrendo (special)."""
    s = Canvas(24 * 5, 24)
    s.blit(medal(), 0, 0)
    for i, sw in enumerate((6, 15, 24, 33)):
        s.blit(medal(sw), 24 * (i + 1), 0)
    return s


# ------------------------------------------------------------------ lanterna
LANTERN = [
    "........................",
    "..........KKKK..........",
    ".........KZYYyK.........",
    ".........KYKKyK.........",
    "........KKyKKyKK........",
    ".......KZZYYYYyyK.......",
    "......KZYYYYYYYYyK......",
    ".....KZYYYYYYYYYYyK.....",
    ".....KKKKKKKKKKKKKK.....",
    "......KyYYYYYYYYyyK.....",
    "......KyYYYYYYYYYyK.....",
    "......KyYYYYYYYYYyK.....",
    "......KyYYYYYYYYYyK.....",
    "......KyYYYYYYYYYyK.....",
    "......KyYYYYYYYYYyK.....",
    "......KyYYYYYYYYYyK.....",
    "......KyYYYYYYYYYyK.....",
    "......KyYYYYYYYYYyK.....",
    ".....KKKKKKKKKKKKKK.....",
    ".....KZYYYYYYYYYYyK.....",
    "....KZZYYYYYYYYYYyyK....",
    "....KyyyyyyyyyyyyyyK....",
    ".....KKKKKKKKKKKKKK.....",
    "........................",
]


def _lantern_body(glass, glass_hi, post):
    c = Canvas(24, 24)
    c.rows(0, 0, LANTERN)
    # vidro: x 8..16, y 9..17; postes x=7 (claro) e x=17 (escuro)
    for y in range(9, 18):
        for x in range(8, 17):
            c.set(x, y, glass)
        c.set(7, y, post[0])
        c.set(17, y, post[1])
    # halo mais claro no vidro em volta da chama
    for (x, y) in [(10, 11), (11, 10), (12, 10), (13, 11), (10, 15), (13, 15), (9, 13), (14, 13),
                   (9, 12), (14, 12), (9, 14), (14, 14), (10, 16), (11, 16), (12, 16), (13, 16)]:
        c.set(x, y, glass_hi)
    # pavio/base da chama
    c.set(11, 17, 18)
    c.set(12, 17, 18)
    return c


FLAMES = [
    # chama normal 3 frames (6x7 no canto (9, 9)): Z = 26 corpo, W = 23 nucleo, Y = 25 ponta
    ["..Y...",
     "..ZZ..",
     ".ZWZ..",
     ".ZWWZ.",
     ".ZWWZ.",
     "..ZZ..",
     "......"],
    ["...Y..",
     "..ZZ..",
     "..ZWZ.",
     ".ZWWZ.",
     ".ZWWZ.",
     "..ZZ..",
     "......"],
    ["......",
     "..YY..",
     ".ZWZZ.",
     ".ZWWZ.",
     ".ZWWZ.",
     "..ZZ..",
     "......"],
]
FLAMES_LOW = [
    # chama fraca, tremendo: menor, sem nucleo 23, inclina e encolhe
    ["......",
     "......",
     "......",
     "...Y..",
     "..ZY..",
     "..ZZ..",
     "......"],
    ["......",
     "......",
     "......",
     "..Y...",
     "..YZ..",
     "..ZZ..",
     "......"],
    ["......",
     "......",
     "......",
     "......",
     "..YY..",
     "..ZY..",
     "......"],
]


def lantern(frame, low=False):
    if low:
        c = _lantern_body(24, 25, (25, 24))
        fl = FLAMES_LOW[frame]
    else:
        c = _lantern_body(25, 26, (26, 24))
        fl = FLAMES[frame]
    for j, row in enumerate(fl):
        for i, ch in enumerate(row):
            if ch != '.':
                c.set(9 + i, 10 + j, {'Z': 26, 'W': 23, 'Y': 25}[ch])
    return c


def lantern_sheet():
    """6 frames 24x24: 0-2 idle (chama normal), 3-5 low (oleo baixo)."""
    s = Canvas(24 * 6, 24)
    for i in range(3):
        s.blit(lantern(i), 24 * i, 0)
        s.blit(lantern(i, True), 24 * (3 + i), 0)
    return s


# ------------------------------------------------------------------ caveirinha
SKULL = [
    "................",
    ".....KKKKKK.....",
    "...KKWOOOOOKK...",
    "..KWOOOOOOOOoK..",
    "..KOOOOOOOOOoK..",
    ".KOOOOOOOOOOOoK.",
    ".KOKKKOOOKKKOoK.",
    ".KOKKKKOKKKKOoK.",
    ".KOKKKKOKKKKooK.",
    ".KOOKKOOOKKOooK.",
    "..KOOOOKOOOooK..",
    "...KoOOOOOooK...",
    "...KOKOKOKoK....",
    "...KoKoKoKoK....",
    "....KKKKKKK.....",
    "................",
]


def skull():
    check_rows('skull', SKULL)
    c = Canvas(16, 16)
    c.rows(0, 0, SKULL)
    return c
