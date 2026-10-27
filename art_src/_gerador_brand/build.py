"""Splash do estudio: logo Briba Studio em pixel art (lagartixa + "briba" + "studio").

Uso:  python -B build.py
Gera (PNG indexados com a paleta Lua de Cova 32; indice 0 = transparente, 1-32 = cores 01-32):
  assets/ui/brand/briba_logo.png            estatico, 104x132
  assets/ui/brand/briba_logo_anim.png/.json tira horizontal de frames 104x132 (Aseprite Array)
  art_src/_previews/briba_splash_640x360.png, briba_splash_640x360_2x.png,
  art_src/_previews/briba_logo_intro_4x.gif, briba_logo_compara_4x.png

A lagartixa esta em lagartixa.txt (colunas brancas por linha, 1 px = 8 px do original de
1254x1254). As letras sao desenhadas a mao abaixo, em grade. Nada e reamostrado do original:
ele so entra nas previas de comparacao."""
import json
import os
import sys
from PIL import Image

sys.dont_write_bytecode = True
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
J = os.path.join
OUT = J(ROOT, 'assets', 'ui', 'brand')
PREV = J(ROOT, 'art_src', '_previews')
ORIG = J(ROOT, 'art_src', 'brand', 'briba_studio_logo_original.png')

PAL_HEX = """0d0b14 1a1626 2a2440 3d3660 58507f 7d789c a8a5bf d6d4e3
1f3b35 2f5a46 4a7d55 7aa35e 2b1a17 4a2c22 6e4430 946140
b88a5a 3b2230 5e3340 8a4b4f c9b48f e8dcc0 fff6e0 a8541a
e08a2a ffc94a 1b5e5a 2fb39a 7cf2c8 8fd3ff 8c2b3a d0465a""".split()
PAL = [tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) for h in PAL_HEX]  # PAL[i-1] = cor i

