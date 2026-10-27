"""Coveiro da tela-titulo (32x32, pivo (16, 31)), pa cravada e lanterna no chao.

Partes desenhadas em linhas de caracteres (legenda em common.LEG; '.' = transparente).
O contorno externo 01 e automatico (common.outline); linhas internas 01 ficam no desenho.
Luz da lua do alto a esquerda: lado esquerdo/topo claro.
Tudo se apoia na linha do pivo (y = 31 do quadro do Coveiro): o topo do monte e plano ali.
"""
from common import Canvas, LEG, outline

W = H = 32


def put(c, rows, ox=0, oy=0):
    """sobrepoe linhas ('.' mantem o que esta embaixo)."""
    for j, r in enumerate(rows):
        for i, ch in enumerate(r):
            assert ch in LEG, (ch, r)
            if ch != '.':
                c.set(ox + i, oy + j, LEG[ch])


def grid(s):
    return [r for r in s.strip('\n').split('\n')]


# ------------------------------------------------------------------ cabeca
# chapeu de palha 17/21 (sombra 16), furo no topo; aba larga
HAT = grid("""
......ooob.........
.....oobbbbU.......
....oobbKKbbU......
....obbbbbbbU......
....UUUUUUUUUU.....
ooooobbbbbbbbbbbU..
obbbbbbbbbbbbbbbbbU
.KKKK..........KKKK
""")
# chapeu inclinado (empurrado para tras pela mao no coçar): aba sobe 1 px a direita
HAT_TILT = grid("""
.......oooob.......
.....ooobbbbbU.....
....oobbbKKbbU.....
....obbbbbbbbUU....
....UUUUUUUUUUUbbU.
ooooobbbbbbbbbbbbbU
obbbbbbbbbbbbbbbKKK
.KKKK..............
""")
# rosto: linha 0 = testa (so aparece se o chapeu sobe), linha 1 = sombra da aba
FACE = grid("""
.....TTTTUUUbbbU..
.....TUUUUUUUUUU..
.....TUUbbbbbbbbbU
.....TUbbKbbbKbbbb
.....TUbbKbbbKbbbU
.....TTUbbbbbbbbbU
......TUUbbbbbbbU.
.......UUUbbbbUU..
""")
HAT_X = 5        # coluna do quadro onde comeca a parte do chapeu
FACE_X = 5


def face(eyes='open', mouth=None):
    rows = [list(r) for r in FACE]
    if eyes == 'closed':          # olhos fechados: tracinho de 2 px
        for x in (9, 13):
            rows[3][x] = 'b'
            rows[4][x] = 'K'
            rows[4][x - 1] = 'K'
    if mouth == 'small':
        rows[6][11] = 'K'
    elif mouth == 'open':         # boca aberta 2x2 (bocejo)
        for (x, y) in ((11, 5), (12, 5), (11, 6), (12, 6)):
            rows[y][x] = 'K'
        rows[7][11] = 'U'
    return [''.join(r) for r in rows]


def head(c, oy, ox=0, hat=HAT, hat_dy=0, eyes='open', mouth=None):
    """oy = linha do topo da copa do chapeu."""
    put(c, face(eyes, mouth), FACE_X + ox, oy + 6)
    put(c, hat, HAT_X + ox, oy + hat_dy)


# ------------------------------------------------------------------ corpo sentado
# macacao 04/05 (sombra 03), alca 03; botas 14/13. Sem o braco da frente.
SIT_BODY = grid("""
...........LLLLVIVVVV...........
..........LLLVVIVVVVVV..........
..........LLVVVVIVVVVVV.........
..........LVVVVVVIVVVVVV........
..........LVVVVVVVVVVLLL........
..........LVVVVVLLLLLVVVV.......
..........LVVVLLVVVVVVVVI.......
.........LVVLVVVVVVVVVVVI.......
.........LVVVVVVVVLVVVVI........
.........LVVVVVVVITTTTTT........
.........VVVVVVVIITTTTTTT.......
..........IIIIII..ttttttt.......
""")
SIT_BODY_Y = 19          # linha do quadro da 1a linha de SIT_BODY

