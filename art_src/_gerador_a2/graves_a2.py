"""Covas de indigente da Area 2: vala de 2 tiles com caixao de tabuas simples (sem alcas, sem
pregos de cobre, sem lapide de pedra; a cova e marcada pela cruz de madeira sem nome).

Mesmo layout de grave_a1 / grave_open_a1:
  grave_a2       coluna = eixo/metade (0 NO-SE cabeca, 1 NO-SE pes, 2 NE-SO cabeca, 3 NE-SO pes)
                 linha  = estado (0 exposto, 1 rachado, 2 aberto)
  grave_open_a2  coluna = frame (0-3), linha = eixo/metade (mesma ordem acima)

Desenho por "raycast" de buraco iso: um pixel de tela (x, y) que cai na boca da vala ve, na
profundidade t, o ponto do chao (x, y - t). Desce t = 0, 1, 2... ate bater numa parede de tras
(o ponto sai da boca), num solido (tampa, corpo do caixao) ou no fundo (t = D)."""
from base import Canvas, row_span, LEG

D = 6                 # profundidade da vala (px)
LID_T = 3             # profundidade do topo da tampa (caixao com 2 px de altura acima do fundo)
A0, A1_ = -0.24, 1.24   # caixao ao longo do eixo (unidades de tile; cabeca em 0, pes em 1)
B0, B1 = -0.19, 0.19    # caixao na largura
WALL = 0.075          # espessura das tabuas do corpo (aberto)

ORIENT = {
    # cabeca/pes: origem da celula 32x24 no canvas do par 48x32
    'NOSE': dict(head=(0, 0), feet=(16, 8)),
    'NESO': dict(head=(16, 0), feet=(0, 8)),
}


def pair_mask(orient):
    o = ORIENT[orient]
    m = set()
    for (ox, oy) in (o['head'], o['feet']):
        for y in range(9, 24):
            s = row_span(y)
            for x in range(s[0], s[1] + 1):
                m.add((ox + x, oy + y))
    return m


def runs(m):
    rows = {}
    for (x, y) in m:
        a, b = rows.get(y, (x, x))
        rows[y] = (min(a, x), max(b, x))
    return rows


def ground(orient, x, y):
    """(eixo, largura) do ponto de chao no pixel (x, y) do canvas do par."""
    hx, hy = ORIENT[orient]['head']
    sx, sy = x + 0.5 - (hx + 16), y + 0.5 - (hy + 16)
    u = sx / 32 + sy / 16
    v = sy / 16 - sx / 32
    return (u, v) if orient == 'NOSE' else (v, u)


class Slab:
    """caixa no espaco (eixo a, largura b, profundidade t). hollow = so as tabuas (interior vazio)."""

    def __init__(self, a0, a1, b0, b1, t0, t1, kind, hollow=False):
        self.a0, self.a1, self.b0, self.b1, self.t0, self.t1 = a0, a1, b0, b1, t0, t1
        self.kind, self.hollow = kind, hollow

    def foot(self, a, b, inset=0.0):
        return self.a0 + inset <= a <= self.a1 - inset and self.b0 + inset <= b <= self.b1 - inset

    def solid(self, a, b, t):
        if not (self.t0 <= t <= self.t1 and self.foot(a, b)):
            return False
        if self.hollow and self.foot(a, b, WALL) and t < self.t1:
            return False          # interior vazio (o fundo t1 e solido: e o fundo do caixao)
        return True


