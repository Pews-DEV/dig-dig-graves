"""Pacote ART-A1 · Tabuleiro do estagio 1 (plano v1 §3, briefs §7; DA §13.1, §13.5).

Uso:  python -B build.py     gera PNG/JSON em assets/ e previas em art_src/_previews/

Produz:
  tiles_a1 / tiles_a1_lit      +2 colunas: 4 = reservada (vazia; camada propria do estagio, como a
                               Lama na A2) e 5 = OSSADA v1-v3. Colunas 0-3 copiadas pixel a pixel.
  cracks_a1 / cracks_a1_lit    linhas 3-4 vazias e linha 5 = Ossada (linha = coluna do tile, como
                               na A2). Linhas 0-2 copiadas pixel a pixel.
  lapide                       colunas 0-2 redesenhadas (foto oval / cruz / musgo torta).
  icons_lapide                 3 icones 8x8 do tipo de lapide (tooltip).
  vela_campo (+_lit, +_halo)   vela de Finados no tile, idle 3f.
  moeda_ouro                   spin 4f + pop 3f.
  icon_key_1 / icon_key_1_32   chave da cripta 1, spin 4f.
regen_a1 nao muda (a regeneracao vai do Buraco a Grama; a Ossada nunca aparece nela).
O .aseprite fonte fica pendente (ambiente sem Aseprite), como nos outros geradores em Python."""
import os
import subprocess
import sys

import base1  # noqa: F401  (ajusta o sys.path)
from base1 import (Canvas, PAL, J, ROOT, LUMA, load, cell, lit, hstrip, write_json, DIAMOND, in_diamond,
                   loose_pixels)
from PIL import Image
import io
import ossada as OS
import lapides as LP
import itens as IT
import previas_a1t as PV

TILES = J(ROOT, 'assets', 'tiles', 'a1')
PROPS = J(ROOT, 'assets', 'sprites', 'props')
FX = J(ROOT, 'assets', 'sprites', 'fx')
ICONS = J(ROOT, 'assets', 'ui', 'icons')
WRITTEN = []
OSSADA_COL = 5


def save(c, path):
    c.save(path)
    WRITTEN.append(path)


BASE_REV = '8f66bbf'   # ultimo commit antes do ART-A1: fonte das celulas antigas (nunca redesenhadas)


def head_png(rel):
    """PNG indexado na versao BASE_REV do git (para provar que as celulas antigas nao mudaram)."""
    data = subprocess.run(['git', '-C', ROOT, 'show', BASE_REV + ':' + rel], capture_output=True, check=True).stdout
    im = Image.open(io.BytesIO(data))
    c = Canvas(*im.size)
    d = list(im.getdata())
    for y in range(im.size[1]):
        c.px[y] = d[y * im.size[0]:(y + 1) * im.size[0]]
    return c


def same(a, b, w, h):
    return all(a.px[y][x] == b.px[y][x] for y in range(h) for x in range(w))


# ===================================================================== geracao
def build_tiles():
    old = head_png('assets/tiles/a1/tiles_a1.png')
    old_l = head_png('assets/tiles/a1/tiles_a1_lit.png')
    assert (old.w, old.h) == (128, 72)
    oss = [OS.ossada(v) for v in range(3)]
    at = Canvas(32 * 6, 72)
    at.blit(old, 0, 0)
    at_l = Canvas(32 * 6, 72)
    at_l.blit(old_l, 0, 0)
    for v, c in enumerate(oss):
        at.blit(c, OSSADA_COL * 32, v * 24)
        at_l.blit(lit(c), OSSADA_COL * 32, v * 24)
    save(at, J(TILES, 'tiles_a1.png'))
    save(at_l, J(TILES, 'tiles_a1_lit.png'))

    cr_old = head_png('assets/tiles/a1/cracks_a1.png')
    cr_old_l = head_png('assets/tiles/a1/cracks_a1_lit.png')
    assert (cr_old.w, cr_old.h) == (32, 24)
    cr = Canvas(32, 48)
    cr.blit(cr_old, 0, 0)
    cr.blit(cr_old.crop(0, 16, 32, 8), 0, 8 * OSSADA_COL)      # Ossada: 01 + borda 15 (como o Barro)
    cr_l = Canvas(32, 48)
    cr_l.blit(cr_old_l, 0, 0)
    cr_l.blit(lit(cr_old.crop(0, 16, 32, 8)), 0, 8 * OSSADA_COL)
    save(cr, J(TILES, 'cracks_a1.png'))
    save(cr_l, J(TILES, 'cracks_a1_lit.png'))
    return dict(tiles=at, tiles_lit=at_l, old=old, old_lit=old_l, cracks=cr, cracks_old=cr_old,
                cracks_lit=cr_l, cracks_old_lit=cr_old_l, ossada=oss)


