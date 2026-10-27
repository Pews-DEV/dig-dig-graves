"""Dig Dig Graves - efeitos sonoros sintetizados (mono, 44.1 kHz).

Uso:  python audio_src/sfx.py [id ...]
Cada gerador recebe um rng semeado e devolve uma variacao. Tudo e sintese propria.
"""
import os
import sys

import numpy as np

from dsp import SR, midi_hz, bp, exp_decay, fade, hp, lp, onepole, secs, sweep_bp, peak
from common import BUILD, SFX, encode_ogg, measure, write_wav


# ------------------------------------------------------------------ blocos

def buf(d):
    return np.zeros(secs(d))


def put(dst, x, t, g=1.0):
    a = secs(t)
    b = min(len(dst), a + len(x))
    if b > a:
        dst[a:b] += x[:b - a] * g


def noise(rng, d):
    return rng.normal(0, 1, secs(d))


def perc_env(n, att, t60):
    e = exp_decay(n, t60)
    a = max(1, secs(att))
    e[:a] *= np.linspace(0.15, 1, a)
    return e


def modal(rng, freqs, amps, t60s, d, jitter=0.0):
    n = secs(d)
    t = np.arange(n) / SR
    out = np.zeros(n)
    for f, a, tt in zip(freqs, amps, t60s):
        f = f * (1 + rng.uniform(-jitter, jitter))
        if f < SR * 0.45:
            out += a * np.sin(2 * np.pi * f * t + rng.uniform(0, 0.3)) * exp_decay(n, tt)
    return out


def thump(f0, f1, d, t60, tau=0.02):
    n = secs(d)
    t = np.arange(n) / SR
    f = f1 + (f0 - f1) * np.exp(-t / tau)
    return np.sin(np.cumsum(2 * np.pi * f / SR)) * exp_decay(n, t60)


def sweep_tone(f0, f1, d, t60=None, curve="exp"):
    n = secs(d)
    t = np.arange(n) / SR
    f = f0 * (f1 / f0) ** (t / d) if curve == "exp" else f0 + (f1 - f0) * t / d
    x = np.sin(np.cumsum(2 * np.pi * f / SR))
    return x * (exp_decay(n, t60) if t60 else 1)


def grain(rng, d, lo, hi, t60=None):
    x = bp(noise(rng, d), lo, hi)
    n = len(x)
    return x * perc_env(n, 0.001, t60 or d * 0.6)


def click(rng, d=0.003, lo=2500):
    x = hp(noise(rng, d), lo)
    return x * np.linspace(1, 0, len(x))


def creak(rng, d, rate0, rate1, res, lpf=900, jitter=0.25):
    """Atrito 'stick-slip': trem de pulsos com taxa variando, filtrado por ressonancias de madeira."""
    n = secs(d)
    out = np.zeros(n)
    t = 0.0
    while t < d:
        frac = t / d
        rate = rate0 + (rate1 - rate0) * frac
        rate *= 1 + rng.uniform(-jitter, jitter)
        i = secs(t)
        if i < n:
            out[i] += rng.uniform(0.6, 1.0)
        t += 1.0 / max(rate, 5)
    y = sum(g * peak(out, f, q) for f, q, g in res)
    y = lp(y, lpf)
    return y / (np.max(np.abs(y)) + 1e-9)


def chime(rng, f, d, amp=1.0, ratios=(1, 2.76, 5.4), amps=(1, 0.35, 0.12), t60=0.6):
    return modal(rng, [f * r for r in ratios], [a * amp for a in amps],
                 [t60, t60 * 0.4, t60 * 0.2], d)


def coin(rng, f0, d=0.35, amp=1.0):
    x = modal(rng, [f0, f0 * 1.52, f0 * 2.33, f0 * 3.07], [1, 0.6, 0.35, 0.2],
              [0.32, 0.22, 0.13, 0.08], d, jitter=0.01)
    put(x, click(rng, 0.002, 4000), 0, 0.6)
    return x * amp


def sparkle(rng, d, n_pings=6, lo=4000, hi=8000, amp=0.15):
    out = buf(d)
    for _ in range(n_pings):
        f = rng.uniform(lo, hi)
        put(out, modal(rng, [f], [1], [0.06], 0.1), rng.uniform(0, d - 0.1), amp * rng.uniform(0.4, 1))
    return out


# ------------------------------------------------------------------ geradores

def dig_grass(rng):
    d = 0.22
    x = buf(d)
    for _ in range(rng.integers(7, 11)):
        put(x, grain(rng, rng.uniform(0.012, 0.035), 2200, 7500), rng.uniform(0, 0.12), rng.uniform(0.3, 0.8))
    put(x, thump(170, 75, 0.12, 0.06) * 0.35, 0.0)
    put(x, grain(rng, 0.05, 500, 1600, 0.03) * 0.5, 0.0)
    return x


def dig_dirt(rng):
    d = 0.28
    x = buf(d)
    put(x, thump(rng.uniform(150, 175), rng.uniform(55, 65), 0.2, 0.09) * 1.0, 0)
    put(x, lp(noise(rng, 0.12), 900) * perc_env(secs(0.12), 0.002, 0.06) * 0.9, 0)
    for _ in range(rng.integers(3, 6)):
        put(x, grain(rng, 0.015, 1500, 4000), rng.uniform(0.02, 0.13), rng.uniform(0.05, 0.14))
    return x


def dig_clay(rng):
    d = 0.32
    x = buf(d)
    put(x, thump(rng.uniform(120, 140), 55, 0.18, 0.08) * 0.8, 0)
    put(x, bp(noise(rng, 0.06), 300, 2500) * perc_env(secs(0.06), 0.001, 0.04) * 0.9, 0)
    sq = noise(rng, 0.22)
    sq = sweep_bp(sq, rng.uniform(1600, 2000), rng.uniform(420, 520), q=5)
    env = np.minimum(np.arange(len(sq)) / secs(0.03), 1) * exp_decay(len(sq), 0.16)
    put(x, sq * env * 1.2, 0.015)
    for _ in range(rng.integers(2, 4)):
        f0 = rng.uniform(260, 380)
        put(x, sweep_tone(f0, f0 * 2.2, 0.03, 0.04) * 0.18, rng.uniform(0.06, 0.2))
    return x


def dig_coffin(rng):
    d = 0.5
    x = buf(d)
    b = rng.uniform(180, 205)
    put(x, modal(rng, [b, b * 2.31, b * 3.86, b * 5.62], [1, 0.6, 0.35, 0.18], [0.26, 0.16, 0.09, 0.05], d), 0)
    put(x, modal(rng, [rng.uniform(90, 100)], [0.6], [0.3], d), 0)
    put(x, grain(rng, 0.012, 1000, 5000, 0.006) * 0.8, 0)
    put(x, lp(noise(rng, 0.08), 700) * perc_env(secs(0.08), 0.001, 0.04) * 0.3, 0)
    return x


def dig_rock(rng):
    d = 0.4
    x = buf(d)
    k = rng.uniform(0.93, 1.07)
    put(x, modal(rng, [2150 * k, 3480 * k, 5230 * k, 7100 * k], [1, 0.55, 0.3, 0.15], [0.26, 0.17, 0.1, 0.06], d, 0.01), 0)
    put(x, click(rng, 0.003, 3000) * 1.2, 0)
    put(x, modal(rng, [rng.uniform(280, 330)], [0.5], [0.05], 0.1), 0)
    put(x, grain(rng, 0.08, 2000, 6000, 0.05) * 0.12, 0.01)
    return x


def layer_break(rng):
    d = 0.55
    x = buf(d)
    put(x, thump(rng.uniform(115, 130), 45, 0.35, 0.18) * 1.0, 0)
    put(x, lp(noise(rng, 0.2), 2000) * perc_env(secs(0.2), 0.001, 0.12) * 0.8, 0)
    put(x, bp(noise(rng, 0.05), 800, 4000) * perc_env(secs(0.05), 0.001, 0.03) * 0.6, 0.005)
    for i in range(rng.integers(14, 20)):
        t = 0.04 + rng.uniform(0, 0.38) ** 1.3
        put(x, grain(rng, rng.uniform(0.01, 0.03), 800, 4000), t, rng.uniform(0.08, 0.25) * (1 - t / 0.6))
    for _ in range(rng.integers(3, 6)):
        put(x, modal(rng, [rng.uniform(1500, 3200)], [1], [0.025], 0.05) * 0.12, rng.uniform(0.08, 0.4))
    return x


def pickup_copper(rng, i):
    d = 0.4
    x = buf(d)
    f0 = [2450, 2600, 2750, 2900][i % 4]
    put(x, coin(rng, f0), 0)
    put(x, coin(rng, f0 * 1.26, 0.3, 0.45), 0.045)
    return x


def pickup_bone(rng, i):
    d = 0.32
    x = buf(d)
    f0 = [720, 780, 840, 900][i % 4]

    def tok(f, a):
        y = modal(rng, [f, f * 3.95, f * 9.9], [1, 0.3, 0.08], [0.15, 0.05, 0.02], 0.2)
        put(y, grain(rng, 0.004, 1500, 6000, 0.002), 0, 0.4)
        return y * a
    put(x, tok(f0, 1.0), 0)
    put(x, tok(f0 * 1.335, 0.7), 0.06)
    return x


