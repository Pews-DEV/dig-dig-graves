"""Logo da tela-titulo (docs/03_UI_UX.md §9.2): 12 letras de pedra (07/08, bisel 06,
espessura 05, contorno 01) com terra 15/16 escorrendo do topo, uma por celula do atlas;
pa cravada no 2o G (title_logo_shovel) e gota de terra (title_logo_drip)."""
import random
from common import Canvas

N4 = ((1, 0), (-1, 0), (0, 1), (0, -1))

GLYPHS = {
    'D': ["XXXXX.", "XX..XX", "XX..XX", "XX..XX", "XX..XX", "XX..XX", "XXXXX."],
    'I': ["XXXX", ".XX.", ".XX.", ".XX.", ".XX.", ".XX.", "XXXX"],
    'G': [".XXXX.", "XX..XX", "XX....", "XX.XXX", "XX..XX", "XX..XX", ".XXXXX"],
    'R': ["XXXXX.", "XX..XX", "XX..XX", "XXXXX.", "XX.XX.", "XX..XX", "XX..XX"],
    'A': [".XXXX.", "XX..XX", "XX..XX", "XXXXXX", "XX..XX", "XX..XX", "XX..XX"],
    'V': ["XX..XX", "XX..XX", "XX..XX", "XX..XX", "XX..XX", ".XXXX.", "..XX.."],
    'E': ["XXXXXX", "XX....", "XX....", "XXXXX.", "XX....", "XX....", "XXXXXX"],
    'S': [".XXXXX", "XX....", "XX....", ".XXXX.", "....XX", "....XX", "XXXXX."],
}

CELL_W, CELL_H = 36, 46
GX, GY = 2, 5              # canto sup. esq. do glifo dentro da celula
EXTRUDE = 3

LETTERS = 'DIGDIGGRAVES'
# layout final (tela): linha 1 "DIG DIG" (bloco 4 px), linha 2 "GRAVES" (bloco 5 px)
LINE1_TOP, LINE2_TOP = 28, 65
JITTER = [0, 1, 0, -1, 0, 1, 1, 0, -1, 0, 1, 0]      # baseline "assentada a mao"
SHOVEL_LETTER = 5          # 2o "G" do logo (fim de "DIG DIG")


def glyph_mask(ch, k):
    g = GLYPHS[ch]
    gh, gw = len(g), len(g[0])
    full = lambda i, j: 0 <= i < gw and 0 <= j < gh and g[j][i] == 'X'
    m = set()
    for j in range(gh):
        for i in range(gw):
            if not full(i, j):
                continue
            for y in range(k):
                for x in range(k):
                    m.add((i * k + x, j * k + y))
            # cantos convexos arredondados (degraus 2-1)
            for (cx, cy, sx, sy) in ((0, 0, 1, 1), (k - 1, 0, -1, 1), (0, k - 1, 1, -1), (k - 1, k - 1, -1, -1)):
                if sx == 1 and i == 0 and ch in 'DER':
                    continue          # haste reta a esquerda (D nao vira O)
                ni, nj = i - sx, j - sy
                if not full(ni, j) and not full(i, nj) and not full(ni, nj):
                    x0, y0 = i * k + cx, j * k + cy
                    for (dx, dy) in ((0, 0), (sx, 0), (0, sy)):
                        m.discard((x0 + dx, y0 + dy))
    return m, gw * k, gh * k