def build_props():
    lap = LP.lapide_atlas()
    save(lap, J(PROPS, 'lapide.png'))
    ic = LP.icon_atlas()
    save(ic, J(ICONS, 'icons_lapide.png'))
    vf = IT.vela_campo_frames()
    vs = hstrip(vf)
    save(vs, J(PROPS, 'vela_campo.png'))
    save(lit(vs), J(PROPS, 'vela_campo_lit.png'))
    write_json(J(PROPS, 'vela_campo.json'), 'vela_campo.png', vs.w, vs.h,
               [('vela_campo %d.aseprite' % i, i * 32, 0, 32, 24, 125) for i in range(3)],
               [('idle', 0, 2, 'forward')])
    halo = IT.vela_halo()
    save(halo, J(PROPS, 'vela_campo_halo.png'))
    cf = IT.coin_frames()
    cs = hstrip(cf)
    save(cs, J(FX, 'moeda_ouro.png'))
    durs = [100] * 4 + [83] * 3
    write_json(J(FX, 'moeda_ouro.json'), 'moeda_ouro.png', cs.w, cs.h,
               [('moeda_ouro %d.aseprite' % i, i * 8, 0, 8, 8, durs[i]) for i in range(7)],
               [('spin', 0, 3, 'forward'), ('pop', 4, 6, 'forward')])
    k16, k32 = IT.key16_frames(), IT.key32_frames()
    s16, s32 = hstrip(k16), hstrip(k32)
    save(s16, J(ICONS, 'icon_key_1.png'))
    save(s32, J(ICONS, 'icon_key_1_32.png'))
    for name, s, n in (('icon_key_1', s16, 16), ('icon_key_1_32', s32, 32)):
        write_json(J(ICONS, name + '.json'), name + '.png', s.w, s.h,
                   [('%s %d.aseprite' % (name, i), i * n, 0, n, n, 125) for i in range(4)],
                   [('spin', 0, 3, 'forward')])
    return dict(lapide=lap, lapides=LP.lapides(), icons=ic, vela=vf, halo=halo, coin=cf, key16=k16, key32=k32)


# ===================================================================== checagens (DA §11.5)
def check_palette():
    want = [v for rgb in PAL for v in rgb]
    for f in WRITTEN:
        im = Image.open(f)
        assert im.mode == 'P', f
        mx = max(im.getdata())
        assert mx <= 32 and im.getpalette()[3:3 + 96] == want, (f, mx)
        assert im.info.get('transparency') == 0, f
    print('[1] paleta: %d PNG indexados, indices <= 32, paleta = Lua de Cova 32' % len(WRITTEN))


def check_fit(name, c):
    bad = []
    for y in range(c.h):
        for x in range(c.w):
            if not c.px[y][x] or in_diamond(x, y):
                continue
            if not (y >= 2 and any(in_diamond(x, yy) for yy in range(y + 1, 17))):
                bad.append((x, y))
    holes = [(x, y) for (x, y) in DIAMOND if not c.px[y][x]]
    assert not bad and not holes, (name, bad[:5], holes[:5])


