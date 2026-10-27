"""Balao de dialogo 9-slice (pergaminho 22, luz 23, sombra 21, contorno 01, 1 px de sombra
01 embaixo), irmao maior do tooltip, e o rabicho em 4 direcoes."""
from common import Canvas, from_rows, grid

BALAO = grid("""
...KKKKKKKKKKKKKKKKKK...
.KKWWWWWWWWWWWWWWWWWWKK.
.KWWOOOOOOOOOOOOOOOOOoK.
KWWOOOOOOOOOOOOOOOOOOOoK
KWOOOOOOOOOOOOOOOOOOOOoK
KWOOOOOOOOOOOOOOOOOOOOoK
KWOOOOOOOOOOOOOOOOOOOOoK
KWOOOOOOOOOOOOOOOOOOOOoK
KWOOOOOOOOOOOOOOOOOOOOoK
KWOOOOOOOOOOOOOOOOOOOOoK
KWOOOOOOOOOOOOOOOOOOOOoK
KWOOOOOOOOOOOOOOOOOOOOoK
KWOOOOOOOOOOOOOOOOOOOOoK
KWOOOOOOOOOOOOOOOOOOOOoK
KWOOOOOOOOOOOOOOOOOOOOoK
KWOOOOOOOOOOOOOOOOOOOOoK
KWOOOOOOOOOOOOOOOOOOOOoK
KWOOOOOOOOOOOOOOOOOOOOoK
KWOOOOOOOOOOOOOOOOOOOOoK
KWOOOOOOOOOOOOOOOOOOOooK
.KoOOOOOOOOOOOOOOOOOooK.
.KKooooooooooooooooooKK.
...KKKKKKKKKKKKKKKKKK...
...KKKKKKKKKKKKKKKKKK...
""")
NINE = (4, 4, 4, 5)   # esquerda, direita, topo, base

# rabicho para baixo, 9x7: a linha 0 cobre a linha de contorno de baixo do balao
# (altura - 2) e a linha 1 cobre a linha de sombra (altura - 1); ponta em (2, 6)
DOWN = grid("""
KOOOOOOoK
KOOOOOoK.
.KOOOoK..
.KOOoK...
..KOK....
..KoK....
..KK.....
""")


def balao():
    return from_rows(BALAO, 24, 24)


def _transpose(rows):
    h, w = len(rows), len(rows[0])
    return [''.join(rows[j][i] for j in range(h)) for i in range(w)]


def rabicho():
    """atlas 40x10, celulas 10x10: 0 baixo, 1 cima, 2 esquerda, 3 direita."""
    c = Canvas(40, 10)
    down = DOWN
    up = list(reversed(DOWN))
    left = [r[::-1] for r in _transpose(DOWN)]
    right = _transpose(DOWN)
    for rows, (ox, oy) in ((down, (0, 0)), (up, (10, 3)), (left, (23, 0)), (right, (30, 0))):
        for j, r in enumerate(rows):
            for i, ch in enumerate(r):
                if ch != '.':
                    c.set(ox + i, oy + j, from_rows([ch]).px[0][0])
    return c