# braco da frente apoiado no joelho (mao 16/17 pendurada na frente do joelho)
ARM_REST = grid("""
.................ILLL...........
................KLLLLLbb........
...............KKKKKKLbbU.......
....................KKUbU.......
......................KU........
""")
ARM_REST_Y = 22

# braco erguido coçando a cabeca: o braco sobe por fora do rosto (lado direito) e a mao
# esfrega a aba do chapeu; [0] = mao em cima (chapeu levantado 1 px), [1] = mao 1 px abaixo
ARM_SCRATCH = [grid("""
......................bbb...
.....................bbbbU..
.....................KbbbU..
.......................KLLV.
........................LLV.
........................LLV.
........................LLVV
........................LLVV
.......................LLVVV
......................LLVVV.
.....................LLVVV..
....................LLVVV...
...................ILVVV....
"""), grid("""
............................
......................bbb...
.....................bbbbU..
.....................KbbbU..
.......................KLLV.
........................LLV.
........................LLVV
........................LLVV
.......................LLVVV
......................LLVVV.
.....................LLVVV..
....................LLVVV...
...................ILVVV....
""")]
ARM_SCRATCH_Y = 8
# braco no meio do caminho (subindo/descendo)
ARM_HALF = grid("""
........................bb..
.......................bbbU.
.......................KbbU.
........................LLV.
......................LLLVV.
.....................LLLVV..
....................LLLVV...
...................ILLVV....
""")
ARM_HALF_Y = 13
# braco esticado para cima no bocejo
ARM_STRETCH = grid("""
.........................bbb
.........................bbbU
.........................KbbU
..........................LLV
..........................LLV
.........................LLVV
.........................LLV.
........................LLVV.
........................LLV..
.......................LLVV..
.......................LLV...
......................LLVV...
.....................ILVV....
""")
ARM_STRETCH_Y = 9


def sit(head_dy=0, head_dx=0, arm='rest', **kw):
    c = Canvas(W, H)
    put(c, SIT_BODY, 0, SIT_BODY_Y)
    head(c, 5 + head_dy, head_dx, **kw)
    if arm:
        rows, y = {'rest': (ARM_REST, ARM_REST_Y), 'half': (ARM_HALF, ARM_HALF_Y),
                   'scratch0': (ARM_SCRATCH[0], ARM_SCRATCH_Y),
                   'scratch1': (ARM_SCRATCH[1], ARM_SCRATCH_Y),
                   'stretch': (ARM_STRETCH, ARM_STRETCH_Y)}[arm]
        put(c, rows, 0, y)
    return outline(c)


# ------------------------------------------------------------------ pa cravada (9x26, pivo (4, 25))
# lamina 06/07/08 (luz a esquerda), cabo 15/16, alça em D; montinho de terra 14/15/16 na base
PA = grid("""
.........
..UUUUu..
..U...u..
...UUu...
....Uu...
....Uu...
....Uu...
....Uu...
....Uu...
....Uu...
....Uu...
....Uu...
....Uu...
....Uu...
....Uu...
....Uu...
....Uu...
....Uu...
...SMMS..
..PMMMMS.
..PMMMMS.
..PMMMSS.
.UuPMMSuT
.UUuuuuuT
UUuuuuuTT
uuuuTTTTT
""")
PA_W, PA_H, PA_PIVOT = 9, 26, (4, 25)
# lamina inteira (para quando sai da terra): 6 linhas + ponta
BLADE = grid("""
...SMMS..
..PMMMMS.
..PMMMMS.
..PMMMMS.
..PMMMSS.
..PMMMSS.
...PMSS..
""")
MOUND_HOLE = grid("""
.U..K...T
.UUuKuuuT
UUuuuuuTT
uuuuTTTTT
""")


def pa_cravada():
    c = Canvas(PA_W, PA_H)
    put(c, PA)
    o = outline(c)
    for x in range(PA_W):          # a base encosta no chao: sem contorno embaixo
        if o.px[PA_H - 1][x] == 1 and not c.px[PA_H - 1][x]:
            o.px[PA_H - 1][x] = 0
    return o


