"""Icones de no da Arvore de Raizes (16x16). Contorno 01 completo, luz NO."""
import math
from common import Canvas, LEG, check_rows
from PIL import Image

ROOT = r'C:\Users\pedro\Documents\projects\dig-dig-graves'


def from_rows(rows):
    check_rows('?', rows)
    c = Canvas(16, 16)
    c.rows(0, 0, rows)
    return c


def outline(c, col=1, diag=False):
    add = []
    for y in range(c.h):
        for x in range(c.w):
            if c.px[y][x]:
                continue
            nb = [(1, 0), (-1, 0), (0, 1), (0, -1)]
            if diag:
                nb += [(1, 1), (1, -1), (-1, 1), (-1, -1)]
            if any(c.get(x + dx, y + dy) not in (None, 0) for dx, dy in nb):
                add.append((x, y))
    for x, y in add:
        c.set(x, y, col)


ICONS = {}

ICONS['N00'] = [  # Pa Velha: pa enferrujada (ferrugem em terra 15/16)
    "................",
    "...........KKKK.",
    "..........KbUUuK",
    "...........KUuK.",
    "..........KUuK..",
    "..........KUuK..",
    ".........KUuK...",
    ".........KUuK...",
    "......KKKPMSK...",
    ".....KPMuMSK....",
    "....KPuUMMSK....",
    "...KPMMuUSK.....",
    "...KPMMMSSK.....",
    "...KuMSSKK......",
    "...KPSKK........",
    "....KK..........",
]

ICONS['N01'] = [  # Visita da Vidente: bola de cristal
    "................",
    "......KKKK......",
    "....KKWEEEKK....",
    "...KEWFEEEEeK...",
    "..KEWFEEEEEEeK..",
    "..KEFEEEEEEEeK..",
    "..KEEEEEEEEEeK..",
    "..KEEEEEEEEeeK..",
    "..KeEEEEEEeeeK..",
    "...KeeEEEeeeK...",
    "....KKeeeeKK....",
    "...KKKKKKKKKK...",
    "...KrrrrCCCCK...",
    "..KrCCCCCCCCcK..",
    "..KKKKKKKKKKKK..",
    "................",
]

ICONS['N02'] = [  # Ficha do Coveiro: prancheta
    "................",
    "......KKKK......",
    "..KKKKPMMSKKKK..",
    "..KrrKKKKKKrCK..",
    "..KrOOOOOOOOCK..",
    "..KrOLLLLOOoCK..",
    "..KrOOOOOOOoCK..",
    "..KrOLLLOLLoCK..",
    "..KrOOOOOOOoCK..",
    "..KrOLLLLLOoCK..",
    "..KrOOOOOOOoCK..",
    "..KrOLLOOOOoCK..",
    "..KrooooooooCK..",
    "..KCCCCCCCCCcK..",
    "..KKKKKKKKKKKK..",
    "................",
]

ICONS['E01'] = [  # Lamina Afiada: lamina com brilho
    "..............W.",
    ".............WWW",
    "..........KKK.W.",
    ".........KMSK...",
    "........KPMSK...",
    "......KKPMMSK...",
    ".....KPPMMMSK...",
    "....KPMMMMMSK...",
    "...KPMMMMMSK....",
    "..KPMMMMMSSK....",
    "..KWMMMMSSK.....",
    ".KWMMMMSSK......",
    ".KWMMSSSK.......",
    ".KWSSKKK........",
    ".KWKK...........",
    "..K.............",
]

ICONS['E02'] = [  # Braco Firme: braco flexionado (pele 15/16/17, manga 04/05)
    "................",
    ".........KKKK...",
    "........KbbUUK..",
    "........KbUUuK..",
    "........KbUuuK..",
    ".........KbUuK..",
    "....KKKK.KbUuK..",
    "...KbbbUKKbUuK..",
    "KKKbbUUUUbbUuK..",
    "KLLbUUUUUUUUuK..",
    "KLVUUUUUUUUuuK..",
    "KVVuUUUUUUuuK...",
    "KKKKKKKKKKKK....",
    "................",
    "................",
    "................",
]

