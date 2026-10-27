import os
import math
import random
from PIL import Image
from common import Canvas
import icons as IC
import font5x7 as F
import tree as T1
from tree2 import *

os.makedirs(OUT, exist_ok=True)
J = os.path.join
LUA = []   # specs para gerar as fontes .aseprite


def save_anim(name, frames, cw, ch, cols, durs, tags, prefix=None):
    sh = sheet(frames, cw, ch, cols)
    sh.save(J(OUT, name + '.png'))
    fr = grid_frames(prefix or name, cw, ch, cols, len(frames), durs)
    write_json(J(OUT, name + '.json'), name + '.png', sh.w, sh.h, fr, tags)
    LUA.append((name, cw, ch, cols, len(frames), [d for *_, d in fr], tags))
    return sh


icons = IC.build_all()

# ---------------- medalhoes 32
atlas, row0, row1 = build_medallions32()
atlas.save(J(OUT, 'medallions32.png'))
LUA.append(('medallions32', 32, 32, 9, 18, [100] * 18, []))
pp = pips()
pp.save(J(OUT, 'pips.png'))

# ---------------- camadas da superficie
sk = sky()
sk.save(J(OUT, 'tree_sky.png'))
st = stars_sheet()
st.save(J(OUT, 'tree_stars.png'))
write_json(J(OUT, 'tree_stars.json'), 'tree_stars.png', 10, 10,
           [('estrela_pequena 0', 0, 0, 5, 5, 500), ('estrela_pequena 1', 5, 0, 5, 5, 500),
            ('estrela_cruz 0', 0, 5, 5, 5, 500), ('estrela_cruz 1', 5, 5, 5, 5, 500)],
           [('pequena', 0, 1, 'forward'), ('cruz', 2, 3, 'forward')])
LUA.append(('tree_stars', 5, 5, 2, 4, [500] * 4, [('pequena', 0, 1, 'forward'), ('cruz', 2, 3, 'forward')]))
cf = canopy_frames()
save_anim('tree_canopy', cf, CANOPY_W, CANOPY_H, 3, [400], [('idle', 0, 2, 'pingpong')])
tr = trunk()
tr.save(J(OUT, 'tree_trunk.png'))
gr = grass()
gr.save(J(OUT, 'tree_grass.png'))
so = soil()
so.save(J(OUT, 'tree_soil.png'))

# ---------------- particulas e bichinhos
pet = petals()
pet.save(J(OUT, 'fx_petals.png'))
pf = []
for i in range(4):
    pf += [('petala_%d 0' % i, 0, i * 3, 3, 3, 200), ('petala_%d 1' % i, 3, i * 3, 3, 3, 200)]
ptags = [('petala_%d' % i, 2 * i, 2 * i + 1, 'forward') for i in range(4)]
write_json(J(OUT, 'fx_petals.json'), 'fx_petals.png', 6, 12, pf, ptags)
LUA.append(('fx_petals', 3, 3, 2, 8, [200] * 8, ptags))
ff = firefly()
save_anim('fx_firefly', [ff.crop(i * 3, 0, 3, 3) for i in range(3)], 3, 3, 3, [400, 150, 250], [('idle', 0, 2, 'forward')])
sd = soil_dust()
sd.save(J(OUT, 'fx_soil_dust.png'))
wm = worm()
save_anim('fx_worm', [wm.crop(i * 12, 0, 12, 5) for i in range(4)], 12, 5, 4, [180], [('idle', 0, 3, 'forward')])
bt = beetle()
save_anim('fx_beetle', [bt.crop(i * 6, 0, 6, 5) for i in range(2)], 6, 5, 2, [150], [('idle', 0, 1, 'forward')])
sp = sap()
save_anim('fx_sap', [sp.crop(i * 8, 0, 8, 2) for i in range(3)], 8, 2, 3, [100], [('idle', 0, 2, 'forward')])