def pa_solta(lift):
    """pa puxada `lift` px para cima (lamina inteira a mostra) + o montinho com o furo."""
    c = Canvas(PA_W, PA_H + 4)
    rows = PA[:18]
    put(c, rows, 0, 4 - lift)
    put(c, BLADE, 0, 22 - lift)
    o = outline(c)
    m = Canvas(PA_W, PA_H + 4)
    put(m, MOUND_HOLE, 0, PA_H)
    mo = outline(m)
    for x in range(PA_W):
        if mo.px[PA_H + 3][x] == 1 and not m.px[PA_H + 3][x]:
            mo.px[PA_H + 3][x] = 0
    mo.blit(o, 0, 0)
    return mo.crop(0, 4, PA_W, PA_H)


# ------------------------------------------------------------------ lanterna no chao (12x16, pivo (6, 15))
LANT = grid("""
............
............
............
............
.....KKK....
....K...K...
...KKKKKKK..
...KZYYYyK..
...KKKKKKK..
...K#####K..
...K#####K..
...K#####K..
...KKKKKKK..
...KZYYyyK..
...KyyyyyK..
...KKKKKKK..
""")
# miolo do vidro (5x3) por frame: vidro 25, brilho 26, chama 23
GLASS = [["ZZWZy", "ZWWZy", "YZZYy"],
         ["YZWZy", "ZWWZy", "ZWWZy"],
         ["YZZYy", "ZZWZy", "YWWZy"]]
LANT_W, LANT_H, LANT_PIVOT = 12, 16, (6, 15)


def lanterna(frame=0):
    c = Canvas(LANT_W, LANT_H)
    rows = [r.replace('#', '.') for r in LANT]
    put(c, rows)
    put(c, GLASS[frame], 4, 9)
    return c