def letter(ch, k, seed, shovel=False):
    """retorna (Canvas CELL_W x CELL_H, info). info: glyph (x, y, w, h) na celula e
    pontas das gotas (x, y) na celula (pixel logo abaixo do bulbo de cada escorrido)."""
    rnd = random.Random(seed)
    m, gw, gh = glyph_mask(ch, k)
    face = {}
    for (x, y) in m:
        v = 7
        if (x - 1, y) not in m or (x, y - 1) not in m:
            v = 8
        if (x + 1, y) not in m or (x, y + 1) not in m:
            v = 6
        face[(x, y)] = v
    # rachaduras (06, 2-3 px ligadas) e lascas de luz (08, 2 px)
    pts = sorted(p for p, v in face.items() if v == 7)
    for _ in range(2 if k == 4 else 3):
        x, y = rnd.choice(pts)
        path = [(x, y), (x + 1, y + 1), (x + 1, y + 2)] if rnd.random() < 0.5 else [(x, y), (x + 1, y), (x + 2, y + 1)]
        if all(face.get(p) == 7 for p in path):
            for p in path:
                face[p] = 6
    for _ in range(2):
        x, y = rnd.choice(pts)
        if face.get((x, y)) == 7 and face.get((x + 1, y)) == 7:
            face[(x, y)] = 8
            face[(x + 1, y)] = 8
    # espessura (pedra em bloco): 3 px para baixo
    ext = {}
    for (x, y) in m:
        for d in range(1, EXTRUDE + 1):
            q = (x, y + d)
            if q in m:
                break
            if q not in ext:
                ext[q] = 5
    for (x, y) in list(ext):
        if (x - 1, y) not in ext and (x - 1, y) not in m:
            ext[(x, y)] = 6
    # terra no topo de cada coluna + monte acima nas partes retas
    tops = {}
    for (x, y) in m:
        if (x, y - 1) not in m and y < 2 * k and (x not in tops or y < tops[x]):
            tops[x] = y
    dirt = {}
    for x, y0 in tops.items():
        th = 2 + (1 if rnd.random() < 0.45 else 0)
        for d in range(th):
            if (x, y0 + d) in m:
                dirt[(x, y0 + d)] = 15
    pile = {}
    xs = sorted(tops)
    for x in xs:
        y0 = tops[x]
        if tops.get(x - 1) == y0 and tops.get(x + 1) == y0 and tops.get(x - 2) == y0 and tops.get(x + 2) == y0:
            p = 1 + (1 if ((x * 7 + seed * 3) % 9) < 4 else 0)
            for d in range(1, p + 1):
                pile[(x, y0 - d)] = 15
    # suaviza o monte: sem degraus de 2 px seguidos de buraco
    for (x, y) in list(pile):
        if (x - 1, y) not in pile and (x + 1, y) not in pile and (x, y + 1) in pile:
            del pile[(x, y)]
    dirt.update(pile)
    for (x, y) in list(dirt):
        if (x, y - 1) not in dirt:
            dirt[(x, y)] = 16
    # escorridos: 2 px de largura, bulbo de 3 px, dentro da face
    drips = []
    cand = [x for x in xs if tops.get(x + 1) == tops[x] and tops.get(x + 2) == tops[x] and tops.get(x - 1) == tops[x]]
    rnd.shuffle(cand)
    want = 1 if ch == 'I' else 2
    used = []
    for x in cand:
        if len(drips) >= want:
            break
        if any(abs(x - u) < 6 for u in used):
            continue
        if shovel and abs(x - 14) < 6:
            continue
        y0 = tops[x]
        L = rnd.randrange(3, 10 if k == 4 else 13)
        ys = y0 + 3
        ok = all((xx, yy) in m for xx in (x, x + 1, x + 2) for yy in range(ys, ys + L + 3))
        if not ok:
            continue
        for yy in range(ys - 1, ys + L):
            dirt[(x, yy)] = 16
            dirt[(x + 1, yy)] = 15
        yb = ys + L
        dirt[(x, yb)] = 16
        dirt[(x + 1, yb)] = 15
        dirt[(x + 2, yb)] = 15
        dirt[(x, yb + 1)] = 15
        dirt[(x + 1, yb + 1)] = 15
        dirt[(x + 2, yb + 1)] = 14
        drips.append((x, yb + 2))
        used.append(x)
    c = Canvas(CELL_W, CELL_H)
    allp = set(m) | set(ext) | set(pile)
    for (x, y), v in ext.items():
        c.set(GX + x, GY + y, v)
    for (x, y), v in face.items():
        c.set(GX + x, GY + y, v)
    for (x, y), v in dirt.items():
        c.set(GX + x, GY + y, v)
    for (x, y) in allp:
        for dx, dy in N4:
            q = (x + dx, y + dy)
            if q not in allp:
                c.set(GX + q[0], GY + q[1], 1)
    info = {'glyph': (GX, GY, gw, gh), 'drips': [(GX + x, GY + y) for (x, y) in drips],
            'tops': {GX + x: GY + y for x, y in tops.items()}, 'dirt_top': {}}
    for (x, y) in dirt:
        X = GX + x
        if X not in info['dirt_top'] or GY + y < info['dirt_top'][X]:
            info['dirt_top'][X] = GY + y
    return c, info


