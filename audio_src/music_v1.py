"""Dig Dig Graves - leva 3 (jogo completo): chefe, Areas 2-5, Mascate, final, jingles/stingers.

Uso: python audio_src/music.py mus_boss mus_area2 ...   (os JOBS daqui entram no music.py)

DNA compartilhado (ver build_title em music.py):
  - Motivo "M": grau 5 pontuado descendo ate o 3 e caindo no 1 (ritmo 1,5 + 0,5 + 1 + 1),
    respondido pela subida 2-3-4-5 ate a oitava.
  - Cadencia "C": arpejo descendente do V7 ate a sensivel (4-2-#7 -> 1).
Cada faixa abre (ou abre a melodia principal) com M transposto para o seu tom e fecha as frases
com C. Todas as melodias sao originais.
"""
import numpy as np

from dsp import (SR, accordion, bell, choir_voice, drum_low, exp_decay, fade, harpsichord, hp,
                 bp, lp, midi_hz, musicbox, organ, piano, secs, triangle_hit, ks_pluck,
                 VOWEL_OO, VOWEL_EH, mist_pad)
from music import (CHORDS, Song, mel, voice_lead, render_loop, render_oneshot)


def bars_check(m, bpb, nbars, name):
    tot = sum(d for _, d in m)
    assert abs(tot - bpb * nbars) < 1e-6, (name, tot, bpb * nbars)
    return m


def tops(ch, lo, hi):
    pcs = CHORDS[ch][3]
    return [m for m in range(lo, hi) if m % 12 in pcs]


class Song3(Song):
    """Song com instrumentos da leva 3 e (opcional) mapa de andamento (ritardando)."""

    warp = None  # funcao: tempos absolutos -> segundos

    def t(self, bar, beat=0.0, jitter=0.0):
        b = bar * self.bpb + beat
        x = self.warp(b) if self.warp else b * self.beat
        if jitter:
            x += self.rng.normal(0, jitter)
        return max(0.0, x)

    def dur(self, bar, beat, d):
        return self.t(bar, beat + d) - self.t(bar, beat)

    # linhas melodicas ----------------------------------------------------
    def line(self, bus, bar0, notes, inst, vel=0.5, transpose=0, pan=0.0, legato=0.95, jitter=0.005, **kw):
        beat = 0.0
        for m, d in notes:
            if m is not None:
                v = vel * self.rng.uniform(0.88, 1.05)
                x = inst(midi_hz(m + transpose), self.dur(bar0, beat, d) * legato, self.rng, vel=v, **kw)
                bus.add(x, self.t(bar0, beat, jitter), pan=pan)
            beat += d

    def whistle(self, bar0, notes, vel=0.5, transpose=0, pan=0.08, gap=0.0):
        from dsp import whistle_line
        evs, beat = [], 0.0
        for m, d in notes:
            if m is not None:
                s = self.t(bar0, beat, 0.008)
                evs.append((s, self.dur(bar0, beat, d) - gap, m + transpose, vel * self.rng.uniform(0.9, 1.05)))
            beat += d
        evs2 = []
        for i, (s, d, m, v) in enumerate(evs):
            if i + 1 < len(evs) and evs[i + 1][0] - (s + d) < 0.03:
                d = evs[i + 1][0] - s
            evs2.append((s, d, m, v))
        x, t0 = whistle_line(evs2, self.rng)
        self.wh.add(x, t0, pan=pan)

    def acc_chords(self, bar0, chords, vel=0.12, start=(55, 59, 64), beats=None, bellows=0.25, pan=-0.3):
        voices = list(start)
        for i, ch in enumerate(chords):
            voices = voice_lead(CHORDS[ch][3], voices)
            d = self.dur(bar0 + i, 0, beats or self.bpb)
            for k, m in enumerate(voices):
                x = accordion(midi_hz(m), d - 0.05, self.rng, vel=vel, att=0.18, rel=0.25, bellows=bellows)
                self.bus("acc").add(x, self.t(bar0 + i, 0, 0.004), pan=pan + 0.2 * (k - 1))

    def acc_stab(self, bar, beat, ch, vel=0.1, lo=55, pan=-0.3):
        for k, m in enumerate(tops(ch, lo, lo + 12)[:3]):
            x = accordion(midi_hz(m), self.beat * 0.22, self.rng, vel=vel, att=0.008, rel=0.05)
            self.bus("acc").add(x, self.t(bar, beat, 0.004), pan=pan + 0.15 * (k - 1))

    def organ_line(self, bar0, notes, vel=0.3, transpose=0, pan=0.0, att=0.06, rel=0.35):
        beat = 0.0
        for m, d in notes:
            if m is not None:
                x = organ(midi_hz(m + transpose), self.dur(bar0, beat, d) * 0.97, self.rng, vel=vel, att=att, rel=rel)
                self.org.add(x, self.t(bar0, beat, 0.003), pan=pan)
            beat += d

    def choir_line(self, bar0, notes, gain=0.1, transpose=0, vowel=VOWEL_OO, voices=3, pan=0.0):
        beat = 0.0
        for m, d in notes:
            if m is not None:
                for v in range(voices):
                    x = choir_voice(midi_hz(m + transpose), self.dur(bar0, beat, d), self.rng, att=0.12,
                                    rel=0.45, vowel=vowel)
                    self.choir.add(x, self.t(bar0, beat, 0.01), pan=pan + self.rng.uniform(-0.4, 0.4),
                                   gain=gain / voices ** 0.5)
            beat += d

    def choir_chord(self, bar, ch, nbars=1, gain=0.05, lo=57, vowel=VOWEL_OO, att=0.8, beat=0.0):
        d = self.dur(bar, beat, self.bpb * nbars) - 0.2
        for m in tops(ch, lo, lo + 12)[:3]:
            x = choir_voice(midi_hz(m), d, self.rng, att=att, rel=1.2, vowel=vowel)
            self.choir.add(x, self.t(bar, beat), pan=self.rng.uniform(-0.6, 0.6), gain=gain)

    def drum(self, bar, beat, vel=0.6, f0=95, f1=55, t60=0.45, pan=0.0, bus="drum", **kw):
        x = drum_low(self.rng, f0 * self.rng.uniform(0.97, 1.03), f1, dur=max(0.4, t60 * 1.6), vel=vel, t60=t60, **kw)
        self.bus(bus).add(x, self.t(bar, beat, 0.004), pan=pan)

    def stick(self, bar, beat, vel=0.15, f=1900):
        """'Bacalhau' da zabumba / aro: estalo seco de madeira."""
        n = secs(0.06)
        t = np.arange(n) / SR
        x = np.sin(2 * np.pi * f * t) * exp_decay(n, 0.025) + 0.6 * hp(self.rng.normal(0, 1, n), 2500) * exp_decay(n, 0.01)
        self.perc.add(fade(x, 0.0003, 0.01) * vel, self.t(bar, beat, 0.004), pan=0.25)

    def tri(self, bar, beat, vel=0.25, muted=False):
        self.perc.add(triangle_hit(self.rng, 0.6, vel, muted), self.t(bar, beat, 0.003), pan=0.45)

    def drip(self, start_s, vel=0.2, pan=0.0):
        """Gota caindo numa poca (catacumba): senoide com subida rapida de altura."""
        n = secs(0.12)
        t = np.arange(n) / SR
        f0 = self.rng.uniform(900, 1700)
        f = f0 * (1 + 1.4 * (1 - np.exp(-t / 0.018)))
        x = np.sin(np.cumsum(2 * np.pi * f / SR)) * exp_decay(n, 0.06)
        x = fade(x, 0.0005, 0.02)
        self.bus("drip").add(x * vel, start_s, pan=pan)

    def harp_roll(self, bar, beat, ch, vel=0.35, lo=60, n=6, spread=0.09, ring=2.5, pan=0.15):
        notes = tops(ch, lo, lo + 24)[:n]
        for i, m in enumerate(notes):
            self.pluck(bar, beat + i * spread, m, ring, vel * (0.8 + 0.2 * i / n), pan=pan, bright=0.3)

    def fingerpick(self, bar, ch, vel=0.6, pattern=None):
        b, a, up, _ = CHORDS[ch]
        bt = self.beat
        pattern = pattern or [(0, "b", 1.0, 2.2), (0.5, 1, 0.45, 1.5), (1, 2, 0.5, 1.5), (1.5, 3, 0.42, 1.4),
                              (2, "a", 0.82, 2.2), (2.5, 2, 0.45, 1.4), (3, 3, 0.48, 1.4), (3.5, 1, 0.4, 1.2)]
        for beat, idx, v, ring in pattern:
            m = b if idx == "b" else a if idx == "a" else up[idx]
            self.pluck(bar, beat, m, bt * ring, vel * v, bright=0.35 if isinstance(idx, str) else 0.5)