ICONS['E03'] = [  # Pa Larga
    "......KKKK......",
    ".....KbKKbK.....",
    ".....KbbbuK.....",
    "......KbuK......",
    "......KbuK......",
    "......KbuK......",
    ".KKKKKKbuKKKKKK.",
    ".KPPPPPMMMMMMSK.",
    ".KPMMMMMMMMMMSK.",
    ".KPMMMMMMMMMMSK.",
    ".KPMMMMMMMMMSSK.",
    ".KPMMMMMMMMMSSK.",
    ".KPMMMMMMMMSSSK.",
    "..KPMMMMMMSSSK..",
    "...KKKKKKKKKK...",
    "................",
]


def target():
    c = Canvas(16, 16)
    cx = cy = 7.5
    for y in range(16):
        for x in range(16):
            d = math.hypot(x - cx, y - cy)
            if d > 6.45:
                continue
            shade = (x - cx) + (y - cy) > 1.5
            if d < 1.6:
                v = 23 if not shade else 22
            elif d < 3.6:
                v = 20 if not shade else 19
            elif d < 5.1:
                v = 22 if not shade else 21
            else:
                v = 20 if not shade else 19
            c.set(x, y, v)
    outline(c)
    # flecha cravada no centro, vindo do alto a direita (haste 17, penas 22)
    shaft = [(9, 6), (10, 5), (11, 4), (12, 3)]
    feath = [(13, 1), (14, 2), (13, 2), (12, 1), (14, 3)]
    pts = shaft + feath
    for x, y in pts:
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            q = (x + dx, y + dy)
            if q not in pts and c.get(*q) in (0, None) or (q not in pts and q[1] <= 4 and c.get(*q) == 1):
                c.set(q[0], q[1], 1)
    for x, y in shaft:
        c.set(x, y, 17)
    for x, y in feath:
        c.set(x, y, 22 if (x + y) % 2 else 21)
    return c


def burst():
    c = Canvas(16, 16)
    cx = cy = 7.5
    n = 8
    for y in range(16):
        for x in range(16):
            dx, dy = x - cx, y - cy
            d = math.hypot(dx, dy)
            a = math.atan2(dy, dx) + math.pi / 2 + math.pi / 8
            t = (a / (2 * math.pi / n)) % 1.0
            tri = abs(t - 0.5) * 2  # 1 na ponta, 0 no vale
            k = int((a / (2 * math.pi / n)) % n)
            tip = 6.7 if k % 2 == 0 else 5.2
            r = 3.0 + (tip - 3.0) * tri ** 1.3
            if d > r:
                continue
            shade = dx + dy > 1.0
            if d < 2.2:
                v = 23
            elif d < 3.8:
                v = 22
            else:
                v = 21 if not shade else 17
            c.set(x, y, v)
    outline(c)
    return c


ICONS['E10'] = [  # Pisao: bota
    "................",
    "....KKKKKK......",
    "....KbbUuK......",
    "....KKKKKK......",
    "....KUuuTK......",
    "....KUuuTK......",
    "....KUuuTK......",
    "....KUuuTKKKK...",
    "....KUuuuUUUTK..",
    "....KUuuuuuuuTK.",
    "....KuuuuuuuuTK.",
    "....KKKKKKKKKKK.",
    "....KttKKKKttK..",
    "..o..KK....KK.o.",
    ".oo..........oo.",
    "................",
]

ICONS['L01'] = [  # Pavio Longo: vela comprida
    ".......KK.......",
    "......KZYK......",
    ".....KZWZYK.....",
    ".....KZWWYK.....",
    "......KZYK......",
    ".......KK.......",
    ".......KK.......",
    ".....KKKKKK.....",
    ".....KWOOoK.....",
    ".....KOOOoK.....",
    ".....KOOOoK.....",
    ".....KOOOoK.....",
    ".....KOOOoK.....",
    "....KOOOOooK....",
    "....KKKKKKKK....",
    "................",
]

