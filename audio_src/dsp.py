"""Dig Dig Graves - nucleo de sintese e DSP (numpy/scipy).

Instrumentos sintetizados (sem samples de terceiros):
  - violao de nylon: Karplus-Strong vetorizado por periodo + corpo ressonante
  - caixinha de musica: aditiva com parciais de palheta (cantilever)
  - orgao suave: aditiva tipo flauta 8'+4'+16'
  - assovio: senoide com glide, vibrato e sopro
  - coro "aah": aditiva com envelope de formantes
  - sino de capela: parciais inarmonicos de sino (hum/prime/tierce/quint/nominal)
  - reverb de capela: convolucao com IR estereo sintetizada
"""
import numpy as np
from scipy import signal

SR = 44100


def midi_hz(m):
    return 440.0 * 2.0 ** ((np.asarray(m, dtype=float) - 69.0) / 12.0)


def secs(n):
    return int(round(n * SR))


# ---------------------------------------------------------------- filtros

def lp(x, fc, order=2):
    sos = signal.butter(order, min(fc, SR * 0.45), btype="low", fs=SR, output="sos")
    return signal.sosfilt(sos, x)


def hp(x, fc, order=2):
    sos = signal.butter(order, fc, btype="high", fs=SR, output="sos")
    return signal.sosfilt(sos, x)


def bp(x, lo, hi, order=2):
    sos = signal.butter(order, [lo, min(hi, SR * 0.45)], btype="band", fs=SR, output="sos")
    return signal.sosfilt(sos, x)


def peak(x, f0, q):
    b, a = signal.iirpeak(f0, q, fs=SR)
    return signal.lfilter(b, a, x)


def onepole(x, fc):
    p = np.exp(-2 * np.pi * fc / SR)
    return signal.lfilter([1 - p], [1, -p], x)


def sweep_bp(x, f_start, f_end, q=4.0, blocks=64):
    """Passa-banda com centro varrendo (em blocos com crossfade simples)."""
    n = len(x)
    out = np.zeros(n)
    edges = np.linspace(0, n, blocks + 1).astype(int)
    zi = None
    for i in range(blocks):
        a0, a1 = edges[i], edges[i + 1]
        if a1 <= a0:
            continue
        frac = i / max(1, blocks - 1)
        fc = f_start * (f_end / f_start) ** frac
        b, a = signal.iirpeak(min(fc, SR * 0.45), q, fs=SR)
        if zi is None:
            zi = np.zeros(max(len(a), len(b)) - 1)
        out[a0:a1], zi = signal.lfilter(b, a, x[a0:a1], zi=zi)
    return out


# ---------------------------------------------------------------- envelopes

def exp_decay(n, t60):
    t = np.arange(n) / SR
    return np.exp(-6.907755 * t / max(t60, 1e-4))


def fade(x, fin=0.001, fout=0.01):
    x = x.copy()
    a, b = secs(fin), secs(fout)
    if a > 0:
        x[:a] *= np.linspace(0, 1, a)
    if b > 0 and b < len(x):
        x[-b:] *= np.linspace(1, 0, b) ** 2
    return x


def adsr(n, att, rel_start, rel):
    """Ataque suave (seno^2), sustenta, solta exponencial a partir de rel_start (s)."""
    t = np.arange(n) / SR
    env = np.ones(n)
    a = t < att
    env[a] = np.sin(0.5 * np.pi * t[a] / att) ** 2
    r = t >= rel_start
    env[r] *= np.exp(-6.9 * (t[r] - rel_start) / max(rel, 1e-3))
    return env


# ---------------------------------------------------------------- instrumentos

