"""Tiao, o Corvo (16x16, pivo (8, 15)): corvo gordinho de peito estufado, virado para a
ESQUERDA (olha para o Coveiro), com uma moeda de cobre no bico.
Corpo 02 com luz 04 (lado esquerdo/topo), sombra 01; bico e pes 17; moeda 24/25/26.
Contorno 01 automatico."""
from common import Canvas, outline
from coveiro import put, grid

W = H = 16

# corpo (sem cabeca): peito estufado a esquerda (luz 04 em meia-lua), asa com risco 01,
# rabo para a direita; o risco 01 no alto separa a nuca das costas
BODY = grid("""
........KNNNN...
....VVNNNKNNNNN.
....VVVNNNKNNNNN
....VVVNNNNKNNNN
.....VVNNNNNKKNN
......VNNNNNNN.N
.......NNNNNNN..
""")
BODY_Y = 7
LEGS = grid("""
.......b..b.....
......bb.bb.....
""")
LEGS_Y = 14

# cabeca redonda (5x4) com bico 17; a moeda vai pendurada na ponta do bico
HEADS = {
    'open': grid("""
....VVVN.
...VVKVNN
.bbbVVNNN
..bbVVNNN
"""),
    'blink': grid("""
....VVVN.
...VVVVNN
.bbbVKNNN
..bbVVNNN
"""),
    'tilt': grid("""
.....VVN.
....VVVNN
...VVKVNN
.bbbVVNN.
..bbVN...
"""),
    'caw': grid("""
.b..VVVN.
..bVVKVNN
...bVVNNN
.bbbVVNNN
"""),
}
COIN = grid("""
.KK.
KZYK
KYyK
.KK.
""")
HEAD_X, HEAD_Y = 0, 4


def tiao(head='open', dy=0, hx=0, hy=0, squash=False):
    c = Canvas(W, H)
    body = BODY
    if squash:              # agachado: corpo 1 px mais baixo (perde a 2a linha)
        body = BODY[:1] + BODY[2:]
    by = BODY_Y + dy + (1 if squash else 0)
    put(c, body, 0, by)
    put(c, LEGS, 0, LEGS_Y + dy)
    h = HEADS[head]
    oy = HEAD_Y + dy + hy + (1 if squash else 0)
    put(c, h, HEAD_X + hx, oy)
    # moeda presa embaixo da ponta do bico (linha do bico de baixo)
    low = max(j for j, r in enumerate(h) if 'b' in r[:4])
    put(c, COIN, HEAD_X + hx + 1, oy + low)
    return outline(c)


def frames():
    """devolve (lista de frames, duracoes, tags)."""
    fr, du, tags = [], [], []

    def tag(name, items):
        a = len(fr)
        for f, d in items:
            fr.append(f)
            du.append(d)
        tags.append((name, a, len(fr) - 1))

    base = tiao()
    # idle: olho aberto e piscada
    tag('idle', [(base, 1500), (tiao('blink'), 167)])
    # tilt: inclina a cabeca, segura, volta
    tag('tilt', [(tiao(hx=0, hy=0, head='tilt'), 83), (tiao(head='tilt', hy=0), 500),
                 (tiao('blink'), 83), (base, 83)])
    # hop: agacha, sobe, topo, cai, amortece
    tag('hop', [(tiao(squash=True), 83), (tiao(dy=-2), 83), (tiao(dy=-3), 83),
                (tiao(dy=-1), 83), (tiao(squash=True), 83), (base, 83)])
    # caw: antecipa (cabeca baixa), grasna (bico aberto), segura, fecha
    tag('caw', [(tiao(hy=1), 83), (tiao('caw', hy=-1), 83), (tiao('caw', hy=-1), 250),
                (tiao('caw'), 83), (base, 83)])
    return fr, du, tags