def layout():
    """[(letra, k, (x_celula, y_celula) na tela)]: canto sup. esq. da celula no enquadramento final."""
    gap1, space1, gap2 = 3, 9, 5
    w1 = [GLYPHS[ch].__getitem__(0).__len__() * 4 for ch in 'DIGDIG']
    total1 = sum(w1) + gap1 * 4 + space1
    x = 320 - total1 // 2
    out = []
    for i, ch in enumerate('DIGDIG'):
        out.append((ch, 4, (x - GX, LINE1_TOP + JITTER[i] - GY)))
        x += w1[i] + (space1 if i == 2 else gap1)
    w2 = [len(GLYPHS[ch][0]) * 5 for ch in 'GRAVES']
    total2 = sum(w2) + gap2 * 5
    x = 320 - total2 // 2
    for i, ch in enumerate('GRAVES'):
        out.append((ch, 5, (x - GX, LINE2_TOP + JITTER[6 + i] - GY)))
        x += w2[i] + gap2
    return out


def build_letters():
    cells, infos = [], []
    for i, (ch, k, pos) in enumerate(layout()):
        c, info = letter(ch, k, seed=11 + i * 7, shovel=(i == SHOVEL_LETTER))
        info['pos'] = pos
        info['ch'] = ch
        cells.append(c)
        infos.append(info)
    return cells, infos


# ------------------------------------------------------------------ pa cravada
SHOVEL_ROWS = [
    "..KKKKKKK..",
    ".KQbbbbbrK.",
    ".KbrrrrrCK.",
    "..KKbrCKK..",
    "...KbrCK...",
    "...KQrCK...",
    "...KbrCK...",
    "...KbrCK...",
    "...KbrCK...",
    "...KbCCK...",
    "...KbrCK...",
    "...KQrCK...",
    "...KbrCK...",
    "...KbrCK...",
    "..KPMMMSK..",
    "..KPMMMSK..",
    "KKKPMMMSKKK",
    "KPPMMMMMMSK",
    "KPMMMMMMMSK",
    "KPMMMMMMSSK",
    "KPMMMMMMSSK",
    "KMMMMMMSSLK",
    "KMMMMMSSSLK",
    "KMMMMSSSSLK",
]
SHOVEL_PAD = 4
SHOVEL_ENTRY_X = 13        # x do glifo do G onde a pa crava (barra de cima)


def shovel():
    """pa inclinada para a direita em degraus 2-2-2 (1 px a cada 2 linhas) com a lamina
    enterrada num montinho de terra. Pivo = centro da lamina na linha de base do montinho,
    que pousa sobre a linha de cima da terra do G."""
    from common import LEG
    H = len(SHOVEL_ROWS)
    lean = (H - 1) // 2
    w = 11 + lean + 2 * SHOVEL_PAD
    c = Canvas(w, H + 2)
    bx = SHOVEL_PAD
    for y, row in enumerate(SHOVEL_ROWS):
        off = (H - 1 - y) // 2
        for x, ch in enumerate(row):
            if ch != '.':
                c.set(bx + x + off, y, 17 if ch == 'Q' else LEG[ch])
    base = H - 1 + 1          # linha logo abaixo da ultima linha da lamina
    prof = {-3: 1, -2: 2, -1: 3, 0: 3, 1: 2, 9: 2, 10: 3, 11: 3, 12: 2, 13: 1}
    heap = {}
    for dx in range(-3, 14):
        h = prof.get(dx, 1)
        for j in range(h):
            heap[(bx + dx, base - j)] = 15
    for (x, y) in heap:
        top = (x, y - 1) not in heap
        v = 15
        if top:
            v = 16 if x < bx + 8 else 15
        if x >= bx + 12 and not top:
            v = 14
        c.set(x, y, v)
    for (x, y) in heap:
        for dx, dy in ((-1, 0), (1, 0), (0, -1)):
            q = (x + dx, y + dy)
            if q not in heap and c.get(*q) == 0:
                c.set(q[0], q[1], 1)
    pivot = (bx + 5, base)
    return c, pivot


# ------------------------------------------------------------------ gota
DRIP_W, DRIP_H = 4, 16
DRIP_PIVOT = (1, 0)           # encaixa na ponta do escorrido (pixel logo abaixo do bulbo)


def drip_frames():
    fr = []
    a = Canvas(DRIP_W, DRIP_H)
    a.rows(0, 0, [".uu.", ".uT."])
    fr.append(a)
    b = Canvas(DRIP_W, DRIP_H)
    b.rows(0, 0, [".uu.", ".uu.", ".Uu.", ".uT."])
    fr.append(b)
    d = Canvas(DRIP_W, DRIP_H)
    d.rows(0, 5, [".Uu.", ".uT."])
    fr.append(d)
    e = Canvas(DRIP_W, DRIP_H)
    e.rows(0, 11, [".u..", ".T.."])
    fr.append(e)
    return fr
