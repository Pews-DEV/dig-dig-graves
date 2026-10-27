"""Personagens da tela-titulo (UI/UX §9.1 e §9.6): Coveiro, pa cravada, lanterna no chao
(+ halo), Tiao e a alminha da fila.

Uso:  python build.py            (gera PNG + JSON em assets/sprites/chars/title/ e as previas)
      python build.py --ase      (tambem monta os .aseprite fonte, se o Aseprite existir)

Os PNG sao indexados (0 = transparente, 1-32 = cores 01-32 da Lua de Cova 32). Os JSON
seguem o formato "Array" do Aseprite (frames + meta.frameTags com duracoes).
Caminhos configuraveis por variavel de ambiente: DDG_ROOT (raiz do repo) e ASEPRITE
(executavel do Aseprite)."""
import json
import os
import shutil
import subprocess
import sys
import tempfile

from PIL import Image

from common import Canvas, PAL, lonely_pixels, components
import coveiro as C
import tiao as T
import alma_fila as A

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.environ.get('DDG_ROOT') or os.path.abspath(os.path.join(HERE, '..', '..'))
ASE = os.environ.get('ASEPRITE') or shutil.which('aseprite') or \
    r'C:\Program Files (x86)\Steam\steamapps\common\Aseprite\Aseprite.exe'
OUT = os.path.join(ROOT, 'assets', 'sprites', 'chars', 'title')
PREV = os.path.join(ROOT, 'art_src', '_previews')
SRC = os.path.join(ROOT, 'art_src', 'chars')

SPECS = []


def spec(id_, src, frames, durations, tags=(), fx=False):
    w, h = frames[0].w, frames[0].h
    for f in frames:
        assert (f.w, f.h) == (w, h), id_
    SPECS.append(dict(id=id_, src=src, frames=frames, durations=list(durations),
                      tags=list(tags), fx=fx))


def hstrip(frames):
    w, h = frames[0].w, frames[0].h
    s = Canvas(w * len(frames), h)
    for i, f in enumerate(frames):
        s.blit(f, i * w, 0)
    return s


# ------------------------------------------------------------------ montagem
def coveiro_frames():
    fr, du, tags = [], [], []

    def tag(name, items):
        a = len(fr)
        for f, d in items:
            fr.append(f)
            du.append(d)
        tags.append((name, a, len(fr) - 1))

    S = C.sit
    base = S()
    # idle: respira (o rosto desce antes do chapeu e, na volta, sobe antes dele)
    tag('idle', [(base, 167), (base, 167), (S(head_dy=1, hat_dy=-1), 167),
                 (S(head_dy=1), 167), (S(head_dy=1), 167), (S(head_dy=1, hat_dy=-1), 167)])
    s0 = S(arm='scratch0', hat_dy=-1, eyes='closed')
    s1 = S(arm='scratch1', eyes='closed')
    tag('scratch', [(S(arm='half'), 100), (s0, 83), (s1, 83), (s0, 83), (s1, 83),
                    (s0, 83), (s1, 83), (S(arm='half', eyes='closed'), 100)])
    tag('yawn', [(S(head_dy=-1, eyes='closed', mouth='small', arm='half'), 125),
                 (S(head_dy=-1, eyes='closed', mouth='open', arm='stretch'), 125),
                 (S(head_dy=-1, eyes='closed', mouth='open', arm='stretch'), 500),
                 (S(head_dy=-1, eyes='closed', mouth='small', arm='stretch'), 125),
                 (S(eyes='closed', arm='half'), 125),
                 (S(eyes='closed'), 250)])
    st = C.stand_frames()
    tag('stand', list(zip(st, [167, 83, 83, 167, 250])))
    return fr, du, tags


def build():
    os.makedirs(OUT, exist_ok=True)
    fr, du, tags = coveiro_frames()
    spec('coveiro_title', 'chars/char_coveiro_title.aseprite', fr, du, tags)
    spec('pa_cravada', 'props/prop_pa_cravada.aseprite', [C.pa_cravada()], [100])
    spec('lanterna_chao', 'props/prop_lanterna_chao.aseprite',
         [C.lanterna(i) for i in range(3)], [125] * 3, [('idle', 0, 2)])
    spec('lanterna_chao_halo', 'fx/fx_lanterna_chao_halo.aseprite', [C.halo()], [100], fx=True)
    fr, du, tags = T.frames()
    spec('tiao', 'chars/char_tiao.aseprite', fr, du, tags)
    wk, vn = A.walk(), A.vanish()
    spec('alma_fila', 'fx/fx_alma_fila.aseprite', wk + vn, [143] * 4 + [83] * 3,
         [('walk', 0, 3), ('vanish', 4, 6)], fx=True)


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
    path = os.path.join(OUT, sp['id'] + '.json')
    with open(path, 'w', encoding='utf-8', newline='\n') as fh:
        json.dump({'frames': frames, 'meta': meta}, fh, indent=1, ensure_ascii=False)
        fh.write('\n')


