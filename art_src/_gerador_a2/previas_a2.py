"""Previas da Area 2 em art_src/_previews/ (nunca em assets/)."""
import random

from base import Canvas, J, ROOT, load, cell
import tiles_a2 as T

PREV = J(ROOT, 'art_src', '_previews')


def grey(im):
    return im.convert('L').convert('RGB')


def mock_mod():
    import mock
    mock.load = lambda p: load(p.replace('\\', '/'))
    return mock


def tile_pos(O, i, j):
    return O[0] + (i - j) * 16, O[1] + (i + j) * 8


def field(scr, o_t, o_s, N, O, layout, cursor=None, radius=3, decor=True):
    """desenha o diorama N x N da A2 em scr. layout: dict com stage/graves/rocks/puddles/crosses."""
    tiles, tiles_l = o_t['tiles'], T_lit(o_t['tiles'])
    grave, grave_l = o_t['grave'], T_lit(o_t['grave'])
    poca = o_s['poca']
    poca_l = T_lit(poca)
    rocha = load('assets/sprites/props/rocha.png')
    cz = o_s['cruz']
    fen = o_s['cerca']
    fen_no, fen_ne, post = fen.crop(0, 0, 32, 32), fen.crop(32, 0, 32, 32), fen.crop(64, 0, 32, 32)
    for j in layout.get('fence_no', []):
        x, y = tile_pos(O, 0, j)
        scr.blit(fen_no, x - 16, y - 24)
    for i in layout.get('fence_ne', []):
        x, y = tile_pos(O, i, 0)
        scr.blit(fen_ne, x - 16, y - 24)
    tx, ty = tile_pos(O, 0, 0)
    scr.blit(post, tx - 16, ty - 8 - 31 + 8)
    rnd = random.Random(N * 7 + 1)
    order = sorted(((i, j) for i in range(N) for j in range(N)), key=lambda p: (p[0] + p[1], p[0]))
    for (i, j) in order:
        x, y = tile_pos(O, i, j)
        lit = False
        if cursor:
            d = max(abs(i - cursor[0]), abs(j - cursor[1]))
            lit = d <= radius - 1 or (d == radius and (i + j) % 2 == 0)
        if (i, j) in layout['graves']:
            col, row = layout['graves'][(i, j)]
            scr.blit(cell(grave_l if lit else grave, col, row), x - 16, y - 16)
            continue
        if (i, j) in layout.get('puddles', {}):
            scr.blit(cell(poca_l if lit else poca, layout['puddles'][(i, j)], 0), x - 16, y - 16)
            continue
        s, v = layout['stage'].get((i, j), (0, None))
        if v is None:
            v = rnd.randrange(3 if s in (0, 1, 4) else 2)
        scr.blit(cell(tiles_l if lit else tiles, s, v), x - 16, y - 16)
        if (i, j) in layout.get('rocks', {}):
            scr.blit(cell(rocha, layout['rocks'][(i, j)], 0), x - 16, y - 16)
    for ((i, j), v) in sorted(layout.get('crosses', {}).items(), key=lambda p: p[0][0] + p[0][1]):
        x, y = tile_pos(O, i, j)
        scr.blit(cz.crop(v * 12, 0, 12, 20), x - 6, y - 19)
    cells = o_s['bloco_cells']
    for i in range(N):
        x, y = tile_pos(O, i, N - 1)
        c = cells[8] if i == N - 1 else (cells[3] if i == 0 else cells[i % 3])
        scr.blit(c, x - 16, y - 16)
    for j in range(N - 1):
        x, y = tile_pos(O, N - 1, j)
        scr.blit(cells[7] if j == 0 else cells[4 + j % 3], x - 16, y - 16)
    if decor:
        tf = o_s['tufos']
        lx, ly = tile_pos(O, 0, N - 1)
        rx, ry = tile_pos(O, N - 1, 0)
        bx, by = tile_pos(O, N - 1, N - 1)
        for (x, y, k) in [(lx - 24, ly + 18, 0), (lx - 12, ly + 30, 2), (rx + 12, ry + 20, 1),
                          (rx + 22, ry + 8, 0), (bx - 40, by + 34, 1), (bx + 26, by + 30, 2),
                          (tx - 30, ty + 2, 1), (tx + 26, ty + 4, 0)]:
            scr.blit(tf.crop(0, k * 8, 12, 8), x - 6, y - 7)
        if N >= 10:
            scr.blit(o_s['placa'].crop(0, 0, 56, 26), lx - 70, ly + 4)
            velas = load('assets/sprites/props/velas_grupo.png')
            scr.blit(velas.crop(16, 0, 16, 12), rx + 14, ry + 2)


