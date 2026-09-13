"""Original 128 BPM arcade arrangement and synthesized game sounds. No samples."""
import array
import math
from pathlib import Path
import random
import wave

ROOT = Path(__file__).resolve().parents[1] / "Assets"
RATE = 22050


def save(name, data):
    peak = max(max(abs(v) for v in data), 1)
    pcm = array.array("h", (int(max(-1, min(1, v / peak * 0.76)) * 32767) for v in data))
    with wave.open(str(ROOT / f"{name}.wav"), "wb") as out:
        out.setnchannels(1); out.setsampwidth(2); out.setframerate(RATE); out.writeframes(pcm.tobytes())


beat = 60 / 128
song = [0.0] * int(beat * 64 * RATE)


def tone(start, duration, midi, volume, kind="pulse"):
    freq = 440 * 2 ** ((midi - 69) / 12)
    for i in range(int(duration * RATE)):
        t = i / RATE
        envelope = min(1, t * 100) * min(1, (duration - t) * 22)
        phase = (freq * t) % 1
        v = (1 if phase < 0.35 else -1) if kind == "pulse" else (1 - 4 * abs(phase - 0.5))
        at = int(start * RATE) + i
        if at < len(song):
            song[at] += v * volume * envelope


melody = [76, 79, 81, 83, 81, 79, 76, 74, 76, 79, 83, 86, 83, 81, 79, 74,
          72, 76, 79, 81, 79, 76, 74, 72, 74, 78, 81, 83, 81, 78, 74, 71]
roots = [40, 40, 36, 38]
for n in range(128):
    tone(n * beat / 2, beat * 0.43, melody[n % 32], 0.12)
for n in range(64):
    root = roots[(n // 4) % 4]
    tone(n * beat, beat * 0.7, root + (12 if n % 2 else 0), 0.2, "triangle")
    for note in [root + 24, root + 31, root + 36]:
        tone(n * beat + beat * 0.5, beat * 0.18, note, 0.035)
rng = random.Random(94)
for n in range(128):
    start = int(n * beat / 2 * RATE)
    for i in range(int(0.11 * RATE)):
        t = i / RATE
        hi = rng.uniform(-1, 1) * math.exp(-t * 55) * 0.07
        drum = 0
        if n % 4 == 0:
            drum = math.sin(2 * math.pi * (75 * t - 130 * t * t)) * math.exp(-t * 24) * 0.42
        elif n % 4 == 2:
            drum = rng.uniform(-1, 1) * math.exp(-t * 28) * 0.22
        if start + i < len(song):
            song[start + i] += hi + drum
save("harbor_theme", song)
for name, duration, freq, noise in [("hit", 0.16, 105, 0.6), ("block", 0.11, 640, 0.3),
                                     ("fire", 0.35, 260, 0.35), ("super", 0.65, 540, 0.15),
                                     ("ko", 0.9, 180, 0.15), ("start", 0.3, 880, 0)]:
    data = []
    for i in range(int(duration * RATE)):
        t = i / RATE
        v = math.sin(2 * math.pi * freq * (t - t * t / duration * 0.35))
        data.append((v * (1 - noise) + rng.uniform(-1, 1) * noise) * math.exp(-t * 5 / duration))
    save(name, data)
print("Generated original 30-second arcade soundtrack and six action sounds.")