def ks_pluck(freq, dur, rng, vel=0.8, bright=0.5, t60=None, pos=0.17):
    """Corda de nylon dedilhada (Karplus-Strong vetorizado por periodo)."""
    P = SR / freq - 0.5
    N = max(2, int(np.floor(P)))
    out_len = secs(dur)
    nblocks = out_len // N + 3
    y = np.zeros(nblocks * N)
    # forma de "dedo puxando a corda": triangulo com pico na posicao do toque + um pouco de ruido
    pp = pos * rng.uniform(0.85, 1.15)
    xs = np.arange(N) / N
    tri = np.where(xs < pp, xs / pp, (1 - xs) / (1 - pp))
    tri -= tri.mean()
    tri /= np.max(np.abs(tri))
    noise = rng.uniform(-1, 1, N)
    fc = float(np.clip(freq * (6.0 + 16.0 * bright * vel), 350, 6000))  # nylon: macio, relativo ao tom
    noise = onepole(onepole(noise, fc), fc)
    noise -= noise.mean()
    noise /= np.max(np.abs(noise)) + 1e-9
    exc = 0.8 * tri + 0.35 * noise
    exc = onepole(np.concatenate([exc, exc]), fc * 1.5)[N:]  # suaviza a quina do triangulo (periodico)
    exc /= np.max(np.abs(exc)) + 1e-9
    y[:N] = exc
    if t60 is None:
        t60 = float(np.clip(3.2 * (110.0 / freq) ** 0.45, 0.9, 4.5))
    g = 10 ** (-3.0 / (t60 * freq))
    y[N:2 * N] = g * 0.5 * (y[0:N] + np.concatenate([[0.0], y[:N - 1]]))
    for k in range(2, nblocks):
        s = k * N
        y[s:s + N] = g * 0.5 * (y[s - N:s] + y[s - N - 1:s - 1])
    rate = freq / (SR / (N + 0.5))
    idx = np.arange(out_len) * rate
    out = np.interp(idx, np.arange(len(y)), y)
    tt = np.arange(out_len) / SR
    out *= 1 - 0.45 * np.exp(-tt / 0.012)  # polpa do dedo: ataque macio
    out = fade(out, 0.002, min(0.08, dur * 0.3))
    return out * vel


def guitar_body(x):
    body = (0.30 * peak(x, 98, 5) + 0.22 * peak(x, 204, 7) + 0.12 * peak(x, 395, 5))
    return lp(x + body, 6500)


def musicbox(freq, dur, rng, vel=0.8):
    n = secs(dur)
    t = np.arange(n) / SR
    T = float(np.clip(2.6 * (1000.0 / freq) ** 0.35, 1.0, 3.5))
    parts = [(1.0, 1.0, T), (2.0, 0.07, T * 0.5), (3.0, 0.03, T * 0.3),
             (5.93, 0.13, 0.16), (9.2, 0.04, 0.07)]
    out = np.zeros(n)
    for ratio, amp, t60 in parts:
        f = freq * ratio * (1 + rng.uniform(-0.0015, 0.0015))
        if f > 17000:
            continue
        ph = rng.uniform(0, 2 * np.pi)
        out += amp * np.sin(2 * np.pi * f * t + ph) * exp_decay(n, t60)
    # dente vizinho levemente desafinado: brilho/beating suave
    out += 0.08 * np.sin(2 * np.pi * freq * 1.003 * t) * exp_decay(n, T * 0.8)
    click = hp(rng.normal(0, 1, secs(0.004)), 3000) * 0.04
    out[:len(click)] += click * np.linspace(1, 0, len(click))
    return fade(out, 0.0008, 0.05) * vel


def organ(freq, dur, rng, vel=0.5, att=0.35, rel=0.8):
    n = secs(dur + rel)
    t = np.arange(n) / SR
    parts = [(0.5, 0.30), (1.0, 1.0), (2.0, 0.40), (3.0, 0.10), (4.0, 0.12), (6.0, 0.03)]
    out = np.zeros(n)
    for ratio, amp in parts:
        f = freq * ratio
        if f > 12000:
            continue
        for det in (-0.0012, 0.0012):
            out += 0.5 * amp * np.sin(2 * np.pi * f * (1 + det) * t + rng.uniform(0, 6.28))
    env = adsr(n, att, dur, rel)
    return lp(out * env, 3500) * vel