ICONS['L02'] = [  # Vidro Polido: lanterna brilhando
    "................",
    "......KKKK......",
    ".Z...KyKKyK...Z.",
    "..Z.KKKKKKKK.Z..",
    "...KZZZZZZyyK...",
    "....KKKKKKKK....",
    "ZZ..KYWWWWYK..ZZ",
    "....KYWWWWYK....",
    "....KYWWWWYK....",
    "ZZ..KYZWWZYK..ZZ",
    "....KKKKKKKK....",
    "...KZZZZZZyyK...",
    "...KyyyyyyyyK...",
    "..Z.KKKKKKKK.Z..",
    ".Z............Z.",
    "................",
]

ICONS['L03'] = [  # Isca de Fogo-fatuo
    ".........K......",
    "........KeK.....",
    ".......KeEK.....",
    "......KeEEK.....",
    ".....KeEFEeK....",
    "....KeEFFEeK....",
    "...KeEFWFEEeK...",
    "...KeFWWWFEeK...",
    "..KeEFWWWFEEeK..",
    "..KeEFWWWFEEeK..",
    "..KeEEFWFEEEeK..",
    "...KeEEFEEEeK...",
    "...KeeEEEEeeK...",
    "....KKeeeeKK....",
    "......KKKK......",
    "................",
]

DROP = [
    ".....KK.........",
    "....KZYK........",
    "....KZYK........",
    "...KZYYyK.......",
    "...KZYYyK.......",
    "..KZYYYYyK......",
    ".KZWYYYYYyK.....",
    ".KZWYYYYYyK.....",
    ".KZYYYYYYyK.....",
    ".KYYYYYYyyK.....",
    "..KyYYYyyK......",
    "...KKyyKK.......",
    ".....KK.........",
    "................",
    "................",
    "................",
]
BONE_H = [
    ".KK....KK.",
    "KWOKKKKOoK",
    ".KOOOOOoK.",
    "KOoKKKKooK",
    ".KK....KK.",
]
BONE_SMALL = [
    ".KK..KK.",
    "KWOKKOoK",
    ".KOOOOK.",
    "KOoKKooK",
    ".KK..KK.",
]

ICONS['F02'] = [  # Faro de Osso: focinho farejando + osso
    "................",
    "..KKKKK.........",
    ".KbbbUUK........",
    "KbbUUUUUKKKKKKK.",
    "KbUKUUUUUUUUKLNK",
    "KUUUUUUUUUUUKNNK",
    "KTTUUUUUuuuuuKK.",
    "KTTKuuKKKKKKKK..",
    "KTTKuuuK........",
    ".KKKKKK.........",
    "................",
    ".....KK....KK...",
    "....KWOKKKKOoK..",
    ".....KOOOOOoK...",
    "....KOoKKKKooK..",
    ".....KK....KK...",
]

ICONS['F03'] = [  # Moeda Enterrada: bau
    "................",
    "................",
    "................",
    "...KKKKKKKKKK...",
    "..KrYrrrrrrYCK..",
    ".KrrYrrrrrrYrCK.",
    ".KCCYCCCCCCYCcK.",
    ".KKKKKKZZKKKKKK.",
    ".KrrYrKZyKrYrCK.",
    ".KCCYCKKKKCYCcK.",
    ".KCCYCCCCCCYCcK.",
    ".KCCYCCCCCCYCcK.",
    ".KccYccccccYccK.",
    ".KKKKKKKKKKKKKK.",
    "................",
    "................",
]

