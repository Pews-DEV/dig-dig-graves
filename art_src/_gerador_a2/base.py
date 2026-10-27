"""Utilitarios comuns do gerador da Area 2 (Campo dos Indigentes).

Reaproveita Canvas/paleta de art_src/_gerador_turno/common.py. Caminhos relativos a este arquivo.
PNG indexados: 0 = transparente, 1-32 = Lua de Cova 32."""
import json
import os
import sys

sys.dont_write_bytecode = True
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
for p in (os.path.join(ROOT, 'art_src', '_gerador_turno'), os.path.join(ROOT, 'art_src', '_gerador_fundo_turno'), HERE):
    if p not in sys.path:
        sys.path.insert(0, p)

from PIL import Image                        # noqa: E402
from common import Canvas, PAL, LEG          # noqa: E402,F401

J = os.path.join
LUMA = [0] + [0.299 * r + 0.587 * g + 0.114 * b for (r, g, b) in PAL]

# DA §4.2: remapeamento de 1 degrau (21-32 nao mudam)
LIT = {1: 2, 2: 3, 3: 4, 4: 5, 5: 6, 6: 7, 7: 8, 8: 8, 9: 10, 10: 11, 11: 12, 12: 12,
       13: 14, 14: 15, 15: 16, 16: 17, 17: 17, 18: 19, 19: 20, 20: 20}

CELL_W, CELL_H = 32, 24
PIVOT = (16, 16)


def load(rel):
    """PNG indexado do repositorio -> Canvas (indices)."""
    im = Image.open(J(ROOT, *rel.split('/')))
    assert im.mode == 'P', rel
    c = Canvas(*im.size)
    data = list(im.get_flattened_data() if hasattr(im, 'get_flattened_data') else im.getdata())
    for y in range(im.size[1]):
        c.px[y] = data[y * im.size[0]:(y + 1) * im.size[0]]
    return c


def cell(atlas, col, row, w=CELL_W, h=CELL_H):
    return atlas.crop(col * w, row * h, w, h)


def lit(c):
    o = Canvas(c.w, c.h)
    for y in range(c.h):
        for x in range(c.w):
            v = c.px[y][x]
            o.px[y][x] = LIT.get(v, v)
    return o


def hstrip(frames):
    s = Canvas(frames[0].w * len(frames), frames[0].h)
    for i, f in enumerate(frames):
        s.blit(f, i * f.w, 0)
    return s


def grid(cells, cols, w=CELL_W, h=CELL_H):
    """cells: dict (col, row) -> Canvas."""
    rows = max(r for (_, r) in cells) + 1
    a = Canvas(cols * w, rows * h)
    for (cx, cy), c in cells.items():
        if c is not None:
            a.blit(c, cx * w, cy * h)
    return a


# ---------------------------------------------------------------- losango 32x16 (DA §5.1)
def row_width(y):
    if 9 <= y <= 16:
        return 4 * (y - 8)
    if 17 <= y <= 23:
        return 4 * (24 - y)
    return 0


def row_span(y):
    """(x0, x1) inclusivo da linha y do losango no canvas 32x24, ou None."""
    w = row_width(y)
    if not w:
        return None
    return 16 - w // 2, 16 + w // 2 - 1


def in_diamond(x, y):
    s = row_span(y)
    return s is not None and s[0] <= x <= s[1]


DIAMOND = [(x, y) for y in range(9, 24) for x in range(row_span(y)[0], row_span(y)[1] + 1)]
assert len(DIAMOND) == 256


def write_json(path, image_name, sheet_w, sheet_h, frames, tags):
    """JSON no formato Aseprite Array. frames: (nome, x, y, w, h, ms); tags: (nome, de, ate, direcao)."""
    data = {
        'frames': [{
            'filename': n, 'frame': {'x': x, 'y': y, 'w': w, 'h': h}, 'rotated': False, 'trimmed': False,
            'spriteSourceSize': {'x': 0, 'y': 0, 'w': w, 'h': h}, 'sourceSize': {'w': w, 'h': h}, 'duration': d}
            for n, x, y, w, h, d in frames],
        'meta': {'app': 'https://www.aseprite.org/', 'version': '1.3', 'image': image_name, 'format': 'I8',
                 'size': {'w': sheet_w, 'h': sheet_h}, 'scale': '1',
                 'frameTags': [{'name': n, 'from': a, 'to': b, 'direction': d, 'color': '#000000ff'}
                               for n, a, b, d in tags],
                 'layers': [], 'slices': []}}
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=1, ensure_ascii=False)
