from PIL import Image

PAL_HEX = """0d0b14 1a1626 2a2440 3d3660 58507f 7d789c a8a5bf d6d4e3
1f3b35 2f5a46 4a7d55 7aa35e 2b1a17 4a2c22 6e4430 946140
b88a5a 3b2230 5e3340 8a4b4f c9b48f e8dcc0 fff6e0 a8541a
e08a2a ffc94a 1b5e5a 2fb39a 7cf2c8 8fd3ff 8c2b3a d0465a""".split()
PAL = [tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) for h in PAL_HEX]  # PAL[i-1] = cor i

# legenda de caracteres -> indice (0 = transparente)
LEG = {'.': 0, 'K': 1, 'N': 2, 'I': 3, 'V': 4, 'L': 5, 'S': 6, 'M': 7, 'P': 8,
       'g': 9, 'G': 10, 'h': 11, 'H': 12, 't': 13, 'T': 14, 'u': 15, 'U': 16, 'b': 17,
       'c': 18, 'C': 19, 'r': 20, 'o': 21, 'O': 22, 'W': 23, 'y': 24, 'Y': 25, 'Z': 26,
       'e': 27, 'E': 28, 'F': 29, 'A': 30, 'x': 31, 'X': 32}


class Canvas:
    def __init__(self, w, h, fill=0):
        self.w, self.h = w, h
        self.px = [[fill] * w for _ in range(h)]

    def get(self, x, y):
        if 0 <= x < self.w and 0 <= y < self.h:
            return self.px[y][x]
        return None

    def set(self, x, y, c):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.px[y][x] = c

    def rect(self, x, y, w, h, c):
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                self.set(xx, yy, c)

    def rows(self, x0, y0, rows, transparent=True):
        for j, row in enumerate(rows):
            for i, ch in enumerate(row):
                v = LEG[ch]
                if v == 0 and transparent:
                    continue
                self.set(x0 + i, y0 + j, v)

    def blit(self, other, x0, y0):
        for y in range(other.h):
            for x in range(other.w):
                v = other.px[y][x]
                if v:
                    self.set(x0 + x, y0 + y, v)

    def crop(self, x, y, w, h):
        c = Canvas(w, h)
        for yy in range(h):
            for xx in range(w):
                c.px[yy][xx] = self.get(x + xx, y + yy) or 0
        return c

    def to_image(self):
        im = Image.new('P', (self.w, self.h))
        flat = [0, 0, 0] + [v for rgb in PAL for v in rgb]
        flat += [0] * (768 - len(flat))
        im.putpalette(flat)
        im.putdata([v for row in self.px for v in row])
        im.info['transparency'] = 0
        return im

    def save(self, path):
        self.to_image().save(path, transparency=0)

    def to_rgba(self, scale=1, bg=None):
        im = Image.new('RGBA', (self.w, self.h))
        data = []
        for row in self.px:
            for v in row:
                if v:
                    data.append(PAL[v - 1] + (255,))
                elif bg is not None:
                    data.append(PAL[bg - 1] + (255,))
                else:
                    data.append((0, 0, 0, 0))
        im.putdata(data)
        if scale != 1:
            im = im.resize((self.w * scale, self.h * scale), Image.NEAREST)
        return im


def check_rows(name, rows, w=16, h=16):
    assert len(rows) == h, f'{name}: {len(rows)} linhas'
    for i, r in enumerate(rows):
        assert len(r) == w, f'{name} linha {i}: {len(r)} chars: {r!r}'
        for ch in r:
            assert ch in LEG, f'{name} linha {i}: char {ch!r}'


# ------------------------------------------------------------------ helpers dos personagens
def from_rows(rows, w=None, h=None):
    h = h or len(rows)
    w = w or max(len(r) for r in rows)
    c = Canvas(w, h)
    for j, r in enumerate(rows):
        for i, ch in enumerate(r):
            assert ch in LEG, f'char {ch!r} na linha {j}'
            if LEG[ch]:
                c.set(i, j, LEG[ch])
    return c


def outline(c, color=1):
    """contorno externo de 1 px (vizinhanca 4) em volta de tudo que nao e transparente."""
    o = Canvas(c.w, c.h)
    o.blit(c, 0, 0)
    for y in range(c.h):
        for x in range(c.w):
            if c.px[y][x]:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                v = c.get(x + dx, y + dy)
                if v:
                    o.px[y][x] = color
                    break
    return o


def shifted(c, dx, dy):
    o = Canvas(c.w, c.h)
    o.blit(c, dx, dy)
    return o


def mirror(c):
    o = Canvas(c.w, c.h)
    for y in range(c.h):
        o.px[y] = list(reversed(c.px[y]))
    return o