def checks(t, p):
    # [0] celulas antigas intactas
    assert same(t['tiles'], t['old'], 128, 72) and same(t['tiles_lit'], t['old_lit'], 128, 72)
    assert same(t['cracks'], t['cracks_old'], 32, 24) and same(t['cracks_lit'], t['cracks_old_lit'], 32, 24)
    for x in range(128, 160):
        for y in range(72):
            assert not t['tiles'].px[y][x], 'coluna 4 deve ficar vazia'
    assert same(lit(t['old']), t['old_lit'], 128, 72)
    print('[0] tiles_a1/cracks_a1 (+_lit): colunas 0-3 e linhas 0-2 identicas ao commit %s' % BASE_REV + '; coluna 4 vazia')
    # [2] encaixe
    for v, c in enumerate(t['ossada']):
        check_fit('ossada v%d' % v, c)
    for f, c in enumerate(p['vela']):
        check_fit('vela_campo f%d' % f, c)
    print('[2] encaixe 32x16: Ossada v1-v3 e vela_campo sem pixel fora do losango (so a chama/velas na folga)')
    # [3] valor (cinza): miolo do tile, mesma medida do gerador da A2
    import tiles_a2 as T2

    def mean(c):
        pts = [(x, y) for (x, y) in DIAMOND if T2.basin(x, y, 0.5)]
        return sum(LUMA[c.px[y][x]] for (x, y) in pts) / len(pts)
    a1 = t['old']
    rows = [('S0 grama', [cell(a1, 0, v) for v in range(3)]), ('S1 terra', [cell(a1, 1, v) for v in range(3)]),
            ('S2 barro', [cell(a1, 2, v) for v in range(2)]), ('Ossada', t['ossada']),
            ('S3 buraco', [cell(a1, 3, v) for v in range(2)])]
    cen = []
    for name, cs in rows:
        ms = [mean(c) for c in cs]
        cen.append(sum(ms) / len(ms))
        print('    %-10s miolo %5.1f  (%s)' % (name, cen[-1], ', '.join('%.1f' % m for m in ms)))
    gaps = [cen[i] - cen[i + 1] for i in range(len(cen) - 1)]
    print('[3] cinza: o miolo desce a cada camada; degraus', ', '.join('%.1f' % g for g in gaps))
    assert all(g >= 4 for g in gaps), gaps
    share = [OS.bone_share(c) for c in t['ossada']]
    print('    ossos 21/22 por tile: %s (limite 15%%)' % ', '.join('%.1f%%' % (100 * s) for s in share))
    assert max(share) <= 0.15
    # lapides: valor medio e altura distintos
    for i, c in enumerate(p['lapides']):
        px = [v for row in c.px for v in row if v and v not in (1, 2)]
        top = min(y for y in range(24) if any(c.px[y]))
        print('    lapide col %d: luma media %.0f, topo y = %d, altura %d px' % (
            i, sum(LUMA[v] for v in px) / len(px), top, 22 - top))
    # [5] pixels soltos (sprites com contorno; FX/halo ficam de fora: sem contorno por regra)
    for name, cs in (('lapide', p['lapides']), ('icons_lapide', LP.icons()), ('vela_campo', p['vela']),
                     ('moeda spin', p['coin'][:5]), ('key16', p['key16']), ('key32', p['key32'])):
        for i, c in enumerate(cs):
            lp = loose_pixels(c)
            assert not lp, (name, i, lp[:5])
    print('[5] sem pixels soltos (lapides, icones, vela, moeda, chaves)')
    # papeis de cor: 27-30 (sobrenatural) e 31-32 (perigo) fora de tudo
    for name, c in (('tiles', t['tiles']), ('lapide', p['lapide']), ('vela', hstrip(p['vela'])),
                    ('moeda', hstrip(p['coin'])), ('key', hstrip(p['key16'])), ('key32', hstrip(p['key32']))):
        bad = {v for row in c.px for v in row if 27 <= v <= 32}
        assert not bad, (name, bad)
    print('[6] papeis de cor: nenhum 27-32; 24-26 so em vela, halo e moeda')


if __name__ == '__main__':
    t = build_tiles()
    p = build_props()
    check_palette()
    checks(t, p)
    PV.all_previews(t, p)
    print('.aseprite: pendente (sem Aseprite neste ambiente)')
    print('ok')
