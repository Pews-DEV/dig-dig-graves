"""Gera e exporta: pa 24x24, cena da Area 1 e kit de UI.
Uso: python build.py <pasta_temporaria>
1. gera os canvases (indices da Lua de Cova 32, 0 = transparente);
2. grava os PNG estaticos em assets/;
3. grava os frames em <tmp> e monta os .aseprite (Aseprite CLI + Lua) em art_src/;
4. exporta as folhas animadas + JSON (Array) pelo proprio Aseprite e confere pixel a pixel;
5. gera as previas em art_src/_previews/."""
import json
import os
import subprocess
import sys
from PIL import Image

from common import Canvas, PAL
import pa
import cena
import kit
import mock

ROOT = r'C:\Users\pedro\Documents\projects\dig-dig-graves'
ASE = r'C:\Program Files (x86)\Steam\steamapps\common\Aseprite\Aseprite.exe'
PREV = ROOT + r'\art_src\_previews'
TMP = sys.argv[1] if len(sys.argv) > 1 else os.environ['TEMP']
FR = os.path.join(TMP, 'frames')
os.makedirs(FR, exist_ok=True)


def P(*parts):
    return os.path.join(ROOT, *parts)


def hstrip(frames):
    w, h = frames[0].w, frames[0].h
    s = Canvas(w * len(frames), h)
    for i, f in enumerate(frames):
        s.blit(f, i * w, 0)
    return s


# ------------------------------------------------------------------ especificacoes
SPECS = []   # cada uma vira um .aseprite


def spec(name, src, frames, durations=None, tags=(), slices=(), sheet=None):
    """frames: lista de Canvas (mesmo tamanho). sheet: caminho do PNG/JSON exportado pelo
    Aseprite (sem extensao) ou None (PNG estatico gravado pelo Python)."""
    SPECS.append(dict(name=name, src=src, frames=frames,
                      durations=durations or [100] * len(frames), tags=list(tags),
                      slices=list(slices), sheet=sheet))