# =============================================================== mus_boss

def build_boss():
    """Tema de chefe (generico). Re menor, 90 BPM, 4/4, 28 compassos = 74,7 s.
    Galope de violao (3+3+2), surdo grave, orgao com pedal, bII (Mi bemol) frigio para tensao.
    M em Re menor: La-Sol-Fa (pontuado) - Re; resposta Mi-Fa-Sol-La-Re. C: Sol-Mi-Do# -> Re."""
    s = Song3(bpm=90, beats_per_bar=4, bars=28, seed=101)
    I = ["Dm", "Eb", "Dm", "A7"]
    A = ["Dm", "Eb", "Dm", "A7", "Bb", "Gm", "Eb", "A7"]
    B = ["Gm", "Dm", "Eb", "Bb", "Gm", "Dm", "Eb", "A7"]
    T = ["Dm", "Eb", "Dm", "A7", "Bb", "Gm", "A7", "A7"]
    melA = bars_check(mel("A5:1.5 G5:.5 F5:1 D5:1  Eb5:.5 F5:.5 G5:.5 Bb5:.5 G5:2  "
                          "A5:1.5 G5:.5 F5:1 D5:1  E5:.5 F5:.5 G5:.5 A5:.5 C#6:1 E6:1  "
                          "D6:1.5 C6:.5 Bb5:1 F5:1  G5:.5 A5:.5 Bb5:.5 C6:.5 D6:2  "
                          "Eb6:1.5 D6:.5 C6:1 G5:1  G5:1 E5:1 C#5:1 E5:1"), 4, 8, "boss A")
    melB = bars_check(mel("D6:1.5 C6:.5 Bb5:1 G5:1  A5:.5 Bb5:.5 C6:.5 D6:.5 F6:2  "
                          "G6:1.5 F6:.5 Eb6:1 Bb5:1  D6:2 F6:1 D6:1  "
                          "D6:1.5 C6:.5 Bb5:1 G5:1  F5:.5 G5:.5 A5:.5 Bb5:.5 D6:2  "
                          "Eb6:1 D6:1 C6:1 Bb5:1  A5:1 G5:1 E5:1 C#5:1"), 4, 8, "boss B")
    melT_org = bars_check(mel("A4:1.5 G4:.5 F4:1 D4:1  Eb4:.5 F4:.5 G4:.5 Bb4:.5 G4:2  "
                              "A4:1.5 G4:.5 F4:1 D4:1  E4:.5 F4:.5 G4:.5 A4:.5 C#5:2"), 4, 4, "boss T1")
    melT_box = bars_check(mel("F6:1.5 Eb6:.5 D6:1 Bb5:1  C6:.5 D6:.5 Eb6:.5 F6:.5 G6:2  "
                              "G6:1 E6:1 C#6:1 E6:1  G5:1 E5:1 C#5:1 A4:1"), 4, 4, "boss T2")

    def galope(b, ch, vel):
        bass, alt, up, _ = CHORDS[ch]
        seq = [bass, bass, bass + 12, bass, bass, bass + 12, alt, bass + 12]
        for k, m in enumerate(seq):
            acc = k in (0, 3, 6)
            s.pluck(b, 0.5 * k, m, 0.24 if not acc else 0.34, vel * (0.85 if acc else 0.5), bright=0.45, pan=-0.25)

    form = [("I", I), ("A", A), ("B", B), ("T", T)]
    bar = 0
    for name, chords in form:
        for i, ch in enumerate(chords):
            b = bar + i
            galope(b, ch, 0.75 if name != "I" else 0.65)
            if name != "I":
                _, _, up, _ = CHORDS[ch]
                for bt in (1, 3):
                    s.roll(b, bt, up[1:], 0.16, 0.3, spread=0.008, pan=0.2)
            # surdo: "batida de coracao" na intro, padrao 1 . 2+ 3 . 4 nas partes
            if name == "I":
                s.drum(b, 0, 0.75)
                s.drum(b, 0.5, 0.35)
                s.drum(b, 2, 0.6)
            else:
                for bt, v in ((0, 0.8), (1.5, 0.45), (2, 0.65), (3, 0.5)):
                    s.drum(b, bt, v)
                s.brush(b, 1, 0.24)
                s.brush(b, 3, 0.28)
            if name in ("B", "T"):
                for k in range(8):
                    s.shaker(b, k * 0.5, 0.05 if k % 2 else 0.08)
            if name == "B" and i % 2 == 1:
                s.woodblock(b, 3.5, 0.12, f=700)
            if name == "T" and i == 7:  # virada de surdo para voltar a intro
                for k, bt in enumerate((2.5, 3.0, 3.25, 3.5, 3.75)):
                    s.drum(b, bt, 0.4 + 0.08 * k, f0=110 + 12 * k, f1=70 + 6 * k, t60=0.25)
        vel_org = {"I": 0.12, "A": 0.13, "B": 0.17, "T": 0.15}[name]
        s.organ_bars(bar, chords, vel=vel_org, start_voices=(57, 62, 65))
        if name == "I":
            s.box_line(bar + 1, mel("A5:1.5 G5:.5 F5:1 D5:1"), vel=0.3, pan=0.4)
            s.box_line(bar + 3, mel("r:1 G5:1 E5:1 C#5:1"), vel=0.28, pan=0.4)
            s.choir.add(bell(midi_hz(50), 4.0, s.rng, vel=0.35), s.t(bar), pan=-0.2)
        elif name == "A":
            s.box_line(bar, melA, vel=0.55)
            s.choir.add(bell(midi_hz(62), 3.5, s.rng, vel=0.3), s.t(bar), pan=-0.2)
        elif name == "B":
            s.whistle(bar, melB, vel=0.5)
            for i, ch in enumerate(chords):
                s.choir_chord(bar + i, ch, gain=0.06, lo=50)
                tp = tops(ch, 86, 99)
                s.box_note(bar + i, 0.5, tp[0], vel=0.14)
                s.box_note(bar + i, 2.5, tp[1], vel=0.12)
        elif name == "T":
            s.organ_line(bar, melT_org, vel=0.26)
            s.box_line(bar + 4, melT_box, vel=0.5)
            s.choir.add(bell(midi_hz(50), 3.5, s.rng, vel=0.3), s.t(bar), pan=-0.2)
        bar += len(chords)
    assert bar == s.bars
    out = s.mix({"gtr": 0.55, "box": 0.72, "org": 0.5, "wh": 0.4, "perc": 1.5, "drum": 0.75, "choir": 1.0},
                rev_mix=0.24, t60=2.0)
    return out, s


