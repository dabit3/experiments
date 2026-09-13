"""Generate original deterministic synth music and arcade cues; no sample libraries."""
import math
import random
import struct
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "App" / "Resources"
RATE = 22050


def save(name, samples):
    peak = max(1.0, max(abs(s) for s in samples))
    with wave.open(str(ROOT / f"{name}.wav"), "wb") as out:
        out.setparams((1, 2, RATE, 0, "NONE", "not compressed"))
        out.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s / peak)) * 29000)) for s in samples))


def note(midi):
    return 440 * 2 ** ((midi - 69) / 12)


def score():
    duration = 32
    samples = [0.0] * (duration * RATE)
    chords = [(38, 45, 50, 53), (34, 41, 46, 50), (41, 48, 53, 57), (36, 43, 48, 52)]
    melody = [74, 69, 72, 65, 74, 77, 72, 69, 70, 65, 69, 62, 70, 74, 69, 65]
    for i in range(len(samples)):
        t = i / RATE
        chord = chords[int(t / 4) % 4]
        bar_t = t % 4
        fade = min(1, bar_t * 5, (4 - bar_t) * 5)
        pad = sum(math.sin(2 * math.pi * note(n) * t) + 0.2 * math.sin(2 * math.pi * note(n) * 2.005 * t)
                  for n in chord) * 0.047 * fade
        beat = t % 0.5
        bass = math.sin(2 * math.pi * note(chord[0] - 12) * t) * math.exp(-beat * 8) * 0.18
        kick = math.sin(2 * math.pi * (45 * beat + 8 * (1 - math.exp(-beat * 30)))) * math.exp(-beat * 22) * 0.4
        phase = t % 0.25
        n = melody[int(t / 0.5) % len(melody)]
        lead = math.sin(2 * math.pi * note(n) * t) * math.exp(-phase * 11) * 0.06
        samples[i] = pad + bass + kick + lead
    save("score", samples)


def effect(name, duration, low, high, noise=0.0):
    rng = random.Random(name)
    samples = []
    for i in range(int(duration * RATE)):
        t = i / RATE
        u = t / duration
        phase = 2 * math.pi * (low * t + (high - low) * t * t / (2 * duration))
        envelope = min(1, t * 200) * (1 - u) ** 2
        samples.append((math.sin(phase) * 0.65 + rng.uniform(-1, 1) * noise) * envelope)
    save(name, samples)


score()
for args in [
    ("hit", 0.18, 140, 30, 0.65), ("block", 0.23, 850, 290, 0.18),
    ("super", 1.6, 70, 480, 0.13), ("ko", 0.75, 190, 25, 0.35),
    ("tag", 0.35, 160, 700, 0.03), ("tap", 0.07, 650, 400, 0.03),
    ("start", 0.8, 240, 620, 0.03), ("win", 1.7, 330, 880, 0.02)
]:
    effect(*args)