_LIT_CACHE = {}


def T_lit(c):
    from base import lit
    k = id(c)
    if k not in _LIT_CACHE:
        _LIT_CACHE[k] = lit(c)
    return _LIT_CACHE[k]


def layout12():
    st = {}
    for p in [(2, 7), (3, 7), (3, 8), (8, 3), (9, 3), (9, 4), (6, 9), (7, 9), (4, 4), (5, 4), (4, 5)]:
        st[p] = (1, None)
    for p in [(5, 5), (6, 7), (4, 6), (7, 5), (8, 4), (3, 6), (6, 8)]:
        st[p] = (4, None)                      # lama
    for p in [(5, 7), (6, 6)]:
        st[p] = (2, None)
    for p in [(6, 5), (5, 6)]:
        st[p] = (3, None)
    return dict(stage=st,
                graves={(3, 10): (0, 0), (4, 10): (1, 0), (9, 8): (2, 1), (9, 9): (3, 1)},
                crosses={(2, 10): 0, (9, 7): 1, (1, 2): 2, (10, 5): 1},
                rocks={(2, 2): 1},
                puddles={(8, 9): 0, (10, 2): 1},
                fence_no=[1, 2, 3, 4, 8, 9, 10], fence_ne=[2, 3, 4, 5, 7, 8, 9, 10])


def mock_scene(o_t, o_s, bg, frame_cursor=True):
    import pa
    mock = mock_mod()
    N, O = 12, (320, 78)
    mock.N, mock.O = N, O
    s = Canvas(640, 360)
    s.blit(bg, 0, 0)
    field(s, o_t, o_s, N, O, layout12(), cursor=(5, 6), radius=3)
    ms = load('assets/sprites/bg/a1/nevoa_a1.png')
    for (x, y, r) in [(30, 246, 0), (350, 246, 0), (170, 276, 1), (-150, 276, 1), (490, 276, 1)]:
        s.blit(ms.crop(0, r * 24, 320, 24), x, y)
    mock.area_outline(s, 5, 6)
    x, y = tile_pos(O, 5, 6)
    s.blit(pa.frames()[0][1], x - 3, y - 20)
    s.blit(load('assets/sprites/bg/a1/vinheta.png'), 0, 0)
    mock.hud(s)
    return s


def campo6(o_t, o_s, bg=None):
    N, O = 6, (112, 34)
    c = Canvas(224, 160, 2)
    if bg is not None:
        c.blit(bg.crop(208, 112, 224, 160), 0, 0)
    lay = dict(stage={(0, 0): (0, 0), (1, 0): (0, 1), (2, 0): (0, 2), (3, 0): (1, 0), (4, 0): (1, 1), (5, 0): (1, 2),
                      (0, 1): (4, 0), (1, 1): (4, 1), (2, 1): (4, 2), (3, 1): (2, 0), (4, 1): (2, 1), (5, 1): (3, 0),
                      (0, 2): (3, 1), (1, 2): (4, 0), (2, 2): (1, 0), (5, 2): (0, 1),
                      (0, 3): (0, 0), (1, 3): (1, 1), (2, 3): (4, 1), (3, 3): (2, 0), (4, 3): (3, 0), (5, 3): (4, 2),
                      (0, 4): (0, 2), (2, 4): (0, 0), (4, 4): (1, 0)},
               graves={(3, 2): (0, 0), (4, 2): (1, 0), (1, 4): (2, 2), (1, 5): (3, 2)},
               crosses={(2, 2): 0, (1, 3): 1},
               puddles={(5, 4): 0, (3, 5): 1},
               fence_no=[1, 2, 4], fence_ne=[1, 2, 4])
    # cruz do (1, 3) fica em cima de terra (o tile da lapide e bloqueado; ok na previa)
    field(c, o_t, o_s, N, O, lay, decor=True)
    return c


