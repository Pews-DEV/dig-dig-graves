"""Chefe do estagio 1 (Caixao Fujao), retratos de dialogo 48x48, Mascate (corpo inteiro)
e balao de dialogo.

Uso:  python -B build.py          (gera PNG + JSON em assets/ e as previas em art_src/_previews/)
      python -B build.py --ase    (tambem monta os .aseprite fonte, se o Aseprite existir)

PNG indexados (0 = transparente, 1-32 = cores 01-32 da Lua de Cova 32). JSON no formato
"Array" do Aseprite (frames + meta.frameTags com duracoes).
Variaveis de ambiente: DDG_ROOT (raiz do repo) e ASEPRITE (executavel do Aseprite)."""
import json
import os
import shutil
import subprocess
import sys
import tempfile

from PIL import Image

from common import Canvas, PAL, lonely_pixels, components, ellipse, fill
import boss as B
import portraits as P
import mascate as M
import balao as BL

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.environ.get('DDG_ROOT') or os.path.abspath(os.path.join(HERE, '..', '..'))
ASE = os.environ.get('ASEPRITE') or shutil.which('aseprite') or ''
PREV = os.path.join(ROOT, 'art_src', '_previews')

SPECS = []


def spec(id_, out, src, frames, durations=None, tags=(), loose=(), lint=True):
    """loose = quadros que podem ter partes soltas (torroes, alma, faiscas)."""
    w, h = frames[0].w, frames[0].h
    for f in frames:
        assert (f.w, f.h) == (w, h), id_
    SPECS.append(dict(id=id_, out=out, src=src, frames=frames,
                      durations=list(durations or [100] * len(frames)),
                      tags=list(tags), loose=set(loose), lint=lint))


def hstrip(frames):
    w, h = frames[0].w, frames[0].h
    s = Canvas(w * len(frames), h)
    for i, f in enumerate(frames):
        s.blit(f, i * w, 0)
    return s


def build():
    fr, du, tags = B.frames()
    loose = [i for (n, a, b) in tags if n in ('sink', 'emerge', 'defeat') for i in range(a, b + 1)]
    spec('boss_caixao_fujao', 'assets/sprites/bosses', 'bosses/boss_caixao_fujao.aseprite',
         fr, du, tags, loose=loose)
    spec('boss_caixao_buraco', 'assets/sprites/bosses', 'bosses/boss_caixao_buraco.aseprite',
         [B.hole_sprite()], lint=False)
    spec('icon_boss_caixao', 'assets/ui/icons', 'ui/icon_boss_caixao.aseprite', [B.icon()])
    for name in P.CHARS:
        spec('portrait_' + name, 'assets/ui/portraits', f'ui/portrait_{name}.aseprite',
             P.frames(name), [125, 125, 125], [('idle', 0, 0), ('talk', 0, 1), ('happy', 2, 2)])
    fr, du, tags = M.frames()
    spec('mascate', 'assets/sprites/chars', 'chars/char_mascate.aseprite', fr, du, tags)
    spec('balao', 'assets/ui/kit', 'ui/ui_balao.aseprite', [BL.balao()])
    spec('balao_rabicho', 'assets/ui/kit', 'ui/ui_balao_rabicho.aseprite', [BL.rabicho()],
         lint=False)


def write_json(sp, png_name):
    w, h = sp['frames'][0].w, sp['frames'][0].h
    title = os.path.splitext(os.path.basename(sp['src']))[0]
    frames = []
    for i, d in enumerate(sp['durations']):
        frames.append({
            'filename': f'{title} {i}.aseprite',
            'frame': {'x': i * w, 'y': 0, 'w': w, 'h': h},
            'rotated': False, 'trimmed': False,
            'spriteSourceSize': {'x': 0, 'y': 0, 'w': w, 'h': h},
            'sourceSize': {'w': w, 'h': h},
            'duration': d,
        })
    meta = {'app': 'https://www.aseprite.org/', 'version': '1.3.x (gerado em Python)',
            'image': png_name, 'format': 'I8',
            'size': {'w': w * len(sp['frames']), 'h': h}, 'scale': '1',
            'frameTags': [{'name': n, 'from': a, 'to': b, 'direction': 'forward',
                           'color': '#000000ff'} for (n, a, b) in sp['tags']]}
    path = os.path.join(ROOT, sp['out'], sp['id'] + '.json')
    with open(path, 'w', encoding='utf-8', newline='\n') as fh:
        json.dump({'frames': frames, 'meta': meta}, fh, indent=1, ensure_ascii=False)
        fh.write('\n')


