"""Dig Dig Graves - composicao e render das musicas (seresta assombrada lo-fi).

Uso:  python audio_src/music.py [id ...]
Ids: mus_title, mus_tree, mus_area1, jingle_summary, stinger_grave, stinger_level
Todas as melodias sao originais, escritas aqui.
"""
import os
import sys

import numpy as np

from dsp import (SR, Bus, bell, choir_voice, guitar_body, ks_pluck, lp, make_ir, midi_hz,
                 musicbox, organ, reverb, compressor, secs, whistle_line, hp, bp, exp_decay, fade, peak)
from common import (BUILD, MUSIC, PREV, encode_ogg, measure, normalize_loop,
                    normalize_oneshot, write_wav)

# ------------------------------------------------------------------ teoria

NOTE = {"C": 0, "C#": 1, "Db": 1, "D": 2, "D#": 3, "Eb": 3, "E": 4, "F": 5, "F#": 6,
        "Gb": 6, "G": 7, "G#": 8, "Ab": 8, "A": 9, "A#": 10, "Bb": 10, "B": 11}


def n2m(s):
    name, octv = s[:-1], int(s[-1])
    return 12 * (octv + 1) + NOTE[name]


_QUAL = {"": [0, 4, 7], "m": [0, 3, 7], "7": [0, 4, 7, 10], "m7": [0, 3, 7, 10],
         "maj7": [0, 4, 7, 11], "dim": [0, 3, 6], "dim7": [0, 3, 6, 9], "m7b5": [0, 3, 6, 10],
         "sus4": [0, 5, 7], "add9": [0, 4, 7, 2], "madd9": [0, 3, 7, 2]}


class _Chords(dict):
    """Acordes fixos (leva 1-2) + gerados sob demanda ('Ebmaj7', 'F#m', 'A/C#'...)."""

    def __missing__(self, name):
        main, _, slash = name.partition("/")
        r = main[0] + (main[1] if len(main) > 1 and main[1] in "#b" else "")
        q = main[len(r):]
        iv = _QUAL[q]
        root = NOTE[r]
        pcs = [(root + i) % 12 for i in iv]
        bass = next(m for m in range(40, 52) if m % 12 == NOTE[slash or r])
        i5 = iv[2]
        alt = bass - (12 - i5) if bass - (12 - i5) >= 40 else bass + i5
        if slash:  # baixo invertido: o alternado e a fundamental
            alt = next(m for m in range(40, 52) if m % 12 == root)
        up = [m for m in range(52, 76) if m % 12 in pcs][:4]
        self[name] = (bass, alt, up, pcs)
        return self[name]


# nome: (baixo, baixo alternado, notas agudas do violao, classes de altura p/ orgao)
CHORDS = _Chords({
    "Am": (45, 40, [52, 57, 60, 64], [9, 0, 4]),
    "AmG": (43, 40, [52, 57, 60, 64], [9, 0, 4]),
    "F": (41, 48, [53, 57, 60, 65], [5, 9, 0]),
    "E7": (40, 47, [50, 56, 59, 64], [4, 8, 11, 2]),
    "Dm": (50, 45, [57, 62, 65, 69], [2, 5, 9]),
    "G7": (43, 50, [50, 55, 59, 65], [7, 11, 2, 5]),
    "C": (48, 43, [52, 55, 60, 64], [0, 4, 7]),
    "A7": (45, 40, [52, 55, 61, 64], [9, 1, 4, 7]),
    "G": (43, 50, [50, 55, 59, 62], [7, 11, 2]),
    "Gm": (43, 50, [50, 55, 58, 62], [7, 10, 2]),
    "Bb": (46, 41, [53, 58, 62, 65], [10, 2, 5]),
    "C7": (48, 43, [52, 58, 60, 64], [0, 4, 7, 10]),
    "A": (45, 40, [52, 57, 61, 64], [9, 1, 4]),
})


def mel(s):
    """'E6:1.5 D6:.5 r:1' -> [(midi|None, beats)]"""
    out = []
    for tok in s.split():
        p, d = tok.split(":")
        out.append((None if p == "r" else n2m(p), float(d)))
    return out


