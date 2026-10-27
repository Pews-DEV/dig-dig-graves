"""Lapides do estagio 1 (`lapide`, celula 16x24, pivo (8, 23)) e icones 8x8 do tipo (tooltip).

GDD §4.6: o TIPO decide o efeito, entao ele precisa ser legivel sem texto (DA §13.1):
  0 foto oval  -> lapide alta de topo em arco, de pe e reta, com foto oval de porcelana (22/21)
  1 cruz       -> a mais alta e a mais clara (07/08), recortada em cruz
  2 musgo      -> a mais baixa e a mais escura, TORTA (inclinada para a direita), sem pedestal,
                  com o topo lascado e coberta de musgo 10/11 (o tufo da base sai da terra)
Silhuetas diferentes (arco / cruz / torta-lascada), alturas diferentes (19 / 21 / 15 px) e valor
diferente (media 07 / 08 / 06+10): passa no teste de sombra chinesa e no de cinza.
Contorno seletivo 01; sombra projetada 02 para baixo e a direita (como a lapide antiga)."""
from base1 import from_rows, hstrip

FOTO = [
    "................",
    "................",
    "................",
    "......KKKK......",
    "....KKPPMMKK....",
    "...KPPMMMMMSK...",
    "..KPPMMMMMMMSK..",
    "..KPMMOOOoMMSK..",
    "..KPMOLVVVoMSK..",
    "..KPMOVIIVoMSK..",
    "..KPMOVIIVoMSK..",
    "..KPMOVVVVoMSK..",
    "..KPMMooooMMSK..",
    "..KPMMMMMMMMSK..",
    "..KPMSSSSSSMSK..",
    "..KPMMMMMMMMSK..",
    "..KPMMSSSSMSSK..",
    "..KPMMMMMMMSSK..",
    ".KKKKKKKKKKKKKK.",
    ".KPPPPMMMMMMMSK.",
    ".KSSSSSSSSSSSLK.",
    "..KKKKKKKKKKKKNN",
    "...NNNNNNNNNNNNN",
    "................",
]

CRUZ = [
    "................",
    "......KKKK......",
    ".....KPPMSK.....",
    ".....KPPMSK.....",
    ".....KPPMSK.....",
    ".KKKKKPPMSKKKKK.",
    "KPPPPPPPPPPMMMSK",
    "KPMMMMPPMMMMMMSK",
    ".KSSSSPPMSSSSLK.",
    "..KKKKPPMSKKKKNN",
    ".....KPPMSKNNNN.",
    ".....KPPMSKN....",
    ".....KPPMSKN....",
    ".....KPPMSKN....",
    ".....KPPMSKN....",
    ".....KPPMSKN....",
    "...KKKPPMSKKK...",
    "..KPPPPPMMMMSK..",
    "..KPMMMMMMMMSK..",
    "..KPMMMMMMMSSK..",
    "..KSSSSSSSSSLK..",
    "...KKKKKKKKKKKNN",
    "....NNNNNNNNNNNN",
    "................",
]

MUSGO = [
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
    "........KKKK....",
    "......KKhhGGK...",
    ".....KhhhhGGVK..",
    ".....KhGGGSSVK..",
    "....KMGSSSSSVVK.",
    "....KMSSSSSSVVK.",
    "....KMSVVVSSVVK.",
    "...KMSSSSSSVVK..",
    "...KMSVVVSSVVK..",
    "...KMSSSSSSGVK..",
    "...KMSSSSSGhVK..",
    "..KMSSSSSSGhVK..",
    "..KMSSSSSGhhVK..",
    "..KhSSSSGGhhVKN.",
    ".KhhGKKKKKKKKKNN",
    "..KKKNNNNNNNNNN.",
    "................",
    "................",
]

ICON_FOTO = [
    "..KKKK..",
    ".KPPMMK.",
    "KPMOOMSK",
    "KPOVVoSK",
    "KPMooMSK",
    "KPMMMMSK",
    "KSSSSSSK",
    ".KKKKKK.",
]
ICON_CRUZ = [
    "...KK...",
    "..KPSK..",
    "KKKPSKKK",
    "KPPPPMSK",
    "KKKPSKKK",
    "..KPSK..",
    ".KPPMSK.",
    ".KKKKKK.",
]
ICON_MUSGO = [
    "..KKKK..",
    ".KhhGGK.",
    ".KhGGVK.",
    ".KMSSVK.",
    "KMSSVK..",
    "KMSVVK..",
    "KhGGVK..",
    "KKKKK...",
]


def lapides():
    return [from_rows(m, 16, 24) for m in (FOTO, CRUZ, MUSGO)]


def lapide_atlas():
    return hstrip(lapides())


def icons():
    return [from_rows(m, 8, 8) for m in (ICON_FOTO, ICON_CRUZ, ICON_MUSGO)]


def icon_atlas():
    return hstrip(icons())