def halo():
    """halo grande da lanterna: xadrez 25 (miolo) e 24 (meio e borda rala), sem alfa. 56x36, centro (28, 18)."""
    w, h = 56, 36
    cx, cy = 27.5, 17.5
    c = Canvas(w, h)
    for y in range(h):
        for x in range(w):
            d = ((x - cx) / 27.5) ** 2 + ((y - cy) / 17.5) ** 2
            if d <= 0.12 and (x + y) % 2 == 0:
                c.px[y][x] = 25          # miolo: xadrez 50% em 25
            elif d <= 0.45 and (x + y) % 2 == 0:
                c.px[y][x] = 24          # meio: xadrez 50% em 24
            elif d <= 1.0 and x % 2 == 0 and y % 2 == 0 and (x // 2 + y // 2) % 2 == 0:
                c.px[y][x] = 24          # borda: xadrez ralo (1 em 8) em 24
    return c


HALO_PIVOT = (28, 18)

# ------------------------------------------------------------------ posicoes relativas ao pivo do Coveiro
PA_AT = (4, 31)        # pivo da pa cravada, em coordenadas do quadro do Coveiro
LANT_AT = (28, 31)     # pivo da lanterna no chao
GLASS_AT = (LANT_AT[0], LANT_AT[1] - 5)   # centro do vidro = centro do halo


def put_canvas(c, other, at, pivot):
    c.blit(other, at[0] - pivot[0], at[1] - pivot[1])


# ------------------------------------------------------------------ levantar
CROUCH_BODY = grid("""
............LLLVIVVV............
...........LLLVVVIVVV...........
..........LLLLVVVVIVVV..........
..........LLLVVVVVVIVVV.........
..........LLVVVVVVVVVVVV........
..........LVVVVVVVVLLLLLL.......
..........LVVVVVVLLLVVVVVV......
...........VVVVVVVVVVVVVVI......
............IIIIIIIIIVVVVI......
...................LVVVI........
..................TTTTTT........
.................TTTTTTTT.......
.................tttttttt.......
""")
CROUCH_Y = 18
ARM_CROUCH = grid("""
.................ILLL...........
................KLLLLLLbb.......
...............KKKKKKKKbbU......
.....................KKbU.......
""")
ARM_CROUCH_Y = 21

STAND_BODY = grid("""
............LLVIVVVV............
...........LLLVVIVVVV...........
..........LLLLVVVIVVVV..........
..........LLLVVVVVIVVVV.........
..........LLVVVVVVVVVVV.........
..........LLVVVVVVVVVVV.........
..........LVVVVVVVVVVVV.........
..........LVVVVVVVVVVVI.........
..........LVVVVVVVVVVVI.........
...........LVVVVIVVVVI..........
...........LVVVI.LVVVI..........
...........LVVVI.LVVVI..........
...........LVVVI.LVVVI..........
..........TTTTTT.TTTTTT.........
..........TTTTTT.TTTTTTT........
..........tttttt.ttttttt........
""")
STAND_Y = 15
# bracos caidos ao lado do corpo
ARMS_DOWN = grid("""
........LLK...........KVV.......
........LLK...........KLVV......
........LVK...........KLVV......
........LVK...........KLVV......
........LVK...........KLVV......
........LVK............LVV......
........UbK............bbU......
........Ub.............bbU......
""")
ARMS_DOWN_Y = 17
# bracos abertos segurando o cabo da pa (esq.) e a alça da lanterna (dir.)
ARMS_GRAB = grid("""
.......LLLLK..........KLLLV.....
.....bbVVVVK..........KVVVVLLV..
....bbbbKKK............KKKVVVV..
....UbbU....................bbb.
.....UU....................bbbU.
............................bU..
""")
ARMS_GRAB_Y = 17


def stand_base(head_dy=0, **kw):
    c = Canvas(W, H)
    put(c, STAND_BODY, 0, STAND_Y)
    head(c, 1 + head_dy, **kw)
    return c


def stand_frames():
    """[agachar (antecipacao), meio de pe, de pe, pega pa+lanterna, levanta a pa e a lanterna]"""
    out = []
    # 0: inclina para frente (antecipacao), maos empurram os joelhos
    out.append(sit(head_dy=1, head_dx=1))
    # 1: levantando, agachado
    c = Canvas(W, H)
    put(c, CROUCH_BODY, 0, CROUCH_Y)
    head(c, 4, 1)
    put(c, ARM_CROUCH, 0, ARM_CROUCH_Y)
    out.append(outline(c))
    # 2: de pe, bracos caidos (estica: cabeca 1 px acima)
    c = stand_base(-1)
    put(c, ARMS_DOWN, 0, ARMS_DOWN_Y - 1)
    out.append(outline(c))
    # 3: pega a pa e a lanterna (no lugar exato dos sprites soltos)
    c = stand_base()
    put(c, ARMS_GRAB, 0, ARMS_GRAB_Y)
    body = outline(c)
    f = Canvas(W, H)
    put_canvas(f, pa_cravada(), PA_AT, PA_PIVOT)
    f.blit(body, 0, 0)
    put_canvas(f, lanterna(0), LANT_AT, LANT_PIVOT)
    put_canvas(f, _hands(0), (0, 0), (0, 0))
    out.append(f)
    # 4: ergue (pa sai da terra, lanterna sobe 2 px) -- quadro final, segurado
    c = stand_base()
    put(c, ARMS_GRAB, 0, ARMS_GRAB_Y - 2)
    body = outline(c)
    f = Canvas(W, H)
    put_canvas(f, pa_solta(3), PA_AT, PA_PIVOT)
    f.blit(body, 0, 0)
    put_canvas(f, lanterna(0), (LANT_AT[0], LANT_AT[1] - 2), LANT_PIVOT)
    put_canvas(f, _hands(-2), (0, 0), (0, 0))
    out.append(f)
    return out


def _hands(dy):
    """maos por cima do cabo e da alça (para o cabo passar por tras dos dedos)."""
    c = Canvas(W, H)
    put(c, grid("""
....bbb.....................bbb.
....UbU.....................bbU.
"""), 0, 19 + dy)
    return outline(c)
