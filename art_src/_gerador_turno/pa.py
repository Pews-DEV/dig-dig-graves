"""Pa 24x24 (cursor do turno).

Desenho em grade diagonal exata (45 graus): a = y - x (ao longo do eixo, cresce para a
ponta), b = x + y (perpendicular, cresce para baixo-direita). Isso da bordas em degraus
1-1-1 limpos. Cada pose = (deslocamento da ponta, comprimento/largura da lamina).
Depois do raster, `fix` aplica retoques pixel a pixel."""
from common import Canvas, LEG


def outline(c, col=1):
    pts = [(x, y) for y in range(c.h) for x in range(c.w) if c.px[y][x]]
    s = set(pts)
    add = set()
    for x, y in pts:
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            q = (x + dx, y + dy)
            if q not in s:
                add.add(q)
    for x, y in add:
        c.set(x, y, col)


def to_rows(c):
    inv = {v: k for k, v in LEG.items()}
    return [''.join(inv[v] for v in r) for r in c.px]


# ------------------------------------------------------------------ modelo
def blade_hw(kind, a, L, hw):
    """meia-largura (em passos de b) da lamina na posicao a (0 = ombro, L = ponta)."""
    if a < 0 or a > L:
        return -1
    if kind == 'bico':
        w = min(hw, L - a)
        if a == 0:
            w = hw - 1          # ombro arredondado
        return w
    if kind == 'bico2':
        w = min(hw, (L - a + 1) // 2 * 1 + (L - a) // 2)
        w = min(hw, int((L - a) * 0.75 + 0.5))
        if a == 0:
            w = hw - 1
        return w
    if kind == 'quadrada':
        w = hw
        if a == 0 or a == L:
            w = hw - 1
        return w
    if kind == 'redonda':
        # concha: ponta arredondada
        t = L - a
        if t >= 5:
            w = hw
        else:
            w = [1, 3, 5, 6, 6][t] if hw >= 7 else min(hw, [1, 3, 4, 5, 5][t])
        if a == 0:
            w = hw - 1
        return w


def draw_shovel(kind='bico', tip=(2, 21), L=19, hw=7, Lh=13, grip='T', tape=True,
                glint=True, amber=True, bow=0, w=24, h=24, glint_shift=0):
    """tip = pixel da ponta. L = comprimento da lamina (em a), hw = meia-largura.
    Lh = comprimento do cabo (em a). bow: deslocamento lateral (em b) do topo do cabo
    para o balanco (0 ou +-2)."""
    c = Canvas(w, h)
    # ponta: a = L, b = b0 -> x = (b0 - L)/2 = tip.x, y = (L + b0)/2 = tip.y
    b0 = tip[0] + tip[1]
    a_tip = tip[1] - tip[0]
    a_sh = a_tip - L                       # a do ombro

    def put(a, b, col):
        if (a + b) % 2:
            return
        x, y = (b - a) // 2, (a + b) // 2
        c.set(x, y, col)

    for a in range(a_sh - Lh - 6, a_tip + 1):
        for d in range(-10, 11):
            b = b0 + d
            if (a + b) % 2:
                continue
            al = a - a_sh                   # 0 no ombro
            col = 0
            hwa = blade_hw(kind, al, L, hw)
            if hwa >= 0 and abs(d) <= hwa:
                if d <= -hwa + 1:
                    col = 8
                elif d >= hwa - 1:
                    col = 5
                    if amber and al >= L - 8:
                        col = 25
                    if amber and al >= L - 4:
                        col = 26
                elif d <= 0:
                    col = 7
                else:
                    col = 6
                if glint and d in (-4, -3) and 3 <= al <= L - 7:
                    col = 8
                if glint and d == -4 and al == 3 + 2 * glint_shift:
                    col = 23
            elif -2 <= al < 0:              # colar
                if abs(d) <= 2:
                    col = 7 if d < 0 else (6 if d == 0 else 5)
                    if al == -2 and abs(d) <= 2:
                        col = 6 if d <= 0 else 5
            elif a_sh - 2 - Lh <= a < a_sh - 2:  # cabo
                ah = (a_sh - 2) - a            # 1.. Lh (distancia do colar)
                dd = d - (bow * ah) // Lh if bow else d
                if abs(dd) <= 1:
                    col = {-1: 17, 0: 16, 1: 15}[dd]
                    if tape and (3 <= ah <= 4 or 7 <= ah <= 8):
                        col = {-1: 22, 0: 21, 1: 21}[dd]
            elif grip and a_sh - 2 - Lh - 4 <= a < a_sh - 2 - Lh:
                dd = d - bow if bow else d
                ag = (a_sh - 2 - Lh) - a       # 1..4
                if grip == 'T' and abs(dd) <= 4 and ag <= 2:
                    col = 17 if dd < 0 else (16 if dd == 0 else 15)
                if grip == 'D':
                    ring = abs(dd) <= 3 and not (abs(dd) <= 1 and ag in (1, 2)) and ag <= 4
                    if ring and not (ag == 4 and abs(dd) >= 2):
                        col = 17 if (dd < 0 or ag == 4) else 15
            if col:
                put(a, b, col)
    outline(c)
    return c


def metal_tip(c):
    """pixel de metal mais adiantado no eixo (max y - x)."""
    best = None
    for y in range(c.h):
        for x in range(c.w):
            if c.px[y][x] in (5, 6, 7, 8, 23, 25, 26):
                k = (y - x, y)
                if best is None or k > best[0]:
                    best = (k, (x, y))
    return best[1]


def clipped(**kw):
    """True se a pose nao cabe em 24x24 (renderiza com folga e compara)."""
    tip = kw.pop('tip')
    big = draw_shovel(tip=(tip[0] + 10, tip[1] + 10), w=44, h=44, **kw)
    n_big = sum(1 for r in big.px for v in r if v)
    small = draw_shovel(tip=tip, **kw)
    n_small = sum(1 for r in small.px for v in r if v)
    return n_big != n_small


def clod(c, x, y, size=2):
    if size == 2:
        # torrao 3x3 arredondado, luz NO
        for (dx, dy), col in {(1, 0): 17, (0, 1): 17, (1, 1): 16, (2, 1): 15,
                              (1, 2): 15, (2, 2): 14}.items():
            c.set(x + dx, y + dy, col)
    else:
        for (dx, dy), col in {(0, 0): 17, (1, 0): 16, (0, 1): 16, (1, 1): 14}.items():
            c.set(x + dx, y + dy, col)


BASE = dict(kind='bico2', grip='D', L=19, hw=7, Lh=10)
TIP = (3, 20)


def pose(tip, smear=False, clods=(), **over):
    kw = dict(BASE)
    kw.update(over)
    assert not clipped(tip=tip, **kw), (tip, over)
    c = draw_shovel(tip=tip, **kw)
    if smear:
        # rastro: borda iluminada repetida 2 px atras (para cima-direita) em 05
        ghost = draw_shovel(tip=(tip[0] + 2, tip[1] - 2), **kw)
        g = Canvas(24, 24)
        for y in range(24):
            for x in range(24):
                if ghost.px[y][x] == 8 and not c.px[y][x]:
                    g.set(x, y, 5)
        g.blit(c, 0, 0)
        c = g
    for (x, y, sz) in clods:
        clod(c, x, y, sz)
    return c


def frames():
    """lista de (nome, canvas). idle 2 + act 5."""
    out = [
        ('idle0', pose(TIP)),
        ('idle1', pose((TIP[0], TIP[1] - 1), glint_shift=1)),
        ('act0_antecipacao', pose((TIP[0] + 2, TIP[1] - 3), L=17, Lh=8)),
        ('act1_descida', pose((TIP[0], TIP[1] + 1), L=20, hw=6, Lh=9)),
        ('act2_impacto', pose(TIP, L=16, hw=8, Lh=11, clods=((0, 14, 2), (9, 21, 2)))),
        ('act3_recuperacao', pose((TIP[0] + 1, TIP[1] - 2), L=18, Lh=9, clods=((0, 10, 1), (13, 19, 1)))),
        ('act4_volta', pose((TIP[0], TIP[1] - 1))),
    ]
    return out




if __name__ == '__main__':
    import sys
    PREV = sys.argv[1]
    exp = [draw_shovel('bico2', grip='T'), draw_shovel('bico2', grip='D'),
           draw_shovel('quadrada', grip='D', L=16, tip=(3, 20)),
           draw_shovel('redonda', grip='D', L=17, hw=6, tip=(2, 21))]
    sheet = Canvas(4 * 28 + 4, 28, 11)
    for i, e in enumerate(exp):
        sheet.blit(e, 4 + i * 28, 2)
        for r in to_rows(e):
            print(r)
        print()
    sheet.to_rgba(8).save(PREV + '/pa_test.png')
    big = Canvas(sheet.w * 2 + 8, sheet.h, 2)
    big.blit(sheet, 0, 0)
    sh2 = Canvas(sheet.w, sheet.h, 3)
    for i, e in enumerate(exp):
        sh2.blit(e, 4 + i * 28, 2)
    big.blit(sh2, sheet.w + 8, 0)
    big.to_rgba(1).save(PREV + '/pa_test_1x.png')
    big.to_rgba(3).save(PREV + '/pa_test_3x.png')


def anim_sheet(path, scale=6):
    fr = frames()
    sh = Canvas(len(fr) * 26 + 2, 26 * 2 + 2, 11)
    dark = Canvas(24, 24)
    for i, (n, c) in enumerate(fr):
        sh.blit(c, 2 + i * 26, 2)
        sh.rect(2 + i * 26, 28, 24, 24, 3)
        sh.blit(c, 2 + i * 26, 28)
        t = metal_tip(c)
        print(n, 'ponta', t)
    sh.to_rgba(scale).save(path)
