"""Tela-titulo: cenario em camadas, logo e pecas de UI (docs/03_UI_UX.md §9.6).

Uso:  python -B build.py            gera PNG/JSON em assets/, previas em art_src/_previews/
      python -B build.py --ase      tambem monta os .aseprite fonte (precisa do Aseprite:
                                    variavel ASEPRITE ou 'aseprite' no PATH)
Todos os PNG sao indexados (0 = transparente, 1-32 = Lua de Cova 32). Os caminhos saem da
posicao deste arquivo (art_src/_gerador_titulo/), entao roda igual no Windows e no Linux.
Rode com -B (ou PYTHONDONTWRITEBYTECODE=1) para nao criar __pycache__."""
import json
import os
import random
import shutil
import subprocess
import sys
import tempfile
from PIL import Image

sys.dont_write_bytecode = True
from common import Canvas, PAL
import cenario as C
import logo as LG
import ui as U
import font5x7 as F

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
J = os.path.join
BG = J(ROOT, 'assets', 'sprites', 'bg', 'title')
UI = J(ROOT, 'assets', 'ui', 'title')
PREV = J(ROOT, 'art_src', '_previews')
CHARS = J(ROOT, 'assets', 'sprites', 'chars', 'title')
WRITTEN = []          # PNG gravados (para o check de paleta)
SPECS = []            # .aseprite a montar: (arquivo, frames, duracoes, tags)


def save_png(c, path):
    c.save(path)
    WRITTEN.append(path)


def write_json(path, image_name, sheet_w, sheet_h, frames, tags):
    """Aseprite Array. frames: lista de (nome, x, y, w, h, dur); tags: (nome, de, ate, direcao)."""
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


def hstrip(frames):
    w, h = frames[0].w, frames[0].h
    s = Canvas(w * len(frames), h)
    for i, f in enumerate(frames):
        s.blit(f, i * w, 0)
    return s


def load(path):
    im = Image.open(path)
    assert im.mode == 'P', path
    c = Canvas(*im.size)
    data = list(im.get_flattened_data() if hasattr(im, 'get_flattened_data') else im.getdata())
    for y in range(im.size[1]):
        c.px[y] = data[y * im.size[0]:(y + 1) * im.size[0]]
    return c


def bbox(c):
    xs = [x for y in range(c.h) for x in range(c.w) if c.px[y][x]]
    ys = [y for y in range(c.h) for x in range(c.w) if c.px[y][x]]
    return (min(xs), min(ys), max(xs), max(ys))


LUMA = [round(0.299 * r + 0.587 * g + 0.114 * b) for (r, g, b) in PAL]