def voice_lead(pcs, prev):
    """Escolhe, para cada voz anterior, a altura mais proxima com classe em pcs."""
    used, out = set(), []
    for v in prev:
        best = None
        for m in range(v - 6, v + 7):
            if m % 12 in pcs and (m % 12 not in used or len(used) >= len(pcs)):
                if best is None or abs(m - v) < abs(best - v):
                    best = m
        used.add(best % 12)
        out.append(best)
    return out


class Song:
    def __init__(self, bpm, beats_per_bar, bars, tail=5.0, seed=1):
        self.beat = 60.0 / bpm
        self.bpb = beats_per_bar
        self.bars = bars
        self.length = self.beat * beats_per_bar * bars
        self.rng = np.random.default_rng(seed)
        total = self.length + tail
        self.gtr = Bus(total)
        self.box = Bus(total)
        self.org = Bus(total)
        self.wh = Bus(total)
        self.perc = Bus(total)
        self.choir = Bus(total)
        self.extra = {}
        self._total = total

    def bus(self, name):
        """Barramento extra (leva 3: sanfona, cravo, piano, tambor, nevoa, gotas...)."""
        if name not in self.extra:
            self.extra[name] = Bus(self._total)
        return self.extra[name]

    def t(self, bar, beat=0.0, jitter=0.0):
        x = (bar * self.bpb + beat) * self.beat
        if jitter:
            x += self.rng.normal(0, jitter)
        return max(0.0, x)

    # violao ------------------------------------------------------------
    def pluck(self, bar, beat, midi, ring, vel, pan=-0.22, bright=0.5):
        v = vel * self.rng.uniform(0.88, 1.08)
        x = ks_pluck(midi_hz(midi), ring, self.rng, vel=v, bright=bright)
        self.gtr.add(x, self.t(bar, beat, 0.006), pan=pan + self.rng.uniform(-0.05, 0.05))

    def roll(self, bar, beat, notes, ring, vel, spread=0.014, **kw):
        for i, m in enumerate(notes):
            self.pluck(bar, beat + i * spread / self.beat, m, ring, vel * (0.9 + 0.1 * i / len(notes)), **kw)

    def gtr_waltz(self, bar, ch, vel=0.8, alt=False):
        b, a, up, _ = CHORDS[ch]
        bar_s = self.bpb * self.beat
        self.pluck(bar, 0, a if alt else b, bar_s * 1.1, vel, bright=0.35)
        self.roll(bar, 1, up[1:], self.beat * 1.1, vel * 0.55)
        self.roll(bar, 2, up[1:], self.beat * 1.3, vel * 0.5)

    def gtr_arp3(self, bar, ch, vel=0.8, alt=False):
        b, a, up, _ = CHORDS[ch]
        bar_s = self.bpb * self.beat
        self.pluck(bar, 0, a if alt else b, bar_s * 1.1, vel, bright=0.35)
        seq = [1, 2, 3, 2, 1] if len(up) >= 4 else [0, 1, 2, 1, 0]
        for i, idx in enumerate(seq):
            self.pluck(bar, 0.5 * (i + 1), up[idx], self.beat * 1.8, vel * (0.55 if i % 2 else 0.62))

    def gtr_travis(self, bar, ch, vel=0.8):
        b, a, up, _ = CHORDS[ch]
        bt = self.beat
        self.pluck(bar, 0, b, bt * 1.9, vel, bright=0.35)
        self.pluck(bar, 2, a, bt * 1.9, vel * 0.85, bright=0.35)
        hi = up[-3:]
        for beat in (0.5, 1.5, 2.5, 3.5):
            self.pluck(bar, beat, hi[0], bt * 0.9, vel * 0.42)
        for beat in (1, 3):
            self.pluck(bar, beat, hi[1], bt * 1.0, vel * 0.5)
            self.pluck(bar, beat + 0.01, hi[2], bt * 1.0, vel * 0.5)

    # outros --------------------------------------------------------------
    def box_line(self, bar0, notes, vel=0.6, transpose=0, pan=0.32, ring=2.6):
        beat = 0.0
        for m, d in notes:
            if m is not None:
                v = vel * self.rng.uniform(0.85, 1.05)
                x = musicbox(midi_hz(m + transpose), ring, self.rng, vel=v)
                self.box.add(x, self.t(bar0, beat, 0.004), pan=pan)
            beat += d

    def box_note(self, bar, beat, m, vel=0.4, pan=0.32, ring=2.4):
        x = musicbox(midi_hz(m), ring, self.rng, vel=vel * self.rng.uniform(0.85, 1.05))
        self.box.add(x, self.t(bar, beat, 0.004), pan=pan)

    def whistle(self, bar0, notes, vel=0.5, transpose=0, pan=0.08, gap=0.0):
        evs = []
        beat = 0.0
        for m, d in notes:
            if m is not None:
                s = self.t(bar0, beat, 0.008)
                evs.append((s, d * self.beat - gap, m + transpose, vel * self.rng.uniform(0.9, 1.05)))
            beat += d
        # legato: encosta o fim de cada nota no inicio da proxima
        evs2 = []
        for i, (s, d, m, v) in enumerate(evs):
            if i + 1 < len(evs) and evs[i + 1][0] - (s + d) < 0.03:
                d = evs[i + 1][0] - s
            evs2.append((s, d, m, v))
        x, t0 = whistle_line(evs2, self.rng)
        self.wh.add(x, t0, pan=pan)

    def organ_bars(self, bar0, chords, vel=0.18, start_voices=(57, 60, 64), bars_per_chord=1):
        voices = list(start_voices)
        for i, ch in enumerate(chords):
            pcs = CHORDS[ch][3]
            voices = voice_lead(pcs, voices)
            dur = bars_per_chord * self.bpb * self.beat
            for k, m in enumerate(voices):
                x = organ(midi_hz(m), dur + 0.05, self.rng, vel=vel, att=0.3, rel=0.7)
                self.org.add(x, self.t(bar0 + i * bars_per_chord), pan=(-0.45, 0.0, 0.45)[k % 3])
            # pedal 16' bem discreto
            root = CHORDS[ch][0] if ch != "AmG" else 43
            x = organ(midi_hz(root), dur + 0.05, self.rng, vel=vel * 0.35, att=0.4, rel=0.7)
            self.org.add(x, self.t(bar0 + i * bars_per_chord), pan=0.0)

    def brush(self, bar, beat, vel=0.25):
        n = secs(0.22)
        x = bp(self.rng.normal(0, 1, n), 1800, 8000) * exp_decay(n, 0.16)
        x[:secs(0.006)] *= np.linspace(0, 1, secs(0.006))
        self.perc.add(x * vel, self.t(bar, beat, 0.005), pan=self.rng.uniform(-0.15, 0.15))

    def shaker(self, bar, beat, vel=0.08):
        n = secs(0.08)
        env = np.minimum(np.linspace(0, 1, n) * 5, 1) * exp_decay(n, 0.06)
        x = hp(self.rng.normal(0, 1, n), 5000) * env
        self.perc.add(x * vel, self.t(bar, beat, 0.006), pan=0.35)

    def woodblock(self, bar, beat, vel=0.2, f=620):
        n = secs(0.15)
        t = np.arange(n) / SR
        x = (np.sin(2 * np.pi * f * t) * exp_decay(n, 0.07) + 0.4 * np.sin(2 * np.pi * f * 2.7 * t) * exp_decay(n, 0.03))
        self.perc.add(fade(x, 0.0005, 0.01) * vel, self.t(bar, beat, 0.004), pan=-0.3)

    # mix -----------------------------------------------------------------
    def mix(self, gains, rev_mix=0.28, t60=2.3, loop=True, echo_send=None, echo_cfg=None):
        """Em modo loop, tudo e circular: os barramentos secos sao 'enrolados' no
        comprimento do loop (a cauda soma no inicio), compressores/filtros rodam sobre
        3 copias (pega-se a do meio) e o reverb e convolucao circular. Costura exata."""
        g = gains
        L = secs(self.length)
        wrap = (lambda x: _wrap(x, L)) if loop else (lambda x: x)
        circ = _circ if loop else (lambda fn, x: fn(x))

        def body_comp(x):
            y = np.stack([guitar_body(x[0]), guitar_body(x[1])])
            return compressor(y, thr_db=-24, ratio=3.0, att=0.002, rel=0.15)
        gtr = circ(body_comp, wrap(self.gtr.buf))
        dry = (gtr * g.get("gtr", 1) + wrap(self.box.buf) * g.get("box", 1)
               + wrap(self.org.buf) * g.get("org", 1) + wrap(self.wh.buf) * g.get("wh", 1)
               + wrap(self.perc.buf) * g.get("perc", 1) + wrap(self.choir.buf) * g.get("choir", 1))
        for k, b in self.extra.items():
            dry = dry + wrap(b.buf) * g.get(k, 1)
        if echo_send:
            from dsp import echo as _echo
            src = sum((self.extra[k].buf if k in self.extra else getattr(self, k).buf) * v * g.get(k, 1)
                      for k, v in echo_send.items())
            dry = dry + wrap(_echo(src, **(echo_cfg or {})))
        ir = make_ir(t60=t60, length=t60 * 1.5)
        wet = wrap(reverb(dry, ir, mix=rev_mix))

        def master(x):
            x = compressor(x, thr_db=-18, ratio=2.0, att=0.004, rel=0.25)
            # cor lo-fi: topo suave, sem subgrave
            return np.stack([hp(lp(c, 9500, order=1), 35) for c in x])
        return circ(master, wet)