# =============================================================== mus_area2

def build_area2():
    """Campo dos Indigentes. Mi menor, 76 BPM, 4/4, 36 compassos = 113,7 s.
    Violao dedilhado, sanfona discreta (acordes e uma passagem da melodia), assovio, nevoa.
    M: Si-La-Sol (pontuado) - Mi; resposta Fa#-Sol-La-Si-Mi. C: La-Fa#-Re# -> Mi."""
    s = Song3(bpm=76, beats_per_bar=4, bars=36, seed=202)
    I = ["Em", "C", "Am", "B7"]
    A = ["Em", "C", "Am", "B7", "Em", "Am", "B7", "Em"]
    B = ["C", "D", "G", "Em", "Am", "D", "G", "B7"]
    melA = bars_check(mel("B5:1.5 A5:.5 G5:1 E5:1  F#5:.5 G5:.5 A5:.5 B5:.5 E6:2  "
                          "C6:1.5 B5:.5 A5:1 E5:1  B5:1.5 A5:.5 F#5:1 D#5:1  "
                          "G5:1.5 F#5:.5 E5:1 B4:1  E5:1 A5:1 C6:1.5 B5:.5  "
                          "A5:1 F#5:1 D#5:1 F#5:1  E5:3 r:1"), 4, 8, "a2 A")
    melB = bars_check(mel("E6:1.5 D6:.5 C6:1 G5:1  F#5:.5 G5:.5 A5:.5 B5:.5 D6:2  "
                          "D6:1.5 C6:.5 B5:1 G5:1  B5:1.5 A5:.5 G5:2  "
                          "A5:1 C6:1 E6:1.5 D6:.5  C6:1 A5:1 F#5:1 D6:1  "
                          "B5:1.5 A5:.5 G5:1 D5:1  F#5:1 A5:1 B5:1 D#6:1"), 4, 8, "a2 B")
    melA_end = melA[:-1] + mel("E5:4")
    form = [("I", I), ("A1", A), ("A2", A), ("B1", B), ("A3", A)]
    bar = 0
    for name, chords in form:
        for i, ch in enumerate(chords):
            b = bar + i
            if name == "I" or (name == "A3" and i >= 6):
                bass, _, up, _ = CHORDS[ch]
                s.pluck(b, 0, bass, s.beat * 4.0, 0.6, bright=0.3)
                s.roll(b, 1 if i % 2 == 0 else 2, up[1:], s.beat * 2.4, 0.34, spread=0.035)
            else:
                s.fingerpick(b, ch, vel=0.62 if name != "B1" else 0.66)
            # nevoa: um sopro filtrado a cada 2 compassos, alternando lados
            if i % 2 == 0:
                lo, hi = (380, 1400) if (b // 2) % 2 else (1200, 450)
                x = mist_pad(s.beat * 8 * 1.2, s.rng, lo, hi)
                s.bus("mist").add(x, s.t(b), pan=(-0.6 if (b // 2) % 2 else 0.6))
        if name == "I":
            s.acc_chords(bar, chords, vel=0.07, bellows=0.35)
            s.choir_chord(bar, "Em", nbars=2, gain=0.035, lo=52)
            s.choir_chord(bar + 2, "Am", nbars=2, gain=0.035, lo=52)
            s.whistle(bar + 2, mel("r:2 B5:1.5 A5:.5  G5:1 F#5:1 D#5:2"), vel=0.22, pan=-0.35)
        elif name == "A1":
            s.whistle(bar, melA, vel=0.5)
            s.acc_chords(bar, chords, vel=0.08)
        elif name == "A2":
            # a sanfona assume a melodia, uma oitava abaixo, bem discreta; orgao segura a cama
            s.line(s.bus("acc"), bar, melA, accordion, vel=0.42, transpose=-12, pan=-0.2,
                   legato=0.92, att=0.035, rel=0.12, bellows=0.15)
            s.organ_bars(bar, chords, vel=0.09, start_voices=(55, 59, 64))
            for i, ch in enumerate(chords):
                tp = tops(ch, 83, 96)
                s.box_note(bar + i, 1.5, tp[1], vel=0.12)
        elif name == "B1":
            s.whistle(bar, melB, vel=0.5)
            s.acc_chords(bar, chords, vel=0.1, start=(55, 59, 62))
            for i, ch in enumerate(chords):
                tp = tops(ch, 84, 97)
                s.box_note(bar + i, 0, tp[0], vel=0.16)
                s.box_note(bar + i, 2.5, tp[1], vel=0.12)
            for k in range(8):
                s.brush(bar + k, 1, 0.1)
                s.brush(bar + k, 3, 0.12)
        elif name == "A3":
            s.whistle(bar, melA_end, vel=0.26, transpose=-12, pan=-0.1)
            s.line(s.bus("acc"), bar, melA_end, accordion, vel=0.22, pan=0.25, legato=0.92,
                   att=0.04, rel=0.15, bellows=0.15)
            s.organ_bars(bar, chords, vel=0.07, start_voices=(55, 59, 64))
            s.choir_chord(bar + 6, "B7", nbars=1, gain=0.03, lo=54)
        bar += len(chords)
    assert bar == s.bars
    out = s.mix({"gtr": 0.58, "box": 0.7, "org": 0.5, "wh": 0.42, "perc": 1.2, "acc": 0.55,
                 "mist": 0.12, "choir": 1.0}, rev_mix=0.3, t60=2.6)
    return out, s


# =============================================================== mus_area3

def build_area3():
    """Catacumbas de Pedra. Do menor, 70 BPM, 4/4, 36 compassos = 123,4 s.
    Orgao em primeiro plano, violao grave, gotas com eco, coro de monges na parte maior.
    M: Sol-Fa-Mib (pontuado) - Do; resposta Re-Mib-Fa-Sol-Do. C: Fa-Re-Si -> Do."""
    s = Song3(bpm=70, beats_per_bar=4, bars=36, seed=303)
    I = ["Cm", "Cm", "Ab", "G7"]
    A = ["Cm", "Ab", "Fm", "G7", "Cm", "Bb", "G7", "Cm"]
    B = ["Eb", "Bb", "Cm", "Ab", "Fm", "Bb", "Eb", "G7"]
    melA = bars_check(mel("G4:1.5 F4:.5 Eb4:1 C4:1  D4:.5 Eb4:.5 F4:.5 G4:.5 C5:2  "
                          "Ab4:1.5 G4:.5 F4:1 C4:1  D4:1.5 Eb4:.5 F4:1 B3:1  "
                          "Eb4:1.5 D4:.5 C4:1 G3:1  F4:1 D4:1 Bb4:1.5 Ab4:.5  "
                          "F4:1 D4:1 B3:1 D4:1  C4:3 r:1"), 4, 8, "a3 A")
    melB = bars_check(mel("Bb4:1.5 Ab4:.5 G4:1 Eb4:1  F4:.5 G4:.5 Ab4:.5 Bb4:.5 D5:2  "
                          "Eb5:1.5 D5:.5 C5:1 G4:1  Ab4:2 C5:1 Eb5:1  "
                          "F5:1.5 Eb5:.5 C5:1 Ab4:1  D5:1 F5:1 Bb4:2  "
                          "G4:1.5 F4:.5 Eb4:1 Bb3:1  F4:1 D4:1 B3:1 D4:1"), 4, 8, "a3 B")
    form = [("I", I), ("A1", A), ("A2", A), ("B1", B), ("A3", A)]
    bar = 0
    for name, chords in form:
        for i, ch in enumerate(chords):
            b = bar + i
            bass, alt, up, _ = CHORDS[ch]
            # violao grave e lento: baixo uma oitava abaixo + acorde rolado nos tempos 2 e 3,5
            s.pluck(b, 0, bass - 12 if bass - 12 >= 40 else bass, s.beat * 3.5, 0.62, bright=0.25)
            if name != "I" or i >= 2:
                s.roll(b, 1, up[:3], s.beat * 2.0, 0.3, spread=0.04)
                s.pluck(b, 2.5, alt, s.beat * 1.5, 0.35, bright=0.3)
        vel_org = {"I": 0.08, "A1": 0.1, "A2": 0.13, "B1": 0.14, "A3": 0.11}[name]
        if name != "A1":
            s.organ_bars(bar, chords, vel=vel_org, start_voices=(55, 60, 63))
        else:
            # so o pedal grave sob a melodia do orgao (clareza)
            for i, ch in enumerate(chords):
                x = organ(midi_hz(CHORDS[ch][0] - 12), s.beat * 4, s.rng, vel=0.07, att=0.5, rel=0.8)
                s.org.add(x, s.t(bar + i))
        if name == "A1":
            s.organ_line(bar, melA, vel=0.3, transpose=12, pan=0.05)
        elif name == "A2":
            s.box_line(bar, melA, vel=0.42, transpose=24, pan=0.3)
        elif name == "B1":
            s.organ_line(bar, melB, vel=0.28, transpose=12, pan=0.05)
            for i, ch in enumerate(chords):
                s.choir_chord(bar + i, ch, gain=0.075, lo=48, vowel=VOWEL_OO, att=0.5)
            s.choir.add(bell(midi_hz(48), 4.5, s.rng, vel=0.32), s.t(bar), pan=0.3)
        elif name == "A3":
            s.organ_line(bar, melA[:-2] + mel("C4:4"), vel=0.22, transpose=0, pan=-0.05)
            s.whistle(bar, melA[:-2] + mel("C4:4"), vel=0.2, transpose=12, pan=0.35)
        bar += len(chords)
    assert bar == s.bars
    # gotas espalhadas (sempre dentro do loop; o eco e o reverb sao circulares)
    tt = 0.7
    while tt < s.length - 0.3:
        s.drip(tt, vel=s.rng.uniform(0.08, 0.2), pan=s.rng.uniform(-0.8, 0.8))
        tt += s.rng.uniform(1.2, 3.4)
    for k in range(int(s.length / (s.beat * 8))):  # zumbido grave da cripta (Do 1), em ondas
        x = organ(midi_hz(36), s.beat * 8, s.rng, vel=0.05, att=3.0, rel=2.5)
        s.org.add(x, k * s.beat * 8)
    out = s.mix({"gtr": 0.55, "box": 0.7, "org": 0.58, "wh": 0.35, "drip": 2.0, "choir": 1.0},
                rev_mix=0.36, t60=3.4,
                echo_send={"drip": 0.7, "box": 0.35, "wh": 0.5, "org": 0.12},
                echo_cfg=dict(delay_s=60 / 70 * 0.75, fb=0.42, taps=6, lp_fc=2200))
    return out, s


# =============================================================== mus_area4

def build_area4():
    """Necropole dos Baroes. Sol menor, valsa de salao lenta, 80 BPM, 3/4, 44 compassos = 99 s.
    Cravo no acompanhamento (baixo + 2 acordes), piano de salao velho na melodia, orgao solene.
    M (em 3/4): Re-Do-Sib (pontuado) | Sol . La | Sib Do Re | Sol' (resposta ate a oitava).
    C: Do-La-Fa# -> Sol."""
    s = Song3(bpm=80, beats_per_bar=3, bars=44, seed=404)
    I = ["Gm", "Gm", "Cm", "D7"]
    A = ["Gm", "Gm", "Cm", "D7", "Gm", "Eb", "D7", "Gm"]
    B = ["Eb", "Bb", "Cm", "F7", "Bb", "Gm", "Cm", "D7"]
    C = ["Cm", "Gm", "Eb", "D7", "Cm", "Gm", "Am7b5", "D7"]
    melA = bars_check(mel("D5:1.5 C5:.5 Bb4:1  G4:2 A4:1  Bb4:1 C5:1 D5:1  G5:2 F#5:1  "
                          "Bb5:1.5 A5:.5 G5:1  G5:1 Eb5:1 Bb4:1  C5:1 A4:1 F#4:1  G4:3"), 3, 8, "a4 A")
    melB = bars_check(mel("G5:1.5 F5:.5 Eb5:1  D5:2 F5:1  Eb5:1 D5:1 C5:1  A4:2 C5:1  "
                          "D5:1.5 C5:.5 Bb4:1  G4:1 Bb4:1 D5:1  Eb5:1.5 D5:.5 C5:1  A4:1 C5:1 F#5:1"), 3, 8, "a4 B")
    melC = bars_check(mel("G5:1 F5:.5 Eb5:.5 C5:1  D5:.5 Eb5:.5 F5:.5 G5:.5 Bb5:1  "
                          "Bb5:1 G5:.5 Eb5:.5 Bb4:1  A4:.5 C5:.5 D5:.5 F#5:.5 A5:1  "
                          "C6:1 Bb5:.5 G5:.5 Eb5:1  D5:.5 G5:.5 Bb5:1 A5:1  "
                          "C6:1 A5:.5 Eb5:.5 C5:1  C5:1 A4:1 F#4:1"), 3, 8, "a4 C")

    def comp(b, ch, vel=0.5, inst="hc"):
        bass, alt, up, _ = CHORDS[ch]
        bt = s.beat
        if inst == "hc":
            x = harpsichord(midi_hz(bass - 12 if bass >= 45 else bass), bt * 0.95, s.rng, vel=vel)
            s.bus("keys").add(x, s.t(b, 0, 0.004), pan=-0.3)
            for beat in (1, 2):
                for k, m in enumerate(up[1:]):
                    x = harpsichord(midi_hz(m), bt * 0.45, s.rng, vel=vel * 0.42, octave=0.2)
                    s.bus("keys").add(x, s.t(b, beat + 0.006 * k, 0.003), pan=-0.3 + 0.1 * k)
        else:
            x = piano(midi_hz(bass - 12 if bass >= 45 else bass), bt * 1.0, s.rng, vel=vel, honky=0.0015)
            s.bus("piano").add(x, s.t(b, 0, 0.004), pan=0.1)
            for beat in (1, 2):
                for m in up[1:]:
                    x = piano(midi_hz(m), bt * 0.5, s.rng, vel=vel * 0.4, honky=0.0015)
                    s.bus("piano").add(x, s.t(b, beat, 0.004), pan=0.15)

    def piano_mel(bar0, notes, vel, transpose=0, graces=0.0):
        beat = 0.0
        for m, d in notes:
            if m is not None:
                mm = m + transpose
                if graces and beat % 3 == 0 and s.rng.uniform() < graces:
                    g = piano(midi_hz(mm - 1), 0.07, s.rng, vel=vel * 0.35, honky=0.002)
                    s.bus("piano").add(g, s.t(bar0, beat) - 0.07, pan=0.2)
                x = piano(midi_hz(mm), s.dur(bar0, beat, d) * 1.05, s.rng, vel=vel * s.rng.uniform(0.9, 1.05),
                          honky=0.002)
                s.bus("piano").add(x, s.t(bar0, beat, 0.006), pan=0.2)
            beat += d

    form = [("I", I), ("A1", A), ("B1", B), ("A2", A), ("C1", C), ("A3", A)]
    bar = 0
    for name, chords in form:
        for i, ch in enumerate(chords):
            b = bar + i
            if name == "C1":
                comp(b, ch, vel=0.5, inst="pn")
            else:
                comp(b, ch, vel=0.55 if name != "I" else 0.5)
        vel_org = {"I": 0.06, "A1": 0.07, "B1": 0.12, "A2": 0.09, "C1": 0.12, "A3": 0.08}[name]
        s.organ_bars(bar, chords, vel=vel_org, start_voices=(55, 58, 62))
        if name == "I":
            s.line(s.bus("keys"), bar, mel("D6:1.5 C6:.5 Bb5:1  G5:3  r:3  C6:1 A5:1 F#5:1"),
                   harpsichord, vel=0.32, pan=0.35, legato=1.0)
        elif name == "A1":
            piano_mel(bar, melA, 0.62)
        elif name == "B1":
            piano_mel(bar, melB, 0.6)
            s.choir.add(bell(midi_hz(55), 4.0, s.rng, vel=0.24), s.t(bar), pan=-0.3)
            s.choir.add(bell(midi_hz(55), 4.0, s.rng, vel=0.2), s.t(bar + 4), pan=-0.3)
        elif name == "A2":
            piano_mel(bar, melA, 0.55, transpose=12, graces=0.4)
            for i, ch in enumerate(chords):  # contracanto do cravo, esparso
                tp = tops(ch, 67, 80)
                x = harpsichord(midi_hz(tp[1]), s.beat * 1.4, s.rng, vel=0.22, octave=0.0)
                s.bus("keys").add(x, s.t(bar + i, 1.5), pan=0.4)
        elif name == "C1":
            s.line(s.bus("keys"), bar, melC, harpsichord, vel=0.45, pan=-0.15, legato=1.0)
        elif name == "A3":
            piano_mel(bar, melA, 0.5, graces=0.3)
            s.whistle(bar + 4, mel("Bb5:1.5 A5:.5 G5:1  G5:1 Eb5:1 Bb4:1  C5:1 A4:1 F#4:1  G4:3"),
                      vel=0.2, pan=-0.3)
        bar += len(chords)
    assert bar == s.bars
    out = s.mix({"gtr": 0.5, "box": 0.6, "org": 0.5, "wh": 0.4, "keys": 0.5, "piano": 1.3, "choir": 1.0},
                rev_mix=0.3, t60=2.8)
    return out, s


# =============================================================== mus_area5

def build_area5():
    """Jardim das Almas. La menor -> La MAIOR no fim; 70 BPM, 4/4, 36 compassos = 123,4 s.
    Caixinha, coro 'uuh/aah', harpa de violao, sinos; sem percussao.
    M: Mi-Re-Do (pontuado) - La, resposta Si-Do-Re-Mi-La (como mus_title);
    na parte final M em maior: Mi-Re-Do#-La."""
    s = Song3(bpm=70, beats_per_bar=4, bars=36, seed=505)
    I = ["Am", "F", "Dm", "E"]
    A = ["Am", "F", "Dm", "E", "Am", "F", "E7", "Am"]
    B = ["F", "G", "C", "Am", "Dm", "G", "C", "E7"]
    M = ["A", "D", "A", "E", "F#m", "D", "E7", "A"]
    melA = bars_check(mel("E6:1.5 D6:.5 C6:1 A5:1  B5:.5 C6:.5 D6:.5 E6:.5 A6:2  "
                          "F6:1.5 E6:.5 D6:1 A5:1  G#5:1 B5:1 E6:2  "
                          "C6:1.5 B5:.5 A5:1 E5:1  F5:1 A5:1 C6:1.5 B5:.5  "
                          "D6:1 B5:1 G#5:1 B5:1  A5:4"), 4, 8, "a5 A")
    melB = bars_check(mel("A6:1.5 G6:.5 F6:1 C6:1  D6:.5 E6:.5 F6:.5 G6:.5 B6:2  "
                          "C7:1.5 B6:.5 G6:1 E6:1  A6:3 r:1  "
                          "F6:1 A6:1 D7:1.5 C7:.5  B6:1 G6:1 F6:1 D6:1  "
                          "E6:1.5 D6:.5 C6:1 G5:1  B5:1 D6:1 E6:1 G#6:1"), 4, 8, "a5 B")
    melM = bars_check(mel("E6:1.5 D6:.5 C#6:1 A5:1  B5:.5 C#6:.5 D6:.5 E6:.5 A6:2  "
                          "C#6:1.5 B5:.5 A5:1 E5:1  B5:2 G#5:1 B5:1  "
                          "A5:1.5 G#5:.5 F#5:1 C#6:1  D6:1 F#6:1 A6:1.5 G#6:.5  "
                          "D6:1 B5:1 G#5:1 B5:1  A5:4"), 4, 8, "a5 M")

    def glass(bar, ch, nbars=1, vel=0.05):
        d = s.dur(bar, 0, s.bpb * nbars)
        n = secs(d + 1.5)
        t = np.arange(n) / SR
        env = np.sin(np.pi * np.clip(t / (d + 1.5), 0, 1)) ** 2
        for k, m in enumerate(tops(ch, 76, 88)[:3]):
            f = midi_hz(m)
            x = (np.sin(2 * np.pi * f * t + s.rng.uniform(0, 6)) + 0.15 * np.sin(4 * np.pi * f * t)) * env
            x *= 1 + 0.2 * np.sin(2 * np.pi * (0.3 + 0.1 * k) * t)
            s.bus("glass").add(x * vel, s.t(bar) - 0.4, pan=(-0.6, 0.0, 0.6)[k])

    form = [("I", I), ("A1", A), ("A2", A), ("B1", B), ("M1", M)]
    bar = 0
    for name, chords in form:
        for i, ch in enumerate(chords):
            b = bar + i
            if name == "I":
                s.harp_roll(b, 0, ch, vel=0.3, lo=57, n=5, spread=0.14)
            else:
                s.harp_roll(b, 0, ch, vel=0.34, lo=55, n=6, spread=0.1)
                s.harp_roll(b, 2, ch, vel=0.26, lo=64, n=4, spread=0.1)
                s.pluck(b, 0, CHORDS[ch][0], s.beat * 4, 0.5, bright=0.25)
            glass(b, ch, vel=0.035 if name != "M1" else 0.045)
        if name == "I":
            s.box_line(bar + 1, mel("E6:1.5 D6:.5 C6:1 A5:1"), vel=0.28, pan=0.45)
            s.box_line(bar + 3, mel("r:1 D6:1 B5:1 G#5:1"), vel=0.25, pan=0.45)
            for i, ch in enumerate(chords):
                s.choir_chord(bar + i, ch, gain=0.03, lo=57)
        elif name == "A1":
            s.box_line(bar, melA, vel=0.55, ring=3.0)
            for i, ch in enumerate(chords):
                s.choir_chord(bar + i, ch, gain=0.035, lo=55)
        elif name == "A2":
            s.choir_line(bar, melA, gain=0.16, transpose=-12, vowel=VOWEL_OO)
            for i, ch in enumerate(chords):
                tp = tops(ch, 88, 100)
                s.box_note(bar + i, 0.5, tp[0], vel=0.2, ring=3.0)
                s.box_note(bar + i, 2.5, tp[1], vel=0.16, ring=3.0)
            s.choir.add(bell(midi_hz(81), 4.0, s.rng, vel=0.2), s.t(bar), pan=0.4)
        elif name == "B1":
            s.box_line(bar, melB, vel=0.5, transpose=-12, ring=3.0)
            for i, ch in enumerate(chords):
                s.choir_chord(bar + i, ch, gain=0.045, lo=55, vowel=VOWEL_EH)
        elif name == "M1":
            s.box_line(bar, melM, vel=0.55, ring=3.0)
            s.whistle(bar, melM, vel=0.3, transpose=-12, pan=-0.15)
            for i, ch in enumerate(chords):
                from dsp import VOWEL_AH
                s.choir_chord(bar + i, ch, gain=0.06, lo=57, vowel=VOWEL_AH)
            s.choir.add(bell(midi_hz(69), 4.5, s.rng, vel=0.32), s.t(bar), pan=-0.3)
            s.choir.add(bell(midi_hz(76), 4.5, s.rng, vel=0.22), s.t(bar + 4), pan=0.3)
        bar += len(chords)
    assert bar == s.bars
    out = s.mix({"gtr": 0.5, "box": 0.75, "wh": 0.4, "choir": 1.0, "glass": 1.0}, rev_mix=0.38, t60=3.3)
    return out, s


# =============================================================== mus_shop

def build_shop():
    """Loja do Mascate: xote simpatico. Do maior, 90 BPM, 4/4, 16 compassos = 42,7 s.
    Sanfona na melodia, violao, zabumba (surdo + bacalhau), triangulo, caixinha (as quinquilharias).
    M em Do maior: Sol-Fa-Mi (pontuado) - Do; resposta Re-Mi-Fa-Sol-Do'. C: Fa-Re-Si -> Do."""
    s = Song3(bpm=90, beats_per_bar=4, bars=16, seed=606)
    A = ["C", "Am", "F", "G7", "C", "Am", "G7", "C"]
    B = ["F", "C", "G7", "C", "F", "C", "D7", "G7"]
    melA = bars_check(mel("G5:1.5 F5:.5 E5:1 C5:1  D5:.5 E5:.5 F5:.5 G5:.5 C6:2  "
                          "A5:1.5 G5:.5 F5:1 C5:1  D5:1 F5:1 B5:1.5 G5:.5  "
                          "E5:1.5 D5:.5 C5:1 G4:1  A4:.5 B4:.5 C5:.5 E5:.5 A5:2  "
                          "F5:1 D5:1 B4:1 D5:1  C5:2 r:.5 G4:.5 C5:.5 E5:.5"), 4, 8, "shop A")
    melB = bars_check(mel("A5:1.5 C6:.5 A5:1 F5:1  G5:1.5 E5:.5 C5:2  "
                          "F5:.5 G5:.5 F5:.5 D5:.5 B4:2  C5:.5 E5:.5 G5:.5 C6:.5 E6:2  "
                          "D6:1.5 C6:.5 A5:1 F5:1  E5:1.5 G5:.5 C6:2  "
                          "A5:1 F#5:1 D5:1 C6:1  B5:1 G5:1 F5:1 D5:1"), 4, 8, "shop B")
    bar = 0
    for name, chords in (("A", A), ("B", B)):
        for i, ch in enumerate(chords):
            b = bar + i
            bass, alt, up, _ = CHORDS[ch]
            # violao: baixo em 1 e 3, "chuc" no contratempo
            s.pluck(b, 0, bass, s.beat * 1.6, 0.7, bright=0.35)
            s.pluck(b, 2, alt, s.beat * 1.6, 0.6, bright=0.35)
            for bt in (1, 3):
                s.roll(b, bt, up[1:], 0.18, 0.32, spread=0.007, pan=0.15)
            # zabumba: tum em 1, tum no "e" do 2, toque leve no 3; bacalhau no 2 e 4
            s.drum(b, 0, 0.55, f0=110, f1=68, t60=0.3, noise_amt=0.15)
            s.drum(b, 1.5, 0.35, f0=110, f1=68, t60=0.25, noise_amt=0.15)
            s.drum(b, 2, 0.4, f0=110, f1=68, t60=0.28, noise_amt=0.15)
            s.stick(b, 1, 0.12)
            s.stick(b, 3, 0.14)
            s.stick(b, 3.5, 0.07)
            # triangulo: fechado no tempo, aberto no contratempo
            for k in range(8):
                s.tri(b, 0.5 * k, vel=0.16 if k % 2 else 0.1, muted=(k % 2 == 0))
            if name == "B":
                for bt in (0.5, 2.5):
                    s.acc_stab(b, bt, ch, vel=0.06, lo=60)
        mm = melA if name == "A" else melB
        s.line(s.bus("acc"), bar, mm, accordion, vel=0.5, pan=0.05, legato=0.88, att=0.015, rel=0.06,
               musette=0.004, bellows=0.1)
        if name == "B":
            for i, ch in enumerate(chords):  # quinquilharias do carrinho: caixinha brilhando
                tp = tops(ch, 84, 98)
                s.box_note(bar + i, 0.5, tp[0], vel=0.13, pan=0.45)
                s.box_note(bar + i, 2.5, tp[2], vel=0.1, pan=0.45)
        else:
            s.box_note(bar + 1, 2, 96, vel=0.14, pan=0.45)
            s.box_note(bar + 5, 2, 93, vel=0.12, pan=0.45)
        s.organ_bars(bar, chords, vel=0.05, start_voices=(55, 60, 64))
        bar += len(chords)
    assert bar == s.bars
    out = s.mix({"gtr": 0.6, "box": 0.7, "org": 0.5, "perc": 1.4, "drum": 0.75, "acc": 0.75},
                rev_mix=0.18, t60=1.6)
    return out, s


# =============================================================== mus_ending

def build_ending():
    """Final. La menor -> La MAIOR. 72 BPM, 4/4, 22 compassos com ritardando no fim (~78 s, sem loop).
    Cada frase passa por um instrumento dos estagios (violao, caixinha/sanfona, assovio+orgao+coro,
    cravo), ate M e C resolverem em La maior com sino e coro."""
    s = Song3(bpm=72, beats_per_bar=4, bars=22, tail=14, seed=707)
    b0, RIT = 18 * 4, 0.9  # ritardando a partir do compasso 19

    def warp(b):
        if b <= b0:
            return b * s.beat
        u = b - b0
        return (b0 + u + RIT * u ** 3 / (3 * 8.0 ** 2)) * s.beat
    s.warp = warp
    s.length = warp(22 * 4)

    P1 = ["Am", "AmG", "F", "E7"]
    P2 = ["Dm", "Am", "E7", "Am"]
    P3 = ["A", "D", "A", "E", "F#m", "D", "E7", "A"]
    P4 = ["D", "A/C#", "Bm7", "E7"]
    m1 = bars_check(mel("E5:1.5 D5:.5 C5:1 A4:1  B4:.5 C5:.5 D5:.5 E5:.5 A5:2  "
                        "G5:1.5 F5:.5 E5:1 C5:1  D5:1 B4:1 G#4:1 B4:1"), 4, 4, "end P1")
    m2 = bars_check(mel("F5:1.5 E5:.5 D5:1 A4:1  C5:1 E5:1 A5:1.5 G5:.5  "
                        "F5:1 D5:1 B4:1 G#4:1  A4:3 r:1"), 4, 4, "end P2")
    m3 = bars_check(mel("E6:1.5 D6:.5 C#6:1 A5:1  B5:.5 C#6:.5 D6:.5 E6:.5 A6:2  "
                        "C#6:1.5 B5:.5 A5:1 E5:1  B5:2 G#5:1 B5:1  "
                        "A5:1.5 G#5:.5 F#5:1 C#6:1  D6:1 F#6:1 A6:1.5 G#6:.5  "
                        "D6:1 B5:1 G#5:1 B5:1  A5:4"), 4, 8, "end P3")
    m4 = bars_check(mel("F#6:1.5 E6:.5 D6:1 A5:1  E6:1.5 D6:.5 C#6:1 A5:1  "
                        "D6:1 C#6:1 B5:1 F#5:1  D6:1 B5:1 G#5:1 B5:1"), 4, 4, "end P4")

    def seresta(b, ch, vel):
        bass, alt, up, _ = CHORDS[ch]
        s.pluck(b, 0, bass, s.dur(b, 0, 2.2), vel, bright=0.35)
        s.pluck(b, 2, alt, s.dur(b, 2, 2.2), vel * 0.8, bright=0.35)
        for beat, idx, v in ((0.5, 1, 0.42), (1.0, 2, 0.46), (1.5, 3, 0.4), (2.5, 2, 0.42),
                             (3.0, 3, 0.45), (3.5, 1, 0.38)):
            s.pluck(b, beat, up[idx], s.dur(b, beat, 1.4), vel * v)

    # P1: violao sozinho canta M (citacao direta do mus_title)
    for i, ch in enumerate(P1):
        bass, _, up, _ = CHORDS[ch]
        s.pluck(i, 0, bass, s.beat * 3.8, 0.55, bright=0.3)
        s.roll(i, 2, up[1:3], s.beat * 1.8, 0.26, spread=0.03)
    s.line(s.gtr, 0, m1, lambda f, d, r, vel: ks_pluck(f, d + 0.6, r, vel=vel, bright=0.55),
           vel=0.62, pan=0.05, legato=1.0)
    # P2: caixinha (Jardim) + sanfona (Indigentes) + orgao (Catacumbas)
    for i, ch in enumerate(P2):
        seresta(4 + i, ch, 0.55)
    s.box_line(4, m2, vel=0.5, transpose=12)
    s.acc_chords(4, P2, vel=0.07, start=(57, 60, 64))
    s.organ_bars(4, P2, vel=0.07, start_voices=(57, 62, 65))
    # P3: La MAIOR — assovio com M em maior, orgao, coro, sino
    for i, ch in enumerate(P3):
        seresta(8 + i, ch, 0.62)
        s.choir_chord(8 + i, ch, gain=0.05, lo=57)
        tp = tops(ch, 84, 97)
        s.box_note(8 + i, 1.5, tp[1], vel=0.15)
        s.box_note(8 + i, 3.5, tp[0], vel=0.12)
    s.whistle(8, m3, vel=0.52)
    s.organ_bars(8, P3, vel=0.13, start_voices=(57, 61, 64))
    s.choir.add(bell(midi_hz(69), 4.5, s.rng, vel=0.3), s.t(8), pan=-0.25)
    for k in range(8):
        s.brush(8 + k, 1, 0.08)
        s.brush(8 + k, 3, 0.1)
    # P4: coda — o cravo (Necropole) dedilha, caixinha + assovio grave levam C ate o fim
    for i, ch in enumerate(P4):
        seresta(16 + i, ch, 0.55)
        for kk, m in enumerate(tops(ch, 64, 80)[:4]):
            x = harpsichord(midi_hz(m), s.beat * 0.5, s.rng, vel=0.2, octave=0.2)
            s.bus("keys").add(x, s.t(16 + i, 0.5 + 0.75 * kk), pan=0.35)
        s.choir_chord(16 + i, ch, gain=0.055, lo=57, vowel=VOWEL_EH)
    s.box_line(16, m4, vel=0.48)
    s.whistle(16, m4, vel=0.25, transpose=-12, pan=-0.2)
    s.organ_bars(16, P4, vel=0.13, start_voices=(57, 61, 66))
    # final: La maior suspenso (fermata), sino, coro "aah", caixinha subindo
    from dsp import VOWEL_AH
    bt = 20
    s.roll(bt, 0, [45, 52, 57, 61, 64, 69], 9.0, 0.7, spread=0.06)
    s.choir.add(bell(midi_hz(69), 7.0, s.rng, vel=0.42), s.t(bt), pan=-0.2)
    s.choir.add(bell(midi_hz(57), 7.0, s.rng, vel=0.28), s.t(bt) + 0.05, pan=0.2)
    for m in (57, 61, 64, 69):
        for v in range(2):
            x = choir_voice(midi_hz(m), 7.0, s.rng, att=0.6, rel=3.0, vowel=VOWEL_AH)
            s.choir.add(x, s.t(bt) + 0.02 * v, pan=s.rng.uniform(-0.5, 0.5), gain=0.05)
    for k in (57, 61, 64, 69):
        s.org.add(organ(midi_hz(k), 6.0, s.rng, vel=0.12, att=0.6, rel=3.0), s.t(bt), pan=0.0)
    s.org.add(organ(midi_hz(33), 6.0, s.rng, vel=0.05, att=0.6, rel=3.0), s.t(bt))
    s.whistle(bt, mel("A5:4"), vel=0.4)
    for i, m in enumerate([81, 85, 88, 93]):
        s.box.add(musicbox(midi_hz(m), 3.5, s.rng, vel=0.3 + 0.05 * i), s.t(bt, 2 + 0.5 * i), pan=0.4)
    out = s.mix({"gtr": 0.62, "box": 0.72, "org": 0.5, "wh": 0.42, "perc": 1.2, "acc": 0.9,
                 "keys": 0.8, "choir": 1.0}, rev_mix=0.32, t60=2.8, loop=False)
    end = s.t(bt) + 10.0
    out = out[:, :secs(end)]
    kf = secs(4.0)
    out[:, -kf:] *= np.linspace(1, 0, kf) ** 2
    return out


# =============================================================== jingles / stingers

def build_boss_win():
    """Vitoria sobre o chefe: M em Re menor vira Re MAIOR na resposta (Fa -> Fa#). ~5,5 s."""
    from dsp import VOWEL_AH
    s = Song3(bpm=90, beats_per_bar=4, bars=2, tail=6, seed=808)
    s.drum(0, 0, 0.9, f0=90, f1=50, t60=0.5)
    s.roll(0, 0, [50, 57, 62, 65, 69], s.beat * 1.2, 0.62, spread=0.015)
    s.roll(0, 1, [46, 53, 58, 62, 65], s.beat * 1.2, 0.58, spread=0.015)
    s.roll(0, 2, [45, 52, 57, 61, 64, 67], s.beat * 1.2, 0.6, spread=0.015)
    s.roll(0, 3, [38, 50, 57, 62, 66, 69, 74], 4.5, 0.75, spread=0.035)
    s.drum(0, 3, 0.75, f0=95, f1=52, t60=0.6)
    m = mel("A5:.75 G5:.25 F5:.5 D5:.5 E5:.25 F#5:.25 G5:.25 A5:.25 D6:3")
    s.box_line(0, m, vel=0.55)
    s.whistle(0, m, vel=0.38, transpose=-12, pan=-0.15)
    s.choir.add(bell(midi_hz(62), 4.5, s.rng, vel=0.45), s.t(0, 3), pan=-0.2)
    for mm in (50, 57, 62, 66, 69):
        for v in range(2):
            x = choir_voice(midi_hz(mm), 2.2, s.rng, att=0.15, rel=1.4, vowel=VOWEL_AH)
            s.choir.add(x, s.t(0, 3) + 0.02 * v, pan=s.rng.uniform(-0.5, 0.5), gain=0.09)
    for i, mm in enumerate([86, 90, 93, 98]):
        s.box.add(musicbox(midi_hz(mm), 2.0, s.rng, vel=0.22 + 0.04 * i), s.t(0, 3.5) + 0.07 * i, pan=0.35)
    for k in (57, 62, 66):
        s.org.add(organ(midi_hz(k), 2.0, s.rng, vel=0.14, att=0.25, rel=1.5), s.t(0, 3))
    out = s.mix({"gtr": 0.8, "box": 0.65, "wh": 0.4, "drum": 0.8, "choir": 1.0, "org": 0.6},
                rev_mix=0.3, t60=2.2, loop=False)
    out = out[:, :secs(5.6)]
    kf = secs(1.5)
    out[:, -kf:] *= np.linspace(1, 0, kf) ** 2
    return out


def build_boss_appear():
    """O chefe surge (~2,2 s): surdo + gongo grave, orgao com o bII (Re-Mib-La), cabeca de M
    descendo rapido na caixinha, sino grave."""
    s = Song3(bpm=90, beats_per_bar=4, bars=1, tail=4, seed=909)
    s.drum(0, 0, 1.0, f0=75, f1=38, t60=0.9)
    n = secs(2.2)
    t = np.arange(n) / SR
    gong = np.zeros(n)
    for r, a, tt in [(1.0, 1.0, 1.6), (1.47, 0.5, 1.2), (2.09, 0.35, 0.9), (2.76, 0.25, 0.7), (3.53, 0.15, 0.5)]:
        gong += a * np.sin(2 * np.pi * 73.4 * r * t * (1 + 0.004 * np.exp(-t / 0.3))) * exp_decay(n, tt)
    gong += bp(s.rng.normal(0, 1, n), 200, 1500) * exp_decay(n, 0.6) * 0.12
    s.bus("drum").add(fade(gong, 0.001, 0.2) * 0.35, 0.0, pan=0.1)
    s.choir.add(bell(midi_hz(50), 2.2, s.rng, vel=0.35), 0.02, pan=-0.25)
    for k, m in enumerate((50, 51, 57, 62, 63)):
        s.org.add(organ(midi_hz(m), 0.9, s.rng, vel=0.16, att=0.12, rel=0.9), 0.0, pan=(-0.4, 0.4, 0, -0.2, 0.2)[k])
    for i, m in enumerate((93, 91, 89, 86)):
        s.box.add(musicbox(midi_hz(m - 12), 1.6, s.rng, vel=0.45 - 0.05 * i), 0.12 + 0.11 * i, pan=0.35)
    s.drum(0, 0.7, 0.55, f0=70, f1=40, t60=0.6)
    out = s.mix({"box": 0.7, "org": 0.6, "drum": 1.0, "choir": 1.0}, rev_mix=0.3, t60=2.0, loop=False)
    out = out[:, :secs(2.3)]
    kf = secs(0.6)
    out[:, -kf:] *= np.linspace(1, 0, kf) ** 2
    return out


def build_stage_unlock():
    """Novo estagio liberado (~2,2 s): sino + resposta de M (Si-Do#-Re-Mi-La) em La maior na
    caixinha + coro 'aah' abrindo + violao rolado."""
    from dsp import VOWEL_AH
    s = Song3(bpm=90, beats_per_bar=4, bars=1, tail=4, seed=1010)
    s.choir.add(bell(midi_hz(69), 2.4, s.rng, vel=0.45), 0.0, pan=-0.2)
    s.roll(0, 0, [45, 52, 57, 61, 64, 69], 2.4, 0.6, spread=0.03)
    for i, m in enumerate((83, 85, 86, 88, 93)):
        s.box.add(musicbox(midi_hz(m), 1.8, s.rng, vel=0.42 + 0.04 * i), 0.05 + 0.085 * i, pan=0.3)
    for m in (57, 61, 64, 69):
        x = choir_voice(midi_hz(m), 1.0, s.rng, att=0.25, rel=1.0, vowel=VOWEL_AH)
        s.choir.add(x, 0.08, pan=s.rng.uniform(-0.5, 0.5), gain=0.12)
    out = s.mix({"gtr": 0.7, "box": 0.7, "choir": 1.0}, rev_mix=0.32, t60=2.0, loop=False)
    out = out[:, :secs(2.3)]
    kf = secs(0.6)
    out[:, -kf:] *= np.linspace(1, 0, kf) ** 2
    return out


def _prev_oneshot(id_):
    import os
    import shutil
    from common import MUSIC, PREV
    shutil.copy(os.path.join(MUSIC, id_ + ".ogg"), os.path.join(PREV, id_ + "_previa.ogg"))


JOBS = {
    "mus_boss": lambda: render_loop("mus_boss", build_boss),
    "mus_area2": lambda: render_loop("mus_area2", build_area2),
    "mus_area3": lambda: render_loop("mus_area3", build_area3),
    "mus_area4": lambda: render_loop("mus_area4", build_area4, ceiling=-2.5),
    "mus_area5": lambda: render_loop("mus_area5", build_area5),
    "mus_shop": lambda: render_loop("mus_shop", build_shop),
    "mus_ending": lambda: (render_oneshot("mus_ending", build_ending, lufs=-14.0), _prev_oneshot("mus_ending")),
    "jingle_boss_win": lambda: render_oneshot("jingle_boss_win", build_boss_win, lufs=-15.0),
    "stinger_boss_appear": lambda: render_oneshot("stinger_boss_appear", build_boss_appear, peak_db=-5.0),
    "stinger_stage_unlock": lambda: render_oneshot("stinger_stage_unlock", build_stage_unlock, peak_db=-5.0),
}