def render(orient, slabs, shadow=True):
    """retorna (canvas 48x32, mapa de rotulos) do par de tiles."""
    m = pair_mask(orient)
    rr = runs(m)
    ring = {}
    for (x, y) in m:
        a, b = rr[y]
        if x - a < 2 or b - x < 2:
            left = x - a < 2 if (x - a < 2) != (b - x < 2) else x < (a + b) / 2
            if left:
                upper = (y - 1) not in rr or rr[y - 1][0] > a
            else:
                upper = (y - 1) not in rr or rr[y - 1][1] < b
            ring[(x, y)] = ('L' if left else 'R', upper)
    opening = m - set(ring)
    c = Canvas(48, 32)
    lab = {}
    for (x, y) in m:
        if (x, y) in ring:
            c.set(x, y, 16 if ring[(x, y)][1] else 17)
            lab[(x, y)] = 'rim'
            continue
        prev = None
        hit = None
        for t in range(0, D + 1):
            gx, gy = x, y - t
            a, b = ground(orient, gx, gy)
            for s in slabs:
                if s.solid(a, b, t):
                    if prev is None or prev[2] < s.t0 or t == s.t0:
                        hit = (s.kind + '_top', t)
                    else:
                        pa, pb = prev[0], prev[1]
                        if s.hollow and s.foot(pa, pb, WALL) and s.t0 < t:
                            hit = (s.kind + '_in', t)         # parede interna (vista de dentro)
                        elif pa > s.a1:
                            hit = (s.kind + '_end', t)        # ponta dos pes
                        else:
                            hit = (s.kind + '_side', t)       # lado comprido da frente
                    break
            if hit:
                break
            if (gx, gy) not in opening:
                side = ring.get((gx, gy), ('L' if gx < 24 else 'R', True))[0]
                hit = ('wall' + side, t)
                break
            if t == D:
                hit = ('floor', t)
                break
            prev = (a, b, t)
        kind, t = hit
        if kind == 'wallL':
            v = 14 if t < D else 13
        elif kind == 'wallR':
            v = 15 if t <= D // 2 else 14
        elif kind == 'floor':
            v = 13
            if shadow:
                a, b = ground(orient, x, y - D)
                # sombra do caixao no fundo, para SE (lua NO)
                for s in slabs:
                    if s.kind == 'lid' and s.a0 <= a - 0.06 <= s.a1 + 0.02 and s.b0 <= b - 0.07 <= s.b1 + 0.02 \
                            and not s.foot(a, b):
                        v = 1
        elif kind == 'lid_top':
            v = 20
        elif kind.endswith('_top'):
            v = 19                                   # beirada das tabuas do corpo (aberto)
        elif kind.endswith('_side'):
            v = 19 if orient == 'NOSE' else 18       # lado comprido: SO (luz) 19 / SE 18
        elif kind.endswith('_end'):
            v = 18 if orient == 'NOSE' else 19
        elif kind.endswith('_in'):
            v = 1
        c.set(x, y, v)
        lab[(x, y)] = kind
    # canto mais fundo (fundo colado na parede da esquerda e na de tras) em 01, como no S3
    for (x, y), k in list(lab.items()):
        if k == 'floor' and lab.get((x - 1, y)) == 'wallL' and str(lab.get((x, y - 1))).startswith('wall'):
            c.set(x, y, 1)
    return c, lab


def detail_lid(c, lab, orient, lid):
    """tabuas da tampa: veios 18 ao longo do eixo; aresta de tras 20 (pega luar)."""
    top = lid.kind + '_top'
    for (x, y), k in list(lab.items()):
        if k != top:
            continue
        a, b = ground(orient, x, y - lid.t0)
        # 2 juntas entre 3 tabuas
        # 1 junta entre 2 tabuas, no meio da largura
        if abs(b - (lid.b0 + lid.b1) / 2) < 1 / 32:
            c.set(x, y, 19)
        # aresta de tras (pixel de cima nao e tampa) pega luar: 17
        if lab.get((x, y - 1)) != top:
            c.set(x, y, 17)
    # contato com o fundo: linha 01 sob as faces da frente
    for (x, y), k in list(lab.items()):
        if k in ('lid_side', 'lid_end', 'body_side', 'body_end') and lab.get((x, y + 1)) in ('floor', None, 'rim'):
            pass