def _wrap(x, L):
    out = x[:, :L].copy()
    rest = x[:, L:]
    while rest.shape[1] > 0:
        k = min(L, rest.shape[1])
        out[:, :k] += rest[:, :k]
        rest = rest[:, k:]
    return out


def _circ(fn, x):
    n = x.shape[1]
    return fn(np.concatenate([x, x, x], axis=1))[:, n:2 * n]


# ------------------------------------------------------------------ faixas

def build_tree():
    s = Song(bpm=74, beats_per_bar=3, bars=48, seed=11)
    A = ["Am", "AmG", "F", "E7", "Am", "Dm", "E7", "Am"]
    B = ["Dm", "G7", "C", "Am", "Dm", "E7", "Am", "A7"]
    C = ["F", "G", "C", "Am", "F", "G", "C", "E7"]
    B_end = B[:-1] + ["E7"]
    melA = mel("E6:1.5 D6:.5 C6:1  B5:1 C6:1 E6:1  A5:2 C6:1  B5:1.5 G#5:.5 B5:1 "
               "A5:1 C6:1 E6:1  F6:1.5 E6:.5 D6:1  D6:1 B5:1 G#5:1  A5:3")
    melB = mel("D6:1 F6:1 A6:1  G6:1.5 F6:.5 D6:1  E6:2 C6:1  C6:1 B5:.5 A5:.5 E5:1 "
               "F5:1 A5:1 D6:1  E6:1.5 D6:.5 B5:1  C6:1 A5:2  C#6:1 E6:1 G6:1")
    melB_end = melB[:-3] + mel("D6:1 B5:1 G#5:1")
    melC = mel("C6:1 A5:1 C6:1  D6:2 B5:1  E6:1.5 D6:.5 C6:1  A5:3 "
               "F6:1 E6:1 C6:1  D6:1.5 C6:.5 B5:1  C6:1 E6:1 G6:1  E6:1.5 D6:.5 B5:1")

    form = [("A0", A), ("A1", A), ("B1", B), ("C1", C), ("A2", A), ("B2", B_end)]
    bar = 0
    for name, chords in form:
        for i, ch in enumerate(chords):
            alt = (i % 2 == 1) and ch == chords[i - 1]
            if name in ("A0", "B2"):
                s.gtr_waltz(bar + i, ch, vel=0.78 if name == "A0" else 0.72, alt=alt)
            else:
                s.gtr_arp3(bar + i, ch, vel=0.74, alt=alt)
        if name == "A0":
            s.organ_bars(bar + 4, chords[4:], vel=0.10)
        elif name == "C1":
            s.organ_bars(bar, chords, vel=0.17, start_voices=(57, 60, 65))
        else:
            s.organ_bars(bar, chords, vel=0.14)
        if name == "A1":
            s.box_line(bar, melA, vel=0.55)
        elif name == "B1":
            s.box_line(bar, melB, vel=0.55)
        elif name == "C1":
            s.whistle(bar, melC, vel=0.5)
            for i, ch in enumerate(chords):  # contracanto: caixinha esparsa, oitava acima
                pcs = CHORDS[ch][3]
                top = [m for m in range(84, 97) if m % 12 in pcs]
                s.box_note(bar + i, 0, top[1], vel=0.22)
                s.box_note(bar + i, 1.5, top[0], vel=0.17)
        elif name == "A2":
            s.whistle(bar, melA, vel=0.5)
            for i, ch in enumerate(chords):
                pcs = CHORDS[ch][3]
                top = [m for m in range(81, 94) if m % 12 in pcs]
                s.box_note(bar + i, 0.5, top[0], vel=0.16)
                s.box_note(bar + i, 2, top[2], vel=0.14)
        elif name == "B2":
            s.box_line(bar, melB_end, vel=0.5)
        bar += len(chords)
    assert bar == s.bars
    out = s.mix({"gtr": 0.6, "box": 0.72, "org": 0.5, "wh": 0.4}, rev_mix=0.3, t60=2.4)
    return out, s