def pickup_soul(rng, i):
    d = 0.75
    n = secs(d)
    t = np.arange(n) / SR
    x = np.zeros(n)
    base = [1760, 1865, 1976, 2093][i % 4]
    for r, a in [(1, 1.0), (1.5, 0.5), (2.0, 0.35)]:
        for det in (-0.004, 0.0, 0.005):
            f = base * r * (1 + det) * 2 ** (1.5 * t / d / 12)
            x += a * np.sin(np.cumsum(2 * np.pi * f / SR) + rng.uniform(0, 6))
    env = np.minimum(t / 0.02, 1) * np.exp(-6.9 * t / 0.7) * (1 + 0.25 * np.sin(2 * np.pi * 11 * t))
    x = x * env / 6
    x += sparkle(rng, d, 7, 4500, 9000, 0.12)
    x += hp(noise(rng, d), 6000) * env * 0.03
    return x


def wisp_collect(rng, i):
    d = 0.65
    n = secs(d)
    t = np.arange(n) / SR
    fl = bp(noise(rng, d), 300, 1500)
    flutter = 1 + 0.5 * onepole(rng.normal(0, 1, n), 20) * 6
    env = np.minimum(t / 0.04, 1) ** 0.5 * np.exp(-6.9 * t / 0.4)
    x = fl * env * np.clip(flutter, 0.2, 2) * 0.5
    f = [1480, 1568, 1661, 1760][i % 4]
    x += chime(rng, f, d, 0.7, t60=0.5) + chime(rng, f * 1.5, d, 0.4, t60=0.4)
    x[secs(0.05):] += sparkle(rng, d - 0.05, 6, 3500, 8000, 0.15)
    return x


def oil_tick(rng, i):
    d = 0.16
    x = buf(d)
    hi = [3200, 2700, 3000][i % 3]
    put(x, click(rng, 0.002, 2500) * 0.8, 0)
    put(x, modal(rng, [hi, hi * 0.5, hi * 1.6], [1, 0.6, 0.25], [0.03, 0.045, 0.02], 0.1), 0)
    put(x, modal(rng, [rng.uniform(480, 540)], [0.5], [0.05], 0.1), 0)
    fl = lp(noise(rng, 0.14), 600) * (1 + 0.8 * np.sin(2 * np.pi * 16 * np.arange(secs(0.14)) / SR))
    put(x, fl * perc_env(secs(0.14), 0.01, 0.1) * 0.25, 0.005)
    return x


def oil_out(rng, i):
    d = 1.15
    x = buf(d)
    n = secs(0.45)
    blow = sweep_bp(noise(rng, 0.45), 2600, 550, q=1.4)
    env = np.minimum(np.arange(n) / secs(0.03), 1) * exp_decay(n, 0.32)
    put(x, blow * env * 1.0, 0)
    n2 = secs(0.95)
    t = np.arange(n2) / SR
    rate = 12 - 8 * t / 0.95
    am = 0.5 + 0.5 * np.sin(np.cumsum(2 * np.pi * rate / SR))
    flame = lp(noise(rng, 0.95), 450) * am * np.exp(-6.9 * t / 0.8)
    put(x, flame * 1.6, 0.05)
    for _ in range(rng.integers(3, 6)):
        put(x, grain(rng, 0.006, 1500, 5000, 0.004) * 0.25, rng.uniform(0.1, 0.6))
    put(x, thump(140, 70, 0.1, 0.05) * 0.2, 0.62 + rng.uniform(-0.05, 0.05))
    return x


def grave_open(rng, i):
    d = 1.35
    x = buf(d)
    res = [(140, 9, 1.0), (230, 8, 0.8), (360, 7, 0.5)]
    r0, r1 = [(30, 55), (40, 28), (26, 48)][i % 3]
    c = creak(rng, 0.85, r0, r1, res, lpf=700)
    env = np.minimum(np.arange(len(c)) / secs(0.02), 1)
    env *= 0.7 + 0.3 * np.sin(np.linspace(0, np.pi, len(c)))
    put(x, c * env, 0)
    # tampa assentando: baque de madeira grave + terra escorrendo
    tt = 0.86 + rng.uniform(-0.04, 0.04)
    put(x, modal(rng, [85, 170, 260], [1, 0.5, 0.25], [0.25, 0.15, 0.08], 0.4) * 0.8, tt)
    put(x, lp(noise(rng, 0.3), 800) * perc_env(secs(0.3), 0.005, 0.2) * 0.35, tt)
    put(x, lp(noise(rng, 0.9), 1200) * np.linspace(0.12, 0.0, secs(0.9)) ** 2 * 0.6, 0.0)
    return x


def ui_hover(rng, i):
    f = [1850, 1950, 2050][i % 3]
    x = modal(rng, [f, f * 2.2], [1, 0.25], [0.025, 0.012], 0.05)
    put(x, click(rng, 0.0015, 3000), 0, 0.15)
    return x


def ui_click(rng, i):
    f = [820, 870, 920][i % 3]
    x = modal(rng, [f, f * 2.6, f * 4.1], [1, 0.4, 0.15], [0.055, 0.03, 0.015], 0.1)
    put(x, grain(rng, 0.004, 1500, 6000, 0.002), 0, 0.5)
    return x


def ui_panel_open(rng, i):
    d = 0.24
    n = secs(0.17)
    t = np.arange(n) / SR
    env = (0.25 + 0.75 * np.sin(np.pi * t / 0.17 * 0.9) ** 0.7) * np.exp(-t / 0.4)
    sl = bp(noise(rng, 0.17), 1200, 5500) * env
    sl += bp(noise(rng, 0.17), 300, 1200) * env * 0.4
    x = buf(d)
    put(x, sl * 0.6, 0)
    for _ in range(4):
        put(x, grain(rng, 0.01, 2500, 7000) * 0.12, rng.uniform(0.01, 0.15))
    put(x, modal(rng, [600 + 40 * i, 1500 + 80 * i], [1, 0.3], [0.05, 0.03], 0.08) * 0.7, 0.155)
    return x


def ui_panel_close(rng, i):
    d = 0.16
    n = secs(0.1)
    t = np.arange(n) / SR
    env = np.exp(-t / 0.05)
    x = buf(d)
    put(x, bp(noise(rng, 0.1), 1000, 4500) * env * 0.5, 0)
    put(x, modal(rng, [480 + 30 * i, 1250], [1, 0.3], [0.05, 0.025], 0.08) * 0.8, 0.075)
    return x


def ui_count_tick(rng, i):
    f = [2500, 2640, 2790][i % 3]
    x = modal(rng, [f, f * 2.0], [1, 0.15], [0.012, 0.006], 0.022)
    put(x, click(rng, 0.001, 4000), 0, 0.1)
    return x


def node_buy(rng, i):
    d = 0.5
    x = buf(d)
    p = sweep_tone(900 * (1 + 0.04 * i), 230, 0.06, 0.08)
    put(x, p * 1.0, 0)
    for k, (tt, a) in enumerate([(0.05, 0.55), (0.1, 0.4), (0.16, 0.3)]):
        put(x, coin(rng, rng.uniform(2500, 3000), 0.3, a), tt + rng.uniform(-0.01, 0.01))
    return x


def root_grow(rng, i):
    d = 0.45
    x = buf(d)
    ts = np.sort(0.38 * (1 - np.sqrt(rng.uniform(0, 1, rng.integers(7, 11)))))[::-1]
    ts = 0.38 - ts  # acelerando
    for tt in ts:
        f = rng.uniform(700, 2400)
        put(x, modal(rng, [f, f * 2.1], [1, 0.3], [0.02, 0.01], 0.04) * rng.uniform(0.2, 0.5), tt)
        put(x, grain(rng, 0.006, 1000, 5000, 0.004) * 0.25, tt)
    n = secs(0.4)
    t = np.arange(n) / SR
    rustle = bp(noise(rng, 0.4), 500, 3000) * np.sin(np.pi * t / 0.4) ** 1.5
    put(x, rustle * 0.15, 0)
    c = creak(rng, 0.35, 22, 40, [(180, 6, 1), (320, 6, 0.6)], lpf=900)
    put(x, c * 0.5 * np.sin(np.pi * np.arange(len(c)) / len(c)), 0.02)
    put(x, thump(160, 90, 0.06, 0.04) * 0.4, 0)
    return x


def node_reveal(rng, i):
    d = 0.6
    x = buf(d)
    n = secs(0.2)
    t = np.arange(n) / SR
    put(x, bp(noise(rng, 0.2), 600, 3500) * (0.2 + 0.8 * t / 0.2) * 0.3, 0)
    put(x, sweep_tone(280, 720, 0.07, 0.07) * 0.7, 0.17)
    f = [2093, 2349][i % 2]
    put(x, chime(rng, f, 0.38, 0.5, t60=0.3), 0.21)
    put(x, chime(rng, f * 1.5, 0.35, 0.3, t60=0.25), 0.25)
    put(x, sparkle(rng, 0.3, 4, 5000, 9000, 0.08), 0.22)
    return x


def level_up(rng, i):
    d = 0.75
    x = buf(d)
    for k, m in enumerate([81, 85, 88]):
        f = 440 * 2 ** ((m - 69) / 12)
        put(x, chime(rng, f, 0.6, 0.7 + 0.1 * k, t60=0.5), 0.07 * k)
    put(x, sparkle(rng, 0.45, 6, 4000, 9000, 0.1), 0.15)
    return x