# ===================================================================== geracao
def build():
    for d in (BG, UI, PREV):
        os.makedirs(d, exist_ok=True)
    out = {}
    # ---------------- cenario
    sky = C.sky()
    save_png(sky, J(BG, 'title_sky.png'))
    SPECS.append(('bg', 'bg_title_sky', [sky], [100], []))
    vil_full = C.village()
    vb = bbox(vil_full)
    assert vb[1] >= C.VILLAGE_Y, ('vila corta no topo', vb)
    vil = C.layer_crop(vil_full, C.VILLAGE_Y)
    save_png(vil, J(BG, 'title_village.png'))
    SPECS.append(('bg', 'bg_title_village', [vil], [100], []))
    win = C.windows_sheet()
    save_png(win, J(BG, 'title_windows.png'))
    write_json(J(BG, 'title_windows.json'), 'title_windows.png', 4, 3,
               [('title_windows 0', 0, 0, 2, 3, 100), ('title_windows 1', 2, 0, 2, 3, 100)], [])
    SPECS.append(('bg', 'bg_title_windows', [win.crop(0, 0, 2, 3), win.crop(2, 0, 2, 3)], [100, 100], []))
    wall_full = C.wall()
    assert bbox(wall_full)[1] >= C.WALL_Y
    wall = C.layer_crop(wall_full, C.WALL_Y)
    save_png(wall, J(BG, 'title_wall.png'))
    SPECS.append(('bg', 'bg_title_wall', [wall], [100], []))
    fg_full = C.fg()
    assert bbox(fg_full)[1] >= C.FG_Y
    fg = C.layer_crop(fg_full, C.FG_Y)
    save_png(fg, J(BG, 'title_fg.png'))
    SPECS.append(('bg', 'bg_title_fg', [fg], [100], []))
    can = C.canopy_frames()
    sheet = hstrip(can)
    save_png(sheet, J(BG, 'title_fg_canopy.png'))
    write_json(J(BG, 'title_fg_canopy.json'), 'title_fg_canopy.png', sheet.w, sheet.h,
               [('title_fg_canopy %d' % i, i * C.CANOPY_W, 0, C.CANOPY_W, C.CANOPY_H, 400) for i in range(3)],
               [('idle', 0, 2, 'pingpong')])
    SPECS.append(('bg', 'bg_title_fg_canopy', can, [400] * 3, [('idle', 0, 2)]))
    out.update(sky=sky, vil=vil_full, win=win, wall=wall_full, fg=fg_full, can=can)

    # ---------------- logo
    cells, infos = LG.build_letters()
    cols = 6
    atlas = Canvas(LG.CELL_W * cols, LG.CELL_H * 2)
    frames = []
    for i, c in enumerate(cells):
        x, y = (i % cols) * LG.CELL_W, (i // cols) * LG.CELL_H
        atlas.blit(c, x, y)
        frames.append(('letra_%02d_%s' % (i, infos[i]['ch']), x, y, LG.CELL_W, LG.CELL_H, 100))
    save_png(atlas, J(UI, 'title_logo.png'))
    write_json(J(UI, 'title_logo.json'), 'title_logo.png', atlas.w, atlas.h, frames, [])
    SPECS.append(('ui', 'ui_title_logo', cells, [100] * 12, []))
    sh, piv = LG.shovel()
    save_png(sh, J(UI, 'title_logo_shovel.png'))
    SPECS.append(('ui', 'ui_title_logo_shovel', [sh], [100], []))
    g = infos[LG.SHOVEL_LETTER]
    ex = g['pos'][0] + LG.GX + LG.SHOVEL_ENTRY_X
    ey = g['pos'][1] + g['dirt_top'][LG.GX + LG.SHOVEL_ENTRY_X]
    shovel_pos = (ex - piv[0], ey - piv[1])
    dr = LG.drip_frames()
    ds = hstrip(dr)
    save_png(ds, J(UI, 'title_logo_drip.png'))
    write_json(J(UI, 'title_logo_drip.json'), 'title_logo_drip.png', ds.w, ds.h,
               [('title_logo_drip %d' % i, i * LG.DRIP_W, 0, LG.DRIP_W, LG.DRIP_H, d)
                for i, d in enumerate((100, 83, 83, 84))], [('act', 0, 3, 'forward')])
    SPECS.append(('fx', 'fx_title_logo_drip', dr, [100, 83, 83, 84], [('act', 0, 3)]))
    out.update(cells=cells, infos=infos, shovel=sh, shovel_pivot=piv, shovel_pos=shovel_pos,
               shovel_entry=(ex, ey), drip=dr)

    # ---------------- UI
    ps = U.panel_stone()
    save_png(ps, J(UI, 'panel_stone.png'))
    SPECS.append(('ui', 'ui_panel_stone', [ps], [100], []))
    bp = U.btn_perigo_sheet()
    save_png(bp, J(UI, 'btn_perigo.png'))
    SPECS.append(('ui', 'ui_btn_perigo', [bp.crop(i * 48, 0, 48, 24) for i in range(4)], [100] * 4, []))
    se = U.scroll_ends_sheet()
    save_png(se, J(UI, 'scroll_ends.png'))
    SPECS.append(('ui', 'ui_scroll_ends', [se], [100], []))
    out.update(panel=ps, btn=bp, scroll=se)
    return out


# ===================================================================== verificacoes
def check_palette():
    want = [v for rgb in PAL for v in rgb]
    for f in WRITTEN:
        im = Image.open(f)
        assert im.mode == 'P', f
        mx = max(im.get_flattened_data() if hasattr(im, 'get_flattened_data') else im.getdata())
        assert mx <= 32, (f, mx)
        assert im.getpalette()[3:3 + 96] == want, f
        assert im.info.get('transparency') == 0, f
    print('paleta OK em', len(WRITTEN), 'PNG (modo P, indices 0-32, Lua de Cova 32)')


def checks(o):
    bad = []
    for name in ('vil', 'wall', 'fg'):
        fl = C.floaters(o[name])
        bad += [(name, p) for p in fl]
    for i, c in enumerate(o['can']):
        bad += [('copa%d' % i, p) for p in C.floaters(c)]
    for i, c in enumerate(o['cells']):
        bad += [('letra%d' % i, p) for p in C.floaters(c)]
    for nm in ('shovel', 'panel', 'btn', 'scroll'):
        bad += [(nm, p) for p in C.floaters(o[nm])]
    for i, c in enumerate(o['drip']):
        bad += [('gota%d' % i, p) for p in C.floaters(c)]
    assert not bad, ('pixels soltos', bad[:20])
    print('sem pixels soltos (8-vizinhanca) nas camadas, letras, pa, gota e UI')
    # btn_perigo: mesma geometria do btn_grande (contorno 01 e transparencia nos mesmos pixels)
    ref = load(J(ROOT, 'assets', 'ui', 'kit', 'btn_grande.png'))
    b = o['btn']
    for y in range(24):
        for x in range(192):
            a, r = b.px[y][x], ref.px[y][x]
            assert (a == 0) == (r == 0) and (a == 1) == (r == 1), ('btn_perigo difere', x, y)
    print('btn_perigo: mesma silhueta/contorno do btn_grande nos 4 estados')
    # topo plano do monte na linha do pivo do Coveiro
    fg = o['fg']
    cx, cy = C.COVEIRO
    for x in range(cx - 16, cx + 17):
        assert fg.get(x, cy + 1) in (13, 14, 15, 16), ('monte sem terra', x)
        for y in range(cy - 31, cy + 1):
            assert fg.get(x, y) == 0, ('algo acima do topo plano', x, y)
    print('monte: topo plano em y = %d de x = %d a %d' % (cy + 1, cx - 16, cx + 16))
    # Tiao: linha do pivo vazia e a de baixo e o contorno do topo da lapide
    tx, ty = C.TIAO
    assert fg.get(tx, ty) == 0 and fg.get(tx, ty + 1) == 1, ('pouso do Tiao', fg.get(tx, ty + 1))
    # luma > 105 nas camadas de decoracao (relatorio)
    for name in ('vil', 'wall', 'fg'):
        cnt = {}
        for row in o[name].px:
            for v in row:
                if v and LUMA[v - 1] > 105:
                    cnt[v] = cnt.get(v, 0) + 1
        print('  luma>105 em %s:' % name, dict(sorted(cnt.items())))
    cnt = {}
    for row in o['can'][1].px:
        for v in row:
            if v and LUMA[v - 1] > 105:
                cnt[v] = cnt.get(v, 0) + 1
    print('  luma>105 na copa:', cnt)


# ===================================================================== previas
def try_load(path):
    return load(path) if os.path.exists(path) else None


def mock(o, logo=True, chars=True):
    rnd = random.Random(3)
    cv = Canvas(640, 360, 2)
    cv.blit(o['sky'].crop(0, C.SKY_OFF, 640, 360), 0, 0)
    stars = try_load(J(ROOT, 'assets', 'sprites', 'bg', 'a1', 'bg_a1_stars.png'))
    if stars:
        for (x, y, k) in [(160, 20, 0), (470, 150, 1), (560, 60, 0), (20, 150, 1), (340, 140, 0), (610, 100, 0)]:
            cv.blit(stars.crop(0, 5 * k, 5, 5), x - 2, y - 2)
    clouds = try_load(J(ROOT, 'assets', 'sprites', 'bg', 'a1', 'bg_a1_clouds.png'))
    if clouds:
        cv.blit(clouds.crop(0, 32, 160, 16), 40, 66)
        cv.blit(clouds.crop(0, 0, 160, 16), 440, 120)
    cv.blit(o['vil'], 0, 0)
    for i, (x, y) in enumerate(C.WINDOWS):
        cv.blit(o['win'].crop(2 if i % 5 else 0, 0, 2, 3), x, y)
    souls = try_load(J(CHARS, 'alma_fila.png'))
    pts = C.trail_points(1.0)
    for k, t in enumerate((0.12, 0.33, 0.55, 0.78)):
        x, y = pts[int(t * (len(pts) - 1))]
        if souls:
            cv.blit(souls.crop(8 * (k % 4), 0, 8, 10), x - 4, y - 9)
        else:
            cv.rect(x - 4, y - 9, 8, 10, 30)
    cv.blit(o['wall'], 0, 0)
    mist = try_load(J(ROOT, 'assets', 'sprites', 'bg', 'a1', 'nevoa_a1.png'))
    if mist:
        for x0 in (0, 320):
            cv.blit(mist.crop(0, 0, 320, 24), x0 - 40, 292)
    cv.blit(o['fg'], 0, 0)
    cx, cy = C.COVEIRO
    if chars:
        halo = try_load(J(CHARS, 'lanterna_chao_halo.png'))
        pa = try_load(J(CHARS, 'pa_cravada.png'))
        cov = try_load(J(CHARS, 'coveiro_title.png'))
        lan = try_load(J(CHARS, 'lanterna_chao.png'))
        tiao = try_load(J(CHARS, 'tiao.png'))
        if halo:
            for y in range(halo.h):
                for x in range(halo.w):
                    if halo.px[y][x]:
                        cv.set(C.LANTERNA[0] - 28 + x, C.LANTERNA[1] - 5 - 18 + y, halo.px[y][x])
        if pa:
            cv.blit(pa, C.PA_CRAVADA[0] - 4, C.PA_CRAVADA[1] - 25)
        else:
            cv.rect(C.PA_CRAVADA[0] - 1, C.PA_CRAVADA[1] - 24, 3, 25, 17)
        if cov:
            cv.blit(cov.crop(0, 0, 32, 32), cx - 16, cy - 31)
        else:
            cv.rect(cx - 10, cy - 26, 20, 27, 5)
        if lan:
            cv.blit(lan.crop(0, 0, 12, 16), C.LANTERNA[0] - 6, C.LANTERNA[1] - 15)
        else:
            cv.rect(C.LANTERNA[0] - 3, C.LANTERNA[1] - 9, 7, 10, 25)
        tx, ty = C.TIAO
        if tiao:
            cv.blit(tiao.crop(0, 0, 16, 16), tx - 8, ty - 15)
        else:
            cv.rect(tx - 5, ty - 10, 11, 11, 2)
    cv.blit(o['can'][1], *C.CANOPY_POS)
    pet = try_load(J(ROOT, 'assets', 'ui', 'tree', 'fx_petals.png'))
    if pet:
        for i in range(14):
            x, y = rnd.randrange(500, 636), rnd.randrange(180, 330)
            cv.blit(pet.crop(3 * (i % 2), 3 * (i % 4), 3, 3), x, y)
    ff = try_load(J(ROOT, 'assets', 'ui', 'tree', 'fx_firefly.png'))
    if ff:
        for i, (x, y) in enumerate([(30, 300), (190, 318), (238, 290), (330, 312), (500, 300), (620, 280)]):
            cv.blit(ff.crop(3 * (i % 3), 0, 3, 3), x, y)
    if logo:
        for c, inf in zip(o['cells'], o['infos']):
            cv.blit(c, *inf['pos'])
        cv.blit(o['shovel'], *o['shovel_pos'])
        sub = 'CAVA CAVA COVAS'
        F.draw(cv, 320 - F.width(sub) // 2, 109, sub, 22, outline=1)
    # botoes
    btn = load(J(ROOT, 'assets', 'ui', 'kit', 'btn_grande.png'))
    labels = ['CONTINUAR', 'NOVO JOGO', 'OPÇOES', 'CRÉDITOS', 'SAIR']
    for i, lab in enumerate(labels):
        st = 1 if i == 0 else 0
        y = 168 + 28 * i
        U.nine(cv, btn.crop(48 * st, 0, 48, 24), 372, y, 104, 24, 6, 6, 6, 8)
        F.draw(cv, 372 + 52 - F.width(lab) // 2, y + 7, lab, 22, outline=1)
    wisp = try_load(J(ROOT, 'assets', 'sprites', 'fx', 'fogo_fatuo.png'))
    if wisp:
        cv.blit(wisp.crop(0, 0, 8, 8), 360, 175)
    F.draw(cv, 320 - F.width('NOITE 7 1.234') // 2, 312, 'NOITE 7 1.234', 22, outline=1)
    F.draw(cv, 640 - 6 - F.width('V0.1'), 360 - 10, 'V0.1', 5)
    vin = try_load(J(ROOT, 'assets', 'sprites', 'bg', 'a1', 'vinheta.png'))
    if vin:
        cv.blit(vin, 0, 0)
    return cv


def gif(frames, durs, path, scale=4, bg=2, pad=2):
    w, h = frames[0].w + 2 * pad, frames[0].h + 2 * pad
    ims = []
    for fr in frames:
        c = Canvas(w, h, bg)
        c.blit(fr, pad, pad)
        ims.append(c.to_rgba(scale).convert('RGB').convert('P', palette=Image.ADAPTIVE))
    ims[0].save(path, save_all=True, append_images=ims[1:], duration=durs, loop=0, disposal=2)


def previews(o):
    m = mock(o)
    m.to_rgba(1).save(J(PREV, 'title_mock_640x360.png'))
    m.to_rgba(2).save(J(PREV, 'title_mock_2x.png'))
    m.to_rgba(2).convert('L').save(J(PREV, 'title_mock_cinza_2x.png'))
    # proporcao de cor (§3.3) na composicao final
    cnt = {}
    for row in m.px:
        for v in row:
            cnt[v] = cnt.get(v, 0) + 1
    tot = 640 * 360.0
    grp = {'noite 01-05': range(1, 6), 'materiais 06-22': range(6, 23), 'quente 24-26': range(24, 27),
           'sobrenatural 27-30': range(27, 31), 'perigo 31-32': range(31, 33), 'brilho 23': (23,)}
    print('proporcao:', {k: '%.1f%%' % (100 * sum(cnt.get(i, 0) for i in r) / tot) for k, r in grp.items()})
    # logo 4x sobre o ceu
    lg = Canvas(240, 120)
    lg.blit(o['sky'].crop(200, C.SKY_OFF, 240, 120), 0, 0)
    for c, inf in zip(o['cells'], o['infos']):
        lg.blit(c, inf['pos'][0] - 200, inf['pos'][1])
    sx, sy = o['shovel_pos']
    lg.blit(o['shovel'], sx - 200, sy)
    for inf in o['infos'][:2]:
        for (dx, dy) in inf['drips'][:1]:
            lg.blit(o['drip'][1], inf['pos'][0] + dx - LG.DRIP_PIVOT[0] - 200, inf['pos'][1] + dy - LG.DRIP_PIVOT[1])
    lg.to_rgba(4).save(J(PREV, 'title_logo_4x.png'))
    # pecas de UI 4x: lapide esticada, botoes, rolos em volta do pergaminho
    pc = Canvas(300, 110, 3)
    U.nine(pc, o['panel'], 4, 4, 120, 64, *U.STONE_NINE)
    F.draw(pc, 64 - F.width('ENTERRAR O') // 2, 22, 'ENTERRAR O', 1)
    F.draw(pc, 64 - F.width('PROGRESSO ATUAL?') // 2, 31, 'PROGRESSO ATUAL?', 1)
    U.nine(pc, o['panel'], 130, 4, 40, 40, *U.STONE_NINE)
    for i in range(4):
        pc.blit(o['btn'].crop(48 * i, 0, 48, 24), 4 + 52 * i, 76)
    F.draw(pc, 4 + 24 - F.width('ENTERRAR') // 2, 83, 'ENTERRAR', 22, outline=1)
    parch = load(J(ROOT, 'assets', 'ui', 'panels', 'panel_parchment.png'))
    px, py, pw, ph = 186, 12, 100, 50
    U.nine(pc, parch, px, py, pw, ph, 8, 8, 8, 8)
    F.draw(pc, px + 10, py + 14, 'CRÉDITOS', 18)
    rl = o['scroll']
    U.nine(pc, rl.crop(0, 0, 32, 12), px - 4, py - 6, pw + 8, 12, 8, 8, 0, 0)
    U.nine(pc, rl.crop(0, 12, 32, 12), px - 4, py + ph - 6, pw + 8, 12, 8, 8, 0, 0)
    pc.to_rgba(4).save(J(PREV, 'title_ui_4x.png'))
    # animacoes
    base = Canvas(12, 20, 2)
    gif(o['drip'] + [Canvas(LG.DRIP_W, LG.DRIP_H)], [100, 83, 83, 84, 400], J(PREV, 'title_logo_drip_8x.gif'), 8, 2)
    crop = [c.crop(10, 0, 154, 150) for c in o['can']]
    gif([crop[0], crop[1], crop[2], crop[1]], [400] * 4, J(PREV, 'title_canopy_3x.gif'), 3, 4)


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
    tmp = tempfile.mkdtemp(prefix='ddg_titulo_')
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
    for cat, name, frames, durs, tags in SPECS:
        paths = []
        for i, f in enumerate(frames):
            d = J(tmp, name, 'f%d' % i)
            os.makedirs(d, exist_ok=True)
            p = J(d, 'quadro.png')
            f.save(p)
            paths.append(p)
        out = J(ROOT, 'art_src', cat, name + '.aseprite')
        fl = '{' + ', '.join(lua_str(p) for p in paths) + '}'
        dl = '{' + ', '.join(str(d) for d in durs) + '}'
        tl = '{' + ', '.join('{%s, %d, %d}' % (lua_str(n), a, b) for (n, a, b) in tags) + '}'
        lines.append('build(%s, %s, %s, %s)' % (lua_str(out), fl, dl, tl))
    lua = J(tmp, 'build_titulo.lua')
    open(lua, 'w', encoding='utf-8').write('\n'.join(lines) + '\n')
    r = subprocess.run([ase, '-b', '--script', lua], capture_output=True, text=True)
    if r.returncode != 0 or 'rror' in (r.stdout + r.stderr):
        print(r.stdout, r.stderr)
        raise SystemExit('aseprite falhou')
    print('.aseprite montados:', len(SPECS))


def report(o):
    print('\n== coordenadas (tela, enquadramento final) ==')
    for i, inf in enumerate(o['infos']):
        gx, gy, gw, gh = inf['glyph']
        x, y = inf['pos']
        print('letra %2d %s celula (%d, %d) atlas (%d, %d) glifo (%d, %d)-(%d, %d) gotas %s' % (
            i, inf['ch'], x, y, (i % 6) * LG.CELL_W, (i // 6) * LG.CELL_H, x + gx, y + gy, x + gx + gw - 1,
            y + gy + gh - 1, [(x + a, y + b) for a, b in inf['drips']]))
    print('pa: canto', o['shovel_pos'], 'pivo', o['shovel_pivot'], 'ponto', o['shovel_entry'], 'tamanho',
          (o['shovel'].w, o['shovel'].h))
    print('janelas', C.WINDOWS)
    print('trilha', C.TRAIL, 'some em', C.SOUL_VANISH)
    print('coveiro', C.COVEIRO, 'pa', C.PA_CRAVADA, 'lanterna', C.LANTERNA, 'tiao', C.TIAO)
    print('copa', C.CANOPY_POS, (C.CANOPY_W, C.CANOPY_H))
    for nm, c in (('vila', o['vil']), ('muro', o['wall']), ('fg', o['fg'])):
        print(nm, 'bbox', bbox(c))


if __name__ == '__main__':
    o = build()
    check_palette()
    checks(o)
    previews(o)
    report(o)
    if '--ase' in sys.argv:
        ase = find_aseprite()
        if ase:
            build_aseprite(ase)
        else:
            print('Aseprite nao encontrado (defina ASEPRITE): .aseprite fonte pendente')
    print('ok')