def build_all():
    os.makedirs(P('assets', 'sprites', 'bg', 'a1'), exist_ok=True)
    os.makedirs(P('assets', 'ui', 'kit'), exist_ok=True)
    os.makedirs(P('art_src', 'bg'), exist_ok=True)

    # ---- pa
    fr = [c for (_, c) in pa.frames()]
    spec('fx_cursor_pa24', P('art_src', 'fx', 'fx_cursor_pa24.aseprite'), fr,
         [167, 167, 50, 50, 50, 50, 50], [('idle', 0, 1), ('act', 2, 6)],
         sheet=P('assets', 'sprites', 'fx', 'cursor_pa24'))

    # ---- cena
    BG = P('assets', 'sprites', 'bg', 'a1')
    statics = {}
    statics['bg_a1_sky'] = cena.sky()
    statics['bg_a1_stars'] = cena.star_sheet()
    statics['bg_a1_clouds'] = cena.clouds()
    statics['bg_a1_far'] = cena.far()
    blk, _ = cena.block_atlas()
    statics['bloco_a1'] = blk
    fence = Canvas(96, 32)
    fence.blit(cena.fence('NO'), 0, 0)
    fence.blit(cena.fence('NE'), 32, 0)
    fence.blit(cena.fence_post(), 64 + 13, 18)
    statics['cerca_a1'] = fence
    statics['tufos_a1'] = cena.tufts()
    sg = Canvas(112, 26)
    sg.blit(cena.sign_with_text(), 0, 0)
    sg.blit(cena.sign(), 56, 0)
    statics['placa_a1'] = sg
    statics['nevoa_a1'] = cena.mist_atlas()
    statics['vinheta'] = cena.vignette()
    for k, c in statics.items():
        c.save(os.path.join(BG, k + '.png'))
        spec('bg_' + k if not k.startswith('bg_') else k, P('art_src', 'bg', (k if k.startswith('bg_') else 'bg_' + k) + '.aseprite'), [c])

    # ---- kit de UI
    KIT = P('assets', 'ui', 'kit')
    bg = [kit.button(48, 24, s) for s in kit.STATES]
    hstrip(bg).save(os.path.join(KIT, 'btn_grande.png'))
    spec('ui_btn_grande', P('art_src', 'ui', 'ui_btn_grande.aseprite'), bg,
         slices=[('nine', (0, 0, 48, 24), (6, 6, 36, 10))])
    bp = [kit.button(20, 20, s) for s in kit.STATES]
    hstrip(bp).save(os.path.join(KIT, 'btn_pequeno.png'))
    spec('ui_btn_pequeno', P('art_src', 'ui', 'ui_btn_pequeno.aseprite'), bp)
    pl = kit.plaque()
    pl.save(os.path.join(KIT, 'plaqueta.png'))
    spec('ui_plaqueta', P('art_src', 'ui', 'ui_plaqueta.aseprite'), [pl],
         slices=[('nine', (0, 0, 32, 24), (8, 12, 16, 1))])
    tt = kit.tooltip()
    tt.save(os.path.join(KIT, 'tooltip.png'))
    spec('ui_tooltip', P('art_src', 'ui', 'ui_tooltip.aseprite'), [tt],
         slices=[('nine', (0, 0, 16, 16), (3, 3, 10, 9))])
    tl = kit.tails()
    tl.save(os.path.join(KIT, 'tooltip_rabicho.png'))
    spec('ui_tooltip_rabicho', P('art_src', 'ui', 'ui_tooltip_rabicho.aseprite'), [tl])
    md = [kit.medal()] + [kit.medal(sw) for sw in (6, 15, 24, 33)]
    spec('ui_medalha_nivel', P('art_src', 'ui', 'ui_medalha_nivel.aseprite'), md,
         [500, 83, 83, 84, 83], [('idle', 0, 0), ('special', 1, 4)],
         sheet=os.path.join(KIT, 'medalha_nivel'))
    ln = [kit.lantern(i) for i in range(3)] + [kit.lantern(i, True) for i in range(3)]
    spec('ui_lanterna', P('art_src', 'ui', 'ui_lanterna.aseprite'), ln,
         [125, 125, 125, 83, 83, 84], [('idle', 0, 2), ('low', 3, 5)],
         sheet=os.path.join(KIT, 'lanterna'))
    sk = kit.skull()
    sk.save(os.path.join(KIT, 'icone_inquietacao.png'))
    spec('icon_inquietacao', P('art_src', 'ui', 'icon_inquietacao.aseprite'), [sk])


# ------------------------------------------------------------------ aseprite
def lua_str(s):
    return '"' + s.replace('\\', '\\\\') + '"'