def screen_transition(rng, i):
    d = 0.5
    x = buf(d)
    put(x, bp(noise(rng, 0.07), 1000, 3500) * perc_env(secs(0.07), 0.002, 0.06) * 0.7, 0)
    put(x, thump(130, 70, 0.08, 0.05) * 0.35, 0)
    n = secs(0.18)
    t = np.arange(n) / SR
    w = sweep_bp(noise(rng, 0.18), 400, 1500, q=1.5) * np.sin(np.pi * t / 0.18) ** 2
    put(x, w * 0.8, 0.05)
    for _ in range(rng.integers(22, 30)):
        tt = 0.2 + rng.uniform(0, 0.22) ** 1.2
        put(x, grain(rng, rng.uniform(0.008, 0.02), 700, 4000), tt, rng.uniform(0.1, 0.3) * (1 - (tt - 0.2) / 0.35))
    put(x, lp(noise(rng, 0.15), 600) * perc_env(secs(0.15), 0.003, 0.08) * 0.5, 0.21)
    return x


# ------------------------------------------------------------------ ambiente

def amb_night(seed=77, L=48.0):
    rng = np.random.default_rng(seed)
    X = 3.0
    n = secs(L)
    nx = secs(L + X)
    t = np.arange(nx) / SR

    def lfo(cycles, ph):
        return np.sin(2 * np.pi * cycles * t / L + ph)

    def xfade_loop(st):
        """camada continua (ruido): crossfade equal-power da sobra no inicio."""
        out = st[..., :n].copy()
        k = secs(X)
        w = np.linspace(0, np.pi / 2, k)
        out[..., :k] = st[..., :k] * np.sin(w) + st[..., n:n + k] * np.cos(w)
        return out

    st = np.zeros((2, nx))
    # vento: graves macios com rajadas lentas (periodicas no loop)
    wind_env = 0.55 + 0.25 * lfo(2, 0.3) + 0.15 * lfo(3, 1.7) + 0.08 * lfo(5, 4.0)
    for ch in range(2):
        w = lp(rng.normal(0, 1, nx), 380, order=2) * 0.9 + bp(rng.normal(0, 1, nx), 700, 2200) * 0.05
        st[ch] = w * wind_env * (1 + 0.1 * lfo(4, ch * 2.0))
    bed = xfade_loop(st)

    ev = np.zeros((2, nx))
    # folhas: graos de farfalhar com densidade seguindo o vento
    tt = 0.0
    while tt < L:
        dens = 4 + 10 * max(0, wind_env[secs(tt)] - 0.5)
        tt += rng.exponential(1 / dens)
        if tt >= L:
            break
        g = grain(rng, rng.uniform(0.01, 0.04), 2000, 7000) * rng.uniform(0.02, 0.06)
        pan = rng.uniform(0.2, 0.8)
        a = secs(tt)
        ev[0, a:a + len(g)] += g * (1 - pan)
        ev[1, a:a + len(g)] += g * pan

    # grilos: 3 individuos + coro distante
    crickets = [(4300, 0.72, 3, 0.25, 0.9), (4750, 0.95, 4, 0.75, 0.7), (5200, 1.3, 2, 0.5, 0.5)]
    for fc, period, pulses, pan, amp in crickets:
        cycles = int(round(L / period))
        per = L / cycles
        for c in range(cycles):
            if rng.uniform() < 0.12:  # pausas ocasionais
                continue
            t0 = c * per + rng.uniform(0, 0.03)
            # intensidade varia devagar (periodica)
            a_mod = 0.6 + 0.4 * np.sin(2 * np.pi * 2 * t0 / L + fc)
            for p in range(pulses):
                pn = secs(0.014)
                tp = np.arange(pn) / SR
                f = fc * (1 + rng.uniform(-0.004, 0.004))
                pulse = np.sin(2 * np.pi * f * tp) * np.sin(np.pi * tp / 0.014) ** 2
                a = secs(t0 + p * 0.032)
                ev[0, a:a + pn] += pulse * amp * a_mod * (1 - pan) * 0.06
                ev[1, a:a + pn] += pulse * amp * a_mod * pan * 0.06
    # coro distante: trinado continuo muito baixo
    chorus = np.zeros((2, nx))
    for ch, fc in enumerate((3900, 4100)):
        am = 0.5 + 0.5 * np.sin(2 * np.pi * 38 * t + ch)
        chorus[ch] = np.sin(2 * np.pi * fc * t) * am * (0.5 + 0.3 * lfo(3, ch + 0.5)) * 0.008
    chorus = xfade_loop(chorus)
    # eventos: 'enrola' a sobra no inicio (continua o que comecou antes do fim)
    evl = ev[:, :n].copy()
    evl[:, :nx - n] += ev[:, n:]
    out = bed + evl + chorus
    # passa-altas circular (3 copias, pega a do meio) para nao criar degrau na costura
    trip = np.concatenate([out, out, out], axis=1)
    out = np.stack([hp(c, 40) for c in trip])[:, n:2 * n]
    return out


# ------------------------------------------------------------------ tela-titulo (UI/UX §9.5)

_IR_CHAPEL = None


def chapel(x, mix=0.35, t60=2.2, max_len=None):
    """Reverb de capela mono (canal esquerdo da IR estereo do dsp)."""
    global _IR_CHAPEL
    from scipy.signal import fftconvolve
    from dsp import make_ir
    if _IR_CHAPEL is None:
        _IR_CHAPEL = make_ir(t60=t60, length=t60 * 1.4, seed=13)[0]
    wet = fftconvolve(hp(x, 180), _IR_CHAPEL)
    out = np.zeros(len(wet))
    out[:len(x)] = x * (1 - mix * 0.5)
    out = out + wet * mix
    if max_len:
        out = out[:secs(max_len)]
        k = secs(max_len * 0.4)
        out[-k:] *= np.linspace(1, 0, k) ** 2
    return out


def logo_land(rng, i):
    """Letra de pedra pousando: 'toc' curto e abafado + poeirinha. Toca 12x a cada 40 ms."""
    d = 0.24
    x = buf(d)
    f = [430, 475, 515, 560][i % 4] * rng.uniform(0.98, 1.02)
    put(x, modal(rng, [f, f * 2.32, f * 3.7], [1, 0.4, 0.15], [0.05, 0.03, 0.015], 0.1) * 0.7, 0)
    put(x, thump(210, 95, 0.08, 0.035) * 0.55, 0)
    put(x, click(rng, 0.0015, 2500), 0, 0.12)
    n = secs(0.16)
    env = np.minimum(np.arange(n) / secs(0.012), 1) * exp_decay(n, 0.11)
    put(x, bp(noise(rng, 0.16), 900, 4500) * env * 0.22, 0.004)
    for _ in range(rng.integers(2, 4)):
        put(x, grain(rng, 0.008, 2000, 6000, 0.005) * 0.08, rng.uniform(0.02, 0.12))
    return x


def logo_thunk(rng, i):
    """Pa cravando no G: lamina entrando na terra + 'tunc' de cabo de madeira + capela."""
    d = 0.9
    x = buf(d)
    put(x, bp(noise(rng, 0.03), 1500, 6000) * perc_env(secs(0.03), 0.0005, 0.02) * 0.5, 0)
    put(x, thump(135 + 10 * i, 52, 0.35, 0.16) * 1.0, 0)
    put(x, lp(noise(rng, 0.12), 900) * perc_env(secs(0.12), 0.002, 0.07) * 0.6, 0.002)
    w = [185, 400, 720] if i == 0 else [172, 385, 690]
    put(x, modal(rng, w, [0.55, 0.3, 0.12], [0.22, 0.12, 0.06], 0.4), 0.003)
    put(x, modal(rng, [1240, 2960, 4410], [0.08, 0.05, 0.02], [0.3, 0.18, 0.1], 0.5), 0.001)
    for _ in range(rng.integers(6, 10)):
        tt = 0.04 + rng.uniform(0, 0.35) ** 1.2
        put(x, grain(rng, rng.uniform(0.008, 0.02), 900, 4000), tt, rng.uniform(0.04, 0.1))
    return chapel(x, mix=0.4, max_len=1.6)


def logo_drip(rng, i):
    """Gota de terra caindo do logo: tique minusculo + 'puf' + farelos."""
    d = 0.2
    x = buf(d)
    f = [2300, 2550, 2800][i % 3]
    put(x, modal(rng, [f, f * 1.9], [1, 0.3], [0.018, 0.01], 0.04) * 0.5, 0)
    put(x, lp(noise(rng, 0.06), 700) * perc_env(secs(0.06), 0.001, 0.035) * 0.8, 0.002)
    put(x, thump(260, 140, 0.04, 0.02) * 0.4, 0)
    for _ in range(rng.integers(1, 3)):
        put(x, grain(rng, 0.005, 2500, 7000, 0.003) * 0.2, rng.uniform(0.03, 0.09))
    return x


def ui_wisp_slide(rng, i):
    """Fogo-fatuo deslizando ao proximo botao: sopro que sobe + sininho de vidro."""
    d = 0.34
    x = buf(d)
    n = secs(0.16)
    t = np.arange(n) / SR
    air = sweep_bp(noise(rng, 0.16), 1400, 4200, q=2.0) * (0.2 + 0.8 * np.sin(np.pi * t / 0.16) ** 2)
    put(x, air * 0.35, 0)
    f = [2637, 2794, 2960][i % 3]
    for k, (r, a) in enumerate([(1.0, 0.5), (1.5, 0.28), (2.0, 0.12)]):
        put(x, chime(rng, f * r, 0.3, a, ratios=(1, 2.0, 3.0), amps=(1, 0.08, 0.03), t60=0.22), 0.002 + 0.03 * k)
    put(x, sparkle(rng, 0.2, 3, 6000, 9500, 0.06), 0.04)
    return x