def lonely_pixels(c, ignore=()):
    """pixels opacos sem nenhum vizinho opaco (8-viz.) = pixels soltos."""
    out = []
    for y in range(c.h):
        for x in range(c.w):
            if c.px[y][x] and c.px[y][x] not in ignore:
                n = 0
                for dy in (-1, 0, 1):
                    for dx in (-1, 0, 1):
                        if (dx or dy) and c.get(x + dx, y + dy):
                            n += 1
                if n == 0:
                    out.append((x, y))
    return out


def components(c):
    """numero de partes conectadas (8-viz.) da silhueta."""
    seen = set()
    n = 0
    for y in range(c.h):
        for x in range(c.w):
            if c.px[y][x] and (x, y) not in seen:
                n += 1
                st = [(x, y)]
                seen.add((x, y))
                while st:
                    a, b = st.pop()
                    for dy in (-1, 0, 1):
                        for dx in (-1, 0, 1):
                            p = (a + dx, b + dy)
                            if p not in seen and c.get(*p):
                                seen.add(p)
                                st.append(p)
    return n


# ------------------------------------------------------------------ formas e sombreamento
# (acrescentado no gerador de chefes/retratos; o resto do arquivo e copia do
#  _gerador_titulo_personagens/common.py)
def grid(s):
    return [r for r in s.strip('\n').split('\n')]


def put(c, rows, ox=0, oy=0):
    """sobrepoe linhas de caracteres ('.' mantem o que esta embaixo)."""
    for j, r in enumerate(rows):
        for i, ch in enumerate(r):
            assert ch in LEG, (ch, r)
            if ch != '.':
                c.set(ox + i, oy + j, LEG[ch])


def ellipse(cx, cy, rx, ry):
    """mascara de elipse (centros de pixel)."""
    m = set()
    for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
        for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
            dx = (x + 0.5 - cx) / rx
            dy = (y + 0.5 - cy) / ry
            if dx * dx + dy * dy <= 1.0:
                m.add((x, y))
    return m


def poly(pts):
    """mascara de poligono (teste no centro do pixel, regra par-impar)."""
    xs = [p[0] for p in pts]
    ys = [p[1] for p in pts]
    m = set()
    n = len(pts)
    for y in range(int(min(ys)) - 1, int(max(ys)) + 2):
        for x in range(int(min(xs)) - 1, int(max(xs)) + 2):
            px, py = x + 0.5, y + 0.5
            inside = False
            j = n - 1
            for i in range(n):
                xi, yi = pts[i]
                xj, yj = pts[j]
                if (yi > py) != (yj > py):
                    xc = xi + (py - yi) * (xj - xi) / (yj - yi)
                    if px < xc:
                        inside = not inside
                j = i
            if inside:
                m.add((x, y))
    return m


def rows_mask(rows, ox=0, oy=0, chars=None):
    """mascara a partir de linhas de caracteres (qualquer char != '.')."""
    m = set()
    for j, r in enumerate(rows):
        for i, ch in enumerate(r):
            if ch != '.' and (chars is None or ch in chars):
                m.add((ox + i, oy + j))
    return m


def shift_mask(m, dx, dy):
    return {(x + dx, y + dy) for (x, y) in m}


def dilate(m):
    o = set(m)
    for (x, y) in m:
        o.update(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
    return o


def paint(c, m, ramp, dark_w=2, light_w=1, ol=None, hi=None):
    """pinta a mascara com sombreamento direcional (lua no alto a esquerda).
    ramp = (sombra, base, luz). Faixa de sombra de largura dark_w junto as bordas
    de baixo/direita; filete de luz de largura light_w nas bordas de cima/esquerda.
    ol = cor de contorno interno (pinta o anel da mascara antes, por baixo).
    hi = cor de brilho (1 px) no canto de cima-esquerda mais exposto."""
    if ol is not None:
        for p in dilate(m) - m:
            c.set(p[0], p[1], ol)
    sh, base, lt = ramp
    for (x, y) in m:
        v = base
        if dark_w and any((x + i, y + i) not in m for i in range(1, dark_w + 1)):
            v = sh
        if light_w and any((x - i, y - i) not in m for i in range(1, light_w + 1)) \
                and (x + 1, y + 1) in m:
            v = lt
        c.set(x, y, v)
    if hi is not None:
        best = min(m, key=lambda p: (p[0] + p[1], p[1]))
        c.set(best[0] + 2, best[1] + 1, hi)


def fill(c, m, color):
    for (x, y) in m:
        c.set(x, y, color)


def recolor(c, mapping):
    o = Canvas(c.w, c.h)
    for y in range(c.h):
        for x in range(c.w):
            v = c.px[y][x]
            o.px[y][x] = mapping.get(v, v) if v else 0
    return o