def build_area1():
    s = Song(bpm=88, beats_per_bar=4, bars=44, seed=23)
    intro = ["Dm", "Gm", "Dm", "A7"]
    A = ["Dm", "Dm", "Gm", "A7", "Dm", "Bb", "A7", "Dm"]
    B = ["F", "C", "Bb", "F", "Gm", "C7", "F", "A7"]
    BR = ["Gm", "Dm", "Gm", "A7", "Bb", "F", "Gm", "A7"]
    melA = mel("A5:1.5 F5:.5 D5:1 F5:1  E5:.5 F5:.5 G5:.5 A5:.5 D6:2  Bb5:1.5 A5:.5 G5:1 D5:1 "
               "C#6:1 A5:1 E5:1 G5:1  F5:1 A5:1 D6:1.5 C6:.5  D6:1 Bb5:1 F5:2  "
               "E5:1 G5:1 C#6:1 E6:1  D6:3 r:1")
    melB = mel("C6:1 A5:.5 C6:.5 F6:2  E6:1 D6:.5 C6:.5 G5:2  D6:1.5 C6:.5 Bb5:1 F5:1  A5:3 r:1 "
               "Bb5:1 D6:1 G6:1.5 F6:.5  E6:1 C6:1 Bb5:1 G5:1  A5:1 C6:1 F6:2  E6:1 C#6:1 A5:2")
    form = [("I", intro), ("A1", A), ("A2", A), ("B1", B), ("A3", A), ("BR", BR)]
    bar = 0
    for name, chords in form:
        for i, ch in enumerate(chords):
            b = bar + i
            if name == "I":
                _, _, up, _ = CHORDS[ch]
                s.pluck(b, 0, CHORDS[ch][0], s.beat * 4.2, 0.75, bright=0.35)
                s.roll(b, 1, up[1:], s.beat * 2.0, 0.42)
                s.roll(b, 2.5, up[1:], s.beat * 1.5, 0.36)
            else:
                s.gtr_travis(b, ch, vel=0.7 if name != "BR" else 0.6)
            # percussao: escovinha em 2 e 4, chocalho em colcheias, bloco de madeira
            if name != "I":
                s.brush(b, 1, 0.22)
                s.brush(b, 3, 0.25)
            if name in ("A2", "B1", "A3"):
                for k in range(8):
                    s.shaker(b, k * 0.5, 0.05 if k % 2 else 0.075)
            if name in ("B1", "A3") and i % 2 == 1:
                s.woodblock(b, 3.5, 0.13)
        vel_org = {"I": 0.08, "A1": 0.12, "A2": 0.12, "B1": 0.15, "A3": 0.14, "BR": 0.17}[name]
        s.organ_bars(bar, chords, vel=vel_org, start_voices=(57, 62, 65))
        if name == "A1":
            s.box_line(bar, melA, vel=0.5, transpose=12)
        elif name == "A2":
            s.whistle(bar, melA, vel=0.48)
            for i, ch in enumerate(chords):
                top = [m for m in range(86, 99) if m % 12 in CHORDS[ch][3]]
                s.box_note(bar + i, 1.5, top[0], vel=0.14)
                s.box_note(bar + i, 3.5, top[1], vel=0.12)
        elif name == "B1":
            s.whistle(bar, melB, vel=0.5)
            for i, ch in enumerate(chords):
                top = [m for m in range(84, 99) if m % 12 in CHORDS[ch][3]]
                for k, bt in enumerate((0, 1, 2, 3)):
                    s.box_note(bar + i, bt + 0.5, top[(k * 2) % len(top)], vel=0.11)
        elif name == "A3":
            s.box_line(bar, melA, vel=0.5, transpose=12)
            s.whistle(bar, [(m - 12 if m else None, d) for m, d in melA], vel=0.22, pan=-0.1)
        elif name == "BR":
            for i, ch in enumerate(chords):
                top = [m for m in range(79, 92) if m % 12 in CHORDS[ch][3]]
                s.box_note(bar + i, 0, top[-1], vel=0.2)
                s.box_note(bar + i, 2.5, top[1], vel=0.15)
        bar += len(chords)
    assert bar == s.bars
    out = s.mix({"gtr": 0.58, "box": 0.72, "org": 0.5, "wh": 0.4, "perc": 1.6}, rev_mix=0.24, t60=2.0)
    return out, s