def ui_bury(rng, i):
    """Confirmar 'Enterrar': pa raspando, terra jogada e caindo + nota grave de sino."""
    d = 1.6
    x = buf(d)
    n = secs(0.14)
    t = np.arange(n) / SR
    scrape = sweep_bp(noise(rng, 0.14), 700, 1800, q=2.5) * np.minimum(t / 0.01, 1) * np.exp(-t / 0.1)
    put(x, scrape * 0.5, 0)
    put(x, thump(150, 70, 0.08, 0.05) * 0.35, 0)
    n2 = secs(0.16)
    t2 = np.arange(n2) / SR
    put(x, sweep_bp(noise(rng, 0.16), 1500, 450, q=1.5) * np.sin(np.pi * t2 / 0.16) ** 2 * 0.45, 0.1)
    tl = 0.26
    put(x, thump(105 - 6 * i, 42, 0.45, 0.25) * 1.0, tl)
    put(x, lp(noise(rng, 0.3), 1000) * perc_env(secs(0.3), 0.004, 0.18) * 0.55, tl)
    for _ in range(rng.integers(16, 22)):
        tt = tl + rng.uniform(0, 0.45) ** 1.3
        put(x, grain(rng, rng.uniform(0.01, 0.03), 600, 3500), tt, rng.uniform(0.05, 0.16) * (1 - (tt - tl) / 0.6))
    from dsp import bell
    put(x, bell(110.0 * (1, 0.944)[i % 2], 1.3, rng, vel=0.22), tl + 0.01)
    return chapel(x, mix=0.25, max_len=1.5)


VOWEL_OO = [(320, 70, 1.0), (800, 90, 0.3), (2300, 160, 0.05), (3000, 200, 0.03)]
VOWEL_AH2 = [(700, 90, 1.0), (1100, 110, 0.5), (2600, 160, 0.16), (3300, 200, 0.08)]


def soul_voice(freq, dur, rng, m_curve, att=1.2, rel=1.6, sigh=-0.5):
    """Voz 'uuh -> aah' com morfologia de vogal ao longo da nota e leve suspiro descendo no fim."""
    n = secs(dur + rel)
    t = np.arange(n) / SR
    vib = 0.1 * np.sin(2 * np.pi * rng.uniform(4.4, 5.4) * t + rng.uniform(0, 6)) * np.clip((t - 0.4) / 0.8, 0, 1)
    tail = np.clip((t - dur * 0.8) / (dur * 0.2 + rel), 0, 1) ** 2 * sigh
    f = freq * 2 ** ((vib + tail + rng.uniform(-0.06, 0.06)) / 12)
    ph = np.cumsum(2 * np.pi * f / SR)
    m = np.interp(t, np.linspace(0, dur + rel, len(m_curve)), m_curve)
    out = np.zeros(n)
    k = 1
    while k * freq < 5000:
        fk = k * freq
        a_oo = sum(g / (1 + ((fk - F) / bw) ** 2) for F, bw, g in VOWEL_OO) / k ** 0.6
        a_ah = sum(g / (1 + ((fk - F) / bw) ** 2) for F, bw, g in VOWEL_AH2) / k ** 0.6
        out += (a_oo * (1 - m) + a_ah * m) * np.sin(k * ph + rng.uniform(0, 6))
        k += 1
    out += bp(rng.normal(0, 1, n), 500, 2500) * 0.015
    from dsp import adsr
    return out * adsr(n, att, dur, rel)


def amb_souls_choir(seed=91, L=32.0):
    """Coro distante das almas na fila: vozes longas 'uuh/aah' em La menor pentatonica,
    com 2 ondas de intensidade por loop (vai e volta). Estereo, circular (arquivo inteiro = loop)."""
    from dsp import make_ir, pan_gains
    from scipy.signal import fftconvolve
    rng = np.random.default_rng(seed)
    n = secs(L)
    pitches = [57, 60, 64, 62, 67, 69, 52, 64, 60]
    st = np.zeros((2, n + secs(12)))
    tt = 0.0
    while tt < L:
        for _ in range(rng.integers(1, 3)):
            m = int(rng.choice(pitches))
            dur = rng.uniform(3.0, 6.5)
            mc = np.clip(np.cumsum(rng.uniform(-0.3, 0.45, 6)), 0, 1)  # uuh abrindo para aah e voltando
            v = soul_voice(midi_hz(m), dur, rng, mc, sigh=rng.choice([-0.5, -0.3, 0.0]))
            gl, gr = pan_gains(rng.uniform(-0.55, 0.35))
            a = secs(tt + rng.uniform(0, 0.8))
            g = rng.uniform(0.5, 1.0) * (0.7 if m < 55 else 1.0)
            st[0, a:a + len(v)] += v * g * gl
            st[1, a:a + len(v)] += v * g * gr
        tt += rng.uniform(1.6, 3.2)
    # enrola o excesso no inicio (circular)
    loop = st[:, :n].copy()
    rest = st[:, n:]
    loop[:, :rest.shape[1]] += rest
    # distancia: sem graves e sem brilho
    trip = np.concatenate([loop, loop, loop], axis=1)
    trip = np.stack([lp(hp(c, 160), 2400, order=2) for c in trip])
    loop = trip[:, n:2 * n]
    # vai e volta: 2 ondas por loop (periodico)
    t = np.arange(n) / SR
    swell = 0.55 + 0.45 * np.sin(2 * np.pi * 2 * t / L - np.pi / 2) * (0.8 + 0.2 * np.sin(2 * np.pi * 3 * t / L))
    loop = loop * np.clip(swell, 0.08, 1.0)
    # capela longa, quase so molhado (distante); convolucao circular
    ir = make_ir(t60=3.2, length=4.5, seed=19, hf=0.35)
    wet = np.stack([fftconvolve(loop[c], ir[c]) for c in range(2)])
    out = loop * 0.35
    w = wet[:, :n].copy()
    r = wet[:, n:]
    while r.shape[1] > 0:
        k = min(n, r.shape[1])
        w[:, :k] += r[:, :k]
        r = r[:, k:]
    return out + w * 0.9


# ------------------------------------------------------------------ leva 3 (jogo completo)

def formant_voice(rng, f0, vowel_fn, breath=0.0, rough=0.0, fmax=5000):
    """Voz curta: harmonicos de f0 (array por amostra) com envelope espectral de formantes.
    vowel_fn(t) -> lista [(F, bw, g)] (pode variar no tempo; avaliado por amostra se arrays)."""
    n = len(f0)
    t = np.arange(n) / SR
    ph = np.cumsum(2 * np.pi * f0 / SR)
    forms = vowel_fn(t)
    out = np.zeros(n)
    k = 1
    while k * np.min(f0) < fmax:
        fk = k * f0
        a = sum(g / (1 + ((fk - F) / bw) ** 2) for F, bw, g in forms) / k ** 0.5
        out += a * np.sin(k * ph + rng.uniform(0, 6))
        k += 1
    if rough:
        out *= 1 + rough * np.sin(2 * np.pi * rng.uniform(70, 95) * t)
    if breath:
        out += bp(noise(rng, n / SR), 800, 4000)[:n] * breath * np.max(np.abs(out))
    return out


V_AH = [(750, 90, 1.0), (1200, 110, 0.5), (2600, 160, 0.2)]
V_OH = [(450, 80, 1.0), (850, 100, 0.45), (2500, 160, 0.1)]
V_EH = [(550, 80, 1.0), (1800, 120, 0.45), (2550, 160, 0.2)]
V_OO = [(330, 70, 1.0), (800, 90, 0.3), (2300, 160, 0.05)]
V_NASAL = [(600, 90, 1.0), (1300, 80, 0.8), (2500, 120, 0.5), (3400, 200, 0.2)]


def stomp(rng, i):
    """Pisao: baque grave da bota/pa no chao + terra explodindo + farelos + rumor."""
    d = 0.95
    x = buf(d)
    f0 = [78, 72, 84, 75][i % 4] * rng.uniform(0.97, 1.03)
    put(x, thump(f0, 32, 0.7, 0.34), 0)
    put(x, thump(150, 62, 0.15, 0.06) * 0.5, 0)
    put(x, lp(noise(rng, 0.35), 900) * perc_env(secs(0.35), 0.002, 0.2) * 0.8, 0)
    put(x, bp(noise(rng, 0.03), 800, 4000) * perc_env(secs(0.03), 0.0005, 0.02) * 0.45, 0)
    for _ in range(rng.integers(18, 27)):
        tt = 0.05 + rng.uniform(0, 0.55) ** 1.4
        put(x, grain(rng, rng.uniform(0.008, 0.025), 700, 4000), tt, rng.uniform(0.05, 0.2) * (1 - tt / 0.8))
    rum = lp(noise(rng, 0.8), 150) * exp_decay(secs(0.8), 0.5)
    put(x, rum * 0.5, 0.01)
    return x


