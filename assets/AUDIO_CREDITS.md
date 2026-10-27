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