ICONS['F04'] = [  # Juros dos Mortos: moeda com caveira
    "................",
    "......KKKK......",
    "....KKZZZZKK....",
    "...KZZYYYYYyK...",
    "..KZYYKKKKKYyK..",
    "..KZYKOOOOOKyK..",
    ".KZYKOKOKoKYYyK.",
    ".KZYKOOOOoKYYyK.",
    ".KZYYKOOoKYYyyK.",
    ".KZYYYKKKYYYyyK.",
    "..KYYYYYYYYYyK..",
    "..KZYYYYYYYYyK..",
    "...KyYYYYYYyK...",
    "....KKyyyyKK....",
    "......KKKK......",
    "................",
]

ICONS['C02'] = [  # Terra Fofa: monte de terra com broto
    "................",
    "................",
    "........KK......",
    "...KK..KHHK.....",
    "..KHHK.KHhK.....",
    "..KhHhKKhK......",
    "...KKhhKK.......",
    ".....KhK........",
    "...KKKhKKK......",
    "..KbbUUUUuKK....",
    ".KbUUUUUUuuuK...",
    "KbUUUuUUUUuuuK..",
    "KUUUUUUUuUuuTTK.",
    "KuUuuuuuuuuTTTK.",
    "KKKKKKKKKKKKKKK.",
    "................",
]

ICONS['C05'] = [  # Lapides Antigas: lapide rachada com musgo
    "................",
    ".....KKKKK......",
    "...KKhhPMMKK....",
    "..KhhGPMKMMSK...",
    "..KhPMMMKMMSK...",
    "..KPMMMKMMMSK...",
    "..KPMMMKKMMSK...",
    "..KPMMMMKMSSK...",
    "..KPMMMMKMSSK...",
    "..KPMMMKMMSSK...",
    "..KhMMMKMMSSK...",
    "..KhhMMMMSSSK...",
    ".KKhhGhSSSSSKK..",
    "KhHhhGGhhGGGGhK.",
    "KKKKKKKKKKKKKKK.",
    "................",
]

ICONS['A01'] = [  # Toupeira Tita: rosto com oculos de protecao
    "................",
    ".....KKKKKK.....",
    "...KKUUUUUUKK...",
    "..KUUUUUUUUuuK..",
    ".KUKZZKUUKZZKuK.",
    ".KTZPMZTTZPMZTK.",
    ".KTZMSZTTZMSZTK.",
    ".KUKZZKUUKZZKuK.",
    ".KUUUUUUUUUUuuK.",
    ".KUUUUKXXKUUuuK.",
    ".KuUUKXXXxKuuTK.",
    "..KuUKxxxxKuTK..",
    "...KKuKKKKuKK...",
    ".....KKKKKK.....",
    "................",
    "................",
]

ICONS['A02'] = [  # Gato Breu: rosto de gato preto, olhos 26
    "................",
    "..KK........KK..",
    "..KVK......KNK..",
    "..KVNK....KNNK..",
    "..KVNNKKKKNNNK..",
    ".KVVNNNNNNNNNNK.",
    ".KVNNNNNNNNNNNK.",
    ".KVZKZNNNNZKZNK.",
    ".KNZKZNNNNZKZNK.",
    ".KNNNNNVVNNNNNK.",
    "..KNNNKNNKNNNK..",
    "...KKNNKKNNKK...",
    ".....KKKKKK.....",
    "................",
    "................",
    "................",
]

ICONS['S03'] = [  # Embaralhar: duas cartas-lapide + seta circular (alma)
    "...KKKKKKKK.....",
    "..KAAAAAAAAKK...",
    ".KKKKKKKKKKAAK..",
    "KSSSSLLK.KAAAAK.",
    "KSLLLLLK..KAAK..",
    "KSLLLKKKKKKKK...",
    "KSLLKPPMMMMMSK..",
    "KSLLKPMMSMMMSK..",
    "KSLLKPMSSSMMSK..",
    "KSLLKPMMSMMMSK..",
    "KKKKKPMMSMMMSK..",
    "..K.KPMMMMMSSK..",
    ".KAKKPMMMMSSSK..",
    "KAAAKKKKKKKKKK..",
    ".KAAAAAAAAAK....",
    "..KKKKKKKKK.....",
]