def flare(rng, i):
    """Clarao: fosforo riscando + chama acendendo ('fuump') + estalos + brilho."""
    d = 1.05
    x = buf(d)
    put(x, sweep_bp(noise(rng, 0.06), 2500, 5200, q=2.0) * perc_env(secs(0.06), 0.001, 0.05) * 0.5, 0)
    n = secs(0.6)
    t = np.arange(n) / SR
    env = np.minimum(t / 0.06, 1) * np.exp(-6.9 * np.maximum(t - 0.06, 0) / 0.5)
    put(x, sweep_bp(noise(rng, 0.6), 280, 1900, q=1.3) * env * 1.1, 0.03)
    put(x, thump(120, 60, 0.22, 0.12) * 0.4, 0.04)
    nf = secs(0.9)
    tf = np.arange(nf) / SR
    flick = 1 + 0.6 * onepole(rng.normal(0, 1, nf), 18) * 8
    put(x, lp(noise(rng, 0.9), 650) * np.clip(flick, 0.2, 2) * np.exp(-6.9 * tf / 0.9) * 0.35, 0.08)
    for _ in range(rng.integers(10, 17)):
        tt = rng.uniform(0.08, 0.9)
        put(x, click(rng, 0.0015, 2500) * rng.uniform(0.1, 0.35) * (1 - tt), tt)
    ng = secs(0.8)
    tg = np.arange(ng) / SR
    fg = [1319, 1397, 1245][i % 3]
    glow = (np.sin(2 * np.pi * fg * tg) + 0.6 * np.sin(2 * np.pi * fg * 1.5 * tg)) * np.minimum(tg / 0.12, 1) * np.exp(-6.9 * tg / 0.7)
    put(x, glow * 0.12, 0.1)
    put(x, sparkle(rng, 0.6, 5, 4000, 8500, 0.1), 0.12)
    return x


def dig_bone(rng, i):
    """Camada Ossada: 'toc-tac' oco de ossos + chocalhar miudo + terra."""
    d = 0.36
    x = buf(d)
    put(x, thump(160, 70, 0.12, 0.05) * 0.5, 0)
    put(x, lp(noise(rng, 0.06), 900) * perc_env(secs(0.06), 0.001, 0.035) * 0.4, 0)
    base = [1150, 1300, 1450, 1250][i % 4] * rng.uniform(0.97, 1.03)
    tt = 0.0
    for k in range(rng.integers(2, 4)):
        f = base * rng.uniform(0.85, 1.2)
        tok = modal(rng, [f, f * 2.7, f * 5.2], [1, 0.4, 0.15], [0.05, 0.025, 0.012], 0.1)
        put(x, tok * (1.0 if k == 0 else rng.uniform(0.35, 0.6)), tt)
        tt += rng.uniform(0.025, 0.07)
    for _ in range(rng.integers(4, 8)):
        put(x, grain(rng, 0.004, 2000, 6000, 0.003) * rng.uniform(0.1, 0.25), rng.uniform(0.03, 0.18))
    return x


def dig_mud(rng, i):
    """Lama (estagio 2): baque mole + 'chlop' + succao subindo + bolhas (diferente do barro)."""
    d = 0.45
    x = buf(d)
    put(x, thump(rng.uniform(100, 120), 45, 0.22, 0.1) * 0.85, 0)
    put(x, bp(noise(rng, 0.08), 200, 1800) * perc_env(secs(0.08), 0.001, 0.05) * 0.8, 0)
    n = secs(0.24)
    t = np.arange(n) / SR
    env = np.sin(np.pi * np.clip(t / 0.24, 0, 1)) ** 0.8 * np.where(t > 0.2, np.exp(-(t - 0.2) / 0.01), 1)
    put(x, sweep_bp(noise(rng, 0.24), rng.uniform(300, 380), rng.uniform(1200, 1600), q=6) * env * 1.0, 0.07)
    for _ in range(rng.integers(3, 6)):
        f0 = rng.uniform(150, 260)
        put(x, sweep_tone(f0, f0 * 2.5, 0.04, 0.05) * 0.2, rng.uniform(0.1, 0.36))
    return x


def dig_stone(rng, i):
    """Pedra das catacumbas: 'toc' seco e opaco (nao metalico como dig_rock) + areia + lascas."""
    d = 0.3
    x = buf(d)
    f = [700, 760, 650, 820][i % 4] * rng.uniform(0.97, 1.03)
    put(x, modal(rng, [f, f * 1.68, f * 2.9, f * 4.1], [1, 0.6, 0.35, 0.15], [0.06, 0.04, 0.025, 0.015], 0.15), 0)
    put(x, grain(rng, 0.004, 2000, 7000, 0.003) * 0.8, 0)
    put(x, bp(noise(rng, 0.1), 1500, 6000) * perc_env(secs(0.1), 0.001, 0.05) * 0.25, 0.002)
    for _ in range(rng.integers(2, 5)):
        put(x, modal(rng, [rng.uniform(2500, 4500)], [1], [0.015], 0.04) * 0.15, rng.uniform(0.03, 0.15))
    put(x, thump(200, 110, 0.06, 0.03) * 0.4, 0)
    return x


def dig_marble(rng, i):
    """Marmore: 'clank' polido e brilhante com ressonancia longa."""
    d = 0.6
    x = buf(d)
    f = [1380, 1450, 1520, 1310][i % 4] * rng.uniform(0.98, 1.02)
    put(x, modal(rng, [f, f * 2.32, f * 3.41, f * 4.62, f * 6.1], [1, 0.7, 0.45, 0.3, 0.15],
                 [0.4, 0.28, 0.18, 0.12, 0.07], d, 0.005), 0)
    put(x, click(rng, 0.002, 3000) * 1.0, 0)
    put(x, modal(rng, [rng.uniform(360, 400)], [0.4], [0.08], 0.15), 0)
    put(x, thump(220, 120, 0.05, 0.025) * 0.3, 0)
    return x


def dig_mist(rng, i):
    """Nevoa eterea: golpe macio + sopro 'fff' descendo + tom de vidro que se desfaz."""
    d = 0.6
    x = buf(d)
    put(x, thump(140, 80, 0.08, 0.05) * 0.3, 0)
    n = secs(0.42)
    t = np.arange(n) / SR
    put(x, sweep_bp(noise(rng, 0.42), 2600, 700, q=2.0) * np.minimum(t / 0.01, 1) * np.exp(-t / 0.13) * 0.7, 0)
    f = [1760, 1976, 2093, 2349][i % 4]
    ng = secs(0.5)
    tg = np.arange(ng) / SR
    gl = f * (1 + 0.02 * tg / 0.5)
    tone = (np.sin(np.cumsum(2 * np.pi * gl / SR)) + 0.5 * np.sin(np.cumsum(2 * np.pi * gl * 1.5 / SR)))
    tone *= np.minimum(tg / 0.01, 1) * np.exp(-6.9 * tg / 0.45) * (1 + 0.3 * np.sin(2 * np.pi * 9 * tg))
    put(x, tone * 0.16, 0.005)
    put(x, sparkle(rng, 0.4, 3, 5000, 9000, 0.06), 0.05)
    return x


def boss_sink(rng, i):
    """Chefe (caixao) afundando: rangido de madeira + terra escorrendo + 'glup' grave."""
    d = 1.15
    x = buf(d)
    c = creak(rng, 0.6, [40, 34][i % 2], 18, [(150, 8, 1.0), (260, 7, 0.6)], lpf=800)
    put(x, c * np.sin(np.pi * np.linspace(0, 1, len(c))) ** 0.5 * 0.6, 0)
    n = secs(0.9)
    t = np.arange(n) / SR
    put(x, sweep_bp(noise(rng, 0.9), 1200, 250, q=1.2) * np.minimum(t / 0.05, 1) * np.exp(-t / 0.4) * 0.8, 0)
    put(x, thump(110, 40, 0.45, 0.22) * 0.9, 0.55 + 0.04 * i)
    for _ in range(rng.integers(10, 16)):
        tt = rng.uniform(0.05, 0.7)
        put(x, grain(rng, rng.uniform(0.01, 0.025), 600, 3000), tt, rng.uniform(0.05, 0.15))
    return x


def boss_emerge(rng, i):
    """Chefe emergindo: rumor crescendo + rangido subindo + explosao de terra."""
    d = 1.2
    x = buf(d)
    n = secs(0.6)
    t = np.arange(n) / SR
    put(x, lp(noise(rng, 0.6), 220) * (0.15 + 0.85 * (t / 0.6) ** 2) * 0.9, 0)
    put(x, grain(rng, 0.02, 300, 1500, 0.015) * 0.3, 0)  # ataque imediato (terra mexendo)
    c = creak(rng, 0.3, 20, 45, [(170, 8, 1.0), (300, 7, 0.5)], lpf=900)
    put(x, c * np.linspace(0.2, 1, len(c)) * 0.45, 0.28)
    tb = 0.58 + 0.03 * i
    put(x, thump(95, 42, 0.45, 0.22) * 1.0, tb)
    put(x, lp(noise(rng, 0.3), 1500) * perc_env(secs(0.3), 0.002, 0.15) * 0.7, tb)
    for _ in range(rng.integers(18, 26)):
        tt = tb + rng.uniform(0, 0.5) ** 1.3
        put(x, grain(rng, rng.uniform(0.008, 0.025), 700, 4000), tt, rng.uniform(0.06, 0.2) * (1 - (tt - tb) / 0.65))
    return x


