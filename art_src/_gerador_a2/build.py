"""Pacote visual do estagio 2 · Campo dos Indigentes.

Uso:  python -B build.py          gera PNG/JSON em assets/ e previas em art_src/_previews/
      python -B build.py --ase    tambem monta os .aseprite fonte (precisa do Aseprite: variavel
                                  ASEPRITE ou 'aseprite' no PATH)
Reaproveita Canvas/paleta/kit/pa/mock de art_src/_gerador_turno/ e o fundo v2 de
art_src/_gerador_fundo_turno/. Tudo em indices da Lua de Cova 32 (0 = transparente)."""
import os
import shutil
import subprocess
import sys
import tempfile

import base
from base import Canvas, PAL, J, ROOT, LUMA, lit, hstrip, grid, load, cell, DIAMOND, write_json, in_diamond
from PIL import Image
import tiles_a2 as T
import graves_a2 as G
import cena_a2 as C

TILES = J(ROOT, 'assets', 'tiles', 'a2')
BG = J(ROOT, 'assets', 'sprites', 'bg', 'a2')
PROPS = J(ROOT, 'assets', 'sprites', 'props')
PREV = J(ROOT, 'art_src', '_previews')
WRITTEN = []
SPECS = []            # (caminho .aseprite, frames, duracoes, tags)
SWAY_MS = 800


def save(c, path):
    c.save(path)
    WRITTEN.append(path)


def src(sub, name):
    return J(ROOT, 'art_src', sub, name + '.aseprite')


# ===================================================================== geracao
def build_tiles():
    os.makedirs(TILES, exist_ok=True)
    out = {}
    cells = T.tiles_atlas()
    atlas = grid(cells, 5)
    save(atlas, J(TILES, 'tiles_a2.png'))
    save(lit(atlas), J(TILES, 'tiles_a2_lit.png'))
    out['tiles'] = atlas
    # fonte: frame n = coluna n; camada vN = linha N (como tile_a1_estagios)
    SPECS.append((src('tiles', 'tile_a2_estagios'), [atlas], [100], []))

    cr = T.cracks_atlas()
    save(cr, J(TILES, 'cracks_a2.png'))
    save(lit(cr), J(TILES, 'cracks_a2_lit.png'))
    out['cracks'] = cr
    SPECS.append((src('tiles', 'tile_a2_rachaduras'), [cr], [100], []))

    rg = T.regen_frames()
    sheet = hstrip(rg)
    save(sheet, J(TILES, 'regen_a2.png'))
    save(lit(sheet), J(TILES, 'regen_a2_lit.png'))
    durs = [83, 83, 82, 82]
    write_json(J(TILES, 'regen_a2.json'), 'regen_a2.png', sheet.w, sheet.h,
               [('tile_a2_regen %d.aseprite' % i, i * 32, 0, 32, 24, durs[i]) for i in range(4)],
               [('regen', 0, 3, 'forward')])
    out['regen'] = rg
    SPECS.append((src('tiles', 'tile_a2_regen'), rg, durs, [('regen', 0, 3)]))

    gv = grid(G.grave_atlas(), 4)
    save(gv, J(TILES, 'grave_a2.png'))
    save(lit(gv), J(TILES, 'grave_a2_lit.png'))
    out['grave'] = gv
    SPECS.append((src('tiles', 'tile_a2_cova'), [gv], [100], []))

    go = grid(G.grave_open_atlas(), 4)
    save(go, J(TILES, 'grave_open_a2.png'))
    save(lit(go), J(TILES, 'grave_open_a2_lit.png'))
    names = ['noSE_cabeca', 'noSE_pes', 'neSO_cabeca', 'neSO_pes']
    write_json(J(TILES, 'grave_open_a2.json'), 'grave_open_a2.png', go.w, go.h,
               [('grave_open_%s %d' % (names[r], f), f * 32, r * 24, 32, 24, durs[f])
                for r in range(4) for f in range(4)],
               [('open', 0, 3, 'forward')])
    out['grave_open'] = go
    SPECS.append((src('tiles', 'tile_a2_cova_abrir'), [go.crop(f * 32, 0, 32, 96) for f in range(4)], durs,
                  [('open', 0, 3)]))
    return out