def build_jingle():
    """Resumo do turno: Am -> F -> G -> A maior (picardia), caixinha subindo, ~6.5 s."""
    s = Song(bpm=80, beats_per_bar=4, bars=3, tail=6, seed=5)
    s.roll(0, 0, [45, 52, 57, 60, 64], s.beat * 2.2, 0.7, spread=0.02)
    s.roll(0, 2, [41, 53, 57, 60, 65], s.beat * 2.2, 0.68, spread=0.02)
    s.roll(1, 0, [43, 50, 55, 59, 67], s.beat * 2.2, 0.7, spread=0.02)
    s.roll(1, 2, [45, 52, 57, 61, 64, 69], 4.5, 0.8, spread=0.035)
    s.box_line(0, mel("E6:.5 A6:.5 C7:1 A6:.5 C7:.5 F7:1 D7:.5 G7:.5 B6:1 A6:.5 C#7:.5 E7:1.5 A7:2"), vel=0.5, transpose=-12)
    for k, m in enumerate([57, 61, 64]):
        s.org.add(organ(midi_hz(m), 3.0, s.rng, vel=0.16, att=0.4, rel=1.6), s.t(1, 2), pan=(-0.4, 0, 0.4)[k])
    s.org.add(organ(midi_hz(45), 3.0, s.rng, vel=0.07, att=0.4, rel=1.6), s.t(1, 2))
    out = s.mix({"gtr": 0.9, "box": 0.6, "org": 0.7}, rev_mix=0.3, t60=2.2, loop=False)
    n = secs(7.0)
    out = out[:, :n]
    tail = secs(1.2)
    out[:, -tail:] *= np.linspace(1, 0, tail) ** 2
    return out


