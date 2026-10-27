"""Mascate de corpo inteiro (24x32, pivo (12, 31) = base, entre os pes) para o hub.

Esqueleto simpatico com chapeu de feltro (18/19/20, fita 25), paleto 03/04/05 com
colete 19 e botoes 26, dente de ouro, mochila de lona (14/15/16) com cobertor enrolado
e frigideira (05/06/07) pendurada. Contorno 01 automatico.
"""
from common import Canvas, outline, grid, put

W, H = 24, 32

PACK = grid("""
.LLLLL.
LVVVVVL
.VVVVV.
UUUUUUu
UUUUUUu
TTTTTTT
UUUZUUu
UUUUUUu
UUUUUUu
UUUUUUu
UUUUUUu
UUUUUuT
TTTTTTT
""")
PAN = grid("""
.c..
.MS.
MSSL
MSSL
.LL.
""")
LEGS = grid("""
.Oo..Oo..
.Oo..Oo..
.Oo..Oo..
cCCc.cCCc
cccc.cccc
""")
BODY = grid("""
..LLVYYVVV..
.LLVVCOCVVVV
.LVVVCOCVVVI
LLVVVCZCVVVI
LVVVVCOCVVVI
LVVVVCZCVVII
LVVVVCCCVVII
.LVVVCCCVVI.
.VVVVVVVVVI.
..IIIIIIII..
""")
HEAD = grid("""
..OOOOOOOO..
.WOOOOOOOOo.
WOWKOOOOWKOo
OOKKOOOOKKOo
OOKKOOOOKKoo
.OOOOKKOOOo.
.oOOOOOOOOo.
..oKOKZKOo..
...oOOOOo...
....oooo....
""")
HAT = grid("""
................
.....cccccc.....
....cCrrCCCc....
....CrCCCCCc....
....YYYYYYYy....
cCrrrCCCCCCCCCCc
.cc..........cc.
""")
EYES_CLOSED = grid("""
OOOOOOOOOO
OOOOOOOOOO
KKOOOOOOKK
""")
EYES_HAPPY = grid("""
OKKOOOOKKO
KOOKOOKOOK
OOOOOOOOOO
""")


def mascate(head_dy=0, eyes='open', arm='down', pan_dx=0):
    c = Canvas(W, H)
    put(c, PACK, 15, 6)
    put(c, PAN, 20 + pan_dx, 13)
    put(c, LEGS, 8, 25)
    put(c, BODY, 6, 15)
    # bracos: mangas 05/03 e maos de osso
    put(c, ['I', 'I', 'I', 'I'], 18, 17)
    put(c, ['Oo', 'oo'], 18, 21)
    if arm == 'down':
        put(c, ['L', 'L', 'L', 'L'], 5, 17)
        put(c, ['WO', 'Oo'], 4, 21)
    else:
        # braco esquerdo (lado da lua) erguido acenando: manga sobe em degraus 2:1
        put(c, grid("""
L....
LL...
.LL..
..LL.
...LV
"""), 2, 13)
        hand = grid("""
O.O.
OOOO
WOOo
.Oo.
""") if arm == 'up0' else grid("""
.O.O
OOOO
WOOo
.Oo.
""")
        put(c, hand, 1 if arm == "up0" else 2, 9)
    put(c, HEAD, 6, 5 + head_dy)
    if eyes == 'closed':
        put(c, EYES_CLOSED, 7, 7 + head_dy)
    elif eyes == 'happy':
        put(c, EYES_HAPPY, 7, 7 + head_dy)
    put(c, HAT, 4, -1 + head_dy)
    return outline(c)


def frames():
    fr, du, tags = [], [], []

    def tag(name, items):
        a = len(fr)
        for f, d in items:
            fr.append(f)
            du.append(d)
        tags.append((name, a, len(fr) - 1))

    tag('idle', [(mascate(), 167), (mascate(head_dy=1, pan_dx=1), 167),
                 (mascate(head_dy=1), 167), (mascate(eyes='closed'), 167)])
    tag('wave', [(mascate(eyes='happy', arm='up0'), 125),
                 (mascate(eyes='happy', arm='up1', pan_dx=1), 125),
                 (mascate(eyes='happy', arm='up0', head_dy=1), 125),
                 (mascate(eyes='happy', arm='up1'), 125)])
    return fr, du, tags