def build_scene():
    os.makedirs(BG, exist_ok=True)
    out = {}
    blk, cells = C.block_atlas()
    save(blk, J(BG, 'bloco_a2.png'))
    out['bloco'], out['bloco_cells'] = blk, cells
    fen = C.fence_atlas()
    save(fen, J(BG, 'cerca_a2.png'))
    out['cerca'] = fen
    tf = C.tufts()
    save(tf, J(BG, 'tufos_a2.png'))
    out['tufos'] = tf
    sg = C.sign_atlas()
    save(sg, J(BG, 'placa_a2.png'))
    out['placa'] = sg
    for name, c in (('bg_bloco_a2', blk), ('bg_cerca_a2', fen), ('bg_tufos_a2', tf), ('bg_placa_a2', sg)):
        SPECS.append((src('bg', name), [c], [100], []))
    # props do estagio
    cz = C.cross_atlas()
    save(cz, J(PROPS, 'cruz_madeira.png'))
    lp = C.lapide_compat()
    save(lp, J(PROPS, 'lapide_a2.png'))
    pc = C.puddle_atlas()
    save(pc, J(PROPS, 'poca_lama.png'))
    save(lit(pc), J(PROPS, 'poca_lama_lit.png'))
    out['cruz'], out['lapide'], out['poca'] = cz, lp, pc
    SPECS.append((src('props', 'prop_cruz_madeira'), [C.cross(v) for v in range(3)], [100] * 3, []))
    SPECS.append((src('props', 'prop_lapide_a2'), [lp], [100], []))
    SPECS.append((src('props', 'prop_poca_lama'), [C.puddle(v) for v in range(2)], [100] * 2, []))
    return out


def build_bg():
    import fundo_a2 as FA
    import fundo as F
    m0 = FA.mata_frame(0)
    m1 = FA.mata_frame(1)
    ch = FA.chao(m0)
    FA.trunk_shadows(m0, ch)
    FA.trunk_shadows(m1, ch)
    pr = FA.props(ch)
    save(ch, J(BG, 'bg_a2_chao.png'))
    save(pr, J(BG, 'bg_a2_props.png'))
    sheet = Canvas(F.W * 2, F.H)
    sheet.blit(m0, 0, 0)
    sheet.blit(m1, F.W, 0)
    save(sheet, J(BG, 'bg_a2_mata.png'))
    write_json(J(BG, 'bg_a2_mata.json'), 'bg_a2_mata.png', sheet.w, sheet.h,
               [('bg_a2_mata %d.aseprite' % i, i * F.W, 0, F.W, F.H, SWAY_MS) for i in range(2)],
               [('idle', 0, 1, 'forward')])
    SPECS.append((src('bg', 'bg_a2_chao'), [ch], [100], []))
    SPECS.append((src('bg', 'bg_a2_props'), [pr], [100], []))
    SPECS.append((src('bg', 'bg_a2_mata'), [m0, m1], [SWAY_MS, SWAY_MS], [('idle', 0, 1)]))
    return dict(chao=ch, props=pr, mata=[m0, m1])


# ===================================================================== checagens
def check_palette():
    want = [v for rgb in PAL for v in rgb]
    for f in WRITTEN:
        im = Image.open(f)
        assert im.mode == 'P', f
        mx = max(im.get_flattened_data() if hasattr(im, 'get_flattened_data') else im.getdata())
        assert mx <= 32 and im.getpalette()[3:3 + 96] == want, (f, mx)
        assert im.info.get('transparency') == 0, f
    print('[1] paleta OK: %d PNG indexados, indices <= 32, paleta = Lua de Cova 32' % len(WRITTEN))


def check_fit(name, c, allow_tufts=True, full=True):
    """encaixe 32x16: nada fora do losango, exceto tufos na folga de cima (acima de uma aresta de
    cima, y >= 7); losango sem furos."""
    bad = []
    for y in range(c.h):
        for x in range(c.w):
            if not c.px[y][x] or in_diamond(x, y):
                continue
            above_edge = allow_tufts and y >= 7 and any(in_diamond(x, yy) for yy in range(y + 1, 17))
            if not above_edge:
                bad.append((x, y))
    holes = [(x, y) for (x, y) in DIAMOND if not c.px[y][x]] if full else []
    assert not bad and not holes, (name, bad[:5], holes[:5])


