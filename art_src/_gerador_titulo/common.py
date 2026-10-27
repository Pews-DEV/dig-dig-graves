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