def export():
    for sp in SPECS:
        png = sp['id'] + '.png'
        hstrip(sp['frames']).save(os.path.join(OUT, png))
        if len(sp['frames']) > 1 or sp['tags']:
            write_json(sp, png)


# ------------------------------------------------------------------ verificacoes
def check():
    want = [v for rgb in PAL for v in rgb]
    ok = True
    for sp in SPECS:
        im = Image.open(os.path.join(OUT, sp['id'] + '.png'))
        data = list(im.get_flattened_data() if hasattr(im, 'get_flattened_data') else im.getdata())
        assert im.mode == 'P' and max(data) <= 32, sp['id']
        assert im.getpalette()[3:3 + 96] == want, sp['id']
        assert im.info.get('transparency') == 0, sp['id']
        used = sorted(set(data) - {0})
        msgs = []
        for i, f in enumerate(sp['frames']):
            if not sp['fx']:
                lp = lonely_pixels(f)
                if lp:
                    msgs.append(f'frame {i}: pixels soltos {lp}')
                    ok = False
                n = components(f)
                if n != 1:
                    msgs.append(f'frame {i}: {n} partes soltas')
                    ok = False
        print(f"{sp['id']:20s} {im.size} cores {used} {'OK' if not msgs else ''}")
        for m in msgs:
            print('   ', m)
    # semantica: 27-29 e 31-32 nunca aparecem; 24-26 so na lanterna/moeda/halo
    for sp in SPECS:
        cs = set(v for f in sp['frames'] for r in f.px for v in r)
        assert not cs & {27, 28, 29, 31, 32}, sp['id']
        if sp['id'] == 'alma_fila':
            assert cs <= {0, 3, 23, 30}, cs
    if not ok:
        raise SystemExit('verificacao falhou')
    print('verificacoes OK')


# ------------------------------------------------------------------ previas
def scene(cov, props=True, lant_frame=0):
    c = Canvas(32, 32)
    if props:
        C.put_canvas(c, C.pa_cravada(), C.PA_AT, C.PA_PIVOT)
    c.blit(cov, 0, 0)
    if props:
        C.put_canvas(c, C.lanterna(lant_frame), C.LANT_AT, C.LANT_PIVOT)
    return c


def mock_ground(w, h, ground_y, bg=2):
    """chao provisorio (topo plano do monte 14/15) so para as previas."""
    c = Canvas(w, h, bg)
    for y in range(ground_y, h):
        for x in range(w):
            c.px[y][x] = 15 if y == ground_y else 14
    return c


def gif(path, frames, durs, scale=4, bg=3):
    ims = []
    for f in frames:
        c = Canvas(f.w, f.h, bg)
        c.blit(f, 0, 0)
        ims.append(c.to_rgba(scale).convert('RGB'))
    ims[0].save(path, save_all=True, append_images=ims[1:], duration=durs, loop=0, disposal=1)


def framed(f, pad, ground=True, halo=False):
    """frame do Coveiro (com pa/lanterna) sobre o chao provisorio + halo."""
    w, h = 32 + 2 * pad + 8, 32 + pad + 4
    c = mock_ground(w, h, 31 + pad + 1) if ground else Canvas(w, h, 2)
    if halo:
        hx = pad + C.GLASS_AT[0] - C.HALO_PIVOT[0]
        hy = pad + C.GLASS_AT[1] - C.HALO_PIVOT[1]
        c.blit(C.halo(), hx, hy)
    c.blit(f, pad, pad)
    return c