def checks(o_t, o_s):
    rep = {}
    # 2) encaixe de todas as celulas de tile
    n = 0
    for (cx, cy), c in T.tiles_atlas().items():
        if c is not None:
            check_fit('tiles %d,%d' % (cx, cy), c)
            n += 1
    for (cx, cy), c in G.grave_atlas().items():
        check_fit('grave %d,%d' % (cx, cy), c, allow_tufts=False)
        n += 1
    for (cx, cy), c in G.grave_open_atlas().items():
        check_fit('grave_open %d,%d' % (cx, cy), c, allow_tufts=False)
        n += 1
    for i, c in enumerate(T.regen_frames()):
        check_fit('regen %d' % i, c)
        n += 1
    for v in range(2):
        check_fit('poca %d' % v, C.puddle(v))
        n += 1
    print('[2] encaixe 32x16 OK em %d celulas (so tufos na folga de cima; losango sem furos)' % n)
    # 3) valor (teste em cinza): luma media do miolo (sem as bordas de 2 px)
    def mean(c, center=False):
        # DA §7: "a escala de valor do CENTRO do tile desce a cada estagio" -> miolo = losango
        # interno de meia escala; tambem a media do losango inteiro (sem a borda de 2 px)
        pts = [(x, y) for (x, y) in DIAMOND if (T.basin(x, y, 0.5) if center else not T.is_edge(x, y))]
        return sum(LUMA[c.px[y][x]] for (x, y) in pts) / len(pts)
    cells = T.tiles_atlas()
    a1 = load('assets/tiles/a1/tiles_a1.png')
    order = [('S0 grama rala', 0), ('S1 terra', 1), ('Lama', 4), ('S2 barro', 2), ('S3 buraco', 3)]
    cen = []
    for name, col in order:
        ms = [mean(cells[(col, v)], True) for v in range(3) if cells.get((col, v))]
        mm = [mean(cells[(col, v)]) for v in range(3) if cells.get((col, v))]
        cen.append(sum(ms) / len(ms))
        ref = ''
        if col < 4:
            r = [mean(cell(a1, col, v), True) for v in range(3 if col < 2 else 2)]
            ref = ' | A1 miolo %.1f' % (sum(r) / len(r))
        print('    %-14s miolo %5.1f  losango %5.1f%s' % (name, cen[-1], sum(mm) / len(mm), ref))
    gaps = [cen[i] - cen[i + 1] for i in range(len(cen) - 1)]
    print('[3] teste em cinza: valor do miolo desce a cada estagio; degraus', ', '.join('%.1f' % g for g in gaps))
    assert all(g >= 4 for g in gaps), gaps
    gm = [mean(c) for c in G.grave_atlas().values()]
    print('    covas: luma media %.1f-%.1f' % (min(gm), max(gm)))
    # 4) lama 27 <= 15% da area
    worst = 0
    for name, c in [('lama v%d' % v, cells[(4, v)]) for v in range(3)] + \
                   [('poca v%d' % v, C.puddle(v)) for v in range(2)] + \
                   [('s2 v%d' % v, cells[(2, v)]) for v in range(2)]:
        p = sum(1 for (x, y) in DIAMOND if c.px[y][x] == 27) / 256
        worst = max(worst, p)
        print('    27 em %-8s %4.1f%%' % (name, 100 * p))
    rep['27_tile_max'] = worst
    assert worst <= 0.15, worst
    # 5) pixels soltos (sem vizinho 8 opaco) nos sprites com transparencia
    for name, c in (('cruz', o_s['cruz']), ('cerca', o_s['cerca']), ('tufos', o_s['tufos']),
                    ('placa', o_s['placa']), ('poca', o_s['poca'])):
        loose = [(x, y) for y in range(c.h) for x in range(c.w) if c.px[y][x] and not any(
            c.get(x + a, y + b) for a in (-1, 0, 1) for b in (-1, 0, 1) if (a or b))]
        print('    pixels soltos em %-6s %d' % (name, len(loose)))
        assert not loose, (name, loose[:5])
    print('[4] lama 27 <= 15%% de cada tile (pior: %.1f%%); [5] sem pixels soltos nos props' % (100 * worst))
    return rep


def check_bg(o):
    import fundo as F
    for name, lay in (('chao', o['chao']), ('props', o['props']), ('mata0', o['mata'][0]), ('mata1', o['mata'][1])):
        vals = [v for row in lay.px for v in row if v]
        deco = [v for v in vals if v not in F.FLAME]
        mx = max(LUMA[v] for v in deco)
        p27 = sum(1 for v in vals if v == 27) / max(1, len(vals))
        print('    %-6s cores %s | luma max (sem chamas) %.1f | 27: %.2f%%' % (name, sorted(set(vals)), mx, 100 * p27))
        assert mx <= 105.5, (name, mx)
    for name, lay in (('props', o['props']), ('mata0', o['mata'][0]), ('mata1', o['mata'][1])):
        n = sum(1 for y in range(F.Y0, F.Y1) for x in range(F.X0, F.X1) if lay.g(x, y) and F.in_zone(x, y, 0))
        hud = sum(1 for y in range(F.Y0, F.Y1) for x in range(F.X0, F.X1)
                  if lay.g(x, y) and F.near_hud(x, y, 4) and LUMA[lay.g(x, y)] > 60)
        print('    %-6s px no maior campo: %d | px claros (>60) junto das plaquetas: %d' % (name, n, hud))
        assert n == 0 and hud == 0, name
    s = compose_bg(o)
    a1 = Canvas(640, 360)
    for f in ('bg_a1_chao', 'bg_a1_props'):
        a1.blit(load('assets/sprites/bg/a1/%s.png' % f), -16, -16)
    a1.blit(load('assets/sprites/bg/a1/bg_a1_mata.png').crop(0, 0, 672, 392), -16, -16)
    m2 = sum(LUMA[v] for row in s.px for v in row) / (640 * 360)
    m1 = sum(LUMA[v] for row in a1.px for v in row) / (640 * 360)
    print('[6] fundo: zona livre e plaquetas OK; luma media A2 %.1f (A1 %.1f)' % (m2, m1))


