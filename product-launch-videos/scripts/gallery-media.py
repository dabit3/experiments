"""Install authenticated downloads, verify the collection, and package a local gallery."""

import argparse
import concurrent.futures
import hashlib
import json
import shutil
import struct
import subprocess
import zipfile
from pathlib import Path
from urllib.parse import urlparse


ROOT = Path(__file__).resolve().parent.parent
MANIFEST = ROOT / "gallery-manifest.json"
KINDS = {"video": "sample.mp4", "poster": "poster.png", "contact_sheet": "contact-sheet.png"}


def digest(path):
    checksum = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            checksum.update(chunk)
    return checksum.hexdigest()


def run(*args):
    return subprocess.check_output(args, text=True, cwd=ROOT.parent if args[0] == "git" else ROOT).strip()


def png_size(path):
    with path.open("rb") as stream:
        header = stream.read(24)
    if header[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError(f"Not a PNG: {path}")
    return struct.unpack(">II", header[16:24])


def hydrate(manifest, downloads):
    for entry in manifest["templates"]:
        target = ROOT / "public/renders" / entry["slug"]
        target.mkdir(parents=True, exist_ok=True)
        for kind, filename in KINDS.items():
            parts = Path(urlparse(entry[f"{kind}_url"]).path).parts
            source = downloads / parts[-2] / parts[-1]
            if not source.is_file():
                raise FileNotFoundError(f"Download through authenticated attachment tooling first: {source}")
            shutil.copy2(source, target / filename)
        print(f"Installed {entry['slug']}", flush=True)


def verify_entry(entry, expected, foundation):
    result = dict(entry)
    directory = ROOT / "src/templates" / entry["slug"]
    result["sourcePath"] = f"product-launch-videos/src/templates/{entry['slug']}/"
    result["local"] = {
        kind: f"renders/{entry['slug']}/{filename}" for kind, filename in KINDS.items()
    }
    result["checks"] = {}
    try:
        remote = run("git", "rev-parse", f"origin/{entry['branch']}")
        if remote != entry["commit"]:
            raise ValueError(f"Producer branch changed: {remote}")
        relative = f"product-launch-videos/src/templates/{entry['slug']}/"
        changed = run("git", "diff", "--name-only", foundation, entry["commit"]).splitlines()
        if not changed or any(not name.startswith(relative) for name in changed):
            raise ValueError("Producer changed files outside its assigned directory")
        files = run("git", "ls-tree", "-r", entry["commit"], "--", relative).splitlines()
        if not files:
            raise ValueError("No producer source files found")
        for line in files:
            fields, path = line.split("\t", 1)
            blob = fields.split()[2]
            if run("git", "hash-object", str(ROOT.parent / path)) != blob:
                raise ValueError(f"Source differs from producer: {path}")
        required = ["entry.tsx", "index.ts", "Template.tsx", "config.ts", "manifest.json", "attribution.json", "README.md"]
        if not all((directory / name).is_file() for name in required):
            raise ValueError("Incomplete template directory")
        result["checks"]["source"] = f"PASS: {len(files)} files identical to producer commit"
        video = ROOT / "public" / result["local"]["video"]
        probe = json.loads(run(
            "ffprobe", "-v", "error", "-count_frames", "-show_streams", "-show_format",
            "-of", "json", str(video),
        ))
        streams = probe["streams"]
        if len(streams) != 1 or streams[0]["codec_type"] != "video":
            raise ValueError("Expected one silent video stream")
        stream = streams[0]
        measured = {
            "codec": stream["codec_name"], "width": stream["width"], "height": stream["height"],
            "fps": stream["r_frame_rate"], "frames": int(stream["nb_read_frames"]),
            "durationSeconds": float(probe["format"]["duration"]),
        }
        if not (
            measured["codec"] == "h264"
            and measured["width"] == expected["width"]
            and measured["height"] == expected["height"]
            and measured["fps"] == f"{expected['fps']}/1"
            and measured["frames"] == expected["frames"]
            and abs(measured["durationSeconds"] - expected["durationSeconds"]) < 0.001
        ):
            raise ValueError(f"Unexpected metadata: {measured}")
        run("ffmpeg", "-v", "error", "-xerror", "-threads", "2", "-i", str(video), "-f", "null", "-")
        result["checks"]["video"] = measured
        result["checks"]["decode"] = "PASS: complete MP4 decoded without errors"
        result["checks"]["artifacts"] = {}
        for kind, path in result["local"].items():
            artifact = ROOT / "public" / path
            record = {"bytes": artifact.stat().st_size, "sha256": digest(artifact)}
            if kind != "video":
                width, height = png_size(artifact)
                if kind == "poster" and (width, height) != (1920, 1080):
                    raise ValueError(f"Unexpected poster dimensions: {width}x{height}")
                run("ffmpeg", "-v", "error", "-xerror", "-i", str(artifact), "-f", "null", "-")
                record.update(width=width, height=height)
            result["checks"]["artifacts"][kind] = record
        result["status"] = "complete"
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        result["status"] = "failed"
        result["checks"]["error"] = str(error)
    print(f"{result['status']}: {entry['slug']}", flush=True)
    return result


def verify(manifest):
    expected_numbers = list(range(1, manifest["expected"]["count"] + 1))
    if [entry["number"] for entry in manifest["templates"]] != expected_numbers:
        raise ValueError("Manifest must include every numbered direction exactly once")
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
        results = list(pool.map(
            lambda entry: verify_entry(entry, manifest["expected"], manifest["foundationCommit"]),
            manifest["templates"],
        ))
    manifest["templates"] = results
    manifest["completedCount"] = sum(entry["status"] == "complete" for entry in results)
    MANIFEST.write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"Completed {manifest['completedCount']} / {len(results)}")
    if manifest["completedCount"] != len(results):
        raise SystemExit(1)


