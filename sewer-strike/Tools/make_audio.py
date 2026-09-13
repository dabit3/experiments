"""Generate original 128 BPM electro-funk and arcade sound effects; no samples."""
import array
import math
from pathlib import Path
import random
import wave

RATE = 22050
ROOT = Path(__file__).resolve().parents[1] / "Resources"
random.seed(17)


def write(name, samples):
    peak = max(1, max(abs(s) for s in samples))
    pcm = array.array("h", (int(s / peak * 28000) for s in samples))
    with wave.open(str(ROOT / f"{name}.wav"), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(pcm.tobytes())


def tone(freq, t):
    return math.sin(2 * math.pi * freq * t) + 0.23 * math.sin(4 * math.pi * freq * t)


def music():
    beat = 60 / 128
    notes = [40, 40, 47, 50, 43, 43, 50, 53, 45, 45, 52, 55, 47, 47, 54, 57]
    lead = [76, 79, 83, 79, 74, 78, 81, 78, 76, 79, 83, 86, 81, 78, 74, 71]
    samples = []
    for i in range(int(RATE * beat * 64)):
        t = i / RATE
        b = int(t / beat)
        sub = int(t / (beat / 2))
        phase = t % beat
        sixteenth = t % (beat / 4)
        bass = 440 * 2 ** ((notes[(b // 4) % 16] - 69) / 12)
        sound = 0.22 * tone(bass, t) * math.exp(-phase * 8)
        sound += 0.42 * math.sin(2 * math.pi * (48 * phase + 4 * (1 - math.exp(-phase * 45)))) * math.exp(-phase * 18)
        if b % 2 == 1:
            sound += 0.20 * random.uniform(-1, 1) * math.exp(-phase * 27)
        sound += 0.045 * random.uniform(-1, 1) * math.exp(-sixteenth * 90)
        melody = 440 * 2 ** ((lead[sub % 16] - 69) / 12)
        sound += 0.105 * tone(melody, t) * math.exp(-(t % (beat / 2)) * 10)
        sound += 0.045 * tone(bass * 4, t) * math.sin(math.pi * phase / beat)
        samples.append(sound)
    write("undercurrent", samples)


music()
for name, duration in [("hit", .16), ("slam", .4), ("jump", .23), ("power", .8), ("heal", .5), ("clear", 1.6)]:
    samples = []
    for i in range(int(RATE * duration)):
        t = i / RATE
        decay = math.exp(-t * (15 if name == "hit" else 5))
        if name in ("hit", "slam"):
            sound = (.6 * random.uniform(-1, 1) + tone(75, t)) * decay
        elif name == "jump":
            sound = math.sin(2 * math.pi * (350 * t + 1000 * t * t)) * decay
        elif name == "power":
            sound = (tone(110 + 450 * t, t) + .2 * random.uniform(-1, 1)) * decay
        else:
            frequencies = [523.25, 659.25, 783.99, 1046.5]
            frequency = frequencies[min(3, int(t / (duration / 4)))]
            sound = tone(frequency, t) * .7 * math.exp(-(t % (duration / 4)) * 6)
        samples.append(sound)
    write(name, samples)
print("Authored seven PCM WAV assets at 22050 Hz")