def boss_hit(rng, i):
    """Golpe no chefe: madeira grossa e oca (mais grave que dig_coffin) + caixao chacoalhando."""
    d = 0.5
    x = buf(d)
    b = [150, 162, 140][i % 3] * rng.uniform(0.98, 1.02)
    put(x, modal(rng, [b, b * 2.31, b * 3.86], [1, 0.55, 0.3], [0.3, 0.18, 0.1], d), 0)
    put(x, thump(130, 55, 0.25, 0.12) * 0.8, 0)
    put(x, grain(rng, 0.01, 1000, 5000, 0.006) * 0.8, 0)
    for _ in range(rng.integers(3, 6)):
        f = rng.uniform(500, 1100)
        put(x, modal(rng, [f, f * 2.4], [1, 0.3], [0.03, 0.015], 0.05) * 0.18, rng.uniform(0.04, 0.16))
    return x


def boss_defeat(rng, i):
    """Chefe derrotado: estalo grande, lascas, desabamento, terra assentando, alma subindo + sino."""
    from dsp import bell
    d = 2.7
    x = buf(d)
    put(x, bp(noise(rng, 0.08), 500, 5000) * perc_env(secs(0.08), 0.0005, 0.05) * 0.9, 0)
    put(x, thump(80, 35, 0.9, 0.5) * 1.0, 0)
    for _ in range(rng.integers(12, 19)):
        f = rng.uniform(400, 1600)
        put(x, modal(rng, [f, f * 2.3], [1, 0.3], [0.05, 0.025], 0.08) * rng.uniform(0.1, 0.3), rng.uniform(0.02, 0.5))
    for tt, a in ((0.35, 0.6), (0.6, 0.45), (0.82, 0.3)):
        put(x, thump(rng.uniform(90, 120), 45, 0.3, 0.15) * a, tt)
        put(x, lp(noise(rng, 0.15), 1200) * perc_env(secs(0.15), 0.002, 0.08) * a * 0.5, tt)
    put(x, lp(noise(rng, 1.4), 800) * exp_decay(secs(1.4), 1.0) * 0.18, 0.4)
    n = secs(1.5)
    t = np.arange(n) / SR
    f = 600 * 3 ** (t / 1.5) * (1 + 0.01 * np.sin(2 * np.pi * 5.5 * t))
    soul = np.sin(np.cumsum(2 * np.pi * f / SR)) * np.sin(np.pi * t / 1.5) ** 2
    put(x, soul * 0.12, 0.6)
    put(x, bell(880.0, 1.4, rng, vel=0.22), 1.3)
    put(x, sparkle(rng, 1.0, 9, 4000, 9000, 0.1), 1.2)
    return chapel(x, mix=0.25, max_len=2.7)


def card_flip(rng, i):
    """Carta-lapide virando: sopro curto + toque de pedra fina."""
    d = 0.2
    x = buf(d)
    n = secs(0.08)
    t = np.arange(n) / SR
    put(x, sweep_bp(noise(rng, 0.08), 1500, 4500, q=1.5) * np.sin(np.pi * t / 0.08) * 0.6, 0)
    f = [900, 960, 1020][i % 3]
    put(x, modal(rng, [f, f * 2.6], [1, 0.3], [0.03, 0.015], 0.06) * 0.6, 0.07)
    put(x, click(rng, 0.0015, 3000) * 0.3, 0.07)
    return x


def card_pick(rng, i):
    """Carta escolhida: toque + arpejo de sininhos (La maior) + faiscas."""
    d = 0.75
    x = buf(d)
    put(x, modal(rng, [600, 1500], [1, 0.3], [0.05, 0.02], 0.1) * 0.6, 0)
    put(x, click(rng, 0.0015, 3000) * 0.3, 0)
    base = [880, 988][i % 2]
    for k, r in enumerate((1.0, 1.26, 1.5)):
        put(x, chime(rng, base * r, 0.6, 0.5, t60=0.5), 0.03 + 0.035 * k)
    put(x, sparkle(rng, 0.4, 4, 4500, 9000, 0.08), 0.1)
    return x


def card_legendary(rng, i):
    """Carta lendaria: sino + coro 'aah' em La maior + chuva de faiscas, com capela."""
    from dsp import bell, choir_voice
    d = 2.3
    x = buf(d)
    put(x, bell(880.0, 2.0, rng, vel=0.5), 0)
    n = secs(0.5)
    t = np.arange(n) / SR
    put(x, sweep_bp(noise(rng, 0.5), 600, 4500, q=1.5) * (t / 0.5) ** 1.5 * 0.25, 0)
    for m in (57, 61, 64, 69, 76):
        for v in range(2):
            put(x, choir_voice(midi_hz(m), 1.1, rng, att=0.15, rel=0.8) * 0.09, 0.03 + 0.015 * v)
    put(x, sparkle(rng, 1.6, 14, 4000, 9500, 0.1), 0.05)
    return chapel(x, mix=0.3, max_len=2.3)


def shop_bell(rng, i):
    """Sininho de porta na mola: 4-5 batidas que perdem forca (balanço)."""
    d = 1.1
    x = buf(d)
    f0 = [2210, 2350][i % 2]
    tt, a = 0.0, 1.0
    for k in range(rng.integers(4, 6)):
        f = f0 * (1 + rng.uniform(-0.004, 0.004))
        put(x, modal(rng, [f, f * 2.32, f * 4.1, f * 5.4], [1, 0.4, 0.2, 0.1], [0.55, 0.3, 0.15, 0.08], 0.7) * a, tt)
        put(x, click(rng, 0.001, 4000) * 0.2 * a, tt)
        tt += rng.uniform(0.07, 0.11) * (1 + 0.15 * k)
        a *= rng.uniform(0.55, 0.7)
    return x


def shop_buy(rng, i):
    """Compra no Mascate: moedas no balcao de madeira + 'tlim' da venda."""
    d = 0.7
    x = buf(d)
    put(x, thump(220, 120, 0.05, 0.03) * 0.3, 0)
    for k in range(rng.integers(3, 6)):
        put(x, coin(rng, rng.uniform(2200, 3000), 0.3, rng.uniform(0.35, 0.7)), 0.005 + rng.uniform(0, 0.15))
    f = [1760, 1865, 1661][i % 3]
    put(x, chime(rng, f, 0.5, 0.6, t60=0.45), 0.2)
    put(x, chime(rng, f * 1.26, 0.45, 0.45, t60=0.4), 0.26)
    return x


def shop_deny(rng, i):
    """Sem dinheiro: dois 'bonc' de madeira abafados, descendo uma terca menor."""
    d = 0.4
    x = buf(d)
    f = [520, 490][i % 2]
    for k, (ff, tt) in enumerate(((f, 0.0), (f / 1.19, 0.13))):
        put(x, modal(rng, [ff, ff * 2.4], [1, 0.25], [0.07, 0.03], 0.15) * (1.0 - 0.15 * k), tt)
        put(x, thump(ff * 0.4, ff * 0.25, 0.06, 0.03) * 0.3, tt)
    return x


def coin_gold(rng, i):
    """Moeda dourada: mais grave, pesada e brilhante que o Cobre."""
    d = 0.75
    x = buf(d)
    f0 = [1850, 1960, 2080][i % 3]
    put(x, modal(rng, [f0, f0 * 1.52, f0 * 2.33, f0 * 3.07, f0 * 4.1], [1, 0.6, 0.4, 0.22, 0.12],
                 [0.5, 0.35, 0.2, 0.12, 0.07], d, 0.005), 0)
    put(x, click(rng, 0.002, 4000) * 0.6, 0)
    put(x, coin(rng, f0 * 1.26, 0.4, 0.4), 0.05)
    put(x, modal(rng, [4186], [1], [0.3], 0.4) * 0.08, 0.1)
    put(x, sparkle(rng, 0.45, 4, 5000, 9500, 0.08), 0.08)
    return x


def chest_open(rng, i):
    """Bau: trinco, dobradica rangendo (agudo), tampa batendo e brilho do tesouro."""
    d = 1.3
    x = buf(d)
    put(x, modal(rng, [2400, 3800], [1, 0.4], [0.02, 0.01], 0.05) * 0.7, 0)
    put(x, click(rng, 0.0015, 3000) * 0.5, 0)
    put(x, modal(rng, [2100, 3300], [1, 0.4], [0.02, 0.01], 0.05) * 0.5, 0.06)
    c = creak(rng, 0.5, [35, 30][i % 2], 55, [(420, 8, 1.0), (780, 7, 0.6), (1300, 6, 0.3)], lpf=2000)
    put(x, c * np.sin(np.pi * np.linspace(0, 1, len(c))) ** 0.6 * 0.5, 0.1)
    tl = 0.62
    put(x, modal(rng, [160, 320], [1, 0.4], [0.15, 0.08], 0.3) * 0.6, tl)
    put(x, thump(150, 70, 0.2, 0.1) * 0.6, tl)
    for k, f in enumerate([1568, 1976, 2349]):
        put(x, chime(rng, f * (1, 1.06)[i % 2], 0.6, 0.35, t60=0.5), tl + 0.05 + 0.05 * k)
    put(x, sparkle(rng, 0.5, 6, 4500, 9500, 0.1), tl + 0.05)
    return x