def whistle_line(notes, rng, glide=0.035, vib_depth=0.16, vib_rate=5.4):
    """notes: lista (start_s, dur_s, midi, vel). Retorna sinal mono contínuo."""
    if not notes:
        return np.zeros(1), 0.0
    t0 = notes[0][0]
    end = max(s + d for s, d, _, _ in notes) - t0 + 0.4
    n = secs(end)
    logf = np.full(n, np.nan)
    amp = np.zeros(n)
    onset_age = np.zeros(n)
    prev_end = -1.0
    for i, (s, d, m, v) in enumerate(notes):
        a, b = secs(s - t0), min(n, secs(s - t0 + d))
        logf[a:b] = m
        legato = abs((s - t0) - prev_end) < 0.02
        seg = np.full(b - a, v)
        k = secs(0.018)
        if legato and b - a > 2 * k:
            seg[:k] *= np.linspace(0.45, 1, k)
        elif not legato:
            # leve "scoop" de entrada
            logf[a:a + secs(0.05)] = m - 0.7
        rel = min(secs(0.06), b - a)
        seg[-rel:] *= np.linspace(1, 0.0 if i == len(notes) - 1 or notes[i + 1][0] - s - d > 0.02 else 0.6, rel)
        amp[a:b] = seg
        onset_age[a:b] = np.arange(b - a) / SR
        prev_end = s - t0 + d
    # preenche buracos com a ultima nota (para o glide)
    valid = ~np.isnan(logf)
    idx = np.where(valid, np.arange(n), 0)
    np.maximum.accumulate(idx, out=idx)
    logf = logf[idx]
    logf = onepole(logf - logf[0], 1 / (2 * np.pi * glide)) + logf[0]
    tt = np.arange(n) / SR
    vib = vib_depth * np.sin(2 * np.pi * vib_rate * tt + rng.uniform(0, 6)) * np.clip((onset_age - 0.18) / 0.3, 0, 1)
    f = midi_hz(logf + vib + 0.04 * np.sin(2 * np.pi * 0.7 * tt))
    ph = np.cumsum(2 * np.pi * f / SR)
    amp_s = onepole(amp, 40)
    tone = np.sin(ph) + 0.05 * np.sin(2 * ph)
    breath = bp(rng.normal(0, 1, n), 1500, 6000) * 0.035
    out = (tone + breath) * amp_s
    return out, t0


VOWEL_AH = [(730, 90, 1.0), (1150, 110, 0.55), (2650, 160, 0.22), (3300, 200, 0.12)]


def choir_voice(freq, dur, rng, att=0.25, rel=0.6, vowel=VOWEL_AH):
    n = secs(dur + rel)
    t = np.arange(n) / SR
    vib = 0.13 * np.sin(2 * np.pi * rng.uniform(4.6, 5.6) * t + rng.uniform(0, 6))
    drift = 0.05 * np.sin(2 * np.pi * rng.uniform(0.2, 0.5) * t + rng.uniform(0, 6))
    f = freq * 2 ** ((vib + drift + rng.uniform(-0.08, 0.08)) / 12)
    ph = np.cumsum(2 * np.pi * f / SR)
    out = np.zeros(n)
    k = 1
    while k * freq < 7000:
        fk = k * freq
        a = sum(g / (1 + ((fk - F) / bw) ** 2) for F, bw, g in vowel) / k ** 0.6
        out += a * np.sin(k * ph + rng.uniform(0, 6))
        k += 1
    breath = bp(rng.normal(0, 1, n), 600, 3000) * 0.02
    env = adsr(n, att, dur, rel)
    return (out + breath) * env


def bell(freq, dur, rng, vel=1.0):
    """Sino de capela; freq = 'prime' (tom percebido)."""
    n = secs(dur)
    t = np.arange(n) / SR
    parts = [(0.5, 0.55, 5.0), (1.0, 0.55, 3.6), (1.26, 0.40, 3.0), (1.5, 0.20, 2.2),
             (2.0, 0.65, 2.6), (2.52, 0.18, 1.4), (2.66, 0.14, 1.2), (3.01, 0.16, 0.9),
             (4.07, 0.08, 0.6), (5.4, 0.05, 0.35)]
    out = np.zeros(n)
    for r, a, t60 in parts:
        f = freq * r
        if f > 16000:
            continue
        out += a * np.sin(2 * np.pi * f * t + rng.uniform(0, 6)) * exp_decay(n, t60)
        out += 0.3 * a * np.sin(2 * np.pi * f * 1.0022 * t) * exp_decay(n, t60)
    strike = bp(rng.normal(0, 1, secs(0.03)), 1500, 7000) * exp_decay(secs(0.03), 0.02) * 0.3
    out[:len(strike)] += strike
    return fade(out, 0.0005, 0.2) * vel


# ---------------------------------------------------------------- espaco

