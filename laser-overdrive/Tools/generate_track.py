"""Generate the original, deterministic ION / AFTERBURN score and stereo music."""

import array
import json
import math
from pathlib import Path
import random
import wave

ROOT = Path(__file__).resolve().parents[1]
RATE = 44100
BPM = 144
BEAT = 60 / BPM
INTRO = 2.0
BARS = 24
DURATION = INTRO + BARS * 4 * BEAT + 2
random.seed(144)


def generate_chart():
    notes = []
    lasers = []
    motifs = [
        [0, 1, 2, 3, 2, 1, 0, 3],
        [3, 2, 0, 1, 3, 1, 2, 0],
        [0, 2, 1, 3, 0, 3, 2, 1],
        [1, 0, 3, 2, 1, 2, 3, 0],
    ]
    for bar in range(BARS):
        start = INTRO + bar * 4 * BEAT
        motif = motifs[bar % 4]
        for step in range(8):
            # Quiet space on the sustained-note phrases is deliberate.
            if bar % 4 == 3 and step in [1, 2, 3, 5, 6, 7]:
                continue
            duration = BEAT * 1.5 if bar % 4 == 3 else 0
            notes.append({
                "id": len(notes), "lane": motif[step],
                "time": round(start + step * BEAT / 2, 5),
                "duration": round(duration, 5), "kind": "bt",
            })
        for step, lane in [(1, 4), (3, 5)]:
            notes.append({
                "id": len(notes), "lane": lane,
                "time": round(start + step * BEAT, 5),
                "duration": round(BEAT * 0.75 if bar % 2 else 0, 5),
                "kind": "fx",
            })
        # Four-beat laser phrases alternate hands, then cross at the climax.
        colors = [bar % 2] if bar < 16 else [0, 1]
        for color in colors:
            flip = -1 if color else 1
            positions = [0.18, 0.18, 0.76, 0.76, 0.28, 0.28, 0.82]
            if bar % 3 == 1:
                positions = [0.8, 0.5, 0.2, 0.2, 0.72, 0.72, 0.3]
            beats = [0, 0.5, 1.5, 2, 2.06, 2.5, 3.75]
            points = [
                {"time": round(start + beat * BEAT, 5),
                 "x": round(x if flip == 1 else 1 - x, 4)}
                for beat, x in zip(beats, positions)
            ]
            lasers.append({"id": len(lasers), "color": color, "points": points})
    notes.sort(key=lambda n: n["time"])
    for index, note in enumerate(notes):
        note["id"] = index
    chart = {
        "id": "ion-afterburn-v1", "title": "ION / AFTERBURN",
        "artist": "OVERDRIVE SOUND SYSTEM", "bpm": BPM,
        "duration": DURATION, "tick": BEAT / 4, "notes": notes, "lasers": lasers,
    }
    (ROOT / "Resources/chart.json").write_text(json.dumps(chart, separators=(",", ":")))


def generate_music():
    data = array.array("f", [0]) * (int(DURATION * RATE) + RATE)

    def tone(start, length, frequency, volume, kind="lead"):
        offset = int(start * RATE)
        count = int(length * RATE)
        for index in range(count):
            t = index / RATE
            attack = min(1, t / 0.008)
            release = min(1, (length - t) / 0.065)
            phase = 2 * math.pi * frequency * t
            if kind == "bass":
                sound = math.sin(phase) + 0.3 * math.sin(phase * 2)
            elif kind == "pad":
                sound = (math.sin(phase) + math.sin(phase * 1.004)) * 0.5
            else:
                sound = math.sin(phase) + 0.24 * math.sin(phase * 3) + 0.12 * math.sin(phase * 5)
            data[offset + index] += volume * sound * attack * release

    def drum(start, kind):
        length = {"kick": 0.28, "snare": 0.17, "hat": 0.045}[kind]
        offset = int(start * RATE)
        for index in range(int(length * RATE)):
            t = index / RATE
            noise = random.uniform(-1, 1)
            if kind == "kick":
                phase = 2 * math.pi * (47 * t + 1.4 * (1 - math.exp(-t * 36)))
                sound = 0.68 * math.sin(phase) * math.exp(-t * 16)
            elif kind == "snare":
                sound = (noise * 0.28 + math.sin(2 * math.pi * 185 * t) * 0.11) * math.exp(-t * 25)
            else:
                sound = noise * 0.115 * math.exp(-t * 95)
            data[offset + index] += sound

    def hz(midi):
        return 440 * 2 ** ((midi - 69) / 12)

    progression = [40, 36, 43, 38]  # E, C, G, D.
    lead = [0, 7, 12, 10, 7, 3, 5, 7, 12, 14, 15, 14, 12, 7, 10, 7]
    for bar in range(BARS):
        root = progression[bar % 4]
        start = INTRO + bar * 4 * BEAT
        for beat in range(4):
            drum(start + beat * BEAT, "kick")
            if beat % 2:
                drum(start + beat * BEAT, "snare")
            for half in range(2):
                drum(start + (beat + half / 2) * BEAT, "hat")
            tone(start + beat * BEAT + BEAT / 2, BEAT * 0.43, hz(root), 0.25, "bass")
        for chord in [0, 7, 12, 15 if root in [40, 36] else 16]:
            tone(start, BEAT * 3.8, hz(root + 12 + chord), 0.034, "pad")
        for step in range(16):
            melody = lead[(step + bar * 2) % len(lead)]
            volume = 0.1 if bar < 8 else 0.135
            if 8 <= bar < 12 and step % 2:
                continue
            at = start + step * BEAT / 4
            tone(at, BEAT * 0.19, hz(root + 24 + melody), volume)
            tone(at + BEAT * 0.75, BEAT * 0.18, hz(root + 24 + melody), volume * 0.23)
        if bar in [0, 8, 16, 20]:
            for step in range(8):
                tone(start + step * BEAT / 8, BEAT / 7, hz(52 + step * 2), 0.09)
    # Final resolved chord and long tail.
    for midi in [40, 52, 59, 64, 67]:
        tone(INTRO + BARS * 4 * BEAT, 1.8, hz(midi), 0.07, "pad")
    pcm = array.array("h")
    for index in range(int(DURATION * RATE)):
        left = math.tanh(data[index] * 1.25) * 0.88
        delayed = data[max(0, index - int(BEAT * 0.75 * RATE))]
        right = math.tanh((data[index] * 0.94 + delayed * 0.1) * 1.25) * 0.88
        pcm.extend([int(left * 32767), int(right * 32767)])
    with wave.open(str(ROOT / "Resources/afterburn.wav"), "wb") as output:
        output.setnchannels(2)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(pcm.tobytes())


if __name__ == "__main__":
    generate_chart()
    generate_music()
    print(f"Generated {DURATION:.2f}s original stereo track at {BPM} BPM")