# ---------------- efeitos de compra
bu = burst()
save_anim('fx_buy_burst', bu, 32, 32, 6, [50], [('act', 0, 5, 'forward')])
sr = sprout()
save_anim('fx_sprout', sr, 24, 12, 4, [80], [('open', 0, 3, 'forward')])
bg_ = bang()
save_anim('fx_new_badge', bg_, 8, 10, 2, [300], [('idle', 0, 1, 'forward')])

# ======================================================================= mock
CAM = 28


def mock():
    rnd = random.Random(21)
    cv = Canvas(640, 360, 2)
    cv.blit(sk, 0, -CAM // 2)
    # estrelas cintilando (algumas no frame 1)
    for x, y, k in ((210, 20, 1), (470, 12, 0), (560, 30, 1), (30, 8, 0), (150, 4, 0)):
        cell = st.crop(5 * k, 5 * (x % 2), 5, 5)
        cv.blit(cell, x - 2, y - 2)
    cv.blit(so, 0, -CAM)
    cv.blit(tr, TRUNK_X, TRUNK_Y - CAM)
    cv.blit(gr, 0, SURF - 8 - CAM)
    cv.blit(cf[1], CANOPY_X, CANOPY_Y - CAM)
    # petalas caindo (zigue-zague) e pousadas
    for i in range(16):
        x = round(rnd.gauss(320, 120))
        y = rnd.randrange(30, 54)
        k = rnd.randrange(4)
        cv.blit(pet.crop(3 * (i % 2), 3 * k, 3, 3), x, y)
    # vaga-lumes na grama
    for i, (x, y) in enumerate(((120, 46), (176, 40), (452, 44), (520, 38), (588, 47), (70, 41))):
        cv.blit(ff.crop(3 * (i % 3), 0, 3, 3), x - 1, y - 1)
    # poeira do subsolo
    for _ in range(40):
        x, y = rnd.randrange(0, 640), rnd.randrange(70, 300)
        base = cv.get(x, y)
        cv.set(x, y, 16 if base == 14 else (14 if base in (13, 1) else base))
    # bichinhos
    cv.blit(wm.crop(12, 0, 12, 5), 556, 160)
    cv.blit(bt.crop(0, 0, 6, 5), 40, 236)

    nodes = {
        'N00': ((320, 140), 'max', 0),
        'E01': ((232, 196), 'part', 0, 3, 10),
        'N02': ((320, 196), 'max', 0),
        'L01': ((408, 196), 'part', 1, 4, 10),
        'E02': ((144, 252), 'buy', 0, 25),
        'C01': ((232, 260), 'poor', 3, 60),
        'N01': ((320, 252), 'buy', 0, 50),
        'F01': ((408, 260), 'poor', 2, 80),
        'L02': ((496, 252), 'buy', 1, 30, True),
        'H1': ((64, 222), 'hidden', None),
        'H2': ((576, 222), 'hidden', None),
    }
    edges = [('N00', 'E01', 'on', .1), ('N00', 'L01', 'on', -.1), ('N00', 'N02', 'on', 0),
             ('E01', 'E02', 'off', .1), ('E01', 'C01', 'off', -.05), ('N02', 'N01', 'off', 0),
             ('L01', 'F01', 'off', .05), ('L01', 'L02', 'off', -.1), ('E02', 'H1', 'off', .12), ('L02', 'H2', 'off', -.12)]
    # halo ambar (xadrez 24) em volta dos nos comprados
    for nid, info in nodes.items():
        if info[1] in ('max', 'part'):
            (nx, ny) = info[0]
            for y in range(ny - 24, ny + 25):
                for x in range(nx - 24, nx + 25):
                    d = math.hypot(x - nx, y - ny)
                    if 17 < d < 23 and (x + y) % 2 == 0 and (x // 2 + y // 2) % 2 == 0 and cv.get(x, y) in (13, 14):
                        cv.set(x, y, 24)
    T1.draw_root(cv, [(319, SURF + 36 - CAM), (319, 128)], 'on')
    for a, b, stt, bend in edges:
        T1.draw_root(cv, T1.curve(nodes[a][0], nodes[b][0], bend, 8), stt)
    # seiva nas raizes compradas
    for a, b, t in (('N00', 'E01', .45), ('N00', 'L01', .6), ('N00', 'N02', .5)):
        pts = T1.curve(nodes[a][0], nodes[b][0], .1 if b == 'E01' else (-.1 if b == 'L01' else 0), 20)
        x, y = pts[int(t * 20)]
        cv.blit(sp.crop(0, 0, 8, 2), round(x) - 6, round(y))
    for nid, info in nodes.items():
        (x, y), stt = info[0], info[1]
        x0, y0 = x - 16, y - 16
        if stt == 'hidden':
            cv.blit(row0[7], x0, y0)
            continue
        if stt == 'max':
            cv.blit(row0[8], x0, y0)
        elif stt == 'buy':
            cv.blit(row1[info[2]], x0, y0)
        else:
            cv.blit(row0[info[2]], x0, y0)
        cv.blit(icons[nid], x0 + 8, y0 + 8)
        if stt == 'part':
            lv, mx = info[3], info[4]
            w = mx * 3 + 1
            bx = x - w // 2
            for i in range(mx):
                k = 0 if i >= lv else (2 if i == lv - 1 else 1)
                cv.blit(pp.crop(4 * k, 0, 4, 4), bx + 3 * i, y + 17)
        if stt in ('buy', 'poor'):
            txt = str(info[3])
            w = F.width(txt)
            F.draw(cv, x - w // 2, y + 18, txt, 22 if stt == 'buy' else 32, outline=1)
        if len(info) > 5 and info[5]:
            cv.blit(bg_[0], x + 10, y - 22)
    # broto (frame 2) sob o no recem-revelado L02 nao; mostra explosao de compra no N01
    cv.blit(bu[2], nodes['N01'][0][0] - 16, nodes['N01'][0][1] - 16)
    # painel inferior
    parch = Image.open(ROOT + r'\assets\ui\panels\panel_parchment.png')
    wood = Image.open(ROOT + r'\assets\ui\panels\panel_wood.png')
    px, py, pw, ph = 8, 304, 624, 50
    T1.nine_slice(cv, parch, px, py, pw, ph)
    cv.blit(row1[0], px + 8, py + 9)
    cv.blit(icons['E02'], px + 16, py + 17)
    F.draw(cv, px + 48, py + 10, 'BRAÇO FIRME', 1)
    F.draw(cv, px + 48 + F.width('BRAÇO FIRME') + 10, py + 10, 'NV 0/8', 14)
    F.draw(cv, px + 48, py + 21, '-6% NO INTERVALO DO GOLPE', 14)
    F.draw(cv, px + 48, py + 32, 'INTERVALO: 1,00S ~', 1)
    F.draw(cv, px + 48 + F.width('INTERVALO: 1,00S ~') + 6, py + 32, '0,94S', 24)
    res = Image.open(ROOT + r'\assets\ui\icons\icons_res.png')
    coin = Canvas(16, 16)
    bone = Canvas(16, 16)
    for yy in range(16):
        for xx in range(16):
            coin.px[yy][xx] = res.getpixel((xx, yy))
            bone.px[yy][xx] = res.getpixel((16 + xx, yy))
    cw = F.width('CUSTO 25')
    F.draw(cv, px + pw - 30 - cw, py + 21, 'CUSTO 25', 1)
    cv.blit(coin, px + pw - 26, py + 17)
    # botao Cavar e plaqueta de recursos
    T1.nine_slice(cv, wood, 548, 6, 86, 24)
    tw = F.width('CAVAR >')
    F.draw(cv, 548 + (86 - tw) // 2, 15, 'CAVAR >', 22, outline=1)
    T1.nine_slice(cv, wood, 6, 6, 104, 24)
    cv.blit(coin, 10, 10)
    F.draw(cv, 28, 15, '1.234', 22, outline=1)
    cv.blit(bone, 66, 10)
    F.draw(cv, 84, 15, '56', 22, outline=1)
    return cv


m = mock()
m.to_rgba(1).save(J(PREV, 'tree2_mock_640x360.png'))
m.to_rgba(2).save(J(PREV, 'tree2_mock_2x.png'))
m.to_rgba(2).convert('L').save(J(PREV, 'tree2_mock_cinza_2x.png'))

# ======================================================================= GIFs
canopy_crop = [f.crop(108, 0, 200, 90) for f in cf]
gif([canopy_crop[0], canopy_crop[1], canopy_crop[2], canopy_crop[1]], [400] * 4, J(PREV, 'tree2_copa_4x.gif'), 4, 2)
pet_frames = []
for f in range(2):
    c = Canvas(4 * 5, 5)
    for i in range(4):
        c.blit(pet.crop(3 * f, 3 * i, 3, 3), 1 + i * 5, 1)
    pet_frames.append(c)
gif(pet_frames, [200, 200], J(PREV, 'tree2_petalas_4x.gif'), 8, 2)
gif([ff.crop(3 * i, 0, 3, 3) for i in range(3)], [400, 150, 250], J(PREV, 'tree2_vagalume_4x.gif'), 8, 10, 3)
gif([wm.crop(12 * i, 0, 12, 5) for i in range(4)], [180] * 4, J(PREV, 'tree2_minhoca_4x.gif'), 6, 14, 3)
gif([bt.crop(6 * i, 0, 6, 5) for i in range(2)], [150] * 2, J(PREV, 'tree2_besouro_4x.gif'), 6, 13, 3)
gif([sp.crop(8 * i, 0, 8, 2) for i in range(3)], [100] * 3, J(PREV, 'tree2_seiva_4x.gif'), 8, 14, 3)
gif(bu + [Canvas(32, 32)], [50] * 6 + [400], J(PREV, 'tree2_compra_4x.gif'), 4, 14, 2)
gif(sr + [sr[3]], [80] * 4 + [500], J(PREV, 'tree2_broto_4x.gif'), 4, 14, 2)
gif(bg_, [300, 300], J(PREV, 'tree2_novidade_4x.gif'), 6, 13, 2)
# medalhao respirando (normal <-> halo) e maximo cintilando
breath = []
for i in range(7):
    pass
c0 = Canvas(7 * 36, 36, 14)
c1 = Canvas(7 * 36, 36, 14)
for i in range(7):
    c0.blit(row0[i], 2 + i * 36, 2)
    c1.blit(row1[i], 2 + i * 36, 2)
gif([c0, c1], [600, 600], J(PREV, 'tree2_medalhoes_respirar_4x.gif'), 4, 14, 0)
mx = [row0[8], row1[7], row1[8]]
gif(mx, [1200, 100, 150], J(PREV, 'tree2_maximo_4x.gif'), 6, 14, 2)
# folha estatica das pecas a 4x
pc = Canvas(9 * 34 + 2, 2 * 34 + 2 + 14, 14)
for i in range(9):
    pc.blit(row0[i], 2 + i * 34, 2)
    pc.blit(row1[i], 2 + i * 34, 36)
    if i < 7:
        pc.blit(icons[['E01', 'L02', 'F03', 'C02', 'A01', 'S01', 'N01'][i]], 10 + i * 34, 10)
pc.blit(pp, 4, 72)
pc.to_rgba(4).save(J(PREV, 'tree2_medalhoes32_4x.png'))

# ======================================================== spec para o Lua
with open('lua_specs.txt', 'w') as f:
    for name, cw, ch, cols, n, durs, tags in LUA:
        f.write('%s|%d|%d|%d|%d|%s|%s\n' % (name, cw, ch, cols, n, ','.join(map(str, durs)),
                                            ';'.join('%s:%d:%d:%s' % t for t in tags)))
print('ok')
