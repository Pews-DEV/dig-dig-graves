"""Previas de SFX para o orquestrador ouvir (audio_src/_previews/).

Uso: python audio_src/preview_sfx.py id [id ...]   -> <id>_previa.ogg (variacoes em sequencia, 0,6 s entre elas)
     python audio_src/preview_sfx.py --repeat id N  -> <id>_x<N>.ogg (N disparos sorteados com pitch +-6%, 1 por 0,7 s)
     python audio_src/preview_sfx.py --splash       -> splash_briba_mus_title.ogg (splash, 0,4 s de preto, 12 s do mus_title com fade-in 0,6 s)
"""
import glob
import os
import sys

import numpy as np
from scipy.signal import resample

from common import BUILD, MUSIC, PREV, SFX, decode, encode_ogg, write_wav
from dsp import SR, secs


def variations(id_):
    return [decode(f)[0] for f in sorted(glob.glob(os.path.join(SFX, id_ + "_[0-9].ogg")))]


def save(name, x):
    wav = os.path.join(BUILD, name + ".wav")
    write_wav(wav, x)
    encode_ogg(wav, os.path.join(PREV, name + ".ogg"))
    print(name, "%.1f s" % ((x.shape[-1]) / SR))


def seq(id_):
    parts = []
    for v in variations(id_):
        parts += [v, np.zeros(secs(0.6))]
    save(id_ + "_previa", np.concatenate(parts))


def repeat(id_, n, every=0.7, seed=1):
    rng = np.random.default_rng(seed)
    vs = variations(id_)
    out = np.zeros(secs(every * n + 1.0))
    for k in range(n):
        v = vs[rng.integers(len(vs))]
        r = rng.uniform(0.94, 1.06)
        v = resample(v, int(len(v) / r))
        a = secs(every * k)
        out[a:a + len(v)] += v
    save("%s_x%d" % (id_, n), out)


def splash():
    sp = decode(os.path.join(SFX, "splash_briba_1.ogg"))[0]
    title = decode(os.path.join(MUSIC, "mus_title.ogg"))[:, :secs(12.0)].copy()
    k = secs(0.6)
    title[:, :k] *= np.linspace(0, 1, k)
    gap = np.zeros((2, secs(0.4)))
    out = np.concatenate([np.stack([sp, sp]), gap, title], axis=1)
    save("splash_briba_mus_title", out)


if __name__ == "__main__":
    a = sys.argv[1:]
    if a and a[0] == "--repeat":
        repeat(a[1], int(a[2]))
    elif a and a[0] == "--splash":
        splash()
    else:
        for i in a:
            seq(i)