def previews():
    os.makedirs(PREV, exist_ok=True)
    cov = next(s for s in SPECS if s['id'] == 'coveiro_title')
    for (name, a, b) in cov['tags']:
        props = name != 'stand'
        frs, durs = [], []
        for i in range(a, b + 1):
            keep = props or i - a < 3
            frs.append(framed(scene(cov['frames'][i], keep, (i - a) % 3), 8, halo=keep))
            durs.append(cov['durations'][i])
        if name == 'stand':                        # segura o ultimo e recomeca
            durs[-1] = 1200
            frs = [framed(scene(cov['frames'][0], True), 8, halo=True)] + frs
            durs = [600] + durs
        gif(os.path.join(PREV, f'coveiro_title_{name}_4x.gif'), frs, durs, 4, 2)
    ti = next(s for s in SPECS if s['id'] == 'tiao')
    tf = []
    for f in ti['frames']:
        c = Canvas(24, 24, 2)
        c.rect(4, 19, 16, 5, 7)            # lapide provisoria (07/08) embaixo
        c.rect(4, 19, 16, 1, 8)
        c.blit(f, 4, 4)
        tf.append(c)
    gif(os.path.join(PREV, 'tiao_4x.gif'), tf, ti['durations'], 4, 2)
    al = next(s for s in SPECS if s['id'] == 'alma_fila')
    seq = al['frames'][:4] * 3 + al['frames'][4:] + [Canvas(8, 10)]
    dd = al['durations'][:4] * 3 + al['durations'][4:] + [500]
    gif(os.path.join(PREV, 'alma_fila_8x.gif'), seq, dd, 8, 3)
    lc = [C.lanterna(i) for i in range(3)]
    gif(os.path.join(PREV, 'lanterna_chao_8x.gif'), lc, [125] * 3, 8, 2)

    # folha estatica: todos os frames + cena montada 1x + sombra chinesa
    rows = []
    for sp in SPECS:
        rows.append(sp)
    W = 4
    for sp in SPECS:
        W = max(W, 4 + len(sp['frames']) * (sp['frames'][0].w + 2))
    W = max(W, 200)
    H = sum(sp['frames'][0].h + 4 for sp in SPECS) + 4 + 120
    sh = Canvas(W, H, 3)
    y = 4
    for sp in SPECS:
        x = 4
        for f in sp['frames']:
            if sp['id'] == 'lanterna_chao_halo':
                sh.rect(x, y, f.w, f.h, 2)
            sh.blit(f, x, y)
            x += f.w + 2
        y += sp['frames'][0].h + 4
    # cena 1x: halo, pa, coveiro, lanterna, Tiao na lapide e 3 alminhas
    sc = mock_ground(200, 60, 48)
    sc.blit(C.halo(), 20 + C.GLASS_AT[0] - C.HALO_PIVOT[0], 17 + C.GLASS_AT[1] - C.HALO_PIVOT[1])
    sc.blit(scene(cov['frames'][0]), 20, 17)
    sc.rect(68, 34, 14, 14, 7)
    sc.rect(68, 34, 14, 1, 8)
    sc.blit(ti['frames'][0], 67, 19)
    for i in range(3):
        sc.blit(al['frames'][i], 120 + 14 * i, 10 + 2 * i)
    sh.blit(sc, 4, y)
    # sombra chinesa (silhueta 01 sobre 07)
    sil = Canvas(200, 52, 7)
    xx = 4
    for f in [scene(cov['frames'][0]), scene(cov['frames'][7]), scene(cov['frames'][15]),
              cov['frames'][-1], ti['frames'][0], ti['frames'][-3], al['frames'][0]]:
        for j in range(f.h):
            for i in range(f.w):
                if f.px[j][i]:
                    sil.set(xx + i, 4 + j, 1)
        xx += f.w + 4
    sh.blit(sil, 4, y + 64)
    im = sh.to_rgba(4)
    im.save(os.path.join(PREV, 'title_chars_4x.png'))
    im.convert('L').convert('RGB').save(os.path.join(PREV, 'title_chars_cinza_4x.png'))
    sc.to_rgba(1).save(os.path.join(PREV, 'title_chars_cena_1x.png'))
    print('previas OK')


# ------------------------------------------------------------------ aseprite (opcional)
def build_aseprite():
    if not ASE or not os.path.exists(ASE):
        print('Aseprite nao encontrado: .aseprite fonte fica pendente')
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
        out = os.path.join(SRC, *sp['src'].split('/')[1:]) if False else \
            os.path.join(ROOT, 'art_src', *sp['src'].split('/'))
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
