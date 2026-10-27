"""Chefe do estagio 1: o Caixao Fujao (64x48, pivo (32, 32) = centro dos 2x2 tiles).

Caixao de madeira EM PE (18/19/20, pregos 26, contorno 01), com rostinho na tampa
(olhos 2x3 em 01, boca, bochechas 20). Perspectiva: tampa de frente, lateral direita
(18) e topo (20) recuados em degraus 2:1. Lua no alto a esquerda.

Chao (montinho de terra revolvida, sombra) e torroes saem das mesmas funcoes usadas
em boss_caixao_buraco (64x32 = linhas 16-47 do quadro do chefe).
"""
from common import Canvas, outline, ellipse, paint, fill, grid, put, recolor

W, H = 64, 48
PIVOT = (32, 32)
OX, OY = 20, 5          # canto sup. esq. da tampa no quadro
LID_H = 30
DEPTH = 4


# ------------------------------------------------------------------ geometria da tampa
def lid_rows(h=LID_H):
    """[(x0, x1)] por linha da tampa (x1 exclusivo), coordenadas locais."""
    out = []
    for y in range(h):
        if y < 8:
            left = 4 - y // 2
        elif y < 12:
            left = 0
        else:
            left = min(5, 1 + (y - 12) // 4)
        if y >= h - 2:
            left = max(left, 5)
        out.append((left, 20 - left))
    return out


def lid_mask(h=LID_H, ox=OX, oy=OY):
    m = set()
    for y, (a, b) in enumerate(lid_rows(h)):
        for x in range(a, b):
            m.add((ox + x, oy + y))
    return m


def offs(t):
    return (t, -((t + 1) // 2))


EYES = {
    'open': grid("""
KK....KK
KK....KK
KK....KK
"""),
    'closed': grid("""
........
K.K..K.K
.K....K.
"""),
    'squint': grid("""
K......K
.KK..KK.
K......K
"""),
    'x': grid("""
K.K..K.K
.K....K.
K.K..K.K
"""),
    'happy': grid("""
.K....K.
K.K..K.K
........
"""),
}
MOUTHS = {
    'smile': grid("""
K..K
.KK.
"""),
    'o': grid("""
.KK.
K..K
.KK.
"""),
    'tight': grid("""
KKKK
"""),
    'wobble': grid("""
.K.K
K.K.
"""),
}


def coffin(gap=0, eyes='open', mouth='smile', blush=True):
    """caixao inteiro (com contorno), no quadro 64x48, sem chao."""
    c = Canvas(W, H)
    lid = lid_mask()
    # caixa: varredura da tampa para tras (degraus 2:1); cor pela linha de origem
    box = {}
    for t in range(DEPTH, 0, -1):
        dx, dy = offs(t)
        for (x, y) in lid:
            q = (x + dx, y + dy)
            if q in lid:
                continue
            r = y - OY
            col = 17 if r <= 0 else (19 if r <= 8 else 18)
            box[q] = col
    for (x, y), col in box.items():
        c.set(x, y, col)
    # quina entre topo e lateral (1 px mais claro no topo)
    if gap:
        # tampa entreaberta: boca escura do caixao + parede interna 18 a direita
        fill(c, lid, 1)
        for (x, y) in lid:
            if (x + 1, y) not in lid and (x, y) in lid:
                c.set(x, y, 18)
        lid_draw = {(x - gap, y) for (x, y) in lid}
    else:
        lid_draw = lid
    # tampa: base 19, filete de luz 20 (cima/esq.), sombra 18 (baixo/dir.)
    paint(c, lid_draw, (19, 20, 17), dark_w=1, light_w=1)
    lx = OX - gap
    # cruz em relevo na metade de baixo (17, sombra 19 em baixo/dir.)
    cross = {(lx + 9 + i, OY + 15 + j) for i in range(2) for j in range(11)}
    cross |= {(lx + 6 + i, OY + 18 + j) for i in range(8) for j in range(2)}
    for (x, y) in cross:
        c.set(x + 1, y + 1, 19)
    fill(c, cross, 17)
    # pregos 26 (cantos da tampa)
    for (x, y) in ((lx + 4, OY + 1), (lx + 15, OY + 1), (lx + 1, OY + 9),
                   (lx + 18, OY + 9), (lx + 6, OY + LID_H - 2), (lx + 13, OY + LID_H - 2)):
        c.set(x, y, 26)
    # rosto
    put(c, EYES[eyes], lx + 6, OY + 6)
    if blush:
        for (x, y) in ((lx + 3, OY + 10), (lx + 4, OY + 10), (lx + 15, OY + 10), (lx + 16, OY + 10)):
            c.set(x, y, 19)
    mo = MOUTHS[mouth]
    put(c, mo, lx + 8, OY + 11)
    return outline(c)


def squash(c, row=OY + 18, n=1):
    """tira n linhas na altura `row` (a parte de cima desce n px)."""
    o = Canvas(c.w, c.h)
    for y in range(c.h):
        src = y - n if y <= row else y
        o.px[y] = list(c.px[src]) if 0 <= src < c.h else [0] * c.w
    return o


def stretch(c, row=OY + 18, n=1):
    """duplica n linhas na altura `row` (a parte de cima sobe)."""
    o = Canvas(c.w, c.h)
    for y in range(c.h):
        if y < row - n:
            src = y + n
        elif y < row:
            src = row
        else:
            src = y
        o.px[y] = list(c.px[src]) if 0 <= src < c.h else [0] * c.w
    return o


def moved(c, dx, dy):
    o = Canvas(c.w, c.h)
    o.blit(c, dx, dy)
    return o


# ------------------------------------------------------------------ chao
SHADOW = ellipse(34, 35, 15, 3.5)
MOUND = ellipse(32, 32.5, 19, 7)
HOLE = ellipse(32, 32, 13.5, 4)


def hole_front(x):
    ys = [y for (xx, y) in HOLE if xx == x]
    return max(ys) if ys else None


def shadow(c):
    fill(c, SHADOW, 2)


def mound(c, filled=False, bulge=False):
    """montinho de terra revolvida com a boca do buraco (aberta ou ja fechada)."""
    ring = MOUND - HOLE
    paint(c, ring, (14, 15, 16), dark_w=2, light_w=1)
    for (x, y) in ring:                      # labio da frente pega o 17
        if (x, y - 1) in HOLE:
            c.set(x, y, 17)
    if not filled:
        fill(c, HOLE, 13)
        for (x, y) in HOLE:                  # parede de tras: esq. na sombra, dir. iluminada
            if (x, y - 1) not in HOLE:
                c.set(x, y, 14 if x < 32 else 15)
                if x >= 38:
                    c.set(x, y + 1, 14)
        for (x, y) in ((22, 33), (23, 33)):  # 1-2 px de 01 no canto mais escuro
            c.set(x, y, 1)
    else:
        fill(c, HOLE, 14)
        for (x, y) in HOLE:
            if (x, y - 1) not in HOLE:
                c.set(x, y, 13)
        # dimple central e torroes soltos
        for (x, y) in ((30, 32), (31, 32), (32, 32), (33, 32), (31, 33), (32, 33)):
            c.set(x, y, 13)
        for (x, y, col) in CLODS_ON_HOLE:
            c.set(x, y, col)
    if bulge:                                 # terra estufando (antes de emergir)
        b = ellipse(32, 31.5, 8, 3)
        paint(c, b, (14, 15, 16), dark_w=1, light_w=1)
        for (x, y) in ((28, 30), (29, 30), (35, 31), (36, 31)):
            c.set(x, y, 17)
        for (x, y) in ((31, 32), (32, 32), (33, 33)):
            c.set(x, y, 13)
    # torroes no labio
    for (x, y, col) in CLODS_ON_RIM:
        c.set(x, y, col)


CLODS_ON_RIM = [(16, 31, 16), (17, 31, 17), (17, 32, 16), (45, 29, 17), (46, 29, 16),
                (46, 30, 15), (24, 37, 16), (25, 37, 17), (25, 38, 16), (41, 37, 16),
                (42, 37, 17), (42, 36, 16)]
CLODS_ON_HOLE = [(24, 31, 16), (25, 31, 17), (25, 32, 16), (38, 33, 16), (39, 33, 17),
                 (39, 32, 16), (35, 30, 15), (36, 30, 16), (28, 34, 15), (29, 34, 16)]


def clod(c, x, y, size=2, col=16):
    """torrao solto (2x2 ou 3x2 com luz 17 em cima-esq.)."""
    for j in range(2):
        for i in range(size):
            c.set(x + i, y + j, col)
    c.set(x, y, 17 if col != 17 else 16)
    if size == 2:
        c.set(x + 1, y + 1, 15 if col == 16 else 14)


def sunk(cof, s, hole_open=True, filled=False, bulge=False, clods=()):
    """caixao afundado s px no buraco, com o montinho."""
    c = Canvas(W, H)
    mound(c, filled=filled, bulge=bulge)
    m = moved(cof, 0, s)
    for y in range(H):
        for x in range(W):
            v = m.px[y][x]
            if not v:
                continue
            f = hole_front(x)
            if f is None or y > f:
                continue
            c.set(x, y, v)
    for (x, y, sz, col) in clods:
        clod(c, x, y, sz, col)
    return c


def standing(cof, dy=0, ground='shadow', clods=()):
    c = Canvas(W, H)
    if ground == 'shadow':
        shadow(c)
    elif ground == 'mound':
        mound(c)
    elif ground == 'mound_lip':
        mound(c, filled=True)
    m = moved(cof, 0, dy)
    c.blit(m, 0, 0)
    for (x, y, sz, col) in clods:
        clod(c, x, y, sz, col)
    return c


# ------------------------------------------------------------------ alma grande
SOUL = grid("""
......A......
......AA.....
.....AAA.....
.....AAAA....
....AAWAA....
...AAWWWAA...
..AAWWWWWAA..
.AAWWWWWWWAA.
.AWWWWWWWWWA.
AAWWIWWWIWWAA
AAWWIWWWIWWAA
AAWWWWWWWWWAA
AAWWWIWIWWWAA
.AAWWWIWWWAA.
.AAWWWWWWWAA.
..AAWWWWWAA..
....AAAAA....
""")
SOUL_W, SOUL_H = 13, 17


def soul(c, x, y, dissolve=0):
    """dissolve: 0 inteira, 1 xadrez 50%, 2 so faiscas."""
    if dissolve == 2:                         # 3 faiscas em cruz (30 com miolo 23)
        for (i, j) in ((6, 1), (1, 7), (11, 10)):
            put(c, ['.A.', 'AWA', '.A.'], x + i - 1, y + j - 1)
        return
    for j, r in enumerate(SOUL):
        for i, ch in enumerate(r):
            if ch == '.':
                continue
            if dissolve == 1 and (i + j) % 2:
                continue
            put(c, [ch], x + i, y + j)


# ------------------------------------------------------------------ tampa aberta (derrota)
def coffin_open(eyes_on_lid=True):
    """tampa escancarada para a esquerda (dobradica na quina esquerda), interior 01."""
    c = Canvas(W, H)
    lid = lid_mask()
    for t in range(DEPTH, 0, -1):
        dx, dy = offs(t)
        for (x, y) in lid:
            q = (x + dx, y + dy)
            if q in lid:
                continue
            r = y - OY
            c.set(q[0], q[1], 17 if r <= 0 else (19 if r <= 8 else 18))
    # boca do caixao: interior 01, parede interna da direita 18 e fundo 02
    fill(c, lid, 1)
    rows = lid_rows()
    for y, (a, b) in enumerate(rows):
        yy = OY + y
        c.set(OX + b - 1, yy, 19)
        c.set(OX + b - 2, yy, 18)
        c.set(OX + a, yy, 18)
    for x in range(OX + 1, OX + 19):
        if (x, OY + 1) in lid:
            c.set(x, OY + 1, 18)
    # travesseirinho (04/05) no alto do interior
    pil = ellipse(OX + 10, OY + 5.5, 5, 2)
    paint(c, pil, (3, 4, 5), dark_w=1, light_w=1)
    # tampa aberta: tabua fina vista de lado (parede interna 18/19), indo para baixo-esq.
    lid2 = set()
    for y, (a, b) in enumerate(rows):
        for t in range(0, 6):
            lid2.add((OX + a - 1 - t, OY + y + (t + 1) // 2))
    filled2 = set()
    for y in {p[1] for p in lid2}:
        xs = [p[0] for p in lid2 if p[1] == y]
        filled2.update((x, y) for x in range(min(xs), max(xs) + 1))
    lid2 = filled2
    fill(c, lid2, 19)
    for (x, y) in lid2:                      # borda de baixo 18, quina de fora 20
        if (x, y + 1) not in lid2:
            c.set(x, y, 18)
        elif (x - 1, y) not in lid2:
            c.set(x, y, 20)
    for (x, y) in ((OX + a - 3, OY + 4) for (a, b) in [rows[4]]):
        c.set(x, y, 26)
    c.set(OX - 3, OY + LID_H - 1, 26)
    return outline(c)


# ------------------------------------------------------------------ animacoes
def frames():
    fr, du, tags = [], [], []

    def tag(name, items):
        a = len(fr)
        for f, d in items:
            fr.append(f)
            du.append(d)
        tags.append((name, a, len(fr) - 1))

    base = coffin()
    # idle (7 fps): respira, a tampa da uma batidinha (abre 2 px e fecha), pisca
    tag('idle', [(standing(base), 143),
                 (standing(squash(base)), 143),
                 (standing(stretch(coffin(gap=2, eyes='happy', mouth='o'))), 143),
                 (standing(coffin(eyes='closed')), 143)])
    # sink (12 fps): antecipa, afunda jogando terra, some
    tense = coffin(eyes='squint', mouth='tight')
    tag('sink', [
        (standing(squash(tense, n=2)), 83),
        (sunk(stretch(tense), 4, clods=[(14, 24, 2, 16), (47, 22, 2, 16)]), 83),
        (sunk(tense, 12, clods=[(10, 18, 3, 16), (50, 16, 2, 15), (20, 20, 2, 17)]), 83),
        (sunk(tense, 20, clods=[(8, 16, 2, 16), (53, 13, 2, 16), (18, 14, 2, 15)]), 83),
        (sunk(tense, 27, clods=[(7, 22, 2, 15), (54, 19, 2, 16), (16, 19, 2, 16)]), 83),
        (sunk(tense, 40, filled=True, clods=[(8, 28, 2, 16), (53, 26, 2, 15)]), 83),
    ])
    # emerge (12 fps): a terra estufa, ele pula para fora, aterrissa
    happy = coffin(eyes='happy', mouth='o')
    tag('emerge', [
        (sunk(base, 40, filled=True, bulge=True), 83),
        (sunk(happy, 22, clods=[(26, 20, 2, 16), (38, 18, 2, 17), (31, 14, 3, 16)]), 83),
        (sunk(stretch(happy, n=2), 9, clods=[(18, 10, 2, 16), (45, 8, 2, 16), (30, 2, 3, 15)]), 83),
        (standing(stretch(happy, n=2), dy=-3, ground='mound',
                  clods=[(12, 12, 2, 15), (50, 10, 2, 16), (26, 0, 2, 16)]), 83),
        (standing(squash(coffin(eyes='closed'), n=2), ground='mound_lip',
                  clods=[(10, 24, 2, 16), (52, 22, 2, 15)]), 83),
        (standing(base, clods=[(13, 36, 2, 16), (51, 34, 2, 15)]), 83),
    ])
    # hit: 1 quadro, todas as cores do caixao trocadas por 23 (a sombra no chao fica)
    flash = Canvas(W, H)
    shadow(flash)
    flash.blit(recolor(base, {v: 23 for v in range(1, 33)}), 0, 0)
    tag('hit', [(flash, 83)])
    # defeat: tonto, treme, a tampa escancara, a alma grande sobe e ele afunda
    dizzy = coffin(eyes='x', mouth='wobble', blush=False)
    op = coffin_open()

    def with_soul(cof, s, sy, dissolve=0, filled=False):
        c = sunk(cof, s, filled=filled) if s else standing(cof)
        soul(c, 26, sy, dissolve)
        return c

    tag('defeat', [
        (standing(squash(dizzy)), 100),
        (standing(moved(coffin(gap=1, eyes='x', mouth='wobble', blush=False), -1, 0)), 83),
        (standing(moved(coffin(gap=3, eyes='x', mouth='o', blush=False), 1, 0)), 83),
        (standing(op), 125),
        (with_soul(op, 0, 16), 125),
        (with_soul(op, 6, 8), 125),
        (with_soul(op, 16, 1, dissolve=1), 125),
        (with_soul(op, 40, 0, dissolve=2, filled=True), 250),
    ])
    return fr, du, tags


def hole_sprite():
    """terra revolvida onde ele afundou: 64x32, pivo (32, 16) = linhas 16-47 do chefe."""
    c = Canvas(W, H)
    mound(c, filled=True)
    return c.crop(0, 16, 64, 32)


ICON = grid("""
................
....KKKKKKKK....
...KbbbbbbbcK...
..KbbrrrrrrrcK..
.KbrrKKrrKKrrcK.
.KbrrKKrrKKrrcK.
.KbrCrrrrrrCrcK.
.KbrrrKrrKrrrcK.
..KbrrrKKrrrcK..
..KbrrrbbrrrcK..
..KbrrbbbbrrcK..
...KbrrbbrrcK...
...KbrrbbrrcK...
....KbrrrrcK....
.....KKKKKK.....
................
""")


def icon():
    from common import from_rows
    c = from_rows(ICON, 16, 16)
    return c