def bone_rain(rng, i):
    """Ossario cheio: chuva de ossos (toques de xilofone de madeira) caindo e chacoalhando."""
    d = 1.7
    x = buf(d)
    scale = [600, 675, 800, 900, 1070, 1200, 1350]
    m = rng.integers(22, 32)
    for k in range(m):
        tt = 1.3 * rng.uniform(0, 1) ** 1.6
        f = scale[rng.integers(0, len(scale))] * rng.uniform(0.98, 1.02)
        tok = modal(rng, [f, f * 3.95, f * 9.9], [1, 0.3, 0.08], [0.12, 0.04, 0.015], 0.18)
        put(tok, grain(rng, 0.004, 1500, 6000, 0.002), 0, 0.4)
        put(x, tok * rng.uniform(0.3, 1.0) * (1 - 0.5 * tt / 1.3), tt)
    put(x, thump(170, 80, 0.12, 0.06) * 0.5, 0)
    nb = secs(1.4)
    put(x, bp(noise(rng, 1.4), 1500, 5000) * exp_decay(nb, 0.8) * 0.05, 0)
    return x


def soul_wander(rng, i):
    """Alminha errante: 'uuu' baixinho e curioso + brilho. Tocar de vez em quando enquanto ela vaga."""
    d = 1.7
    x = buf(d)
    m = [(69, [0, 0.2, 0.5, 0.3, 0.1, 0]), (72, [0.1, 0.4, 0.6, 0.2, 0, 0])][i % 2]
    v = soul_voice(midi_hz(m[0]), 0.8, rng, m[1], att=0.25, rel=0.6, sigh=[-1.0, 0.8][i % 2])
    put(x, lp(v, 2500) * 0.5, 0)
    n = secs(1.2)
    t = np.arange(n) / SR
    sh = np.sin(2 * np.pi * midi_hz(m[0] + 24) * t) * np.sin(np.pi * t / 1.2) ** 2 * (1 + 0.4 * np.sin(2 * np.pi * 7 * t))
    put(x, sh * 0.05, 0.1)
    put(x, sparkle(rng, 0.9, 3, 5000, 9000, 0.05), 0.2)
    return chapel(x, mix=0.35, max_len=1.8)


def tombstone_effect(rng, i):
    """Lapide ativando efeito: pedra arrastando curtinho + sininho magico + brilho."""
    d = 0.85
    x = buf(d)
    n = secs(0.18)
    t = np.arange(n) / SR
    am = 1 + 0.7 * onepole(rng.normal(0, 1, n), 40) * 8
    put(x, bp(noise(rng, 0.18), 200, 1500) * np.clip(am, 0.2, 2) * np.sin(np.pi * t / 0.18) * 0.5, 0)
    f = [1319, 1568, 1760][i % 3]
    put(x, chime(rng, f, 0.7, 0.55, t60=0.5), 0.1)
    put(x, chime(rng, f * 1.5, 0.6, 0.3, t60=0.4), 0.14)
    ng = secs(0.4)
    tg = np.arange(ng) / SR
    put(x, np.sin(2 * np.pi * f / 2 * tg) * np.sin(np.pi * tg / 0.4) ** 2 * 0.15, 0.05)
    put(x, sparkle(rng, 0.5, 5, 4500, 9000, 0.08), 0.15)
    return x


def seal(rng, i):
    """Raiz selada / encruzilhada: raizes se atando + trava 'clunc' + sino grave misterioso."""
    from dsp import bell
    d = 0.95
    x = buf(d)
    c = creak(rng, 0.25, 30, 60, [(200, 6, 1.0), (380, 6, 0.5)], lpf=1000)
    put(x, c * np.sin(np.pi * np.linspace(0, 1, len(c))) * 0.5, 0)
    put(x, grain(rng, 0.03, 500, 2500, 0.02) * 0.3, 0)
    tl = 0.22
    put(x, modal(rng, [260, 610, 1180], [1, 0.5, 0.25], [0.15, 0.08, 0.04], 0.3) * 0.8, tl)
    put(x, click(rng, 0.002, 2500) * 0.5, tl)
    put(x, thump(160, 80, 0.1, 0.05) * 0.5, tl)
    put(x, bell([110.0, 103.8][i % 2], 0.8, rng, vel=0.2), tl + 0.01)
    return chapel(x, mix=0.2, max_len=0.95)


def respec(rng, i):
    """Replantar: terra revolvendo, raizes recolhendo (rangidos desacelerando) e um arpejo de volta ao inicio."""
    d = 1.9
    x = buf(d)
    n = secs(1.4)
    t = np.arange(n) / SR
    am = 0.6 + 0.4 * np.sin(2 * np.pi * (3.5 + 0.5 * i) * t)
    put(x, lp(noise(rng, 1.4), 1200) * am * np.sin(np.pi * t / 1.4) ** 0.7 * 0.5, 0)
    put(x, grain(rng, 0.02, 400, 2000, 0.015) * 0.3, 0)
    for _ in range(rng.integers(20, 30)):
        tt = rng.uniform(0.02, 1.3)
        put(x, grain(rng, rng.uniform(0.01, 0.025), 700, 3500), tt, rng.uniform(0.04, 0.12))
    c = creak(rng, 1.0, 50, 15, [(180, 6, 1.0), (330, 6, 0.6)], lpf=900)
    put(x, c * np.sin(np.pi * np.linspace(0, 1, len(c))) * 0.4, 0.1)
    rs = bp(noise(rng, 0.6), 600, 3000) * (np.arange(secs(0.6)) / secs(0.6)) ** 2
    put(x, rs * 0.25, 0.6)
    for k, f in enumerate([880, 1109, 1319]):
        put(x, chime(rng, f, 0.6, 0.45, t60=0.5), 1.22 + 0.06 * k)
    return x


def milestone(rng, i):
    """Marco alcancado: toque de madeira + tres sinos subindo (Mi-La-Do#) + faiscas."""
    d = 1.0
    x = buf(d)
    put(x, modal(rng, [700, 1650], [1, 0.3], [0.06, 0.03], 0.1) * 0.5, 0)
    for k, f in enumerate([1319, 1760, 2217]):
        put(x, chime(rng, f, 0.8, 0.6 + 0.1 * k, t60=0.55), 0.03 + 0.08 * k)
    put(x, sparkle(rng, 0.6, 6, 4500, 9500, 0.09), 0.2)
    return x


def helper_mole(rng, i):
    """Toupeira cavando: 3-4 arranhoes rapidos + torroes miudos."""
    d = 0.38
    x = buf(d)
    tt = 0.0
    for k in range(rng.integers(3, 5)):
        put(x, grain(rng, rng.uniform(0.02, 0.03), 1500, 5000) * rng.uniform(0.5, 1.0), tt)
        put(x, thump(220, 120, 0.04, 0.02) * 0.3, tt)
        tt += rng.uniform(0.05, 0.075)
    for _ in range(rng.integers(3, 6)):
        put(x, grain(rng, 0.008, 1000, 4000, 0.005) * 0.2, rng.uniform(0.05, 0.3))
    return x


def helper_cat(rng, i):
    """Gato Breu: miado curtinho ('miau') ou trinado ('mrrp')."""
    if i % 2 == 0:
        d = 0.42
        n = secs(d)
        t = np.arange(n) / SR
        f0 = np.interp(t, [0, 0.12, 0.42], [560, 760, 470])

        def vf(tt):
            F1 = np.interp(tt, [0, 0.12, 0.42], [380, 900, 500])
            F2 = np.interp(tt, [0, 0.12, 0.42], [2300, 1500, 950])
            return [(F1, 120, 1.0), (F2, 160, 0.5), (3200, 250, 0.15)]
        x = formant_voice(rng, f0, vf, breath=0.05)
        env = np.minimum(t / 0.03, 1) * np.where(t > 0.3, np.exp(-(t - 0.3) / 0.05), 1)
    else:
        d = 0.28
        n = secs(d)
        t = np.arange(n) / SR
        f0 = np.interp(t, [0, 0.1, 0.28], [480, 640, 600])

        def vf(tt):
            F1 = np.interp(tt, [0, 0.28], [400, 750])
            return [(F1, 120, 1.0), (1700, 180, 0.4), (3000, 250, 0.1)]
        x = formant_voice(rng, f0, vf, breath=0.05)
        x *= 1 - 0.7 * (t < 0.09) * (0.5 + 0.5 * np.sin(2 * np.pi * 28 * t))
        env = np.minimum(t / 0.015, 1) * np.where(t > 0.2, np.exp(-(t - 0.2) / 0.03), 1)
    return x * env


BLIP = {  # personagem: (f0 base, vogais, extras)
    "": (560, [V_AH, V_EH, V_OH], {}),
    "ossada": (330, [V_OH, V_AH, V_OO], {"tok": True}),
    "ceifa": (190, [V_AH, V_OH, V_EH], {"breath": 0.25, "dur": 0.085}),
    "tiao": (760, [V_AH, V_NASAL, V_AH], {"rough": 0.6, "dur": 0.05}),
    "mascate": (440, [V_NASAL, V_EH, V_NASAL], {"glide": 0.06}),
}


