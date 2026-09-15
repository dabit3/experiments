"""Original 120 BPM instrumental, synthesized from oscillators and seeded noise."""

import math
import random
import struct
import wave
from pathlib import Path

RATE = 48000
DURATION = 40
BPM = 120
STEP = 60 / BPM
TRACK = [0.0] * (RATE * DURATION)
RNG = random.Random(60120)


def hit(start, duration, voice, pitch=65.406):
    offset = round(start * RATE)
    for i in range(round(duration * RATE)):
        if offset + i >= len(TRACK):
            break
        t = i / RATE
        if voice == "kick":
            phase = 2 * math.pi * (45 * t + 5 * (1 - math.exp(-t * 30)))
            value = 0.65 * math.sin(phase) * math.exp(-t * 17)
        elif voice == "snare":
            value = (RNG.uniform(-1, 1) * 0.21 + math.sin(2 * math.pi * 185 * t) * 0.1) * math.exp(-t * 24)
        elif voice == "hat":
            value = RNG.uniform(-1, 1) * 0.055 * math.exp(-t * 95)
        elif voice == "bass":
            envelope = min(t / 0.007, 1) * math.exp(-t * 8)
            value = (math.sin(2 * math.pi * pitch * t) + 0.18 * math.sin(4 * math.pi * pitch * t)) * 0.17 * envelope
        else:
            envelope = min(t / 0.004, 1) * math.exp(-t * 9)
            value = math.sin(2 * math.pi * pitch * t) * 0.085 * envelope
        TRACK[offset + i] += value


for beat in range(80):
    time = beat * STEP
    if beat < 75:
        if beat % 4 in (0, 2):
            hit(time, 0.36, "kick")
        if beat % 4 in (1, 3):
            hit(time, 0.25, "snare")
        hit(time, 0.08, "hat")
        hit(time + STEP / 2, 0.07, "hat")
        if beat % 4 in (0, 2, 3):
            note = [65.406, 65.406, 77.782, 58.27][(beat // 4) % 4]
            hit(time, 0.36, "bass", note)
        if beat % 8 in (0, 3, 6):
            hit(time, 0.45, "tone", [523.251, 622.254, 698.456][(beat % 8) // 3])

for beat in (0, 5, 10, 14, 18, 23, 28, 32, 37, 41, 43, 46, 51, 55, 60, 65, 70, 75):
    hit(beat * STEP, 0.34, "kick")
hit(37.5, 1.6, "tone", 523.251)
hit(37.5, 1.6, "tone", 783.991)

peak = max(abs(sample) for sample in TRACK)
with wave.open(str(Path(__file__).with_name("original-beat.wav")), "wb") as output:
    output.setnchannels(1)
    output.setsampwidth(2)
    output.setframerate(RATE)
    output.writeframes(b"".join(
        struct.pack("<h", round(sample / peak * 0.78 * 32767))
        for sample in TRACK
    ))
print(f"Original beat: {DURATION}s / {BPM} BPM / {RATE} Hz / peak -2.16 dBFS")