def crack_lid(c, lab, orient, lid):
    """rachadura em zigue-zague atravessando a tampa (01 com lasca 20 por cima), uma por metade."""
    top = lid.kind + '_top'
    pts = []
    for (a_c, sgn) in ((0.05, 1), (0.95, -1)):
        # caminho na largura b, com o eixo a oscilando
        for k in range(0, 9):
            b = lid.b0 + 0.02 + k * (lid.b1 - lid.b0 - 0.04) / 8
            a = a_c + sgn * (0.06 if k % 3 == 1 else (-0.04 if k % 3 == 2 else 0.0))
            pts.append((a, b))
        pts.append(None)
    # rasteriza: cada ponto do caminho vira o pixel de tela mais proximo da tampa
    hx, hy = ORIENT[orient]['head']
    seg = []
    for p in pts + [None]:
        if p is None:
            if seg:
                prev = None
                for (a, b) in seg:
                    u, v = (a, b) if orient == 'NOSE' else (b, a)
                    sx = 16 * (u - v)
                    sy = 8 * (u + v)
                    x = int(round(hx + 16 + sx - 0.5))
                    y = int(round(hy + 16 + sy - 0.5)) + lid.t0
                    if prev and abs(prev[0] - x) > 1:
                        # preenche o degrau horizontal
                        for xx in range(min(prev[0], x) + 1, max(prev[0], x)):
                            if lab.get((xx, prev[1])) == top:
                                c.set(xx, prev[1], 1)
                    if lab.get((x, y)) == top:
                        c.set(x, y, 1)
                        if lab.get((x, y - 1)) == top and c.get(x, y - 1) == 20:
                            c.set(x, y - 1, 17)
                    prev = (x, y)
            seg = []
        else:
            seg.append(p)


def coffin_closed():
    lid = Slab(A0, A1_, B0, B1, LID_T, LID_T, 'lid')
    body = Slab(A0, A1_, B0, B1, LID_T + 1, D, 'body')
    return lid, body


def state(orient, st, shift=0.0, lift=0, hollow=None):
    """st: 'exposed' | 'cracked' | 'open'; shift/lift para os frames da abertura."""
    if st == 'open':
        shift, hollow = 0.62, True
    lid = Slab(A0 + shift, A1_ + shift, B0 + (0.03 if shift else 0), B1 + (0.03 if shift else 0),
               LID_T - lift, LID_T - lift, 'lid')
    body = Slab(A0, A1_, B0, B1, LID_T + 1, D, 'body', hollow=bool(hollow))
    c, lab = render(orient, [lid, body])
    detail_lid(c, lab, orient, lid)
    if st == 'cracked':
        crack_lid(c, lab, orient, lid)
    return c


def split(orient, pair):
    """recorta o par nas 2 celulas 32x24 (cabeca, pes), cada uma no seu losango."""
    out = []
    for key in ('head', 'feet'):
        ox, oy = ORIENT[orient][key]
        t = Canvas(32, 24)
        for y in range(9, 24):
            s = row_span(y)
            for x in range(s[0], s[1] + 1):
                t.set(x, y, pair.get(ox + x, oy + y) or 0)
        out.append(t)
    return out


def grave_atlas():
    """dict (col, row) -> Canvas, layout de grave_a1."""
    cells = {}
    for row, st in enumerate(('exposed', 'cracked', 'open')):
        for k, orient in enumerate(('NOSE', 'NESO')):
            h, f = split(orient, state(orient, st))
            cells[(2 * k, row)] = h
            cells[(2 * k + 1, row)] = f
    return cells


OPEN_FRAMES = [dict(shift=0.0, lift=1, hollow=True), dict(shift=0.22, lift=1, hollow=True),
               dict(shift=0.45, lift=0, hollow=True), None]


def grave_open_atlas():
    """dict (frame, metade) -> Canvas, layout de grave_open_a1."""
    cells = {}
    for k, orient in enumerate(('NOSE', 'NESO')):
        for f, p in enumerate(OPEN_FRAMES):
            pair = state(orient, 'open') if p is None else state(orient, 'x', **p)
            h, ft = split(orient, pair)
            cells[(f, 2 * k)] = h
            cells[(f, 2 * k + 1)] = ft
    return cells