def export():
    for sp in SPECS:
        d = os.path.join(ROOT, sp['out'])
        os.makedirs(d, exist_ok=True)
        png = sp['id'] + '.png'
        hstrip(sp['frames']).save(os.path.join(d, png))
        if sp['tags']:
            write_json(sp, png)


# ------------------------------------------------------------------ verificacoes
SEM_PERIGO = {31, 32}
SOBRENATURAL = {27, 28, 29, 30}


def check():
    want = [v for rgb in PAL for v in rgb]
    ok = True
    for sp in SPECS:
        im = Image.open(os.path.join(ROOT, sp['out'], sp['id'] + '.png'))
        data = list(im.get_flattened_data() if hasattr(im, 'get_flattened_data') else im.getdata())
        assert im.mode == 'P' and max(data) <= 32, sp['id']
        assert im.getpalette()[3:3 + 96] == want, sp['id']
        assert im.info.get('transparency') == 0, sp['id']
        used = sorted(set(data) - {0})
        msgs = []
        if sp['lint']:
            for i, f in enumerate(sp['frames']):
                lp = lonely_pixels(f)
                if lp:
                    msgs.append(f'frame {i}: pixels soltos {lp}')
                    ok = False
                n = components(f)
                if n != 1 and i not in sp['loose']:
                    msgs.append(f'frame {i}: {n} partes soltas')
                    ok = False
        print(f"{sp['id']:24s} {str(im.size):12s} cores {used} {'OK' if not msgs else ''}")
        for m in msgs:
            print('   ', m)
    # semantica de cor (DA §3.2)
    by = {sp['id']: set(v for f in sp['frames'] for r in f.px for v in r) for sp in SPECS}
    b = by['boss_caixao_fujao']
    assert not b & (SEM_PERIGO | {27, 28, 29}), b
    assert b & {24, 25} == set(), 'chefe: 24/25 nao (so pregos 26)'
    # alma (30) so nos quadros da derrota
    fr = SPECS[0]['frames']
    dt = [t for t in SPECS[0]['tags'] if t[0] == 'defeat'][0]
    for i, f in enumerate(fr):
        has30 = any(30 in r for r in f.px)
        assert not has30 or dt[1] <= i <= dt[2], f'alma fora da derrota no quadro {i}'
    for k in ('portrait_dona_ceifa', 'portrait_tiao', 'portrait_coveiro', 'portrait_mascate',
              'mascate', 'balao', 'balao_rabicho', 'icon_boss_caixao', 'boss_caixao_buraco'):
        assert not by[k] & (SEM_PERIGO | SOBRENATURAL), (k, by[k] & (SEM_PERIGO | SOBRENATURAL))
    if not ok:
        raise SystemExit('verificacao falhou')
    print('verificacoes OK')