def dialog_blip(who):
    def gen(rng, i):
        f, vows, ex = BLIP[who]
        d = ex.get("dur", 0.065)
        n = secs(d)
        t = np.arange(n) / SR
        f0 = f * [1.0, 1.09, 0.93][i % 3] * (1 + ex.get("glide", 0.0) * t / d)
        x = formant_voice(rng, f0, lambda tt, v=vows[i % 3]: v, breath=ex.get("breath", 0.0),
                          rough=ex.get("rough", 0.0))
        x *= np.minimum(t / 0.004, 1) * np.exp(-6.9 * t / (d * 1.1))
        x /= np.max(np.abs(x)) + 1e-9
        if ex.get("tok"):
            ft = f * 3.3 * [1.0, 1.09, 0.93][i % 3]
            put(x, modal(rng, [ft, ft * 2.7], [1, 0.3], [0.03, 0.015], d) * 0.35, 0)
        return fade(x, 0.0005, 0.01)
    return gen


def unrest_warning(rng, i):
    """'A terra treme': rumor grave tremido + baques subgraves + pedrinhas chacoalhando (~1,5 s)."""
    d = 1.6
    n = secs(d)
    t = np.arange(n) / SR
    trem = 1 + 0.5 * np.sin(2 * np.pi * (7 + 1.5 * i) * t + 2 * np.sin(2 * np.pi * 1.3 * t))
    env = np.minimum(t / 0.2, 1) * np.where(t > 1.1, np.exp(-(t - 1.1) / 0.18), 1)
    x = (lp(noise(rng, d), 90, order=4) * 1.0 + lp(noise(rng, d), 220) * 0.3) * trem * env
    x = x / (np.max(np.abs(x)) + 1e-9) * 0.7
    for tt, a in ((0.0, 0.8), (0.5, 0.6), (0.95, 0.45)):
        put(x, thump(62, 30, 0.4, 0.25) * a, tt + rng.uniform(0, 0.04))
    for _ in range(rng.integers(25, 40)):
        tt = rng.uniform(0.05, 1.25)
        put(x, grain(rng, 0.005, 1500, 4500, 0.003) * rng.uniform(0.04, 0.12), tt)
    return x


def build_complete(rng, i):
    """Construcao restaurada no hub: 3 marteladas, a peca assenta e um acorde de sinos (La maior)."""
    d = 1.7
    x = buf(d)
    for k, tt in enumerate((0.0, 0.14, 0.28)):
        f = 700 * (1 + 0.06 * k) * rng.uniform(0.98, 1.02)
        put(x, modal(rng, [f, f * 2.36], [1, 0.3], [0.06, 0.03], 0.1) * 0.7, tt)
        put(x, thump(250, 140, 0.05, 0.03) * 0.4, tt)
        put(x, click(rng, 0.0015, 3000) * 0.3, tt)
    put(x, thump(120, 60, 0.25, 0.1) * 0.7, 0.42)
    put(x, lp(noise(rng, 0.2), 1000) * perc_env(secs(0.2), 0.003, 0.1) * 0.35, 0.42)
    for k, f in enumerate([880, 1109, 1319, 1760][::1 if i == 0 else -1]):
        put(x, chime(rng, f, 0.9, 0.45, t60=0.7), 0.5 + 0.06 * k)
    put(x, sparkle(rng, 0.7, 7, 4500, 9500, 0.09), 0.55)
    return chapel(x, mix=0.2, max_len=1.7)


# ------------------------------------------------------------------ registro

# id: (gerador, n_variacoes, pico alvo dBFS)
SPEC = {
    "dig_grass": (lambda r, i: dig_grass(r), 4, -8.0),
    "dig_dirt": (lambda r, i: dig_dirt(r), 4, -7.0),
    "dig_clay": (lambda r, i: dig_clay(r), 4, -7.0),
    "dig_coffin": (lambda r, i: dig_coffin(r), 4, -6.0),
    "dig_rock": (lambda r, i: dig_rock(r), 4, -8.0),
    "layer_break": (lambda r, i: layer_break(r), 3, -4.5),
    "pickup_copper": (pickup_copper, 4, -11.0),
    "pickup_bone": (pickup_bone, 4, -10.0),
    "pickup_soul": (pickup_soul, 3, -10.0),
    "wisp_collect": (wisp_collect, 3, -7.0),
    "oil_tick": (oil_tick, 2, -9.0),
    "oil_out": (oil_out, 2, -5.0),
    "grave_open": (grave_open, 2, -3.0),
    "ui_hover": (ui_hover, 3, -20.0),
    "ui_click": (ui_click, 3, -13.0),
    "ui_panel_open": (ui_panel_open, 2, -14.0),
    "ui_panel_close": (ui_panel_close, 2, -16.0),
    "ui_count_tick": (ui_count_tick, 3, -18.0),
    "node_buy": (node_buy, 3, -8.0),
    "root_grow": (root_grow, 3, -9.0),
    "node_reveal": (node_reveal, 2, -9.0),
    "level_up": (level_up, 1, -7.0),
    "screen_transition": (screen_transition, 2, -8.0),
    # tela-titulo
    "logo_land": (logo_land, 4, -17.0),
    "logo_thunk": (logo_thunk, 2, -6.0),
    "logo_drip": (logo_drip, 3, -20.0),
    "ui_wisp_slide": (ui_wisp_slide, 3, -23.0),
    "ui_bury": (ui_bury, 2, -9.0),
    # leva 3 (jogo completo) -- picos coerentes: grave_open (-3) continua o mais alto
    "stomp": (stomp, 4, -4.0),
    "flare": (flare, 3, -6.0),
    "dig_bone": (dig_bone, 4, -7.0),
    "dig_mud": (dig_mud, 4, -7.0),
    "dig_stone": (dig_stone, 4, -7.0),
    "dig_marble": (dig_marble, 4, -8.0),
    "dig_mist": (dig_mist, 4, -9.0),
    "boss_sink": (boss_sink, 2, -6.0),
    "boss_emerge": (boss_emerge, 2, -5.0),
    "boss_hit": (boss_hit, 3, -6.0),
    "boss_defeat": (boss_defeat, 1, -3.5),
    "card_flip": (card_flip, 3, -15.0),
    "card_pick": (card_pick, 2, -11.0),
    "card_legendary": (card_legendary, 1, -8.0),
    "shop_bell": (shop_bell, 2, -12.0),
    "shop_buy": (shop_buy, 3, -10.0),
    "shop_deny": (shop_deny, 2, -15.0),
    "coin_gold": (coin_gold, 3, -9.0),
    "chest_open": (chest_open, 2, -6.0),
    "bone_rain": (bone_rain, 2, -7.0),
    "soul_wander": (soul_wander, 2, -20.0),
    "tombstone_effect": (tombstone_effect, 3, -10.0),
    "seal": (seal, 2, -10.0),
    "respec": (respec, 2, -8.0),
    "milestone": (milestone, 1, -10.0),
    "helper_mole": (helper_mole, 3, -13.0),
    "helper_cat": (helper_cat, 2, -20.0),
    "dialog_blip": (dialog_blip(""), 3, -19.0),
    "dialog_blip_ossada": (dialog_blip("ossada"), 3, -19.0),
    "dialog_blip_ceifa": (dialog_blip("ceifa"), 3, -19.0),
    "dialog_blip_tiao": (dialog_blip("tiao"), 3, -19.0),
    "dialog_blip_mascate": (dialog_blip("mascate"), 3, -19.0),
    "unrest_warning": (unrest_warning, 2, -6.0),
    "build_complete": (build_complete, 2, -7.0),
}

AMBIENT = {"amb_night": (lambda: amb_night(), -30.0), "amb_souls_choir": (lambda: amb_souls_choir(), -35.0)}

AMB_LUFS = -30.0


def finish(x, peak_db):
    x = np.asarray(x, dtype=float)
    x = hp(x, 30, order=2)
    # corta cauda abaixo de -70 dBFS (relativo ao pico final)
    pk = np.max(np.abs(x))
    thr = pk * 10 ** (-60 / 20)
    idx = np.where(np.abs(x) > thr)[0]
    x = x[: idx[-1] + 1]
    # ataque imediato: remove qualquer silencio inicial
    first = np.where(np.abs(x) > pk * 0.01)[0][0]
    x = x[first:]
    x = fade(x, 0.0005, min(0.012, len(x) / SR * 0.2))
    return x * (10 ** (peak_db / 20) / np.max(np.abs(x)))


def render(id_):
    if id_ in AMBIENT:
        from common import normalize_oneshot
        fn, lufs = AMBIENT[id_]
        st = fn()
        y = normalize_oneshot(st, target_lufs=lufs, name=id_)
        wav = os.path.join(BUILD, id_ + "_1.wav")
        write_wav(wav, y)
        ogg = os.path.join(SFX, id_ + "_1.ogg")
        encode_ogg(wav, ogg)
        print(id_, "%.2f s" % (y.shape[1] / SR), measure(ogg))
        return
    gen, nvar, pk = SPEC[id_]
    for i in range(nvar):
        rng = np.random.default_rng(sum(map(ord, id_)) * 31 + i)
        x = finish(gen(rng, i), pk)
        wav = os.path.join(BUILD, "%s_%d.wav" % (id_, i + 1))
        write_wav(wav, x)
        ogg = os.path.join(SFX, "%s_%d.ogg" % (id_, i + 1))
        encode_ogg(wav, ogg, q=5)
        print("%s_%d %.3f s" % (id_, i + 1, len(x) / SR), measure(ogg))


if __name__ == "__main__":
    ids = sys.argv[1:] or (list(SPEC) + list(AMBIENT))
    for i in ids:
        render(i)