def make_ir(t60=2.2, length=3.0, predelay=0.018, seed=7, hf=0.45):
    rng = np.random.default_rng(seed)
    n = secs(length)
    t = np.arange(n) / SR
    chans = []
    for ch in range(2):
        noise = rng.normal(0, 1, n)
        low = lp(noise, 400) * np.exp(-6.9 * t / (t60 * 1.15))
        mid = bp(noise, 400, 3000) * np.exp(-6.9 * t / t60)
        high = hp(noise, 3000) * np.exp(-6.9 * t / (t60 * hf)) * 0.5
        ir = low + mid + high
        ir *= np.clip(t / 0.03, 0, 1)  # difusao cresce
        er = np.zeros(n)
        for d, g in [(0.007, 0.5), (0.013, 0.35), (0.021, 0.3), (0.029, 0.22), (0.041, 0.15)]:
            er[secs(d + 0.002 * ch)] = g * rng.choice([-1, 1])
        ir = ir / np.sqrt(np.sum(ir ** 2)) + er * 0.6
        ir = np.concatenate([np.zeros(secs(predelay)), ir])
        chans.append(ir / np.sqrt(np.sum(ir ** 2)))
    return chans


def reverb(st, ir, mix=0.25, predelay_hp=180):
    """st: array (2, n). Retorna (2, n + len(ir)-1)."""
    L = signal.fftconvolve(hp(st[0], predelay_hp), ir[0])
    R = signal.fftconvolve(hp(st[1], predelay_hp), ir[1])
    n = st.shape[1]
    out = np.zeros((2, len(L)))
    out[:, :n] = st * (1 - mix * 0.5)
    out[0] += L * mix
    out[1] += R * mix
    return out


def pan_gains(p):
    a = (p + 1) * np.pi / 4
    return np.cos(a), np.sin(a)


class Bus:
    """Barramento estereo onde se somam eventos por tempo."""

    def __init__(self, length_s):
        self.buf = np.zeros((2, secs(length_s)))

    def add(self, x, start_s, pan=0.0, gain=1.0):
        a = secs(start_s)
        if a < 0:
            x = x[-a:]
            a = 0
        b = min(self.buf.shape[1], a + len(x))
        if b <= a:
            return
        gl, gr = pan_gains(pan)
        self.buf[0, a:b] += x[:b - a] * gain * gl
        self.buf[1, a:b] += x[:b - a] * gain * gr

    def add_st(self, st, start_s, gain=1.0):
        a = secs(start_s)
        b = min(self.buf.shape[1], a + st.shape[1])
        self.buf[:, a:b] += st[:, :b - a] * gain


# ---------------------------------------------------------------- dinamica

def limiter(x, ceiling_db=-1.5, attack=0.003, release=0.12):
    """Limitador com lookahead (x: (ch, n)). Retorna sinal e GR maxima em dB."""
    ceil = 10 ** (ceiling_db / 20)
    mono_peak = np.max(np.abs(x), axis=0)
    need = np.minimum(1.0, ceil / np.maximum(mono_peak, 1e-9))
    la = secs(attack)
    # minimo deslizante (lookahead)
    from scipy.ndimage import minimum_filter1d
    g = minimum_filter1d(need, size=2 * la + 1, mode="nearest")
    # release suave (one-pole subindo), ataque instantaneo ja garantido pelo minimo
    p = np.exp(-1 / (release * SR))
    gs = signal.lfilter([1 - p], [1, -p], g, zi=[g[0] * p])[0]
    gs = np.minimum(gs, g)
    gs = np.concatenate([np.full(la, gs[0]), gs, np.full(la, gs[-1])])
    gs = signal.lfilter(np.ones(la) / la, [1], gs)  # suaviza (FIR centrado)
    gs = gs[la + la // 2: la + la // 2 + x.shape[1]]
    gs = np.minimum(gs, 1.0)
    out = x * gs
    # garante teto
    out = np.clip(out, -ceil, ceil)
    return out, 20 * np.log10(np.min(gs) + 1e-12)


def compressor(x, thr_db=-24.0, ratio=2.5, att=0.005, rel=0.12, makeup=True):
    """Compressor feed-forward simples (x: (ch, n)), detector de pico estereo linkado."""
    det = np.max(np.abs(x), axis=0)
    pa = np.exp(-1 / (att * SR))
    pr = np.exp(-1 / (rel * SR))
    # ataque rapido via lfilter + max com release lento
    ea = signal.lfilter([1 - pa], [1, -pa], det)
    er = signal.lfilter([1 - pr], [1, -pr], det)
    env = np.maximum(ea, er)
    lvl = 20 * np.log10(env + 1e-9)
    over = np.maximum(0, lvl - thr_db)
    gdb = -over * (1 - 1 / ratio)
    g = 10 ** (gdb / 20)
    return x * g


def soft_sat(x, drive=1.0):
    return np.tanh(x * drive) / np.tanh(drive)
