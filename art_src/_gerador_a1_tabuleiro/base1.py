"""Utilitarios do gerador do tabuleiro do estagio 1 (pacote ART-A1).

Reaproveita base.py do gerador da Area 2 (Canvas, paleta, LIT da DA §4.2, losango 32x16,
write_json no formato Aseprite Array). PNG indexados: 0 = transparente, 1-32 = Lua de Cova 32."""
import os
import sys

sys.dont_write_bytecode = True
HERE = os.path.dirname(os.path.abspath(__file__))
A2 = os.path.abspath(os.path.join(HERE, '..', '_gerador_a2'))
if A2 not in sys.path:
    sys.path.insert(0, A2)

from base import (Canvas, PAL, LEG, LUMA, LIT, J, ROOT, load, cell, lit, hstrip, grid,  # noqa: E402,F401
                  row_span, in_diamond, DIAMOND, write_json)

CH = '.KNIVLSMPgGhHtTuUbcCroOWyYZeEFAxX'   # indice -> caractere (inverso de LEG)


def from_rows(rows, w=None, h=None):
    h = h or len(rows)
    w = w or len(rows[0])
    assert len(rows) == h, (len(rows), h)
    c = Canvas(w, h)
    for y, r in enumerate(rows):
        assert len(r) == w, (y, len(r), r)
        for x, ch in enumerate(r):
            c.px[y][x] = LEG[ch]
    return c


def dump(c):
    return '\n'.join(''.join(CH[v] for v in row) for row in c.px)


def flip_h(c):
    o = Canvas(c.w, c.h)
    for y in range(c.h):
        o.px[y] = list(reversed(c.px[y]))
    return o


def loose_pixels(c):
    return [(x, y) for y in range(c.h) for x in range(c.w) if c.px[y][x] and not any(
        c.get(x + a, y + b) for a in (-1, 0, 1) for b in (-1, 0, 1) if (a or b))]
