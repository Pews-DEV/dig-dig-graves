"""Fundo do Turno v2 — clareira de cemiterio na mata escura (docs/03_UI_UX.md §5, rev. 1.1).

Uso:  python -B build.py          gera PNG/JSON em assets/sprites/bg/a1/ e previas em art_src/_previews/
      python -B build.py --ase    tambem monta os .aseprite fonte (precisa do Aseprite: variavel
                                  ASEPRITE ou 'aseprite' no PATH)
Reaproveita Canvas/paleta e o mock do Turno de art_src/_gerador_turno/ (diorama + HUD atuais).
PNG indexados: 0 = transparente, 1-32 = Lua de Cova 32. Caminhos relativos a este arquivo."""
import json
import os
import random
import shutil
import subprocess
import sys
import tempfile

sys.dont_write_bytecode = True
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
sys.path.insert(0, os.path.join(ROOT, 'art_src', '_gerador_turno'))
sys.path.insert(0, HERE)

from PIL import Image                      # noqa: E402
from common import Canvas, PAL              # noqa: E402  (do _gerador_turno)
import fundo as F                           # noqa: E402

J = os.path.join
OUT = J(ROOT, 'assets', 'sprites', 'bg', 'a1')
PREV = J(ROOT, 'art_src', '_previews')
LUMA = [0] + [0.299 * r + 0.587 * g + 0.114 * b for (r, g, b) in PAL]
SWAY_MS = 800
WRITTEN = []
SPECS = []          # (nome do .aseprite, frames, duracoes, tags)


def save_png(c, path):
    c.save(path)
    WRITTEN.append(path)


def write_json(path, image_name, sheet_w, sheet_h, frames, tags):
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


def load(path):
    im = Image.open(path)
    assert im.mode == 'P', path
    c = Canvas(*im.size)
    data = list(im.get_flattened_data() if hasattr(im, 'get_flattened_data') else im.getdata())
    for y in range(im.size[1]):
        c.px[y] = data[y * im.size[0]:(y + 1) * im.size[0]]
    return c


# ===================================================================== geracao
def build():
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(PREV, exist_ok=True)
    m0 = F.mata_frame(0)
    m1 = F.mata_frame(1)
    chao = F.chao(m0)
    F.trunk_shadows(m0, chao)
    F.trunk_shadows(m1, chao)
    pr = F.props(chao)
    save_png(chao, J(OUT, 'bg_a1_chao.png'))
    save_png(pr, J(OUT, 'bg_a1_props.png'))
    sheet = Canvas(F.W * 2, F.H)
    sheet.blit(m0, 0, 0)
    sheet.blit(m1, F.W, 0)
    save_png(sheet, J(OUT, 'bg_a1_mata.png'))
    write_json(J(OUT, 'bg_a1_mata.json'), 'bg_a1_mata.png', sheet.w, sheet.h,
               [('bg_a1_mata %d.aseprite' % i, i * F.W, 0, F.W, F.H, SWAY_MS) for i in range(2)],
               [('idle', 0, 1, 'forward')])
    SPECS.append(('bg_a1_chao', [chao], [100], []))
    SPECS.append(('bg_a1_props', [pr], [100], []))
    SPECS.append(('bg_a1_mata', [m0, m1], [SWAY_MS, SWAY_MS], [('idle', 0, 1)]))
    return dict(chao=chao, props=pr, mata=[m0, m1])


# ===================================================================== checagens
def check_palette():
    want = [v for rgb in PAL for v in rgb]
    for f in WRITTEN:
        im = Image.open(f)
        assert im.mode == 'P', f
        mx = max(im.get_flattened_data() if hasattr(im, 'get_flattened_data') else im.getdata())
        assert mx <= 32 and im.getpalette()[3:3 + 96] == want, (f, mx)
        assert im.info.get('transparency') == 0, f
    print('paleta OK em', len(WRITTEN), 'PNG')


def screen_px(layer, x, y):
    return layer.px[y + F.PAD][x + F.PAD]


def compose_bg(o, frame=0, dx=0, dy=0):
    """fundo sozinho no enquadramento 640x360 (camadas em (-16, -16) + deslocamento)."""
    s = Canvas(640, 360)
    for lay in (o['chao'], o['props'], o['mata'][frame]):
        s.blit(lay, -F.PAD + dx, -F.PAD + dy)
    return s


