"""Monta a previa do turno (640x360) com os assets novos e os existentes."""
import random
from PIL import Image
from common import Canvas
import cena

ROOT = r'C:\Users\pedro\Documents\projects\dig-dig-graves'


def load(path):
    im = Image.open(ROOT + '\\' + path)
    assert im.mode == 'P', path
    c = Canvas(*im.size)
    data = list(im.getdata())
    for y in range(im.height):
        c.px[y] = data[y * im.width:(y + 1) * im.width]
    return c


def cell(atlas, col, row, w, h):
    return atlas.crop(col * w, row * h, w, h)


N = 12
O = (320, 78)          # pivo do tile (0, 0) na tela


def tile_pos(i, j):
    return O[0] + (i - j) * 16, O[1] + (i + j) * 8


def scene(cursor=(5, 6), radius=3, with_hud=True, pa_frame=None, extras=True):
    rnd = random.Random(4)
    scr = Canvas(640, 360)
    scr.blit(cena.sky(), 0, 0)
    cl = cena.clouds()
    scr.blit(cl.crop(0, 0, 160, 16), 150, 40)
    scr.blit(cl.crop(0, 32, 160, 16), 20, 66)        # passando na frente da lua
    scr.blit(cl.crop(0, 16, 160, 16), 470, 84)
    scr.blit(cena.far(), 0, cena.FAR_Y)

    tiles = load(r'assets\tiles\a1\tiles_a1.png')
    tiles_lit = load(r'assets\tiles\a1\tiles_a1_lit.png')
    lapide = load(r'assets\sprites\props\lapide.png')
    rocha = load(r'assets\sprites\props\rocha.png')
    vela = load(r'assets\sprites\props\vela.png')
    velas = load(r'assets\sprites\props\velas_grupo.png')
    cris = load(r'assets\sprites\props\crisantemo.png')
    grave = load(r'assets\tiles\a1\grave_a1.png')
    grave_lit = load(r'assets\tiles\a1\grave_a1_lit.png')

    # cerquinha atras (bordas de tras), em trechos
    fen_no = cena.fence('NO')
    fen_ne = cena.fence('NE')
    post = cena.fence_post()
    for j in list(range(1, 5)) + list(range(8, 11)):
        x, y = tile_pos(0, j)
        scr.blit(fen_no, x - 16, y - 24)
    for i in list(range(2, 6)) + list(range(7, 11)):
        x, y = tile_pos(i, 0)
        scr.blit(fen_ne, x - 16, y - 24)

    # campo: estagios
    stage = {}
    for i in range(N):
        for j in range(N):
            stage[(i, j)] = (0, rnd.randrange(3))
    for (i, j) in [(2, 7), (3, 7), (3, 8), (8, 3), (9, 3), (9, 4), (6, 9), (7, 9), (4, 4), (5, 4)]:
        stage[(i, j)] = (1, rnd.randrange(3))
    for (i, j) in [(5, 5), (6, 6), (5, 7)]:
        stage[(i, j)] = (2, rnd.randrange(2))
    for (i, j) in [(6, 5), (5, 6)]:
        stage[(i, j)] = (3, rnd.randrange(2))
    rock = {(9, 7): 0, (2, 2): 1}
    graves = {(3, 10): (0, 0), (4, 10): (1, 0)}   # eixo NO-SE, caixao exposto
    cx, cy = cursor
    order = sorted(stage, key=lambda p: (p[0] + p[1], p[0]))
    for (i, j) in order:
        x, y = tile_pos(i, j)
        d = max(abs(i - cx), abs(j - cy))
        lit = d <= radius - 1 or (d == radius and (i + j) % 2 == 0)
        if (i, j) in rock:
            scr.blit(cell(tiles_lit if lit else tiles, 0, 0, 32, 24), x - 16, y - 16)
            scr.blit(cell(rocha, rock[(i, j)], 0, 32, 24), x - 16, y - 16)
            continue
        if (i, j) in graves:
            col, row = graves[(i, j)]
            scr.blit(cell(grave_lit if lit else grave, col, row, 32, 24), x - 16, y - 16)
            continue
        s, v = stage[(i, j)]
        scr.blit(cell(tiles_lit if lit else tiles, s, v, 32, 24), x - 16, y - 16)
    # props sobre tiles (ordem de profundidade simples)
    props = [((2, 10), lapide, 0, 16, 24, (8, 23)), ((4, 2), lapide, 1, 16, 24, (8, 23)),
             ((8, 8), lapide, 2, 16, 24, (8, 23)),
             ((5, 2), vela, 0, 8, 12, (4, 11)), ((7, 10), velas, 0, 16, 12, (8, 11)),
             ((10, 6), cris, 0, 8, 10, (4, 9)), ((1, 9), cris, 0, 8, 10, (4, 9))]
    for (pos, atlas, col, w, h, piv) in sorted(props, key=lambda p: p[0][0] + p[0][1]):
        x, y = tile_pos(*pos)
        scr.blit(cell(atlas, col, 0, w, h), x - piv[0], y - piv[1])

    # bloco de terra: frente-esquerda (j = N-1) e frente-direita (i = N-1)
    blk, cells = cena.block_atlas()
    for i in range(N):
        x, y = tile_pos(i, N - 1)
        if i == N - 1:
            c = cells[8]
        elif i == 0:
            c = cells[3]
        else:
            c = cells[i % 3]
        scr.blit(c, x - 16, y - 16)
    for j in range(N - 1):
        x, y = tile_pos(N - 1, j)
        c = cells[7] if j == 0 else cells[4 + j % 3]
        scr.blit(c, x - 16, y - 16)

    if extras:
        # decoracao fora da grade: tufos nas quinas, velas e crisantemos no chao
        tf = cena.tufts()
        lx, ly = tile_pos(0, N - 1)
        rx, ry = tile_pos(N - 1, 0)
        bx, by = tile_pos(N - 1, N - 1)
        tx, ty = tile_pos(0, 0)
        for (x, y, k) in [(lx - 24, ly + 18, 0), (lx - 12, ly + 30, 2), (rx + 12, ry + 20, 1),
                          (rx + 22, ry + 8, 0), (bx - 40, by + 34, 1), (bx + 26, by + 30, 2),
                          (tx - 30, ty + 2, 1), (tx + 26, ty + 4, 0)]:
            scr.blit(tf.crop(0, k * 8, 12, 8), x - 6, y - 7)
        scr.blit(cell(velas, 1, 0, 16, 12), lx - 30, ly + 6)
        scr.blit(cris, lx - 16, ly + 14)
        scr.blit(cell(vela, 2, 0, 8, 12), rx + 18, ry + 2)
        scr.blit(cris, rx + 6, ry + 14)
        scr.blit(post, tx - 3 - 1, ty - 7 - 13 + 0)
        sg = cena.sign_with_text()
        scr.blit(sg, lx - 70, ly + 4)

    # nevoa na frente do bloco
    ms = cena.mist_atlas()
    scr.blit(ms.crop(0, 0, 320, 24), 30, 246)
    scr.blit(ms.crop(0, 0, 320, 24), 350, 246)
    scr.blit(ms.crop(0, 24, 320, 24), 170, 276)
    scr.blit(ms.crop(0, 24, 320, 24), -150, 276)
    scr.blit(ms.crop(0, 24, 320, 24), 490, 276)
    return scr


