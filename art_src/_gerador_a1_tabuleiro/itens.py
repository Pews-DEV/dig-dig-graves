"""Elementos de tabuleiro do estagio 1 (GDD §4.8) e chave da cripta 1.

vela_campo      32x24, pivo (16, 16): vela de Finados DENTRO do tile (tile bloqueado). Desenhada no
                lugar do tile de solo (como a rocha): grama do S0 v1 + terra batida com pingos de
                cera, pote de vela de sete dias e 2 velinhas. `idle` 3f 8 fps (so as chamas mudam).
vela_campo_halo 64x32, pivo (32, 16) = pivo do tile da vela: anel de luz em xadrez 25/24 sobre os
                vizinhos (DA §4.3: halo grande = sprite separado em xadrez, nunca alfa).
moeda_ouro      8x8, pivo (4, 4): `spin` 4f 10 fps (loop), `pop` 3f (pegou).
icon_key_1      16x16 e 32x32: chave antiga com caveira (DA §10.2, 06/07/08), fita verde da
                Paroquia (11/12) e UM dente no palhetao (= estagio 1). `spin` 4f 8 fps."""
from base1 import Canvas, from_rows, load, cell, flip_h, DIAMOND, in_diamond

# ============================================================== vela de Finados no tile
FLAMES = [  # 3x4, base (1, 3) = pavio; cores: Y 25, Z 26, W 23
    ["...", ".Y.", "YZY", "YWY"],
    [".Y.", ".YZ", "YWZ", ".W."],
    ["...", "...", "YWZ", "ZWY"],
]
FLAMES_SMALL = [  # 3x3 para as velinhas
    [".Y.", "YZY", ".W."],
    ["..Y", ".ZY", ".W."],
    ["...", "YWZ", ".W."],
]

JAR = [  # pote de vela de sete dias, 8x9 (x 12-19, y 10-18)
    ".KKKKKK.",
    "KWZZZYoK",
    "KWOZYOoK",
    "KWOOOOoK",
    "KWyyyyyK",
    "KWOOOOoK",
    "KOOOOOoK",
    "KoOOOooK",
    ".KKKKKK.",
]
CANDLE_L = [  # velinha alta 4x7 (x 7-10, y 12-18)
    ".KK.",
    "KWOK",
    "KOoK",
    "KOoK",
    "KOoK",
    "KOoK",
    "KKKK",
]
CANDLE_R = [  # velinha baixa 4x5 (x 21-24, y 14-18)
    ".KK.",
    "KWOK",
    "KOoK",
    "KOoK",
    "KKKK",
]


def _stamp(c, rows, x0, y0):
    for j, r in enumerate(rows):
        for i, ch in enumerate(r):
            if ch != '.':
                from base1 import LEG
                c.set(x0 + i, y0 + j, LEG[ch])


def vela_campo_base():
    t = cell(load('assets/tiles/a1/tiles_a1.png'), 0, 0)
    # tira os tufos da folga de cima perto do centro (a chama ocupa essa folga)
    # terra batida em volta (losango interno 15 com borda de luz 16 do lado da lua) + pingos de cera
    for (x, y) in DIAMOND:
        sx, sy = x + 0.5 - 16, y + 0.5 - 17
        d = abs(sx) / 12 + abs(sy) / 6       # losango 2:1 (degraus 2-2-2)
        if d <= 1:
            t.set(x, y, 16 if (d > 0.7 and (sx < 0 and sy < 0)) else 15)
        elif d <= 1.25 and t.get(x, y) in (11, 12):
            t.set(x, y, 10)
    for (x, y) in ((6, 18), (11, 20), (20, 19), (26, 17), (13, 19)):
        t.set(x, y, 21)
    # sombras das velas (09 = sombra na grama/terra), para baixo e a direita (lua NO)
    for (x, y) in ((20, 18), (21, 18), (20, 19), (25, 18), (11, 18)):
        t.set(x, y, 14 if t.get(x, y) in (15, 16) else 9)
    _stamp(t, JAR, 12, 10)
    _stamp(t, CANDLE_L, 7, 12)
    _stamp(t, CANDLE_R, 21, 14)
    return t


def vela_campo_frames():
    out = []
    for f in range(3):
        c = vela_campo_base()
        _stamp(c, FLAMES[f], 14, 6)                       # chama do pote (sobre o pavio em x 15)
        _stamp(c, FLAMES_SMALL[(f + 1) % 3], 7, 9)        # velinha alta, defasada 1 frame
        _stamp(c, FLAMES_SMALL[(f + 2) % 3], 21, 11)      # velinha baixa, defasada 2 frames
        out.append(c)
    return out