def checks(o):
    rep = {}
    # 1) luma da decoracao (fora das chamas), por camada
    for name, lay in (('chao', o['chao']), ('props', o['props']), ('mata0', o['mata'][0]), ('mata1', o['mata'][1])):
        vals = [v for row in lay.px for v in row if v]
        deco = [v for v in vals if v not in F.FLAME]
        mx = max(LUMA[v] for v in deco)
        over74 = sum(1 for v in deco if LUMA[v] > 75)
        cols = sorted(set(vals))
        rep[name] = (round(mx, 1), over74, cols)
        assert mx <= 105.5, (name, mx)
        print('%-6s cores %s | luma max (sem chamas) %.1f | px > 74: %d' % (name, cols, mx, over74))
    flames = sum(1 for row in o['props'].px for v in row if v in F.FLAME)
    print('pixels de chama (22/23/25/26):', flames)
    # 2) zona livre: nada de props/mata dentro do maior campo 18x18 (+ bloco)
    for name, lay in (('props', o['props']), ('mata0', o['mata'][0]), ('mata1', o['mata'][1])):
        n = sum(1 for y in range(F.Y0, F.Y1) for x in range(F.X0, F.X1)
                if lay.g(x, y) and F.in_zone(x, y, 0))
        hud = sum(1 for y in range(F.Y0, F.Y1) for x in range(F.X0, F.X1)
                  if lay.g(x, y) and F.near_hud(x, y, 4) and LUMA[lay.g(x, y)] > 60)
        print('%-6s px no maior campo: %d | px claros (>60) junto das plaquetas: %d' % (name, n, hud))
        rep['zona_' + name] = (n, hud)
    # 3) pixels soltos (sem vizinho 4 opaco) nas camadas transparentes
    for name, lay in (('props', o['props']), ('mata0', o['mata'][0])):
        loose = 0
        for y in range(1, lay.h - 1):
            for x in range(1, lay.w - 1):
                if lay.px[y][x] and not any(lay.px[y + b][x + a] for a in (-1, 0, 1) for b in (-1, 0, 1) if a or b):
                    loose += 1
        print('%-6s pixels soltos (sem vizinho 8): %d' % (name, loose))
        rep['soltos_' + name] = loose
    # 4) luma media
    bg = compose_bg(o)
    lum = [LUMA[v] for row in bg.px for v in row]
    rep['bg_mean'] = sum(lum) / len(lum)
    print('luma media do fundo (640x360): %.1f' % rep['bg_mean'])
    return rep


# ===================================================================== mock (diorama + HUD atuais)
def mock_setup(bg_canvas):
    import cena
    import mock

    def load_linux(path):
        return load(J(ROOT, *path.replace('\\', '/').split('/')))
    mock.load = load_linux
    cena.sky = lambda: bg_canvas
    cena.clouds = lambda: Canvas(160, 48)
    cena.far = lambda: Canvas(1, 1)
    return cena, mock


def field_only(mock, cena, N, O):
    """campo N x N so com grama (S0) + bloco, para medir o topo do diorama e testar a zona livre."""
    old_N, old_O = mock.N, mock.O
    mock.N, mock.O = N, O
    rnd = random.Random(N)
    tiles = load(J(ROOT, 'assets', 'tiles', 'a1', 'tiles_a1.png'))
    c = Canvas(640, 360)
    top = []
    for (i, j) in sorted(((i, j) for i in range(N) for j in range(N)), key=lambda p: (p[0] + p[1], p[0])):
        x, y = mock.tile_pos(i, j)
        c.blit(mock.cell(tiles, 0, rnd.randrange(3), 32, 24), x - 16, y - 16)
    _, cells = cena.block_atlas()
    for i in range(N):
        x, y = mock.tile_pos(i, N - 1)
        cc = cells[8] if i == N - 1 else (cells[3] if i == 0 else cells[i % 3])
        c.blit(cc, x - 16, y - 16)
    for j in range(N - 1):
        x, y = mock.tile_pos(N - 1, j)
        c.blit(cells[7] if j == 0 else cells[4 + j % 3], x - 16, y - 16)
    mock.N, mock.O = old_N, old_O
    return c


def grey(im):
    return im.convert('L').convert('RGB')