# ------------------------------------------------------------------ previas
def mock_field(w, h, cx, cy):
    """2x2 tiles de grama (11/12) em volta do pivo, so para as previas."""
    c = Canvas(w, h, 2)
    for y in range(h):
        for x in range(w):
            dx, dy = abs(x + 0.5 - cx), abs(y + 0.5 - cy)
            if dx / 32 + dy / 16 <= 1:
                c.px[y][x] = 11 if ((x - cx) // 2 + (y - cy)) % 16 else 10
    return c


def gif(path, frames, durs, scale=4):
    ims = [f.to_rgba(scale).convert('RGB') for f in frames]
    ims[0].save(path, save_all=True, append_images=ims[1:], duration=durs, loop=0, disposal=1)


def on_bg(f, w, h, x, y, bg=3, field=None):
    c = field() if field else Canvas(w, h, bg)
    c.blit(f, x, y)
    return c


def previews():
    os.makedirs(PREV, exist_ok=True)
    bs = SPECS[0]
    fld = lambda: mock_field(80, 60, 40, 38)  # noqa: E731  pivo (32, 32) -> (40, 38)
    for (name, a, b) in bs['tags']:
        frs = [on_bg(bs['frames'][i], 80, 60, 8, 6, field=fld) for i in range(a, b + 1)]
        durs = bs['durations'][a:b + 1]
        if len(frs) == 1 or name in ('sink', 'emerge', 'defeat'):
            frs = [on_bg(bs['frames'][0], 80, 60, 8, 6, field=fld)] + frs
            durs = [500] + durs[:-1] + [max(durs[-1], 600)]
        gif(os.path.join(PREV, f'boss_caixao_{name}_4x.gif'), frs, durs, 4)
    ms = next(s for s in SPECS if s['id'] == 'mascate')
    for (name, a, b) in ms['tags']:
        frs = [on_bg(ms['frames'][i], 32, 36, 4, 2) for i in range(a, b + 1)]
        gif(os.path.join(PREV, f'mascate_{name}_4x.gif'), frs, ms['durations'][a:b + 1], 4)
    # retratos falando (todos lado a lado, sobre o balao)
    prs = [s for s in SPECS if s['id'].startswith('portrait_')]
    talk = []
    for k in range(4):
        c = Canvas(len(prs) * 52 + 4, 56, 3)
        for j, s in enumerate(prs):
            c.blit(s['frames'][k % 2], 4 + j * 52, 4)
        talk.append(c)
    gif(os.path.join(PREV, 'portraits_talk_4x.gif'), talk, [125] * 4, 4)

    # folha estatica
    W = 1700
    rows = []
    y = 4
    sh = Canvas(W // 1, 10, 3)
    blocks = []
    for sp in SPECS:
        fw, fh = sp['frames'][0].w, sp['frames'][0].h
        per = max(1, (W - 8) // (fw + 4))
        n = len(sp['frames'])
        hh = ((n + per - 1) // per) * (fh + 4)
        blocks.append((sp, per, y))
        y += hh + 4
    # mock de dialogo e sombra chinesa
    y_mock = y
    y += 64
    y_sil = y
    y += 56
    sh = Canvas(W, y, 3)
    for sp, per, y0 in blocks:
        fw, fh = sp['frames'][0].w, sp['frames'][0].h
        for i, f in enumerate(sp['frames']):
            x = 4 + (i % per) * (fw + 4)
            yy = y0 + (i // per) * (fh + 4)
            if sp['id'].startswith('balao'):
                sh.rect(x, yy, fw, fh, 2)
            sh.blit(f, x, yy)
    # mock de dialogo: balao esticado 9-slice com retrato e rabicho
    mock = dialog_mock()
    sh.blit(mock, 4, y_mock)
    # sombra chinesa
    xx = 4
    for f in [SPECS[0]['frames'][0], SPECS[0]['frames'][6], SPECS[0]['frames'][20]] + \
             [s['frames'][0] for s in prs] + [ms['frames'][0], ms['frames'][4]]:
        for j in range(f.h):
            for i in range(f.w):
                if f.px[j][i]:
                    sh.set(xx + i, y_sil + j, 1)
        xx += f.w + 4
    im = sh.to_rgba(4)
    im.save(os.path.join(PREV, 'chefes_dialogos_4x.png'))
    im.convert('L').convert('RGB').save(os.path.join(PREV, 'chefes_dialogos_cinza_4x.png'))
    mock.to_rgba(2).save(os.path.join(PREV, 'dialogo_mock_2x.png'))
    print('previas OK')


def nine(src, w, h, l, r, t, b):
    o = Canvas(w, h)
    sw, shh = src.w, src.h

    def sx(x):
        if x < l:
            return x
        if x >= w - r:
            return sw - (w - x)
        return l + (x - l) % (sw - l - r)

    def sy(y):
        if y < t:
            return y
        if y >= h - b:
            return shh - (h - y)
        return t + (y - t) % (shh - t - b)
    for y in range(h):
        for x in range(w):
            o.px[y][x] = src.px[sy(y)][sx(x)]
    return o


def dialog_mock():
    """como o godot-dev deve montar: retrato a esquerda, balao 9-slice, rabicho para a esq."""
    c = Canvas(300, 60, 2)
    pr = next(s for s in SPECS if s['id'] == 'portrait_madame_ossada')['frames'][1]
    c.blit(pr, 6, 6)
    bx, by, bw, bh = 66, 8, 220, 44
    c.blit(nine(BL.balao(), bw, bh, *BL.NINE), bx, by)
    rab = BL.rabicho().crop(20, 0, 10, 10)
    # celula 2 (esquerda): coluna 9 da celula cobre a coluna 0 do balao
    c.blit(rab, bx - 9, by + 22)
    # "texto" de mentirinha em 18
    for k, ln in enumerate((150, 120)):
        for x in range(bx + 8, bx + 8 + ln):
            if (x // 5) % 6:
                c.set(x, by + 10 + k * 10, 18)
                c.set(x, by + 11 + k * 10, 18)
    cofre = next(s for s in SPECS if s['id'] == 'icon_boss_caixao')['frames'][0]
    c.blit(cofre, 268, 32)
    return c


# ------------------------------------------------------------------ aseprite (opcional)
def build_aseprite():
    if not ASE or not os.path.exists(ASE):
        print('Aseprite nao encontrado: .aseprite fonte fica pendente (defina ASEPRITE)')
        return
    tmp = tempfile.mkdtemp()
    lines = ['local function build(out, frames, durs, tags)',
             '  local spr = app.open(frames[1])',
             '  local layer = spr.layers[1]; layer.name = "arte"',
             '  for i = 2, #frames do',
             '    local o = app.open(frames[i]); local img = Image(o.cels[1].image)',
             '    local pos = o.cels[1].position; o:close()',
             '    spr:newEmptyFrame(i); spr:newCel(layer, i, img, pos)',
             '  end',
             '  for i = 1, #frames do spr.frames[i].duration = durs[i] / 1000 end',
             '  for _, t in ipairs(tags) do local tg = spr:newTag(t[2] + 1, t[3] + 1); tg.name = t[1] end',
             '  spr.transparentColor = 0; spr:saveAs(out); spr:close()',
             'end']

    def q(s):
        return '"' + s.replace('\\', '\\\\') + '"'
    for sp in SPECS:
        paths = []
        for i, f in enumerate(sp['frames']):
            d = os.path.join(tmp, sp['id'], f'f{i}')
            os.makedirs(d, exist_ok=True)
            p = os.path.join(d, 'quadro.png')
            f.save(p)
            paths.append(p)
        out = os.path.join(ROOT, 'art_src', *sp['src'].split('/'))
        os.makedirs(os.path.dirname(out), exist_ok=True)
        lines.append('build(%s, {%s}, {%s}, {%s})' % (
            q(out), ', '.join(q(p) for p in paths), ', '.join(map(str, sp['durations'])),
            ', '.join('{%s, %d, %d}' % (q(n), a, b) for (n, a, b) in sp['tags'])))
    lua = os.path.join(tmp, 'build.lua')
    open(lua, 'w', encoding='utf-8').write('\n'.join(lines) + '\n')
    r = subprocess.run([ASE, '-b', '--script', lua], capture_output=True, text=True)
    print(r.stdout, r.stderr)


if __name__ == '__main__':
    build()
    export()
    check()
    previews()
    if '--ase' in sys.argv:
        build_aseprite()
    print('ok')
