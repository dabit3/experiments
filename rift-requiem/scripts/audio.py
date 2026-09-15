"""Generate the original Cathedral Engine riff and synthesized combat foley."""
import math
import random
import struct
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "Resources"
RATE = 22050
RNG = random.Random(414)


def write(name, seconds, sample):
    with wave.open(str(ROOT / f"{name}.wav"), "wb") as out:
        out.setparams((1, 2, RATE, 0, "NONE", "not compressed"))
        out.writeframes(b"".join(
            struct.pack("<h", int(max(-1, min(1, sample(i / RATE))) * 28000))
            for i in range(int(seconds * RATE))
        ))


RIFF = [40, 40, 52, 40, 43, 40, 45, 43, 40, 40, 47, 46, 43, 45, 38, 38]


def song(t):
    beat = t * 2.2
    eighth = int(beat * 2)
    phase = beat * 2 % 1
    freq = 440 * 2 ** ((RIFF[eighth % 16] - 69) / 12)
    guitar = sum(math.tanh(3 * math.sin(2 * math.pi * freq * ratio * t))
                 for ratio in (1, 1.5, 2.003)) / 3
    guitar *= 0.23 * math.exp(-phase * 3)
    bass = math.sin(2 * math.pi * freq / 2 * t) * 0.12
    kick_phase = beat % 1 / 2.2
    kick = math.sin(2 * math.pi * (52 * kick_phase + 13 * (1 - math.exp(-30 * kick_phase))))
    kick *= math.exp(-kick_phase * 22) * 0.32
    snare_phase = beat % 2 / 2.2
    snare = RNG.uniform(-1, 1) * math.exp(-max(0, snare_phase - 1 / 2.2) * 30) * 0.2
    if snare_phase < 1 / 2.2:
        snare = 0
    hat = RNG.uniform(-1, 1) * math.exp(-phase * 24) * 0.10
    return guitar + bass + kick + snare + hat


write("cathedral-riff", 32 / 2.2, song)
write("hit", 0.24, lambda t: (
    RNG.uniform(-1, 1) * 0.6 + math.sin(t * (650 - t * 900))) * math.exp(-t * 24))
write("block", 0.25, lambda t: (
    math.sin(t * 8000) + math.sin(t * 5371)) * 0.3 * math.exp(-t * 22))
write("slash", 0.20, lambda t: RNG.uniform(-1, 1) * math.sin(t * 900) * math.exp(-t * 15) * 0.5)
write("cancel", 0.65, lambda t: (
    math.sin(t * (1800 + t * 3000)) + math.sin(t * 2700)) * 0.24 * math.exp(-t * 5))
write("finish", 1.1, lambda t: (
    math.sin(t * 410) + math.sin(t * 610) + math.sin(t * 820)) * 0.22 * math.exp(-t * 3))
