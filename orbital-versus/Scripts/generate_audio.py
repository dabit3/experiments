"""Deterministic original 112-BPM synth cue and mecha sound effects; no samples."""
import math
import pathlib
import random
import struct
import wave

ROOT = pathlib.Path(__file__).resolve().parents[1] / "App" / "Audio"
RATE = 22050


def save(name, duration, sample):
    with wave.open(str(ROOT / f"{name}.wav"), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(RATE)
        data = bytearray()
        for index in range(int(duration * RATE)):
            value = max(-1, min(1, sample(index / RATE)))
            data.extend(struct.pack("<h", int(value * 24000)))
        output.writeframes(data)


def music(t):
    beat = t * 112 / 60
    progression = [110, 87.307, 130.813, 97.999]
    root = progression[int(beat // 8) % 4]
    eighth = int(beat * 2)
    degree = [0, 7, 12, 19, 12, 7, 15, 19][eighth % 8]
    frequency = root * 2 ** (degree / 12)
    local = (beat * 2) % 1
    arp = math.sin(2 * math.pi * frequency * t) * math.exp(-local * 4) * 0.20
    bass = math.sin(2 * math.pi * root / 2 * t) * 0.16
    kick_time = beat % 1 * 60 / 112
    kick = math.sin(2 * math.pi * (48 * kick_time + 8 * (1 - math.exp(-kick_time * 30)))) * math.exp(-kick_time * 20) * 0.25
    hat = math.sin(t * 17321) * math.sin(t * 23637) * math.exp(-local * 23) * 0.07
    return (arp + bass + kick + hat) * min(1, t * 8)


def main():
    ROOT.mkdir(exist_ok=True)
    save("orbit", 32 * 60 / 112, music)
    save("fire", 0.20, lambda t: math.sin(2 * math.pi * (1700 * t - 3300 * t * t)) * math.exp(-t * 18))
    save("saber", 0.36, lambda t: (math.sin(2 * math.pi * (150 * t + 1400 * t * t)) + math.sin(t * 4133) * 0.4) * math.sin(math.pi * t / 0.36) * 0.7)
    rng = random.Random(81)
    save("destroy", 0.9, lambda t: (rng.uniform(-1, 1) * 0.65 + math.sin(t * 173) * 0.35) * math.exp(-t * 5))
    save("hit", 0.14, lambda t: rng.uniform(-1, 1) * math.exp(-t * 30))
    save("burst", 0.8, lambda t: math.sin(2 * math.pi * (200 * t + 500 * t * t)) * math.sin(math.pi * t / 0.8))
    for name, pitches in [("confirm", [440, 660, 880]), ("lock", [1200, 1600]), ("result", [440, 554, 660, 880])]:
        duration = len(pitches) * 0.13
        save(name, duration, lambda t, notes=pitches: math.sin(2 * math.pi * notes[min(len(notes) - 1, int(t / 0.13))] * t) * math.exp(-(t % 0.13) * 16) * 0.5)


if __name__ == "__main__":
    main()
