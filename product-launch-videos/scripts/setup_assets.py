"""Validate and install the private, flat launch bundle without extracting paths."""

import argparse
import hashlib
import json
import shutil
import struct
import subprocess
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "public" / "assets"
MANIFEST = ROOT / "src" / "shared" / "asset-manifest.json"
EXPECTED = (
    [f"devin-web-{i}.png" for i in range(1, 20)]
    + [f"devin-desktop-{i}.png" for i in range(1, 10)]
    + [f"devin-cli-{i}.png" for i in range(1, 4)]
    + [
        "agent-selector-cloud.mp4",
        "devin-testing-2.mp4",
        "NBInternationalPro-Regular.woff2",
        "NBInternationalPro-Light.woff2",
        "GeistMono-Regular.woff2",
        "DEVIN_LOCKUP_HORIZONTAL_WHITE_TRANSPARENT.png",
        "BLACK_NO_BG_DEVIN_LOCKUP_HORIZONTAL_WHITE.png",
        "DEVIN_AVATAR_SQUARE_BLACK_NO_BG.png",
        "DEVIN_AVATAR_SQUARE_WHITE_NO_BG.png",
        "figma-cloud.png",
        "figma-cloud-hero.png",
        "production-brief.md",
        "brand-reference.md",
        "pasted-1789430547875.txt",
    ]
)


def validate_archive(archive):
    names = archive.namelist()
    if len(names) != len(set(names)):
        raise ValueError("Duplicate ZIP entries are not allowed")
    if set(names) != set(EXPECTED):
        missing = sorted(set(EXPECTED) - set(names))
        extra = sorted(set(names) - set(EXPECTED))
        raise ValueError(f"Bundle inventory mismatch. Missing: {missing}; extra: {extra}")
    if sum(item.file_size for item in archive.infolist()) > 512 * 1024 * 1024:
        raise ValueError("Bundle exceeds the 512 MB uncompressed limit")
    for item in archive.infolist():
        if item.filename != Path(item.filename).name or item.is_dir():
            raise ValueError("Expected flat ZIP files only")
        if (item.external_attr >> 16) & 0o170000 == 0o120000:
            raise ValueError("ZIP symlinks are not allowed")


def inspect_file(path):
    data = path.read_bytes()
    record = {
        "file": path.name,
        "bytes": len(data),
        "sha256": hashlib.sha256(data).hexdigest(),
    }
    if path.suffix == ".png":
        if data[:8] != b"\x89PNG\r\n\x1a\n" or data[12:16] != b"IHDR":
            raise ValueError(f"Invalid PNG: {path.name}")
        width, height = struct.unpack(">II", data[16:24])
        record.update(kind="image", width=width, height=height)
    elif path.suffix == ".woff2":
        if data[:4] != b"wOF2":
            raise ValueError(f"Invalid WOFF2: {path.name}")
        record.update(kind="font")
    elif path.suffix == ".mp4":
        result = subprocess.run(
            [
                "ffprobe", "-v", "error", "-select_streams", "v:0",
                "-show_entries", "stream=width,height,r_frame_rate,duration,nb_frames",
                "-of", "json", str(path),
            ],
            check=True, capture_output=True, text=True,
        )
        stream = json.loads(result.stdout)["streams"][0]
        numerator, denominator = map(int, stream["r_frame_rate"].split("/"))
        record.update(
            kind="video", width=stream["width"], height=stream["height"],
            fps=numerator / denominator, durationSeconds=float(stream["duration"]),
            frameCount=int(stream["nb_frames"]),
        )
    else:
        data.decode("utf-8")
        record.update(kind="document")
    return record


def check_assets(expected):
    actual = {name: inspect_file(ASSETS / name) for name in EXPECTED}
    for name in EXPECTED:
        if actual[name] != expected[name]:
            raise ValueError(f"Asset does not match the verified bundle: {name}")
    return actual


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("zip_path", nargs="?", type=Path)
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--record-manifest", action="store_true",
                        help="Foundation maintenance only: regenerate tracked metadata")
    args = parser.parse_args()
    if not shutil.which("ffprobe"):
        parser.error("ffprobe is required. Install FFmpeg and retry.")
    if args.check and (args.zip_path or args.record_manifest):
        parser.error("--check cannot be combined with a ZIP or --record-manifest")
    if not args.check and not args.zip_path:
        parser.error("Pass the path to the downloaded shared-assets.zip")
    expected = json.loads(MANIFEST.read_text()) if MANIFEST.exists() else None
    if expected is None and not args.record_manifest:
        parser.error("Tracked asset-manifest.json is missing")
    if args.zip_path:
        with zipfile.ZipFile(args.zip_path) as archive:
            validate_archive(archive)
            # Check all hashes before replacing any previously installed assets.
            if not args.record_manifest:
                for name in EXPECTED:
                    digest = hashlib.sha256(archive.read(name)).hexdigest()
                    if digest != expected[name]["sha256"]:
                        raise ValueError(f"ZIP checksum mismatch: {name}")
            ASSETS.mkdir(parents=True, exist_ok=True)
            for name in EXPECTED:
                destination = ASSETS / name
                if destination.is_symlink():
                    raise ValueError(f"Refusing symlink destination: {name}")
                destination.write_bytes(archive.read(name))
    if args.record_manifest:
        actual = {name: inspect_file(ASSETS / name) for name in EXPECTED}
        MANIFEST.write_text(json.dumps(actual, indent=2, sort_keys=True) + "\n")
    else:
        actual = check_assets(expected)
    print(f"PASS: {len(actual)} original assets verified in {ASSETS}")
    for record in actual.values():
        if record["kind"] == "video":
            print(f'{record["file"]}: {record["width"]}x{record["height"]}, '
                  f'{record["fps"]} fps, {record["durationSeconds"]} seconds')


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, zipfile.BadZipFile, subprocess.CalledProcessError) as error:
        print(f"Asset setup failed: {error}", file=sys.stderr)
        sys.exit(1)