def area_outline(scr, cx, cy, r=1, col=25):
    """perimetro externo da area (2r+1)^2 em degraus iso, com cantoneiras 26."""
    i0, i1, j0, j1 = cx - r, cx + r, cy - r, cy + r
    top = tile_pos(i0, j0)
    top = (top[0], top[1] - 8)
    right = tile_pos(i1, j0)
    right = (right[0] + 16, right[1])
    bot = tile_pos(i1, j1)
    bot = (bot[0], bot[1] + 8)
    left = tile_pos(i0, j1)
    left = (left[0] - 16, left[1])
    def edge(a, b):
        (x0, y0), (x1, y1) = a, b
        n = abs(x1 - x0)
        sx = 1 if x1 > x0 else -1
        sy = 1 if y1 > y0 else -1
        pts = []
        for k in range(n):
            pts.append((x0 + sx * k, y0 + sy * (k // 2)))
        return pts
    pts = edge(top, right) + edge(right, bot) + edge(bot, left) + edge(left, top)
    for (x, y) in pts:
        scr.set(x, y, col)
    for v in (top, right, bot, left):
        for (x, y) in pts:
            if abs(x - v[0]) <= 3 and abs(y - v[1]) <= 2:
                scr.set(x, y, 26)


def nine(dst, src, x, y, w, h, l, r, t, b):
    """9-slice com repeticao (tile) do miolo e das bordas."""
    sw, sh = src.w, src.h
    for yy in range(h):
        if yy < t:
            sy = yy
        elif yy >= h - b:
            sy = sh - (h - yy)
        else:
            sy = t + (yy - t) % (sh - t - b)
        for xx in range(w):
            if xx < l:
                sx = xx
            elif xx >= w - r:
                sx = sw - (w - xx)
            else:
                sx = l + (xx - l) % (sw - l - r)
            v = src.px[sy][sx]
            if v:
                dst.set(x + xx, y + yy, v)


def bar(dst, x, y, w, frac, fill_path):
    mold = load(r'assets\ui\hud\barra_moldura.png')
    fill = load(fill_path)
    nine(dst, mold, x, y, w, 10, 3, 3, 3, 3)
    fw = int((w - 6) * frac)
    for xx in range(fw):
        for yy in range(4):
            dst.set(x + 3 + xx, y + 3 + yy, fill.px[yy][xx % fill.w])
    if fw > 0:
        dst.set(x + 3 + fw - 1, y + 3, 23)      # 1 px de brilho na ponta


def text(dst, x, y, s, col=22, outline=None):
    import font5x7 as F
    return F.draw(dst, x, y, s, col, outline)


def hud(scr, oil=0.62, low=False, lantern_frame=0):
    import kit
    icons = load(r'assets\ui\icons\icons_res.png')
    pl = kit.plaque()
    PL = (8, 8, 12, 11)          # margens da plaqueta (esq, dir, topo, base)
    # recursos (topo esquerdo)
    nine(scr, pl, 6, 6, 170, 24, *PL)
    x = 12
    for k, s in ((0, '1.234'), (1, '56'), (2, '3')):
        scr.blit(icons.crop(k * 16, 0, 16, 16), x, 9)
        x += 18
        x += text(scr, x, 13, s, 22) + 10
    # nivel (topo centro): plaqueta + medalha por cima da ponta esquerda
    nine(scr, pl, 244, 6, 170, 24, *PL)
    bar(scr, 266, 13, 118, 0.7, r'assets\ui\hud\barra_xp.png')
    text(scr, 389, 14, 'XP', 22)
    md = kit.medal()
    scr.blit(md, 232, 6)
    text(scr, 241, 14, '4', 22, outline=1)
    # inquietacao (topo direito)
    nine(scr, pl, 494, 6, 140, 24, *PL)
    scr.blit(kit.skull(), 500, 9)
    bar(scr, 518, 13, 108, 0.45, r'assets\ui\hud\barra_inquietacao.png')
    # lanterna (base centro)
    nine(scr, pl, 174, 330, 290, 24, *PL)
    scr.blit(kit.lantern(lantern_frame, low), 178, 328)
    bar(scr, 204, 337, 222, oil, r'assets\ui\hud\barra_oleo_alerta.png' if low else r'assets\ui\hud\barra_oleo.png')
    text(scr, 432, 338, '12S', 32 if low else 22)
    # pisao (base direita)
    nine(scr, pl, 514, 330, 120, 24, *PL)
    w = text(scr, 524, 338, 'PISÃO', 22)
    for k in range(3):
        px = 524 + w + 8 + k * 9
        for yy in range(7):
            for xx in range(7):
                edge = xx in (0, 6) or yy in (0, 6)
                v = 1 if edge else (26 if k < 2 else 3)
                if not edge and k < 2 and (xx == 1 or yy == 1):
                    v = 23 if (xx == 1 and yy == 1) else 26
                scr.set(px + xx, 338 + yy, v)