def comparison(manifest):
    out = ROOT / "out/comparison"
    out.mkdir(parents=True, exist_ok=True)
    font = ROOT / "public/assets/NBInternationalPro-Regular.woff2"
    for entry in manifest["templates"]:
        if entry.get("status") != "complete":
            raise ValueError(f"Cannot include unverified poster: {entry['slug']}")
        label = out / f"label-{entry['number']:02}.txt"
        title = entry["name"]
        if len(title) > 29:
            words = title.split()
            half = min(range(1, len(words)), key=lambda i: abs(len(" ".join(words[:i])) - len(" ".join(words[i:]))))
            title = " ".join(words[:half]) + "\n" + " ".join(words[half:])
        label.write_text(f"{entry['number']:02}   {title}")
        run(
            "ffmpeg", "-v", "error", "-y", "-i", str(ROOT / "public" / entry["local"]["poster"]),
            "-vf", f"scale=640:360,pad=664:456:12:12:color=0xf7f6f5,"
            f"drawtext=fontfile='{font}':textfile='{label}':fontsize=25:fontcolor=0x191919:x=16:y=390:line_spacing=4",
            "-frames:v", "1", str(out / f"tile-{entry['number']:02}.png"),
        )
    run(
        "ffmpeg", "-v", "error", "-y", "-pattern_type", "glob", "-i", str(out / "tile-*.png"),
        "-vf", "tile=4x5:nb_frames=20:padding=12:margin=24:color=0xf7f6f5",
        "-frames:v", "1", str(out / "comparison.png"),
    )
    print(out / "comparison.png")


def package(manifest):
    if (
        manifest.get("completedCount") != manifest["expected"]["count"]
        or len(manifest["templates"]) != manifest["expected"]["count"]
        or any(entry.get("status") != "complete" for entry in manifest["templates"])
    ):
        raise ValueError("Verify the full collection before packaging")
    for entry in manifest["templates"]:
        for kind, local in entry["local"].items():
            if digest(ROOT / "public" / local) != entry["checks"]["artifacts"][kind]["sha256"]:
                raise ValueError(f"Artifact changed since verification: {local}")
        props = ROOT / "public/renders" / entry["slug"] / "default-props.json"
        if not props.is_file():
            raise FileNotFoundError(f"Run gallery:catalog before packaging: {props}")
    destination = ROOT / "out/portable-gallery"
    if destination.exists():
        raise FileExistsError(f"Move the previous package before rebuilding: {destination}")
    shutil.copytree(ROOT / "dist", destination)
    shutil.copytree(ROOT / "public/renders", destination / "renders")
    fonts = destination / "brand"
    fonts.mkdir()
    shutil.copy2(ROOT / "public/assets/NBInternationalPro-Regular.woff2", fonts)
    shutil.copy2(MANIFEST, destination / "gallery-manifest.json")
    shutil.copy2(ROOT / "out/comparison/comparison.png", destination / "comparison.png")
    shutil.copy2(ROOT / "GALLERY.md", destination / "README.md")
    index = destination / "index.html"
    html = index.read_text().replace('type="module"', "defer").replace(" crossorigin", "")
    index.write_text(html)
    source_root = destination / "sources"
    source_root.mkdir()
    for entry in manifest["templates"]:
        source = ROOT / "src/templates" / entry["slug"]
        shutil.copytree(source, source_root / entry["slug"])
    archive = ROOT / "out/devin-on-mac-gallery.zip"
    with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=1) as bundle:
        for path in sorted(destination.rglob("*")):
            if path.is_file():
                bundle.write(path, Path("devin-on-mac-gallery") / path.relative_to(destination))
    with zipfile.ZipFile(archive) as bundle:
        if bundle.testzip() is not None:
            raise ValueError("ZIP integrity check failed")
    print(f"{archive}: {archive.stat().st_size:,} bytes")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["hydrate", "verify", "comparison", "package"])
    parser.add_argument("downloads", nargs="?", type=Path)
    args = parser.parse_args()
    manifest = json.loads(MANIFEST.read_text())
    if args.action == "hydrate":
        if not args.downloads:
            parser.error("hydrate requires the authenticated downloads directory")
        hydrate(manifest, args.downloads)
    elif args.action == "verify":
        verify(manifest)
    elif args.action == "comparison":
        comparison(manifest)
    else:
        package(manifest)


if __name__ == "__main__":
    main()
