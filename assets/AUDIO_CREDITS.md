# Créditos de Áudio — Dig Dig Graves

## Leva 1 (26/10/2026)
Todo o áudio desta leva (músicas, jingle, stingers, SFX e ambiente) foi **sintetizado do zero** pelo `sound-designer` com Python (numpy/scipy) — fontes em `audio_src/`. Não há samples, SoundFonts nem gravações de terceiros. As melodias e harmonias são originais (escritas em `audio_src/music.py`).

| Item | Origem | Licença |
|---|---|---|
| Todos os arquivos em `assets/music/` e `assets/sfx/` | Síntese própria (`audio_src/dsp.py`, `music.py`, `sfx.py`) | Propriedade do projeto |

### Ferramentas (não distribuídas com o jogo)
| Ferramenta | Uso | Licença |
|---|---|---|
| Python 3.14, numpy, scipy | Síntese e DSP | PSF / BSD-3 |
| mido | (instalado; não usado nesta leva) | MIT |
| FFmpeg 9 + libvorbis | Codificação OGG Vorbis e medição EBU R128 | LGPL/GPL (ferramenta) · BSD (libvorbis) |
| matplotlib | Espectrogramas para revisão | PSF-like |

## Leva 2 — tela-título (27/10/2026)
`mus_title`, `logo_land`, `logo_thunk`, `logo_drip`, `amb_souls_choir`, `ui_wisp_slide` e `ui_bury` também foram **sintetizados do zero** (`audio_src/music.py` → `build_title`; `audio_src/sfx.py`). Melodia original; nenhum sample, SoundFont ou gravação de terceiros. Mesmas ferramentas da leva 1.
