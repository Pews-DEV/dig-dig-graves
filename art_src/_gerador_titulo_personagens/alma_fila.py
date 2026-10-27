"""Alminha da fila (8x10, pivo (4, 9)): chama-gota 30/23 com olhinhos 03, sem contorno,
coerente com `alma` e o icone de Alma. Anda para a DIREITA (a ponta da chama fica para tras,
a esquerda); o codigo espelha quando precisar."""
from common import Canvas
from coveiro import put, grid

W, H = 8, 10

# walk: sobe/desce 1 px (6-8 fps) e a ponta da chama balanca; squash leve no ponto baixo
WALK = [grid("""
.A......
.AA.....
..AAA...
.AAWWA..
.AWIWIA.
.AWWWWA.
..AWWA..
...AA...
........
........
"""), grid("""
........
A.......
.AA.....
..AAAA..
.AAWWWA.
.AWIWIA.
.AWWWWA.
..AWWA..
...AA...
........
"""), grid("""
........
........
........
A.......
.AAAA...
.AAWWWA.
AAWIWIWA
.AWWWWWA
..AAAAA.
...AA...
"""), grid("""
........
........
.A......
..A.....
.AAAA...
.AAWWA..
.AWIWIA.
.AWWWWA.
..AWWA..
...AA...
""")]


def walk():
    out = []
    for g in WALK:
        c = Canvas(W, H)
        put(c, g)
        out.append(c)
    return out


def vanish():
    """some em xadrez no portao: 50% -> 25% -> faiscas 23."""
    base = walk()[0]
    out = []
    a = Canvas(W, H)
    b = Canvas(W, H)
    for y in range(H):
        for x in range(W):
            v = base.px[y][x]
            if not v:
                continue
            if (x + y) % 2 == 0:
                a.px[y][x] = v
            if x % 2 == 0 and y % 2 == 0:
                b.px[y][x] = 23 if v == 23 else 30
    c = Canvas(W, H)
    for (x, y) in ((3, 2), (5, 4), (2, 5)):
        c.px[y][x] = 23
    return [a, b, c]
