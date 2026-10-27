"""E/S, codificacao OGG e medicao (ffmpeg ebur128)."""
import json
import os
import re
import subprocess

import numpy as np
from scipy.io import wavfile

from dsp import SR, limiter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BUILD = os.path.join(ROOT, "audio_src", "_tools", "_build")
MUSIC = os.path.join(ROOT, "assets", "music")
SFX = os.path.join(ROOT, "assets", "sfx")
PREV = os.path.join(ROOT, "audio_src", "_previews")
os.makedirs(BUILD, exist_ok=True)


def write_wav(path, x):
    x = np.asarray(x, dtype=np.float32)
    if x.ndim == 2:
        x = x.T
    wavfile.write(path, SR, x)


def encode_ogg(wav, ogg, q=5):
    subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", wav,
                    "-c:a", "libvorbis", "-q:a", str(q), "-ar", str(SR), ogg], check=True)


def measure(path):
    r = subprocess.run(["ffmpeg", "-hide_banner", "-nostats", "-i", path, "-af",
                        "ebur128=peak=true+sample", "-f", "null", "-"],
                       capture_output=True, text=True)
    txt = r.stderr
    summ = txt[txt.rfind("Summary:"):]

    def grab(label):
        m = re.search(label + r"\s*(-?[\d.]+|-inf)", summ)
        return float(m.group(1)) if m and m.group(1) != "-inf" else float("-inf")
    return {"I": grab(r"I:"), "TP": grab(r"True peak:\s*Peak:"),
            "SP": grab(r"Sample peak:\s*Peak:")}


def decode(path):
    """Decodifica para float (ch, n) via ffmpeg."""
    r = subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-i", path,
                        "-f", "f32le", "-acodec", "pcm_f32le", "-"], capture_output=True, check=True)
    info = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "stream=channels",
                           "-of", "json", path], capture_output=True, text=True)
    ch = json.loads(info.stdout)["streams"][0]["channels"]
    x = np.frombuffer(r.stdout, dtype=np.float32)
    return x.reshape(-1, ch).T


def normalize_loop(st, target_lufs, name, ceiling=-1.5, max_iter=3):
    """Ganho estatico + limitador aplicado de forma circular (preserva a costura)."""
    n = st.shape[1]
    g = 1.0
    tmp = os.path.join(BUILD, name + "_meas.wav")
    gr = 0.0
    for _ in range(max_iter):
        y = st * g
        trip = np.concatenate([y, y, y], axis=1)
        lim, gr = limiter(trip, ceiling)
        y = lim[:, n:2 * n]
        write_wav(tmp, y)
        I = measure(tmp)["I"]
        if abs(I - target_lufs) < 0.2:
            break
        g *= 10 ** ((target_lufs - I) / 20)
    lim_full = trip[:, n:2 * n]
    ratio = np.max(np.abs(y), axis=0) / np.maximum(np.max(np.abs(lim_full), axis=0), 1e-9)
    loud = np.max(np.abs(lim_full), axis=0) > 0.05
    pct = float(np.mean(ratio[loud] < 10 ** (-1 / 20)) * 100)
    gr = -20 * np.log10(np.max(ratio[loud]))
    return y, gr, pct


def normalize_oneshot(x, target_peak_db=None, target_lufs=None, name="tmp", ceiling=-1.0):
    x = np.asarray(x, dtype=float)
    if target_lufs is not None:
        tmp = os.path.join(BUILD, name + "_meas.wav")
        g = 1.0
        for _ in range(3):
            y = x * g
            pk = np.max(np.abs(y))
            if pk > 10 ** (ceiling / 20):
                y2 = y if y.ndim == 2 else y[None]
                y2, _ = limiter(y2, ceiling)
                y = y2 if y.ndim == 2 else y2[0]
            write_wav(tmp, y)
            I = measure(tmp)["I"]
            if not np.isfinite(I) or abs(I - target_lufs) < 0.2:
                break
            g *= 10 ** ((target_lufs - I) / 20)
        return y
    pk = np.max(np.abs(x))
    return x * (10 ** (target_peak_db / 20) / pk)