def build_grave():
    """Cova aberta: sino de capela + coro 'aah' em La maior, ~2.2 s."""
    rng = np.random.default_rng(9)
    s = Song(bpm=120, beats_per_bar=4, bars=2, tail=4, seed=9)
    b = bell(midi_hz(69), 2.6, rng, vel=0.8)
    s.choir.add(b, 0.0, pan=-0.1, gain=0.9)
    for m, p in [(57, -0.3), (61, 0.25), (64, -0.1), (69, 0.3), (45, 0.0)]:
        for v in range(3):
            x = choir_voice(midi_hz(m), 0.9, rng, att=0.12, rel=0.9)
            s.choir.add(x * (0.5 if m == 45 else 0.32), 0.04 + 0.01 * v, pan=p + rng.uniform(-0.15, 0.15))
    out = s.mix({"choir": 1.0}, rev_mix=0.35, t60=2.0, loop=False)
    n = secs(2.4)
    out = out[:, :n]
    k = secs(0.5)
    out[:, -k:] *= np.linspace(1, 0, k) ** 2
    return out


def build_level():
    """Subiu de nivel: caixinha ascendente brilhante, ~1.1 s."""
    s = Song(bpm=120, beats_per_bar=4, bars=1, tail=3, seed=3)
    for i, m in enumerate([81, 85, 88, 93, 97]):
        x = musicbox(midi_hz(m), 1.4, s.rng, vel=0.55 + 0.08 * i)
        s.box.add(x, i * 0.065, pan=-0.3 + 0.15 * i)
    x = musicbox(midi_hz(105), 1.0, s.rng, vel=0.25)
    s.box.add(x, 0.33, pan=0.3)
    out = s.mix({"box": 1.0}, rev_mix=0.3, t60=1.6, loop=False)
    n = secs(1.25)
    out = out[:, :n]
    k = secs(0.35)
    out[:, -k:] *= np.linspace(1, 0, k) ** 2
    return out