def overlay(base_rows, ov_rows, x0, y0):
    c = from_rows(base_rows)
    c.rows(x0, y0, ov_rows)
    return c


def sack():
    rows = [
        "................",
        ".....KKKKK......",
        "....KbUUUuK.....",
        ".....KTTTK......",
        "......KuK.......",
        ".....KbUuK......",
        "...KKbUUUuKK....",
        "..KbUUUUUUuuK...",
        ".KbUUUUUUUUuuK..",
        ".KbUUUUUUUuuuK..",
        ".KUUUUUUUUuuuK..",
        ".KUUUUUUUuuuuK..",
        "..KuUUUUuuuuK...",
        "...KKuuuuuKK....",
        ".....KKKKK......",
        "................",
    ]
    coin = [
        ".KKKK.",
        "KZZYYK",
        "KZYKyK",
        "KZYYyK",
        "KYyyyK",
        ".KKKK.",
    ]
    return overlay(rows, coin, 9, 9)


def stones():
    return from_rows([
        "................",
        ".........KKKK...",
        "........KSSSLK..",
        "....KKKKSSSSLLK.",
        "...KPPMMKLLLLLK.",
        "..KPMMMMSKLLLLK.",
        "..KPMKKMSKLLLLK.",
        "..KPKKKKSKLLLLK.",
        "..KPMKKMSKLLLLK.",
        "..KPMKKMSKLLLLK.",
        "..KPMMMMSKLLLVK.",
        "..KPMMMSSKLLVVK.",
        ".KHKKKKKKKKKKhGK",
        "KhHhhhGhhhhhGhhK",
        "KKKKKKKKKKKKKKKK",
        "................",
    ])


def field():
    c = Canvas(16, 16)
    # losango 2:1 (y 3..10) com laterais de terra (y 11..12)
    hw = [1, 3, 5, 7, 7, 5, 3, 1]
    for i, h in enumerate(hw):
        y = 3 + i
        for x in range(8 - h, 8 + h):
            top_left = (x < 8 and i <= 3) or (i <= 1)
            c.set(x, y, 12 if top_left and (x + i) < 9 else 11)
            if i >= 4 and x >= 8:
                c.set(x, y, 10 if x - 8 >= h - 3 else 11)
    for i, h in enumerate([8, 6, 4, 2]):
        for x in range(8 - h, 8 + h):
            y = 7 + i + 1
            # laterais: so onde nao ha topo
            pass
    # faces laterais: 2 px abaixo das arestas de baixo
    for i, h in enumerate([7, 5, 3, 1]):
        yb = 7 + i  # linha do topo
        for x in range(8 - h, 8 + h):
            for dy in (1, 2):
                if c.get(x, yb + dy) == 0:
                    c.set(x, yb + dy, 15 if x < 8 else 14)
    # setas (osso 22) apontando para fora
    for (x, y) in [(2, 6), (2, 7), (3, 5), (3, 6), (3, 7), (3, 8),
                   (13, 6), (13, 7), (12, 5), (12, 6), (12, 7), (12, 8),
                   (7, 4), (8, 4), (6, 5), (7, 5), (8, 5), (9, 5),
                   (7, 9), (8, 9), (6, 8), (7, 8), (8, 8), (9, 8)]:
        pass
    # setas: cada uma 3 px na ponta do losango
    arrows = {
        'L': [(2, 6), (2, 7), (3, 5), (3, 6), (3, 7), (3, 8)],
        'R': [(13, 6), (13, 7), (12, 5), (12, 6), (12, 7), (12, 8)],
        'U': [(7, 3), (8, 3), (6, 4), (7, 4), (8, 4), (9, 4)],
        'D': [(7, 10), (8, 10), (6, 9), (7, 9), (8, 9), (9, 9)],
    }
    for pts in arrows.values():
        for x, y in pts:
            c.set(x, y, 22)
    outline(c)
    return c


