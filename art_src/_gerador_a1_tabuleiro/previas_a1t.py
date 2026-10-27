"""Previas do ART-A1 em art_src/_previews/ (nunca em assets/)."""
from base1 import Canvas, J, ROOT, load, cell, lit, hstrip

PREV = J(ROOT, 'art_src', '_previews')
N = 6


def grey(im):
    return im.convert('L').convert('RGB')


def tile_pos(O, i, j):
    return O[0] + (i - j) * 16, O[1] + (i + j) * 8


def gif(path, frames, durs, scale, bg=3):
    ims = []
    for f in frames:
        c = Canvas(f.w, f.h, bg)
        c.blit(f, 0, 0)
        ims.append(c.to_rgba(scale).convert('RGB'))
    ims[0].save(path, save_all=True, append_images=ims[1:], duration=durs, loop=0, disposal=1)


# campo 6x6: camada por tile (coluna do atlas, variante); covas pelo grave_a1
STAGE = {(0, 0): (0, 0), (1, 0): (1, 1), (2, 0): (2, 0), (3, 0): (5, 0), (4, 0): (5, 1), (5, 0): (0, 1),
         (0, 1): (1, 0), (1, 1): (5, 2), (2, 1): (5, 0), (3, 1): (3, 0), (4, 1): (5, 2), (5, 1): (1, 2),
         (0, 2): (0, 2), (1, 2): (2, 1), (2, 2): (3, 1), (3, 2): (5, 1), (4, 2): (2, 0), (5, 2): (0, 0),
         (0, 3): (0, 0), (2, 3): (5, 0), (3, 3): (1, 0), (5, 3): (0, 2),
         (0, 4): (1, 1), (1, 4): (0, 1), (2, 4): (0, 0), (5, 4): (5, 1),
         (0, 5): (0, 1), (1, 5): (5, 2), (2, 5): (0, 2), (5, 5): (0, 0)}
# cova NO-SE (cabeca c, pes c+(1,0), lapide c+(-1,0)) e NE-SO (cabeca c, pes c+(0,1), lapide c+(0,-1))
GRAVES = {(4, 1): (0, 0), (5, 1): (1, 0), (1, 4): (2, 1), (1, 5): (3, 1), (4, 4): (2, 2), (4, 5): (3, 2)}
TOMBS = {(3, 1): 0, (1, 3): 2, (4, 3): 1}        # tile da lapide (sempre atras da cova) -> tipo
CANDLE = (2, 2)
COIN = (3, 5)


def campo(t, p, frame=0, lit_all=False):
    O = (N * 16 + 8, 34)
    c = Canvas(N * 32 + 16, N * 16 + 70, 2)
    tiles = t['tiles_lit'] if lit_all else t['tiles']
    grave = load('assets/tiles/a1/grave_a1.png')
    bloco = load('assets/sprites/bg/a1/bloco_a1.png')
    order = sorted(((i, j) for i in range(N) for j in range(N)), key=lambda q: (q[0] + q[1], q[0]))
    for (i, j) in order:
        x, y = tile_pos(O, i, j)
        if (i, j) in GRAVES:
            col, row = GRAVES[(i, j)]
            c.blit(cell(grave, col, row), x - 16, y - 16)
        elif (i, j) in TOMBS:
            c.blit(cell(tiles, 0, (i + j) % 3), x - 16, y - 16)
        elif (i, j) == CANDLE:
            v = p['vela'][frame]
            c.blit(lit(v) if lit_all else v, x - 16, y - 16)
        else:
            col, v = STAGE.get((i, j), (0, 0))
            c.blit(cell(tiles, col, v), x - 16, y - 16)
    # halo da vela por cima do chao, antes dos props altos
    x, y = tile_pos(O, *CANDLE)
    c.blit(p['halo'], x - 32, y - 16)
    v = p['vela'][frame]
    c.blit(lit(v) if lit_all else v, x - 16, y - 16)
    for (i, j) in order:
        x, y = tile_pos(O, i, j)
        if (i, j) in TOMBS:
            c.blit(p['lapides'][TOMBS[(i, j)]], x - 8, y - 23)
        if (i, j) == COIN:
            c.blit(p['coin'][frame % 4], x - 4, y - 10)
    for i in range(N):
        x, y = tile_pos(O, i, N - 1)
        col = 8 if i == N - 1 else (3 if i == 0 else i % 3)
        c.blit(bloco.crop(col * 32, 0, 32, 56), x - 16, y - 16)
    for j in range(N - 1):
        x, y = tile_pos(O, N - 1, j)
        col = 7 if j == 0 else 4 + j % 3
        c.blit(bloco.crop(col * 32, 0, 32, 56), x - 16, y - 16)
    return c