def build_title():
    """Tema principal (tela-titulo). La menor, 80 BPM, 4/4, 36 compassos = 108 s.

    Motivo-mae "M" (compartilhado): grau 5 pontuado descendo por grau ate o 3 e caindo no 1
    (ritmo longo-curto-longo: 1,5 + 0,5 + 1), respondido por subida em graus 2-3-4-5 ate a oitava.
      - mus_tree abre com a metade de cima de M (E-D-C = 5-4-3, pontuado) e a resposta 2-3-5.
      - mus_area1 abre com M "em arpejo" (A-F-D = 5-3-1, pontuado) e a resposta 2-3-4-5-8.
    Motivo de cadencia "C": arpejo descendente do V7 ate a sensivel (4-2-#7 -> 1), igual ao
    D-B-G#-A de mus_tree e ao C#-E-D de mus_area1.
    """
    s = Song(bpm=80, beats_per_bar=4, bars=36, seed=41)
    intro = ["Am", "F", "Dm", "E7"]
    A = ["Am", "AmG", "F", "E7", "Dm", "Am", "E7", "Am"]
    B = ["F", "G", "C", "Am", "Dm", "G7", "C", "E7"]
    # escrito uma oitava abaixo; caixinha/assovio tocam +12
    melA = mel("E5:1.5 D5:.5 C5:1 A4:1  B4:.5 C5:.5 D5:.5 E5:.5 A5:2  "
               "G5:1.5 F5:.5 E5:1 C5:1  D5:1 B4:1 G#4:1 B4:1  "
               "F5:1.5 E5:.5 D5:1 A4:1  C5:1 E5:1 A5:1.5 G5:.5  "
               "F5:1 D5:1 B4:1 G#4:1  A4:3 r:1")
    melB = mel("A5:1.5 G5:.5 F5:1 C5:1  D5:.5 E5:.5 F5:.5 G5:.5 B5:2  "
               "C6:1.5 B5:.5 G5:1 E5:1  A5:1.5 G5:.5 E5:2  "
               "F5:1 A5:1 D6:1.5 C6:.5  B5:1 G5:1 F5:1 D5:1  "
               "E5:1.5 D5:.5 C5:1 G4:1  B4:1 D5:1 E5:1 G#5:1")
    # final do ultimo A mais ralo, deixando o loop "respirar" antes da intro
    melA_end = melA[:-2] + mel("A4:4")

    def seresta(b, ch, vel):
        bass, alt, up, _ = CHORDS[ch]
        bt = s.beat
        s.pluck(b, 0, bass, bt * 2.2, vel, bright=0.35)
        s.pluck(b, 2, alt, bt * 2.2, vel * 0.8, bright=0.35)
        for beat, idx, v in ((0.5, 1, 0.45), (1.0, 2, 0.5), (1.5, 3, 0.42), (2.5, 2, 0.45),
                             (3.0, 3, 0.48), (3.5, 1, 0.4)):
            s.pluck(b, beat, up[idx], bt * 1.4, vel * v)

    form = [("I", intro), ("A1", A), ("A2", A), ("B1", B), ("A3", A)]
    bar = 0
    for name, chords in form:
        for i, ch in enumerate(chords):
            b = bar + i
            if name == "I":
                # intro rala (o jogo faz fade-in de 0,6 s): orgao + violao rolado so a partir do 2o tempo
                _, _, up, _ = CHORDS[ch]
                if i > 0:
                    s.pluck(b, 0, CHORDS[ch][0], s.beat * 4.0, 0.62, bright=0.3)
                s.roll(b, 1 if i == 0 else 2, up[1:], s.beat * 2.2, 0.36 + 0.03 * i, spread=0.03)
            elif name == "A3" and i >= 6:
                bass, _, up, _ = CHORDS[ch]
                s.pluck(b, 0, bass, s.beat * 3.5, 0.62, bright=0.3)
                s.roll(b, 2, up[1:], s.beat * 2.0, 0.34, spread=0.025)
            else:
                seresta(b, ch, vel=0.7 if name != "B1" else 0.74)
            if name in ("A2", "B1"):
                s.brush(b, 1, 0.12)
                s.brush(b, 3, 0.14)
        vel_org = {"I": 0.09, "A1": 0.11, "A2": 0.13, "B1": 0.17, "A3": 0.12}[name]
        s.organ_bars(bar, chords, vel=vel_org, start_voices=(57, 60, 64))
        if name == "I":
            # o motivo M aparece de longe na caixinha (anuncio do tema)
            s.box_line(bar + 1, mel("E6:1.5 D6:.5 C6:1 A5:1"), vel=0.32, pan=0.4)
            s.box_line(bar + 3, mel("r:1 D6:1 B5:1 G#5:1"), vel=0.28, pan=0.4)
        elif name == "A1":
            s.box_line(bar, melA, vel=0.55, transpose=12)
        elif name == "A2":
            s.whistle(bar, melA, vel=0.5, transpose=12)
            for i, ch in enumerate(chords):  # contracanto esparso da caixinha
                top = [m for m in range(84, 97) if m % 12 in CHORDS[ch][3]]
                s.box_note(bar + i, 1.5, top[1], vel=0.17)
                s.box_note(bar + i, 3.5, top[0], vel=0.14)
        elif name == "B1":
            # momento maior: assovio + caixinha em terca acima nos pontos de apoio + coro bem baixo
            s.whistle(bar, melB, vel=0.5, transpose=12)
            for i, ch in enumerate(chords):
                top = [m for m in range(86, 99) if m % 12 in CHORDS[ch][3]]
                s.box_note(bar + i, 0, top[0], vel=0.2)
                s.box_note(bar + i, 2, top[1], vel=0.15)
                pcs = CHORDS[ch][3]
                for m in [m for m in range(60, 72) if m % 12 in pcs][:3]:
                    x = choir_voice(midi_hz(m), s.beat * 4 - 0.3, s.rng, att=0.9, rel=1.2)
                    s.choir.add(x, s.t(bar + i), pan=s.rng.uniform(-0.5, 0.5), gain=0.05)
            s.choir.add(bell(midi_hz(69), 4.0, s.rng, vel=0.5), s.t(bar), pan=-0.2)
        elif name == "A3":
            s.box_line(bar, melA_end, vel=0.52, transpose=12)
            s.whistle(bar, melA_end, vel=0.24, transpose=0, pan=-0.1)
        bar += len(chords)
    assert bar == s.bars
    out = s.mix({"gtr": 0.6, "box": 0.72, "org": 0.5, "wh": 0.4, "perc": 1.4, "choir": 1.0},
                rev_mix=0.32, t60=2.6)
    return out, s


