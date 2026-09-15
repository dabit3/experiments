"""Extract finished-video scene and transition frames; verify delivery metadata."""

import json
import subprocess
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
OUT = ROOT / "out"
VIDEO = OUT / "19-monochrome-accent.mp4"
FRAMES = OUT / "19-monochrome-accent-frames"
SCENES = [
    ("HOOK", 60), ("CONTEXT", 192), ("BUILD + RUN", 340),
    ("SIMULATOR", 492), ("REPRODUCE / FIX / RETEST", 690),
    ("RECORDED EVIDENCE", 870), ("OUTCOME", 1050), ("LOGO", 1215),
]
BOUNDARIES = [135, 255, 420, 585, 765, 960, 1140]


def main():
    FRAMES.mkdir(exist_ok=True)
    probe = json.loads(subprocess.check_output([
        "ffprobe", "-v", "error", "-show_streams", "-show_format", "-of", "json", str(VIDEO),
    ]))
    video = next(stream for stream in probe["streams"] if stream["codec_type"] == "video")
    assert video["codec_name"] == "h264"
    assert (video["width"], video["height"]) == (1920, 1080)
    assert video["r_frame_rate"] == "30/1"
    assert video["pix_fmt"] == "yuv420p"
    assert int(video["nb_frames"]) == 1260
    assert abs(float(probe["format"]["duration"]) - 42) < 0.05
    (OUT / "19-monochrome-accent-ffprobe.json").write_text(json.dumps(probe, indent=2))
    samples = SCENES + [("FIRST FRAME", 0)]
    for boundary in BOUNDARIES:
        samples.extend([
            (f"BEFORE {boundary / 30:g}s", boundary - 1),
            (f"WIPE {boundary / 30:g}s", boundary + 6),
            (f"AFTER {boundary / 30:g}s", boundary + 33),
        ])
    samples.append(("FINAL FRAME", 1259))
    manifest = []
    for index, (label, frame) in enumerate(samples):
        target = FRAMES / f"{index:02d}.png"
        subprocess.run([
            "ffmpeg", "-v", "error", "-y", "-ss", f"{frame / 30:.8f}",
            "-i", str(VIDEO), "-frames:v", "1", str(target),
        ], check=True)
        manifest.append({"label": f"{label}  /  f{frame}", "path": str(target)})
    subprocess.run([
        "ffmpeg", "-v", "error", "-y", "-ss", "2", "-i", str(VIDEO),
        "-frames:v", "1", str(OUT / "19-monochrome-accent-poster.png"),
    ], check=True)
    manifest_path = OUT / "19-monochrome-accent-contact.json"
    manifest_path.write_text(json.dumps(manifest))
    subprocess.run([
        "swift", str(HERE / "contact_sheet.swift"), str(manifest_path),
        str(OUT / "19-monochrome-accent-contact-sheet.png"),
    ], check=True)
    print("PASS: H.264, 1920x1080, 30fps, yuv420p, 1260 frames, 42 seconds.")
    print(f"Extracted {len(samples)} full-resolution QA frames.")


if __name__ == "__main__":
    main()