def write_lua():
    lines = ['local function build(out, frames, durs, tags, slices)',
             '  local imgs, poss = {}, {}',
             '  for i = 2, #frames do',
             '    local o = app.open(frames[i])',
             '    imgs[i] = Image(o.cels[1].image)',
             '    poss[i] = Point(o.cels[1].position.x, o.cels[1].position.y)',
             '    o:close()',
             '  end',
             '  local spr = app.open(frames[1])',
             '  local layer = spr.layers[1]',
             '  layer.name = "arte"',
             '  for i = 2, #frames do',
             '    spr:newEmptyFrame(i)',
             '    spr:newCel(layer, i, imgs[i], poss[i])',
             '  end',
             '  for i = 1, #frames do spr.frames[i].duration = durs[i] / 1000 end',
             '  for _, t in ipairs(tags) do',
             '    local tg = spr:newTag(t[2] + 1, t[3] + 1)',
             '    tg.name = t[1]',
             '  end',
             '  for _, s in ipairs(slices) do',
             '    local sl = spr:newSlice(Rectangle(s[2], s[3], s[4], s[5]))',
             '    sl.name = s[1]',
             '    sl.center = Rectangle(s[6], s[7], s[8], s[9])',
             '  end',
             '  spr.transparentColor = 0',
             '  spr:saveAs(out)',
             '  spr:close()',
             'end']
    for sp in SPECS:
        paths = []
        for i, f in enumerate(sp['frames']):
            d = os.path.join(FR, sp['name'], f'f{i}')
            os.makedirs(d, exist_ok=True)
            p = os.path.join(d, 'quadro.png')     # 1 pasta por frame: evita a deteccao de sequencia
            f.save(p)
            paths.append(p)
        fl = '{' + ', '.join(lua_str(p) for p in paths) + '}'
        dl = '{' + ', '.join(str(d) for d in sp['durations']) + '}'
        tl = '{' + ', '.join('{%s, %d, %d}' % (lua_str(n), a, b) for (n, a, b) in sp['tags']) + '}'
        sl = '{' + ', '.join('{%s, %d, %d, %d, %d, %d, %d, %d, %d}' % ((lua_str(n),) + tuple(r) + tuple(cc))
                             for (n, r, cc) in sp['slices']) + '}'
        lines.append(f"build({lua_str(sp['src'])}, {fl}, {dl}, {tl}, {sl})")
    path = os.path.join(TMP, 'build_ase.lua')
    open(path, 'w', encoding='utf-8').write('\n'.join(lines) + '\n')
    return path


def run_ase(*args):
    r = subprocess.run([ASE, '-b'] + list(args), capture_output=True, text=True)
    if r.returncode != 0 or 'rror' in (r.stdout + r.stderr):
        print(r.stdout, r.stderr)
        raise SystemExit('aseprite falhou')
    return r


def export_sheets():
    for sp in SPECS:
        if not sp['sheet']:
            continue
        png, js = sp['sheet'] + '.png', sp['sheet'] + '.json'
        run_ase(sp['src'], '--sheet', png, '--data', js, '--format', 'json-array',
                '--sheet-type', 'horizontal', '--list-tags', '--filename-format',
                '{title} {frame}.aseprite')
        # confere pixel a pixel com o gerado
        exp = hstrip(sp['frames'])
        im = Image.open(png)
        if im.mode != 'P':
            raise SystemExit(f'{png}: modo {im.mode}, esperado P')
        data = list(im.get_flattened_data()) if hasattr(im, 'get_flattened_data') else list(im.getdata())
        ref = [v for row in exp.px for v in row]
        pal = im.getpalette()[:99]
        want = [0, 0, 0] + [v for rgb in PAL for v in rgb]
        ok = data == ref and pal[3:] == want[3:]
        print('export', os.path.basename(png), im.size, 'OK' if ok else 'DIFERENTE')
        js_d = json.load(open(js, encoding='utf-8'))
        print('   frames', len(js_d['frames']), 'tags', [(t['name'], t['from'], t['to']) for t in js_d['meta']['frameTags']])
        if not ok:
            raise SystemExit('folha exportada difere do gerado')


def check_palette():
    """todo PNG novo: modo P, indices <= 32, paleta = Lua de Cova 32 nos indices 1-32."""
    want = [v for rgb in PAL for v in rgb]
    files = []
    for d in (P('assets', 'sprites', 'bg', 'a1'), P('assets', 'ui', 'kit')):
        files += [os.path.join(d, f) for f in os.listdir(d) if f.endswith('.png')]
    files.append(P('assets', 'sprites', 'fx', 'cursor_pa24.png'))
    for f in files:
        im = Image.open(f)
        assert im.mode == 'P', f
        mx = max(im.get_flattened_data() if hasattr(im, 'get_flattened_data') else im.getdata())
        pal = im.getpalette()[3:3 + 96]
        assert mx <= 32 and pal == want, (f, mx)
        assert im.info.get('transparency') == 0, (f, im.info.get('transparency'))
    print('paleta OK em', len(files), 'PNG')


if __name__ == '__main__':
    build_all()
    lua = write_lua()
    run_ase('--script', lua)
    export_sheets()
    check_palette()
    print('ok')