def mocks(o, rep):
    import pa
    bg = compose_bg(o)
    cena, mock = mock_setup(bg)
    # mock padrao (N = 12, igual ao run_mock): fundo novo + diorama + cursor + nevoa + vinheta + HUD
    s = mock.scene()
    mock.area_outline(s, 5, 6)
    x, y = mock.tile_pos(5, 6)
    s.blit(pa.frames()[0][1], x - 3, y - 20)
    vin = load(J(OUT, 'vinheta.png'))
    s.blit(vin, 0, 0)
    mock.hud(s)
    s.to_rgba(1).save(J(PREV, 'run_bg2_mock_640x360.png'))
    s.to_rgba(2).save(J(PREV, 'run_bg2_mock_2x.png'))
    grey(s.to_rgba(2)).save(J(PREV, 'run_bg2_mock_cinza_2x.png'))
    # so o fundo (com vinheta, sem diorama/HUD)
    b2 = compose_bg(o)
    b2.to_rgba(2).save(J(PREV, 'run_bg2_so_fundo_2x.png'))
    b3 = compose_bg(o)
    b3.blit(vin, 0, 0)
    b3.to_rgba(2).save(J(PREV, 'run_bg2_so_fundo_vinheta_2x.png'))
    # GIF do balanco da mata (2 frames, 800 ms)
    ims = [compose_bg(o, k).to_rgba(1).convert('RGB') for k in (0, 1)]
    ims[0].save(J(PREV, 'run_bg2_mata_balanco_1x.gif'), save_all=True, append_images=ims[1:],
                duration=SWAY_MS, loop=0)
    # campos extremos: 6x6 e 18x18 centrados em (320, 180) (sem HUD por cima do campo)
    for N in (6, 18):
        O = (320, 188 - 8 * N)
        f = field_only(mock, cena, N, O)
        c = compose_bg(o)
        c.blit(f, 0, 0)
        c.blit(vin, 0, 0)
        mock.hud(c)
        c.to_rgba(2).save(J(PREV, 'run_bg2_campo%d_2x.png' % N))
        # luma media do topo do diorama (pixels do campo cujo indice e grama de tile)
        vals = [LUMA[v] for row in f.px for v in row if v]
        rep['diorama_%d' % N] = sum(vals) / len(vals)
    # topo do diorama no mock padrao: losango N = 12 (pixels de tile)
    top = []
    for yy in range(360):
        for xx in range(640):
            ox, oy = mock.O
            # losango do campo 12x12: pivo (0,0) em O; centro em O + (0, 88)
            cx, cy = ox, oy - 8 + 12 * 8
            if abs(xx - cx) / (12 * 16) + abs(yy - cy) / (12 * 8) <= 0.95:
                top.append(LUMA[s.px[yy][xx]])
    rep['diorama_top_mock'] = sum(top) / len(top)
    # fundo visivel no mock (fora do losango + bloco, fora do HUD)
    vis = []
    for yy in range(360):
        for xx in range(640):
            ox, oy = mock.O
            cx, cy = ox, oy - 8 + 96
            dy = yy - cy
            if dy > 0:
                dy = max(0, dy - 30)
            if abs(xx - cx) / 200 + abs(dy) / 100 > 1 and not F.near_hud(xx, yy, 2):
                vis.append(LUMA[bg.px[yy][xx]])
    rep['bg_visivel_mock'] = sum(vis) / len(vis)
    print('luma media do topo do diorama (mock N=12): %.1f' % rep['diorama_top_mock'])
    print('luma media do fundo visivel no mock (fora do campo/HUD): %.1f' % rep['bg_visivel_mock'])
    print('luma media do diorama (campo S0 + bloco): N=6 %.1f | N=18 %.1f' % (rep['diorama_6'], rep['diorama_18']))


def pieces(o):
    """props recortados a 4x sobre o chao, para revisao."""
    c = compose_bg(o)
    crops = [(60, 70, 140, 110), (400, 40, 160, 120), (20, 190, 140, 140), (500, 200, 140, 130)]
    W = sum(w for (_, _, w, _) in crops) + 4 * (len(crops) + 1)
    H = max(h for (_, _, _, h) in crops) + 8
    sh = Canvas(W, H, 1)
    x = 4
    for (cx, cy, w, h) in crops:
        sh.blit(c.crop(cx, cy, w, h), x, 4)
        x += w + 4
    sh.to_rgba(3).save(J(PREV, 'run_bg2_props_3x.png'))


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
    tmp = tempfile.mkdtemp(prefix='ddg_fundo_turno_')
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
    for name, frames, durs, tags in SPECS:
        paths = []
        for i, f in enumerate(frames):
            d = J(tmp, name, 'f%d' % i)
            os.makedirs(d, exist_ok=True)
            p = J(d, 'quadro.png')
            f.save(p)
            paths.append(p)
        out = J(ROOT, 'art_src', 'bg', name + '.aseprite')
        fl = '{' + ', '.join(lua_str(p) for p in paths) + '}'
        dl = '{' + ', '.join(str(d) for d in durs) + '}'
        tl = '{' + ', '.join('{%s, %d, %d}' % (lua_str(n), a, b) for (n, a, b) in tags) + '}'
        lines.append('build(%s, %s, %s, %s)' % (lua_str(out), fl, dl, tl))
    lua = J(tmp, 'build_fundo_turno.lua')
    open(lua, 'w', encoding='utf-8').write('\n'.join(lines) + '\n')
    r = subprocess.run([ase, '-b', '--script', lua], capture_output=True, text=True)
    if r.returncode != 0 or 'rror' in (r.stdout + r.stderr):
        print(r.stdout, r.stderr)
        raise SystemExit('aseprite falhou')
    print('.aseprite montados:', len(SPECS))


if __name__ == '__main__':
    o = build()
    check_palette()
    rep = checks(o)
    mocks(o, rep)
    pieces(o)
    if '--ase' in sys.argv:
        ase = find_aseprite()
        if not ase:
            raise SystemExit('Aseprite nao encontrado (defina ASEPRITE)')
        build_aseprite(ase)
    else:
        print('.aseprite: pendente (rode com --ase numa maquina com Aseprite)')
    print('ok')
