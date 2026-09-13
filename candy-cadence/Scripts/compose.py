"""Reproducible original music and phrase-authored nine-lane charts (no dependencies)."""
import json
import math
import pathlib
import struct
import wave

ROOT = pathlib.Path(__file__).resolve().parents[1] / "Resources"
RATE = 22050
SONGS = [
    ("sugar", "Sugar Rush Parade", "CANDY POP", 120, "MALLOW & THE SPRINKLES", 0),
    ("soda", "Soda Galaxy", "BUBBLE DISCO", 138, "FIZZY COSMIC CLUB", 5),
]
MELODIES = [
    [72, 76, 79, 76, 74, 77, 81, 79, 76, 79, 84, 83, 81, 79, 76, 74],
    [77, 81, 84, 88, 86, 84, 81, 79, 77, 79, 81, 84, 86, 84, 81, 79],
]
PHRASES = [
    [0, 2, 4, 6, 8, 6, 4, 2],
    [1, 3, 5, 7, 5, 3, 1, 4],
    [0, 4, 8, 4, 2, 6, 3, 5],
    [8, 7, 6, 5, 4, 3, 2, 1],
]


def make_song(index, spec):
    ident, title, genre, bpm, artist, transpose = spec
    beat = 60 / bpm
    duration = 100 * beat + 2
    samples = [0.0] * int(duration * RATE)

    def tone(at, length, midi, gain, kind="bell"):
        frequency = 440 * 2 ** ((midi - 69) / 12)
        start = int(at * RATE)
        count = int(length * RATE)
        for i in range(min(count, len(samples) - start)):
            t = i / RATE
            envelope = min(1, t / 0.008) * max(0, 1 - i / count) ** 2
            phase = 2 * math.pi * frequency * t
            if kind == "bass":
                sound = math.sin(phase) + 0.25 * math.sin(phase * 2)
            else:
                sound = math.sin(phase) + 0.3 * math.sin(phase * 2) + 0.12 * math.sin(phase * 3)
            samples[start + i] += sound * envelope * gain

    def drum(at, kind):
        start = int(at * RATE)
        count = int(RATE * (0.18 if kind == "kick" else 0.10))
        for i in range(min(count, len(samples) - start)):
            t = i / RATE
            if kind == "kick":
                sound = math.sin(2 * math.pi * (65 * t + 3 * (1 - math.exp(-30 * t))))
                sound *= math.exp(-24 * t) * 0.38
            else:
                noise = math.sin(i * 127.1 + 13.7) * math.sin(i * 311.7)
                sound = noise * math.exp(-t * (55 if kind == "hat" else 30))
                sound *= 0.14 if kind == "hat" else 0.26
            samples[start + i] += sound

    notes = []
    for bar in range(24):
        root = [48, 53, 57, 55][(bar // 2) % 4] + transpose
        for step in range(8):
            position = 4 + bar * 4 + step * 0.5
            at = position * beat
            drum(at, "hat")
            if step % 2 == 0:
                drum(at, "kick")
                tone(at, beat * 0.8, root - 12, 0.24, "bass")
            if step in (2, 6):
                drum(at, "snare")
                for interval in (0, 4 if root % 12 != 9 else 3, 7):
                    tone(at, beat * 0.65, root + interval + 12, 0.075)
            melody = MELODIES[index][(step + (bar % 2) * 8) % 16]
            tone(at, beat * 0.7, melody + (12 if bar >= 16 else 0), 0.19)
            if bar < 4 and step % 2:
                continue
            if 8 <= bar < 12 and step in (3, 7):
                continue
            lane = PHRASES[(bar // 2 + index) % 4][step]
            notes.append({"id": len(notes), "lane": lane, "at": round(at * 1000)})
            if bar >= 16 and step in (0, 4):
                other = 8 - lane if lane != 4 else (0 if step == 0 else 8)
                notes.append({"id": len(notes), "lane": other, "at": round(at * 1000)})
    for tick in range(4):
        tone(tick * beat, 0.09, 84 if tick == 0 else 79, 0.15)
    for interval in (0, 4, 7, 12):
        tone(100 * beat, 1.8, 60 + transpose + interval, 0.12)
    peak = max(abs(value) for value in samples)
    with wave.open(str(ROOT / f"{ident}.wav"), "wb") as audio:
        audio.setnchannels(1)
        audio.setsampwidth(2)
        audio.setframerate(RATE)
        audio.writeframes(b"".join(struct.pack("<h", int(value / max(peak, 1) * 28000)) for value in samples))
    return {
        "id": ident, "title": title, "genre": genre, "artist": artist, "bpm": bpm,
        "duration": round(duration * 1000), "level": 6 if index == 0 else 8,
        "notes": sorted(notes, key=lambda note: (note["at"], note["lane"])),
    }


if __name__ == "__main__":
    ROOT.mkdir(exist_ok=True)
    for lane in range(9):
        frequency = 440 * 2 ** ((72 + [0, 2, 4, 5, 7, 9, 11, 12, 14][lane] - 69) / 12)
        frames = []
        for index in range(int(RATE * 0.06)):
            t = index / RATE
            sound = math.sin(2 * math.pi * frequency * t) * math.exp(-t * 70)
            frames.append(struct.pack("<h", int(sound * 18000)))
        with wave.open(str(ROOT / f"tap{lane}.wav"), "wb") as audio:
            audio.setnchannels(1)
            audio.setsampwidth(2)
            audio.setframerate(RATE)
            audio.writeframes(b"".join(frames))
    catalog = [make_song(index, spec) for index, spec in enumerate(SONGS)]
    (ROOT / "songs.json").write_text(json.dumps(catalog, separators=(",", ":")) + "\n")
    print([(song["title"], len(song["notes"]), song["duration"]) for song in catalog])