def compose_bg(o, frame=0):
    s = Canvas(640, 360)
    for lay in (o['chao'], o['props'], o['mata'][frame]):
        s.blit(lay, -16, -16)
    return s


# ===================================================================== aseprite (opcional)
def find_aseprite():
    cand = [os.environ.get('ASEPRITE'), shutil.which('aseprite'), shutil.which('Aseprite'),
            r'C:\Program Files (x86)\Steam\steamapps\common\Aseprite\Aseprite.exe',
            r'C:\Program Files\Aseprite\Aseprite.exe']
    for c in cand:
        if c and os.path.exists(c):
            return c
    return None


def lua_str(s):
    return '"' + s.replace('\\', '\\\\') + '"'


def build_aseprite(ase):
    tmp = tempfile.mkdtemp(prefix='ddg_a2_')
    lines = ['local function build(out, frames, durs, tags)',
             '  local imgs = {}',
             '  for i = 2, #frames do local o = app.open(frames[i]); imgs[i] = Image(o.cels[1].image);'
             ' imgs[i .. "p"] = Point(o.cels[1].position.x, o.cels[1].position.y); o:close() end',
             '  local spr = app.open(frames[1])',
             '  local layer = spr.layers[1]; layer.name = "arte"',
             '  for i = 2, #frames do spr:newEmptyFrame(i); spr:newCel(layer, i, imgs[i], imgs[i .. "p"]) end',
             '  for i = 1, #frames do spr.frames[i].duration = durs[i] / 1000 end',
             '  for _, t in ipairs(tags) do local tg = spr:newTag(t[2] + 1, t[3] + 1); tg.name = t[1] end',
             '  spr.transparentColor = 0',
             '  spr:saveAs(out)',
             '  spr:close()',
             'end']
    for out, frames, durs, tags in SPECS:
        os.makedirs(os.path.dirname(out), exist_ok=True)
        name = os.path.splitext(os.path.basename(out))[0]
        paths = []
        for i, f in enumerate(frames):
            d = J(tmp, name, 'f%d' % i)
            os.makedirs(d, exist_ok=True)
            p = J(d, 'quadro.png')
            f.save(p)
            paths.append(p)
        fl = '{' + ', '.join(lua_str(p) for p in paths) + '}'
        dl = '{' + ', '.join(str(d) for d in durs) + '}'
        tl = '{' + ', '.join('{%s, %d, %d}' % (lua_str(n), a, b) for (n, a, b) in tags) + '}'
        lines.append('build(%s, %s, %s, %s)' % (lua_str(out), fl, dl, tl))
    lua = J(tmp, 'build_a2.lua')
    open(lua, 'w', encoding='utf-8').write('\n'.join(lines) + '\n')
    r = subprocess.run([ase, '-b', '--script', lua], capture_output=True, text=True)
    if r.returncode != 0 or 'rror' in (r.stdout + r.stderr):
        print(r.stdout, r.stderr)
        raise SystemExit('aseprite falhou')
    print('.aseprite montados:', len(SPECS))


if __name__ == '__main__':
    import previas_a2 as PV
    ot = build_tiles()
    os_ = build_scene()
    ob = build_bg()
    check_palette()
    checks(ot, os_)
    check_bg(ob)
    PV.all_previews(ot, os_, ob, compose_bg)
    if '--ase' in sys.argv:
        ase = find_aseprite()
        if not ase:
            raise SystemExit('Aseprite nao encontrado (defina ASEPRITE)')
        build_aseprite(ase)
    else:
        print('.aseprite: pendente (rode com --ase numa maquina com Aseprite)')
    print('ok')