TARGET_MUSIC = -14.0  # docs/03_UI_UX.md §8


def render_loop(id_, builder, ceiling=-1.5):
    out, s = builder()
    y, gr, pct = normalize_loop(out, TARGET_MUSIC, id_, ceiling=ceiling)
    wav = os.path.join(BUILD, id_ + ".wav")
    write_wav(wav, y)
    ogg = os.path.join(MUSIC, id_ + ".ogg")
    encode_ogg(wav, ogg)
    prev_wav = os.path.join(BUILD, id_ + "_preview.wav")
    write_wav(prev_wav, np.concatenate([y, y], axis=1))
    encode_ogg(prev_wav, os.path.join(PREV, id_ + "_2voltas.ogg"))
    print(id_, "len %.3f s" % (y.shape[1] / SR), "GRmax %.1f dB, >1dB em %.2f%% das amostras" % (gr, pct), measure(ogg))


def render_oneshot(id_, builder, lufs=None, peak_db=None):
    out = builder()
    y = normalize_oneshot(out, target_peak_db=peak_db, target_lufs=lufs, name=id_)
    y = np.stack([fade(c, 0.0005, 0.05) for c in y])
    wav = os.path.join(BUILD, id_ + ".wav")
    write_wav(wav, y)
    ogg = os.path.join(MUSIC, id_ + ".ogg")
    encode_ogg(wav, ogg)
    print(id_, "len %.3f s" % (y.shape[1] / SR), measure(ogg))


JOBS = {
    "mus_tree": lambda: render_loop("mus_tree", build_tree),
    "mus_area1": lambda: render_loop("mus_area1", build_area1),
    "mus_title": lambda: render_loop("mus_title", build_title),
    "jingle_summary": lambda: render_oneshot("jingle_summary", build_jingle, lufs=-15.0),
    "stinger_grave": lambda: render_oneshot("stinger_grave", build_grave, peak_db=-2.0),
    "stinger_level": lambda: render_oneshot("stinger_level", build_level, peak_db=-4.0),
}

if __name__ == "__main__":
    from music_v1 import JOBS as JOBS_V1  # leva 3 (jogo completo)
    JOBS.update(JOBS_V1)
    ids = sys.argv[1:] or list(JOBS)
    for i in ids:
        JOBS[i]()
