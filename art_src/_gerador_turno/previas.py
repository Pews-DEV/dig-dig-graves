"""Previas em art_src/_previews/ (mock do turno, cinza, GIFs, exploracoes da pa)."""
from PIL import Image
from common import Canvas
import pa
import cena
import kit
import mock
import font5x7 as F

PREV = r'C:\Users\pedro\Documents\projects\dig-dig-graves\art_src\_previews'


def grey(im):
    return im.convert('L').convert('RGB')


def gif(path, frames, durs, scale=4, bg=3):
    ims = []
    for f in frames:
        c = Canvas(f.w, f.h, bg)
        c.blit(f, 0, 0)
        ims.append(c.to_rgba(scale).convert('RGB'))
    ims[0].save(path, save_all=True, append_images=ims[1:], duration=durs, loop=0, disposal=1)


def on_tile(fr):
    """pa sobre um tile S0, com a ponta (3, 20) no pivo (16, 16) do tile."""
    tiles = mock.load(r'assets\tiles\a1\tiles_a1.png')
    t = mock.cell(tiles, 0, 0, 32, 24)
    c = Canvas(44, 40)
    c.blit(t, 4, 14)                  # pivo do tile em (20, 30)
    for (x, y) in [(20, 30)]:
        pass
    c.blit(fr, 20 - 3, 30 - 20)
    return c


def main():
    # mock do turno
    s = mock.scene()
    mock.area_outline(s, 5, 6)
    x, y = mock.tile_pos(5, 6)
    s.blit(pa.frames()[0][1], x - 3, y - 20)
    s.blit(cena.vignette(), 0, 0)
    mock.hud(s)
    s.to_rgba(1).save(PREV + r'\run_mock_640x360.png')
    s.to_rgba(2).save(PREV + r'\run_mock_2x.png')
    grey(s.to_rgba(2)).save(PREV + r'\run_mock_cinza_2x.png')
    # variante: oleo baixo (barra de alerta e lanterna fraca)
    s2 = mock.scene(radius=1)
    mock.area_outline(s2, 5, 6)
    s2.blit(pa.frames()[4][1], x - 3, y - 20)
    s2.blit(cena.vignette(), 0, 0)
    mock.hud(s2, oil=0.18, low=True)
    s2.to_rgba(2).save(PREV + r'\run_mock_oleo_baixo_2x.png')

    # GIFs da pa
    fr = [c for (_, c) in pa.frames()]
    gif(PREV + r'\cursor_pa24_idle_4x.gif', [on_tile(f) for f in fr[0:2]], [167, 167])
    gif(PREV + r'\cursor_pa24_act_4x.gif', [on_tile(f) for f in [fr[0]] + fr[2:7] + [fr[0]]],
        [400, 50, 50, 50, 50, 50, 400])
    # lanterna e medalha
    ln = [kit.lantern(i) for i in range(3)]
    lo = [kit.lantern(i, True) for i in range(3)]
    gif(PREV + r'\lanterna_idle_4x.gif', ln, [125] * 3)
    gif(PREV + r'\lanterna_low_4x.gif', lo, [83] * 3)
    md = [kit.medal()] + [kit.medal(sw) for sw in (6, 15, 24, 33)]
    gif(PREV + r'\medalha_nivel_4x.gif', md + [md[0]], [600, 83, 83, 84, 83, 600])

    # exploracoes da pa: A bico + T, B quadrada + D, C bico + D (escolhida)
    exp = [pa.draw_shovel('bico2', grip='T', L=19, hw=7, Lh=10, tip=(3, 20)),
           pa.draw_shovel('quadrada', grip='D', L=16, tip=(3, 20), Lh=10),
           fr[0]]
    sh = Canvas(3 * 30 + 4, 3 * 30 + 12, 3)
    for i, e in enumerate(exp):
        x0 = 4 + i * 30
        F.draw(sh, x0 + 9, 2, 'ABC'[i], 22 if i < 2 else 26)
        sh.rect(x0, 11, 26, 26, 11)          # sobre a grama
        sh.blit(e, x0 + 1, 12)
        sh.blit(e, x0 + 1, 40)               # sobre a noite
        sil = Canvas(24, 24)
        for yy in range(24):
            for xx in range(24):
                if e.px[yy][xx]:
                    sil.px[yy][xx] = 1
        sh.rect(x0, 67, 26, 26, 7)
        sh.blit(sil, x0 + 1, 68)
    sh.to_rgba(4).save(PREV + r'\cursor_pa24_exploracoes_4x.png')
    # escala 1x das exploracoes (ao lado, para o teste de leitura)
    one = Canvas(3 * 28 + 4, 28, 11)
    for i, e in enumerate(exp):
        one.blit(e, 4 + i * 28, 2)
    one.to_rgba(1).save(PREV + r'\cursor_pa24_exploracoes_1x.png')

    # pecas da cena e do kit a 4x
    pc = Canvas(300, 130, 2)
    blk, cells = cena.block_atlas()
    pc.blit(blk, 4, 2)
    fen = Canvas(96, 32)
    fen.blit(cena.fence('NO'), 0, 0)
    fen.blit(cena.fence('NE'), 32, 0)
    fen.blit(cena.fence_post(), 77, 18)
    pc.blit(fen, 4, 62)
    pc.blit(cena.tufts(), 108, 66)
    pc.blit(cena.sign_with_text(), 140, 66)
    pc.blit(cena.sign(), 200, 66)
    pc.blit(cena.star_sheet(), 270, 66)
    pc.to_rgba(4).save(PREV + r'\cena_a1_pecas_4x.png')
    kt = Canvas(232, 110, 3)
    kt.blit(kit.button_sheet(48, 24), 4, 4)
    kt.blit(kit.button_sheet(20, 20), 4, 32)
    kt.blit(kit.plaque(), 92, 32)
    kt.blit(kit.tooltip(), 130, 32)
    kt.blit(kit.tails(), 150, 36)
    kt.blit(kit.skull(), 190, 34)
    kt.blit(kit.medal_sheet(), 4, 58)
    kt.blit(kit.lantern_sheet(), 4, 84)
    kt.to_rgba(4).save(PREV + r'\ui_kit_4x.png')
    print('previas ok')


if __name__ == '__main__':
    main()