FUNDO, OSSO_SOMBRA, OSSO, OSSO_BRILHO = 1, 21, 22, 23
LW, LH = 100, 128          # caixa da marca
M = 2                      # margem transparente em volta
CW, CH = LW + 2 * M, LH + 2 * M   # canvas 104x132
PIVO = (CW // 2, CH // 2)  # (52, 66): centro da marca


# ------------------------------------------------------------------ desenho base (mascara 0/1)
def blank():
    return [[0] * LW for _ in range(LH)]


def spans(g, rows):
    """rows: {linha: 'a-b c-d'}"""
    for r, sp in rows.items():
        for s in sp.split():
            a, b = (int(v) for v in s.split('-'))
            for x in range(a, b + 1):
                g[r][x] = 1


def grid(g, x0, y0, rows):
    for j, row in enumerate(rows):
        for i, ch in enumerate(row):
            if ch == '#':
                g[y0 + j][x0 + i] = 1


def load_lagartixa():
    rows = {}
    with open(J(HERE, 'lagartixa.txt'), encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            r, sp = line.split(':')
            rows[int(r)] = sp
    return rows


# --- "briba": letras grossas arredondadas (altura 28: ascendente y 90, altura-x y 98, base y 117)
B_ROWS = {  # "b" na coluna 0 (desenhado com a haste em 1-10; deslocado depois)
    90: '5-10', 91: '2-10', 92: '1-10', 93: '1-10', 94: '1-10', 95: '1-10', 96: '1-10', 97: '1-10',
    98: '1-15', 99: '1-18', 100: '1-20', 101: '1-21', 102: '1-22', 103: '1-22',
    104: '1-10 15-23', 105: '1-9 16-23', 106: '1-9 16-23', 107: '1-9 16-23', 108: '1-9 16-23',
    109: '1-9 16-23', 110: '1-10 15-23', 111: '1-23', 112: '1-22', 113: '1-21', 114: '1-20',
    115: '2-19', 116: '3-17', 117: '6-13'}
R_ROWS = {
    98: '27-32 36-40', 99: '26-41', 100: '26-41', 101: '26-41', 102: '26-41', 103: '26-41',
    104: '26-41', 105: '26-40', 106: '26-37', **{y: '26-34' for y in range(107, 117)}, 117: '27-33'}
I_ROWS = {
    92: '44-50', 93: '43-51', 94: '43-51', 95: '43-51', 96: '43-51', 97: '43-51', 98: '44-50',
    101: '44-50', **{y: '43-51' for y in range(102, 117)}, 117: '44-50'}
A_ROWS = {
    97: '88-94', 98: '84-97', 99: '82-98', 100: '81-98', 101: '81-99', 102: '81-99',
    103: '81-86 91-99', 104: '82-85 91-99', 105: '88-99', 106: '85-99', 107: '82-99',
    108: '81-87 91-99', 109: '80-86 92-99', 110: '79-86 92-99', 111: '79-87 91-99',
    112: '79-99', 113: '79-99', 114: '80-99', 115: '80-99', 116: '81-90 93-99', 117: '83-88 94-98'}

# --- "studio": traço de 2 px, altura-x 6 (y 122-127), ascendentes em y 120, espaçado
STUDIO = [  # (x0, linhas a partir de y = 120)
    (22, ['.....', '.....', '.####', '##...', '.###.', '...##', '##.##', '.###.']),        # s
    (32, ['.##..', '.##..', '#####', '.##..', '.##..', '.##..', '.##..', '..###']),        # t
    (42, ['......', '......', '##..##', '##..##', '##..##', '##..##', '##..##', '.####.']),  # u
    (53, ['....##', '....##', '.#####', '##..##', '##..##', '##..##', '##..##', '.#####']),  # d
    (65, ['##', '..', '##', '##', '##', '##', '##', '##']),                                  # i
    (72, ['......', '......', '.####.', '##..##', '##..##', '##..##', '##..##', '.####.']),  # o
]
TRACOS = {124: '5-16 83-94', 125: '13-16 83-86'}  # traços dos lados de "studio" (ponta grossa junto ao texto)


def shift(rows, dx):
    out = {}
    for r, sp in rows.items():
        parts = []
        for s in sp.split():
            a, b = (int(v) for v in s.split('-'))
            parts.append('%d-%d' % (a + dx, b + dx))
        out[r] = ' '.join(parts)
    return out


# ------------------------------------------------------------------ olhos (piscada)
OLHO_E = {5: (44, 46), 6: (42, 48), 7: (41, 50), 8: (40, 51), 9: (39, 52), 10: (39, 52),
          11: (39, 53), 12: (39, 53), 13: (39, 53), 14: (40, 53), 15: (41, 54), 16: (43, 54),
          17: (49, 54), 18: (50, 53)}
OLHO_D = {8: (64, 66), 9: (63, 67), 10: (63, 68), 11: (62, 68), 12: (62, 68), 13: (62, 68),
          14: (62, 68), 15: (63, 68), 16: (63, 67), 17: (64, 66)}


def olho(g, socket, estado):
    """estado: 'aberto' (nao mexe), 'meio' (palpebra cobre a metade de cima, sem espiral),
    'fechado' (so a linha de baixo da orbita, 2 px)."""
    if estado == 'aberto':
        return
    cells = {(x, y) for y, (a, b) in socket.items() for x in range(a, b + 1)}
    ys = sorted(socket)
    meio = (ys[0] + ys[-1]) // 2
    for (x, y) in cells:
        if estado == 'meio':
            g[y][x] = 1 if y <= meio else 0
        else:
            linha = (x, y + 1) not in cells or (x, y + 2) not in cells
            g[y][x] = 0 if linha else 1


# ------------------------------------------------------------------ rabo (enrolando)
def rabo_ordem(g):
    """Distancia (BFS 4-viz.) ao longo do rabo, a partir de onde os dois tracos do corpo se
    juntam (y = 74). Serve para revelar o rabo enrolando de fora para dentro."""
    def no_rabo(x, y):
        if not (0 <= x < LW and 0 <= y < LH) or not g[y][x]:
            return False
        return (y >= 74 and 29 <= x <= 63 and y <= 89) or (67 <= y <= 73 and 30 <= x <= 49)
    seeds = [(x, 74) for x in range(50, 64) if no_rabo(x, 74)]
    dist = {p: 0 for p in seeds}
    fila = list(seeds)
    i = 0
    while i < len(fila):
        x, y = fila[i]
        i += 1
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            q = (x + dx, y + dy)
            if q not in dist and no_rabo(*q):
                dist[q] = dist[(x, y)] + 1
                fila.append(q)
    return dist


# ------------------------------------------------------------------ montagem
def marca(olhos='aberto', rabo=1.0):
    g = blank()
    spans(g, load_lagartixa())
    spans(g, shift(B_ROWS, -1))
    spans(g, shift(R_ROWS, -1))
    spans(g, I_ROWS)
    spans(g, shift(B_ROWS, 53))
    spans(g, A_ROWS)
    for x0, rows in STUDIO:
        grid(g, x0, 120, rows)
    spans(g, TRACOS)
    if rabo < 1.0:
        dist = rabo_ordem(g)
        lim = max(dist.values()) * rabo
        for (x, y), d in dist.items():
            if d > lim:
                g[y][x] = 0
    olho(g, OLHO_E, olhos)
    olho(g, OLHO_D, olhos)
    return g


def colorir(g):
    """Osso 22 chapado; 23 no fio de cima/esquerda (luz da lua, NO) e 21 no fio de
    baixo/direita, so onde o traço tem folga (>= 4 px) para nao virar uma cor so."""
    def w(x, y):
        return 0 <= x < LW and 0 <= y < LH and g[y][x]
    c = [[0] * LW for _ in range(LH)]
    for y in range(LH):
        for x in range(LW):
            if not g[y][x]:
                continue
            col = OSSO
            if not w(x, y - 1) and w(x, y + 1) and w(x, y + 2) and w(x, y + 3):
                col = OSSO_BRILHO
            elif not w(x - 1, y) and w(x + 1, y) and w(x + 2, y) and w(x + 3, y):
                col = OSSO_BRILHO
            elif not w(x, y + 1) and w(x, y - 1) and w(x, y - 2) and w(x, y - 3):
                col = OSSO_SOMBRA
            elif not w(x + 1, y) and w(x - 1, y) and w(x - 2, y) and w(x - 3, y):
                col = OSSO_SOMBRA
            c[y][x] = col
    return c


def to_canvas(c):
    out = [[0] * CW for _ in range(CH)]
    for y in range(LH):
        for x in range(LW):
            out[y + M][x + M] = c[y][x]
    return out


def img_p(px):
    h, w = len(px), len(px[0])
    im = Image.new('P', (w, h))
    flat = [0, 0, 0] + [v for rgb in PAL for v in rgb]
    flat += [0] * (768 - len(flat))
    im.putpalette(flat)
    im.putdata([v for row in px for v in row])
    return im


def save_p(px, path):
    img_p(px).save(path, transparency=0)


def rgb(px, bg=FUNDO, scale=1):
    h, w = len(px), len(px[0])
    im = Image.new('RGB', (w, h))
    im.putdata([PAL[(v or bg) - 1] for row in px for v in row])
    return im.resize((w * scale, h * scale), Image.NEAREST) if scale > 1 else im


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
    with open(path, 'w', encoding='utf-8', newline='\n') as f:
        json.dump(data, f, indent=1, ensure_ascii=False)
        f.write('\n')


# intro: o rabo enrola (5 f), a lagartixa pisca (meio, fechado) e abre. idle: aberto / fechado.
INTRO = [('aberto', .20, 100), ('aberto', .40, 100), ('aberto', .60, 100), ('aberto', .80, 100),
         ('aberto', 1.0, 100), ('meio', 1.0, 80), ('fechado', 1.0, 100), ('aberto', 1.0, 120)]
IDLE = [('aberto', 1.0, 3200), ('fechado', 1.0, 140)]


def lint(c):
    """pixels soltos (sem vizinho 4-conexo da mesma mascara) e cores fora da paleta."""
    soltos = []
    for y in range(LH):
        for x in range(LW):
            if c[y][x] and not any(0 <= x + dx < LW and 0 <= y + dy < LH and c[y + dy][x + dx]
                                   for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                soltos.append((x, y))
    return soltos


def main():
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(PREV, exist_ok=True)
    estatico = to_canvas(colorir(marca()))
    save_p(estatico, J(OUT, 'briba_logo.png'))

    frames = []
    for olhos, rabo, d in INTRO + IDLE:
        frames.append((to_canvas(colorir(marca(olhos, rabo))), d))
    sheet = [[0] * (CW * len(frames)) for _ in range(CH)]
    for i, (f, _) in enumerate(frames):
        for y in range(CH):
            sheet[y][i * CW:(i + 1) * CW] = f[y]
    save_p(sheet, J(OUT, 'briba_logo_anim.png'))
    n_intro = len(INTRO)
    write_json(J(OUT, 'briba_logo_anim.json'), 'briba_logo_anim.png', CW * len(frames), CH,
               [('briba_logo_anim %d' % i, i * CW, 0, CW, CH, d) for i, (_, d) in enumerate(frames)],
               [('intro', 0, n_intro - 1, 'forward'), ('idle', n_intro, len(frames) - 1, 'forward')])

    # checagens
    g = marca()
    assert not lint(g), lint(g)
    for f, _ in frames:
        assert set(v for row in f for v in row) <= {0, OSSO_SOMBRA, OSSO, OSSO_BRILHO}
    assert estatico == frames[n_intro - 1][0] == frames[n_intro][0]

    # previas
    tela = [[0] * 640 for _ in range(360)]
    ox, oy = 320 - PIVO[0], 180 - PIVO[1]
    for y in range(CH):
        for x in range(CW):
            if estatico[y][x]:
                tela[oy + y][ox + x] = estatico[y][x]
    rgb(tela).save(J(PREV, 'briba_splash_640x360.png'))
    rgb(tela, scale=2).save(J(PREV, 'briba_splash_640x360_2x.png'))

    Z = 4
    orig = Image.open(ORIG).convert('RGB')
    # original reduzido para a mesma altura (128 px de marca -> 128*Z), lado a lado
    o = orig.crop((228, 108, 228 + 8 * LW, 108 + 8 * LH)).resize((LW * Z, LH * Z), Image.LANCZOS).convert('L')
    o = Image.composite(Image.new('RGB', o.size, PAL[OSSO - 1]), Image.new('RGB', o.size, PAL[FUNDO - 1]), o)
    pad = 8 * Z
    comp = Image.new('RGB', (2 * CW * Z + pad, CH * Z), PAL[FUNDO - 1])
    comp.paste(rgb(estatico, scale=Z), (0, 0))
    comp.paste(o, (CW * Z + pad + M * Z, M * Z))
    comp.save(J(PREV, 'briba_logo_compara_4x.png'))
    gif = []
    durs = []
    for f, d in frames[:n_intro] + [(frames[n_intro][0], 900)] + frames[n_intro + 1:] + [(frames[n_intro][0], 600)]:
        im = Image.new('RGB', comp.size, PAL[FUNDO - 1])
        im.paste(rgb(f, scale=Z), (0, 0))
        im.paste(o, (CW * Z + pad + M * Z, M * Z))
        gif.append(im.convert('P', palette=Image.ADAPTIVE, colors=64))
        durs.append(d)
    gif[0].save(J(PREV, 'briba_logo_intro_4x.gif'), save_all=True, append_images=gif[1:],
                duration=durs, loop=0, disposal=1)
    print('ok:', CW, 'x', CH, 'frames', len(frames), 'pivo', PIVO)


if __name__ == '__main__':
    main()