def atlas_sheet(o_t, o_s):
    from base import lit
    items = [('tiles_a2', o_t['tiles']), ('tiles_a2_lit', lit(o_t['tiles'])),
             ('grave_a2', o_t['grave']), ('grave_open_a2', o_t['grave_open']),
             ('regen_a2', T.__dict__ and _hs(o_t['regen'])), ('cracks_a2', o_t['cracks']),
             ('poca_lama', o_s['poca']), ('cruz_madeira', o_s['cruz']), ('lapide_a2', o_s['lapide'])]
    W = 4 + 160 + 4 + 160 + 4
    pos = [(4, 4), (168, 4), (4, 80), (168, 80), (4, 180), (168, 180), (4, 208), (72, 208), (112, 208)]
    sh = Canvas(W, 236, 2)
    for (name, img), (x, y) in zip(items, pos):
        sh.blit(img, x, y)
    return sh


def _hs(frames):
    from base import hstrip
    return hstrip(frames)


def gif(path, frames, durs, scale, bg=3):
    ims = []
    for f in frames:
        c = Canvas(f.w, f.h, bg)
        c.blit(f, 0, 0)
        ims.append(c.to_rgba(scale).convert('RGB'))
    ims[0].save(path, save_all=True, append_images=ims[1:], duration=durs, loop=0, disposal=1)


def all_previews(o_t, o_s, o_b, compose_bg):
    bg = compose_bg(o_b)
    s = mock_scene(o_t, o_s, bg)
    s.to_rgba(1).save(J(PREV, 'run_a2_mock_640x360.png'))
    s.to_rgba(2).save(J(PREV, 'run_a2_mock_2x.png'))
    grey(s.to_rgba(2)).save(J(PREV, 'run_a2_mock_cinza_2x.png'))
    b2 = compose_bg(o_b)
    b2.blit(load('assets/sprites/bg/a1/vinheta.png'), 0, 0)
    b2.to_rgba(2).save(J(PREV, 'run_a2_so_fundo_2x.png'))
    ims = [compose_bg(o_b, k).to_rgba(1).convert('RGB') for k in (0, 1)]
    ims[0].save(J(PREV, 'run_a2_mata_balanco_1x.gif'), save_all=True, append_images=ims[1:], duration=800, loop=0)
    c6 = campo6(o_t, o_s, bg)
    c6.to_rgba(4).save(J(PREV, 'a2_campo6x6_4x.png'))
    c6.to_rgba(1).save(J(PREV, 'a2_campo6x6_1x.png'))
    grey(c6.to_rgba(4)).save(J(PREV, 'a2_campo6x6_cinza_4x.png'))
    at = atlas_sheet(o_t, o_s)
    at.to_rgba(8).save(J(PREV, 'a2_atlas_8x.png'))
    grey(at.to_rgba(4)).save(J(PREV, 'a2_atlas_cinza_4x.png'))
    # pecas do diorama a 4x
    pc = Canvas(300, 64 + 40, 2)
    pc.blit(o_s['bloco'], 4, 2)
    pc.blit(o_s['cerca'], 4, 62)
    pc.blit(o_s['tufos'], 108, 66)
    pc.blit(o_s['placa'], 140, 66)
    pc.to_rgba(4).save(J(PREV, 'a2_pecas_4x.png'))
    # GIFs: regeneracao e abertura da cova
    gif(J(PREV, 'regen_a2_8x.gif'), o_t['regen'] + [o_t['regen'][3]], [83, 83, 82, 82, 600], 8)
    import graves_a2 as G
    frames = []
    for f in range(4):
        pair = Canvas(48, 32)
        for k, key in ((0, 'head'), (1, 'feet')):
            ox, oy = G.ORIENT['NOSE'][key]
            pair.blit(cell(o_t['grave_open'], f, k), ox, oy)
        frames.append(pair)
    gif(J(PREV, 'cova_abrir_a2_6x.gif'), [frames[0]] + frames + [frames[3]], [600, 83, 83, 82, 82, 900], 6)
    print('previas: run_a2_mock_*, a2_campo6x6_*, a2_atlas_8x, a2_pecas_4x, GIFs')
