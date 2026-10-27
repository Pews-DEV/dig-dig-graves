"""Dig Dig Graves - efeitos sonoros sintetizados (mono, 44.1 kHz).

Uso:  python audio_src/sfx.py [id ...]
Cada gerador recebe um rng semeado e devolve uma variacao. Tudo e sintese propria.
"""
import os
import sys

import numpy as np

from dsp import SR, bp, exp_decay, fade, hp, lp, onepole, secs, sweep_bp, peak
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
}

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
    if id_ == "amb_night":
        from common import normalize_oneshot
        st = amb_night()
        y = normalize_oneshot(st, target_lufs=AMB_LUFS, name=id_)
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
    ids = sys.argv[1:] or (list(SPEC) + ["amb_night"])
    for i in ids:
        render(i)