def vela_halo():
    """64x32, centro (32, 16). Anel de luz iso (2:1) em xadrez esparso: 25 perto, 24 longe.
    O miolo (o proprio tile da vela) fica vazio."""
    c = Canvas(64, 32)
    for y in range(32):
        for x in range(64):
            dx, dy = (x + 0.5 - 32) / 31.0, (y + 0.5 - 16) / 15.5
            d = abs(dx) + abs(dy)                           # losango iso (mesmo desenho do campo)
            if not (0.58 <= d <= 0.98):
                continue
            if y % 2 or (x + 2 * (y // 2)) % 4:
                continue                                   # xadrez esparso: 1 px a cada 4, linhas alternadas
            c.set(x, y, 25 if d < 0.76 else 24)
    return c


# ============================================================== moeda de ouro
COIN_SPIN = [
    ["..KKKK..",
     ".KWZZZK.",
     "KWZZZZYK",
     "KZZZYZYK",
     "KZZYYYyK",
     "KZZZYZyK",
     ".KYYYyK.",
     "..KKKK.."],
    ["..KKKK..",
     ".KWZZYK.",
     ".KWZZYK.",
     ".KZZYYK.",
     ".KZYYyK.",
     ".KZZYyK.",
     ".KYYyyK.",
     "..KKKK.."],
    ["...KK...",
     "..KZYK..",
     "..KZYK..",
     "..KZYK..",
     "..KZyK..",
     "..KZyK..",
     "..KYyK..",
     "...KK..."],
    ["..KKKK..",
     ".KWZZYK.",
     ".KZZZYK.",
     ".KZZZYK.",
     ".KZZZyK.",
     ".KZZYyK.",
     ".KYYyyK.",
     "..KKKK.."],
]
COIN_POP = [
    ["..KKKK..",
     ".KWWWWK.",
     "KWWWWWZK",
     "KWWWWWZK",
     "KWWWWZZK",
     "KWWWZZZK",
     ".KZZZZK.",
     "..KKKK.."],
    ["Z..W..Z.",
     ".Z.W.Z..",
     "..ZWZ...",
     "WWW.WWW.",
     "..ZWZ...",
     ".Z.W.Z..",
     "Z..W..Z.",
     "........"],
    ["Y......Y",
     "........",
     "........",
     "...Z....",
     "....Z...",
     "........",
     "........",
     "Y......Y"],
]


def coin_frames():
    return [from_rows(m, 8, 8) for m in COIN_SPIN] + [from_rows(m, 8, 8) for m in COIN_POP]


# ============================================================== chave da cripta 1 (16x16)
KEY16 = [
    ["......KKKK......",
     "....KKPPMMKK....",
     "...KPPMMMMMSK...",
     "...KPKKMMKKSK...",
     "...KPKKMMKKSK...",
     "...KPMMSMMMSK...",
     "....KMSMSMSK....",
     ".....KKMSKK.....",
     "....KHKMSKhK....",
     "...KHhKMSKhGK...",
     "....KKKMSKKK....",
     "......KMSK......",
     "......KMSKKK....",
     "......KMSMSK....",
     "......KMSKKK....",
     ".......KK......."],
    ["......KKK.......",
     ".....KPPMKK.....",
     "....KPMMMSK.....",
     "....KPKMKSK.....",
     "....KPKMKSK.....",
     "....KMMSMSK.....",
     ".....KMSMK......",
     "......KMSK......",
     ".....KHMSKK.....",
     "....KHhMShK.....",
     ".....KKMSKK.....",
     "......KMSK......",
     "......KMSKK.....",
     "......KMSSK.....",
     "......KMSKK.....",
     ".......KK......."],
    [".......KK.......",
     "......KPSK......",
     "......KPSK......",
     "......KPSK......",
     "......KPSK......",
     "......KPSK......",
     "......KPSK......",
     ".......KK.......",
     "......KhGK......",
     "......KhGK......",
     ".......KK.......",
     "......KMSK......",
     "......KMSK......",
     "......KMSK......",
     "......KMSK......",
     ".......KK......."],
    [".......KKK......",
     ".....KKPMMK.....",
     ".....KPMMMSK....",
     ".....KPMMMSK....",
     ".....KPMMMSK....",
     ".....KPMMSSK....",
     "......KMMSK.....",
     "......KMSK......",
     ".....KKMShK.....",
     ".....KhMShGK....",
     ".....KKMSKK.....",
     "......KMSK......",
     ".....KKMSK......",
     ".....KMMSK......",
     ".....KKMSK......",
     ".......KK......."],
]


def key16_frames():
    return [from_rows(m, 16, 16) for m in KEY16]


# ============================================================== chave da cripta 1 (32x32, Resumo)
def _key32(s, back=False):
    """Desenha a chave 32x32 com largura escalada por s (giro no eixo vertical).
    Materiais: 'm' metal/pedra (06/07/08, sombreado por coluna: luz a esquerda), 'f' fita
    (10/11/12), 'k' detalhe 01 (orbitas, dentes). Contorno 01 completo em volta."""
    W = H = 32
    cx = 15.5
    mat = [[None] * W for _ in range(H)]

    def put(x, y, m):
        if 0 <= x < W and 0 <= y < H:
            mat[y][x] = m

    # cranio (elipse) + mandibula
    rx, ry, cy = max(1.0, 8.0 * s), 7.0, 9.0
    for y in range(H):
        for x in range(W):
            dx, dy = (x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry
            if abs(dx) ** 2.6 + abs(dy) ** 2.6 <= 1.0:      # superelipse: cranio "quadradinho"
                put(x, y, 'm')
            if 14 <= y <= 17 and abs(x + 0.5 - cx) <= max(1.0, 5.0 * s):
                put(x, y, 'm')
    if not back and s > 0.3:
        for side in (-1, 1):
            ex = cx + side * 3.5 * s
            for y in range(7, 12):
                for x in range(W):
                    dx, dy = (x + 0.5 - ex) / max(0.8, 2.0 * s), (y + 0.5 - 9.5) / 2.5
                    if dx * dx + dy * dy <= 1.0:
                        put(x, y, 'k')
        put(int(cx), 12, 'k') if s < 0.8 else (put(15, 12, 'k'), put(16, 12, 'k'))
        # dentes: risquinhos 01 na mandibula
        for x in range(W):
            if mat[16][x] == 'm' and (x - 13) % 2 == 0 and abs(x + 0.5 - cx) < 4.5 * s:
                put(x, 16, 'k')
    # haste
    hw = max(1.0, 1.5 * s)
    for y in range(17, 31):
        for x in range(W):
            if abs(x + 0.5 - cx) <= hw:
                put(x, y, 'm')
    # palhetao com UM dente (estagio 1): para a direita de frente, para a esquerda de costas
    if s > 0.3:
        d = -1 if back else 1
        x0 = cx + d * hw
        ln = 6.0 * s
        for y in range(24, 27):
            for x in range(W):
                t = (x + 0.5 - x0) * d
                if 0 <= t <= ln:
                    put(x, y, 'm')
        for y in range(27, 30):
            for x in range(W):
                t = (x + 0.5 - x0) * d
                if ln - max(1.0, 3.0 * s) <= t <= ln:
                    put(x, y, 'm')
    # fita verde da Paroquia (laco) logo abaixo do cranio
    for y in range(19, 23):
        for x in range(W):
            t = abs(x + 0.5 - cx)
            if (y in (19, 22) and hw < t <= hw + 3.5 * s) or (y in (20, 21) and hw < t <= hw + 4.5 * s):
                put(x, y, 'f')
    if s <= 0.3:
        for y in range(19, 23):
            put(int(cx) + (1 if y % 2 else 0), y, 'f')
    # cor
    c = Canvas(W, H)
    for y in range(H):
        xs = [x for x in range(W) if mat[y][x] in ('m', 'k')]
        fs = [x for x in range(W) if mat[y][x] == 'f']
        for x in range(W):
            m = mat[y][x]
            if m is None:
                continue
            if m == 'k':
                c.set(x, y, 1)
            elif m == 'm':
                # sombreado pela posicao na fileira de metal contigua
                l = x
                while l - 1 >= 0 and mat[y][l - 1] in ('m', 'k'):
                    l -= 1
                r = x
                while r + 1 < W and mat[y][r + 1] in ('m', 'k'):
                    r += 1
                n = r - l + 1
                k = (x - l) / max(1, n - 1) if n > 1 else 0.3
                v = 8 if (k < 0.3 and n > 2) else (6 if k > 0.72 else 7)
                if n <= 2:
                    v = 8 if x == l else 6
                c.set(x, y, v)
            else:
                c.set(x, y, 12 if y == 19 else (11 if y < 22 else 10))
        del xs, fs
    # contorno 01 completo
    o = Canvas(W, H)
    for y in range(H):
        for x in range(W):
            if c.px[y][x]:
                o.px[y][x] = c.px[y][x]
            elif any(c.get(x + a, y + b) for a, b in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                o.px[y][x] = 1
    return o


def key32_frames():
    return [_key32(1.0), _key32(0.6), _key32(0.18), _key32(0.6, back=True)]
