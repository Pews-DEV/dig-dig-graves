"""Mede todos os OGG entregues: duracao, canais, pico, true peak, LUFS integrado,
RMS maximo em 50 ms, silencio inicial e (para loops) a costura fim->inicio.
Uso: python audio_src/verify.py  -> imprime tabela markdown e grava _tools/_build/measures.json
"""
import glob
import json
import os

import numpy as np

from common import BUILD, MUSIC, SFX, decode, measure
from dsp import SR

LOOPS = {"mus_title", "mus_tree", "mus_area1", "amb_night_1", "amb_souls_choir_1",
         "mus_boss", "mus_area2", "mus_area3", "mus_area4", "mus_area5", "mus_shop"}


def rms50(x):
    m = np.max(np.abs(x), axis=0) if x.ndim == 2 else np.abs(x)
    s = np.mean(x ** 2, axis=0) if x.ndim == 2 else x ** 2
    w = int(0.05 * SR)
    if len(s) < w:
        return 10 * np.log10(np.mean(s) + 1e-12)
    c = np.convolve(s, np.ones(w) / w, mode="valid")
    return 10 * np.log10(np.max(c) + 1e-12)


def seam(x):
    """Salto na costura comparado ao salto tipico amostra-a-amostra."""
    d_all = np.abs(np.diff(x, axis=1)).max(axis=0)
    d_seam = np.abs(x[:, 0] - x[:, -1]).max()
    pct = float(np.mean(d_all < d_seam) * 100)
    w = int(0.02 * SR)
    r_end = 10 * np.log10(np.mean(x[:, -w:] ** 2) + 1e-12)
    r_beg = 10 * np.log10(np.mean(x[:, :w] ** 2) + 1e-12)
    return d_seam, pct, r_end - r_beg


def main():
    rows = []
    files = sorted(glob.glob(os.path.join(MUSIC, "*.ogg"))) + sorted(glob.glob(os.path.join(SFX, "*.ogg")))
    for f in files:
        name = os.path.splitext(os.path.basename(f))[0]
        x = decode(f)
        m = measure(f)
        pk = 20 * np.log10(np.max(np.abs(x)) + 1e-12)
        a = np.max(np.abs(x), axis=0)
        lead = np.argmax(a > 10 ** (-60 / 20)) / SR * 1000
        row = {"file": os.path.relpath(f, os.path.dirname(MUSIC)).replace("\\", "/"), "id": name,
               "dur": x.shape[1] / SR, "ch": x.shape[0], "I": m["I"], "TP": m["TP"], "peak": pk,
               "rms50": rms50(x), "lead_ms": lead}
        if name in LOOPS:
            d, pct, dr = seam(x)
            row.update(seam_jump=float(d), seam_pct=pct, seam_rms_db=float(dr))
        rows.append(row)
    with open(os.path.join(BUILD, "measures.json"), "w", encoding="utf-8") as fh:
        json.dump(rows, fh, indent=1, default=float)
    print("| arquivo | dur (s) | ch | LUFS-I | TP (dBTP) | pico (dBFS) | RMS máx 50 ms | silêncio inicial (ms) | costura |")
    print("|---|---|---|---|---|---|---|---|---|")
    for r in rows:
        sm = ""
        if "seam_jump" in r:
            sm = "salto %.4f (percentil %.1f), ΔRMS %.1f dB" % (r["seam_jump"], r["seam_pct"], r["seam_rms_db"])
        I = "%.1f" % r["I"] if r["I"] > -69 else "n/a (curto)"
        print("| %s | %.3f | %d | %s | %.1f | %.1f | %.1f | %.1f | %s |" % (
            r["file"], r["dur"], r["ch"], I, r["TP"], r["peak"], r["rms50"], r["lead_ms"], sm))


if __name__ == "__main__":
    main()
