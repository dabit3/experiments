"""Generate the original Chomp Crown synth bed and arcade cues (stdlib only)."""
import math
from pathlib import Path
import struct
import wave

ROOT = Path(__file__).resolve().parents[1] / "App" / "Audio"
RATE = 22050


def write(name, seconds, sample):
    ROOT.mkdir(exist_ok=True)
    with wave.open(str(ROOT / f"{name}.wav"), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(RATE)
        frames = bytearray()
        for i in range(int(RATE * seconds)):
            value = max(-1, min(1, sample(i / RATE)))
            frames.extend(struct.pack("<h", int(value * 28000)))
        output.writeframes(frames)


def cue(frequencies, duration):
    def sample(t):
        segment = min(len(frequencies) - 1, int(t / duration * len(frequencies)))
        f = frequencies[segment]
        envelope = (1 - (t % (duration / len(frequencies))) / (duration / len(frequencies))) ** 1.5
        return math.sin(2 * math.pi * f * t) * envelope * 0.5
    return sample


for name, notes, duration in [
    ("pellet", [560, 820], 0.09),
    ("power", [220, 330, 440, 660, 880], 0.45),
    ("eliminated", [500, 420, 300, 180, 80], 0.55),
    ("roundEnd", [523.25, 659.25, 783.99, 1046.5], 0.8),
    ("ghostEaten", [880, 1174.66, 1567.98], 0.23),
    ("bump", [110, 73], 0.12),
    ("go", [330, 660, 990], 0.3),
]:
    write(name, duration, cue(notes, duration))

NOTES = [220, 329.63, 440, 523.25, 261.63, 392, 523.25, 659.25,
         174.61, 261.63, 349.23, 440, 196, 293.66, 392, 587.33]


def music(t):
    beat = int(t / 0.25)
    note = NOTES[beat % 16]
    local = t % 0.25
    lead = (math.sin(2 * math.pi * note * 2 * t) +
            0.2 * math.sin(2 * math.pi * note * 4 * t)) * math.exp(-local * 13)
    bass = math.sin(2 * math.pi * NOTES[(beat // 4) * 4 % 16] / 2 * t) * 0.28
    kick_t = t % 0.5
    kick = math.sin(2 * math.pi * (60 * kick_t + 3 * (1 - math.exp(-kick_t * 35)))) * math.exp(-kick_t * 20)
    return (lead * 0.28 + bass + kick * 0.28) * min(1, t * 30, (16 - t) * 30)


write("neon-loop", 16, music)