def soul_sleep():
    src = Image.open(ROOT + r'\assets\ui\icons\icons_res.png')
    c = Canvas(16, 16)
    for y in range(16):
        for x in range(16):
            c.px[y][x] = src.getpixel((32 + x, y))
    # descobre os olhos (cor 03) e fecha: tira 03 e desenha traco horizontal
    eyes = [(x, y) for y in range(16) for x in range(16) if c.px[y][x] == 3]
    for x, y in eyes:
        c.px[y][x] = 23
    ys = sorted(set(y for _, y in eyes))
    xs = sorted(set(x for x, _ in eyes))
    yb = ys[-1]
    # olhos fechados: arco de 2 px por olho, na linha de baixo
    groups = []
    for x in xs:
        if groups and x - groups[-1][-1] == 1:
            groups[-1].append(x)
        else:
            groups.append([x])
    for g in groups:
        gx = g[0]
        c.set(gx - 0 if len(g) > 1 else gx, yb, 3)
        c.set(gx + 1, yb, 3)
    # "z" 3x3 em 08 no alto a direita, sem contorno (efeito)
    z = [(11, 1), (12, 1), (13, 1), (12, 2), (11, 3), (12, 3), (13, 3)]
    # move a alma 1 px para baixo-esquerda se colidir
    for x, y in z:
        c.set(x, y, 8)
    for x, y in z:
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            if c.get(x + dx, y + dy) == 0:
                c.set(x + dx, y + dy, 1)
    return c, eyes


def build_all():
    out = {}
    for k, rows in ICONS.items():
        out[k] = from_rows(rows)
    d = from_rows(DROP)
    d.rows(6, 11, BONE_H)
    out['L04'] = d
    out['E04'] = target()
    out['E05'] = burst()
    out['F01'] = sack()
    out['C01'] = stones()
    out['C03'] = field()
    out['S01'] = soul_sleep()[0]
    return out


ORDER = ['N00', 'N01', 'N02',
         'E01', 'E02', 'E03', 'E04', 'E05', 'E10',
         'L01', 'L02', 'L03', 'L04',
         'F01', 'F02', 'F03', 'F04',
         'C01', 'C02', 'C03', 'C05',
         'A01', 'A02',
         'S01', 'S03']

NAMES = {'N00': 'Pá Velha', 'N01': 'Visita da Vidente', 'N02': 'Ficha do Coveiro',
         'E01': 'Lâmina Afiada', 'E02': 'Braço Firme', 'E03': 'Pá Larga', 'E04': 'Golpe Certeiro',
         'E05': 'Crítico Brutal', 'E10': 'Pisão', 'L01': 'Pavio Longo', 'L02': 'Vidro Polido',
         'L03': 'Isca de Fogo-fátuo', 'L04': 'Óleo de Osso', 'F01': 'Bolso Fundo', 'F02': 'Faro de Osso',
         'F03': 'Moeda Enterrada', 'F04': 'Juros dos Mortos', 'C01': 'Mais Covas', 'C02': 'Terra Fofa',
         'C03': 'Campo Maior', 'C05': 'Lápides Antigas', 'A01': 'Toupeira Tita', 'A02': 'Gato Breu',
         'S01': 'Descanso Eterno', 'S03': 'Embaralhar'}

if __name__ == '__main__':
    icons = build_all()
    sheet = Canvas(8 * 20, 4 * 20, 3)
    for i, k in enumerate(ORDER):
        sheet.blit(icons[k], 2 + (i % 8) * 20, 2 + (i // 8) * 20)
    sheet.to_rgba(6).save('icons_draft_6x.png')
    print('ok', len(ORDER))