def profundidade(t):
    """as 5 profundidades lado a lado na ordem de escavacao: S0, S1, S2 (Barro), Ossada, S3."""
    a = t['tiles']
    cs = [cell(a, 0, 0), cell(a, 1, 0), cell(a, 2, 0), cell(a, 5, 0), cell(a, 3, 0)]
    s = Canvas(5 * 34 + 2, 26, 2)
    for k, cc in enumerate(cs):
        s.blit(cc, 2 + k * 34, 1)
    return s


def lapides_sheet(p):
    """3 lapides em pe sobre tiles de grama + icones 8x8 embaixo."""
    a = load('assets/tiles/a1/tiles_a1.png')
    s = Canvas(3 * 34 + 4, 52, 2)
    for k in range(3):
        x = 2 + k * 34
        s.blit(cell(a, 0, k), x, 14)
        s.blit(p['lapides'][k], x + 16 - 8, 14 + 16 - 23)
        s.blit(LP_icons()[k], x + 12, 42)
    return s


def LP_icons():
    import lapides
    return lapides.icons()


def all_previews(t, p):
    c = campo(t, p)
    c.to_rgba(4).save(J(PREV, 'a1_ossada_campo6x6_4x.png'))
    c.to_rgba(1).save(J(PREV, 'a1_ossada_campo6x6_1x.png'))
    grey(c.to_rgba(4)).save(J(PREV, 'a1_ossada_campo6x6_cinza_4x.png'))
    grey(campo(t, p, lit_all=True).to_rgba(4)).save(J(PREV, 'a1_ossada_campo6x6_lit_cinza_4x.png'))
    campo(t, p, lit_all=True).to_rgba(4).save(J(PREV, 'a1_ossada_campo6x6_lit_4x.png'))
    gif(J(PREV, 'a1_tabuleiro_campo6x6_3x.gif'), [campo(t, p, f) for f in range(3)], [125, 125, 125], 3, bg=2)
    pr = profundidade(t)
    pr.to_rgba(6).save(J(PREV, 'a1_ossada_profundidade_6x.png'))
    grey(pr.to_rgba(6)).save(J(PREV, 'a1_ossada_profundidade_cinza_6x.png'))
    ls = lapides_sheet(p)
    ls.to_rgba(4).save(J(PREV, 'lapide_tipos_4x.png'))
    grey(ls.to_rgba(4)).save(J(PREV, 'lapide_tipos_cinza_4x.png'))
    sh = Canvas(3 * 18 + 2, 26, 22)
    for k, lp in enumerate(p['lapides']):
        for y in range(24):
            for x in range(16):
                if lp.px[y][x] and lp.px[y][x] != 2:
                    sh.set(2 + k * 18 + x, 1 + y, 1)
    sh.to_rgba(4).save(J(PREV, 'lapide_silhueta_4x.png'))
    gif(J(PREV, 'vela_campo_8x.gif'), p['vela'], [125] * 3, 8)
    gif(J(PREV, 'moeda_ouro_8x.gif'), p['coin'][:4] * 3 + p['coin'][4:] + [Canvas(8, 8)],
        [100] * 12 + [83, 83, 83, 400], 8)
    gif(J(PREV, 'icon_key_1_8x.gif'), p['key16'], [125] * 4, 8)
    gif(J(PREV, 'icon_key_1_32_4x.gif'), p['key32'], [125] * 4, 4)
    # folha com tudo a 1x/4x
    sheet = Canvas(200 + 40, 140, 2)
    sheet.blit(t['tiles'], 4, 4)
    sheet.blit(t['cracks'], 200, 4)
    sheet.blit(p['lapide'], 4, 80)
    sheet.blit(p['icons'], 56, 96)
    sheet.blit(hstrip(p['vela']), 84, 80)
    sheet.blit(hstrip(p['coin']), 4, 108)
    sheet.blit(hstrip(p['key16']), 64, 108)
    sheet.blit(p['halo'], 180, 76)
    sheet.to_rgba(4).save(J(PREV, 'a1_tabuleiro_atlas_4x.png'))
    print('previas: a1_ossada_campo6x6_*, a1_ossada_profundidade_*, lapide_tipos_*, lapide_silhueta_4x, '
          'vela_campo_8x.gif, moeda_ouro_8x.gif, icon_key_1_*.gif, a1_tabuleiro_atlas_4x')
